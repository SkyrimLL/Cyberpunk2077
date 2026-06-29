// ScriptBindings.cpp
//
// Registers global native functions with Red4ext's RTTI system so that
// REDscript mods can call into ReshadeManager at runtime.
//
// reshade.hpp is intentionally NOT included here.

#include "ScriptBindings.hpp"
#include "ReshadeManager.hpp"

#include <RED4ext/RED4ext.hpp>
#include <RED4ext/RTTISystem.hpp>
#include <RED4ext/Scripting/Functions.hpp>
#include <RED4ext/Scripting/Utils.hpp>
#include <RED4ext/CString.hpp>

// ─────────────────────────────────────────────────────────────────────────────
//  Native function implementations
//
//  Signature convention:
//    void fn(RED4ext::IScriptable*, RED4ext::CStackFrame*, RetType* aOut, int64_t)
//
//  GetParameter reads one argument from the scripting stack per call.
//  aFrame->code++ skips the end-of-parameters opcode after all params are read.
// ─────────────────────────────────────────────────────────────────────────────

namespace
{

// Module-level pointers kept for logging from native callbacks.
static const RED4ext::v1::Sdk*   s_sdk    = nullptr;
static RED4ext::v1::PluginHandle s_handle = nullptr;

// native func RB_SetPreset(path: String) -> Bool
static void RB_SetPreset(
    RED4ext::IScriptable*  /*aContext*/,
    RED4ext::CStackFrame*   aFrame,
    bool*                   aOut,
    int64_t                 /*a4*/)
{
    RED4ext::CString path;
    RED4ext::GetParameter(aFrame, &path);
    aFrame->code++; // skip end-of-params opcode

    const bool result = ReshadeManager::SetPresetPath(path.c_str());
    if (s_sdk)
        s_sdk->logger->TraceF(s_handle, "[ReshadeBridge] RB_SetPreset(\"%s\") -> %s",
            path.c_str(), result ? "true" : "false");
    if (aOut)
        *aOut = result;
}

// native func RB_GetPreset() -> String
static void RB_GetPreset(
    RED4ext::IScriptable*  /*aContext*/,
    RED4ext::CStackFrame*   aFrame,
    RED4ext::CString*       aOut,
    int64_t                 /*a4*/)
{
    aFrame->code++; // no parameters — skip end-of-params opcode

    std::string buf;
    const bool ok = ReshadeManager::GetPresetPath(buf);
    if (s_sdk)
        s_sdk->logger->TraceF(s_handle, "[ReshadeBridge] RB_GetPreset() -> \"%s\" (ok=%s)",
            buf.c_str(), ok ? "true" : "false");
    if (ok && aOut)
        *aOut = RED4ext::CString(buf.c_str());
}

// native func RB_SetEffectsEnabled(enabled: Bool) -> Void
static void RB_SetEffectsEnabled(
    RED4ext::IScriptable*  /*aContext*/,
    RED4ext::CStackFrame*   aFrame,
    void*                   /*aOut*/,
    int64_t                 /*a4*/)
{
    bool enabled = false;
    RED4ext::GetParameter(aFrame, &enabled);
    aFrame->code++;

    ReshadeManager::SetEffectsEnabled(enabled);
    if (s_sdk)
        s_sdk->logger->TraceF(s_handle, "[ReshadeBridge] RB_SetEffectsEnabled(%s)",
            enabled ? "true" : "false");
}

// native func RB_GetEffectsEnabled() -> Bool
static void RB_GetEffectsEnabled(
    RED4ext::IScriptable*  /*aContext*/,
    RED4ext::CStackFrame*   aFrame,
    bool*                   aOut,
    int64_t                 /*a4*/)
{
    aFrame->code++;

    const bool result = ReshadeManager::GetEffectsEnabled();
    if (s_sdk)
        s_sdk->logger->TraceF(s_handle, "[ReshadeBridge] RB_GetEffectsEnabled() -> %s",
            result ? "true" : "false");
    if (aOut)
        *aOut = result;
}

// native func RB_SetTechniqueEnabled(name: String, enabled: Bool) -> Bool
static void RB_SetTechniqueEnabled(
    RED4ext::IScriptable*  /*aContext*/,
    RED4ext::CStackFrame*   aFrame,
    bool*                   aOut,
    int64_t                 /*a4*/)
{
    RED4ext::CString name;
    bool enabled = false;
    RED4ext::GetParameter(aFrame, &name);
    RED4ext::GetParameter(aFrame, &enabled);
    aFrame->code++;

    const bool result = ReshadeManager::SetTechniqueState(name.c_str(), enabled);
    if (s_sdk)
        s_sdk->logger->TraceF(s_handle,
            "[ReshadeBridge] RB_SetTechniqueEnabled(\"%s\", %s) -> %s",
            name.c_str(), enabled ? "true" : "false", result ? "true" : "false");
    if (aOut)
        *aOut = result;
}

// native func RB_GetTechniqueEnabled(name: String) -> Bool
static void RB_GetTechniqueEnabled(
    RED4ext::IScriptable*  /*aContext*/,
    RED4ext::CStackFrame*   aFrame,
    bool*                   aOut,
    int64_t                 /*a4*/)
{
    RED4ext::CString name;
    RED4ext::GetParameter(aFrame, &name);
    aFrame->code++;

    const bool result = ReshadeManager::GetTechniqueState(name.c_str());
    if (s_sdk)
        s_sdk->logger->TraceF(s_handle,
            "[ReshadeBridge] RB_GetTechniqueEnabled(\"%s\") -> %s",
            name.c_str(), result ? "true" : "false");
    if (aOut)
        *aOut = result;
}

// native func RB_IsRuntimeReady() -> Bool
static void RB_IsRuntimeReady(
    RED4ext::IScriptable*  /*aContext*/,
    RED4ext::CStackFrame*   aFrame,
    bool*                   aOut,
    int64_t                 /*a4*/)
{
    aFrame->code++;

    const bool result = ReshadeManager::IsRuntimeAvailable();
    if (s_sdk)
        s_sdk->logger->TraceF(s_handle,
            "[ReshadeBridge] RB_IsRuntimeReady() -> %s", result ? "true" : "false");
    if (aOut)
        *aOut = result;
}

// native func RB_RefreshRuntime() -> Bool
// Retries reshade::register_addon and event registration if the initial
// DLL_PROCESS_ATTACH attempt failed (ReShade was not yet loaded at that point).
// Returns true once the runtime is captured and ready.
static void RB_RefreshRuntime(
    RED4ext::IScriptable*  /*aContext*/,
    RED4ext::CStackFrame*   aFrame,
    bool*                   aOut,
    int64_t                 /*a4*/)
{
    aFrame->code++;

    // Pass nullptr — TryReattach uses the stored handle from DLL_PROCESS_ATTACH.
    const bool result = ReshadeManager::TryReattach(nullptr);
    if (s_sdk)
        s_sdk->logger->TraceF(s_handle,
            "[ReshadeBridge] RB_RefreshRuntime() -> %s", result ? "true" : "false");
    if (aOut)
        *aOut = result;
}

// ─────────────────────────────────────────────────────────────────────────────
//  RTTI registration callback — fired by the game when scripting types are
//  being registered (before scripts are compiled).
// ─────────────────────────────────────────────────────────────────────────────

static void RegisterNativeFunctions()
{
    auto* rtti = RED4ext::CRTTISystem::Get();

    // Helper lambda to reduce repetition.
    // fullName uses the CP2077 convention: "FunctionName;Param1TypeParam2Type"
    // shortName is the bare function name used in REDscript.

    RED4ext::CBaseFunction::Flags flags;
    flags.isNative = 1;
    flags.isStatic = 1;

    // RB_SetPreset(path: String) -> Bool
    {
        auto* func = RED4ext::CGlobalFunction::Create(
            "RB_SetPreset", "RB_SetPreset",
            static_cast<RED4ext::ScriptingFunction_t<bool*>>(&RB_SetPreset));
        func->flags = flags;
        func->SetReturnType("Bool");
        func->AddParam("String", "path");
        rtti->RegisterFunction(func);
    }

    // RB_GetPreset() -> String
    {
        auto* func = RED4ext::CGlobalFunction::Create(
            "RB_GetPreset", "RB_GetPreset",
            static_cast<RED4ext::ScriptingFunction_t<RED4ext::CString*>>(&RB_GetPreset));
        func->flags = flags;
        func->SetReturnType("String");
        rtti->RegisterFunction(func);
    }

    // RB_SetEffectsEnabled(enabled: Bool) -> Void
    {
        auto* func = RED4ext::CGlobalFunction::Create(
            "RB_SetEffectsEnabled", "RB_SetEffectsEnabled",
            static_cast<RED4ext::ScriptingFunction_t<void*>>(&RB_SetEffectsEnabled));
        func->flags = flags;
        func->AddParam("Bool", "enabled");
        rtti->RegisterFunction(func);
    }

    // RB_GetEffectsEnabled() -> Bool
    {
        auto* func = RED4ext::CGlobalFunction::Create(
            "RB_GetEffectsEnabled", "RB_GetEffectsEnabled",
            static_cast<RED4ext::ScriptingFunction_t<bool*>>(&RB_GetEffectsEnabled));
        func->flags = flags;
        func->SetReturnType("Bool");
        rtti->RegisterFunction(func);
    }

    // RB_SetTechniqueEnabled(name: String, enabled: Bool) -> Bool
    {
        auto* func = RED4ext::CGlobalFunction::Create(
            "RB_SetTechniqueEnabled", "RB_SetTechniqueEnabled",
            static_cast<RED4ext::ScriptingFunction_t<bool*>>(&RB_SetTechniqueEnabled));
        func->flags = flags;
        func->SetReturnType("Bool");
        func->AddParam("String", "name");
        func->AddParam("Bool", "enabled");
        rtti->RegisterFunction(func);
    }

    // RB_GetTechniqueEnabled(name: String) -> Bool
    {
        auto* func = RED4ext::CGlobalFunction::Create(
            "RB_GetTechniqueEnabled", "RB_GetTechniqueEnabled",
            static_cast<RED4ext::ScriptingFunction_t<bool*>>(&RB_GetTechniqueEnabled));
        func->flags = flags;
        func->SetReturnType("Bool");
        func->AddParam("String", "name");
        rtti->RegisterFunction(func);
    }

    // RB_IsRuntimeReady() -> Bool
    {
        auto* func = RED4ext::CGlobalFunction::Create(
            "RB_IsRuntimeReady", "RB_IsRuntimeReady",
            static_cast<RED4ext::ScriptingFunction_t<bool*>>(&RB_IsRuntimeReady));
        func->flags = flags;
        func->SetReturnType("Bool");
        rtti->RegisterFunction(func);
    }

    // RB_RefreshRuntime() -> Bool
    {
        auto* func = RED4ext::CGlobalFunction::Create(
            "RB_RefreshRuntime", "RB_RefreshRuntime",
            static_cast<RED4ext::ScriptingFunction_t<bool*>>(&RB_RefreshRuntime));
        func->flags = flags;
        func->SetReturnType("Bool");
        rtti->RegisterFunction(func);
    }
}

} // anonymous namespace

// ─────────────────────────────────────────────────────────────────────────────
//  Public API
// ─────────────────────────────────────────────────────────────────────────────

void ScriptBindings::Register(const RED4ext::v1::Sdk* aSdk, RED4ext::v1::PluginHandle aHandle)
{
    s_sdk    = aSdk;
    s_handle = aHandle;
    // Native global functions must be registered in PostRegisterTypes, not
    // RegisterTypes.  AddRegisterCallback fires before base types are fully
    // resolved; AddPostRegisterCallback fires after all types are ready and
    // before scripts are compiled/validated.
    RED4ext::CRTTISystem::Get()->AddPostRegisterCallback(&RegisterNativeFunctions);
}
