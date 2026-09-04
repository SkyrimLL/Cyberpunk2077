// FieldMedic — ModSettings-backed configuration.
// Toggle individual conversions and the loot-injection helper at runtime without editing YAML.

public class FieldMedicConfig {

  public static func Get() -> ref<FieldMedicConfig> {
    let self: ref<FieldMedicConfig> = new FieldMedicConfig();
    return self;
  }

  @runtimeProperty("ModSettings.mod", "FieldMedic")
  @runtimeProperty("ModSettings.category", "General")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Enable FieldMedic")
  @runtimeProperty("ModSettings.description", "Master switch. Disabling this skips all runtime hooks; TweakXL YAML overrides still apply because they load with the game.")
  let modON: Bool = true;

  @runtimeProperty("ModSettings.mod", "FieldMedic")
  @runtimeProperty("ModSettings.category", "Loot Injection")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Inject Bloody Bandages")
  @runtimeProperty("ModSettings.description", "When a body / container spawns Medical Gauze, roll for an additional Bloody Bandage. Adds emergency-heal supply for gritty runs.")
  let injectBloodyBandages: Bool = true;

  @runtimeProperty("ModSettings.mod", "FieldMedic")
  @runtimeProperty("ModSettings.category", "Loot Injection")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Bloody Bandage drop chance")
  @runtimeProperty("ModSettings.description", "Percent chance to add a Bloody Bandage alongside vanilla Medical Gauze drops.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let bloodyBandageChance: Int32 = 35;

  @runtimeProperty("ModSettings.mod", "FieldMedic")
  @runtimeProperty("ModSettings.category", "Loot Injection")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Inject Bleach Bottles")
  @runtimeProperty("ModSettings.description", "Add Bleach / Detergent bottles to industrial and janitorial-flagged containers so a detox option is reachable.")
  let injectBleachBottles: Bool = true;

  @runtimeProperty("ModSettings.mod", "FieldMedic")
  @runtimeProperty("ModSettings.category", "Loot Injection")
  @runtimeProperty("ModSettings.category.order", "13")
  @runtimeProperty("ModSettings.displayName", "Bleach Bottle drop chance")
  @runtimeProperty("ModSettings.description", "Percent chance a container that already contains bleach-adjacent junk also drops a usable Bleach Bottle.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let bleachBottleChance: Int32 = 25;

  @runtimeProperty("ModSettings.mod", "FieldMedic")
  @runtimeProperty("ModSettings.category", "Testing only")
  @runtimeProperty("ModSettings.category.order", "92")
  @runtimeProperty("ModSettings.displayName", "Display Test Messages")
  @runtimeProperty("ModSettings.description", "Display Test Messages in the console and on screen")
  let debugLog: Bool = false;

}
