// Joytoys Missions and Gigs: Playing for Keeps undercover route.
// The route reads vanilla lch_05 facts but never advances or completes them.

import NightlyNow.Holo.*

public func PFK_ReginaContactHash() -> Int32 = 407240205

public func PFK_ReginaTipText() -> String {
  return "V, did some digging. My netrunners have uncovered that the manager at Kashuu Hanten has arranged an anonymous online hookup during his shift for him and his goons with a Joytoy using the username KabukiRose. Could be a way into the back office under cover. Your call.";
}

public func PFK_ReginaAcknowledgementText() -> String {
  return "Thanks for the heads up.";
}

public func PFK_ReginaFollowUpText() -> String {
  return "Remember V. If you go with this route he thinks he's meeting KabukiRose, so play the part of a joytoy not a merc.";
}

public func PFK_VFollowUpText() -> String {
  return "Understood.";
}

public class PFK_ReginaJonesContact extends ContactHandler {
  private let player: wref<PlayerPuppet>;
  private let messenger: wref<MessengerDialogViewController>;

  public func Init(player: ref<PlayerPuppet>) -> Void {
    this.player = player;
  }

  public func GetHash() -> Int32 = PFK_ReginaContactHash()

  private func GetHoloSystem() -> ref<HoloSystem> {
    if !IsDefined(this.player) { return null; };
    return HoloSystem.Get(this.player);
  }

  private func MarkThreadRead() -> Void {
    let holo = this.GetHoloSystem();
    if IsDefined(holo) { holo.MarkContactRead(this.GetHash()); };
  }

  // The acknowledgement fact controls route eligibility. NightlyNow's own
  // persistent read set controls the badge while the unanswered tip is open.
  public func HasPendingMessages() -> Bool {
    if !this.TipSent() || this.TipAcknowledged() { return false; };
    let holo = this.GetHoloSystem();
    return !IsDefined(holo) || holo.HasPendingMessages(this.GetHash());
  }

  public func AlwaysTop() -> Bool = this.HasPendingMessages()

  private func TipSent() -> Bool {
    if !IsDefined(this.player) { return false; };
    let qs = GameInstance.GetQuestsSystem(this.player.GetGame());
    return IsDefined(qs) && qs.GetFact(n"pfk_regina_tip_sent") > 0;
  }

  private func TipAcknowledged() -> Bool {
    if !IsDefined(this.player) { return false; };
    let qs = GameInstance.GetQuestsSystem(this.player.GetGame());
    return IsDefined(qs) && qs.GetFact(n"pfk_regina_tip_acknowledged") > 0;
  }

  public func CreateContactData(forMessages: Bool) -> ref<ContactData> {
    if !this.TipSent() { return null; };
    let acknowledged = this.TipAcknowledged();
    let unread = this.HasPendingMessages();
    let data = new ContactData();
    data.hash = this.GetHash();
    data.localizedName = "Regina Jones";
    data.contactId = s"PFK_ReginaJones";
    data.id = s"PFK_REGINA_JONES";
    data.avatarID = t"PhoneAvatars.Avatar_Unknown";
    // Keep the lead visibly active until V acknowledges it. After the reply it
    // becomes an ordinary read NightlyNow thread, so it drops out of the active
    // Messages list instead of retaining the yellow quest exclamation mark.
    data.questRelated = !acknowledged;
    data.isCallable = false;
    data.type = forMessages ? MessengerContactType.SingleThread : MessengerContactType.Contact;
    data.lastMesssagePreview = acknowledged ? PFK_VFollowUpText() : PFK_ReginaTipText();
    data.messagesCount = acknowledged ? 4 : 1;
    data.hasMessages = true;
    data.playerIsLastSender = acknowledged;
    data.playerCanReply = !acknowledged;
    if forMessages {
      data.unreadMessegeCount = unread ? 1 : 0;
      if unread {
        ArrayInsert(data.unreadMessages, 0, 1);
      } else {
        ArrayClear(data.unreadMessages);
      };
    };
    return data;
  }

  public func OnDialogOpen(messenger: wref<MessengerDialogViewController>) -> Bool {
    if !this.TipSent() { return false; };
    this.messenger = messenger;
    messenger.ClearMessages();
    messenger.ClearReplies();
    messenger.AddMessage(PFK_ReginaTipText(), MessageViewType.Received, "Regina Jones", false);
    if this.TipAcknowledged() {
      messenger.AddMessage(PFK_ReginaAcknowledgementText(), MessageViewType.Sent, "V", false);
      messenger.AddMessage(PFK_ReginaFollowUpText(), MessageViewType.Received, "Regina Jones", false);
      messenger.AddMessage(PFK_VFollowUpText(), MessageViewType.Sent, "V", false);
    } else {
      messenger.AddReply(1, PFK_ReginaAcknowledgementText(), false, true, true);
    };
    this.MarkThreadRead();
    return true;
  }

  public func OnReplySelected(replyId: Int32) -> Void {
    if replyId != 1 || !IsDefined(this.player) { return; };
    let qs = GameInstance.GetQuestsSystem(this.player.GetGame());
    if !IsDefined(qs) { return; };
    qs.SetFact(n"pfk_regina_tip_acknowledged", 1);
    if IsDefined(this.messenger) {
      this.messenger.ClearReplies();
      this.messenger.AddMessage(PFK_ReginaAcknowledgementText(), MessageViewType.Sent, "V", false);
      this.messenger.AddMessage(PFK_ReginaFollowUpText(), MessageViewType.Received, "Regina Jones", false);
      this.messenger.AddMessage(PFK_VFollowUpText(), MessageViewType.Sent, "V", true);
    };
    // Use the player retained by this handler. ContactHandler.SetRead() tries
    // to resolve the player from the HUD, which is not reliable in this reply
    // callback on every NightlyNow build.
    this.MarkThreadRead();
  }
}

@addField(NewHudPhoneGameController)
private let pfkReginaContact: ref<PFK_ReginaJonesContact>;

@wrapMethod(NewHudPhoneGameController)
protected cb func OnInitialize() -> Bool {
  let result = wrappedMethod();
  let player = this.GetPlayerControlledObject() as PlayerPuppet;
  if !IsDefined(player) { return result; };
  let holo = HoloSystem.Get(player);
  if IsDefined(holo) {
    this.pfkReginaContact = new PFK_ReginaJonesContact();
    this.pfkReginaContact.Init(player);
    holo.AddContact(this.pfkReginaContact);
  };
  let bridge = PFK_RouteBridge.GetInstance(player.GetGame());
  if IsDefined(bridge) {
    bridge.SetReginaTipPlayer(player);
    bridge.TrySendReginaTip();
  };
  return result;
}

@wrapMethod(NewHudPhoneGameController)
protected cb func OnUninitialize() -> Bool {
  let player = this.GetPlayerControlledObject() as PlayerPuppet;
  if IsDefined(player) {
    let holo = HoloSystem.Get(player);
    if IsDefined(holo) && IsDefined(this.pfkReginaContact) {
      holo.RemoveContact(this.pfkReginaContact);
    };
  };
  this.pfkReginaContact = null;
  return wrappedMethod();
}

@if(ModuleExists("Codeware"))
public class PFK_EmbeddedSceneEntityService extends ScriptableService {
  private func Initialize() {
    GameInstance.GetCallbackSystem().RegisterCallback(n"Entity/Initialize", this, n"OnAssemble");
    GameInstance.GetCallbackSystem().RegisterCallback(n"Entity/Attached", this, n"OnAttached");
  }

  private cb func OnAssemble(event: ref<EntityLifecycleEvent>) {}
  private cb func OnAttached(event: ref<EntityLifecycleEvent>) {}
}

public class PFK_RouteBridge extends ScriptableSystem {
  private let reginaTipPlayer: wref<PlayerPuppet>;

  private func OnPlayerAttach(request: ref<PlayerAttachRequest>) {
    let qs = GameInstance.GetQuestsSystem(request.owner.GetGame());
    if !IsDefined(qs) { return; };

    qs.RegisterListener(n"lch_05_start", this, n"OnGigStarted");
    qs.RegisterListener(n"lch_05_finished", this, n"OnRouteInvalidated");
    qs.RegisterListener(n"lch_05_alarm", this, n"OnRouteInvalidated");
    qs.RegisterListener(n"lch_05_combat_started", this, n"OnRouteInvalidated");
    this.SetReginaTipPlayer(request.owner as PlayerPuppet);
    this.TrySendReginaTip();

    if qs.GetFact(n"pfk_tyger_truce_active") > 0 {
      if qs.GetFact(n"pfk_joytoy_route_state") == 0
        || qs.GetFact(n"lch_05_finished") > 0 {
        this.EndInfiltration();
      } else {
        this.MaintainInfiltration();
      };
    };
  }

  public static func GetInstance(game: GameInstance) -> ref<PFK_RouteBridge> {
    return game.GetScriptableSystemsContainer().Get(n"PFK_RouteBridge") as PFK_RouteBridge;
  }

  public func GetSecurityAreaType(areaID: PersistentID) -> Int32 {
    let persistency = GameInstance.GetPersistencySystem(this.GetGameInstance());
    if !IsDefined(persistency) { return -1; };
    let area = persistency.GetConstAccessToPSObject(
      areaID,
      n"SecurityAreaControllerPS"
    ) as SecurityAreaControllerPS;
    if !IsDefined(area) { return -1; };
    return EnumInt(area.GetSecurityAreaType());
  }

  public func SetSecurityAreaType(areaID: PersistentID, areaType: Int32) -> Bool {
    if areaType < EnumInt(ESecurityAreaType.DISABLED)
      || areaType > EnumInt(ESecurityAreaType.DANGEROUS) {
      return false;
    };
    let persistency = GameInstance.GetPersistencySystem(this.GetGameInstance());
    if !IsDefined(persistency) { return false; };
    let area = persistency.GetConstAccessToPSObject(
      areaID,
      n"SecurityAreaControllerPS"
    ) as SecurityAreaControllerPS;
    if !IsDefined(area) { return false; };

    let transition: AreaTypeTransition;
    transition.transitionTo = IntEnum<ESecurityAreaType>(areaType);
    transition.transitionMode = ETransitionMode.FORCED;
    let event = new QuestExecuteTransition();
    event.transition = transition;
    persistency.QueuePSEvent(areaID, n"SecurityAreaControllerPS", event);
    return true;
  }

  public func SetReginaTipPlayer(player: ref<PlayerPuppet>) -> Void {
    this.reginaTipPlayer = player;
  }

  public func TrySendReginaTip() -> Bool {
    if !IsDefined(this.reginaTipPlayer) { return false; };
    let game = this.reginaTipPlayer.GetGame();
    let qs = GameInstance.GetQuestsSystem(game);
    if !IsDefined(qs)
      || qs.GetFact(n"lch_05_start") == 0
      || qs.GetFact(n"lch_05_finished") > 0
      || qs.GetFact(n"lch_05_have_eye") > 0
      || qs.GetFact(n"lch_05_alarm") > 0
      || qs.GetFact(n"lch_05_combat_started") > 0
      || qs.GetFact(n"pfk_regina_tip_sent") > 0 {
      return false;
    };
    let holo = HoloSystem.Get(this.reginaTipPlayer);
    if !IsDefined(holo) { return false; };
    qs.SetFact(n"pfk_regina_tip_sent", 1);
    holo.SendPushNotification(PFK_ReginaContactHash(), "Regina Jones", PFK_ReginaTipText());
    return true;
  }

  public cb func OnGigStarted(value: Int32) -> Bool {
    if value > 0 { this.TrySendReginaTip(); };
    return true;
  }

  public func StartSceneMoaning(playerID: EntityID, partnerID: EntityID, femaleV: Bool, partnerFemale: Bool, partnerOnly: Bool) -> Bool {
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
    audio.Switch(
      n"lizzies_bds_sg_moaning_type",
      partnerFemale ? n"lizzies_bds_sw_moaning_female_01" : n"lizzies_bds_sw_moaning_male_02",
      partnerID
    );
    audio.Play(n"lizzies_bds_moaning_shut_long", partnerID);
    return true;
  }

  public func ContinueSceneMoaning(playerID: EntityID, partnerID: EntityID, partnerOnly: Bool) -> Void {
    let audio = GameInstance.GetAudioSystem(this.GetGameInstance());
    if !IsDefined(audio) { return; };
    if !partnerOnly { audio.Play(n"lizzies_bds_moaning_shut_short", playerID); };
    audio.Play(n"lizzies_bds_moaning_open_short", partnerID);
  }

  public func StopSceneMoaning(playerID: EntityID, partnerID: EntityID) -> Void {
    let audio = GameInstance.GetAudioSystem(this.GetGameInstance());
    if !IsDefined(audio) { return; };
    audio.Switch(n"lizzies_bds_sg_moaning_type", n"lizzies_bds_sw_moaning_off", playerID);
    audio.Switch(n"lizzies_bds_sg_moaning_type", n"lizzies_bds_sw_moaning_off", partnerID);
  }

  public func CanStart() -> Bool {
    let qs = GameInstance.GetQuestsSystem(this.GetGameInstance());
    if !IsDefined(qs) { return false; };
    return qs.GetFact(n"nif_scene_active") == 0
      && qs.GetFact(n"pfk_scene_start_signal") == 0;
  }

  public func BeginInfiltration() -> Bool {
    let game = this.GetGameInstance();
    let qs = GameInstance.GetQuestsSystem(game);
    let attitudes = GameInstance.GetAttitudeSystem(game);
    if !IsDefined(qs) || !IsDefined(attitudes) { return false; };

    if qs.GetFact(n"pfk_tyger_truce_active") == 0 {
      let previous = attitudes.GetAttitudeRelation(n"TygerClaws", n"player");
      qs.SetFact(n"pfk_previous_tyger_attitude", EnumInt(previous));
      qs.SetFact(n"pfk_tyger_truce_active", 1);
    };
    this.MaintainInfiltration();
    return qs.GetFact(n"pfk_tyger_truce_active") > 0;
  }

  public func MaintainInfiltration() -> Void {
    let game = this.GetGameInstance();
    let qs = GameInstance.GetQuestsSystem(game);
    let attitudes = GameInstance.GetAttitudeSystem(game);
    if !IsDefined(qs) || !IsDefined(attitudes)
      || qs.GetFact(n"pfk_tyger_truce_active") == 0 { return; };

    if qs.GetFact(n"pfk_joytoy_route_state") == 0
      || qs.GetFact(n"lch_05_finished") > 0 {
      this.EndInfiltration();
      return;
    };
    attitudes.SetAttitudeRelation(n"TygerClaws", n"player", EAIAttitude.AIA_Friendly);
    // The vanilla restricted-area entry can raise these facts even though the
    // manager has invited V inside. While this explicit cover route is active,
    // treat those automatic area reactions as false alarms.
    if qs.GetFact(n"lch_05_alarm") > 0 { qs.SetFact(n"lch_05_alarm", 0); };
    if qs.GetFact(n"lch_05_combat_started") > 0 { qs.SetFact(n"lch_05_combat_started", 0); };
  }

  public func EndInfiltration() -> Void {
    let game = this.GetGameInstance();
    let qs = GameInstance.GetQuestsSystem(game);
    let attitudes = GameInstance.GetAttitudeSystem(game);
    if !IsDefined(qs) { return; };

    if qs.GetFact(n"pfk_tyger_truce_active") > 0 && IsDefined(attitudes) {
      let previous = IntEnum<EAIAttitude>(qs.GetFact(n"pfk_previous_tyger_attitude"));
      attitudes.SetAttitudeRelation(n"TygerClaws", n"player", previous);
    };
    qs.SetFact(n"pfk_tyger_truce_active", 0);
    qs.SetFact(n"pfk_previous_tyger_attitude", 0);
  }

  public cb func OnRouteInvalidated(value: Int32) -> Bool {
    if value > 0 {
      let qs = GameInstance.GetQuestsSystem(this.GetGameInstance());
      if IsDefined(qs)
        && qs.GetFact(n"pfk_joytoy_route_state") > 0
        && qs.GetFact(n"lch_05_finished") == 0 {
        this.MaintainInfiltration();
      } else {
        this.EndInfiltration();
      };
    };
    return true;
  }
}
