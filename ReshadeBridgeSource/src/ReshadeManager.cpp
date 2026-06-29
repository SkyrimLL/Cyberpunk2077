// ReshadeManager.cpp 
//
// This is the ONLY translation unit that includes <reshade.hpp>.
// All other source files interact with ReShade exclusively through the
// thread-safe interface declared in ReshadeManager.hpp.

#include "ReshadeManager.hpp" 

#include <reshade.hpp>
#include <vector>
#include <algorithm>
#include <mutex>
 

namespace
{
    std::mutex                                s_mutex;
    std::vector<reshade::api::effect_runtime*> s_runtimes; // Track all active runtimes
    void*                                     s_moduleHandle    = nullptr;
    bool                                      s_addonRegistered = false;

    void on_init_effect_runtime(reshade::api::effect_runtime* aRuntime)
    {
        std::lock_guard<std::mutex> lock(s_mutex);
        if (std::find(s_runtimes.begin(), s_runtimes.end(), aRuntime) == s_runtimes.end())
        {
            s_runtimes.push_back(aRuntime);
        }
    }

    void on_destroy_effect_runtime(reshade::api::effect_runtime* aRuntime)
    {
        std::lock_guard<std::mutex> lock(s_mutex);
        s_runtimes.erase(std::remove(s_runtimes.begin(), s_runtimes.end(), aRuntime), s_runtimes.end());
    }

    void on_reshade_present(reshade::api::effect_runtime* aRuntime)
    {
        std::lock_guard<std::mutex> lock(s_mutex);
        if (std::find(s_runtimes.begin(), s_runtimes.end(), aRuntime) == s_runtimes.end())
        {
            s_runtimes.push_back(aRuntime);
            reshade::log::message(reshade::log::level::debug,
                "[ReshadeBridge] on_reshade_present: captured runtime via late-load.");
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Lifecycle
// ─────────────────────────────────────────────────────────────────────────────

bool ReshadeManager::TryReattach(void* aModuleHandle)
{
    std::unique_lock<std::mutex> lock(s_mutex);

    if (aModuleHandle)
        s_moduleHandle = aModuleHandle;

    if (s_addonRegistered)
    {
        // Already registered — report current runtime state.
        return !s_runtimes.empty();
    }

    if (!reshade::register_addon(s_moduleHandle))
    {
        reshade::log::message(reshade::log::level::debug,
            "[ReshadeBridge] ReshadeManager: reshade::register_addon failed (ReShade not yet loaded).");
        return false;
    }

    s_addonRegistered = true;
    reshade::log::message(reshade::log::level::debug,
        "[ReshadeBridge] ReshadeManager: addon registered, registering events.");

    // Release our lock before calling into ReShade to avoid a potential
    // deadlock with ReShade's own internal lock.
    lock.unlock();
    reshade::register_event<reshade::addon_event::init_effect_runtime>(&on_init_effect_runtime);
    reshade::register_event<reshade::addon_event::destroy_effect_runtime>(&on_destroy_effect_runtime);
    reshade::register_event<reshade::addon_event::reshade_present>(&on_reshade_present);
    lock.lock();

    return !s_runtimes.empty();
}

void ReshadeManager::UnregisterEvents()
{
    reshade::unregister_event<reshade::addon_event::init_effect_runtime>(&on_init_effect_runtime);
    reshade::unregister_event<reshade::addon_event::destroy_effect_runtime>(&on_destroy_effect_runtime);
    reshade::unregister_event<reshade::addon_event::reshade_present>(&on_reshade_present);
} 

// ─────────────────────────────────────────────────────────────────────────────
//  Preset control
// ─────────────────────────────────────────────────────────────────────────────

bool ReshadeManager::SetPresetPath(const char* aPath)
{
    std::lock_guard<std::mutex> lock(s_mutex);
    if (s_runtimes.empty())
    {
        reshade::log::message(reshade::log::level::debug,
            "[ReshadeBridge] SetPresetPath: No active runtimes available.");
        return false;
    }

    for (auto* runtime : s_runtimes)
    {
        runtime->set_current_preset_path(aPath);
    }
    return true;
}

bool ReshadeManager::IsRuntimeAvailable()
{
    std::lock_guard<std::mutex> lock(s_mutex);
    return !s_runtimes.empty();
}

bool ReshadeManager::GetPresetPath(std::string& aOut)
{
    std::lock_guard<std::mutex> lock(s_mutex);
    if (s_runtimes.empty())
    {
        reshade::log::message(reshade::log::level::debug,
            "[ReshadeBridge] GetPresetPath: runtime not available.");
        return false;
    }

    // ReShade get_current_preset_path: first call with nullptr to query length,
    // then call again with a sized buffer.
    size_t size = 0; 
    s_runtimes.front()->get_current_preset_path(nullptr, &size);
    reshade::log::message(reshade::log::level::debug,
        (std::string("[ReshadeBridge] GetPresetPath: queried path size = ") + std::to_string(size)).c_str());

    if (size == 0)
    {
        reshade::log::message(reshade::log::level::debug,
            "[ReshadeBridge] GetPresetPath: reported size is 0, returning empty string.");
        aOut.clear();
        return true;
    }

    aOut.resize(size);
    s_runtimes.front()->get_current_preset_path(aOut.data(), &size);
    // Strip null-terminator if present.
    if (!aOut.empty() && aOut.back() == '\0')
        aOut.pop_back();

    reshade::log::message(reshade::log::level::debug,
        (std::string("[ReshadeBridge] GetPresetPath: path = '") + aOut + "'").c_str());
    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Global effects toggle
// ─────────────────────────────────────────────────────────────────────────────

void ReshadeManager::SetEffectsEnabled(bool aEnabled)
{
    std::lock_guard<std::mutex> lock(s_mutex);
    if (s_runtimes.empty())
        return;

    for (auto* runtime : s_runtimes)
    {
        runtime->set_effects_state(aEnabled);
    }
}

bool ReshadeManager::GetEffectsEnabled()
{
    std::lock_guard<std::mutex> lock(s_mutex);
    if (s_runtimes.empty())
        return false;

    return s_runtimes.front()->get_effects_state();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Per-technique toggle
// ─────────────────────────────────────────────────────────────────────────────

bool ReshadeManager::SetTechniqueState(const char* aName, bool aEnabled)
{
    std::lock_guard<std::mutex> lock(s_mutex);
    if (s_runtimes.empty())
        return false;

    // nullptr for the effect filename means search all loaded effects.
    reshade::api::effect_technique tech = s_runtimes.front()->find_technique(nullptr, aName);
    if (tech.handle == 0)
        return false;

    s_runtimes.front()->set_technique_state(tech, aEnabled);
    return true;
}

bool ReshadeManager::GetTechniqueState(const char* aName)
{
    std::lock_guard<std::mutex> lock(s_mutex);
    if (s_runtimes.empty())
        return false;

    reshade::api::effect_technique tech = s_runtimes.front()->find_technique(nullptr, aName);
    if (tech.handle == 0)
        return false;

    return s_runtimes.front()->get_technique_state(tech);
}
