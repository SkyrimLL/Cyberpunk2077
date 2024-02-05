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

public class VehicleFastTravelTracking extends ScriptedPuppetPS {
  public let player: wref<PlayerPuppet>;
  public let iVehicleMenuOpen: Bool;
  public let terminalEntityID: EntityID;

  public let config: ref<VehiclesFastTravelConfig>;

  public let modON: Bool; 
  public let malwareON: Bool; 
 
  public let chanceMalwareLow: Float;
  public let chanceMalwareMedium: Float;
  public let chanceMalwareHigh: Float;

  public let enableVehicleRecallKeyON: Bool;
  public let enableVehicleMenuKeyON: Bool;
  // public let disableMetroFastTravelON: Bool;

  public let debugON: Bool;
  public let warningsON: Bool;   



  public func init(player: wref<PlayerPuppet>) -> Void {
    this.reset(player);
  }

  private func reset(player: wref<PlayerPuppet>) -> Void {
    this.player = player;

    this.refreshConfig();

    // ------------------ Edit these values to configure the mod
    // Toggle warnings when exceeding your carry capacity without powerlevel bonus
    // this.warningsON = true;

    // ------------------ End of Mod Options

    // For developers only 
    // this.debugON = true;

    // To enable call vehicle key for emergencies
    // this.enableVehicleRecallKeyON = false;

    // To enable vehicle menu key for emergencies (Hold)
    // this.enableVehicleMenuKeyON = false;

  }

  public func refreshConfig() -> Void {
    this.config = new VehiclesFastTravelConfig(); 
    this.invalidateCurrentState();
  }

  public func invalidateCurrentState() -> Void {  
    this.malwareON = this.config.malwareON;
    this.chanceMalwareLow = Cast<Float>(this.config.chanceMalwareLow); 
    this.chanceMalwareMedium = Cast<Float>(this.config.chanceMalwareMedium); 
    this.chanceMalwareHigh = Cast<Float>(this.config.chanceMalwareHigh);   
 
    this.enableVehicleRecallKeyON = this.config.enableVehicleRecallKeyON;
    this.enableVehicleMenuKeyON = this.config.enableVehicleMenuKeyON;
    // this.disableMetroFastTravelON = this.config.disableMetroFastTravelON;

    this.warningsON = this.config.warningsON;
    this.debugON = this.config.debugON;
    this.modON = this.config.modON;  
  } 
}

public class TriggeredVehicleManagerEvent extends Event {

  public let dPadItemDirection: EDPadSlot;
}



/* public class DriveEvents extends VehicleEventsTransition {

  Idea 1
  
  1- Create function to display Fast Travel menu (instead of always blocked)
  2- Create event to display menu remotely
  3- OnEnter event -> Get Vehicle record -> Get Model name -> If Delamain, trigger fast travel menu with event
      Crash if OnEnter method override

  Idea 2

  If in Delamain, override Radio with Fast Travel menu

  */

