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

  public let modON: Bool;
  public let debugON: Bool;
  public let warningsON: Bool;  

  public let chanceOnSteal: Float;
  public let chanceWorkshopHack: Float;
  public let chanceFieldTechnicianHack: Float;
  public let chanceHackerOverlordHack: Float;

  public let claimedVehiclesList: array<PlayerVehicle>;

  public let matchVehicle: PlayerVehicle; 
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
    // this.chanceWorkshopHack = 20;
    // this.chanceFieldTechnicianHack = 50;
    // this.chanceHackerOverlordHack = 100;

    // Toggle warning messages 
    // this.warningsON = true;

    // ------------------ End of Mod Options

    // For developers only 
    // this.debugON = true; 

  }

  public func refreshConfig() -> Void {
    this.config = new ClaimVehiclesConfig();
    this.invalidateCurrentState();
  }

  public func invalidateCurrentState() -> Void { 
    this.chanceOnSteal = Cast<Float>(this.config.chanceOnSteal); 
    this.chanceWorkshopHack = Cast<Float>(this.config.chanceWorkshopHack); 
    this.chanceFieldTechnicianHack = Cast<Float>(this.config.chanceFieldTechnicianHack); 
    this.chanceHackerOverlordHack = Cast<Float>(this.config.chanceHackerOverlordHack);   
    this.warningsON = this.config.warningsON;
    this.debugON = this.config.debugON;
    this.modON = this.config.modON;  
  }  

  // Mapping Vehicle plain text model string -> internal vehicle string ID
  //    Also converts variant vehicle model name to model name found in list of potential player vehicles
  //    Ex: Hella EC-D 1360 ->  Vehicle.v_standard2_archer_hella_player
  public func getVehicleStringFromModel(claimedVehicleModel: String) -> Void {

    this.matchVehicleModel = "";
    this.matchVehicleString = "";
    this.matchVehicleUnlocked = false;

    // LogChannel(n"DEBUG", "N.C.L.A.I.M: Test: claimedVehicleModel: '"+claimedVehicleModel+"' - Target: 'Type-66 640 TX'  - StrCmp: '"+StrCmp(claimedVehicleModel, "Type-66 640 TX")+"'"  );

    if (this.warningsON) {
      LogChannel(n"DEBUG", "N.C.L.A.I.M: Reading Vehicle ID from Model: '"+claimedVehicleModel+"'"  );
      LogChannel(n"DEBUG", ">>> Looking for: '"+StrLower(claimedVehicleModel)+"'"  );
    }
  /*
    TO DO 
    - map all variants - https://cyberpunk.fandom.com/wiki/Cyberpunk_2077_Vehicles
    - Test all cars

    - Unsupported
    - Zeya U420  (Short dump truck)
    - Behemoth  (literally just called that, its from militech and used primarily by arasaka)
 
  */ 

    switch StrLower(claimedVehicleModel) {

  // Cars - Economy
      /*
        [reserved]  Hella EC-D 1360 -  Vehicle.v_standard2_archer_hella_player - Default Car
      */
      // Makigai - Maimai
      case "maimai p126":
        this.matchVehicleModel = "Maimai P126";
        this.matchVehicleString = "Vehicle.v_standard2_makigai_maimai_player";
        break;

      // Mahir - Supron
      case "supron fs3":
        this.matchVehicleModel = "Supron FS3";
        this.matchVehicleString = "Vehicle.v_standard25_mahir_supron_player";
        break;

      // Thornton - Colby
      case "colby c210 camper":
        this.matchVehicleModel = "Colby C210 Camper";
        this.matchVehicleString = "Vehicle.v_standard2_thorton_colby";
        break;

      case "colby cst40":
        this.matchVehicleModel = "Colby CST40";
        this.matchVehicleString = "Vehicle.v_standard2_thorton_colby_gt";
        break;

      case "colby c240t":
        this.matchVehicleModel = "Colby C240T";
        this.matchVehicleString = "Vehicle.v_standard2_thorton_colby_family";
        break;

      case "colby \"vaquero\"": // Valentino variant
        this.matchVehicleModel = "Colby  \"Vaquero\"";
        this.matchVehicleString = "Vehicle.v_standard2_thorton_colby_valentinos";
        break;

      case "colby c125":
        this.matchVehicleModel = "Colby C125";
        this.matchVehicleString = "Vehicle.v_standard2_thorton_colby_player";
        break;

      case "colby cx410 butte": // Untested - could be mapped to colby_pickup_02_player
        // v_standard25_thorton_colby_pickup_player is the green model
        // v_standard25_thorton_colby_pickup_02_player is the red model
        this.matchVehicleModel = "Colby CX410 Butte";
        this.matchVehicleString = "Vehicle.v_standard25_thorton_colby_pickup_02_player";
        break;

      case "colby \"little mule\"":  
        this.matchVehicleModel = "Colby \"Little Mule\"";
        this.matchVehicleString = "Vehicle.v_standard25_thorton_colby_nomad_player";
        break;

      // Thornton - Galena
      case "galena g240":
        this.matchVehicleModel = "Galena G240";
        this.matchVehicleString = "Vehicle.v_standard2_thorton_galena_player";
        break;

      case "galena \"gecko\"": // No reference to Bobas model in websites... assuming this one maps to Gecko model
        this.matchVehicleModel = "Galena \"Gecko\"";
        this.matchVehicleString = "Vehicle.v_standard2_thorton_galena_nomad_player";
        break;

      case "galena ga32t": // Sports model
        this.matchVehicleModel = "Galena GA32t";
        this.matchVehicleString = "Vehicle.v_standard2_thorton_galena_gt";
        break;

      case "galena \"rattler\"": // Default Nomad Life Path Vehicle  
        this.matchVehicleModel = "Galena \"Rattler\"";
        this.matchVehicleString = "Vehicle.v_standard2_thorton_galena_bobas_player";
        break;

      // Thornton - Mackinaw MTL1
      case "mackinaw mtl1":
        this.matchVehicleModel = "Mackinaw MTL1";
        this.matchVehicleString = "Vehicle.v_standard3_thorton_mackinaw_player";
        break;

      case "mackinaw larimore":
        this.matchVehicleModel = "Mackinaw Larimore";
        this.matchVehicleString = "Vehicle.v_standard3_thorton_mackinaw_country";
        break;

      case "mackinaw \"saguaro\"":
        this.matchVehicleModel = "Mackinaw \"Saguaro\""; // Nomad version
        this.matchVehicleString = "Vehicle.v_standard3_thorton_mackinaw_nomad";
        break;

  // Cars - Executive
      // Archer - Hella - Cab
      case "hella ec-v i660 voyage":
        this.matchVehicleModel = "Hella EC-V i660 Voyage";
        this.matchVehicleString = "Vehicle.v_standard2_archer_hella_combat_cab";
        break;

      // Archer - Enforcer - Police
      case "hella ec-h i860 enforcer":
        this.matchVehicleModel = "Hella EC-H i860 Enforcer";
        this.matchVehicleString = "Vehicle.v_standard2_archer_hella_police";
        break;

      // Emperor - Police
      case "emperor 720 ncpd ironclad":
        this.matchVehicleModel = "Emperor 720 NCPD Ironclad";
        this.matchVehicleString = "Vehicle.v_standard3_chevalier_emperor_police";
        break;

      // Villefort - Cortes - Police
      case "cortes v6000 ncpd overlord":
        this.matchVehicleModel = "Cortes V6000 NCPD Overlord";
        this.matchVehicleString = "Vehicle.v_standard2_villefort_cortes_police";
        break;

      // Chevalier - Emperor
      case "emperor 620 ragnar":
        this.matchVehicleModel = "Emperor 620 Ragnar";
        this.matchVehicleString = "Vehicle.v_standard3_chevalier_emperor_player";
        break;

       // Chevalier - Thrax
      case "thrax 378 decurion":
        this.matchVehicleModel = "Thrax 378 Decurion";
        this.matchVehicleString = "Vehicle.v_standard2_chevalier_thrax_sixth_street";
        break;

      case "thrax 388 jefferson":
        this.matchVehicleModel = "Thrax 388 Jefferson";
        this.matchVehicleString = "Vehicle.v_standard2_chevalier_thrax_player";
        break;

      // Villefort - Alvarado
      case "alvarado v4f 570 delegate":
        this.matchVehicleModel = "Alvarado V4F 570 Delegate";
        this.matchVehicleString = "Vehicle.v_sport2_villefort_alvarado_player";
        break;

      case "alvarado v4fc 580 \"vato\"": // Beat on the Brat: The Glen Side Job   
        this.matchVehicleModel = "Alvarado V4FC 580 \"Vato\"";
        this.matchVehicleString = "Vehicle.v_sport2_villefort_alvarado_valentinos_player";
        break;

      // Villefort - Columbus
      case "columbus v340-f freight":
        this.matchVehicleModel = "Columbus V340-F Freight";
        this.matchVehicleString = "Vehicle.v_standard25_villefort_columbus_player";
        break;

      // Villefort - Cortes
      case "cortes v5000 valor":
        this.matchVehicleModel = "Cortes V5000 Valor";
        this.matchVehicleString = "Vehicle.v_standard2_villefort_cortes_player";
        break;

  // Cars - Heavy Duty
      /*
        * [reserved] Mackinaw Beast - Vehicle.v_standard3_thorton_mackinaw_ncu_player - ncu = unique? - The Beast in Me Side Job 
      */
      case "zeya u420": 
        this.matchVehicleModel = "Zeya U420";
        this.matchVehicleString = "Vehicle.v_utility4_kaukaz_zeya";
        break;

      case "bratsk u4020": 
        this.matchVehicleModel = "Bratsk U4020";
        this.matchVehicleString = "Vehicle.v_utility4_kaukaz_bratsk";
        break;

      case "behemoth": 
        this.matchVehicleModel = "Behemoth";
        this.matchVehicleString = "Vehicle.v_utility4_militech_behemoth";
        break;

  // Cars - Sport   
      /*
        [reserved] Porsche 911 II (930) Turbo - Vehicle.v_sport2_porsche_911turbo_player - Chippin’ In Side Job    
      */  
      // Archer - Quartz
      case "quartz ec-l r275":  
        this.matchVehicleModel = "Quartz EC-L R275";
        this.matchVehicleString = "Vehicle.v_standard2_archer_quartz";
        break;

      case "quartz ec-t2 r660": 
        this.matchVehicleModel = "Quartz EC-T2 R660";
        this.matchVehicleString = "Vehicle.v_standard2_archer_quartz_player";
        break;

      case "quartz \"barghest\"":  
        this.matchVehicleModel = "Quartz \"Barghest\"";
        this.matchVehicleString = "Vehicle.v_standard2_archer_quartz_nomad_wraith";
        break;

      case "quartz \"sidewinder\"":  
        this.matchVehicleModel = "Quartz \"Sidewinder\"";
        this.matchVehicleString = "Vehicle.v_standard2_archer_quartz_nomad";
        break;

      case "quartz \"bandit\"": // Mission Reward (spared Nash)
        this.matchVehicleModel = "Quartz \"Bandit\"";
        this.matchVehicleString = "Vehicle.v_standard2_archer_quartz_player";
        break;

      // Quadra - Turbo-R
      case "turbo-r 740":
        this.matchVehicleModel = "Turbo-R 740";
        this.matchVehicleString = "Vehicle.v_sport1_quadra_turbo_player";
        break;

      case "turbo-r \"raijin\"": // Assuming this is the Tyger customized version of the 'Turbo-R 740'
        this.matchVehicleModel = "Turbo-R \"Raijin\"";
        this.matchVehicleString = "Vehicle.v_sport1_quadra_turbo_tyger_claw";
        break;

      case "turbo-r v-tech": //   Reward from Sex on Wheels
        this.matchVehicleModel = "Turbo-R V-Tech";
        this.matchVehicleString = "Vehicle.v_sport1_quadra_turbo_r_player";
        break;

      // Quadra - Type-66 
      case "type-66 \"jen rowley\"":
        this.matchVehicleModel = "Type-66 \"Jen Rowley\"";
        this.matchVehicleString = "Vehicle.v_sport2_quadra_type66_player";
        break;

      case "type-66 640 ts":
        this.matchVehicleModel = "Type-66 640 TS";
        this.matchVehicleString = "Vehicle.v_sport2_quadra_type66_02_player";
        break;

      case "type-66 avenger":
        this.matchVehicleModel = "Type-66 Avenger";
        this.matchVehicleString = "Vehicle.v_sport2_quadra_type66_avenger_player";
        break;

      case "type-66 \"cthulhu\"": // possible reward in The Beast in Me - mapped to avenger model
        this.matchVehicleModel = "Type-66 \"Cthulhu\"";
        this.matchVehicleString = "Vehicle.v_sport2_quadra_type66_nomad_ncu_player";
        break;

      case "type-66 \"javelina\"":
        this.matchVehicleModel = "Type-66 \"Javelina\"";
        this.matchVehicleString = "Vehicle.v_sport2_quadra_type66_nomad_player";
        break;

      case "type-66 \"reaver\"": // Cannot be acquired - mapped to Cthlhu model instead
        this.matchVehicleModel = "Type-66 \"Cthulhu\"";
        this.matchVehicleString = "Vehicle.v_sport2_quadra_type66_nomad_ncu_player";
        break;

      // Mizutani - Shion
      case "shion mz1":
        this.matchVehicleModel = "Shion MZ1";
        this.matchVehicleString = "Vehicle.v_sport2_mizutani_shion";
        break;

      case "shion mz2":
        this.matchVehicleModel = "Shion MZ2";
        this.matchVehicleString = "Vehicle.v_sport2_mizutani_shion_player";
        break;

      case "shion \"kyokotsu\"":
        this.matchVehicleModel = "Shion \"Kyokotsu\"";
        this.matchVehicleString = "Vehicle.v_sport2_mizutani_shion_tyger";
        break;

      case "shion \"coyote\"": // Queen of the Highway Side Job 
        // v_sport2_mizutani_shion_nomad_player is the default model
        // v_sport2_mizutani_shion_nomad_02_player is the red model
        this.matchVehicleModel = "Shion \"Coyote\"";
        this.matchVehicleString = "Vehicle.v_sport2_mizutani_shion_nomad_player";
        break;

  // Motorcycles
      /* 
        [reserved] Apollo Nomad - Vehicle.v_sportbike3_brennan_apollo_nomad_player - Life During Wartime reward 
        [reserved] Apollo Scorpion - Life During Wartime reward   
        [reserved] Nazaré Jackie - Vehicle.v_sportbike2_arch_jackie_player  - Heroes reward 
        [reserved] Nazaré Jackie - Vehicle.v_sportbike2_arch_jackie_tuned_player  
      */
      // [DEBUG] N.C.L.A.I.M: Reading Vehicle ID from Model: 'ARCH NAZARÉ'
      // Arch - Nazare
      case "nazaré racer":  
        this.matchVehicleModel = "Nazaré Racer";
        this.matchVehicleString = "Vehicle.v_sportbike2_arch_sport";
        break;

      case "arch nazaré":  
        this.matchVehicleModel = "ARCH NAZARÉ";
        this.matchVehicleString = "Vehicle.v_sportbike2_arch_player";
        break;

      // Arch - Nazare - Nazaré "Itsumade"
      case "nazaré \"itsumade\"": // The Highwayman reward 
        this.matchVehicleModel = "Nazaré \"Itsumade\"";
        this.matchVehicleString = "Vehicle.v_sportbike2_arch_tyger_player";
        break;

      // Brennan - Apollo
      case "apollo":
        this.matchVehicleModel = "Apollo";
        this.matchVehicleString = "Vehicle.v_sportbike3_brennan_apollo_player";
        break;

      case "apollo \"cicada\"":
        this.matchVehicleModel = "Apollo \"Cicada\"";
        this.matchVehicleString = "Vehicle.v_sportbike3_brennan_apollo";
        break;

      // Brennan - Apollo
      case "apollo \"scorpion\"":
        this.matchVehicleModel = "Apollo \"Scorpion\"";
        this.matchVehicleString = "Vehicle.v_sportbike3_brennan_apollo_nomad_player";
        break;

      // Yaiba - Kusanagi
      case "kusanagi ct-3x":
        this.matchVehicleModel = "Kusanagi CT-3X";
        this.matchVehicleString = "Vehicle.v_sportbike1_yaiba_kusanagi_player";
        break;

      case "kusanagi \"misfit\"":
        this.matchVehicleModel = "Kusanagi \"Mifit\"";
        this.matchVehicleString = "Vehicle.v_sportbike1_yaiba_kusanagi_tyger_player";
        break;

      case "kusanagi \"mizuchi\"":
        // Looks like some Tyger customized bikes in game still have the "Kusanagi CT-3X" model name instead of "Kusanagi "Misuchi", which means they will trigger the default model instead of the Tyger customized one
        this.matchVehicleModel = "Kusanagi \"Mizuchi\"";
        this.matchVehicleString = "Vehicle.v_sportbike1_yaiba_kusanagi_tyger";
        break;

  // Cars - Hypercars    
      // Herrera - Outlaw GTS
      case "outlaw gts":
        this.matchVehicleModel = "Outlaw GTS";
        this.matchVehicleString = "Vehicle.v_sport1_herrera_outlaw_player";
        break;

      // Rayfield - Aerondight
      case "aerondight \"guinevere\"":
        this.matchVehicleModel = "Aerondight \"Guinevere\"";
        this.matchVehicleString = "Vehicle.v_sport1_rayfield_aerondight_player";
        break;

      // Rayfield - Caliburn
      // v_sport1_rayfield_caliburn_player is the default model
      // v_sport1_rayfield_caliburn_02_player is the Black model (free in a tunnel in the badlands)
      case "caliburn":
        this.matchVehicleModel = "Caliburn";
        this.matchVehicleString = "Vehicle.v_sport1_rayfield_caliburn_player";
        break;

  // Other      
      /*
        [reserved] Cortes Delamain No. 21 - Vehicle.v_standard2_villefort_cortes_delamain_player - Don’t Lose Your Mind taxi reward 
      */
      // Judy's van cannot be interacted with - cannot be stolen or entered as a driver
      // case "columbus \"sea dragon\"":
      //  this.matchVehicleModel = "Columbus \"Sea Dragon\"";
      //  this.matchVehicleString = "Vehicle.v_standard25_villefort_columbus_judy_van";
      //  break;

    };

    if (this.warningsON) {
      LogChannel(n"DEBUG", "N.C.L.A.I.M: Vehicle Model found: '"+this.matchVehicleModel+"'"  );
      LogChannel(n"DEBUG", "N.C.L.A.I.M: Vehicle ID found: '"+this.matchVehicleString+"'"  );
    }
  }

  // Mapping Vehicle plain text model string -> vehicle record in list of potential player owned vehicles
  //    Assumes getVehicleStringFromModel() was already ran to convert variant vehicle model to model from player vehicles
  public func isVehicleOwned() -> Int32 {
    let vehiclesList: array<PlayerVehicle>;

    let matchFound = 0;
    let i = 0;

    // First look for a match in unlocked vehicles
    GameInstance.GetVehicleSystem(this.player.GetGame()).GetPlayerUnlockedVehicles(vehiclesList);

    if (this.warningsON) {
      LogChannel(n"DEBUG", " ");
      LogChannel(n"DEBUG", "----- ");
      LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Scanning known vehicles for '" +StrLower(this.matchVehicleModel) + "'");
    }

    // Retrieve RecordID and vehicle type for the matched vehicle model
    while i < ArraySize(vehiclesList) { 
      let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
      let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());

      if (this.warningsON) {
        LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking database for '"+StrLower(_this_vehicleModel)+"' - isUnlocked: " + vehiclesList[i].isUnlocked);
      }

      if ( StrCmp(StrLower(_this_vehicleModel), StrLower(this.matchVehicleModel)) == 0 ) {
        if (this.warningsON) { 
          LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
        }
        matchFound = 1;
 
        this.matchVehicle.recordID = vehiclesList[i].recordID;
        this.matchVehicle.vehicleType = vehiclesList[i].vehicleType;
        this.matchVehicleUnlocked = true;
      }

      i += 1;
    };  

    // If not nfound, scan whole list of known vehicles
    if (matchFound==0) {
      i = 0;

      GameInstance.GetVehicleSystem(this.player.GetGame()).GetPlayerVehicles(vehiclesList);

      if (this.warningsON) {
        LogChannel(n"DEBUG", " ");
        LogChannel(n"DEBUG", "----- ");
        LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Scanning Criminal Asset Forfeiture database for '" +StrLower(this.matchVehicleModel) + "'");
      }

      // Retrieve RecordID and vehicle type for the matched vehicle model
      while i < ArraySize(vehiclesList) { 
        let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
        let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());

        if (this.warningsON) {
          LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking database for '"+StrLower(_this_vehicleModel)+"' - isUnlocked: " + vehiclesList[i].isUnlocked);
        }

        if ( StrCmp(StrLower(_this_vehicleModel), StrLower(this.matchVehicleModel)) == 0 ) {
          if (this.warningsON) { 
            LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
          }
          matchFound = 1;
   
          this.matchVehicle.recordID = vehiclesList[i].recordID;
          this.matchVehicle.vehicleType = vehiclesList[i].vehicleType;
          this.matchVehicleUnlocked = vehiclesList[i].isUnlocked;
        }

        i += 1;
      };  
    }

    if (this.warningsON) && (matchFound == 0){ 
      LogChannel(n"DEBUG", ">>>  NO matching vehicle record ID.");
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

    // LogChannel(n"DEBUG", ":: Entering tryClaimVehicle");
    // LogChannel(n"DEBUG", ":: tryClaimVehicle - vehClassName: " + vehClassName);

    let isVictorHUDInstalled: Int32 = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"tutorial_ripperdoc_buy");
    if (this.debugON) {
      LogChannel(n"DEBUG", ":: tryClaimVehicle - isVictorHUDInstalled: " + isVictorHUDInstalled);
    }

    switch vehClassName {
      case "Car":
        claimVehicle = true;
        break;

      case "Bike":
        claimVehicle = true;
        break;
    };

    // LogChannel(n"DEBUG", ":: tryClaimVehicle - claimVehicle: " + ToString(claimVehicle));
    if (claimVehicle) && (isVictorHUDInstalled>0) {

      if (this.warningsON) {
        LogChannel(n"DEBUG", " ");
        LogChannel(n"DEBUG", "N.C.L.A.I.M:  Registering Forfeit Vehicle - " + vehClassName);
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
    let matchFound = 0;

    // Checking standard dealership database
    this.getVehicleStringFromModel(claimedVehicleModel);
    matchFound = this.isVehicleOwned();


    if (matchFound > 0) { 

      if (this.matchVehicleUnlocked) {
        if (this.debugON) { 
          LogChannel(n"DEBUG", ">>> Skipping registration - vehicle already unlocked");
        }  
             
      } else {

        if (this.debugON) {
          LogChannel(n"DEBUG", "N.C.L.A.I.M: Scanning Criminal Asset Forfeiture database for '"+claimedVehicleModel+"'. Match found ["+matchFound+"]");        
        }

        if (this.warningsON) {
          LogChannel(n"DEBUG", "N.C.L.A.I.M: Vehicle code extracted: '"+this.matchVehicleString+"'"  );   
        }

        if (StrCmp(this.matchVehicleString, "")!=0) {

          GameInstance.GetVehicleSystem(this.player.GetGame()).EnablePlayerVehicle( this.matchVehicleString, true, false);

          GameInstance.GetVehicleSystem(this.player.GetGame()).TogglePlayerActiveVehicle(Cast<GarageVehicleID>(this.matchVehicle.recordID), this.matchVehicle.vehicleType, true);  

          if (this.warningsON) {     
            this.player.SetWarningMessage("N.C.L.A.I.M: Match found in Criminal Asset Forfeiture database for '"+claimedVehicleModel+"'");   
          } 
        }

      }

    } 

    if (this.warningsON) && (matchFound == 0) {     
      //  this.player.SetWarningMessage("N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
      LogChannel(n"DEBUG", "N.C.L.A.I.M: ALERT: Field Asset Forfeiture database corrupted. No match found for '"+claimedVehicleModel+"'");   
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

        playerOwner.m_claimedVehicleTracking.getVehicleStringFromModel(claimedVehicleModel);

        // if (playerOwner.m_claimedVehicleTracking.debugON) {  playerOwner.SetWarningMessage("Vehicle state - abandonned: " + ToString(vehicle.m_abandoned) ); }
 
        // LogChannel(n"DEBUG", ":: OnExit - q001_victor_char_entry: " + GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"q001_victor_char_entry"));
        // LogChannel(n"DEBUG", ":: OnExit - tutorial_ripperdoc_slots: " + GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"tutorial_ripperdoc_slots"));
        // LogChannel(n"DEBUG", ":: OnExit - tutorial_ripperdoc_buy: " + GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"tutorial_ripperdoc_buy"));

        let isVictorHUDInstalled: Int32 = GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"tutorial_ripperdoc_buy");

        if (playerOwner.m_claimedVehicleTracking.debugON) {
          LogChannel(n"DEBUG", ":: tryClaimVehicle - isVictorHUDInstalled: " + isVictorHUDInstalled);
        }

        let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(playerOwner.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;

        // Crafting - Workshop perk - lvl 7 - Disassembling items grants a X% chance to gain a free component of higher quality than the disassembled item
        // 10% chance of registering vehicle on exit
        let playerWorkshopLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataPerkType.Crafting_Area_03_Perk_1);

        // Crafting - Field Technician perk - lvl 11 - Crafted weapons deal X% more damage.
        // 25% chance of registering vehicle on exit
        let playerFieldTechnicianLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataPerkType.Crafting_Area_05_Perk_1);

        // Quickhacking - Hacker Overlord perk - lvl 16 - Unlocks Crafting Specs for Epic quickhacks.
        // 100% chance of registering vehicle on exit
        let playerHackerOverlordLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataPerkType.CombatHacking_Area_08_Perk_2);

        if (playerOwner.m_claimedVehicleTracking.debugON) {
          LogChannel(n"DEBUG", "::: addClaimedVehicle - Workshop perk level: '"+playerWorkshopLevel+"'"  );
          LogChannel(n"DEBUG", "::: addClaimedVehicle - Field Technician perk level: '"+playerFieldTechnicianLevel+"'"  );
          LogChannel(n"DEBUG", "::: addClaimedVehicle - Hacker Overlord perk level: '"+playerHackerOverlordLevel+"'"  );
        }

        // Ignore automatic hacking of car if:
        // - car already belongs to player
        // - player doesn't have the Field Technician perk
        // - eventually, player has received HUD enhancements from Victor (TO DO)

        if (isVictorHUDInstalled>0) {
            let isVehicleHackable: Bool = false;
            let chanceHack: Int32 = RandRange(0,99);
            let playerWorkshopLevelTrigger: Int32 = Cast<Int32>(100.0 - playerOwner.m_claimedVehicleTracking.chanceWorkshopHack);
            let playerFieldTechnicianLevelTrigger: Int32 = Cast<Int32>(100.0 - playerOwner.m_claimedVehicleTracking.chanceFieldTechnicianHack);
            let playerHackerOverlordLevelTrigger: Int32 = Cast<Int32>(100.0 - playerOwner.m_claimedVehicleTracking.chanceHackerOverlordHack);

            if (playerWorkshopLevel > 0) && (Min(chanceHack * playerWorkshopLevel, 99) > playerWorkshopLevelTrigger) {
              isVehicleHackable = true;
            }  

            if (playerFieldTechnicianLevel > 0) && (Min(chanceHack * playerFieldTechnicianLevel, 99) > playerFieldTechnicianLevelTrigger) {
              isVehicleHackable = true;
            }  

            if (playerHackerOverlordLevel > 0) && (Min(chanceHack * playerHackerOverlordLevel, 99) > playerHackerOverlordLevelTrigger) {
              isVehicleHackable = true;
            }  

            if (playerOwner.m_claimedVehicleTracking.debugON) {
              LogChannel(n"DEBUG", "::: addClaimedVehicle - chanceHack: '"+ToString(chanceHack)+"'"  );
              LogChannel(n"DEBUG", "::: addClaimedVehicle - playerWorkshopLevelTrigger: '"+ToString(playerWorkshopLevelTrigger)+"'"  );
              LogChannel(n"DEBUG", "::: addClaimedVehicle - playerFieldTechnicianLevelTrigger: '"+ToString(playerFieldTechnicianLevelTrigger)+"'"  );
              LogChannel(n"DEBUG", "::: addClaimedVehicle - playerHackerOverlordLevelTrigger: '"+ToString(playerHackerOverlordLevelTrigger)+"'"  );
              LogChannel(n"DEBUG", "::: addClaimedVehicle - isVehicleHackable: "+ToString(isVehicleHackable)  );
            }
     
            if (isVehicleHackable){ 
               playerOwner.m_claimedVehicleTracking.tryClaimVehicle(vehicle);   

            } else {             
              // if (playerOwner.m_claimedVehicleTracking.debugON) {  playerOwner.SetWarningMessage("Warning: Leaving your vehicle."); }
              if (playerWorkshopLevel < 0) {
                if (playerOwner.m_claimedVehicleTracking.debugON) {
                  LogChannel(n"DEBUG", "::: addClaimedVehicle - Skipped - Workshop perk missing"  );
                }
              } else {
                if ((chanceHack * playerWorkshopLevel) < playerWorkshopLevelTrigger) {
                  if (playerOwner.m_claimedVehicleTracking.debugON) {
                    LogChannel(n"DEBUG", "::: addClaimedVehicle - Skipped - Workshop perk failed [" + ToString((chanceHack * playerWorkshopLevel)) + "<" + ToString(playerWorkshopLevelTrigger) + "]"  );
                  }
                }                
              }

              if (playerFieldTechnicianLevel < 0)  {
                if (playerOwner.m_claimedVehicleTracking.debugON) {
                  LogChannel(n"DEBUG", "::: addClaimedVehicle - Skipped - Field Technician perk missing"  );
                }
              } else {
                if ((chanceHack * playerFieldTechnicianLevel) < playerFieldTechnicianLevelTrigger) {
                  if (playerOwner.m_claimedVehicleTracking.debugON) {
                    LogChannel(n"DEBUG", "::: addClaimedVehicle - Skipped - Field Technician perk failed [" + ToString(chanceHack)  + "<" + ToString(playerFieldTechnicianLevelTrigger) + "]"  );
                  }
                }
              }

              if (playerHackerOverlordLevel < 0) {
                if (playerOwner.m_claimedVehicleTracking.debugON) {
                  LogChannel(n"DEBUG", "::: addClaimedVehicle - Skipped - Hacker Overlord perk missing ");
                }
              } else {
                if ((chanceHack * playerHackerOverlordLevel) < playerHackerOverlordLevelTrigger) {
                  if (playerOwner.m_claimedVehicleTracking.debugON) {
                    LogChannel(n"DEBUG", "::: addClaimedVehicle - Skipped - Hacker Overlord perk failed [" + ToString(chanceHack)  + "<" + ToString(playerHackerOverlordLevelTrigger) + "]"  );
                  }
                }                
              }



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

    // LogChannel(n"DEBUG", "Player is stealing a vehicle");
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

    LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Removing model '" +StrLower(vehicleModel) + "'"); 
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
        LogChannel(n"DEBUG", " ");
        LogChannel(n"DEBUG", "----- ");
        LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Removing model '" +StrLower(vehicleModel) + "'");
        playerOwner.SetWarningMessage("N.C.L.A.I.M: Removing model '"+vehicleModel+"'"); 
      }

      // Retrieve RecordID and vehicle type for the matched vehicle model
      while i < ArraySize(vehiclesList) { 
        let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
        let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());

        if (playerOwner.m_claimedVehicleTracking.warningsON) {
          LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking database for '"+StrLower(_this_vehicleModel)+"' - isUnlocked: " + vehiclesList[i].isUnlocked);
        }

        if ( StrCmp(StrLower(_this_vehicleModel), StrLower(vehicleModel)) == 0 ) {
          if (playerOwner.m_claimedVehicleTracking.warningsON) { 
            LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
          }
          matchFound = 1;
   
          // GameInstance.GetVehicleSystem(this.m_Player.GetGame()).TogglePlayerActiveVehicle(Cast<GarageVehicleID>(vehicleData.recordID), vehicleData.vehicleType, true); 
          playerOwner.m_claimedVehicleTracking.getVehicleStringFromModel(_this_vehicleModel);

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
            // LogChannel(n"DEBUG","N.C.L.A.I.M: ALERT: Vehicle marked for removal");
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