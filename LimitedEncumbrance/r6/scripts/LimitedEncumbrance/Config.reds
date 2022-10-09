public class LimitedEncumbranceConfig {

  public static func Get() -> ref<LimitedEncumbranceConfig> {
    let self: ref<LimitedEncumbranceConfig> = new LimitedEncumbranceConfig();
    return self;
  } 
 
  @runtimeProperty("ModSettings.mod", "LEncumbrance")
  @runtimeProperty("ModSettings.category", "Encumbrance System")
  @runtimeProperty("ModSettings.displayName", "Base Carry Capacity")
  @runtimeProperty("ModSettings.description", "How much weight you can carry if you had only your backpack (no clothes).")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "5")
  @runtimeProperty("ModSettings.max", "100")
  let carryCapacityBase: Int32 = 25;

  @runtimeProperty("ModSettings.mod", "LEncumbrance")
  @runtimeProperty("ModSettings.category", "Encumbrance System")
  @runtimeProperty("ModSettings.displayName", "Player Level Modifier")
  @runtimeProperty("ModSettings.description", "Contribution of the player level to the carry capacity bonus (percentage of player level added to base carry capacity).")
  @runtimeProperty("ModSettings.step", "10")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "200")
  let playerLevelMod: Int32 = 50;

  @runtimeProperty("ModSettings.mod", "LEncumbrance")
  @runtimeProperty("ModSettings.category", "Encumbrance System")
  @runtimeProperty("ModSettings.displayName", "PackMuke Perk Modifier")
  @runtimeProperty("ModSettings.description", "Contribution of the PackMule Perk to the carry capacity bonus (percentage applied to the base carry capacity).")
  @runtimeProperty("ModSettings.step", "10")
  @runtimeProperty("ModSettings.min", "100")
  @runtimeProperty("ModSettings.max", "200")
  let playerPackMuleMod: Int32 = 150;

  @runtimeProperty("ModSettings.mod", "LEncumbrance")
  @runtimeProperty("ModSettings.category", "Encumbrance System")
  @runtimeProperty("ModSettings.displayName", "Carry Capacity Cap Modifier")
  @runtimeProperty("ModSettings.description", "Sets the maximum value assigned to calculated carry capacity (percentage applied to base carry capacity).")
  @runtimeProperty("ModSettings.step", "10")
  @runtimeProperty("ModSettings.min", "100")
  @runtimeProperty("ModSettings.max", "400")
  let carryCapacityCapMod: Int32 = 150;

  @runtimeProperty("ModSettings.mod", "LEncumbrance")
  @runtimeProperty("ModSettings.category", "Encumbrance System")
  @runtimeProperty("ModSettings.displayName", "Encumbrance Equipment Bonus")
  @runtimeProperty("ModSettings.description", "Modifier applied to total weight in inventory. Use less than 100 to account for pockets and equiped items and more than 100 to add encumbrance instead.")
  @runtimeProperty("ModSettings.step", "10")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "400")
  let encumbranceEquipmentBonus: Int32 = 80;

  @runtimeProperty("ModSettings.mod", "LEncumbrance")
  @runtimeProperty("ModSettings.category", "Notifications")
  @runtimeProperty("ModSettings.displayName", "Display Warning Messages")
  @runtimeProperty("ModSettings.description", "Toggles warnings when exceeding your base carry capacity without any bonus.")
  let warningsON: Bool = true;

  @runtimeProperty("ModSettings.mod", "LEncumbrance")
  @runtimeProperty("ModSettings.category", "Notifications")
  @runtimeProperty("ModSettings.displayName", "Use New Encumbrance Display")
  @runtimeProperty("ModSettings.description", "Changes the carry capacity display with how much you can carry.")
  let newEncumbranceDisplayON: Bool = true;

}

// Replace false with true to show full debug logs in CET console
public static func ShowDebugLogsLimitedEncumbrance() -> Bool = false
