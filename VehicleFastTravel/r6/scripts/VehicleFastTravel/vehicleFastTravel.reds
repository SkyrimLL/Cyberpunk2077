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
    this.reset(player);
  }

  private func reset(player: wref<PlayerPuppet>) -> Void {
    this.player = player;

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



/* public class DriveEvents extends VehicleEventsTransition {

  Idea 1
  
  1- Create function to display Fast Travel menu (instead of always blocked)
  2- Create event to display menu remotely
  3- OnEnter event -> Get Vehicle record -> Get Model name -> If Delamain, trigger fast travel menu with event
      Crash if OnEnter method override

  Idea 2

  If in Delamain, override Radio with Fast Travel menu

  */

