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
@runtimeProperty("ModSettings.displayName", "Chance of success on Steal")
@runtimeProperty("ModSettings.description", "Percent chance breaking in or hijacking a car will succeed in stealing it (locked or used vehicles only).")
@runtimeProperty("ModSettings.step", "5")
@runtimeProperty("ModSettings.min", "0")
@runtimeProperty("ModSettings.max", "100")
  let chanceOnSteal: Int32 = 100;

@runtimeProperty("ModSettings.mod", "NCLAIMS")
@runtimeProperty("ModSettings.category", "Vehicle Claim System")
@runtimeProperty("ModSettings.displayName", "Low Perk success chance")
@runtimeProperty("ModSettings.description", "Percent chance the low level perk will work (Gearhead, Carhacker, Road warrior). Chance of is multiplied by level of this perk (open vehicles only).")
@runtimeProperty("ModSettings.step", "5")
@runtimeProperty("ModSettings.min", "0")
@runtimeProperty("ModSettings.max", "100")
  let chanceLowPerkHack: Int32 = 20;

@runtimeProperty("ModSettings.mod", "NCLAIMS")
@runtimeProperty("ModSettings.category", "Vehicle Claim System")
@runtimeProperty("ModSettings.displayName", "Mid Perk level success chance")
@runtimeProperty("ModSettings.description", "Percent chance the mid level perk will work (driver update, System overwhelm, Sleight of hand). Chance of is multiplied by level of this perk (open vehicles only).")
@runtimeProperty("ModSettings.step", "5")
@runtimeProperty("ModSettings.min", "0")
@runtimeProperty("ModSettings.max", "100")
  let chanceMidPerkHack: Int32 = 50;

@runtimeProperty("ModSettings.mod", "NCLAIMS")
@runtimeProperty("ModSettings.category", "Vehicle Claim System")
@runtimeProperty("ModSettings.displayName", "High Perk level success chance")
@runtimeProperty("ModSettings.description", "Percent chance the high level perk will work (Edgerunner, Smart synergy, Style over substance). Chance of is multiplied by level of this perk (open vehicles only).")
@runtimeProperty("ModSettings.step", "5")
@runtimeProperty("ModSettings.min", "0")
@runtimeProperty("ModSettings.max", "100")
  let chanceHighPerkHack: Int32 = 100;

@runtimeProperty("ModSettings.mod", "NCLAIMS")
@runtimeProperty("ModSettings.category", "Notifications")
@runtimeProperty("ModSettings.displayName", "Display Warning Messages")
@runtimeProperty("ModSettings.description", "Toggles warnings when hacking a vehicle is successful.")
  let warningsON: Bool = true;

@runtimeProperty("ModSettings.mod", "NCLAIMS")
@runtimeProperty("ModSettings.category", "Testing only")
@runtimeProperty("ModSettings.displayName", "Display Test Messages")
@runtimeProperty("ModSettings.description", "Display Test Messages in the console and on screen")
  let debugON: Bool = true;

}

// Replace false with true to show full debug logs in CET console
public static func ShowDebugLogsClaimVehicles() -> Bool = false
