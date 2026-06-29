# ReshadeBridge

A [Red4ext](https://docs.red4ext.com/) plugin that bridges [ReShade's addon API](https://crosire.github.io/reshade-docs/index.html) with REDscript, enabling any REDscript mod to dynamically switch the active ReShade preset, toggle effects, or enable/disable individual techniques at runtime.

The plugin is a single DLL that simultaneously acts as a **Red4ext plugin** (exposing `Main` / `Query` / `Supports` exports) and a **ReShade addon** (registering `effect_runtime` lifecycle callbacks via `DllMain`).

---

## Build prerequisites

| Tool | Minimum version |
|---|---|
| CMake | 3.12 |
| MSVC | Visual Studio 2022 (v143) or ClangCL |
| Windows SDK | 10.0.19041 or later |
| Git | Any version with submodule support |

---

## Clone and build

```sh
# Clone with both submodules in one shot (--depth 1 keeps the reshade clone small)
git clone https://github.com/SkyrimLL/Cyberpunk2077/tree/main/ReshadeBridgeSource 

# 1. Create a new Red4ext project 
Use the started project structure from: https://github.com/wopss/RED4ext.Example.CMake 
Copy the source files in the src folder
Add the external dependencies from Red4ext (https://github.com/WopsS/RED4ext) and reshade API (https://github.com/crosire/reshade)

# 2. Configure (x64 Release)
$env:PATH += ";C:\Program Files\CMake\bin"
cd "Path to ReshadeBridge source"
cmake -B build -A x64

# 3. Build
cmake --build build --config Release
```

The compiled DLL is written to `build/src/Release/ReshadeBridge.dll`.

---

## Install

Copy the DLL into Red4ext's plugins directory so Red4ext picks it up automatically:

```
<Cyberpunk 2077 root>/
└── red4ext/
    └── plugins/
        └── ReshadeBridge/
            └── ReshadeBridge.dll   ← copy here
```

---

## REDscript usage

Declare the native functions in your `.reds` file (no import statement needed — the functions are global):

```swift
// ── Runtime readiness ───────────────────────────────────────────────────────

// Returns true when the ReShade effect runtime has been captured and all
// RB_* calls will succeed.  Poll this before making other calls if you are
// not sure whether ReShade has finished initialising.
native func RB_IsRuntimeReady() -> Bool

// Retries addon registration with ReShade if the initial attempt at DLL load
// time failed (e.g. ReShade had not yet been loaded into the process).
// Also returns true once the runtime is captured and ready.
// Safe to call repeatedly — no-ops once already registered.
native func RB_RefreshRuntime() -> Bool

// ── Preset control ──────────────────────────────────────────────────────────

// Switch the active preset (absolute path or path relative to the game executable).
native func RB_SetPreset(path: String) -> Bool

// Get the path of the currently loaded preset.
native func RB_GetPreset() -> String

// ── Global effects toggle ───────────────────────────────────────────────────

// Enable or disable all ReShade effects at once.
native func RB_SetEffectsEnabled(enabled: Bool) -> Void

// Query whether effects are currently enabled.
native func RB_GetEffectsEnabled() -> Bool

// ── Per-technique toggle ────────────────────────────────────────────────────

// Enable or disable a specific technique by its name as shown in ReShade's UI.
native func RB_SetTechniqueEnabled(name: String, enabled: Bool) -> Bool

// Query whether a specific technique is currently enabled.
native func RB_GetTechniqueEnabled(name: String) -> Bool
```

### Runtime detection note

Red4ext plugins are loaded **after** the renderer starts, meaning the ReShade effect runtime may have already initialised before this DLL was attached.  The plugin handles this automatically via a `reshade_present` fallback that captures the runtime on the first rendered frame.  In practice, the runtime will be ready within one frame of the plugin loading.

If you call `RB_*` functions very early (e.g. from a system `OnAttach`), guard them with `RB_IsRuntimeReady()`.  Use `RB_RefreshRuntime()` to force a re-registration attempt if you suspect ReShade was not yet loaded.

### Example — switch preset on demand

```swift
// In any ScriptableSystem or script class:
public func SwitchToNightPreset() -> Void {
    if !RB_IsRuntimeReady() {
        LogChannel(n"DEBUG", "[ReshadeBridge] runtime not ready, attempting refresh.");
        RB_RefreshRuntime();
        return;
    }
    let ok = RB_SetPreset("reshade-presets\\NightCity_Night.ini");
    if !ok {
        LogChannel(n"DEBUG", "[ReshadeBridge] SetPreset failed.");
    }
}

public func DisableAllEffectsForCutscene() -> Void {
    RB_SetEffectsEnabled(false);
}

public func RestoreEffects() -> Void {
    RB_SetEffectsEnabled(true);
}

public func ToggleDOF(enable: Bool) -> Void {
    let ok = RB_SetTechniqueEnabled("DOF", enable);
    if !ok {
        LogChannel(n"DEBUG", "[ReshadeBridge] DOF technique not found.");
    }
}
```

---

## Preset path format

Preset paths are passed directly to `reshade::api::effect_runtime::set_current_preset_path`, which accepts:

- **Path relative to the game executable** — `reshade-presets\MyPreset.ini`

Use backslashes or forward slashes; the underlying `std::filesystem::path` normalises them.

---

## How it works

```
┌─────────────────────────────────────────────────────────────┐
│                      ReshadeBridge.dll                      │
│                                                             │
│  DllMain ──► ReshadeManager::TryReattach(hinstDLL)          │
│               ├─ reshade::register_addon()                  │
│               └─ register events:                           │
│                    on_init_effect_runtime   ──► s_runtime   │
│                    on_destroy_effect_runtime ──► s_runtime=0│
│                    on_reshade_present (fallback)            │
│                      └─ fires every frame; sets s_runtime   │
│                         on first call if still nullptr      │
│                         (handles late-load by Red4ext)      │
│                                                             │
│  Main(Load) ──► ScriptBindings::Register()                  │
│                  └─► CRTTISystem::AddPostRegisterCallback() │
│                            │                                │
│                    RegisterNativeFunctions() × 8            │
│                    ├─ RB_IsRuntimeReady()                   │
│                    ├─ RB_RefreshRuntime()                   │
│                    ├─ RB_SetPreset / RB_GetPreset           │
│                    ├─ RB_SetEffectsEnabled / GetEffects...  │
│                    └─ RB_SetTechniqueEnabled / GetTech...   │
└─────────────────────────────────────────────────────────────┘
         ▲ Red4ext loads DLL          ▲ REDscript calls
         │                            │
   red4ext/plugins/           native func RB_*(...)
   ReshadeBridge/
   ReshadeBridge.dll
```

The `effect_runtime*` is protected by a `std::mutex` because ReShade callbacks fire on the render thread while REDscript calls arrive on the game thread.

### Runtime detection flow

Red4ext loads plugins after the D3D swapchain is created, so `init_effect_runtime` has already fired by the time `DllMain` runs.  Two mechanisms handle this:

1. **`on_reshade_present` fallback** — registered automatically on load; fires on the first frame and captures `s_runtime` if it is still null.  No script action required.
2. **`RB_RefreshRuntime()`** — available from REDscript for the rare case where `reshade::register_addon` itself failed (ReShade not yet in the process at DLL attach time).  Retries the full registration; idempotent once succeeded.

---

## Submodule notes

| Path | Repository |
|---|---|
| `deps/red4ext.sdk` | https://github.com/WopsS/RED4ext.SDK.git |
| `deps/reshade` | https://github.com/crosire/reshade.git |

Only `deps/reshade/include/` is used at compile time. Use `--depth 1` when cloning to avoid downloading the full ReShade history.
