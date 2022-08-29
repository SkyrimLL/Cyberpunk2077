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

:: New class
public class TriggeredVehicleManagerEvent extends Event
*/

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
    LogChannel(n"DEBUG", ">>> Requesting fast travel menu - popup manager for vehicles should go here."  );

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
@replaceMethod(PopupsManager)

  protected cb func OnQuickSlotButtonHoldStartEvent(evt: ref<QuickSlotButtonHoldStartEvent>) -> Bool {
    switch evt.dPadItemDirection {
      case EDPadSlot.VehicleWheel:
      /* Patch - disable popup menu on action key hold 
        this.SpawnVehiclesManagerPopup();
        */
        this.SpawnVehicleRadioPopup();
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
      /* Patch - Disable call vehicle key -> replaced by fast travel action 
      if Equals(ListenerAction.GetName(action), n"CallVehicle") {
        if !GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).GetBool(GetAllBlackboardDefs().UI_PlayerStats.isReplacer) && Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_RELEASED) {
          this.ProcessCallVehicleAction(ListenerAction.GetType(action));
        };
      };
      */
    };
  }


