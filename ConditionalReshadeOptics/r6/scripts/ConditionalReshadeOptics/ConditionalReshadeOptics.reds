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

        let isVictorHUDInstalled: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_ripperdoc_done") >= 1; // Confirmed working
        let isAmmoCounterHidden: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_hide_ammo_counter") >= 1;   // Confirmed working
        let isArasakaUION: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q000_var_arasaka_ui_on") >= 1; // Confirmed working
        let isDigitalSicknessON: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_wakeup_scene_done") >= 1; // Not working
        // 11let isVRTutorialON: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q000_vr_custom_savelock") >= 1; // Not tested
        let isCyberspaceON: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"cyberspace_on") >= 1; // Not tested
        let isPrologueStarted: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_active") >= 1; // Confirmed working

        let newReshadeProfile: String;

        this.showDebugMessage("[ReshadeBridge] refresh: isCyberspaceON is " + GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"cyberspace_on") );
        // this.showDebugMessage("[ReshadeBridge] refresh: isVRTutorialON is " + GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q000_vr_custom_savelock") );
        this.showDebugMessage("[ReshadeBridge] refresh: isDigitalSicknessON is " + GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_wakeup_scene_done") );
        this.showDebugMessage("[ReshadeBridge] refresh: isAmmoCounterHidden is " + GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_hide_ammo_counter") );
        this.showDebugMessage("[ReshadeBridge] refresh: isArasakaUION is " + GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q000_var_arasaka_ui_on") );
        this.showDebugMessage("[ReshadeBridge] refresh: isVictorHUDInstalled is " + GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_ripperdoc_done") );
        this.showDebugMessage("[ReshadeBridge] refresh: isPrologueStarted is " + GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_active") );

        if !RB_IsRuntimeReady() {
            this.showDebugMessage("[ReshadeBridge] refresh: forcing a refresh of runtime state. Current profile: " + RB_GetPreset());
            RB_RefreshRuntime();  // retry if ReShade wasn't loaded yet
        }
        this.showDebugMessage("[ReshadeBridge] refresh: current profile is " + RB_GetPreset());

        if isCyberspaceON {
            this.showDebugMessage("[ReshadeBridge] refresh: isCyberspaceON is True - switching to " + "Cyberspace");
            newReshadeProfile = "Cyberspace";
        // } else if isVRTutorialON {
        //     this.showDebugMessage("[ReshadeBridge] refresh: isVRTutorialON is True - switching to " + "VR");
        //     newReshadeProfile = "VR";
        } else if isArasakaUION {
            this.showDebugMessage("[ReshadeBridge] refresh: isArasakaUION is True - switching to " + "Arasaka");
            newReshadeProfile = "Arasaka";
        } else if isVictorHUDInstalled {
            this.showDebugMessage("[ReshadeBridge] refresh: isVictorHUDInstalled is True - switching to " + "Kyroshi");
            newReshadeProfile = "Kyroshi";
        } else if isDigitalSicknessON {
            this.showDebugMessage("[ReshadeBridge] refresh: isDigitalSicknessON is True - switching to " + "RescueGlitched");
            newReshadeProfile = "RescueGlitched";
        } else if isAmmoCounterHidden && isPrologueStarted {
            this.showDebugMessage("[ReshadeBridge] refresh: isAmmoCounterHidden is True - switching to " + "CheapCyberware");
            newReshadeProfile = "CheapCyberware";
        } else {
            this.showDebugMessage("[ReshadeBridge] refresh: default case - switching to " + "NoCyberware");
            newReshadeProfile = "NoCyberware";
        }

        if (StrCmp(newReshadeProfile, this.reshadeProfile) != 0) {
            this.showDebugMessage("[ReshadeBridge] refresh: profile changed from " + this.reshadeProfile + " to " + newReshadeProfile);
            this.switchProfile(newReshadeProfile);
        }

    }

    // Reshade profile names (without the "V-" prefix and ".ini" suffix):
    // - NoCyberware   
    // - Arasaka
    // - RescueGlitched
    // - CheapCyberware
    // - Kyroshi
    // - VR
    // - Cyberspace

    public func switchProfile(profileName: String) -> Void {
        this.showDebugMessage("[ReshadeBridge] switchProfile: profileName: " + profileName);
        let ok = RB_SetPreset("reshade-presets\\ConditionalReshadeOptics\\V-" + profileName + ".ini");
        if !ok {
            this.showDebugMessage("[ReshadeBridge] switchProfile: runtime not available yet.");
        } else {
            this.reshadeProfile = profileName;
            this.showDebugMessage("[ReshadeBridge] switchProfile: switched to profile V-" + profileName + ".ini");
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
    //         this.showDebugMessage("[ReshadeBridge] DOF technique not found.");
    //     }
    // }

    private func showDebugMessage(debugMessage: String) {
        LogChannel(n"DEBUG", debugMessage ); 
    }
}

// Basic class for a heartbeat check
// TO DO: How to connect this class to the ConditionalOptics class?  Maybe pass a reference

public class ConditionalOpticsHeartbeatCallback extends DelayCallback {
    public let player: wref<PlayerPuppet>; 

    public static func create() -> ref<ConditionalOpticsHeartbeatCallback> {
        let self: ref<ConditionalOpticsHeartbeatCallback> = new ConditionalOpticsHeartbeatCallback();
        return self;
    }

    public func init(player: wref<PlayerPuppet>) -> Void {
        this.reset(player);
    }

    public func reset(player: wref<PlayerPuppet>) -> Void {
        this.player = player;  
        // Uncomment the following line to start the heartbeat immediately upon creation of the callback object
        // this.startHeartbeat(player);
    }

    public func startHeartbeat(player: wref<PlayerPuppet>) -> Void {
    //  let delaySystem = GameInstance.GetDelaySystem(GetGameInstance());
    //  delaySystem.DelayCallback(heartbeat, 5.0, false);
        let delaySystem = GameInstance.GetDelaySystem(GetGameInstance());
        let delayTime: Float = 5.0; // seconds
        let affectedByTimeDilation: Bool = false;
        let _playerPuppetPS: ref<PlayerPuppetPS> = this.player.GetPS(); 
 
        _playerPuppetPS.m_conditionalOptics.showDebugMessage("[ReshadeBridge] ConditionalOpticsHeartbeatCallback: starting heartbeat.");

        delaySystem.DelayCallback(this, delayTime, affectedByTimeDilation);
    }

    public func Call() -> Void {       
        let _playerPuppetPS: ref<PlayerPuppetPS> = this.player.GetPS(); 

        // refresh() will do the checks for new conditions.
        _playerPuppetPS.m_conditionalOptics.refresh();

        // queue the next heartbeat (e.g., 0.5 seconds from now)
        let delaySystem = GameInstance.GetDelaySystem(GetGameInstance());
        let delayTime: Float = 5.0; // seconds
        let affectedByTimeDilation: Bool = false;

        delaySystem.DelayCallback(this, delayTime, affectedByTimeDilation);
    }
}