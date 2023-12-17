

 // public class VehicleComponent extends ScriptableDeviceComponent {
@replaceMethod(VehicleComponent) 

  private final func StealVehicle(opt slotID: MountingSlotId) -> Void {
    let stealEvent: ref<StealVehicleEvent>;
    let vehicleHijackEvent: ref<VehicleHijackEvent>;
    let vehicle: wref<VehicleObject> = this.GetVehicle();
    if !IsDefined(vehicle) {
      return;
    };
    if IsNameValid(slotID.id) {
      vehicleHijackEvent = new VehicleHijackEvent();
      VehicleComponent.QueueEventToPassenger(vehicle.GetGame(), vehicle, slotID, vehicleHijackEvent);
    };
    stealEvent = new StealVehicleEvent();
    vehicle.QueueEvent(stealEvent);

    // // LogChannel(n"DEBUG", "Player is stealing a vehicle");
    let playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetVehicle().GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;

    // set up tracker if it doesn't exist
    if !IsDefined(playerPuppet.m_claimedVehicleTracking) {
      playerPuppet.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      playerPuppet.m_claimedVehicleTracking.init(playerPuppet);
    } else {
      // Reset if already exists (in case of changed default values)
      playerPuppet.m_claimedVehicleTracking.reset(playerPuppet);
    };

    let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(playerPuppet.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    let isVehicleHackable: Bool = false;
    let chanceHack: Int32 = RandRange(0,99);
    let playerOnStealTrigger: Int32 = Cast<Int32>(100.0 - playerPuppet.m_claimedVehicleTracking.chanceOnSteal);
    let playerCarhackerLevel = playerDevSystem.GetPerkLevel(playerPuppet, gamedataNewPerkType.Intelligence_Right_Milestone_1);

    if (chanceHack  > playerOnStealTrigger) && (playerCarhackerLevel>0) {
      isVehicleHackable = true;
    }  

    if (isVehicleHackable) && (playerPuppet.m_claimedVehicleTracking.modON) { 
      playerPuppet.m_claimedVehicleTracking.tryClaimVehicle(vehicle, true);
    }
  }

// public class VehicleComponent extends ScriptableDeviceComponent {
@replaceMethod(VehicleComponent)

  protected cb func OnRemoteControlEvent(evt: ref<VehicleRemoteControlEvent>) -> Bool {
    let playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetVehicle().GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    // set up tracker if it doesn't exist
    if !IsDefined(playerPuppet.m_claimedVehicleTracking) {
      playerPuppet.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      playerPuppet.m_claimedVehicleTracking.init(playerPuppet);
    } else {
      // Reset if already exists (in case of changed default values)
      playerPuppet.m_claimedVehicleTracking.reset(playerPuppet);
    };

    if (playerPuppet.m_claimedVehicleTracking.modON) {
      playerPuppet.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), true);  
    }

    let vehicleQuestEvent: ref<VehicleQuestChangeDoorStateEvent> = new VehicleQuestChangeDoorStateEvent();
    let maxDelayToUnseatPassengers: Float = 5.00;
    if evt.shouldModifyInteractionState {
      if evt.remoteControl {
        vehicleQuestEvent.newState = EQuestVehicleDoorState.DisableAllInteractions;
      } else {
        vehicleQuestEvent.newState = EQuestVehicleDoorState.ResetInteractions;
      };
      GameInstance.GetPersistencySystem(this.GetVehicle().GetGame()).QueuePSEvent(this.GetPS().GetID(), this.GetPS().GetClassName(), vehicleQuestEvent);
    };
    if evt.shouldUnseatPassengers {
      this.GetVehicle().TriggerExitBehavior(maxDelayToUnseatPassengers);
    };
    if !evt.remoteControl {
      this.GetPS().EndStimsOnVehicleQuickhack();
    };
    this.PushVehicleNPCDataToAllPassengers(this.GetVehicle().GetGame(), this.GetVehicle().GetEntityID());
  }

@replaceMethod(VehicleComponent)

  protected cb func OnForceBrakesQuickhackEvent(evt: ref<VehicleForceBrakesQuickhackEvent>) -> Bool {
    let playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetVehicle().GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    // set up tracker if it doesn't exist
    if !IsDefined(playerPuppet.m_claimedVehicleTracking) {
      playerPuppet.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      playerPuppet.m_claimedVehicleTracking.init(playerPuppet);
    } else {
      // Reset if already exists (in case of changed default values)
      playerPuppet.m_claimedVehicleTracking.reset(playerPuppet);
    };

    // TO DO: Add method to remove a vehicle from Manager List
    if (playerPuppet.m_claimedVehicleTracking.modON) {
      playerPuppet.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), false);  
    }

    if evt.active {
      this.SetDelayDisableCarAlarm(evt.alarmDuration);
    };
    this.PushVehicleNPCDataToAllPassengers(this.GetVehicle().GetGame(), this.GetVehicle().GetEntityID());
  }