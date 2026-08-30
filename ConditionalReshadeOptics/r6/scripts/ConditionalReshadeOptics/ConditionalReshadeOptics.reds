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
    public let reshadeProfilePath: String;
    public let config: ref<ConditionalReshadeOpticsConfig>;
    public let heartbeat: ref<ConditionalOpticsHeartbeatCallback>;
    public let heartbeatRunning: Bool;
    public let heartbeatSessionId: Uint32;

    public let modON: Bool;
    public let heartbeatContinuousON: Bool;
    public let effectDynamicStatusON: Bool;
    public let effectCinematicImmunityON: Bool;
    public let effectVRON: Bool;
    public let isArcadeMachineON: Bool;

    public let effectBraindanceON: Bool;
    public let effectBraindanceEditorON: Bool;
    public let effectJohnnyON: Bool;
    public let effectCyberspaceON: Bool;
    public let effectKiroshiON: Bool;
    public let effectCheapCyberwareON: Bool;
    public let effectGlitchedCyberwareON: Bool;
    public let effectNoCyberwareON: Bool;
    public let effectArcadeGameON: Bool;

    public func init(player: wref<PlayerPuppet>) -> Void {
        // Essential: Tells Mod Settings to trigger callbacks on this object
        ModSettings.RegisterListenerToModifications(this);
        this.reset(player);
    }

    public func reset(player: wref<PlayerPuppet>) -> Void {
        this.player = player; 

        this.refreshConfig();
        this.refresh();
    }

    public func refreshConfig() -> Void {
        this.config = new ConditionalReshadeOpticsConfig(); 
        this.invalidateCurrentState();
    }

    public func invalidateCurrentState() -> Void {    
        this.modON = this.config.modON;
        this.heartbeatContinuousON = this.config.heartbeatContinuousON;
        this.effectDynamicStatusON = this.config.effectDynamicStatusON;
        this.effectCinematicImmunityON = this.config.effectCinematicImmunityON;
        this.effectVRON = this.config.effectVRON;
        this.effectBraindanceON = this.config.effectBraindanceON;
        this.effectBraindanceEditorON = this.config.effectBraindanceEditorON;
        this.effectJohnnyON = this.config.effectJohnnyON;
        this.effectCyberspaceON = this.config.effectCyberspaceON;
        this.effectKiroshiON = this.config.effectKiroshiON;
        this.effectCheapCyberwareON = this.config.effectCheapCyberwareON;
        this.effectGlitchedCyberwareON = this.config.effectGlitchedCyberwareON;
        this.effectNoCyberwareON = this.config.effectNoCyberwareON;
        this.effectArcadeGameON = this.config.effectArcadeGameON;
    }

    public cb func OnModSettingsChange() -> Void {
        let wasHeartbeatEnabled: Bool = this.modON && this.heartbeatContinuousON;

        this.showDebugMessage("[ConditionalReshadeOptics] Settings were applied! Running post-update method...");
        this.refreshConfig();

        if wasHeartbeatEnabled && !this.isHeartbeatContinuousEnabled() {
            this.stopHeartbeat();
        }

        this.refresh();

        if !wasHeartbeatEnabled && this.isHeartbeatContinuousEnabled() {
            this.startHeartbeatIfNeeded();
        }
    }

    public func isHeartbeatContinuousEnabled() -> Bool {
        this.refreshConfig();
        return this.modON && this.heartbeatContinuousON;
    }

    public func startHeartbeatIfNeeded() -> Void {
        if this.heartbeatRunning {
            return;
        }

        if !IsDefined(this.heartbeat) {
            this.heartbeat = ConditionalOpticsHeartbeatCallback.create();
            this.heartbeat.init(this.player);
        }

        this.heartbeatRunning = true;
        this.heartbeatSessionId += 1u;
        this.heartbeat.startHeartbeat(this.player, this.heartbeatSessionId);
    }

    public func stopHeartbeat() -> Void {
        this.heartbeatRunning = false;
    }

    public func refresh() -> Void {
        this.refreshConfig();

        this.refreshReshadeProfile();
        this.refreshReshadeEffects();
        this.refreshCinematicImmunityEffect();

    }

    public func refreshReshadeProfile() -> Void {
        // Check if player is in an active game session (not in pre-game menu)
        if !IsDefined(this.player) {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: player not defined, skipping (likely in main menu).");
            RB_SetEffectsEnabled(false);
            return;
        }

        let questSystem: ref<QuestsSystem> = GameInstance.GetQuestsSystem(this.player.GetGame());
        let thermalVisionActive: Bool = questSystem.GetFact(n"qc_thermal_vision_active") > 0;

        if !this.modON || thermalVisionActive {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: mod disabled or thermal vision inactive, turning off all ReShade effects.");
            RB_SetEffectsEnabled(false);
            return;
        }

        // Ensure effects are enabled when mod is active
        RB_SetEffectsEnabled(true);

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

        let controlledObjRecordID: TweakDBID = this.player.GetRecord().GetID() ;  
        let isVRTutorialON: Bool = false;  
        let isImpersonating: Bool = false;
        let isVJAsJohnny: Bool = false;

        switch controlledObjRecordID {
        case t"Character.johnny_replacer":
            isImpersonating=true;
            isVJAsJohnny=true;
            break;
        case t"Character.q000_vr_replacer":
            isImpersonating=true;
            isVRTutorialON=true; 
            break;
        case t"Character.mq304_assassin_replacer_male":
            isImpersonating=true;
            break;
        case t"Character.mq304_assassin_replacer_female":
            isImpersonating=true;
            break; 
        case t"Character.kurt_replacer":
            isImpersonating=true;
            break;
        default:
            isImpersonating=false;
        };

        let bdSystem: ref<BraindanceSystem> = GameInstance.GetScriptableSystemsContainer(this.player.GetGame()).Get(n"BraindanceSystem") as BraindanceSystem;
    
        let isVictorHUDInstalled: Bool = questSystem.GetFact(n"q001_ripperdoc_done") >= 1; // Confirmed working
        let isAmmoCounterHidden: Bool = questSystem.GetFact(n"q001_hide_ammo_counter") >= 1;   // Confirmed working
        let isArasakaUION: Bool = questSystem.GetFact(n"q000_var_arasaka_ui_on") >= 1; // Confirmed working
        let isDigitalSicknessON: Bool = questSystem.GetFact(n"q001_wakeup_scene_done") >= 1; // Not working 
        let isCyberspaceON: Bool = questSystem.GetFact(n"cyberspace_on") >= 1; // Not tested
        let isBraindanceON: Bool = bdSystem.isInBraindance; // Not tested
        let isBraindanceEditorON: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.player, n"Braindance"); // Confirmed working
        let isPrologueStarted: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_active") >= 1; // Confirmed working

        let newReshadeProfile: String;

        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isCyberspaceON is " + questSystem.GetFact(n"cyberspace_on") );
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isVRTutorialON is " + isVRTutorialON );
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isVJAsJohnny is " + isVJAsJohnny );
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isDigitalSicknessON is " + questSystem.GetFact(n"q001_wakeup_scene_done") );
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isAmmoCounterHidden is " + questSystem.GetFact(n"q001_hide_ammo_counter") );
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isArasakaUION is " + questSystem.GetFact(n"q000_var_arasaka_ui_on") );
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isBraindanceON is " + isBraindanceON );
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isBraindanceEditorON is " + isBraindanceEditorON );
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isVictorHUDInstalled is " + questSystem.GetFact(n"q001_ripperdoc_done") );
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isPrologueStarted is " + questSystem.GetFact(n"q001_active") );
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isArcadeMachineON is " + this.isArcadeMachineON );

        if !RB_IsRuntimeReady() {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: forcing a refresh of runtime state. Current profile path: " + RB_GetPreset());
            RB_RefreshRuntime();  // retry if ReShade wasn't loaded yet
        }
        this.reshadeProfilePath = RB_GetPreset();
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: current profile path is " + this.reshadeProfilePath);

        if this.effectCyberspaceON && isCyberspaceON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isCyberspaceON is True - switching to " + "Cyberspace");
            newReshadeProfile = "Cyberspace";
        } else if this.effectVRON && isVRTutorialON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isVRTutorialON is True - switching to " + "VR");
            newReshadeProfile = "VR";
        } else if this.effectBraindanceEditorON && isBraindanceEditorON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isBraindanceEditorON is True - switching to " + "BraindanceEditor");
            newReshadeProfile = "BraindanceEditor";
        } else if this.effectBraindanceON && isBraindanceON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isBraindanceON is True - switching to " + "Braindance");
            newReshadeProfile = "Braindance";
        } else if this.effectArcadeGameON && this.isArcadeMachineON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isArcadeMachineON is True - switching to " + "Arcade");
            newReshadeProfile = "Arcade";
        } else if this.effectJohnnyON && isVJAsJohnny {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isVJAsJohnny is True - switching to " + "Johnny");
            newReshadeProfile = "Johnny";
        } else if isImpersonating {
            // Special Reshade profile for cases when there should be no reshade effects applied, e.g. Johnny's eyes, impersonations, etc.
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isImpersonating is True - switching to " + "OFF");
            newReshadeProfile = "OFF";
        } else if isArasakaUION {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isArasakaUION is True - switching to " + "Arasaka");
            newReshadeProfile = "Arasaka";
        } else if this.effectKiroshiON && isVictorHUDInstalled {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isVictorHUDInstalled is True - switching to " + "Kyroshi");
            newReshadeProfile = "Kyroshi";
        } else if this.effectGlitchedCyberwareON && isDigitalSicknessON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isDigitalSicknessON is True - switching to " + "RescueGlitched");
            newReshadeProfile = "RescueGlitched";
        } else if this.effectCheapCyberwareON && isAmmoCounterHidden && isPrologueStarted {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: isAmmoCounterHidden is True - switching to " + "CheapCyberware");
            newReshadeProfile = "CheapCyberware";
        } else if this.effectNoCyberwareON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: default case - switching to " + "NoCyberware");
            newReshadeProfile = "NoCyberware";
        } else {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: no enabled profile matched. Keeping current profile " + this.reshadeProfile);
            return;
        }

        if (StrCmp(newReshadeProfile, this.reshadeProfile) != 0) || !(StrContains(this.reshadeProfilePath, this.reshadeProfile)){
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeProfile: profile changed from " + this.reshadeProfile + " to " + newReshadeProfile);
            this.switchProfile(newReshadeProfile);
        }

    }


    public func refreshReshadeEffects() -> Void {
        // Check if player is in an active game session (not in pre-game menu)
        if !IsDefined(this.player) {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeEffects: player not defined, skipping (likely in main menu).");
            return;
        }

        if !this.modON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeEffects: mod disabled in settings, skipping Reshade techniques switches.");
            return;
        }

        if !this.effectDynamicStatusON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeEffects: dynamic effects disabled in settings, skipping Reshade techniques switches.");
            return;
        }

        let game = this.player.GetGame();  
        let ses: ref<StatusEffectSystem>;
        ses = GameInstance.GetStatusEffectSystem(this.player.GetGame());

        // BaseStatusEffect.Blind 
        // BaseStatusEffect.MajorBlind 
        // BaseStatusEffect.MinorBlind 
        // BaseStatusEffect.ModerateBlind 
        // BaseStatusEffect.BreathingHeavy
        // BaseStatusEffect.BreathingLow
        // BaseStatusEffect.BreathingMedium
        // BaseStatusEffect.BreathingSick
        // BaseStatusEffect.Burning
        // BaseStatusEffect.MediumBurning
        // BaseStatusEffect.Cloaked
        // BaseStatusEffect.Drugged
        // BaseStatusEffect.DruggedSevere
        // BaseStatusEffect.Drunk
        // BaseStatusEffect.Overheat 
        // BaseStatusEffect.Sandevsitan 

        let hasExhaustedEffect: Bool = ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.Exhausted"); 
        let hasBleedingEffect: Bool = ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.Bleeding"); 
        let hasBurningEffect: Bool = ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.Burning") 
                                    || ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.MediumBurning")
                                    || ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.Overheat")
                                    || ses.HasStatusEffect(this.player.GetEntityID(), t"AIQuickHackStatusEffect.HackOverheat"); 
        let hasPoisonedEffect: Bool = ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.Poisoned"); 
        let hasElectrocutedEffect: Bool = ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.OverloadShort") 
                                    || ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.Overload")
                                    || ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.Blind")
                                    || ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.MajorBlind")
                                    || ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.MinorBlind")
                                    || ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.ModerateBlind"); 
        let hasEncumberedEffect: Bool = ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.Encumbered");  
        let hasJohnnyEffect: Bool = ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.JohnnySicknessLow") 
                                    || ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.JohnnySicknessMedium")
                                    || ses.HasStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.JohnnySicknessHeavy"); 

        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeEffects: hasExhaustedEffect is " + hasExhaustedEffect);
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeEffects: hasBleedingEffect is " + hasBleedingEffect);
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeEffects: hasBurningEffect is " + hasBurningEffect);
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeEffects: hasPoisonedEffect is " + hasPoisonedEffect);
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeEffects: hasElectrocutedEffect is " + hasElectrocutedEffect);
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeEffects: hasEncumberedEffect is " + hasEncumberedEffect);
        this.showDebugMessage("[ConditionalReshadeOptics] refreshReshadeEffects: hasJohnnyEffect is " + hasJohnnyEffect);
 
        this.switchTechnique("GanossaMotionFocus", hasExhaustedEffect);
        this.switchTechnique("LiquidLens", hasExhaustedEffect);

        this.switchTechnique("AdaptiveColorGrading", hasBleedingEffect);

        this.switchTechnique("DeepFry", hasBurningEffect);
        this.switchTechnique("HueFX", hasPoisonedEffect);
        this.switchTechnique("ASCII", hasElectrocutedEffect);
        this.switchTechnique("TiltShift", hasEncumberedEffect);

        this.switchTechnique("AdaptiveColorGrading", hasJohnnyEffect);
    }

    public func refreshCinematicImmunityEffect() -> Void {
        // Check if player is in an active game session (not in pre-game menu)
        if !IsDefined(this.player) {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshCinematicImmunityEffect: player not defined, skipping (likely in main menu).");
            return;
        }

        if !this.modON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshCinematicImmunityEffect: mod disabled in settings, skipping.");
            return;
        }

        if !this.effectCinematicImmunityON {
            this.showDebugMessage("[ConditionalReshadeOptics] refreshCinematicImmunityEffect: cinematic immunity effect disabled in settings, skipping.");
            return;
        }

        let game = this.player.GetGame();
        let hasCinematicImmunityEffect: Bool = GameInstance.GetQuestsSystem(game).GetFactStr("ConditionalImmunityStatus") > 0;

        this.showDebugMessage("[ConditionalReshadeOptics] refreshCinematicImmunityEffect: hasCinematicImmunityEffect is " + hasCinematicImmunityEffect);
        
        this.switchTechnique("Border", hasCinematicImmunityEffect);
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
        this.showDebugMessage("[ConditionalReshadeOptics] switchProfile: profileName: " + profileName);
        let ok = RB_SetPreset("reshade-presets\\MyConditionalReshadeOptics\\V-" + profileName + ".ini");
        if !ok {
            this.showDebugMessage("[ConditionalReshadeOptics] switchProfile: runtime not available yet.");
        } else {
            this.reshadeProfile = profileName;
            this.showDebugMessage("[ConditionalReshadeOptics] switchProfile: switched to profile V-" + profileName + ".ini");
        }
    }

    public func switchTechnique(techniqueName: String, enable: Bool) -> Void {
        let ok = RB_SetTechniqueEnabled(techniqueName, enable);
        if !ok {
            this.showDebugMessage("[ConditionalReshadeOptics] switchTechnique: " + techniqueName + " technique not found.");
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
    //         this.showDebugMessage("[ConditionalReshadeOptics] DOF technique not found.");
    //     }
    // }

    private func showDebugMessage(debugMessage: String) {
       // LogChannel(n"DEBUG", debugMessage ); 
    }
}

// Basic class for a heartbeat check
// TO DO: How to connect this class to the ConditionalOptics class?  Maybe pass a reference

public class ConditionalOpticsHeartbeatCallback extends DelayCallback {
    public let player: wref<PlayerPuppet>; 
    public let sessionId: Uint32;

    public static func create() -> ref<ConditionalOpticsHeartbeatCallback> {
        let self: ref<ConditionalOpticsHeartbeatCallback> = new ConditionalOpticsHeartbeatCallback();
        return self;
    }

    public func init(player: wref<PlayerPuppet>) -> Void {
        this.reset(player); 
    }

    public func reset(player: wref<PlayerPuppet>) -> Void {
        this.player = player;  
    }

    public func startHeartbeat(player: wref<PlayerPuppet>, sessionId: Uint32) -> Void {
    //  let delaySystem = GameInstance.GetDelaySystem(GetGameInstance());
    //  delaySystem.DelayCallback(heartbeat, 5.0, false);
        let delaySystem = GameInstance.GetDelaySystem(GetGameInstance());
        let delayTime: Float = 5.0; // seconds
        let affectedByTimeDilation: Bool = false;
        let _playerPuppetPS: ref<PlayerPuppetPS> = this.player.GetPS(); 
        this.sessionId = sessionId;
 
        if _playerPuppetPS.m_conditionalOptics.heartbeatRunning && _playerPuppetPS.m_conditionalOptics.isHeartbeatContinuousEnabled() {
            _playerPuppetPS.m_conditionalOptics.showDebugMessage("[ReshadeBridge] ConditionalOpticsHeartbeatCallback: starting heartbeat.");
            delaySystem.DelayCallback(this, delayTime, affectedByTimeDilation);
        }
    }

    public func Call() -> Void {       
        let _playerPuppetPS: ref<PlayerPuppetPS> = this.player.GetPS(); 
        let optics: ref<ConditionalOptics> = _playerPuppetPS.m_conditionalOptics;

        if !IsDefined(optics) {
            return;
        }

        if !optics.heartbeatRunning || this.sessionId != optics.heartbeatSessionId {
            return;
        }

        // refresh() will do the checks for new conditions.
        optics.refresh();

        // queue the next heartbeat (e.g., 0.5 seconds from now)
        let delaySystem = GameInstance.GetDelaySystem(GetGameInstance());
        let delayTime: Float = 5.0; // seconds
        let affectedByTimeDilation: Bool = false;

        if optics.heartbeatRunning && optics.isHeartbeatContinuousEnabled() && this.sessionId == optics.heartbeatSessionId {
            delaySystem.DelayCallback(this, delayTime, affectedByTimeDilation);
        } else {
            optics.stopHeartbeat();
        }
    }
}