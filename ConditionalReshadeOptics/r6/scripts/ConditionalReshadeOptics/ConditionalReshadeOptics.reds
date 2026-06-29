// ConditionalReshadeOptics - by DeepBlueFrog

/*
For redscript mod developers

:: Added fields
@addField(PlayerPuppetPS) public let m_conditionalOptics: ref<ConditionalOptics>;

:: New classes
public class ConditionalOptics
*/

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

public class ConditionalOptics extends ScriptedPuppetPS {
    public let player: wref<PlayerPuppet>;

    public let reshadeProfile: String;

    public func init(player: wref<PlayerPuppet>) -> Void {
        this.reset(player);
    }

    public func reset(player: wref<PlayerPuppet>) -> Void {
        this.player = player; 

        this.refresh();
    }

    public func refresh() -> Void {
        // TODO: catch status of other quest facts to determine which Reshade profile to use
        // - start/end of nomad lifepath intro quest - q000_nomad / q001_hide_ammo_counter
        // - start/end of street kid lifepath intro quest - q000_street_kid / q001_hide_ammo_counter
        // - start/end of corpo lifepath intro quest - q000_corpo / q000_var_arasaka_ui_on / q000_var_arasaka_ui_off 
        //     -> switch to normal view if q000_var_arasaka_ui_on is false
        // - start/end of The Rescue quest - q001_started and q001_digital_sickness and not q001_wakeup_scene_done
        // - cyberware corruption during The rescue quest - q001_wakeup_scene_done and not q001_ripperdoc_done
        // - start/end of q001_ripperdoc_done (Victor's HUD) - tutorial_ripperdoc_eyes_passed / q001_ripperdoc_done / q001_hide_ammo_counter
        // - vr tutorial - q000_vr_tutorial_enabled
        // - cyberspace - cyberspace_on

        let isVictorHUDInstalled: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_ripperdoc_done") >= 1;
        let isAmmoCounterHidden: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_hide_ammo_counter") >= 1;
        let isArasakaUION: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q000_var_arasaka_ui_on") >= 1;
        let isDigitalSicknessON: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_digital_sickness") >= 1;
        let isVRTutorialON: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q000_vr_tutorial_enabled") >= 1;
        let isCyberspaceON: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"cyberspace_on") >= 1;
        
        if !RB_IsRuntimeReady() {
            LogChannel(n"DEBUG", "[ReshadeBridge] refresh: forcing a refresh of runtime state. Current profile: " + RB_GetPreset());
            RB_RefreshRuntime();  // retry if ReShade wasn't loaded yet
        }
        LogChannel(n"DEBUG", "[ReshadeBridge] refresh: current profile is " + RB_GetPreset());

        if isVictorHUDInstalled {
            LogChannel(n"DEBUG", "[ReshadeBridge] refresh: switching to " + "Kyroshi");
            this.switchProfile("Kyroshi");
        } else {
            LogChannel(n"DEBUG", "[ReshadeBridge] refresh: switching to " + "Arasaka");
            this.switchProfile("Arasaka");
        }

    }

    // V-NoCyberware.ini 
    // V-Arasaka.ini
    // V-RescueGlitched.ini
    // V-CheapCyberware.ini
    // V-Kyroshi.ini

    public func switchProfile(profileName: String) -> Void {
        LogChannel(n"DEBUG", "[ReshadeBridge] switchProfile: profileName: " + profileName);
        let ok = RB_SetPreset("reshade-presets\\V-" + profileName + ".ini");
        if !ok {
            LogChannel(n"DEBUG", "[ReshadeBridge] switchProfile: runtime not available yet.");
        } else {
            this.reshadeProfile = profileName;
            LogChannel(n"DEBUG", "[ReshadeBridge] switchProfile: switched to profile V-" + profileName + ".ini");
        }
    }

    // public func disableAllEffectsForCutscene() -> Void {
    //     RB_SetEffectsEnabled(false);
    // }

    // public func restoreEffects() -> Void {
    //     RB_SetEffectsEnabled(true);
    // }

    // public func toggleDOF(enable: Bool) -> Void {
    //     let ok = RB_SetTechniqueEnabled("DOF", enable);
    //     if !ok {
    //         LogChannel(n"DEBUG", "[ReshadeBridge] DOF technique not found.");
    //     }
    // }
}
