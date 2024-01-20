// ClaimVehicles - by DeepBlueFrog 

/*
For redscript mod developers

:: Replaced methods
@replaceMethod(VehiclesManagerDataHelper) public final static func GetVehicles(player: ref<GameObject>) -> array<ref<IScriptable>> 
@replaceMethod(DriveEvents) public final func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void 
@replaceMethod(VehicleComponent) private final func StealVehicle(opt slotID: MountingSlotId) -> Void 

:: Added methods which can cause incompatibilities
@addMethod(PlayerPuppet) private final func InitClaimVehicleSystem() -> Void 

:: Added fields
@addField(PlayerPuppet) public let m_claimedVehicleTracking: ref<ClaimedVehicleTracking>;

:: New classes
public class ClaimedVehicleTracking
*/

public class ClaimedVehicleTracking extends ScriptedPuppetPS {
  public let player: wref<PlayerPuppet>;
  public let config: ref<ClaimVehiclesConfig>;

  public persistent let vehicleDB: ref<ClaimVehicleDB>;
  public persistent let originalGarage: array<TweakDBID>;

  public let modON: Bool;
  public let debugON: Bool;
  public let warningsON: Bool;  

  public let chanceOnSteal: Float;
  public let chanceOnExit: Float;
  public let chanceLowPerkHack: Float;
  public let chanceMidPerkHack: Float;
  public let chanceHighPerkHack: Float;
  public let chanceCrimeReportFail: Float;
  public let chanceCrimeReportSuccess: Float; 
  public let summonMode: vehicleSummonMode;

  public persistent let lastVehicleRecordID: TweakDBID; 
  public persistent let useOriginalGarage: Bool; 

  public let matchVehicle: PlayerVehicle; 
  public let matchVehicleRecordID: TweakDBID; 
  public let matchVehicleModel: String; 
  public let matchVehicleString: String;  
  public let matchVehicleUnlocked: Bool;

  public let refreshPlayerGarageOnLoad: Bool = false;  

  public func init(player: wref<PlayerPuppet>) -> Void {
    this.reset(player);
  }

  private func reset(player: wref<PlayerPuppet>) -> Void {
    this.player = player;

    this.refreshConfig();

    // ------------------ Edit these values to configure the mod
    // Percent chance of successful hack of a vehicle without first stealing it
    // Aligned with three perks
    // this.chanceLowPerkHack = 20;
    // this.chanceMidPerkHack = 50;
    // this.chanceHighPerkHack = 100;
    // this.chanceCrimeReportFail = 80;
    // this.chanceCrimeReportSuccess = 20;

    // Toggle warning messages 
    // this.warningsON = true;

    // ------------------ End of Mod Options

    // For developers only 
    // this.debugON = true; 

    // Persistence - New database only if vehicle unlock state size is 0
    if (ArraySize(this.vehicleDB.vehiclesUnlockStateDB)==0) {
      this.vehicleDB = new ClaimVehicleDB();
    }
    
    this.vehicleDB.init();

    // First time - save garage
    if (ArraySize(this.vehicleDB.vehiclesUnlockStateDB)==0) { 
      this.saveGarage();
      this.useOriginalGarage = true; 
    }
  }

  public func refreshConfig() -> Void {
    this.config = new ClaimVehiclesConfig(); 
    this.invalidateCurrentState();
  }

  public func invalidateCurrentState() -> Void { 
    this.chanceOnSteal = Cast<Float>(this.config.chanceOnSteal); 
    this.chanceOnExit = Cast<Float>(this.config.chanceOnExit); 
    this.chanceLowPerkHack = Cast<Float>(this.config.chanceLowPerkHack); 
    this.chanceMidPerkHack = Cast<Float>(this.config.chanceMidPerkHack); 
    this.chanceHighPerkHack = Cast<Float>(this.config.chanceHighPerkHack);   
    this.chanceCrimeReportFail = Cast<Float>(this.config.chanceCrimeReportFail);   
    this.chanceCrimeReportSuccess = Cast<Float>(this.config.chanceCrimeReportSuccess);   
    this.summonMode = this.config.summonMode;  
    this.warningsON = this.config.warningsON;
    this.debugON = this.config.debugON;
    this.modON = this.config.modON;  
  }  

  // Mapping Vehicle plain text model string -> internal vehicle string ID
  //    Also converts variant vehicle model name to model name found in list of potential player vehicles
  //    Ex: Hella EC-D 1360 ->  Vehicle.v_standard2_archer_hella_player
  public func getVehicleStringFromModel(vehicleRecordID: TweakDBID, claimedVehicleModel: String) -> Void {
    let thisVehicle: ref<VehicleProperties>; 
    let thisVehicleUnlockedState: Bool;

    this.refreshConfig();

    this.matchVehicleUnlocked = false; 

    if (this.warningsON) {
      // LogChannel(n"DEBUG", "N.C.L.A.I.M: Reading Vehicle ID from Model: '"+claimedVehicleModel+"'"  );
    }

    // Universal vehicle detection
    thisVehicle = this.vehicleDB.lookupVehicle(vehicleRecordID);
    thisVehicleUnlockedState = this.vehicleDB.lookupVehicleUnlockState(vehicleRecordID);

    this.matchVehicleRecordID = vehicleRecordID;
    this.matchVehicleModel = claimedVehicleModel;
    this.matchVehicleString = thisVehicle.vehicleString;
    this.matchVehicleUnlocked = thisVehicleUnlockedState;

    this.isVehicleAvailable(); // to refresh owned flag status if needed

    // TO DO: 
    //   Some vehicles are not saved
    //   Known vehicles are 'reclaimed' when using the alternate garage

    if (this.warningsON) {
      // LogChannel(n"DEBUG", "N.C.L.A.I.M: Vehicle ID found: '"+this.matchVehicleString+"'"  );
    }
  }

  // Mapping Vehicle plain text model string -> vehicle record in list of potential player owned vehicles
  //    Assumes getVehicleStringFromModel() was already ran to convert variant vehicle model to model from player vehicles
  public func isVehicleAvailable() -> Bool {
    let vehiclesList: array<PlayerVehicle>;
    let vehicleString: String;
    let thisVehicle: ref<VehicleProperties>; 
    let targetVehicle: ref<VehicleProperties>; 
    let thisVehicleUnlockedState: Bool;

    let matchFound = false;
    let i = 0;

    if (this.warningsON) {
      // LogChannel(n"DEBUG", " ");
      // LogChannel(n"DEBUG", "----- ");
      // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Scanning known vehicles for '" + this.matchVehicleModel + "'");
      // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  " + ToString(ArraySize(this.vehicleDB.vehiclesDB)) + " vehicles in full database.");
      // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  " + ToString(ArraySize(this.vehicleDB.vehiclesUnlockStateDB)) + " vehicles in history.");
    }

    // Refresh status of vehicles in case some vehicles were sold or removed by other means
    this.refreshClaimedVehicles();

    targetVehicle = this.vehicleDB.lookupVehicle(this.matchVehicleRecordID);

    if (Equals(targetVehicle.vehicleString, "")) {
      // Vehicle not found in database - Skip search

    } else { 

      // First try the current garage
      while (i < ArraySize(vehiclesList)) { 
        let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
        let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());
        if (this.warningsON) {
          if (vehiclesList[i].isUnlocked) {
            // LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking database for '"+ _this_vehicleModel +"' - isUnlocked: " + vehiclesList[i].isUnlocked);
          } else {
            // LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking database for '"+ _this_vehicleModel +"'");
          }
          
        }
        // if ( StrCmp(StrLower(_this_vehicleModel), StrLower(this.matchVehicleModel)) == 0 ) {
        if ( Equals( vehiclesList[i].recordID, this.matchVehicleRecordID  ) ){
   
          this.matchVehicle.recordID = vehiclesList[i].recordID;
          this.matchVehicle.vehicleType = vehiclesList[i].vehicleType;
          // 2023-12-30: Some vehicles remain unlocked after being added to player list -> need to keep parallel list of unlocked vehicles
          this.matchVehicleUnlocked = true; // vehiclesList[i].isUnlocked; // force vehicle unlocked sate to true if in current garage

          if (this.matchVehicleUnlocked) {
            if (this.warningsON) { 
              // LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
            }
            matchFound = true;
          }
        }
        i += 1;
      };  

      // Retrieve RecordID and vehicle type for the matched vehicle model
      if (!matchFound) {
        if  (this.useOriginalGarage) {
          while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
            let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID);
            let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());
            // Force refresh of unlock status if needed
            thisVehicle = this.vehicleDB.lookupVehicle(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID);
            thisVehicleUnlockedState = this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked;

            if (this.warningsON) {
              // LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking claim history for '"+ _this_vehicleModel +"' - vehicle code: " + thisVehicle.vehicleString  + " [Unlocked: " + ToString(thisVehicleUnlockedState) + "]");
            }

            // Matching internal vehicle strings - should be more reliable since player owned vehicles seem unique with stable lock status and random vehicles are not
            if ( Equals( thisVehicle.vehicleString, targetVehicle.vehicleString  ) ){
              if (this.warningsON) { 
                // LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
              }
       
              this.matchVehicle.recordID = this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID; 
              this.matchVehicle.vehicleType = _this_vehicleRecord.Type().Type();
              this.matchVehicleUnlocked = thisVehicleUnlockedState;

              matchFound = true;
              
            }

            i += 1;
          };    
        } else {
          // If alternate garage is used, compare with saved list of vehicles
          while i < ArraySize(this.originalGarage) { 
            let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(this.originalGarage[i]);
            let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());
            // Force refresh of unlock status if needed
            thisVehicle = this.vehicleDB.lookupVehicle(this.originalGarage[i]);
            thisVehicleUnlockedState = true;

            if (this.warningsON) {
              // LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking original garage for '"+ _this_vehicleModel +"' - vehicle code: " + thisVehicle.vehicleString  + " [Unlocked: " + ToString(thisVehicleUnlockedState) + "]");
            }

            // Matching internal vehicle strings - should be more reliable since player owned vehicles seem unique with stable lock status and random vehicles are not
            if ( Equals( thisVehicle.vehicleString, targetVehicle.vehicleString  ) ){
              if (this.warningsON) { 
                // LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
              }
       
              this.matchVehicle.recordID = this.originalGarage[i]; 
              this.matchVehicle.vehicleType = _this_vehicleRecord.Type().Type();
              this.matchVehicleUnlocked = thisVehicleUnlockedState;

              matchFound = true;
              
            }

            i += 1;
          };         
        }      
      }

      // If not found, scan whole list of player vehicles
      if (!matchFound) {
        i = 0;
        GameInstance.GetVehicleSystem(this.player.GetGame()).GetPlayerVehicles(vehiclesList);
        if (this.warningsON) {
          // LogChannel(n"DEBUG", " ");
          // LogChannel(n"DEBUG", "----- Fallback");
          // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Database online. " + ToString(ArraySize(vehiclesList)) + " records total");
          // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Scanning Criminal Asset Forfeiture database for '" + this.matchVehicleModel + "'");
        }

        while (i < ArraySize(vehiclesList)) && (!matchFound) { 
          let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
          let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());
          thisVehicle = this.vehicleDB.lookupVehicle(vehiclesList[i].recordID);
          thisVehicleUnlockedState = this.vehicleDB.lookupVehicleUnlockState(vehiclesList[i].recordID); // vehiclesList[i].isUnlocked

          if (this.warningsON) {
            // LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking database for '"+ _this_vehicleModel +"' - vehicle code: " + thisVehicle.vehicleString);
            if (thisVehicleUnlockedState) {
              // LogChannel(n"DEBUG", ">>> Vehicle unlocked: " + thisVehicleUnlockedState);
            } 
            
          }
          // if ( StrCmp(StrLower(_this_vehicleModel), StrLower(this.matchVehicleModel)) == 0 ) {
          if ( Equals( vehiclesList[i].recordID, this.matchVehicleRecordID  ) ){
            if (this.warningsON) { 
              // LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
            }

            if (thisVehicleUnlockedState) {
              this.matchVehicle.recordID = this.matchVehicleRecordID; // vehiclesList[i].recordID; 
              this.matchVehicle.vehicleType = vehiclesList[i].vehicleType;
              this.matchVehicleUnlocked = thisVehicleUnlockedState;

              if (this.warningsON) { 
                // LogChannel(n"DEBUG", ">>> Vehicle is already unlocked");
              }
              matchFound = true;
            }
          }
          i += 1;
        };  

      }
    }

    if (this.warningsON) && (!matchFound) { 
      // LogChannel(n"DEBUG", ">>>  NO matching vehicle record ID.");
    }

    return matchFound;
  }

  public func tryReportCrime(crimeOnSuccess: Bool) -> Void {
    let chanceCrimeReportFail: Int32 = Cast<Int32>(this.chanceCrimeReportFail); 
    let chanceCrimeReportSuccess: Int32 = Cast<Int32>(this.chanceCrimeReportSuccess);

    if (crimeOnSuccess) {
      // LogChannel(n"DEBUG", "::: tryReportCrime - Claim succeeded - reporting a crime"  );
      // LogChannel(n"DEBUG", "::: tryReportCrime - chanceCrimeReportSuccess: " + ToString(chanceCrimeReportSuccess) );
      if (RandRange(1,100) <= chanceCrimeReportSuccess) {
        this.player.SetWarningMessage( ClaimVehiclesText.CRIME());   
        // playerOwner.GetPreventionSystem().HeatPipeline("PlayerStoleVehicle");
        this.player.GetPreventionSystem().HeatPipeline("CrimeWitness");
      }
    } else {
      // LogChannel(n"DEBUG", "::: tryReportCrime - Claim failed - reporting a crime"  );
      // LogChannel(n"DEBUG", "::: tryReportCrime - chanceCrimeReportFail: " + ToString(chanceCrimeReportFail) );
      if (RandRange(1,100) <= chanceCrimeReportFail) {
        this.player.SetWarningMessage( ClaimVehiclesText.CRIME());   
        // _playerPuppetPS.GetPreventionSystem().HeatPipeline("PlayerStoleVehicle");
        this.player.GetPreventionSystem().HeatPipeline("CrimeWitness");
      }
    }


  }

  public func tryClaimVehicle(vehicle: ref<VehicleObject>, addVehicle: Bool) -> Void {
    let claimVehicle: Bool;
    let recordID: TweakDBID = vehicle.GetRecordID();
    let vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(recordID);
    let vehTypeRecord: ref<VehicleType_Record> = vehicleRecord.Type();
    let vehType: gamedataVehicleType = vehTypeRecord.Type();
    let vehClassName: String = vehTypeRecord.EnumName();
    // let vehiclesUnlockedList: array<PlayerVehicle>;
    // let vehiclesList: array<PlayerVehicle>;
    // let vehicleModel: String = GetLocalizedItemNameByCName(vehicleRecord.DisplayName());

    // // LogChannel(n"DEBUG", ":: Entering tryClaimVehicle");
    // // LogChannel(n"DEBUG", ":: tryClaimVehicle - vehClassName: " + vehClassName);

    let isVictorHUDInstalled: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_ripperdoc_done") >= 1;
    let isPhantomLiberyStandalone: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"ep1_standalone") >= 1;
 
    if (this.debugON) {
      // LogChannel(n"DEBUG", ":: tryClaimVehicle - isVictorHUDInstalled: " + isVictorHUDInstalled);
    }

    switch vehClassName {
      case "Car":
        claimVehicle = true;
        break;

      case "Bike":
        claimVehicle = true;
        break;
    };

    // // LogChannel(n"DEBUG", ":: tryClaimVehicle - claimVehicle: " + ToString(claimVehicle));
    if (claimVehicle) && ( (isVictorHUDInstalled) || (isPhantomLiberyStandalone)) {

      if (this.warningsON) {
        // LogChannel(n"DEBUG", " ");
        // LogChannel(n"DEBUG", "N.C.L.A.I.M:  Registering Forfeit Vehicle - " + vehClassName);
      }

      // if (playerOwner.m_claimedVehicleTracking.debugON) {  playerOwner.SetWarningMessage("Warning: vehicle ownership updated."); }
      // playerOwner.SetWarningMessage("Warning: vehicle security malfunction. Vehicle abandoned."); 

      // GameInstance.GetVehicleSystem(playerOwner.GetGame()).GetPlayerUnlockedVehicles(vehiclesUnlockedList);
      // GameInstance.GetVehicleSystem(playerOwner.GetGame()).GetPlayerVehicles(vehiclesList);

      // Adding new vehicle to list if not found - Doesn't work
      let thisPlayerVehicle: PlayerVehicle;
      thisPlayerVehicle.recordID = recordID; 
      thisPlayerVehicle.vehicleType = vehType;
      thisPlayerVehicle.isUnlocked = true;

      if (addVehicle)
      {
        this.addClaimedVehicle(thisPlayerVehicle);

        // Commented out for 2.0.2 testing
        // Added back to enable Stash on vehicles
        this.tryPersistVehicle(vehicle);

      } else {
        // Remove from managed vehicles list
        this.removeClaimedVehicle(thisPlayerVehicle);

      }

    }        
  }

  public func tryPersistVehicle(vehicle: ref<VehicleObject>) -> Void {
    // Adding tweaks to current vehicle to help delay despawn
    // ============ Simulate a delay from passengers in the vehicle??
    let delayReactionEvt: ref<DelayReactionToMissingPassengersEvent>;
    delayReactionEvt = new DelayReactionToMissingPassengersEvent(); 
    GameInstance.GetDelaySystem(vehicle.GetGame()).DelayEvent(vehicle, delayReactionEvt, 20000.00);

    vehicle.GetVehiclePS().SetIsPlayerVehicle(true);  // Not enough to prevent de-spawn
    vehicle.GetVehiclePS().SetIsStolen(false);   
    vehicle.m_abandoned = true;  // 'true' or false' is not enough to prevent de-spawn
  }

  public func refreshClaimedVehicles() -> Void { 
    let m_vehicleSystem: ref<VehicleSystem>  = GameInstance.GetVehicleSystem(this.player.GetGame());
    let vehiclesList: array<PlayerVehicle> ;
    let i = 0;

    m_vehicleSystem.GetPlayerUnlockedVehicles(vehiclesList); 
     
    // Invalidate persistent history
    while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
      // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Garage init " + _this_vehicleString + " with state " + ToString(_this_vehicleUnlockState));
      this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = false;

      i += 1;
    }; 

    // Refresh history from current owned list
    i = 0;

    // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Garage list: " + ToString(ArraySize(vehiclesList)) + " vehicles currently registered.");

    while i < ArraySize(vehiclesList) {    
      // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Claimed vehicles state refresh: " + TDBID.ToStringDEBUG(vehiclesList[i].recordID)  );
 
      this.vehicleDB.setVehicleUnlockState(vehiclesList[i].recordID, true);

      i += 1;
    };       
  }

  public func refreshGarage() -> Void { 
    let m_vehicleSystem: ref<VehicleSystem>  = GameInstance.GetVehicleSystem(this.player.GetGame());
    let vehiclesList: array<PlayerVehicle>;
    let _this_vehicleString: String;
    let i = 0;
    let matchFound: Bool = false;

    m_vehicleSystem.GetPlayerUnlockedVehicles(vehiclesList); 

    switch (this.summonMode) {
      // Normal mode - enable all vehicles in Claim history
      case vehicleSummonMode.Normal:
        // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Garage refresh: Normal Mode"   );

        if  (!this.useOriginalGarage) {
          this.loadGarage();
          this.useOriginalGarage = true; 
        }
        
        /*
        while i < ArraySize(vehiclesList) {    
          _this_vehicleString = this.vehicleDB.lookupVehicleString(vehiclesList[i].recordID);
          GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, true, false);
          this.vehicleDB.setVehicleUnlockState(vehiclesList[i].recordID, true);

          i += 1;
        };  
        */  
            
        break;
      // Last mode - enable only last vehicle claimed 
      case vehicleSummonMode.Last:
        // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Garage refresh: Last Mode"   );
        
        if (!this.lastVehicleRecordID) {
          // Skip
        } else {
          if  (this.useOriginalGarage) {
            this.saveGarage();
            this.useOriginalGarage = false; 
          }

          this.clearGarage();
          
          i = 0;
          while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
            _this_vehicleString = this.vehicleDB.lookupVehicleString(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID);
            // Disable all vehicles except the last one claimed
            if (this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID == this.lastVehicleRecordID) {
                GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, true, false);
                this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = true;
                matchFound = true;

              } else {
                GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, false, false);
                this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = false;
              }

            i += 1;
          };  

          // Fallback on random pick if last vehicle is not found
          if (!matchFound) {
            this.enableRandomVehicle();
          }            
        }
     
        break;
      // Random mode - enable random known vehicle   
      case vehicleSummonMode.Random:
        // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Garage refresh: Random Mode"   );
        
        if  (this.useOriginalGarage) {
          this.saveGarage();
          this.useOriginalGarage = false; 
        }

        this.clearGarage();
        
        this.enableRandomVehicle();

        break;
      // Delamain mode - enable only Delamain models 
      case vehicleSummonMode.Delamain:
        // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Garage refresh: Delamain Mode"   );
        
        if  (this.useOriginalGarage) {
          this.saveGarage();
          this.useOriginalGarage = false; 
        }

        this.clearGarage();
        
        i = 0;
        while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
          _this_vehicleString = this.vehicleDB.lookupVehicleString(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID);
          // Disable all vehicles except Delamains
          if (StrContains(_this_vehicleString, "delamain")) {
              GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, true, false);
              this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = true;

            } else {
              GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, false, false);
              this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = false;
            }

          i += 1;
        };

        break;
      // Favorite mode - enable only favorite vehicles [TBD]
      case vehicleSummonMode.Favorites:
        // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Garage refresh: Favorite Mode"   );
        
        if  (this.useOriginalGarage) {
          this.saveGarage();
          this.useOriginalGarage = false; 
        }

        this.clearGarage();

        while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
          _this_vehicleString = this.vehicleDB.lookupVehicleString(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID);
          // Disable all vehicles except favorites
          if (this.vehicleDB.vehiclesUnlockStateDB[i].vehicleFavorite) {
              GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, true, false);
              this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = true;
              matchFound = true;

            } else {
              GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, false, false);
              this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = false;
            }

          i += 1;
        }; 

        // Fallback on random pick if there is no favorite
        if (!matchFound) {
          this.enableRandomVehicle();
        }   

        break;
      // Last mode - enable all known vehicles from claim history
      case vehicleSummonMode.All:
        // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Garage refresh: All Mode"   );
        
        if  (this.useOriginalGarage) {
          this.saveGarage();
          this.useOriginalGarage = false; 
        }

        this.clearGarage();

        while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
          _this_vehicleString = this.vehicleDB.lookupVehicleString(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID);
          GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, true, false);
          this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = true;

          i += 1;
        }; 
        break;
    };       
  }

  // Pick a random vehicle from history and enables it
  public func enableRandomVehicle() -> Void { 
    let _this_vehicleString: String;
    let i = 0;

    i = 0;
    let randomNum: Int32 = RandRange(0,ArraySize(this.vehicleDB.vehiclesUnlockStateDB)-1);

    while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
      _this_vehicleString = this.vehicleDB.lookupVehicleString(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID);
      // Disable all vehicles except a random one
      if (i == randomNum) {
          GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, true, false);
          this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = true;

        } else {
          GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, false, false);
          this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = false;
        }

      i += 1;
    }; 

  }

  // Add vehicle record to saved garage to register new claimed vehicles
  public func addVehicleToSavedGarage(_id: TweakDBID) -> Void { 
    let m_vehicleSystem: ref<VehicleSystem>  = GameInstance.GetVehicleSystem(this.player.GetGame());
    let vehiclesList: array<PlayerVehicle> ;
    let i = 0;
    let bVehicleFound: Bool = false;

    m_vehicleSystem.GetPlayerUnlockedVehicles(vehiclesList);  

    while i < ArraySize(vehiclesList) {     
      if (vehiclesList[i].recordID == _id) {
        bVehicleFound = true;
      }

      i += 1;
    }; 

    // If vehicle not found, add it to saved garage list
    if (!bVehicleFound) {
      ArrayPush(this.originalGarage, _id); 
    }
  }

  // Clear current garage
  public func clearGarage() -> Void { 
    let m_vehicleSystem: ref<VehicleSystem>  = GameInstance.GetVehicleSystem(this.player.GetGame());
    let vehiclesList: array<PlayerVehicle> ;
    let _this_vehicleString: String;
    let i = 0;

    m_vehicleSystem.GetPlayerUnlockedVehicles(vehiclesList);  

    while i < ArraySize(vehiclesList) {      
      _this_vehicleString = this.vehicleDB.lookupVehicleString(vehiclesList[i].recordID);
      GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, false, false); 

      i += 1;
    }; 
  }

  // Clone garage state for safekeeing between modes
  public func saveGarage() -> Void { 
    let m_vehicleSystem: ref<VehicleSystem>  = GameInstance.GetVehicleSystem(this.player.GetGame());
    let vehiclesList: array<PlayerVehicle> ;
    let i = 0;

    m_vehicleSystem.GetPlayerUnlockedVehicles(vehiclesList); 

    ArrayClear(this.originalGarage);

    while i < ArraySize(vehiclesList) {     
      ArrayPush(this.originalGarage, vehiclesList[i].recordID);

      i += 1;
    }; 
  }

  // Restore original garage state
  public func loadGarage() -> Void {  
    let _this_vehicleString: String;
    let i = 0;

    while i < ArraySize(this.originalGarage) {     
      _this_vehicleString = this.vehicleDB.lookupVehicleString(this.originalGarage[i]);
      GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, true, false);
      this.vehicleDB.setVehicleUnlockState(this.originalGarage[i], true);

      i += 1;
    }; 
  }


  public func refreshClaimedVehiclesOnLoad() -> Void {
    let i = 0;

    while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
      let _this_vehicleString: String = this.vehicleDB.lookupVehicleString(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID);
      let _this_vehicleUnlockState: Bool = this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked;

      // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Garage init: " + _this_vehicleString + " with state " + ToString(_this_vehicleUnlockState));

      GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, _this_vehicleUnlockState, false);

      i += 1;
    };       
  }

  public func addClaimedVehicle(claimedVehicle: PlayerVehicle) -> Void {
    let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(claimedVehicle.recordID);
    let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());

    // Checking standard dealership database
    this.getVehicleStringFromModel(claimedVehicle.recordID, claimedVehicleModel);  

    if (!(StrCmp(this.matchVehicleString,"")==0)) { 
      // Vehicle is known to database
      this.lastVehicleRecordID = this.matchVehicleRecordID;

      if (this.matchVehicleUnlocked) {
        if (this.debugON) { 
          // LogChannel(n"DEBUG", ">>> Skipping registration - vehicle already unlocked");
        }  
             
      } else {

        if (this.debugON) {
          // LogChannel(n"DEBUG", "N.C.L.A.I.M: Scanning Criminal Asset Forfeiture database for '"+claimedVehicleModel+"'.");        
        }

        if (this.warningsON) {
          // LogChannel(n"DEBUG", "N.C.L.A.I.M: Vehicle code extracted: '"+this.matchVehicleString+"'"  );   
        }

        GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( this.matchVehicleString, true, false);

        GameInstance.GetVehicleSystem(this.player.GetGame()).TogglePlayerActiveVehicle(Cast<GarageVehicleID>(this.matchVehicle.recordID), this.matchVehicle.vehicleType, true); 

        this.vehicleDB.setVehicleUnlockState(this.matchVehicleRecordID, true);

        if  (!this.useOriginalGarage) {
          this.addVehicleToSavedGarage(this.matchVehicleRecordID);
        }


        this.tryReportCrime(true);
 
        if (this.warningsON) {     
          this.player.SetWarningMessage( ClaimVehiclesText.MATCH_FOUND() + " '"+claimedVehicleModel+"'");   
        } 

      }

      this.refreshGarage();


    } 

    if (this.warningsON) && (StrCmp(this.matchVehicleString,"") == 0) {     
      //  this.player.SetWarningMessage("N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
      // LogChannel(n"DEBUG", "N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
    }       
   
  }


  public func removeClaimedVehicle(claimedVehicle: PlayerVehicle) -> Void {
    let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(claimedVehicle.recordID);
    let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());

    // Checking standard dealership database
    this.getVehicleStringFromModel(claimedVehicle.recordID, claimedVehicleModel);  


    if (!(StrCmp(this.matchVehicleString,"")==0)) { 
      // Vehicle is known to database

      if (this.matchVehicleUnlocked) {
 

        if (this.debugON) {
          // LogChannel(n"DEBUG", "N.C.L.A.I.M: Scanning Criminal Asset Forfeiture database for '"+claimedVehicleModel+"'.");        
        }

        if (this.warningsON) {
          // LogChannel(n"DEBUG", "N.C.L.A.I.M: Vehicle code extracted: '"+this.matchVehicleString+"'"  );   
        }

        GameInstance.GetVehicleSystem(this.player.GetGame()).TogglePlayerActiveVehicle(Cast<GarageVehicleID>(this.matchVehicle.recordID), this.matchVehicle.vehicleType, false);  

        GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( this.matchVehicleString, false, false);

        this.vehicleDB.setVehicleUnlockState(this.matchVehicleRecordID, false);
 
        if (this.warningsON) {     
          this.player.SetWarningMessage( ClaimVehiclesText.REMOVING() + " '"+claimedVehicleModel+"'");   
        } 
             
      } else {
        if (this.debugON) { 
          // LogChannel(n"DEBUG", ">>> Skipping removal - vehicle not owned");
        } 


      }

      this.refreshGarage();

    } 

    if (this.warningsON) && (StrCmp(this.matchVehicleString,"") == 0) {     
      //  this.player.SetWarningMessage("N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
      // LogChannel(n"DEBUG", "N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
    }       
   
  }

  private func checkPlayerFunds(price: Int32) -> Bool {
    let playerMoney: Int32; 
    let transactionSys: ref<TransactionSystem>;
    transactionSys = GameInstance.GetTransactionSystem(this.GetGameInstance());

    playerMoney = transactionSys.GetItemQuantity(GetPlayer(this.GetGameInstance()), MarketSystem.Money());
    if playerMoney > price {
        return true;
    } else {
        this.player.SetWarningMessage( "Insufficient funds ("+price+" E$)"); 
        return false;  
    }
  }

  private func spendPlayerFunds(price: Int32) -> Bool {
    let playerMoney: Int32;
    let transactionSys: ref<TransactionSystem>;
    transactionSys = GameInstance.GetTransactionSystem(this.GetGameInstance());

    playerMoney = transactionSys.GetItemQuantity(GetPlayer(this.GetGameInstance()), MarketSystem.Money());
    if playerMoney > price { 
        transactionSys.RemoveItem(GetPlayer(this.GetGameInstance()), MarketSystem.Money(), 50);
        return true;
    } else {
        return false;
    }
  }

}

