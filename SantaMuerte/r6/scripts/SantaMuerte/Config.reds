 enum santaMuerteRelicMode {
  Low = 0,
  Medium = 1,
  High = 2 
}

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
  @runtimeProperty("ModSettings.category", "Difficulty")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Relic Difficulty Mode")
  @runtimeProperty("ModSettings.description", "LOW (Relic improves over time and grants new resurrection points) - MEDIUM (simple count down) - HIGH (Relic degrades over time and takes away resurrection points at random).")
  @runtimeProperty("ModSettings.displayValues", "\"Low\", \"Medium\", \"High\"")
  let santaMuerteRelicDifficulty: santaMuerteRelicMode = santaMuerteRelicMode.Medium;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Difficulty")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Immersive Difficulty")
  @runtimeProperty("ModSettings.description", "Let your choice about Jackie's body set the difficulty automatically (Stay at motel - Easy, To Mama Welles - Medium, To Viktor - High)")
  let santaMuerteLoreDifficultyON: Bool = true; 

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Death Options")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "New Death Animation")
  @runtimeProperty("ModSettings.description", "Use the animation from Second Heart Fx (V falls flat on the ground when dying).")
  let newDeathAnimationON: Bool = true; 

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Death Options")
  @runtimeProperty("ModSettings.category.order", "15")
  @runtimeProperty("ModSettings.displayName", "Randomize Death Animation")
  @runtimeProperty("ModSettings.description", "Use a mix between default animation and the animation from Second Heart Fx (V falls flat on the ground when dying).")
  let randomDeathAnimationON: Bool = true;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Death Options")
  @runtimeProperty("ModSettings.category.order", "16")
  @runtimeProperty("ModSettings.displayName", "Death Animation Delay")
  @runtimeProperty("ModSettings.description", "Delay in seconds before resurrection to allow death animation to play. Set to 0 for instant resurrection.")
  @runtimeProperty("ModSettings.step", "0.5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "5.0")
  let deathAnimationDelay: Float = 2.0; 

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Resurrection Options")
  @runtimeProperty("ModSettings.category.order", "20")
  @runtimeProperty("ModSettings.displayName", "Resurrections Scale Modifier")
  @runtimeProperty("ModSettings.description", "Extends the range of number of resurrections allowed from 1 (Default) to 10 times default value)")
  @runtimeProperty("ModSettings.step", "0.1")
  @runtimeProperty("ModSettings.min", "0.1")
  @runtimeProperty("ModSettings.max", "10")
  let scaleResurrectionsModifier: Float = 1;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Resurrection Options")
  @runtimeProperty("ModSettings.category.order", "21")
  @runtimeProperty("ModSettings.displayName", "Resurrections Cap")
  @runtimeProperty("ModSettings.description", "Overrides the default value with a maximum number of allowed resurrections (use 0 to use the default dynamic limit).")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "200")
  let capResurrectionsOverride: Int32 = 0;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Resurrection Options")
  @runtimeProperty("ModSettings.category.order", "22")
  @runtimeProperty("ModSettings.displayName", "Unlimited Resurrections")
  @runtimeProperty("ModSettings.description", "If ON, you will have unlimited resurrections and never reach the maximum. The resurrection pool will not be managed.")
  let unlimitedResurrectionsON: Bool = false;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Resurrection Options")
  @runtimeProperty("ModSettings.category.order", "23")
  @runtimeProperty("ModSettings.displayName", "Second Heart Installed")
  @runtimeProperty("ModSettings.description", "Amplifies resurrection recovery during sleep/rest")
  let hasSecondHeartInstalledON: Bool = false; 

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Resurrection Options")
  @runtimeProperty("ModSettings.category.order", "24")
  @runtimeProperty("ModSettings.displayName", "Dark Future Compatibility")
  @runtimeProperty("ModSettings.description", "Resurrections will impact your energy and nerve.")
  let darkFutureEffectON: Bool = false; 

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Skip Time")
  @runtimeProperty("ModSettings.category.order", "25")
  @runtimeProperty("ModSettings.displayName", "Enable Skip Time")
  @runtimeProperty("ModSettings.description", "If ON, a random amount of Skip Time will be applied before resurrection.")
  let skipTimeON: Bool = false;  

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Skip Time")
  @runtimeProperty("ModSettings.category.order", "26")
  @runtimeProperty("ModSettings.displayName", "Min Skip Time")
  @runtimeProperty("ModSettings.description", "Sets the minimum amount of time (hours) skipped after a resurrection (picked at random).")
  @runtimeProperty("ModSettings.step", "0.1")
  @runtimeProperty("ModSettings.min", "0.1")
  @runtimeProperty("ModSettings.max", "24.0")
  let minSkippedTime: Float = 0.5;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Skip Time")
  @runtimeProperty("ModSettings.category.order", "27")
  @runtimeProperty("ModSettings.displayName", "Max Skip Time")
  @runtimeProperty("ModSettings.description", "Sets the maximum amount of time (hours) skipped after a resurrection (picked at random).")
  @runtimeProperty("ModSettings.step", "0.1")
  @runtimeProperty("ModSettings.min", "0.1")
  @runtimeProperty("ModSettings.max", "24.0")
  let maxSkippedTime: Float = 2.0;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Blackout")
  @runtimeProperty("ModSettings.category.order", "28")
  @runtimeProperty("ModSettings.displayName", "Enable Blackout Effect")
  @runtimeProperty("ModSettings.description", "If ON, a blackout effect will kick in when resurrecting.")
  let blackoutON: Bool = false;  

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Blackout")
  @runtimeProperty("ModSettings.category.order", "29")
  @runtimeProperty("ModSettings.displayName", "Blackout trigger")
  @runtimeProperty("ModSettings.description", "Sets the amount of time (hours) after which a resurrection triggers a blackout (Skip time needs to be ON for this option).")
  @runtimeProperty("ModSettings.step", "0.1")
  @runtimeProperty("ModSettings.min", "0.1")
  @runtimeProperty("ModSettings.max", "5.0")
  let maxBlackoutTime: Float = 1.0;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Death Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "30")
  @runtimeProperty("ModSettings.displayName", "Enable Teleport Effect")
  @runtimeProperty("ModSettings.description", "If ON, there will be random chances for a teleport to a safe or unexpected destination on death.")
  let teleportON: Bool = false;  

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Death Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "31")
  @runtimeProperty("ModSettings.displayName", "Overall Chance of Teleport")
  @runtimeProperty("ModSettings.description", "Sets the random chance of a teleport happening during blackouts")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let blackoutTeleportChance: Int32 = 0;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Death Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "32")
  @runtimeProperty("ModSettings.displayName", "Enable Teleport to Central Hospital or Viktor")
  @runtimeProperty("ModSettings.description", "If ON, V will get a random chance to wake up outside a nearby Safe Haven location (Hospital or Viktor). This is a separate option for mods that block access to certain ripper docs like Take a Breather.")
  let blackoutSafeTeleportHospitalON: Bool = true;   

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Death Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "33")
  @runtimeProperty("ModSettings.displayName", "Enable Teleport to Ripper Docs")
  @runtimeProperty("ModSettings.description", "If ON, V will get a random chance to wake up at a nearby Safe Haven location (Ripperdoc)")
  let blackoutSafeTeleportON: Bool = true;   

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Death Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "34")
  @runtimeProperty("ModSettings.displayName", "Safe Teleport Fee")
  @runtimeProperty("ModSettings.description", "Amount of money removed for a safe teleport. Not enough money cancels the teleport. use 0 to disable.")
  @runtimeProperty("ModSettings.step", "1000")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100000")
  let safeTeleportFee: Int32 = 0;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Death Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "35")
  @runtimeProperty("ModSettings.displayName", "Enable Detour Teleport")
  @runtimeProperty("ModSettings.description", "If ON, V will get a random chance to wake up at a nearby Detour location (unique spots, some dangerous)")
  let blackoutDetourTeleportON: Bool = false;   

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Death Teleport Scenarios")
  @runtimeProperty("ModSettings.category.order", "36")
  @runtimeProperty("ModSettings.displayName", "Chance of Detour Teleport")
  @runtimeProperty("ModSettings.description", "Sets the random chance of a teleport to an unexpected destination")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let blackoutDetourTeleportChance: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Robbed and left for dead")
  @runtimeProperty("ModSettings.category.order", "40")
  @runtimeProperty("ModSettings.displayName", "Death Teleport Hardcore mode")
  @runtimeProperty("ModSettings.description", "If ON, when teleported to an unsafe destination (Detour), V will be robbed from most inventory items (WARNING: Quest items should be safe. There is no way to recover stolen items).")
  let hardcoreDetourRobbedON: Bool = false;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Robbed and left for dead")
  @runtimeProperty("ModSettings.category.order", "41")
  @runtimeProperty("ModSettings.displayName", "Only rob on teleports")
  @runtimeProperty("ModSettings.description", "If ON, robbery can only happen during teleports. If OFF, robbery can also happen during blackout/time skip events without teleportation.")
  let hardcoreOnlyRobOnTeleportON: Bool = true;   

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Robbed and left for dead")
  @runtimeProperty("ModSettings.category.order", "42")
  @runtimeProperty("ModSettings.displayName", "Chance of being robbed")
  @runtimeProperty("ModSettings.description", "Sets the random chance of stolen items from V's inventory after waking up in an unsafe destination.")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let hardcoreDetourRobbedChance: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Robbed and left for dead")
  @runtimeProperty("ModSettings.category.order", "43")
  @runtimeProperty("ModSettings.displayName", "Always steal equipped items")
  @runtimeProperty("ModSettings.description", "If ON, equipped items will be stolen no matter what. If OFF, equipped items will be subjected to the chance of being robbed defined above.")
  let hardcoreStealEquippedON: Bool = false;   

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Robbed and left for dead")
  @runtimeProperty("ModSettings.category.order", "44")
  @runtimeProperty("ModSettings.displayName", "Chance of losing items when robbed")
  @runtimeProperty("ModSettings.description", "Sets the random chance of stolen items items from V's inventory after waking up in an unsafe destination.")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let hardcoreDetourRobbedClothingChance: Int32 = 40;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Robbed and left for dead")
  @runtimeProperty("ModSettings.category.order", "45")
  @runtimeProperty("ModSettings.displayName", "Some detours can strip cyberware")
  @runtimeProperty("ModSettings.description", "If ON, some unsafe destinations will also include Cyberware as items that can be stolen.")
  let hardcoreStealCyberwareON: Bool = false;   
  
  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Robbed and left for dead")
  @runtimeProperty("ModSettings.category.order", "46")
  @runtimeProperty("ModSettings.displayName", "Percent of lost money when robbed")
  @runtimeProperty("ModSettings.description", "Sets percentage of money robbed after waking up in an unsafe destination (set to 0 to disable)")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let hardcoreDetourRobbedMoneyPercent: Int32 = 0;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Safeguards")
  @runtimeProperty("ModSettings.category.order", "50")
  @runtimeProperty("ModSettings.displayName", "Protection from Death Landings")
  @runtimeProperty("ModSettings.description", "Turn ON for safeguard against getting stuck in unreachable areas.")
  let deathLandingProtectionON: Bool = true;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Safeguards")
  @runtimeProperty("ModSettings.category.order", "51")
  @runtimeProperty("ModSettings.displayName", "Protection from Death in Vehicles")
  @runtimeProperty("ModSettings.description", "Turn ON to allow resurrections in vehicles.")
  let deathInVehiclesProtectionON: Bool = true;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Safeguards")
  @runtimeProperty("ModSettings.category.order", "52")
  @runtimeProperty("ModSettings.displayName", "Allow death when V is Johnny")
  @runtimeProperty("ModSettings.description", "Turn OFF for infinite resurrection (but no teleport) when V is Johnny.")
  let deathWhenImpersonatingJohnnyON: Bool = true;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Sleep Recovery")
  @runtimeProperty("ModSettings.category.order", "55")
  @runtimeProperty("ModSettings.displayName", "Enable Sleep Recovery")
  @runtimeProperty("ModSettings.description", "Turn ON to restore a small amount of resurrections after sleeping (time skip of 3+ hours).")
  let sleepRecoveryON: Bool = true;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Sleep Recovery")
  @runtimeProperty("ModSettings.category.order", "56")
  @runtimeProperty("ModSettings.displayName", "Resurrections Restored")
  @runtimeProperty("ModSettings.description", "Number of resurrections restored after a good sleep (capped at max).")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "1")
  @runtimeProperty("ModSettings.max", "10")
  let sleepRecoveryAmount: Int32 = 2;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Sleep Recovery")
  @runtimeProperty("ModSettings.category.order", "57")
  @runtimeProperty("ModSettings.displayName", "Min Sleep Duration (hours)")
  @runtimeProperty("ModSettings.description", "Minimum time skip duration (in hours) required to trigger resurrection recovery.")
  @runtimeProperty("ModSettings.step", "0.5")
  @runtimeProperty("ModSettings.min", "1.0")
  @runtimeProperty("ModSettings.max", "12.0")
  let sleepRecoveryMinDuration: Float = 3.0;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "HUD")
  @runtimeProperty("ModSettings.category.order", "60")
  @runtimeProperty("ModSettings.displayName", "Display Resurrections in HUD")
  @runtimeProperty("ModSettings.description", "Turn ON to display the number of Resurrections left in the Health bar (needs a reload of the gameto take effect).")
  let santaMuerteWidgetON: Bool = true;
 
  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "HUD")
  @runtimeProperty("ModSettings.category.order", "61")
  @runtimeProperty("ModSettings.displayName", "Compatibility Informative HUD")
  @runtimeProperty("ModSettings.description", "Turn ON for compatibility with Informative HUD Quickhacks Memory Counter.")
  let informativeHUDCompatibilityON: Bool = false;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Tutorials")
  @runtimeProperty("ModSettings.category.order", "80")
  @runtimeProperty("ModSettings.displayName", "Display Tutorial Messages")
  @runtimeProperty("ModSettings.description", "Show tutorial messages explaining game mechanics at key moments (first resurrection, first teleport, etc.). Tutorials will only display once per save.")
  let showTutorialsON: Bool = true;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Tutorials")
  @runtimeProperty("ModSettings.category.order", "81")
  @runtimeProperty("ModSettings.displayName", "Reset All Tutorials")
  @runtimeProperty("ModSettings.description", "Turn ON to reset all tutorial messages so they can be shown again. This will automatically turn OFF after the reset is complete.")
  let resetTutorialsON: Bool = false;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Notifications")
  @runtimeProperty("ModSettings.category.order", "90")
  @runtimeProperty("ModSettings.displayName", "Display Warning Messages")
  @runtimeProperty("ModSettings.description", "Toggles error message with count of resurrection during death scenes.")
  let warningsON: Bool = true;

  @runtimeProperty("ModSettings.mod", "SANTA MUERTE")
  @runtimeProperty("ModSettings.category", "Testing only")
  @runtimeProperty("ModSettings.category.order", "92")
  @runtimeProperty("ModSettings.displayName", "Display Test Messages")
  @runtimeProperty("ModSettings.description", "Display Test Messages in the console and on screen")
  let debugON: Bool = true;

  // ── Listener registration ────────────────────────────────────────────────

  public func RegisterMyListeners() -> Void {
      ModSettings.RegisterListenerToClass(this);
  }
}

// Replace false with true to show full debug logs in CET console
public static func ShowDebugLogsSantaMuerte() -> Bool = false
