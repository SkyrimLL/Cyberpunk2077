

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

    if (_playerPuppetPS.m_claimedVehicleTracking.modON) && ( (!_playerPuppetPS.m_claimedVehicleTracking.quickhackManualModeON) || ( (_playerPuppetPS.m_claimedVehicleTracking.player.m_focusModeActive) && (_playerPuppetPS.m_claimedVehicleTracking.quickhackManualModeON)) ) {

      if (isVehicleHackable) { 
        _playerPuppetPS.m_claimedVehicleTracking.tryClaimVehicle(vehicle, true);
      } else {
        // Get vehicle info to check if it's known
        let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehicle.GetRecordID());
        let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());
        _playerPuppetPS.m_claimedVehicleTracking.getVehicleStringFromModel(vehicle.GetRecordID(), claimedVehicleModel);
        
        // Only report crime for known vehicles (valid tweakID in database)
        let isVehicleKnown: Bool = TDBID.IsValid(_playerPuppetPS.m_claimedVehicleTracking.matchVehicleRecordID) && !Equals(_playerPuppetPS.m_claimedVehicleTracking.matchVehicleRecordID, t"");
        
        if (isVehicleKnown) {
          // Skip crime reporting if vehicle is from El Capitan courier mission
          let isQuestVehicle: Bool = vehicle.IsQuest();
          let isCourierMissionActive: Bool = GameInstance.GetQuestsSystem(_playerPuppet.GetGame()).GetFact(n"sa_ep1_couriers_active") >= 1;
          
          if (!isQuestVehicle && !isCourierMissionActive) {
            _playerPuppetPS.m_claimedVehicleTracking.tryReportCrime(false);
          }
        } else {
          _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage("::: StealVehicle - skipped crime reporting (unknown vehicle)"  );
        }
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
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: quickhackManualModeON: " + ToString(_playerPuppetPS.m_claimedVehicleTracking.quickhackManualModeON));
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: remoteControlQuickhackON: " + ToString(_playerPuppetPS.m_claimedVehicleTracking.remoteControlQuickhackON));
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: playerGearheadLevel: " + ToString(playerGearheadLevel));

      // GearHead perk + Manual mode (easy mode ON) = 100% chance of stealing vehicle
      if (_playerPuppetPS.m_claimedVehicleTracking.quickhackManualModeON) {
        if (playerGearheadLevel>=1) {
          _playerPuppetPS.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), true);
        } else {
          // Manual mode enabled but missing perk - notify user and fall through to dynamic mode
          if (_playerPuppetPS.m_claimedVehicleTracking.warningsON) {
            _playerPuppet.SetWarningMessage("N.C.L.A.I.M: Manual mode requires Gearhead perk (Tech tree)");
          }
          // Fall through to dynamic mode
          if (_playerPuppetPS.m_claimedVehicleTracking.remoteControlQuickhackON) {
            if (chanceHack  > playerOnStealTrigger) {
              _playerPuppetPS.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), true);
            } else {
              if (_playerPuppetPS.m_claimedVehicleTracking.warningsON) {
                _playerPuppet.SetWarningMessage("N.C.L.A.I.M: Vehicle claim attempt failed");
              }
              
              // Get vehicle info to check if it's known
              let vehicle: wref<VehicleObject> = this.GetVehicle();
              let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehicle.GetRecordID());
              let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());
              _playerPuppetPS.m_claimedVehicleTracking.getVehicleStringFromModel(vehicle.GetRecordID(), claimedVehicleModel);
              
              // Only report crime for known vehicles (valid tweakID in database)
              let isVehicleKnown: Bool = TDBID.IsValid(_playerPuppetPS.m_claimedVehicleTracking.matchVehicleRecordID) && !Equals(_playerPuppetPS.m_claimedVehicleTracking.matchVehicleRecordID, t"");
              
              if (isVehicleKnown) {
                // Skip crime reporting if vehicle is from El Capitan courier mission
                let isQuestVehicle: Bool = vehicle.IsQuest();
                let isCourierMissionActive: Bool = GameInstance.GetQuestsSystem(_playerPuppet.GetGame()).GetFact(n"sa_ep1_couriers_active") >= 1;
                
                if (!isQuestVehicle && !isCourierMissionActive) {
                  _playerPuppetPS.m_claimedVehicleTracking.tryReportCrime(false);
                } else {
                  _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage("::: OnRemoteControlEvent - skipped crime reporting (quest/courier)"  );
                  _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage("::: OnRemoteControlEvent - isQuestVehicle: "+ToString(isQuestVehicle)  );
                  _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage("::: OnRemoteControlEvent - isCourierMissionActive: "+ToString(isCourierMissionActive)  );
                }
              } else {
                _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage("::: OnRemoteControlEvent - skipped crime reporting (unknown vehicle)"  );
              }
            }
          } else if (_playerPuppetPS.m_claimedVehicleTracking.warningsON) {
            _playerPuppet.SetWarningMessage("N.C.L.A.I.M: Remote Control claiming is disabled");
          }
        }
      } else {
        // Normal dynamic mode - RemoteControl quickhack is ON
        if (_playerPuppetPS.m_claimedVehicleTracking.remoteControlQuickhackON) {
          if (chanceHack  > playerOnStealTrigger) {
            _playerPuppetPS.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), true);
          } else {
            if (_playerPuppetPS.m_claimedVehicleTracking.warningsON) {
              _playerPuppet.SetWarningMessage("N.C.L.A.I.M: Vehicle claim attempt failed");
            }
            
            // Get vehicle info to check if it's known
            let vehicle: wref<VehicleObject> = this.GetVehicle();
            let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehicle.GetRecordID());
            let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());
            _playerPuppetPS.m_claimedVehicleTracking.getVehicleStringFromModel(vehicle.GetRecordID(), claimedVehicleModel);
            
            // Only report crime for known vehicles (valid tweakID in database)
            let isVehicleKnown: Bool = TDBID.IsValid(_playerPuppetPS.m_claimedVehicleTracking.matchVehicleRecordID) && !Equals(_playerPuppetPS.m_claimedVehicleTracking.matchVehicleRecordID, t"");
            
            if (isVehicleKnown) {
              // Skip crime reporting if vehicle is from El Capitan courier mission
              let isQuestVehicle: Bool = vehicle.IsQuest();
              let isCourierMissionActive: Bool = GameInstance.GetQuestsSystem(_playerPuppet.GetGame()).GetFact(n"sa_ep1_couriers_active") >= 1;
              
              if (!isQuestVehicle && !isCourierMissionActive) {
                _playerPuppetPS.m_claimedVehicleTracking.tryReportCrime(false);
              }
            } else {
              _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage("::: OnRemoteControlEvent - skipped crime reporting (unknown vehicle)"  );
            }
          }
        } else if (_playerPuppetPS.m_claimedVehicleTracking.warningsON) {
          _playerPuppet.SetWarningMessage("N.C.L.A.I.M: Remote Control claiming is disabled");
        }
      }
    }

    wrappedMethod(evt);
  }

@wrapMethod(VehicleComponent)

  protected cb func OnForceBrakesQuickhackEvent(evt: ref<VehicleForceBrakesQuickhackEvent>) -> Bool {
    wrappedMethod(evt);

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

    if (_playerPuppetPS.m_claimedVehicleTracking.modON)  {
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: OnForceBrakesQuickhackEvent: ");
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: forceBrakesQuickhackON: " + ToString(_playerPuppetPS.m_claimedVehicleTracking.forceBrakesQuickhackON));
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(":: playerGearheadLevel: " + ToString(playerGearheadLevel));

      if (_playerPuppetPS.m_claimedVehicleTracking.forceBrakesQuickhackON) {
        if (playerGearheadLevel>=1) {
          _playerPuppetPS.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), false);
        } else if (_playerPuppetPS.m_claimedVehicleTracking.warningsON) {
          _playerPuppet.SetWarningMessage("N.C.L.A.I.M: Gearhead perk required (Tech tree)");
        }
      }
    }
  }
 