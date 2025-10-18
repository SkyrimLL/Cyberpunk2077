

 // public class VehicleComponent extends ScriptableDeviceComponent {
@wrapMethod(VehicleComponent) 

  private final func StealVehicle(opt slotID: MountingSlotId) -> Void { 
    let vehicle: wref<VehicleObject> = this.GetVehicle();
    if !IsDefined(vehicle) {
      return;
    };

    wrappedMethod(slotID);


    // LogChannel(n"DEBUG", "Player is stealing a vehicle");
    let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetVehicle().GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();

    // set up tracker if it doesn't exist
    /*
    if !IsDefined(playerPuppet.m_claimedVehicleTracking) {
      playerPuppet.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      playerPuppet.m_claimedVehicleTracking.init(playerPuppet);
    } else {
      playerPuppet.m_claimedVehicleTracking.reset(playerPuppet);
    };
    */

    let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(_playerPuppet.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    let isVehicleHackable: Bool = false;
    let chanceHack: Int32 = RandRange(0,99);
    let playerOnStealTrigger: Int32 = Cast<Int32>(100.0 - _playerPuppetPS.m_claimedVehicleTracking.chanceOnSteal);
    let playerCarhackerLevel = playerDevSystem.GetPerkLevel(_playerPuppet, gamedataNewPerkType.Intelligence_Right_Milestone_1);

    if (chanceHack  > playerOnStealTrigger) && (playerCarhackerLevel>0) {
      isVehicleHackable = true;
    }  

    if (_playerPuppetPS.m_claimedVehicleTracking.modON) && ( (!_playerPuppetPS.m_claimedVehicleTracking.scannerModeON) || ( (_playerPuppetPS.m_claimedVehicleTracking.player.m_focusModeActive) && (_playerPuppetPS.m_claimedVehicleTracking.scannerModeON)) ) {

      if (isVehicleHackable) { 
        _playerPuppetPS.m_claimedVehicleTracking.tryClaimVehicle(vehicle, true);
      } else {
        _playerPuppetPS.m_claimedVehicleTracking.tryReportCrime(false);
      }
    }
  }

// public class VehicleComponent extends ScriptableDeviceComponent {
@wrapMethod(VehicleComponent)

  protected cb func OnRemoteControlEvent(evt: ref<VehicleRemoteControlEvent>) -> Bool {
    let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetVehicle().GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();
    let playerOnStealTrigger: Int32 = Cast<Int32>(100.0 - _playerPuppetPS.m_claimedVehicleTracking.chanceOnSteal);
    let chanceHack: Int32 = RandRange(0,99);
    let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(_playerPuppet.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    let playerGearheadLevel = playerDevSystem.GetPerkLevel(_playerPuppet, gamedataNewPerkType.Tech_Right_Milestone_1);

    // set up tracker if it doesn't exist
    /*
    if !IsDefined(playerPuppet.m_claimedVehicleTracking) {
      playerPuppet.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      playerPuppet.m_claimedVehicleTracking.init(playerPuppet);
    } else { 
      playerPuppet.m_claimedVehicleTracking.reset(playerPuppet);
    };
    */ 
    
    if ((_playerPuppetPS.m_claimedVehicleTracking.modON) && (evt.remoteControl)) {
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: OnRemoteControlEvent: ");
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: scannerModeON: " + ToString(_playerPuppetPS.m_claimedVehicleTracking.scannerModeON));
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: playerGearheadLevel: " + ToString(playerGearheadLevel));

      // GearHead perk + Scanner mode (easy mode ON) = 100% chance of stealing vehicle
      if ((_playerPuppetPS.m_claimedVehicleTracking.scannerModeON) && (playerGearheadLevel>=1)) {
        _playerPuppetPS.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), true);  
        } else {
          // Else, normal chance if RemoteControl quickhack is ON
          if ((_playerPuppetPS.m_claimedVehicleTracking.remoteControlQuickhackON) ){
            if (chanceHack  > playerOnStealTrigger) {
              _playerPuppetPS.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), true);  
            } else {
              _playerPuppetPS.m_claimedVehicleTracking.tryReportCrime(false);
            }
          }
      }
    }

    wrappedMethod(evt);
  }

@wrapMethod(VehicleComponent)

  protected cb func OnForceBrakesQuickhackEvent(evt: ref<VehicleForceBrakesQuickhackEvent>) -> Bool {
    let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetVehicle().GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();
    let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(_playerPuppet.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    let playerGearheadLevel = playerDevSystem.GetPerkLevel(_playerPuppet, gamedataNewPerkType.Tech_Right_Milestone_1);

    // set up tracker if it doesn't exist
    /*
    if !IsDefined(playerPuppet.m_claimedVehicleTracking) {
      playerPuppet.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      playerPuppet.m_claimedVehicleTracking.init(playerPuppet);
    } else { 
      playerPuppet.m_claimedVehicleTracking.reset(playerPuppet);
    };
    */

    // TO DO: Add method to remove a vehicle from Manager List
    if (_playerPuppetPS.m_claimedVehicleTracking.modON)  {
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: OnForceBrakesQuickhackEvent: ");
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: forceBrakesQuickhackON: " + ToString(_playerPuppetPS.m_claimedVehicleTracking.forceBrakesQuickhackON));
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: playerGearheadLevel: " + ToString(playerGearheadLevel));

      if ((_playerPuppetPS.m_claimedVehicleTracking.forceBrakesQuickhackON) && (playerGearheadLevel>=1)) {
        _playerPuppetPS.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), false);  
      }
    }

    wrappedMethod(evt);
  }
 