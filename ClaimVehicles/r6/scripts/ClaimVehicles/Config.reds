public class ClaimVehiclesConfig {

  public static func Get() -> ref<ClaimVehiclesConfig> {
    let self: ref<ClaimVehiclesConfig> = new ClaimVehiclesConfig();
    return self;
  } 

  @runtimeProperty("ModSettings.mod", "NCLAIMS")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.displayName", "Mod toggle")
  @runtimeProperty("ModSettings.description", "Enable or disable the mod if you need to revert back to the default system in certain situations.")
  let modON: Bool = true; 

  @runtimeProperty("ModSettings.mod", "NCLAIMS")
  @runtimeProperty("ModSettings.category", "Vehicle Claim System")
  @runtimeProperty("ModSettings.displayName", "Workshop Perk success chance")
  @runtimeProperty("ModSettings.description", "Percent chance the Workshop perk will work. Chance of is multiplied by level of this perk.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceWorkshopHack: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "NCLAIMS")
  @runtimeProperty("ModSettings.category", "Vehicle Claim System")
  @runtimeProperty("ModSettings.displayName", "Field Technician Perk success chance")
  @runtimeProperty("ModSettings.description", "Percent chance the Field Technician perk will work. Chance of is multiplied by level of this perk.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceFieldTechnicianHack: Int32 = 50;

  @runtimeProperty("ModSettings.mod", "NCLAIMS")
  @runtimeProperty("ModSettings.category", "Vehicle Claim System")
  @runtimeProperty("ModSettings.displayName", "Hacker Overlord Perk success chance")
  @runtimeProperty("ModSettings.description", "Percent chance the Hacker Overlord perk will work. Chance of is multiplied by level of this perk.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceHackerOverlordHack: Int32 = 100;

  @runtimeProperty("ModSettings.mod", "NCLAIMS")
  @runtimeProperty("ModSettings.category", "Notifications")
  @runtimeProperty("ModSettings.displayName", "Display Warning Messages")
  @runtimeProperty("ModSettings.description", "Toggles warnings when hacking a vehicle is successful.")
  let warningsON: Bool = true;

  @runtimeProperty("ModSettings.mod", "NCLAIMS")
  @runtimeProperty("ModSettings.category", "Testing only")
  @runtimeProperty("ModSettings.displayName", "Display Test Messages")
  @runtimeProperty("ModSettings.description", "Display Test Messages in the console and on screen")
  let debugON: Bool = false;

}

// Replace false with true to show full debug logs in CET console
public static func ShowDebugLogsClaimVehicles() -> Bool = false
