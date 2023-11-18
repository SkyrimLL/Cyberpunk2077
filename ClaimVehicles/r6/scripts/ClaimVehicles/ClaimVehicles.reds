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

public class ClaimedVehicleTracking {
  public let player: wref<PlayerPuppet>;
  public let config: ref<ClaimVehiclesConfig>;
  public let vehicleDB: ref<ClaimVehicleDB>;

  public let modON: Bool;
  public let debugON: Bool;
  public let warningsON: Bool;  

  public let chanceOnSteal: Float;
  public let chanceLowPerkHack: Float;
  public let chanceMidPerkHack: Float;
  public let chanceHighPerkHack: Float;

  public let claimedVehiclesList: array<PlayerVehicle>;

  public let matchVehicle: PlayerVehicle; 
  public let matchVehicleRecordID: TweakDBID; 
  public let matchVehicleModel: String; 
  public let matchVehicleString: String;  
  public let matchVehicleUnlocked: Bool;

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

    // Toggle warning messages 
    // this.warningsON = true;

    // ------------------ End of Mod Options

    // For developers only 
    // this.debugON = true; 

  }

  public func refreshConfig() -> Void {
    this.vehicleDB = new ClaimVehicleDB();
    this.vehicleDB.init();
    this.config = new ClaimVehiclesConfig();
    this.invalidateCurrentState();
  }

  public func invalidateCurrentState() -> Void { 
    this.chanceOnSteal = Cast<Float>(this.config.chanceOnSteal); 
    this.chanceLowPerkHack = Cast<Float>(this.config.chanceLowPerkHack); 
    this.chanceMidPerkHack = Cast<Float>(this.config.chanceMidPerkHack); 
    this.chanceHighPerkHack = Cast<Float>(this.config.chanceHighPerkHack);   
    this.warningsON = this.config.warningsON;
    this.debugON = this.config.debugON;
    this.modON = this.config.modON;  
  }  

  // Mapping Vehicle plain text model string -> internal vehicle string ID
  //    Also converts variant vehicle model name to model name found in list of potential player vehicles
  //    Ex: Hella EC-D 1360 ->  Vehicle.v_standard2_archer_hella_player
  public func getVehicleStringFromModel(vehicleRecordID: TweakDBID, claimedVehicleModel: String) -> Void {
 
    this.matchVehicleUnlocked = false; 

    if (this.warningsON) {
      // LogChannel(n"DEBUG", "N.C.L.A.I.M: Reading Vehicle ID from Model: '"+claimedVehicleModel+"'"  );
    }

    // Universal vehicle detection
    this.matchVehicleRecordID = vehicleRecordID;
    this.matchVehicleModel = claimedVehicleModel;
    this.matchVehicleString = this.vehicleDB.lookupVehicleString(vehicleRecordID);
    this.matchVehicleUnlocked = this.isVehicleOwned();

    // TO DO: 
    //   Find out why vehicle is not saved! -> add exact model to missing cars yaml file
    //   Find out why vehicle is not summoned - test another call point

    if (this.warningsON) {
      // LogChannel(n"DEBUG", "N.C.L.A.I.M: Vehicle ID found: '"+this.matchVehicleString+"'"  );
    }
  }

  // Mapping Vehicle plain text model string -> vehicle record in list of potential player owned vehicles
  //    Assumes getVehicleStringFromModel() was already ran to convert variant vehicle model to model from player vehicles
  public func isVehicleOwned() -> Bool {
    let vehiclesList: array<PlayerVehicle>;

    let matchFound = false;
    let i = 0;

    // First look for a match in unlocked vehicles
    GameInstance.GetVehicleSystem(this.player.GetGame()).GetPlayerUnlockedVehicles(vehiclesList);

    if (this.warningsON) {
      // LogChannel(n"DEBUG", " ");
      // LogChannel(n"DEBUG", "----- ");
      // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Scanning known vehicles for '" + this.matchVehicleModel + "'");
      // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  " + ToString(ArraySize(vehiclesList)) + " vehicles currently registered.");
    }

    // Retrieve RecordID and vehicle type for the matched vehicle model
    while i < ArraySize(vehiclesList) { 
      let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
      let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());

      if (this.warningsON) {
        if (vehiclesList[i].isUnlocked) {
          // LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking database for '"+ _this_vehicleModel +"' - isUnlocked: " + vehiclesList[i].isUnlocked);
        } else {
          // LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking database for '"+ _this_vehicleModel +"'" );
        }
      }

      // if ( StrCmp(StrLower(_this_vehicleModel), StrLower(this.matchVehicleModel)) == 0 ) {
      if ( Equals( vehiclesList[i].recordID, this.matchVehicleRecordID  ) ){
        if (this.warningsON) { 
          // LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
        }
        matchFound = true;
 
        this.matchVehicle.recordID = vehiclesList[i].recordID;
        this.matchVehicle.vehicleType = vehiclesList[i].vehicleType;
        this.matchVehicleUnlocked = true;
      }

      i += 1;
    };  

    // If not nfound, scan whole list of player vehicles
    if (!matchFound) {
      i = 0;
      GameInstance.GetVehicleSystem(this.player.GetGame()).GetPlayerVehicles(vehiclesList);
      if (this.warningsON) {
        // LogChannel(n"DEBUG", " ");
        // LogChannel(n"DEBUG", "----- Fallback");
        // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Database online. " + ToString(ArraySize(vehiclesList)) + " records total");
        // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Scanning Criminal Asset Forfeiture database for '" + this.matchVehicleModel + "'");
      }
      // Retrieve RecordID and vehicle type for the matched vehicle model
      while i < ArraySize(vehiclesList) { 
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
          if (this.warningsON) { 
            // LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
          }
   
          this.matchVehicle.recordID = vehiclesList[i].recordID;
          this.matchVehicle.vehicleType = vehiclesList[i].vehicleType;
          this.matchVehicleUnlocked = vehiclesList[i].isUnlocked;

          if (this.matchVehicleUnlocked) {
            matchFound = true;
          }
        }
        i += 1;
      };  
    }

    if (this.warningsON) && (!matchFound) { 
      // LogChannel(n"DEBUG", ">>>  NO matching vehicle record ID.");
    }

    return matchFound;
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
        // this.tryPersistVehicle(vehicle);

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

  public func addClaimedVehicle(claimedVehicle: PlayerVehicle) -> Void {
    let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(claimedVehicle.recordID);
    let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());

    // Checking standard dealership database
    this.getVehicleStringFromModel(claimedVehicle.recordID, claimedVehicleModel);  


    if (!(StrCmp(this.matchVehicleString,"")==0)) { 
      // Vehicle is known to database

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

        if (this.warningsON) {     
          this.player.SetWarningMessage( ClaimVehiclesText.MATCH_FOUND() + " '"+claimedVehicleModel+"'");   
        } 

      }

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

        GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( this.matchVehicleString, false, false);

        GameInstance.GetVehicleSystem(this.player.GetGame()).TogglePlayerActiveVehicle(Cast<GarageVehicleID>(this.matchVehicle.recordID), this.matchVehicle.vehicleType, false);  

        if (this.warningsON) {     
          this.player.SetWarningMessage( ClaimVehiclesText.REMOVING() + " '"+claimedVehicleModel+"'");   
        } 
             
      } else {
        if (this.debugON) { 
          // LogChannel(n"DEBUG", ">>> Skipping removal - vehicle not owned");
        } 


      }

    } 

    if (this.warningsON) && (StrCmp(this.matchVehicleString,"") == 0) {     
      //  this.player.SetWarningMessage("N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
      // LogChannel(n"DEBUG", "N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
    }       
   
  }

}

