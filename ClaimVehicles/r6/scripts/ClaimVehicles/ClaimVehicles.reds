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
    this.player = player;
    this.reset();
  }

  private func reset() -> Void {
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

  public func tryClaimVehicle(vehicle: ref<VehicleObject>) -> Void {
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

      this.addClaimedVehicle(thisPlayerVehicle);

      this.tryPersistVehicle(vehicle);

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
}

@addField(PlayerPuppet)
public let m_claimedVehicleTracking: ref<ClaimedVehicleTracking>;

// -- PlayerPuppet
@addMethod(PlayerPuppet)
// Overload method from - https://codeberg.org/adamsmasher/cyberpunk/src/branch/master/cyberpunk/player/player.swift#L1974
  private final func InitClaimVehicleSystem() -> Void {
    // set up tracker if it doesn't exist
    if !IsDefined(this.m_claimedVehicleTracking) {
      this.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      this.m_claimedVehicleTracking.init(this);
    } else {
      // Reset if already exists (in case of changed default values)
      this.m_claimedVehicleTracking.reset();
    };
  }

// public class VehiclesManagerDataHelper extends IScriptable {
@replaceMethod(VehiclesManagerDataHelper)

  public final static func GetVehicles(player: ref<GameObject>) -> array<ref<IScriptable>> {
    let owner: ref<PlayerPuppet> = player as PlayerPuppet;
    let currentData: ref<VehicleListItemData>;
    let i: Int32;
    let result: array<ref<IScriptable>>;
    let vehicle: PlayerVehicle;
    let vehicleRecord: ref<Vehicle_Record>;
    let vehiclesList: array<PlayerVehicle>;
    let claimedVehiclesList: array<PlayerVehicle>;
 
    // Original list of player owned vehicles
    // GameInstance.GetVehicleSystem(player.GetGame()).GetPlayerVehicles(vehiclesList);
    GameInstance.GetVehicleSystem(player.GetGame()).GetPlayerUnlockedVehicles(vehiclesList);
    i = 0;
    while i < ArraySize(vehiclesList) {
      vehicle = vehiclesList[i];
      if (TDBID.IsValid(vehicle.recordID)){
        vehicleRecord = TweakDBInterface.GetVehicleRecord(vehicle.recordID);
        currentData = new VehicleListItemData();
        currentData.m_displayName = vehicleRecord.DisplayName();
        currentData.m_icon = vehicleRecord.Icon();
        currentData.m_data = vehicle;
        ArrayPush(result, currentData);
      };
      i += 1;
    };

      

    return result;
  }

// public class DriveEvents extends VehicleEventsTransition {

@replaceMethod(DriveEvents) 

public final func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
    let owner: ref<PlayerPuppet>;
    let transition: PuppetVehicleState = this.GetPuppetVehicleSceneTransition(stateContext);

    if Equals(transition, PuppetVehicleState.CombatSeated) || Equals(transition, PuppetVehicleState.CombatWindowed) {
      this.SendEquipmentSystemWeaponManipulationRequest(scriptInterface, EquipmentManipulationAction.RequestLastUsedOrFirstAvailableWeapon);
    };

    let playerOwner: ref<PlayerPuppet>;
    let vehicle: ref<VehicleObject>;
    let currentData: ref<VehicleListItemData>;
 
    playerOwner = scriptInterface.executionOwner as PlayerPuppet;
    if IsDefined(playerOwner) {
      playerOwner.InitClaimVehicleSystem();
      
      if (playerOwner.m_claimedVehicleTracking.modON) {

        vehicle = scriptInterface.owner as VehicleObject;

        // Added here to display vehicle Model strings in logs even when mod doesn't trigger - Remove once testing is done
        let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehicle.GetRecordID());
        let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());

        playerOwner.m_claimedVehicleTracking.getVehicleStringFromModel(vehicle.GetRecordID(), claimedVehicleModel);

        // if (playerOwner.m_claimedVehicleTracking.debugON) {  playerOwner.SetWarningMessage("Vehicle state - abandonned: " + ToString(vehicle.m_abandoned) ); }
 
        // // LogChannel(n"DEBUG", ":: OnExit - q001_victor_char_entry: " + GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"q001_victor_char_entry"));
        // // LogChannel(n"DEBUG", ":: OnExit - tutorial_ripperdoc_slots: " + GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"tutorial_ripperdoc_slots"));
        // // LogChannel(n"DEBUG", ":: OnExit - tutorial_ripperdoc_buy: " + GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"tutorial_ripperdoc_buy"));

        let isVictorHUDInstalled: Bool = GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"q001_ripperdoc_done") >= 1;
        let isPhantomLiberyStandalone: Bool = GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"ep1_standalone") >= 1;

        if (playerOwner.m_claimedVehicleTracking.debugON) {
          // LogChannel(n"DEBUG", ":: tryClaimVehicle - isVictorHUDInstalled: " + isVictorHUDInstalled);
          // LogChannel(n"DEBUG", ":: tryClaimVehicle - isPhantomLiberyStandalone: " + isPhantomLiberyStandalone);
        }

        let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(playerOwner.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;

        // New perk system
        // PlayerDevelopmentSystem.GetData(player).IsNewPerkBought(gamedataNewPerkType.Intelligence_Central_Milestone_3)

        // 
        // Technical - Gearhead - Tech_Right_Milestone_1 - 4 -  +33% vehicle health.
        // Intelligence - Carhacker - Intelligence_Right_Milestone_1 - 4 - Unlocks Vehicle quickhacks, allowing you to take control, set off alarms or even blow them up.
        // Cool - Road Warrior - Cool_Left_Milestone_1 - 4 - Allows you to use Sandevistan to slow time while driving.
        // 20% chance of registering vehicle on exit
        let playerGearheadLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Tech_Right_Milestone_1);
        let playerCarhackerLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Intelligence_Right_Milestone_1);
        let playerRoadWarriorLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Cool_Left_Milestone_1);

        // Technical - Driver Update - Tech_Central_Perk_2_1 - 9 - All cyberware gain an additional stat modifier.  
        // Intelligence - System Overwhelm - Intelligence_Central_Perk_2_3 - 9 - +7% quickhack damage for each unique quickhack and DOT effect affecting the target.
        // Cool - Sleight of Hand - Cool_Right_Perk_3_4 - 15 - +20% Crit damage for 8 sec. whenever Juggler is activated.
        // 50% chance of registering vehicle on exit
        let playerDriverUpdateLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Tech_Central_Perk_2_1);
        let playerSystemOverwhelmLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Intelligence_Central_Perk_2_3);
        let playerSleightofHandLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Cool_Right_Perk_3_4);

        // Technical - Edgerunner - Tech_Master_Perk_3 - 20 - Allows you to exceed your Cyberware Capacity by up to 50 points, but at the cost of -0.5% Max Health per point.
        // Intelligence - Smart Synergy - Intelligence_Master_Perk_4 - 20 - When Overclock is active, smart weapons gain instant target lock, and +25% damage if the enemy is affected by a quickhack.
        // Cool - Style Over Substance - Cool_Master_Perk_4 - 20 - Guaranteed Crit Hits with throwable weapons when crouch-sprinting, sliding, dodging or Dashing.
        // 100% chance of registering vehicle on exit
        let playerEdgerunnerLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Tech_Master_Perk_3);
        let playerSmartSynergyLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Intelligence_Master_Perk_4);
        let playerStyleOverSubstanceLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Cool_Master_Perk_4);

        if (playerOwner.m_claimedVehicleTracking.debugON) {
          // LogChannel(n"DEBUG", "::: addClaimedVehicle - Gearhead perk level: '"+playerGearheadLevel+"'"  );
          // LogChannel(n"DEBUG", "::: addClaimedVehicle - Car Hacker perk level: '"+playerCarhackerLevel+"'"  );
          // LogChannel(n"DEBUG", "::: addClaimedVehicle - Road Warrior level: '"+playerRoadWarriorLevel+"'"  );
        }

        // Ignore automatic hacking of car if:
        // - car already belongs to player
        // - player doesn't have the Field Technician perk
        // - eventually, player has received HUD enhancements from Victor (TO DO)

        if (isVictorHUDInstalled) || (isPhantomLiberyStandalone) {
            let isVehicleHackable: Bool = false;
            let chanceHack: Int32 = RandRange(0,99);
            let playerOnStealTrigger: Int32 = Cast<Int32>(100.0 - playerOwner.m_claimedVehicleTracking.chanceOnSteal);
            let chanceLowPerkHack: Int32 = Cast<Int32>(100.0 - playerOwner.m_claimedVehicleTracking.chanceLowPerkHack);
            let chanceMidPerkHack: Int32 = Cast<Int32>(100.0 - playerOwner.m_claimedVehicleTracking.chanceMidPerkHack);
            let chanceHighPerkHack: Int32 = Cast<Int32>(100.0 - playerOwner.m_claimedVehicleTracking.chanceHighPerkHack);

            // Low level
            if ((playerGearheadLevel > 0) && (Min(chanceHack * playerGearheadLevel, 99) > chanceLowPerkHack)) || ((playerCarhackerLevel > 0) && (Min(chanceHack * playerCarhackerLevel, 99) > chanceLowPerkHack)) || ((playerSleightofHandLevel > 0) && (Min(chanceHack * playerSleightofHandLevel, 99) > chanceLowPerkHack)) {
              isVehicleHackable = true;
            }  
 
            // Mid level
            if ((playerDriverUpdateLevel > 0) && (Min(chanceHack * playerDriverUpdateLevel, 99) > chanceMidPerkHack)) || ((playerSystemOverwhelmLevel > 0) && (Min(chanceHack * playerSystemOverwhelmLevel, 99) > chanceMidPerkHack)) || ((playerEdgerunnerLevel > 0) && (Min(chanceHack * playerEdgerunnerLevel, 99) > chanceMidPerkHack)) {
              isVehicleHackable = true;
            }  
 
            // High level
            if ((playerEdgerunnerLevel > 0) && (Min(chanceHack * playerEdgerunnerLevel, 99) > chanceHighPerkHack)) || ((playerSmartSynergyLevel > 0) && (Min(chanceHack * playerSmartSynergyLevel, 99) > chanceHighPerkHack)) || ((playerStyleOverSubstanceLevel > 0) && (Min(chanceHack * playerStyleOverSubstanceLevel, 99) > chanceHighPerkHack)) {
              isVehicleHackable = true;
            }  
 

            // Hack until Perks are restored
            // if (chanceHack  > (playerOnStealTrigger / 4)) {
            //   isVehicleHackable = true;
            // } 

            if (playerOwner.m_claimedVehicleTracking.debugON) {
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - chanceHack: '"+ToString(chanceHack)+"'"  );
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - chanceLowPerkHack: '"+ToString(chanceLowPerkHack)+"'"  );
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - chanceMidPerkHack: '"+ToString(chanceMidPerkHack)+"'"  );
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - chanceHighPerkHack: '"+ToString(chanceHighPerkHack)+"'"  );
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - isVehicleHackable: "+ToString(isVehicleHackable)  );
            }
     
            if (isVehicleHackable){ 
               playerOwner.m_claimedVehicleTracking.tryClaimVehicle(vehicle);   

            }  

            playerOwner.m_claimedVehicleTracking.tryPersistVehicle(vehicle);
          }
        }


    };

   this.SetIsVehicleDriver(stateContext, false);
   this.SendAnimFeature(stateContext, scriptInterface);
   this.ResetVehFppCameraParams(stateContext, scriptInterface);
   this.isCameraTogglePressed = false;
   stateContext.SetPermanentBoolParameter(n"ForceEmptyHands", false, true);
   this.ResumeStateMachines(scriptInterface.executionOwner);
}


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
      playerPuppet.m_claimedVehicleTracking.reset();
    };

    let isVehicleHackable: Bool = false;
    let chanceHack: Int32 = RandRange(0,99);
    let playerOnStealTrigger: Int32 = Cast<Int32>(100.0 - playerPuppet.m_claimedVehicleTracking.chanceOnSteal);

    if (chanceHack  > playerOnStealTrigger) {
      isVehicleHackable = true;
    }  

    if (isVehicleHackable) && (playerPuppet.m_claimedVehicleTracking.modON) { 
      playerPuppet.m_claimedVehicleTracking.tryClaimVehicle(vehicle);
    }
  }

@addMethod(QuickSlotsManager) 

  public final func NCLAIMRemoveVehicle(vehicleData: PlayerVehicle, vehicleModel: String ) -> Void {
    let playerOwner: ref<PlayerPuppet>; 

    // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Removing model '" +StrLower(vehicleModel) + "'"); 
    let vehiclesList: array<PlayerVehicle>;

    let matchFound = 0;
    let i = 0;

    // First look for a match in unlocked vehicles
    playerOwner = this.m_Player;

    // set up tracker if it doesn't exist
    if !IsDefined(playerOwner.m_claimedVehicleTracking) {
      playerOwner.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      playerOwner.m_claimedVehicleTracking.init(playerOwner);
    } else {
      // Reset if already exists (in case of changed default values)
      playerOwner.m_claimedVehicleTracking.reset();
    };

    if (playerOwner.m_claimedVehicleTracking.modON) {
      GameInstance.GetVehicleSystem(this.m_Player.GetGame()).GetPlayerUnlockedVehicles(vehiclesList);

      if (playerOwner.m_claimedVehicleTracking.warningsON) {
        // LogChannel(n"DEBUG", " ");
        // LogChannel(n"DEBUG", "----- ");
        // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Removing model '" +StrLower(vehicleModel) + "'");
        playerOwner.SetWarningMessage(ClaimVehiclesText.REMOVING() + "'"+vehicleModel+"'"); 
      }

      // Retrieve RecordID and vehicle type for the matched vehicle model
      while i < ArraySize(vehiclesList) { 
        let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
        let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());

        if (playerOwner.m_claimedVehicleTracking.warningsON) {
          // LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking database for '"+StrLower(_this_vehicleModel)+"' - isUnlocked: " + vehiclesList[i].isUnlocked);
        }

        if ( StrCmp(StrLower(_this_vehicleModel), StrLower(vehicleModel)) == 0 ) {
          if (playerOwner.m_claimedVehicleTracking.warningsON) { 
            // LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
          }
          matchFound = 1;
   
          // GameInstance.GetVehicleSystem(this.m_Player.GetGame()).TogglePlayerActiveVehicle(Cast<GarageVehicleID>(vehicleData.recordID), vehicleData.vehicleType, true); 
          playerOwner.m_claimedVehicleTracking.getVehicleStringFromModel(vehiclesList[i].recordID, _this_vehicleModel);

          if (StrCmp(playerOwner.m_claimedVehicleTracking.matchVehicleString, "")!=0) {

            GameInstance.GetVehicleSystem(playerOwner.GetGame()).EnablePlayerVehicle( playerOwner.m_claimedVehicleTracking.matchVehicleString, false, false);
          }
        }

        i += 1;
      };  

    };

  }

// @wrapMethod(VehiclesManagerPopupGameController)

  // protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool
  // {
  //     wrappedMethod(action,consumer);

  //     let actionType: gameinputActionType = ListenerAction.GetType(action);
  //     let actionName: CName = ListenerAction.GetName(action); 

  //     if Equals(actionType, gameinputActionType.BUTTON_PRESSED)
  //     {
  //         switch actionName
  //         {
  //         case n"popup_moveLeft": 
  //             let selectedItem: wref<VehiclesManagerListItemController> = this.m_listController.GetSelectedItem() as VehiclesManagerListItemController;
  //             let selectedVehicleData: ref<VehicleListItemData> = selectedItem.GetVehicleData();

  //             this.m_quickSlotsManager.NCLAIMRemoveVehicle(selectedVehicleData.m_data, GetLocalizedItemNameByCName(selectedVehicleData.m_displayName));
  //             this.Close();
  //             break;
  //         }
  //     }
  // }

@addMethod(VehiclesManagerPopupGameController)

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    let actionType: gameinputActionType = ListenerAction.GetType(action);
    let actionName: CName = ListenerAction.GetName(action);
    if Equals(actionType, gameinputActionType.REPEAT) {
      switch actionName {
        case n"popup_moveUp":
          super.ScrollPrior();
          break;
        case n"popup_moveDown":
          super.ScrollNext();
      };
    } else {
      if Equals(actionType, gameinputActionType.BUTTON_PRESSED) {
        switch actionName {
          case n"proceed":
            this.Activate();
            break;
          case n"popup_moveUp":
            super.ScrollPrior();
            break;
          case n"popup_moveDown":
            super.ScrollNext();
            break;
          case n"popup_moveLeft":
            // // LogChannel(n"DEBUG","N.C.L.A.I.M: ALERT: Vehicle marked for removal");
            let selectedItem: wref<VehiclesManagerListItemController> = super.m_listController.GetSelectedItem() as VehiclesManagerListItemController;
            let selectedVehicleData: ref<VehicleListItemData> = selectedItem.GetVehicleData();

            this.m_quickSlotsManager.NCLAIMRemoveVehicle(selectedVehicleData.m_data, GetLocalizedItemNameByCName(selectedVehicleData.m_displayName));
            super.Close();
            break;
          case n"OpenPauseMenu":
            ListenerActionConsumer.DontSendReleaseEvent(consumer);
            super.Close();
            break;
          case n"cancel":
            super.Close();
        };
      } else {
        if Equals(actionType, gameinputActionType.BUTTON_HOLD_COMPLETE) {
          if Equals(actionName, n"left_stick_y_scroll_up") {
            super.ScrollPrior();
          } else {
            if Equals(actionName, n"left_stick_y_scroll_down") {
              super.ScrollNext();
            };
          };
        };
      };
    };
  }

@wrapMethod(VehiclesManagerPopupGameController)

  protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool
  {
      wrappedMethod(playerPuppet);

      let playerControlledObject = this.GetPlayerControlledObject();
      playerControlledObject.RegisterInputListener(this, n"popup_moveLeft");
  }
 




// Reference code
 
// :: From vehicleSystem
// public final native func EnablePlayerVehicle(vehicle: String, enable: Bool, opt despawnIfDisabling: Bool) -> Bool;
// public final native func EnableAllPlayerVehicles() -> Void;
// public final native func GetPlayerVehicles(out vehicles: array<PlayerVehicle>) -> Void;
// public final native func GetPlayerUnlockedVehicles(out unlockedVehicles: array<PlayerVehicle>) -> Void;


// let thisPlayerVehicle: PlayerVehicle;
// thisPlayerVehicle.recordID = recordID; 
// thisPlayerVehicle.vehicleType = vehType;
// thisPlayerVehicle.isUnlocked = true;

// currentData = new VehicleListItemData();
// currentData.m_displayName = vehicleRecord.DisplayName();
// currentData.m_icon = vehicleRecord.Icon();
// currentData.m_data = thisPlayerVehicle;

// ArrayPush(vehiclesList, thisPlayerVehicle);   



/*
public class VehicleSummonWidgetGameController extends inkHUDGameController {

  protected cb func OnVehiclePurchased(value: Variant) -> Bool {
    let vehicleRecordID: TweakDBID;
    this.m_rootWidget.SetVisible(true);
    inkWidgetRef.SetVisible(this.m_subText, true);
    this.PlayAnim(n"OnVehiclePurchase", n"OnTimeOut");
    vehicleRecordID = FromVariant<TweakDBID>(value);
    this.m_vehicleRecord = TweakDBInterface.GetVehicleRecord(vehicleRecordID);
    inkTextRef.SetLocalizedTextScript(this.m_vehicleNameLabel, this.m_vehicleRecord.DisplayName());
    inkTextRef.SetText(this.m_subText, "LocKey#43690");
    this.SetVehicleIcon(this.m_vehicleRecord.Type().Type());
    this.SetVehicleIconManufactorIcon(this.m_vehicleRecord.Manufacturer().EnumName());
  }

  */
  /*
  public importonly struct PlayerVehicle {

    public native let name: CName;

    public native let recordID: TweakDBID;

    public native let vehicleType: gamedataVehicleType;

    public native let isUnlocked: Bool;
  }
  */