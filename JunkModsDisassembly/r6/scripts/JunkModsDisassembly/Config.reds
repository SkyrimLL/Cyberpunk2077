enum RepeatDisassemblyRepeatModes { 
  RemoveAllButOne = 0,
  RemoveAll = 1 
}

enum RepeatDisassemblyQualityModes {
  KeepOneOfEach = 0,
  SelectMaxQuality = 1,
  TopQualityOnly = 2
}

enum RepeatDisassemblyQuality {
  Common = 0, 
  Uncommon = 1, 
  Rare = 2, 
  Epic = 3, 
  Legendary = 4,  
  Iconic = 5
}

 public class RepeatDisassemblyConfig {

  public static func Get() -> ref<RepeatDisassemblyConfig> {
    let self: ref<RepeatDisassemblyConfig> = new RepeatDisassemblyConfig();
    return self;
  } 

  @runtimeProperty("ModSettings.mod", "JUNK MODS DISASSEMBLY")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Mod toggle")
  @runtimeProperty("ModSettings.description", "Enable or disable the mod if you need to revert back to the default system in certain situations.")
  let modON: Bool = true; 

  @runtimeProperty("ModSettings.mod", "JUNK MODS DISASSEMBLY")
  @runtimeProperty("ModSettings.category", "Compatibility")
  @runtimeProperty("ModSettings.category.order", "5")
  @runtimeProperty("ModSettings.displayName", "Enable Disassemble Junk option")
  @runtimeProperty("ModSettings.description", "Set to OFF if you want to clean up weapon mods instead of disassembling Junk. Set to ON to do both at the same time.")
  let disassembleJunkON: Bool = true; 

  @runtimeProperty("ModSettings.mod", "JUNK MODS DISASSEMBLY")
  @runtimeProperty("ModSettings.category", "Modes")
  @runtimeProperty("ModSettings.category.order", "10")
  @runtimeProperty("ModSettings.displayName", "Repeat Mode")
  @runtimeProperty("ModSettings.description", "Sets how to process weapon mods disassembly - repeat only selected item type or all weapon mods.") 
  let repeatDisassemblyRepeatMode: RepeatDisassemblyRepeatModes = RepeatDisassemblyRepeatModes.RemoveAllButOne;

  @runtimeProperty("ModSettings.mod", "JUNK MODS DISASSEMBLY")
  @runtimeProperty("ModSettings.category", "Modes")
  @runtimeProperty("ModSettings.category.order", "11")
  @runtimeProperty("ModSettings.displayName", "Quality Mode")
  @runtimeProperty("ModSettings.description", "Sets the quality awareness of disassembly - Keep one of each quality, only the top quality for each or disassemble ALL weapon mods.") 
  let repeatDisassemblyQualityMode: RepeatDisassemblyQualityModes = RepeatDisassemblyQualityModes.KeepOneOfEach;

  @runtimeProperty("ModSettings.mod", "JUNK MODS DISASSEMBLY")
  @runtimeProperty("ModSettings.category", "Modes")
  @runtimeProperty("ModSettings.category.order", "12")
  @runtimeProperty("ModSettings.displayName", "Maximum Disassembly Quality")
  @runtimeProperty("ModSettings.description", "For use with 'SelectMinQuality'quality mode. Sets the level of quality preserved from disassembly.") 
  let repeatDisassemblyQualityMax: RepeatDisassemblyQuality = RepeatDisassemblyQuality.Common;

  @runtimeProperty("ModSettings.mod", "JUNK MODS DISASSEMBLY")
  @runtimeProperty("ModSettings.category", "Notifications")
  @runtimeProperty("ModSettings.category.order", "90")
  @runtimeProperty("ModSettings.displayName", "Display Warning Messages")
  @runtimeProperty("ModSettings.description", "Toggles error message with count of resurrection during death scenes.")
  let warningsON: Bool = true;

  @runtimeProperty("ModSettings.mod", "JUNK MODS DISASSEMBLY")
  @runtimeProperty("ModSettings.category", "Testing only")
  @runtimeProperty("ModSettings.category.order", "91")
  @runtimeProperty("ModSettings.displayName", "Display Test Messages")
  @runtimeProperty("ModSettings.description", "Display Test Messages in the console and on screen")
  let debugON: Bool = true;

}

// Replace false with true to show full debug logs in CET console
public static func ShowDebugLogsRepeatDisassembly() -> Bool = false
