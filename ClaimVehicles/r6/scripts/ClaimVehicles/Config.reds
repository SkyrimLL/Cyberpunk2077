enum vehicleSummonMode {
  Normal = 0,
  Last = 1,
  Random = 2,
  Delamain = 3,
  Favorites = 4,
  All = 5 
}

public class ClaimVehiclesConfig {

  public static func Get() -> ref<ClaimVehiclesConfig> {
    let self: ref<ClaimVehiclesConfig> = new ClaimVehiclesConfig();
    return self;
  } 

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Mod toggle")
  @runtimeProperty("ModSettings.description", "Enable or disable the mod if you need to revert back to the default system in certain situations.")
  let modON: Bool = true; 

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Vehicle Summon Mode")
  @runtimeProperty("ModSettings.description", "Behavior of the vehicle summon action.")
  @runtimeProperty("ModSettings.displayValues", "\"Normal\", \"Last\", \"Random\", \"Delamain\", \"Favorites\", \"All\"")
  let summonMode: vehicleSummonMode = vehicleSummonMode.Normal;

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Manual Mode")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Manual Remote Control QuickHack Claim")
  @runtimeProperty("ModSettings.description", "Gives 100% chance of stealing vehicle if GearHead perk is ON and Remote Control Quickhack is used (OFF means claim attempts are dynamic)")
  let scannerModeON: Bool = false; 

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Dynamic mode - Vehicle Claim System")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Chance of success on Steal")
  @runtimeProperty("ModSettings.description", "Percent chance breaking in or hijacking a car will succeed in stealing it (locked or used vehicles only).")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceOnSteal: Int32 = 100;

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Dynamic mode - Vehicle Claim System")
  @runtimeProperty("ModSettings.category.order", "21")
  @runtimeProperty("ModSettings.displayName", "Chance of success on Exit")
  @runtimeProperty("ModSettings.description", "Percent chance exiting a vehicle will succeed in stealing it (open vehicles or bikes only).")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceOnExit: Int32 = 0;

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Dynamic mode - Vehicle Claim System")
  @runtimeProperty("ModSettings.category.order", "22")
  @runtimeProperty("ModSettings.displayName", "Low Perk success chance")
  @runtimeProperty("ModSettings.description", "Percent chance the low level perk will work (Gearhead, Carhacker, Road warrior). Chance of is multiplied by level of this perk (open vehicles only).")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceLowPerkHack: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Dynamic mode - Vehicle Claim System")
  @runtimeProperty("ModSettings.category.order", "23")
  @runtimeProperty("ModSettings.displayName", "Mid Perk level success chance")
  @runtimeProperty("ModSettings.description", "Percent chance the mid level perk will work (driver update, System overwhelm, Sleight of hand). Chance of is multiplied by level of this perk (open vehicles only).")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceMidPerkHack: Int32 = 50;

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Dynamic mode - Vehicle Claim System")
  @runtimeProperty("ModSettings.category.order", "24")
  @runtimeProperty("ModSettings.displayName", "High Perk level success chance")
  @runtimeProperty("ModSettings.description", "Percent chance the high level perk will work (Edgerunner, Smart synergy, Style over substance). Chance of is multiplied by level of this perk (open vehicles only).")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceHighPerkHack: Int32 = 100;

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Crime Reporting")
  @runtimeProperty("ModSettings.category.order", "30")
  @runtimeProperty("ModSettings.displayName", "Chance of Crime Report on FAIL")
  @runtimeProperty("ModSettings.description", "Percent chance a failed Claim attempt will result in an increased Wanted level.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceCrimeReportFail: Int32 = 80;

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Crime Reporting")
  @runtimeProperty("ModSettings.category.order", "31")
  @runtimeProperty("ModSettings.displayName", "Chance of Crime Report on SUCCESS")
  @runtimeProperty("ModSettings.description", "Percent chance a successful Claim attempt will result in an increased Wanted level.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceCrimeReportSuccess: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "QuickHacks support")
  @runtimeProperty("ModSettings.category.order", "40")
  @runtimeProperty("ModSettings.displayName", "Dynamic Remote Control QuickHack Claim")
  @runtimeProperty("ModSettings.description", "Remote Control QuickHack will attempt to claim a vehicle.")
  let remoteControlQuickhackON: Bool = true;  

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "QuickHacks support")
  @runtimeProperty("ModSettings.category.order", "41")
  @runtimeProperty("ModSettings.displayName", "Force Brakes QuickHack Dismiss")
  @runtimeProperty("ModSettings.description", "Force Brakes QuickHack will dismiss a vehicle if it is in your list.")
  let forceBrakesQuickhackON: Bool = false; 

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Notifications")
  @runtimeProperty("ModSettings.category.order", "50")
  @runtimeProperty("ModSettings.displayName", "Display Warning Messages")
  @runtimeProperty("ModSettings.description", "Toggles warnings when hacking a vehicle is successful.")
  let warningsON: Bool = true;

  @runtimeProperty("ModSettings.mod", "N.C.L.A.I.M.S")
  @runtimeProperty("ModSettings.category", "Testing only")
  @runtimeProperty("ModSettings.category.order", "60")
  @runtimeProperty("ModSettings.displayName", "Display Test Messages")
  @runtimeProperty("ModSettings.description", "Display Test Messages in the console and on screen")
  let debugON: Bool = true;

}

// Replace false with true to show full debug logs in CET console
public static func ShowDebugLogsClaimVehicles() -> Bool = false
