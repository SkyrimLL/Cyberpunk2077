#pragma once

#include <string>

// ReshadeManager owns the reshade::api::effect_runtime* pointer (acquired via addon events)
// and exposes a thread-safe interface to the rest of the plugin.
//
// reshade.hpp is intentionally NOT included here — it is only included in ReshadeManager.cpp.
// Callers (ScriptBindings, Main) therefore have no transitive dependency on the ReShade headers.

namespace ReshadeManager
{
    // Called from DllMain DLL_PROCESS_ATTACH.
    // Stores the module handle, calls reshade::register_addon, and registers events.
    // Safe to call again from script via TryReattach if the first attempt failed
    // (e.g. ReShade was not yet loaded when the plugin DLL was first attached).
    bool TryReattach(void* aModuleHandle);

    // Called from DllMain DLL_PROCESS_DETACH.
    void UnregisterEvents();

    // Returns true when an effect_runtime has been captured and API calls will succeed.
    [[nodiscard]] bool IsRuntimeAvailable();

    // ── Preset control ──────────────────────────────────────────────────────
    // Sets the active preset by absolute or game-relative path.
    // Returns false if no runtime is available yet.
    [[nodiscard]] bool SetPresetPath(const char* aPath);

    // Writes the current preset path into aOut.
    // Returns false if no runtime is available yet.
    [[nodiscard]] bool GetPresetPath(std::string& aOut);

    // ── Global effects toggle ────────────────────────────────────────────────
    void SetEffectsEnabled(bool aEnabled);
    [[nodiscard]] bool GetEffectsEnabled();

    // ── Per-technique toggle ─────────────────────────────────────────────────
    // Both return false when the runtime is absent or the technique is not found.
    [[nodiscard]] bool SetTechniqueState(const char* aName, bool aEnabled);
    [[nodiscard]] bool GetTechniqueState(const char* aName);

} // namespace ReshadeManager
