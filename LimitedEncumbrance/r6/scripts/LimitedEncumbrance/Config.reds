public class LimitedEncumbranceConfig {

  public static func Get() -> ref<LimitedEncumbranceConfig> {
    let self: ref<LimitedEncumbranceConfig> = new LimitedEncumbranceConfig();
    return self;
  } 

  // MOD SETTINGS config is commented out until MOD SETTINGS is updated for version 2.0+ / Phantom Liberty

  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Mod toggle")
  @runtimeProperty("ModSettings.description", "Enable or disable the mod if you need to revert back to the default system in certain situations.")
  let modON: Bool = true;
 
  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Limited Encumbrance System")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Original Capacity Contribution")
  @runtimeProperty("ModSettings.description", "Percentage of the game's default carry capacity used in the new calculation.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let carryCapacityContribution: Int32 = 10;
 
  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Limited Encumbrance System")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Base Carry Capacity")
  @runtimeProperty("ModSettings.description", "Weight of weapons you can carry and still be able to run or jump (not counting clothes or backpack).")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "5")
  @runtimeProperty("ModSettings.max", "100")
  let carryCapacityBase: Int32 = 25;
 
  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Limited Encumbrance System")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Backpack size")
  @runtimeProperty("ModSettings.description", "How much weight you can carry in your default 'backpack' and still be able to run and jump.")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let carryCapacityBackpack: Int32 = 10;

  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Limited Encumbrance System")
  @runtimeProperty("ModSettings.category.order", "5")
  @runtimeProperty("ModSettings.displayName", "Player Level Modifier")
  @runtimeProperty("ModSettings.description", "Contribution of the player level to the carry capacity bonus (percentage of player level added to base carry capacity).")
  @runtimeProperty("ModSettings.step", "10")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "200")
  let playerLevelMod: Int32 = 10;

  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Limited Encumbrance System")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Perk Modifier")
  @runtimeProperty("ModSettings.description", "Contribution of Perks to the carry capacity bonus (Like a Feather, Juggernaut, Unstoppable Force - each perk add a percentage applied to the backpack carry capacity).")
  @runtimeProperty("ModSettings.step", "10")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let playerPerkMod: Int32 = 10;

  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Limited Encumbrance System")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Encumbrance Equipment Bonus")
  @runtimeProperty("ModSettings.description", "Modifier applied to equipped items. 100 means worn items have no impact. More than 100 means worn items improve movement. Less than 100 means worn items limit movement.")
  @runtimeProperty("ModSettings.step", "10")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "400")
  let encumbranceEquipmentBonus: Int32 = 50; 

  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Limited Encumbrance System")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Alert Theshold")
  @runtimeProperty("ModSettings.description", "Remaining capacity that will trigger warning messages.")
  @runtimeProperty("ModSettings.step", "1")
  @runtimeProperty("ModSettings.min", "1")
  @runtimeProperty("ModSettings.max", "40")
  let carryCapacityAlertTheshold: Int32 = 20;

  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Limited Encumbrance System")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Carry Capacity Cap")
  @runtimeProperty("ModSettings.description", "Sets the maximum value assigned to the carry capacity (in total value)")
  @runtimeProperty("ModSettings.step", "10")
  @runtimeProperty("ModSettings.min", "10")
  @runtimeProperty("ModSettings.max", "200")
  let carryCapacityCapMod: Int32 = 100;

  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Simple Encumbrance System")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Carry Capacity Override")
  @runtimeProperty("ModSettings.description", "Overrides the Limited Carry Capacity system with a fixed value (use 0 to turn OFF)")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "400")
  let carryCapacityOverride: Int32 = 0;

  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Notifications")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Display Warning Messages")
  @runtimeProperty("ModSettings.description", "Toggles warnings when exceeding your base carry capacity without any bonus.")
  let warningsON: Bool = true;

  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Notifications")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Use New Encumbrance Display")
  @runtimeProperty("ModSettings.description", "Changes the carry capacity display with how much you can carry.")
  let newEncumbranceDisplayON: Bool = true;

  @runtimeProperty("ModSettings.mod", "LIMITED ENCUMBRANCE")
  @runtimeProperty("ModSettings.category", "Testing only")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Display Test Messages")
  @runtimeProperty("ModSettings.description", "Display Test Messages in the console and on screen")
  let debugON: Bool = true;

}

// Replace false with true to show full debug logs in CET console
public static func ShowDebugLogsLimitedEncumbrance() -> Bool = false
