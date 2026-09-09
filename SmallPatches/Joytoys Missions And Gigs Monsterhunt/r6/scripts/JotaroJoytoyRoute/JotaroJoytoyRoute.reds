// Joytoys Missions and Gigs: Monsterhunt - Ho-Oh / Jotaro infiltration bridge.
// The encounter uses an embedded CET/Codeware scene director and has no
// Negotiable Affection, JoytoysOfNightCity, or vanilla quest-scene dependency.
// FreeFly is used only by the CET scene-view adapter.

@if(ModuleExists("Codeware"))
public class JJR_EmbeddedSceneEntityService extends ScriptableService {
  private func Initialize() {
    GameInstance.GetCallbackSystem().RegisterCallback(n"Entity/Initialize", this, n"OnAssemble");
    GameInstance.GetCallbackSystem().RegisterCallback(n"Entity/Attached", this, n"OnAttached");
  }

  private cb func OnAssemble(event: ref<EntityLifecycleEvent>) {}
  private cb func OnAttached(event: ref<EntityLifecycleEvent>) {}
}

public class JJR_RouteBridge extends ScriptableSystem {
  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) {
    let qs = GameInstance.GetQuestsSystem(request.owner.GetGame());
    if !IsDefined(qs) { return; };

    qs.RegisterListener(n"kab_07_enemies_alerted", this, n"OnEnemiesAlerted");
    qs.RegisterListener(n"kab_07_jotaro_killed", this, n"OnJotaroKilled");
    qs.RegisterListener(n"kab_07_done", this, n"OnGigEnded");
    qs.RegisterListener(n"kab_07_finished", this, n"OnGigEnded");
    qs.RegisterListener(n"kab_07_failed", this, n"OnGigEnded");

    let routeState = qs.GetFact(n"jjr_jotaro_joytoy_route_state");
    if qs.GetFact(n"jjr_jotaro_truce_active") > 0 {
      if qs.GetFact(n"kab_07_jotaro_killed") > 0
        || qs.GetFact(n"kab_07_done") > 0
        || qs.GetFact(n"kab_07_finished") > 0
        || qs.GetFact(n"kab_07_failed") > 0
        || routeState == 0 {
        this.EndInfiltration();
      } else {
        this.MaintainInfiltration();
      };
    };
  }

  public static func GetInstance(game: GameInstance) -> ref<JJR_RouteBridge> {
    return game.GetScriptableSystemsContainer().Get(n"JJR_RouteBridge") as JJR_RouteBridge;
  }

  public func StartSceneMoaning(playerID: EntityID, partnerID: EntityID, femaleV: Bool, partnerOnly: Bool) -> Bool {
    let audio = GameInstance.GetAudioSystem(this.GetGameInstance());
    if !IsDefined(audio) { return false; };

    if !partnerOnly {
      audio.Switch(
        n"lizzies_bds_sg_moaning_type",
        femaleV ? n"lizzies_bds_sw_moaning_female_01" : n"lizzies_bds_sw_moaning_male_01",
        playerID
      );
      audio.Play(n"lizzies_bds_moaning_open_long", playerID);
    };
    audio.Switch(n"lizzies_bds_sg_moaning_type", n"lizzies_bds_sw_moaning_male_02", partnerID);
    audio.Play(n"lizzies_bds_moaning_shut_long", partnerID);
    return true;
  }

  public func ContinueSceneMoaning(playerID: EntityID, partnerID: EntityID, partnerOnly: Bool) -> Void {
    let audio = GameInstance.GetAudioSystem(this.GetGameInstance());
    if !IsDefined(audio) { return; };
    if !partnerOnly {
      audio.Play(n"lizzies_bds_moaning_shut_short", playerID);
    };
    audio.Play(n"lizzies_bds_moaning_open_short", partnerID);
  }

  public func StopSceneMoaning(playerID: EntityID, partnerID: EntityID) -> Void {
    let audio = GameInstance.GetAudioSystem(this.GetGameInstance());
    if !IsDefined(audio) { return; };
    audio.Switch(n"lizzies_bds_sg_moaning_type", n"lizzies_bds_sw_moaning_off", playerID);
    audio.Switch(n"lizzies_bds_sg_moaning_type", n"lizzies_bds_sw_moaning_off", partnerID);
  }

  public func CanStart() -> Bool {
    let game = this.GetGameInstance();
    let qs = GameInstance.GetQuestsSystem(game);
    if !IsDefined(qs) { return false; };
    if qs.GetFact(n"nif_scene_active") > 0
      || qs.GetFact(n"jjr_scene_start_signal") > 0 {
      return false;
    };
    return true;
  }

  public func BeginInfiltration() -> Bool {
    let game = this.GetGameInstance();
    let qs = GameInstance.GetQuestsSystem(game);
    let attSystem = GameInstance.GetAttitudeSystem(game);
    if !IsDefined(qs) || !IsDefined(attSystem) { return false; };

    if qs.GetFact(n"jjr_jotaro_truce_active") == 0 {
      let previous = attSystem.GetAttitudeRelation(n"TygerClaws", n"player");
      qs.SetFact(n"jjr_jotaro_previous_tyger_attitude", EnumInt(previous));
      qs.SetFact(n"jjr_jotaro_truce_active", 1);
    };

    this.MaintainInfiltration();
    return true;
  }

  public func MaintainInfiltration() -> Void {
    let game = this.GetGameInstance();
    let qs = GameInstance.GetQuestsSystem(game);
    let attSystem = GameInstance.GetAttitudeSystem(game);
    if !IsDefined(qs) || !IsDefined(attSystem)
      || qs.GetFact(n"jjr_jotaro_truce_active") == 0 { return; };

    if qs.GetFact(n"kab_07_jotaro_killed") > 0
      || qs.GetFact(n"kab_07_done") > 0
      || qs.GetFact(n"kab_07_finished") > 0
      || qs.GetFact(n"kab_07_failed") > 0 {
      this.EndInfiltration();
      return;
    };

    attSystem.SetAttitudeRelation(n"TygerClaws", n"player", EAIAttitude.AIA_Friendly);

    // Keep the gig's combat branch closed for the whole undercover route. The
    // old implementation tried to reset this only after a trespass teleport;
    // this build never performs that teleport and also reconciles the fact on
    // every update while the truce is active.
    if qs.GetFact(n"kab_07_enemies_alerted") > 0 {
      qs.SetFact(n"kab_07_enemies_alerted", 0);
    };
  }

  public func EndInfiltration() -> Void {
    let game = this.GetGameInstance();
    let qs = GameInstance.GetQuestsSystem(game);
    let attSystem = GameInstance.GetAttitudeSystem(game);
    if !IsDefined(qs) { return; };

    if qs.GetFact(n"jjr_jotaro_truce_active") > 0 && IsDefined(attSystem) {
      let previous = IntEnum<EAIAttitude>(qs.GetFact(n"jjr_jotaro_previous_tyger_attitude"));
      attSystem.SetAttitudeRelation(n"TygerClaws", n"player", previous);
    };

    qs.SetFact(n"jjr_jotaro_truce_active", 0);
    qs.SetFact(n"jjr_jotaro_previous_tyger_attitude", 0);
  }

  public cb func OnEnemiesAlerted(value: Int32) -> Bool {
    if value > 0 { this.MaintainInfiltration(); };
    return true;
  }

  public cb func OnJotaroKilled(value: Int32) -> Bool {
    if value > 0 { this.EndInfiltration(); };
    return true;
  }

  public cb func OnGigEnded(value: Int32) -> Bool {
    if value > 0 { this.EndInfiltration(); };
    return true;
  }
}
