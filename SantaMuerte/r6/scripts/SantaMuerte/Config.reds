 public class SantaMuerteConfig {

  public static func Get() -> ref<SantaMuerteConfig> {
    let self: ref<SantaMuerteConfig> = new SantaMuerteConfig();
    return self;
  } 

  public let resurrectCount:  Int32 = 0;
  public let resurrectCountMax:  Int32 = 0;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Mod toggle")
  @runtimeProperty("ModSettings.description", "Enable or disable the mod if you need to revert back to the default system in certain situations.")
  let modON: Bool = true; 

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Unlimited Resurrect")
  @runtimeProperty("ModSettings.description", "Bypass the maximum number of resurrections")
  let unlimitedResurrectON: Bool = false; 

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Options")
  @runtimeProperty("ModSettings.category.order", "5")
  @runtimeProperty("ModSettings.displayName", "Resurrections Scale Modifier")
  @runtimeProperty("ModSettings.description", "Extends the range of number of resurrections allowed from 1 (Default) to 10 times default value)")
  @runtimeProperty("ModSettings.step", "0.1")
  @runtimeProperty("ModSettings.min", "0.1")
  @runtimeProperty("ModSettings.max", "10")
  let scaleResurrectionsModifier: Float = 1;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Options")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Resurrections Cap")
  @runtimeProperty("ModSettings.description", "Overrides the default value with a maximum number of allowed resurrections (use 0 to use the default dynamic limit).")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "200")
  let capResurrectionsOverride: Int32 = 0;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Options")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Enable Skip Time")
  @runtimeProperty("ModSettings.description", "If ON, a random amount of Skip Time will be applied before resurrection.")
  let skipTimeON: Bool = false;  

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Options")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Maximum hours of lost time")
  @runtimeProperty("ModSettings.description", "Sets the maximum amount of time (hours) skipped after a black out (picked at random).")
  @runtimeProperty("ModSettings.step", "0.1")
  @runtimeProperty("ModSettings.min", "0.1")
  @runtimeProperty("ModSettings.max", "5.0")
  let maxSkippedTime: Float = 0.1;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Blackout Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Enable Teleport to Safe Havens")
  @runtimeProperty("ModSettings.description", "If ON, V will get a random chance to wake up at a nearby Safe Haven location (Ripperdoc, Hospital, etc)")
  let blackoutSafeTeleportON: Bool = false;   

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Blackout Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Chance of Safe Haven Teleport")
  @runtimeProperty("ModSettings.description", "Sets the random chance of a teleport happening during blackouts")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let blackoutSafeTeleportChance: Int32 = 0;


  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Blackout Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Enable Detour Teleport")
  @runtimeProperty("ModSettings.description", "If ON, V will get a random chance to wake up at a nearby Detour location (unique spots, some dangerous)")
  let blackoutDetourTeleportON: Bool = false;   

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Blackout Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Chance of Detour Teleport")
  @runtimeProperty("ModSettings.description", "Sets the random chance of a teleport happening during blackouts")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let blackoutDetourTeleportChance: Int32 = 0;


  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Safeguards")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Protection from Death Landings")
  @runtimeProperty("ModSettings.description", "Turn ON for safeguard against getting stuck in unreachable areas.")
  let deathLandingProtectionON: Bool = true;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Notifications")
  @runtimeProperty("ModSettings.category.order", "14")
  @runtimeProperty("ModSettings.displayName", "Display Warning Messages")
  @runtimeProperty("ModSettings.description", "Toggles error message with count of resurrection during death scenes.")
  let warningsON: Bool = true;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Testing only")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Display Test Messages")
  @runtimeProperty("ModSettings.description", "Display Test Messages in the console and on screen")
  let debugON: Bool = true;

}

// Replace false with true to show full debug logs in CET console
public static func ShowDebugLogsSantaMuerte() -> Bool = false
