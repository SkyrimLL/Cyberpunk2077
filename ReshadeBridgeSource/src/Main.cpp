#include <RED4ext/RED4ext.hpp>
#include <RED4ext/Api/v1/EMainReason.hpp>
#include <RED4ext/Api/v1/PluginHandle.hpp>
#include <RED4ext/Api/v1/PluginInfo.hpp>
#include <RED4ext/Api/v1/Runtime.hpp>
#include <RED4ext/Api/v1/Sdk.hpp>
#include <RED4ext/Api/v1/SemVer.hpp>
#include <RED4ext/Api/v1/Version.hpp>
#include <RED4ext/Api/ApiVersion.hpp>
#include <reshade.hpp>

#include "ReshadeManager.hpp"
#include "ScriptBindings.hpp"

// ─────────────────────────────────────────────────────────────────────────────
//  ReShade addon entry point
//
//  DllMain is invoked by the Windows loader when Red4ext (or any loader) calls
//  LoadLibrary/LoadLibraryEx on this DLL.  ReShade hooks LoadLibrary and
//  detects new DLLs via DLL_PROCESS_ATTACH, so both entry points coexist
//  naturally in the same translation unit.
// ─────────────────────────────────────────────────────────────────────────────
BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID)
{
    switch (fdwReason)
    {
    case DLL_PROCESS_ATTACH:
        // TryReattach stores hinstDLL, calls reshade::register_addon, and registers
        // events.  Returns false (non-fatal) when ReShade is not yet loaded;
        // RB_RefreshRuntime() in REDscript can retry later.
        ReshadeManager::TryReattach(hinstDLL);
        break;

    case DLL_PROCESS_DETACH:
        ReshadeManager::UnregisterEvents();
        reshade::unregister_addon(hinstDLL);
        break;
    }
    return TRUE;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Red4ext plugin entry points
// ─────────────────────────────────────────────────────────────────────────────
RED4EXT_C_EXPORT bool RED4EXT_CALL Main(
    RED4ext::v1::PluginHandle aHandle,
    RED4ext::v1::EMainReason  aReason,
    const RED4ext::v1::Sdk*   aSdk)
{
    switch (aReason)
    {
    case RED4ext::v1::EMainReason::Load:
        ScriptBindings::Register(aSdk, aHandle);
        aSdk->logger->Info(aHandle, "[ReshadeBridge] Plugin loaded.");
        break;

    case RED4ext::v1::EMainReason::Unload:
        aSdk->logger->Info(aHandle, "[ReshadeBridge] Plugin unloaded.");
        break;
    }
    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::v1::PluginInfo* aInfo)
{
    aInfo->name    = L"ReshadeBridge";
    aInfo->author  = L"DeepBlueFrog";
    aInfo->version = RED4EXT_V1_SEMVER(1, 0, 0);
    aInfo->runtime = RED4EXT_V1_RUNTIME_VERSION_LATEST;
    aInfo->sdk     = RED4EXT_V1_SDK_VERSION_CURRENT;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports()
{
    return RED4EXT_API_VERSION_1;
}
