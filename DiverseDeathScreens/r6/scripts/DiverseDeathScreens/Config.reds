 public class DiverseDeathScreensConfig {

  public static func Get() -> ref<DiverseDeathScreensConfig> {
    let self: ref<DiverseDeathScreensConfig> = new DiverseDeathScreensConfig();
    return self;
  }  

  @runtimeProperty("ModSettings.mod", "DIVERSE DEATH SCREENS")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Mod toggle")
  @runtimeProperty("ModSettings.description", "Enable or disable the mod if you need to revert back to the default system in certain situations.")
  let modON: Bool = true; 

  @runtimeProperty("ModSettings.mod", "DIVERSE DEATH SCREENS")
  @runtimeProperty("ModSettings.category", "Options")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Enable randomization")
  @runtimeProperty("ModSettings.description", "If OFF, only the shutdown sequence from the original scene with Dex is used. If ON, the death screen effect is picked from a list at random.")
  let randomizeDeathScreensON: Bool = false;  

  @runtimeProperty("ModSettings.mod", "DIVERSE DEATH SCREENS")
  @runtimeProperty("ModSettings.category", "Options")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Enable long animations")
  @runtimeProperty("ModSettings.description", "If ON, there is a small chance a random long animation will trigger.")
  let enableLongAnimationsON: Bool = false;  

  @runtimeProperty("ModSettings.mod", "DIVERSE DEATH SCREENS")
  @runtimeProperty("ModSettings.category", "Options")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Chance of Long Animation")
  @runtimeProperty("ModSettings.description", "Only used when Enable long animations is ON.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceLongAnimation: Int32 = 10;

  @runtimeProperty("ModSettings.mod", "DIVERSE DEATH SCREENS")
  @runtimeProperty("ModSettings.category", "Options")
  @runtimeProperty("ModSettings.category.order", "5")
  @runtimeProperty("ModSettings.displayName", "Death Screens Opacity")
  @runtimeProperty("ModSettings.description", "Set to 0 for fully transparent and 100 for fully opaque.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let deathScreensOpacity: Int32 = 50;

  @runtimeProperty("ModSettings.mod", "DIVERSE DEATH SCREENS")
  @runtimeProperty("ModSettings.category", "Testing only")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Display Test Messages")
  @runtimeProperty("ModSettings.description", "Display Test Messages in the console and on screen")
  let debugON: Bool = true;

}

// Replace false with true to show full debug logs in CET console
public static func ShowDebugLogsDiverseDeathScreens() -> Bool = false

