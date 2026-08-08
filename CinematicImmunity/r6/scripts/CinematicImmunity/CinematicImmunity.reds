// CinematicImmunity
// Grants temporary invulnerability (gameGodModeType.Invulnerable) during cinematic
// scenes and scripted sequences by polling quest-fact values and the player's
// controlled character record every 2 seconds via a DelayCallback heartbeat.


// ── Main tracking class ──────────────────────────────────────────────────────

public class CinematicImmunity extends ScriptedPuppetPS {
    public let player: wref<PlayerPuppet>;
    public let heartbeat: ref<CinematicImmunityHeartbeatCallback>;
    public let heartbeatRunning: Bool;
    public let heartbeatSessionId: Uint32;
    public let immunityActive: Bool;

    public let config: ref<CinematicImmunityConfig>;

    // Mirrored config values – updated by invalidateCurrentState()
    public let modON: Bool;
    public let immunityVRTutorialON: Bool;
    public let immunityJohnnyON: Bool;
    public let immunityAguilarAssassinON: Bool;
    public let immunityKurtHanssenON: Bool;
    public let immunityCorpoIntroON: Bool;
    public let immunityNomadPrologueON: Bool;
    public let immunityStreetKidPrologueON: Bool;
    public let immunityRescueSceneON: Bool;
    public let immunityCyberspaceON: Bool;
    public let immunityBraindanceON: Bool;
    public let immunityInSceneON: Bool;
    public let immunityHeistEscapeON: Bool;
    public let immunityActTransitionON: Bool;
    public let immunityDFTRON: Bool;
    public let immunityPanamChaseON: Bool;
    public let immunityCarRaceON: Bool;
    public let immunityChimeraChaseON: Bool;

    public func init(player: wref<PlayerPuppet>) -> Void {
        ModSettings.RegisterListenerToModifications(this);
        this.reset(player);
    }

    public func reset(player: wref<PlayerPuppet>) -> Void {
        this.player = player;
        this.removeImmunity();
        this.refreshConfig();
        this.refresh();
    }

    public func refreshConfig() -> Void {
        this.config = new CinematicImmunityConfig();
        this.config.RegisterMyListeners();
        this.invalidateCurrentState();
    }

    public func invalidateCurrentState() -> Void {
        this.modON                   = this.config.modON;
        this.immunityVRTutorialON    = this.config.immunityVRTutorialON;
        this.immunityJohnnyON        = this.config.immunityJohnnyON;
        this.immunityAguilarAssassinON    = this.config.immunityAguilarAssassinON;
        this.immunityKurtHanssenON   = this.config.immunityKurtHanssenON;
        this.immunityCorpoIntroON    = this.config.immunityCorpoIntroON;
        this.immunityNomadPrologueON    = this.config.immunityNomadPrologueON;
        this.immunityStreetKidPrologueON = this.config.immunityStreetKidPrologueON;
        this.immunityRescueSceneON   = this.config.immunityRescueSceneON;
        this.immunityCyberspaceON    = this.config.immunityCyberspaceON;
        this.immunityBraindanceON    = this.config.immunityBraindanceON;
        this.immunityInSceneON       = this.config.immunityInSceneON;
        this.immunityHeistEscapeON   = this.config.immunityHeistEscapeON;
        this.immunityActTransitionON = this.config.immunityActTransitionON;
        this.immunityDFTRON          = this.config.immunityDFTRON;
        this.immunityPanamChaseON    = this.config.immunityPanamChaseON;
        this.immunityCarRaceON        = this.config.immunityCarRaceON;
        this.immunityChimeraChaseON  = this.config.immunityChimeraChaseON;
    }

    public cb func OnModSettingsChange() -> Void {
        this.showDebugMessage("[CinematicImmunity] Settings changed – applying update.");
        this.refreshConfig(); 
        this.refresh();
    }

    public func startHeartbeatIfNeeded() -> Void {
        if !this.modON {
            return;
        };

        if this.heartbeatRunning {
            return;
        }

        if !IsDefined(this.heartbeat) {
            this.heartbeat = CinematicImmunityHeartbeatCallback.create();
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
        if this.modON {
            this.startHeartbeatIfNeeded();
        } else {
            this.stopHeartbeat();
        }
        this.refreshImmunity();
    }

    // Evaluate all scene conditions and apply / remove god-mode immunity as needed.
    public func refreshImmunity() -> Void {
        if !this.modON {
            this.removeImmunity(); 
            return;
        };

        if !IsDefined(this.player) {
            return;
        }

        let qs: ref<QuestsSystem> = GameInstance.GetQuestsSystem(this.player.GetGame());
        let controlledObjRecordID: TweakDBID = this.player.GetRecord().GetID();
        let bdSystem: ref<BraindanceSystem> = GameInstance.GetScriptableSystemsContainer(this.player.GetGame()).Get(n"BraindanceSystem") as BraindanceSystem;
        let bb: ref<IBlackboard> = this.player.GetPlayerStateMachineBlackboard();

        let isPhantomLibertyStandalone: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"ep1_standalone") >= 1;

        let noTimeSkip: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.player, n"NoTimeSkip"); 
        let noFastTravel: Bool = StatusEffectSystem.ObjectHasStatusEffect(this.player, t"GameplayRestriction.BlockFastTravel");

        let tier: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.HighLevel);
        let scene: Bool = tier >= EnumInt(gamePSMHighLevel.SceneTier3) && tier <= EnumInt(gamePSMHighLevel.SceneTier5);

        // ── Character-record checks  ──────────────────────────────

        // VR Tutorial opening: player is embodying the q000 VR stand-in character
        let isVRTutorial: Bool = this.immunityVRTutorialON
                               && Equals(controlledObjRecordID, t"Character.q000_vr_replacer");

        // Johnny Silverhand possession sequences
        let isJohnnyPossession: Bool = this.immunityJohnnyON
                                    && Equals(controlledObjRecordID, t"Character.johnny_replacer");

        // Kurt Hanssen impersonation sequences
        let isKurtHanssenImpersonation: Bool = this.immunityKurtHanssenON
                                             && Equals(controlledObjRecordID, t"Character.kurt_replacer");

        // Aguilar assassin impersonation sequences
        let isAguilarAssassinImpersonation: Bool = this.immunityAguilarAssassinON
                                                 && ( Equals(controlledObjRecordID, t"Character.mq304_assassin_replacer_male")
                                                 || Equals(controlledObjRecordID, t"Character.mq304_assassin_replacer_female") );

        // ── Quest-fact checks ────────────────────────────────────────────────

        // Corpo lifepath: Arasaka UI is active during the intro boardroom scene
        // Confirmed working fact.
        let isCorpoIntro: Bool = this.immunityCorpoIntroON
                               && qs.GetFact(n"q000_var_arasaka_ui_on") >= 1;

        // Nomad lifepath prologue: lifepath flag is set but The Rescue (q001) has not yet started.
        let isNomadPrologue: Bool = this.immunityNomadPrologueON
                                  && qs.GetFact(n"q000_nomad") >= 1
                                  && qs.GetFact(n"q001_active") < 1;

        // Street Kid lifepath prologue: lifepath flag is set but The Rescue (q001) has not yet started.
        let isStreetKidPrologue: Bool = this.immunityStreetKidPrologueON
                                      && qs.GetFact(n"q000_street_kid") >= 1
                                      && qs.GetFact(n"q001_active") < 1;

        // The Rescue: digital-sickness / wakeup sequence.
        // Active while q001 is running AND Viktor's ripperdoc visit is not yet done.
        // q001_active is a confirmed working fact; q001_digital_sickness may not fire
        // on all save states, so we use the ripperdoc gate as a broader guard.
        let isRescueScene: Bool = this.immunityRescueSceneON
                                && qs.GetFact(n"q001_active") >= 1
                                && qs.GetFact(n"q001_aft_maxtac_scene") < 1
                                && qs.GetFact(n"q001_aft_maxtac_scene_skip") < 1;

        // Cyberspace / net-dive sequences
        let isCyberspace: Bool = this.immunityCyberspaceON
                               && qs.GetFact(n"cyberspace_on") >= 1;

        // Braindance: check status-effect tag first (confirmed working), then
        // the BraindanceSystem flag as a fallback (not independently verified).
        let isBraindance: Bool = this.immunityBraindanceON
                               && (StatusEffectSystem.ObjectHasStatusEffectWithTag(this.player, n"Braindance")
                               || (IsDefined(bdSystem) && bdSystem.isInBraindance));

        // Car chase: active during high-speed vehicle sequences.  
        // let isCarChase: Bool = qs.GetFact(n"car_chase_on") >= 1;

        // V in Claire's car races 
        let isCarRace: Bool = this.immunityCarRaceON
                               && qs.GetFact(n"custom_race_started") >= 1;
                
        this.showDebugMessage("[CinematicImmunity] custom_race_started=" + qs.GetFact(n"custom_race_started"));


        // V in scene: active during specific in-game scenes, as determined by the high-level state machine tier.
        // Disabled for now, as it is too restrictive and prevents teleporting if combat is still ongoing after a scene ends.  Will need to find a better way to check for combat state.
        // let isInScene: Bool = this.immunityInSceneON
        //                           && (scene || noTimeSkip || noFastTravel);

        // ── Story-specific narrow windows ────────────────────────────────────

        // The Heist escape: from the moment V boards the Delamain for the getaway
        // (q005_ride_to_notell, set in q005_07_garage.questphase when the garage
        // car-chase escape begins and the ride to No Tell Motel starts) until the
        // quest concludes (q005_done confirmed).
        let isHeistEscape: Bool = this.immunityHeistEscapeON
                                && qs.GetFact(n"q005_ride_to_notell") >= 1
                                && qs.GetFact(n"q005_done") < 1;

        // Act 1 → Act 2 transition: No Tell Motel through the H10 apartment scene
        // with Johnny, until V reaches the pills in the H10 apartment.
        // q005_done is confirmed working.
        // Primary end gate: q101_v_reached_pills fires in q101_07c_johnny_triggers.scene
        // when V physically reaches the pills (early in the apartment wakeup scene).
        // Backup end gate: q101_08_takemura_hmm fires in q101_08_takemura_v_room.scene
        // (Takemura's phone call, a separate scene), in case the primary does not fire.
        // Immunity lifts as soon as either fact is set.
        let isActTransition: Bool = this.immunityActTransitionON
                                 && qs.GetFact(n"q005_done") >= 1
                                 && qs.GetFact(n"q101_v_reached_pills") < 1
                                 && qs.GetFact(n"q101_08_takemura_hmm") < 1;

        // Force disable Heist escape and Act transition immunity in Phantom Liberty standalone mode, since those sequences are not present in that version of the game.
        if isPhantomLibertyStandalone {
            isHeistEscape = false;
            isActTransition = false;
        }

        // Chimera chase: active during the Chimera chase sequence.
        let isChimeraChase: Bool = this.immunityChimeraChaseON
                               && (
                                qs.GetFact(n"chimera_phase1_fact") >= 1
                                || qs.GetFact(n"chimera_phase2_fact") >= 1
                                || qs.GetFact(n"chimera_phase3_fact") >= 1
                               )
                               && qs.GetFact(n"chimera_defeated") < 1;

        // this.showDebugMessage("[CinematicImmunity] q005_done=" + qs.GetFact(n"q005_done"));
        // this.showDebugMessage("[CinematicImmunity] q101_v_reached_pills=" + qs.GetFact(n"q101_v_reached_pills"));
        // this.showDebugMessage("[CinematicImmunity] q101_08_takemura_hmm=" + qs.GetFact(n"q101_08_takemura_hmm"));

        // (Don't Fear) The Reaper: V assaults Arasaka Tower in q115.
        // Covers both the Rogue-assisted ending and the solo DFTR variant.
        // q115_started / q115_done follow the same naming pattern as
        // q305_started / q305_done confirmed in SantaMuerte.reds.
        let isDontFearTheReaper: Bool = this.immunityDFTRON
                                     && qs.GetFact(n"q115_started") >= 1
                                     && qs.GetFact(n"q115_done") < 1;

        // Riders on the Storm: car chase after rescuing Saul from the Raffen Shiv camp.
        // sq004_saul_rescued is set the moment Saul is freed (sq004_03_raffen_shiv_camp phase).
        // sq004_no_chase is a branch flag set when the chase is skipped; guard against it.
        // sq004_chase_done is set at the end of sq004_07_chase.scene when the van escape concludes.
        let isPanamChase: Bool = this.immunityPanamChaseON
                               && qs.GetFact(n"sq004_saul_rescued") >= 1
                               && qs.GetFact(n"sq004_no_chase") < 1
                               && qs.GetFact(n"sq004_chase_done") < 1;

        // ── Decision ─────────────────────────────────────────────────────────

        this.showDebugMessage("[CinematicImmunity] -----");
        this.showDebugMessage("[CinematicImmunity] isVRTutorial=" + BoolToString(isVRTutorial));
        this.showDebugMessage("[CinematicImmunity] isJohnnyPossession=" + BoolToString(isJohnnyPossession));
        this.showDebugMessage("[CinematicImmunity] isCorpoIntro=" + BoolToString(isCorpoIntro));
        this.showDebugMessage("[CinematicImmunity] isNomadPrologue=" + BoolToString(isNomadPrologue));
        this.showDebugMessage("[CinematicImmunity] isStreetKidPrologue=" + BoolToString(isStreetKidPrologue));
        this.showDebugMessage("[CinematicImmunity] isRescueScene=" + BoolToString(isRescueScene));
        this.showDebugMessage("[CinematicImmunity] isCyberspace=" + BoolToString(isCyberspace));
        this.showDebugMessage("[CinematicImmunity] isBraindance=" + BoolToString(isBraindance));
        // this.showDebugMessage("[CinematicImmunity] isInScene=" + BoolToString(isInScene));
        this.showDebugMessage("[CinematicImmunity] isHeistEscape=" + BoolToString(isHeistEscape));
        this.showDebugMessage("[CinematicImmunity] isActTransition=" + BoolToString(isActTransition));
        this.showDebugMessage("[CinematicImmunity] isDontFearTheReaper=" + BoolToString(isDontFearTheReaper));
        this.showDebugMessage("[CinematicImmunity] isPanamChase=" + BoolToString(isPanamChase));
        this.showDebugMessage("[CinematicImmunity] isCarRace=" + BoolToString(isCarRace));
        this.showDebugMessage("[CinematicImmunity] isChimeraChase=" + BoolToString(isChimeraChase));
        

        let shouldBeImmune: Bool = isVRTutorial
                                || isJohnnyPossession
                                || isCorpoIntro
                                || isNomadPrologue
                                || isStreetKidPrologue
                                || isRescueScene
                                || isCyberspace
                                || isBraindance
                                || isHeistEscape
                                || isActTransition
                                || isDontFearTheReaper
                                || isCarRace
                                || isChimeraChase
                                || isPanamChase;

        this.showDebugMessage("[CinematicImmunity] shouldBeImmune=" + BoolToString(shouldBeImmune));

        if shouldBeImmune && !this.immunityActive {
            this.applyImmunity();
        } else if !shouldBeImmune && this.immunityActive {
            this.removeImmunity();
        }
    }

    public func applyImmunity() -> Void {
        if !IsDefined(this.player) {
            return;
        } 

        GameInstance.GetGodModeSystem(this.player.GetGame()).AddGodMode(
            this.player.GetEntityID(),
            gameGodModeType.Invulnerable,
            n"TimeSkip"
        );
        GameInstance.GetStatusEffectSystem(this.player.GetGame()).ApplyStatusEffect(
            this.player.GetEntityID(),
            t"BaseStatusEffect.Invulnerable"
        );
        this.immunityActive = true;
        GameInstance.GetQuestsSystem(this.player.GetGame()).SetFactStr("ConditionalImmunityStatus", 1);
        this.showDebugMessage("[CinematicImmunity] Invulnerability granted.");
    }

    public func removeImmunity() -> Void {
        if !IsDefined(this.player) {
            return;
        } 

        GameInstance.GetGodModeSystem(this.player.GetGame()).RemoveGodMode(
            this.player.GetEntityID(),
            gameGodModeType.Invulnerable,
            n"TimeSkip"
        );
        GameInstance.GetStatusEffectSystem(this.player.GetGame()).RemoveStatusEffect(
            this.player.GetEntityID(),
            t"BaseStatusEffect.Invulnerable"
        );
        this.immunityActive = false;
        GameInstance.GetQuestsSystem(this.player.GetGame()).SetFactStr("ConditionalImmunityStatus", 0);
        this.showDebugMessage("[CinematicImmunity] Invulnerability removed.");
    }

    private func showDebugMessage(debugMessage: String) {
       // LogChannel(n"DEBUG", debugMessage ); 
    }
}

// ── Heartbeat callback ───────────────────────────────────────────────────────

public class CinematicImmunityHeartbeatCallback extends DelayCallback {
    public let player: wref<PlayerPuppet>;
    public let sessionId: Uint32;

    public static func create() -> ref<CinematicImmunityHeartbeatCallback> {
        return new CinematicImmunityHeartbeatCallback();
    }

    public func init(player: wref<PlayerPuppet>) -> Void {
        this.player = player;
    }

    public func startHeartbeat(player: wref<PlayerPuppet>, sessionId: Uint32) -> Void {
        let ps: ref<PlayerPuppetPS> = this.player.GetPS();
        this.sessionId = sessionId;

        if ps.m_cinematicImmunity.heartbeatRunning {
            let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(GetGameInstance());
            delaySystem.DelayCallback(this, 5.0, false);
        }
    }

    public func Call() -> Void {
        let ps: ref<PlayerPuppetPS> = this.player.GetPS();
        let immunity: ref<CinematicImmunity> = ps.m_cinematicImmunity;

        if !IsDefined(immunity) {
            return;
        }

        if !immunity.heartbeatRunning || this.sessionId != immunity.heartbeatSessionId {
            return;
        }

        immunity.refresh();

        if immunity.heartbeatRunning && this.sessionId == immunity.heartbeatSessionId {
            let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(GetGameInstance());
            delaySystem.DelayCallback(this, 5.0, false);
        }
    }

}
