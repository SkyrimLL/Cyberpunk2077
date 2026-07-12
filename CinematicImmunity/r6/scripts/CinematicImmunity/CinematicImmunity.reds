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
    public let immunityCorpoIntroON: Bool;
    public let immunityNomadSKPrologueON: Bool;
    public let immunityRescueSceneON: Bool;
    public let immunityCyberspaceON: Bool;
    public let immunityBraindanceON: Bool;
    public let immunityInSceneON: Bool;
    public let immunityHeistEscapeON: Bool;
    public let immunityActTransitionON: Bool;
    public let immunityDFTRON: Bool;
    public let immunityPanamChaseON: Bool;

    public func init(player: wref<PlayerPuppet>) -> Void {
        this.reset(player);
    }

    public func reset(player: wref<PlayerPuppet>) -> Void {
        this.player = player;
        this.immunityActive = false;
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
        this.immunityCorpoIntroON    = this.config.immunityCorpoIntroON;
        this.immunityNomadSKPrologueON = this.config.immunityNomadSKPrologueON;
        this.immunityRescueSceneON   = this.config.immunityRescueSceneON;
        this.immunityCyberspaceON    = this.config.immunityCyberspaceON;
        this.immunityBraindanceON    = this.config.immunityBraindanceON;
        this.immunityInSceneON       = this.config.immunityInSceneON;
        this.immunityHeistEscapeON   = this.config.immunityHeistEscapeON;
        this.immunityActTransitionON = this.config.immunityActTransitionON;
        this.immunityDFTRON          = this.config.immunityDFTRON;
        this.immunityPanamChaseON    = this.config.immunityPanamChaseON;
    }

    public cb func OnModSettingsChange() -> Void {
        this.showDebugMessage("[CinematicImmunity] Settings changed – applying update.");
        this.refreshConfig();
        if !this.modON && this.immunityActive {
            this.removeImmunity();
        };
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
        this.refreshImmunity();
    }

    // Evaluate all scene conditions and apply / remove god-mode immunity as needed.
    public func refreshImmunity() -> Void {
        if !this.modON {
            if this.immunityActive { this.removeImmunity(); };
            return;
        };

        if !IsDefined(this.player) {
            return;
        }

        let qs: ref<QuestsSystem> = GameInstance.GetQuestsSystem(this.player.GetGame());
        let controlledObjRecordID: TweakDBID = this.player.GetRecord().GetID();
        let bdSystem: ref<BraindanceSystem> = GameInstance.GetScriptableSystemsContainer(this.player.GetGame()).Get(n"BraindanceSystem") as BraindanceSystem;
        let bb: ref<IBlackboard> = this.player.GetPlayerStateMachineBlackboard();


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

        // ── Quest-fact checks ────────────────────────────────────────────────

        // Corpo lifepath: Arasaka UI is active during the intro boardroom scene
        // Confirmed working fact.
        let isCorpoIntro: Bool = this.immunityCorpoIntroON
                               && qs.GetFact(n"q000_var_arasaka_ui_on") >= 1;

        // Nomad / Street Kid lifepath prologue: lifepath flag is set but The Rescue
        // (q001) has not yet started.  q000_nomad / q000_street_kid are set at the
        // very start of those prologues.
        let isNomadOrSKPrologue: Bool = this.immunityNomadSKPrologueON
                                      && (qs.GetFact(n"q000_nomad") >= 1
                                      || qs.GetFact(n"q000_street_kid") >= 1)
                                      && qs.GetFact(n"q001_active") < 1;

        // The Rescue: digital-sickness / wakeup sequence.
        // Active while q001 is running AND Viktor's ripperdoc visit is not yet done.
        // q001_active is a confirmed working fact; q001_digital_sickness may not fire
        // on all save states, so we use the ripperdoc gate as a broader guard.
        let isRescueScene: Bool = this.immunityRescueSceneON
                                && qs.GetFact(n"q001_active") >= 1
                                && qs.GetFact(n"q001_ripperdoc_done") < 1;

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

        // V in scene: active during specific in-game scenes, as determined by the high-level state machine tier.
        let isInScene: Bool = this.immunityInSceneON
                           && (scene || noTimeSkip || noFastTravel);

        // ── Story-specific narrow windows ────────────────────────────────────

        // The Heist escape: from the moment the Relic chip enters V's head (confirmed
        // working fact, perksMain.swift) until the quest concludes (q005_done confirmed).
        // Covers the Konpeki Plaza car chase and ride to No Tell Motel.
        let isHeistEscape: Bool = this.immunityHeistEscapeON
                                && qs.GetFact(n"q005_johnny_chip_acquired") >= 1
                                && qs.GetFact(n"q005_done") < 1;

        // Act 1 → Act 2 transition: No Tell Motel through the H10 apartment scene
        // with Johnny, until Playing for Time (q101) is tracked as active.
        // q005_done is confirmed working. q101_active mirrors the q001_active pattern.
        let isActTransition: Bool = this.immunityActTransitionON
                                 && qs.GetFact(n"q005_done") >= 1
                                 && qs.GetFact(n"q101_talking_to_johnny_end") < 1;

        this.showDebugMessage("[CinematicImmunity] q005_done=" + qs.GetFact(n"q005_done"));
        this.showDebugMessage("[CinematicImmunity] q101_talking_to_johnny_end=" + qs.GetFact(n"q101_talking_to_johnny_end"));

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
        this.showDebugMessage("[CinematicImmunity] isNomadOrSKPrologue=" + BoolToString(isNomadOrSKPrologue));
        this.showDebugMessage("[CinematicImmunity] isRescueScene=" + BoolToString(isRescueScene));
        this.showDebugMessage("[CinematicImmunity] isCyberspace=" + BoolToString(isCyberspace));
        this.showDebugMessage("[CinematicImmunity] isBraindance=" + BoolToString(isBraindance));
        this.showDebugMessage("[CinematicImmunity] isInScene=" + BoolToString(isInScene));
        this.showDebugMessage("[CinematicImmunity] isHeistEscape=" + BoolToString(isHeistEscape));
        this.showDebugMessage("[CinematicImmunity] isActTransition=" + BoolToString(isActTransition));
        this.showDebugMessage("[CinematicImmunity] isDontFearTheReaper=" + BoolToString(isDontFearTheReaper));
        this.showDebugMessage("[CinematicImmunity] isPanamChase=" + BoolToString(isPanamChase));

        let shouldBeImmune: Bool = isVRTutorial
                                || isJohnnyPossession
                                || isCorpoIntro
                                || isNomadOrSKPrologue
                                || isRescueScene
                                || isCyberspace
                                || isBraindance
                                || isInScene
                                || isHeistEscape
                                || isActTransition
                                || isDontFearTheReaper
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
