#pragma once

#include <RED4ext/Api/v1/Sdk.hpp>
#include <RED4ext/Api/v1/PluginHandle.hpp>

// ScriptBindings registers Red4ext native global functions so that REDscript mods
// can call into ReshadeManager at runtime.
//
// reshade.hpp is intentionally NOT included here or in ScriptBindings.cpp.

namespace ScriptBindings
{
    // Call from Main() EMainReason::Load.
    // Registers an RTTI callback that will fire when the game's scripting runtime
    // is ready to receive native function registrations.
    void Register(const RED4ext::v1::Sdk* aSdk, RED4ext::v1::PluginHandle aHandle);

} // namespace ScriptBindings
