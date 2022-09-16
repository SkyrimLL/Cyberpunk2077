/*
For redscript mod developers

:: Replaced methods
@replaceMethod(DataTerm) private final func RequestFastTravelMenu() -> Void 
@replaceMethod(DataTerm) protected cb func OnAreaEnter(evt: ref<AreaEnteredEvent>) -> Bool 
@replaceMethod(PopupsManager) protected cb func OnQuickSlotButtonHoldStartEvent(evt: ref<QuickSlotButtonHoldStartEvent>) -> Bool 
@addMethod(PopupsManager) protected cb func OnTriggeredVehicleManagerEvent(evt: ref<TriggeredVehicleManagerEvent>) -> Bool 
@replaceMethod(PlayerPuppet) protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool 

:: Added fields
@addField(DataTerm) public let iVehicleMenuOpen: Bool = false;

:: New classes
public class VehicleFastTravelTracking
public class TriggeredVehicleManagerEvent extends Event
*/

public class VehicleFastTravelTracking {
  public let player: wref<PlayerPuppet>;
  public let enableVehicleRecallKeyON: Bool;
  public let enableVehicleMenuKeyON: Bool;

  public let debugON: Bool;
  public let warningsON: Bool;   

  public func init(player: wref<PlayerPuppet>) -> Void {
    this.player = player;
    this.reset();
  }

  private func reset() -> Void {
    // ------------------ Edit these values to configure the mod
    // Toggle warnings when exceeding your carry capacity without powerlevel bonus
    this.warningsON = true;

    // ------------------ End of Mod Options

    // For developers only 
    this.debugON = true;

    // To enable call vehicle key for emergencies
    this.enableVehicleRecallKeyON = false;

    // To enable vehicle menu key for emergencies (Hold)
    this.enableVehicleMenuKeyON = false;

  }
}

public class TriggeredVehicleManagerEvent extends Event {

  public let dPadItemDirection: EDPadSlot;
}


// public class DataTerm extends InteractiveDevice {
@addField(DataTerm)
public let iVehicleMenuOpen: Bool = false;

@replaceMethod(DataTerm)

  private final func RequestFastTravelMenu() -> Void {
    /* Patch - Disable fast travel menu -> replaced by call vehicle action
    this.UpdateFastTravelPointRecord();
    GameInstance.GetUISystem(this.GetGame()).RequestFastTravelMenu();
    */
    // LogChannel(n"DEBUG", ">>> Requesting fast travel menu - popup manager for vehicles should go here."  );

    let player: ref<GameObject> = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject();

    // trying with events system 
    if (this.iVehicleMenuOpen) {
        // necessary to prevent vehicle menu to open again when player confirms a vehicle (with same hotkey as key to open menu)
        this.iVehicleMenuOpen = false;

      } else {
        this.iVehicleMenuOpen = true;

        let evt: ref<TriggeredVehicleManagerEvent> = new TriggeredVehicleManagerEvent();
        evt.dPadItemDirection = EDPadSlot.VehicleWheel;
        player.QueueEvent(evt);
     
      }


  }

@replaceMethod(DataTerm)

  protected cb func OnAreaEnter(evt: ref<AreaEnteredEvent>) -> Bool {
    let activator: ref<GameObject>;
    return false;

    /* Patch - Fast travel disabled
    if NotEquals(evt.componentName, n"fastTravelArea") {
      return false;
    };
    if NotEquals(this.GetDevicePS().GetFastravelTriggerType(), EFastTravelTriggerType.Auto) {
      return false;
    };
    if this.m_linkedFastTravelPoint == null || IsDefined(this.m_linkedFastTravelPoint) && !this.m_linkedFastTravelPoint.IsValid() {
      return false;
    };
    if this.GetFastTravelSystem().IsFastTravelEnabledOnMap() {
      return false;
    };
    activator = EntityGameInterface.GetEntity(evt.activator) as GameObject;
    if activator.IsPlayer() {
      this.RequestFastTravelMenu();
      this.TeleportToExitNode(activator);
    };
    */
  }
 
// public native class PopupsManager extends inkGameController {
@addField(PopupsManager)
public let m_vehicleFasTravelTracking: ref<VehicleFastTravelTracking>;

@replaceMethod(PopupsManager)

  protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool {
    this.m_blackboard = this.GetUIBlackboard();
    this.m_bbDefinition = GetAllBlackboardDefs().UIGameData;
    this.m_journalManager = GameInstance.GetJournalManager(playerPuppet.GetGame());
    this.m_uiSystemBB = this.GetBlackboardSystem().Get(GetAllBlackboardDefs().UI_System);
    this.m_uiSystemBBDef = GetAllBlackboardDefs().UI_System;
    this.m_uiSystemId = this.m_uiSystemBB.RegisterListenerBool(this.m_uiSystemBBDef.IsInMenu, this, n"OnMenuUpdate");
    this.m_isShownBbId = this.m_blackboard.RegisterDelayedListenerBool(this.m_bbDefinition.Popup_IsShown, this, n"OnUpdateVisibility");
    this.m_dataBbId = this.m_blackboard.RegisterDelayedListenerVariant(this.m_bbDefinition.Popup_Data, this, n"OnUpdateData");
    this.m_photomodeActiveId = this.GetBlackboardSystem().Get(GetAllBlackboardDefs().PhotoMode).RegisterListenerBool(GetAllBlackboardDefs().PhotoMode.IsActive, this, n"OnPhotomodeUpdate");

    // set up tracker if it doesn't exist
    if !IsDefined(this.m_vehicleFasTravelTracking) {
      let m_player: wref<PlayerPuppet>;
      this.m_vehicleFasTravelTracking = new VehicleFastTravelTracking();
      this.m_vehicleFasTravelTracking.init(m_player);
    } else {
      // Reset if already exists (in case of changed default values)
      this.m_vehicleFasTravelTracking.reset();
    };
  }

@replaceMethod(PopupsManager)

  protected cb func OnQuickSlotButtonHoldStartEvent(evt: ref<QuickSlotButtonHoldStartEvent>) -> Bool {
    switch evt.dPadItemDirection {
      case EDPadSlot.VehicleWheel:
      /* Patch - disable popup menu on action key hold 
        this.SpawnVehiclesManagerPopup();
        */
        let m_player: wref<PlayerPuppet> = this.m_vehicleFasTravelTracking.player;
        let isVictorHUDInstalled: Int32 = GameInstance.GetQuestsSystem(m_player.GetGame()).GetFact(n"tutorial_ripperdoc_buy");

        if (isVictorHUDInstalled < 0) || (this.m_vehicleFasTravelTracking.enableVehicleMenuKeyON) {
            this.SpawnVehiclesManagerPopup();
        } else {
            this.SpawnVehicleRadioPopup();
            // m_player.SetWarningMessage("Hailing network out of range. Please use your nearest transport terminal.");  
        }
        
        break;
      case EDPadSlot.VehicleInsideWheel:
        this.SpawnVehicleRadioPopup();
        break;
      default:
    };
  }

@addMethod(PopupsManager)

  protected cb func OnTriggeredVehicleManagerEvent(evt: ref<TriggeredVehicleManagerEvent>) -> Bool {
    // Event is triggered by custom code on Data Terminals used for Fast Travel

    this.SpawnVehiclesManagerPopup();

  }

/*
  private final func SpawnVehiclesManagerPopup() -> Void {
    let data: ref<inkGameNotificationData> = new inkGameNotificationData();
    data.notificationName = n"base\\gameplay\\gui\\widgets\\vehicle_control\\vehicles_manager.inkwidget";
    data.queueName = n"VehiclesManager";
    data.isBlocking = false;
    this.m_vehiclesManagerToken = this.ShowGameNotification(data);
    this.m_vehiclesManagerToken.RegisterListener(this, n"OnVehiclesManagerCloseRequest");
  }
  */

// public class PlayerPuppet extends ScriptedPuppet {
@addField(PlayerPuppet)
public let m_vehicleFasTravelTracking: ref<VehicleFastTravelTracking>;

@replaceMethod(PlayerPuppet)

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    if Equals(ListenerAction.GetName(action), n"ToggleWalk") && ListenerAction.IsButtonJustReleased(action) {
      this.ProcessToggleWalkInput();
      return true;
    };
    if Equals(ListenerAction.GetName(action), n"IconicCyberware") {
      if Equals(ListenerAction.GetType(action), this.DeductGameInputActionType()) && !this.CanCycleLootData() {
        this.ActivateIconicCyberware();
      };
    } else {
      /* Patch - Disable call vehicle key -> replaced by fast travel action     */
      if Equals(ListenerAction.GetName(action), n"CallVehicle") {
        // set up tracker if it doesn't exist
        if !IsDefined(this.m_vehicleFasTravelTracking) {
          this.m_vehicleFasTravelTracking = new VehicleFastTravelTracking();
          this.m_vehicleFasTravelTracking.init(this);
          LogChannel(n"DEBUG", ">>> VehicleFastTravelTracking not found - initializing"  );
        } else {
          // Reset if already exists (in case of changed default values)
          this.m_vehicleFasTravelTracking.reset();
          LogChannel(n"DEBUG", ">>> VehicleFastTravelTracking found - resetting"  );
        };

        let isVictorHUDInstalled: Int32 = GameInstance.GetQuestsSystem(this.GetGame()).GetFact(n"tutorial_ripperdoc_buy");
        LogChannel(n"DEBUG", ">>> isVictorHUDInstalled: " + isVictorHUDInstalled  );

        if (isVictorHUDInstalled <= 0) || (this.m_vehicleFasTravelTracking.enableVehicleRecallKeyON) {
          if !GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).GetBool(GetAllBlackboardDefs().UI_PlayerStats.isReplacer) && Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_RELEASED) {
            this.ProcessCallVehicleAction(ListenerAction.GetType(action));
          };
        };        
      }

    };
  }


