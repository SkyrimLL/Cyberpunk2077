// ClaimVehicles - by DeepBlueFrog 

// Virtual car dealer compatiblitiy
@if(ModuleExists("CarDealer.System"))
import CarDealer.System.PurchasableVehicleSystem

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

  public let quickhackManualModeON: Bool;
  public let remoteControlQuickhackON: Bool; 
  public let forceBrakesQuickhackON: Bool; 

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

  public cb func OnModSettingsChange() -> Void {
      this.showDebugMessage("[ClaimVehicles] Settings changed – applying update.");
      this.refreshConfig();  
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
    this.remoteControlQuickhackON = this.config.remoteControlQuickhackON;   
    this.forceBrakesQuickhackON = this.config.forceBrakesQuickhackON;   
    this.quickhackManualModeON = this.config.quickhackManualModeON;  
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
      this.showDebugMessage("N.C.L.A.I.M: Reading Vehicle ID from Model: '"+claimedVehicleModel+"'"  );
      this.showDebugMessage(">>> ClaimVehicles: getVehicleStringFromModel: searching for:" + TDBID.ToStringDEBUG(vehicleRecordID));
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
      this.showDebugMessage("N.C.L.A.I.M: Vehicle ID found: '"+this.matchVehicleString+"'"  );
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
      this.showDebugMessage(" ");
      this.showDebugMessage("----- ");
      this.showDebugMessage(">>> N.C.L.A.I.M:  Scanning known vehicles for '" + this.matchVehicleModel + "'");
      this.showDebugMessage(">>> N.C.L.A.I.M:  " + ToString(ArraySize(this.vehicleDB.vehiclesUnlockStateDB)) + " vehicles in history.");
    }

    // Refresh status of vehicles in case some vehicles were sold or removed by other means
    this.refreshClaimedVehicles();

    targetVehicle = this.vehicleDB.lookupVehicle(this.matchVehicleRecordID);

    if (Equals(targetVehicle.vehicleString, "")) {
      // Vehicle not found in database - Skip search
      this.showDebugMessage(">>> isVehicleAvailable: Vehicle not found in database - Skip search");

    } else { 

      // First try the current garage
      GameInstance.GetVehicleSystem(this.player.GetGame()).GetPlayerUnlockedVehicles(vehiclesList);
      while (i < ArraySize(vehiclesList)) { 
        let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
        let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());
        if (this.warningsON) {
          if (vehiclesList[i].isUnlocked) {
            this.showDebugMessage("N.C.L.A.I.M: Checking database for '"+ _this_vehicleModel +"' - isUnlocked: " + vehiclesList[i].isUnlocked);
          } else {
            this.showDebugMessage("N.C.L.A.I.M: Checking database for '"+ _this_vehicleModel +"'");
          }
          
        }
        // Compare by tweakID recordID
        if ( Equals( vehiclesList[i].recordID, this.matchVehicleRecordID  ) ){
   
          this.matchVehicle.recordID = vehiclesList[i].recordID;
          this.matchVehicle.vehicleType = vehiclesList[i].vehicleType;
          // 2023-12-30: Some vehicles remain unlocked after being added to player list -> need to keep parallel list of unlocked vehicles
          this.matchVehicleUnlocked = true; // vehiclesList[i].isUnlocked; // force vehicle unlocked sate to true if in current garage

          if (this.matchVehicleUnlocked) {
            if (this.warningsON) { 
              this.showDebugMessage(">>> Found matching vehicle by tweakID.");
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
              this.showDebugMessage("N.C.L.A.I.M: Checking claim history for '"+ _this_vehicleModel +"' [TweakID: " + TDBID.ToStringDEBUG(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID) + "] [Unlocked: " + ToString(thisVehicleUnlockedState) + "]");
            }

            // Compare by tweakID - more reliable than string matching
            if ( Equals( this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID, this.matchVehicleRecordID  ) ){
              if (this.warningsON) { 
                this.showDebugMessage(">>> Found matching vehicle by tweakID.");
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
              this.showDebugMessage("N.C.L.A.I.M: Checking original garage for '"+ _this_vehicleModel +"' [TweakID: " + TDBID.ToStringDEBUG(this.originalGarage[i]) + "] [Unlocked: " + ToString(thisVehicleUnlockedState) + "]");
            }

            // Compare by tweakID - more reliable than string matching
            if ( Equals( this.originalGarage[i], this.matchVehicleRecordID  ) ){
              if (this.warningsON) { 
                this.showDebugMessage(">>> Found matching vehicle by tweakID.");
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
          this.showDebugMessage(" ");
          this.showDebugMessage("----- Fallback");
          this.showDebugMessage(">>> N.C.L.A.I.M:  Database online. " + ToString(ArraySize(vehiclesList)) + " records total");
          this.showDebugMessage(">>> N.C.L.A.I.M:  Scanning Criminal Asset Forfeiture database for '" + this.matchVehicleModel + "'");
        }

        while (i < ArraySize(vehiclesList)) && (!matchFound) { 
          let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
          let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());
          thisVehicle = this.vehicleDB.lookupVehicle(vehiclesList[i].recordID);
          thisVehicleUnlockedState = this.vehicleDB.lookupVehicleUnlockState(vehiclesList[i].recordID); // vehiclesList[i].isUnlocked

          if (this.warningsON) {
            this.showDebugMessage("N.C.L.A.I.M: Checking database for '"+ _this_vehicleModel +"' [TweakID: " + TDBID.ToStringDEBUG(vehiclesList[i].recordID) + "]");
            if (thisVehicleUnlockedState) {
              this.showDebugMessage(">>> Vehicle unlocked: " + thisVehicleUnlockedState);
            } 
            
          }
          // Compare by tweakID recordID
          if ( Equals( vehiclesList[i].recordID, this.matchVehicleRecordID  ) ){
            if (this.warningsON) { 
              this.showDebugMessage(">>> Found matching vehicle by tweakID.");
            }

            if (thisVehicleUnlockedState) {
              this.matchVehicle.recordID = this.matchVehicleRecordID; // vehiclesList[i].recordID; 
              this.matchVehicle.vehicleType = vehiclesList[i].vehicleType;
              this.matchVehicleUnlocked = thisVehicleUnlockedState;

              if (this.warningsON) { 
                this.showDebugMessage(">>> Vehicle is already unlocked");
              }
              matchFound = true;
            }
          }
          i += 1;
        };  

      }
    }

    if (this.warningsON) && (!matchFound) { 
      this.showDebugMessage(">>>  NO matching vehicle record ID.");
    }

    return matchFound;
  }

  public func tryReportCrime(crimeOnSuccess: Bool) -> Void {
    let chanceCrimeReportFail: Int32 = Cast<Int32>(this.chanceCrimeReportFail); 
    let chanceCrimeReportSuccess: Int32 = Cast<Int32>(this.chanceCrimeReportSuccess);

    if (crimeOnSuccess) {
      this.showDebugMessage("::: tryReportCrime - Claim succeeded - reporting a crime"  );
      this.showDebugMessage("::: tryReportCrime - chanceCrimeReportSuccess: " + ToString(chanceCrimeReportSuccess) );
      if (RandRange(1,100) <= chanceCrimeReportSuccess) {
        this.player.SetWarningMessage( ClaimVehiclesText.CRIME());   
        // playerOwner.GetPreventionSystem().HeatPipeline("PlayerStoleVehicle");
        this.player.GetPreventionSystem().HeatPipeline("CrimeWitness");
      }
    } else {
      this.showDebugMessage("::: tryReportCrime - Claim failed - reporting a crime"  );
      this.showDebugMessage("::: tryReportCrime - chanceCrimeReportFail: " + ToString(chanceCrimeReportFail) );
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

    this.showDebugMessage(":: Entering tryClaimVehicle");
    this.showDebugMessage(":: tryClaimVehicle - vehClassName: " + vehClassName);
    this.showDebugMessage(":: tryClaimVehicle - addVehicle: " + ToString(addVehicle));

    let isVictorHUDInstalled: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_ripperdoc_done") >= 1;
    let isPhantomLiberyStandalone: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"ep1_standalone") >= 1;
 
    if (this.debugON) {
      this.showDebugMessage(":: tryClaimVehicle - isVictorHUDInstalled: " + isVictorHUDInstalled);
    }

    switch vehClassName {
      case "Car":
        claimVehicle = true;
        break;

      case "Bike":
        claimVehicle = true;
        break;
    };

    // this.showDebugMessage(":: tryClaimVehicle - claimVehicle: " + ToString(claimVehicle));
    if ( (isVictorHUDInstalled) || (isPhantomLiberyStandalone)) {

      if (this.warningsON) {
        this.showDebugMessage(" ");
        this.showDebugMessage("N.C.L.A.I.M:  Registering Forfeit Vehicle - " + vehClassName);
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
      let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(thisPlayerVehicle.recordID);
      let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());

      this.getVehicleStringFromModel(thisPlayerVehicle.recordID, claimedVehicleModel);  

      // check if vehicle is already owned in both old and new lists
      // Use matchVehicleUnlocked which checks database, not just current garage
      // (important for Last Vehicle mode where current garage may only contain one vehicle)
      // ALSO check for variant mappings by display name to prevent duplicate registrations
      // when the game maps variant IDs (e.g. cs_savable_yaiba_kusanagi -> NCA.v_sportbike1_yaiba_kusanagi)
      if this.matchVehicleUnlocked || this.checkVehicleInSavedGarage(this.matchVehicleRecordID) || this.checkVehicleVariantInGarage(thisPlayerVehicle.recordID) {
        // Vehicle is already owned - skip all add/remove operations
        if (this.debugON) {
          this.showDebugMessage(":: tryClaimVehicle - vehicle already owned (matchVehicleUnlocked: " + ToString(this.matchVehicleUnlocked) + "), skipping");
        }

        if (claimVehicle && addVehicle)
        {
          // this.addClaimedVehicle(thisPlayerVehicle); 

        } else {
          // Remove from managed vehicles list
          this.removeClaimedVehicle(thisPlayerVehicle);

        }

      } else {
        // Vehicle is not owned yet - proceed with claim or remove logic
        if (this.debugON) {
          this.showDebugMessage(":: tryClaimVehicle - vehicle not found in ownership records");
        }
        
        if (claimVehicle && addVehicle)
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
    let allVehiclesList: array<PlayerVehicle>;
    let i = 0;

    m_vehicleSystem.GetPlayerUnlockedVehicles(vehiclesList); 
     
    // Invalidate persistent history
    while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
      this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = false;

      i += 1;
    }; 

    // Refresh history from current owned list
    i = 0;

    this.showDebugMessage(">>> N.C.L.A.I.M:  Garage list: " + ToString(ArraySize(vehiclesList)) + " vehicles currently registered.");

    while i < ArraySize(vehiclesList) {    
      this.showDebugMessage(">>> N.C.L.A.I.M:  Claimed vehicles state refresh: " + TDBID.ToStringDEBUG(vehiclesList[i].recordID)  );
 
      this.vehicleDB.setVehicleUnlockState(vehiclesList[i].recordID, true);

      i += 1;
    };

    // Sync originalGarage against the full player vehicle list (includes disabled vehicles,
    // but excludes sold ones) to detect vehicles removed via other mods.
    // Without this, loadGarage() will blindly re-enable sold vehicles the next time
    // the garage is restored (e.g. when switching back to Normal mode).
    m_vehicleSystem.GetPlayerVehicles(allVehiclesList);
    i = 0;
    while i < ArraySize(this.originalGarage) {
      let bStillOwned: Bool = false;
      let j: Int32 = 0;
      while j < ArraySize(allVehiclesList) {
        if this.originalGarage[i] == allVehiclesList[j].recordID {
          bStillOwned = true;
        }
        j += 1;
      };
      if !bStillOwned {
        this.showDebugMessage(">>> refreshClaimedVehicles: pruning sold vehicle from originalGarage: " + TDBID.ToStringDEBUG(this.originalGarage[i]));
        ArrayErase(this.originalGarage, i);
        // Do NOT increment i — the next element has shifted into position i
      } else {
        i += 1;
      };
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
        this.showDebugMessage(">>> N.C.L.A.I.M:  Garage refresh: Normal Mode"   );

        if  (!this.useOriginalGarage) {
          this.loadGarage();
          this.useOriginalGarage = true; 
        }
        
        /*
        while i < ArraySize(vehiclesList) {     
          this.enablePlayerVehicle( vehiclesList[i].recordID, true, false);
          this.vehicleDB.setVehicleUnlockState(vehiclesList[i].recordID, true);

          i += 1;
        };  
        */  
            
        break;
      // Last mode - enable only last vehicle claimed 
      case vehicleSummonMode.Last:
        this.showDebugMessage(">>> N.C.L.A.I.M:  Garage refresh: Last Mode"   );
        this.showDebugMessage(">>> lastVehicleRecordID: " + TDBID.ToStringDEBUG(this.lastVehicleRecordID));
        this.showDebugMessage(">>> lastVehicleRecordID IsValid: " + ToString(TDBID.IsValid(this.lastVehicleRecordID)));
        
        if (this.debugON) {
          this.showDebugMessage(">>> Current garage state BEFORE clearGarage:");
          this.printGarage();
        }
        
        if (!TDBID.IsValid(this.lastVehicleRecordID) || Equals(this.lastVehicleRecordID, t"")) {
          // Last vehicle was removed or not set, pick a random one
          if (this.debugON) {
            this.showDebugMessage(">>> lastVehicleRecordID is empty, picking random vehicle");
          }
          if  (this.useOriginalGarage) {
            this.saveGarage();
            this.useOriginalGarage = false; 
          }
          this.clearGarage();
          this.enableRandomVehicle();
        } else {
          if  (this.useOriginalGarage) {
            this.saveGarage();
            this.useOriginalGarage = false; 
          }

          this.clearGarage();
          
          if (this.debugON) {
            this.showDebugMessage(">>> Current garage state AFTER clearGarage:");
            this.printGarage();
          }
          
          i = 0;
          while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
            _this_vehicleString = this.vehicleDB.lookupVehicleString(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID);
            let _vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID);
            let _vehicleType: gamedataVehicleType = _vehicleRecord.Type().Type();
            let _vehicleModel: String = GetLocalizedItemNameByCName(_vehicleRecord.DisplayName());
            // Only process vehicles that should be enabled (match lastVehicleRecordID)
            if (this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID == this.lastVehicleRecordID) {
                // Only enable if the vehicle is actually unlocked in our database
                if (this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked) {
                  this.showDebugMessage(">>> Enabling last vehicle: " + _vehicleModel);
                  m_vehicleSystem.TogglePlayerActiveVehicle(Cast<GarageVehicleID>(this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID), _vehicleType, true);
                  this.enablePlayerVehicle( this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID, true, false);
                  this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = true;
                  matchFound = true;
                } else {
                  // Last vehicle was removed, disable it and pick a random one
                  this.showDebugMessage(">>> Last vehicle was removed, disabling: " + _vehicleModel);
                  this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = false;
                }

              } else {
                // Just update database state - don't call TogglePlayerActiveVehicle
                // since clearGarage() already removed all vehicles from the active garage
                if (this.debugON) {
                  this.showDebugMessage(">>> Marking vehicle as disabled in DB: " + _vehicleModel);
                }
                this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = false;
              }

            i += 1;
          };  

          // Fallback on random pick if last vehicle is not found
          if (!matchFound) {
            this.enableRandomVehicle();
          }
          
          // Debug: print final garage state after Last Mode processing
          if (this.debugON) {
            this.showDebugMessage(">>> After Last Mode processing:");
            this.printGarage();
          }
        }
     
        break;
      // Random mode - enable random known vehicle   
      case vehicleSummonMode.Random:
        this.showDebugMessage(">>> N.C.L.A.I.M:  Garage refresh: Random Mode"   );
        
        if  (this.useOriginalGarage) {
          this.saveGarage();
          this.useOriginalGarage = false; 
        }

        this.clearGarage();
        
        this.enableRandomVehicle();

        break;
      // Delamain mode - enable only Delamain models 
      case vehicleSummonMode.Delamain:
        this.showDebugMessage(">>> N.C.L.A.I.M:  Garage refresh: Delamain Mode"   );
        
        if  (this.useOriginalGarage) {
          this.saveGarage();
          this.useOriginalGarage = false; 
        }

        this.clearGarage();
        
        i = 0;
        while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) { 
            // Check if vehicle is a Delamain by tweakID pattern
            let _currentTweakID: TweakDBID = this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID;
            let _isDelamain: Bool = this.isDelamainVehicle(_currentTweakID);
            
            // Disable all vehicles except Delamains
            if (_isDelamain) {
              this.enablePlayerVehicle(  _currentTweakID, true, false);
              this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = true;

            } else {
              this.enablePlayerVehicle(  _currentTweakID, false, false);
            }

          i += 1;
        };

        break;
      // Favorite mode - enable only favorite vehicles [TBD]
      case vehicleSummonMode.Favorites:
        this.showDebugMessage(">>> N.C.L.A.I.M:  Garage refresh: Favorite Mode"   );
        
        if  (this.useOriginalGarage) {
          this.saveGarage();
          this.useOriginalGarage = false; 
        }

        this.clearGarage();

        while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) {  
          // Disable all vehicles except favorites
          if (this.vehicleDB.vehiclesUnlockStateDB[i].vehicleFavorite) {
              this.enablePlayerVehicle( this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID, true, false);
              this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = true;
              matchFound = true;

            } else {
              this.enablePlayerVehicle( this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID, false, false);
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
        this.showDebugMessage(">>> N.C.L.A.I.M:  Garage refresh: All Mode"   );
        
        if  (this.useOriginalGarage) {
          this.saveGarage();
          this.useOriginalGarage = false; 
        }

        this.clearGarage();

        while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) {  
          this.enablePlayerVehicle(  this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID, true, false);
          this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = true;

          i += 1;
        }; 
        break;
    };      

    // Re-apply all claimed vehicles to ensure the game's vehicle system reflects the current state
    // This ensures the UI shows the correct vehicles after any mode change
    this.reapplyClaimedVehicles();

    if (this.debugON) { 
        this.printGarage(); 
        } 
  }

  // Check if a vehicle is a Delamain by comparing tweakID
  public func isDelamainVehicle(_vehicleID: TweakDBID) -> Bool {
    // List of known Delamain vehicle tweakIDs
    let delamainIDs: array<TweakDBID>;
    
    // Add all known Delamain variants
    ArrayPush(delamainIDs, t"Vehicle.v_standard25_mahir_supron_player");  // Del's car
    ArrayPush(delamainIDs, t"Vehicle.v_standard25_mahir_supron_corp");    // Del's car variant
    ArrayPush(delamainIDs, t"Vehicle.v_sport2_villefort_delامain");       // Delamain fleet
    
    // Compare against all known Delamain tweakIDs
    let i: Int32 = 0;
    while i < ArraySize(delamainIDs) {
      if Equals(_vehicleID, delamainIDs[i]) {
        return true;
      }
      i += 1;
    }
    
    return false;
  }

  // Pick a random vehicle from history and enables it
  public func enableRandomVehicle() -> Void { 
    let _this_vehicleString: String;
    let i = 0;

    i = 0;
    let randomNum: Int32 = RandRange(0,ArraySize(this.vehicleDB.vehiclesUnlockStateDB)-1);

    while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) {  
      // Disable all vehicles except a random one
      if (i == randomNum) {
          this.enablePlayerVehicle( this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID, true, false);
          this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = true;
          // Update lastVehicleRecordID when in Last mode
          if (Equals(this.summonMode, vehicleSummonMode.Last)) {
            this.lastVehicleRecordID = this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID;
            if (this.debugON) {
              this.showDebugMessage(">>> Updated lastVehicleRecordID to random vehicle");
            }
          }

        } else {
          this.enablePlayerVehicle( this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID, false, false);
          this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = false;
        }

      i += 1;
    }; 

  }

  // ACheck if vehicle is in virtual garage list
  public func checkVehicleInSavedGarage(_id: TweakDBID) -> Bool { 
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

    return bVehicleFound;
  }

  // Check if any variant of a vehicle (by display name) is in the garage
  // This detects cases where the game maps variant IDs (e.g. cs_savable_* -> NCA.*)
  public func checkVehicleVariantInGarage(_id: TweakDBID) -> Bool {
    let m_vehicleSystem: ref<VehicleSystem> = GameInstance.GetVehicleSystem(this.player.GetGame());
    let vehiclesList: array<PlayerVehicle>;
    let requestedRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(_id);
    let requestedModel: String = GetLocalizedItemNameByCName(requestedRecord.DisplayName());
    let i: Int32 = 0;

    m_vehicleSystem.GetPlayerUnlockedVehicles(vehiclesList);

    while i < ArraySize(vehiclesList) {
      let garageRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
      let garageModel: String = GetLocalizedItemNameByCName(garageRecord.DisplayName());

      // Compare display names (case-insensitive) to detect variants
      if (StrCmp(StrLower(garageModel), StrLower(requestedModel)) == 0) {
        if (this.debugON) {
          this.showDebugMessage(">>> checkVehicleVariantInGarage: Found variant mapping!");
          this.showDebugMessage(">>> Requested ID: " + TDBID.ToStringDEBUG(_id));
          this.showDebugMessage(">>> Found in garage: " + TDBID.ToStringDEBUG(vehiclesList[i].recordID));
        }
        return true;
      }

      i += 1;
    }

    return false;
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
    
    this.showDebugMessage(">>> clearGarage: clearing " + ToString(ArraySize(vehiclesList)) + " vehicles");

    while i < ArraySize(vehiclesList) {       
      let _rec: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
      let _name: String = GetLocalizedItemNameByCName(_rec.DisplayName());
      
      if (this.debugON) {
        this.showDebugMessage(">>>   Clearing: " + _name + " [" + TDBID.ToStringDEBUG(vehiclesList[i].recordID) + "]");
      }
      
      // Also remove from vehicle registry, not just disable
      m_vehicleSystem.TogglePlayerActiveVehicle(Cast<GarageVehicleID>(vehiclesList[i].recordID), vehiclesList[i].vehicleType, false);
      this.enablePlayerVehicle( vehiclesList[i].recordID, false, false); 

      i += 1;
    }; 
    
    this.showDebugMessage(">>> clearGarage: complete");
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
      this.showDebugMessage(">>> N.C.L.A.I.M:  loadGarage: " + TDBID.ToStringDEBUG(this.originalGarage[i] ) );
      this.enablePlayerVehicle(  this.originalGarage[i], true, false);
      this.vehicleDB.setVehicleUnlockState(this.originalGarage[i], true);

      i += 1;
    }; 
  }

  // Re-registers every vehicle that vehiclesUnlockStateDB records as unlocked.
  // Called just before VehiclesManagerPopupGameController.SetupData() queries
  // GetPlayerUnlockedVehicles(), because the game engine may silently evict
  // NPC-origin vehicles between the claim event and the popup open.
  public func reapplyClaimedVehicles() -> Void {
    let i: Int32 = 0;
    this.showDebugMessage(">>> reapplyClaimedVehicles: re-registering all claimed vehicles");
    this.showDebugMessage(">>> Total vehicles in DB: " + ToString(ArraySize(this.vehicleDB.vehiclesUnlockStateDB)));
    this.showDebugMessage(">>> Current summon mode: " + ToString(this.summonMode));
    this.showDebugMessage(">>> Last vehicle ID: " + TDBID.ToStringDEBUG(this.lastVehicleRecordID));
    
    while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) {
      let _id: TweakDBID = this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID;
      let _unlocked: Bool = this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked;
      let _rec: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(_id);
      let _name: String = GetLocalizedItemNameByCName(_rec.DisplayName());
      
      this.showDebugMessage(">>> [" + ToString(i) + "] " + _name + " - unlocked: " + ToString(_unlocked));
      
      if _unlocked {
        let _type: gamedataVehicleType = _rec.Type().Type();
        this.showDebugMessage(">>>   -> Re-registering: " + TDBID.ToStringDEBUG(_id));
        GameInstance.GetVehicleSystem(this.player.GetGame()).TogglePlayerActiveVehicle(Cast<GarageVehicleID>(_id), _type, true);
        this.enablePlayerVehicle(_id, true, false);
      } else {
        if (this.debugON) {
          this.showDebugMessage(">>>   -> Skipping (marked as locked in DB)");
        }
      }
      i += 1;
    };
    
    this.showDebugMessage(">>> reapplyClaimedVehicles: complete");
  }

  // Debug: dump GetPlayerUnlockedVehicles() to the debug console.
  // Also reports whether matchVehicleRecordID is present in the list.
  public func printGarage() -> Void {
    let _dbgVehicleSystem: ref<VehicleSystem> = GameInstance.GetVehicleSystem(this.player.GetGame());
    let _dbgAllVehicles: array<PlayerVehicle>;
    _dbgVehicleSystem.GetPlayerUnlockedVehicles(_dbgAllVehicles);
    this.showDebugMessage(">>> printGarage: unlocked vehicle count: " + ToString(ArraySize(_dbgAllVehicles)));
    let _dbgIdx: Int32 = 0;
    let _dbgFound: Bool = false;
    while _dbgIdx < ArraySize(_dbgAllVehicles) {
      let _dbgRec: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(_dbgAllVehicles[_dbgIdx].recordID);
      let _dbgName: String = GetLocalizedItemNameByCName(_dbgRec.DisplayName());
      this.showDebugMessage(">>>   [" + ToString(_dbgIdx) + "] " + TDBID.ToStringDEBUG(_dbgAllVehicles[_dbgIdx].recordID) + " (" + _dbgName + ")");
      if _dbgAllVehicles[_dbgIdx].recordID == this.matchVehicleRecordID {
        _dbgFound = true;
      }
      _dbgIdx += 1;
    };
    this.showDebugMessage(">>> printGarage: target vehicle present: " + ToString(_dbgFound));
  }

  // Display all vehicles the player can own, including those that are disabled by the current mode. 
  // This is useful for debugging the vehicle database and verifying that vehicles are being correctly registered and tracked.
  public func printAllvehicles() -> Void {
    let _dbgVehicleSystem: ref<VehicleSystem> = GameInstance.GetVehicleSystem(this.player.GetGame());
    let _dbgAllVehicles: array<PlayerVehicle>;
    _dbgVehicleSystem.GetPlayerVehicles(_dbgAllVehicles);
    this.showDebugMessage(">>> printAllvehicles: total vehicle count: " + ToString(ArraySize(_dbgAllVehicles)));
    let _dbgIdx: Int32 = 0;
    let _dbgFound: Bool = false;
    while _dbgIdx < ArraySize(_dbgAllVehicles) {
      let _dbgRec: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(_dbgAllVehicles[_dbgIdx].recordID);
      let _dbgName: String = GetLocalizedItemNameByCName(_dbgRec.DisplayName());
      this.showDebugMessage(">>>   [" + ToString(_dbgIdx) + "] " + TDBID.ToStringDEBUG(_dbgAllVehicles[_dbgIdx].recordID) + " (" + _dbgName + ")");
      if _dbgAllVehicles[_dbgIdx].recordID == this.matchVehicleRecordID {
        _dbgFound = true;
      }
      _dbgIdx += 1;
    };
    this.showDebugMessage(">>> printAllvehicles: target vehicle present: " + ToString(_dbgFound));
  }


  public func refreshClaimedVehiclesOnLoad() -> Void {
    let m_vehicleSystem: ref<VehicleSystem> = GameInstance.GetVehicleSystem(this.player.GetGame());
    let allVehiclesList: array<PlayerVehicle>;
    let i = 0;

    // Fetch the full player vehicle roster (includes mode-disabled vehicles,
    // excludes vehicles that were sold or removed by other mods).
    m_vehicleSystem.GetPlayerVehicles(allVehiclesList);

    while i < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) {  
      let _this_vehicleUnlockState: Bool = this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked;
      let _this_vehicleRecordID: TweakDBID = this.vehicleDB.vehiclesUnlockStateDB[i].vehicleRecordID;

      // Verify the vehicle is still in the player's roster before restoring its state.
      // Without this check a vehicle sold via another mod would be silently re-added on
      // every session load because refreshClaimedVehiclesOnLoad runs before any
      // refreshClaimedVehicles call can correct the stale vehicleUnlocked = true entry.
      let bStillOwned: Bool = false;
      let j: Int32 = 0;
      while j < ArraySize(allVehiclesList) {
        if allVehiclesList[j].recordID == _this_vehicleRecordID {
          bStillOwned = true;
        }
        j += 1;
      };

      if bStillOwned {
        this.enablePlayerVehicle(_this_vehicleRecordID, _this_vehicleUnlockState, false);
      } else if _this_vehicleUnlockState {
        // Vehicle is no longer owned; clear the stale unlock flag so it cannot
        // be re-enabled by a later refreshClaimedVehiclesOnLoad call.
        this.vehicleDB.vehiclesUnlockStateDB[i].vehicleUnlocked = false;
        this.showDebugMessage(">>> refreshClaimedVehiclesOnLoad: sold vehicle pruned from unlock state: " + TDBID.ToStringDEBUG(_this_vehicleRecordID));
      }

      i += 1;
    };       
  }

  public func addClaimedVehicle(claimedVehicle: PlayerVehicle) -> Void {
    let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(claimedVehicle.recordID);
    let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());

    if (this.debugON) { 
      this.showDebugMessage(">>> try addClaimedVehicle");
    }  

    // Checking standard dealership database
    // this.getVehicleStringFromModel(claimedVehicle.recordID, claimedVehicleModel);  

    // Check if vehicle has valid tweakID in database
    if (TDBID.IsValid(this.matchVehicleRecordID) && !Equals(this.matchVehicleRecordID, t"")) { 
      // Vehicle is known to database
      this.lastVehicleRecordID = this.matchVehicleRecordID;

      if (this.matchVehicleUnlocked) {
        if (this.debugON) { 
          //this.showDebugMessage(">>> Skipping registration - vehicle already unlocked");
        }  
             
      } else {

        if (this.debugON) {
          this.showDebugMessage("N.C.L.A.I.M: Scanning Criminal Asset Forfeiture database for '"+claimedVehicleModel+"'.");        
        }

        if (this.warningsON) {
          this.showDebugMessage("N.C.L.A.I.M: Vehicle code extracted: '"+this.matchVehicleString+"'"  );   
        }

        // Register the vehicle first so EnablePlayerVehicle can find it.
        // For sold or never-owned vehicles the vehicle is absent from the active registry;
        // calling enablePlayerVehicle before TogglePlayerActiveVehicle silently fails because
        // there is no entry to enable yet. Mirror the remove path (deregister → disable)
        // in reverse: register first, then enable.
        // Use matchVehicleRecordID (always correctly set by getVehicleStringFromModel) and
        // claimedVehicle.vehicleType (from the actual vehicle object) rather than
        // matchVehicle.recordID / vehicleType which may be stale if no lookup path matched.
        
        this.showDebugMessage(">>> Attempting to register vehicle: " + TDBID.ToStringDEBUG(this.matchVehicleRecordID));
        this.showDebugMessage(">>> Original claimed vehicle: " + TDBID.ToStringDEBUG(claimedVehicle.recordID));
        
        GameInstance.GetVehicleSystem(this.player.GetGame()).TogglePlayerActiveVehicle(Cast<GarageVehicleID>(this.matchVehicleRecordID), claimedVehicle.vehicleType, true);

        // IMPORTANT: The game engine may map the requested variant to a different canonical variant.
        // We need to find what the game actually registered, not what we asked for.
        // Search the garage for vehicles with matching display name to find the actual registered variant.
        let actualRegisteredID: TweakDBID = this.matchVehicleRecordID;
        let garageVehicles: array<PlayerVehicle>;
        GameInstance.GetVehicleSystem(this.player.GetGame()).GetPlayerUnlockedVehicles(garageVehicles);
        
        let k: Int32 = 0;
        let _requestedModel: String = claimedVehicleModel;
        while k < ArraySize(garageVehicles) {
          let _checkRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(garageVehicles[k].recordID);
          let _checkModel: String = GetLocalizedItemNameByCName(_checkRecord.DisplayName());
          
          // Compare display names to detect if game mapped to a different variant
          // This is necessary because game may register a different tweakID variant than requested
          if (StrCmp(StrLower(_checkModel), StrLower(_requestedModel)) == 0) {
            // Found a vehicle with matching display name - check if tweakID differs
            if (!Equals(garageVehicles[k].recordID, actualRegisteredID)) {
              this.showDebugMessage(">>> VARIANT MAPPING DETECTED!");
              this.showDebugMessage(">>> Requested tweakID: " + TDBID.ToStringDEBUG(actualRegisteredID));
              this.showDebugMessage(">>> Actually registered tweakID: " + TDBID.ToStringDEBUG(garageVehicles[k].recordID));
              actualRegisteredID = garageVehicles[k].recordID;
            }
            break;
          }
          k += 1;
        }

        this.enablePlayerVehicle( actualRegisteredID, true, false);

        this.vehicleDB.setVehicleUnlockState(actualRegisteredID, true);

        // In Normal mode: explicitly push to originalGarage since enablePlayerVehicle
        // will already have made the vehicle visible, so addVehicleToSavedGarage's
        // GetPlayerUnlockedVehicles check would find it and skip it.
        // In alternate modes: keep existing behaviour — addVehicleToSavedGarage checks
        // the unlocked list and only adds if the vehicle isn't already there.
        if this.useOriginalGarage {
          ArrayPush(this.originalGarage, actualRegisteredID);
        } else {
          this.addVehicleToSavedGarage(actualRegisteredID);
        }

        // Virtual car dealer compatiblitiy: trigger a silent 'Buyback' of a vehicle stolen after selling it through VCD
        this.triggerVCDBuyback(actualRegisteredID);
        
        // Update lastVehicleRecordID to the actual registered variant
        this.lastVehicleRecordID = actualRegisteredID;
        
        // In Last Mode: immediately update database to mark all OTHER vehicles as unlocked=false
        // This ensures reapplyClaimedVehicles() doesn't re-register old vehicles when UI opens
        if Equals(this.summonMode, vehicleSummonMode.Last) {
          this.showDebugMessage(">>> Last Mode: Updating database to disable all vehicles except: " + TDBID.ToStringDEBUG(actualRegisteredID));
          let k: Int32 = 0;
          while k < ArraySize(this.vehicleDB.vehiclesUnlockStateDB) {
            let _checkRec: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(this.vehicleDB.vehiclesUnlockStateDB[k].vehicleRecordID);
            let _checkName: String = GetLocalizedItemNameByCName(_checkRec.DisplayName());
            
            if this.vehicleDB.vehiclesUnlockStateDB[k].vehicleRecordID != actualRegisteredID {
              if this.vehicleDB.vehiclesUnlockStateDB[k].vehicleUnlocked {
                this.showDebugMessage(">>> Last Mode: marking old vehicle as unlocked=false in DB: " + _checkName);
                this.vehicleDB.vehiclesUnlockStateDB[k].vehicleUnlocked = false;
              } else {
                if (this.debugON) {
                  this.showDebugMessage(">>> Last Mode: vehicle already marked as locked in DB: " + _checkName);
                }
              }
            } else {
              this.showDebugMessage(">>> Last Mode: keeping NEW vehicle as unlocked=true in DB: " + _checkName);
            }
            k += 1;
          };
          this.showDebugMessage(">>> Last Mode: Database update complete");
        }

        this.tryReportCrime(true);
 
        if (this.warningsON) {     
          this.player.SetWarningMessage( ClaimVehiclesText.MATCH_FOUND() + " '"+claimedVehicleModel+"'");   
        } 

      }

      this.refreshGarage(); 
 
    } 

    // Warn if vehicle not found in database (invalid tweakID)
    if (this.warningsON) && (!TDBID.IsValid(this.matchVehicleRecordID) || Equals(this.matchVehicleRecordID, t"")) {     
      this.player.SetWarningMessage("N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
      this.showDebugMessage("N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
    }       
   
  }


  public func removeClaimedVehicle(claimedVehicle: PlayerVehicle) -> Void {
    let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(claimedVehicle.recordID);
    let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());

    this.showDebugMessage(">>> try removeClaimedVehicle for: " + claimedVehicleModel);
    this.showDebugMessage(">>> Original vehicle recordID: " + TDBID.ToStringDEBUG(claimedVehicle.recordID));
    this.showDebugMessage(">>> matchVehicleRecordID: " + TDBID.ToStringDEBUG(this.matchVehicleRecordID));
    this.showDebugMessage(">>> matchVehicleString: " + this.matchVehicleString);
    this.showDebugMessage(">>> matchVehicleUnlocked: " + ToString(this.matchVehicleUnlocked));

    // Checking standard dealership database
    // this.getVehicleStringFromModel(claimedVehicle.recordID, claimedVehicleModel);  

    // Check if vehicle has valid tweakID in database
    if (TDBID.IsValid(this.matchVehicleRecordID) && !Equals(this.matchVehicleRecordID, t"")) { 
      // Vehicle is known to database

      if (this.matchVehicleUnlocked) {
 

        if (this.debugON) {
          this.showDebugMessage("N.C.L.A.I.M: Scanning Criminal Asset Forfeiture database for '"+claimedVehicleModel+"'.");        
        }

        if (this.warningsON) {
          this.showDebugMessage("N.C.L.A.I.M: Vehicle code extracted: '"+this.matchVehicleString+"'"  );   
        }

        // First disable the vehicle
        this.enablePlayerVehicle( this.matchVehicleRecordID, false, false);

        // Then deregister it from the garage
        GameInstance.GetVehicleSystem(this.player.GetGame()).TogglePlayerActiveVehicle(Cast<GarageVehicleID>(this.matchVehicle.recordID), this.matchVehicle.vehicleType, false);  

        // Update database state
        this.vehicleDB.setVehicleUnlockState(this.matchVehicleRecordID, false);

        if (this.debugON) {
          this.showDebugMessage(">>> Vehicle unlock state after removal: " + ToString(this.vehicleDB.lookupVehicleUnlockState(this.matchVehicleRecordID)));
        }

        // Remove from originalGarage to prevent re-enabling in alternate modes
        let j: Int32 = 0;
        while j < ArraySize(this.originalGarage) {
          if (this.originalGarage[j] == this.matchVehicleRecordID) {
            ArrayErase(this.originalGarage, j);
            if (this.debugON) {
              this.showDebugMessage(">>> Removed vehicle from originalGarage");
            }
            break;
          }
          j += 1;
        }

        // Clear lastVehicleRecordID if we're removing the last vehicle
        if (this.matchVehicleRecordID == this.lastVehicleRecordID) {
          this.showDebugMessage(">>> Clearing lastVehicleRecordID (was: " + TDBID.ToStringDEBUG(this.lastVehicleRecordID) + ")");
          this.lastVehicleRecordID = t"";
          this.showDebugMessage(">>> lastVehicleRecordID after clear - IsValid: " + ToString(TDBID.IsValid(this.lastVehicleRecordID)));
        }
 
        if (this.warningsON) {     
          this.player.SetWarningMessage( ClaimVehiclesText.REMOVING() + " '"+claimedVehicleModel+"'");   
        } 
             
      } else {
        if (this.debugON) { 
          this.showDebugMessage(">>> Skipping removal - vehicle not owned");
        } 


      }

      this.refreshGarage(); 

    } 

    // Warn if vehicle not found in database (invalid tweakID)
    if (this.warningsON) && (!TDBID.IsValid(this.matchVehicleRecordID) || Equals(this.matchVehicleRecordID, t"")) {     
      this.player.SetWarningMessage("N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
      this.showDebugMessage("N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
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

  private func showDebugMessage(debugMessage: String) {
    // LogChannel(n"DEBUG", debugMessage );  
  }

// Compatibility with Codeware mod: use EnablePlayerVehicleID instead of EnablePlayerVehicle if Codeware is installed
@if(!ModuleExists("Codeware"))
  public func enablePlayerVehicle(_vehicleId: TweakDBID, _enable: Bool, _despawnIfDisabling: Bool) -> Void {
      let _this_vehicleString: String = this.vehicleDB.lookupVehicleString(_vehicleId);
      GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, _enable, _despawnIfDisabling );
  }

@if(ModuleExists("Codeware"))
  public func enablePlayerVehicle(_vehicleId: TweakDBID, _enable: Bool, _despawnIfDisabling: Bool) -> Void { 
      // this.showDebugMessage(">>> enablePlayerVehicle: codeware version");   
      let vehicleSystem = GameInstance.GetVehicleSystem(GetGameInstance());
      vehicleSystem.EnablePlayerVehicleID(_vehicleId, _enable, _despawnIfDisabling);
  }

// Compatibility with Virtual Car Dealer mod: trigger a silent 'Buyback' of a vehicle stolen after selling it through VCD
@if(!ModuleExists("CarDealer.System"))
  public func triggerVCDBuyback(_vehicleId: TweakDBID) -> Void {
      let _this_vehicleString: String = this.vehicleDB.lookupVehicleString(_vehicleId);
      // If VCD is not installed, this method does nothing
      // GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( _this_vehicleString, true, false );
  }

@if(ModuleExists("CarDealer.System"))
  public func triggerVCDBuyback(_vehicleId: TweakDBID) -> Void {
      let _this_vehicleString: String = this.vehicleDB.lookupVehicleString(_vehicleId);
      // If VCD is installed, trigger a silent 'Buyback' of a vehicle stolen after selling it through VCD
      PurchasableVehicleSystem.GetInstance(this.player.GetGame()).Purchase(_vehicleId);
      
  }


}

