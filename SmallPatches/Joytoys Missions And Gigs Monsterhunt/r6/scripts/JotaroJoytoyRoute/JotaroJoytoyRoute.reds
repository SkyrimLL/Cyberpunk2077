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
  private let m_lastLoggedAlerted: Bool;
  private let m_diagCounter: Int32;

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) {
    let qs = GameInstance.GetQuestsSystem(request.owner.GetGame());
    if !IsDefined(qs) { return; };

    // Log("[JoytoysMissionsAndGigs:Monsterhunt] OnPlayerAttach: registering quest fact listeners");
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
    // Log("[JoytoysMissionsAndGigs:Monsterhunt] BeginInfiltration: called");
    if !IsDefined(qs) || !IsDefined(attSystem) {
      // Log("[JoytoysMissionsAndGigs:Monsterhunt] BeginInfiltration: quest/attitude system unavailable, aborting");
      return false;
    };

    if qs.GetFact(n"jjr_jotaro_truce_active") == 0 {
      let previousTyger = attSystem.GetAttitudeRelation(n"TygerClaws", n"player");
      let previousKab07 = attSystem.GetAttitudeRelation(n"kab_07_Tyger_Claws", n"player");
      let previousOW = attSystem.GetAttitudeRelation(n"tygerClaws_ow", n"player");
      qs.SetFact(n"jjr_jotaro_previous_tyger_attitude", EnumInt(previousTyger));
      qs.SetFact(n"jjr_jotaro_previous_kab07_attitude", EnumInt(previousKab07));
      qs.SetFact(n"jjr_jotaro_previous_ow_attitude", EnumInt(previousOW));
      qs.SetFact(n"jjr_jotaro_truce_active", 1);
      // Log("[JoytoysMissionsAndGigs:Monsterhunt] BeginInfiltration: truce started, previous attitudes TygerClaws=" + ToString(EnumInt(previousTyger)) + " kab_07_Tyger_Claws=" + ToString(EnumInt(previousKab07)) + " tygerClaws_ow=" + ToString(EnumInt(previousOW)));
    } else {
      // Log("[JoytoysMissionsAndGigs:Monsterhunt] BeginInfiltration: truce already active, refreshing");
    };

    this.MaintainInfiltration();
    return true;
  }

  public func MaintainInfiltration() -> Void {
    let game = this.GetGameInstance();
    let qs = GameInstance.GetQuestsSystem(game);
    let attSystem = GameInstance.GetAttitudeSystem(game);
    if !IsDefined(qs) || !IsDefined(attSystem) {
      // Log("[JoytoysMissionsAndGigs:Monsterhunt] MaintainInfiltration: quest/attitude system unavailable");
      return;
    };
    if qs.GetFact(n"jjr_jotaro_truce_active") == 0 {
      // Log("[JoytoysMissionsAndGigs:Monsterhunt] MaintainInfiltration: truce not active, nothing to do");
      return;
    };

    if qs.GetFact(n"kab_07_jotaro_killed") > 0
      || qs.GetFact(n"kab_07_done") > 0
      || qs.GetFact(n"kab_07_finished") > 0
      || qs.GetFact(n"kab_07_failed") > 0 {
      // Log("[JoytoysMissionsAndGigs:Monsterhunt] MaintainInfiltration: gig ended, calling EndInfiltration");
      this.EndInfiltration();
      return;
    };

    // kab_07 NPCs are split across multiple attitude groups (the open-world
    // TygerClaws group plus quest-specific kab_07_Tyger_Claws/tygerClaws_ow
    // groups on the upper floors); all three must be forced Friendly.
    attSystem.SetAttitudeRelation(n"TygerClaws", n"player", EAIAttitude.AIA_Friendly);
    attSystem.SetAttitudeRelation(n"kab_07_Tyger_Claws", n"player", EAIAttitude.AIA_Friendly);
    attSystem.SetAttitudeRelation(n"tygerClaws_ow", n"player", EAIAttitude.AIA_Friendly);

    // Keep the gig's combat branch closed for the whole undercover route. The
    // old implementation tried to reset this only after a trespass teleport;
    // this build never performs that teleport and also reconciles the fact on
    // every update while the truce is active.
    let alerted = qs.GetFact(n"kab_07_enemies_alerted") > 0;
    if alerted && !this.m_lastLoggedAlerted {
      // Log("[JoytoysMissionsAndGigs:Monsterhunt] MaintainInfiltration: kab_07_enemies_alerted set, resetting fact and calming nearby TygerClaws");
    };
    this.m_lastLoggedAlerted = alerted;
    if alerted {
      qs.SetFact(n"kab_07_enemies_alerted", 0);
      // Resetting the fact/attitude relation alone doesn't undo an NPC that the
      // vanilla combat questphase already pushed into Alerted/Combat this frame.
      this.CalmNearbyTygerClaws(game);
    };

    // Unconditional periodic heartbeat so we have proof this is actually being
    // called every poll, even when nothing is alerted (success path was silent).
    this.m_diagCounter += 1;
    if this.m_diagCounter % 10 == 1 {
      // Log("[JoytoysMissionsAndGigs:Monsterhunt] MaintainInfiltration: truce active, TygerClaws groups forced Friendly (call #" + ToString(this.m_diagCounter) + ")");
      this.LogNearbyAttitudes(game);
    };
  }

  private func GetNearbyPuppets(game: GameInstance, source: ref<GameObject>) -> array<ref<ScriptedPuppet>> {
    let result: array<ref<ScriptedPuppet>>;
    let searchQuery: TargetSearchQuery;
    let parts: array<TS_TargetPartInfo>;
    searchQuery.testedSet = TargetingSet.Complete;
    searchQuery.searchFilter = TSF_And(TSF_All(TSFMV.Obj_Puppet), TSF_Not(TSFMV.Obj_Player));
    searchQuery.includeSecondaryTargets = false;
    searchQuery.maxDistance = 40.0;
    searchQuery.filterObjectByDistance = true;
    GameInstance.GetTargetingSystem(game).GetTargetParts(source, searchQuery, parts);

    let i = 0;
    while i < ArraySize(parts) {
      let component = TS_TargetPartInfo.GetComponent(parts[i]);
      let puppet = IsDefined(component) ? (component.GetEntity() as ScriptedPuppet) : null;
      if IsDefined(puppet) {
        ArrayPush(result, puppet);
      };
      i += 1;
    };
    return result;
  }

  private func IsTygerClawsGroup(group: CName) -> Bool {
    return Equals(group, n"TygerClaws") || Equals(group, n"kab_07_Tyger_Claws") || Equals(group, n"tygerClaws_ow");
  }

  private func CalmNearbyTygerClaws(game: GameInstance) -> Void {
    let player = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject();
    if !IsDefined(player) {
      // Log("[JoytoysMissionsAndGigs:Monsterhunt] CalmNearbyTygerClaws: local player unavailable");
      return;
    };

    let puppets = this.GetNearbyPuppets(game, player);
    let matched = 0;
    let changed = 0;
    let i = 0;
    while i < ArraySize(puppets) {
      let puppet = puppets[i];
      if IsDefined(puppet.GetAttitudeAgent()) && this.IsTygerClawsGroup(puppet.GetAttitudeAgent().GetAttitudeGroup()) {
        matched += 1;
        if NotEquals(puppet.GetHighLevelStateFromBlackboard(), gamedataNPCHighLevelState.Relaxed) {
          NPCPuppet.ChangeHighLevelState(puppet, gamedataNPCHighLevelState.Relaxed);
          changed += 1;
        };
      };
      i += 1;
    };
    // Log("[JoytoysMissionsAndGigs:Monsterhunt] CalmNearbyTygerClaws: scanned " + ToString(ArraySize(puppets)) + " puppets, " + ToString(matched) + " TygerClaws, " + ToString(changed) + " de-alerted");
  }

  // Dumps attitude group / relation / high-level state for every nearby NPC so
  // we can identify a hostility source that isn't the TygerClaws group or the
  // kab_07_enemies_alerted fact (e.g. upper-floor security or a distinct group).
  private func LogNearbyAttitudes(game: GameInstance) -> Void {
    let player = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject();
    if !IsDefined(player) { return; };

    let puppets = this.GetNearbyPuppets(game, player);
    let i = 0;
    while i < ArraySize(puppets) {
      let puppet = puppets[i];
      let group = IsDefined(puppet.GetAttitudeAgent()) ? puppet.GetAttitudeAgent().GetAttitudeGroup() : n"<none>";
      let attitude = GameObject.GetAttitudeTowards(puppet, player);
      let hls = puppet.GetHighLevelStateFromBlackboard();
      // Log("[JoytoysMissionsAndGigs:Monsterhunt] NearbyNPC record=" + TDBID.ToStringDEBUG(puppet.GetRecordID()) + " group=" + NameToString(group) + " attitude=" + ToString(EnumInt(attitude)) + " highLevelState=" + ToString(EnumInt(hls)));
      i += 1;
    };
  }

  public func EndInfiltration() -> Void {
    let game = this.GetGameInstance();
    let qs = GameInstance.GetQuestsSystem(game);
    let attSystem = GameInstance.GetAttitudeSystem(game);
    let player = GameInstance.GetPlayerSystem(game).GetLocalPlayerMainGameObject();
    if !IsDefined(qs) { return; };

    // Log("[JoytoysMissionsAndGigs:Monsterhunt] EndInfiltration: truce_active=" + ToString(qs.GetFact(n"jjr_jotaro_truce_active")));
    if qs.GetFact(n"jjr_jotaro_truce_active") > 0 && IsDefined(attSystem) {
      attSystem.SetAttitudeRelation(n"TygerClaws", n"player", IntEnum<EAIAttitude>(qs.GetFact(n"jjr_jotaro_previous_tyger_attitude")));
      attSystem.SetAttitudeRelation(n"kab_07_Tyger_Claws", n"player", IntEnum<EAIAttitude>(qs.GetFact(n"jjr_jotaro_previous_kab07_attitude")));
      attSystem.SetAttitudeRelation(n"tygerClaws_ow", n"player", IntEnum<EAIAttitude>(qs.GetFact(n"jjr_jotaro_previous_ow_attitude")));
    }; 

    qs.SetFact(n"jjr_jotaro_truce_active", 0);
    qs.SetFact(n"jjr_jotaro_previous_tyger_attitude", 0);
    qs.SetFact(n"jjr_jotaro_previous_kab07_attitude", 0);
    qs.SetFact(n"jjr_jotaro_previous_ow_attitude", 0);
  }

  public cb func OnEnemiesAlerted(value: Int32) -> Bool {
    // Log("[JoytoysMissionsAndGigs:Monsterhunt] OnEnemiesAlerted listener fired, value=" + ToString(value));
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
