 public class VehiclesFastTravelConfig {

  public static func Get() -> ref<VehiclesFastTravelConfig> {
    let self: ref<VehiclesFastTravelConfig> = new VehiclesFastTravelConfig();
    return self;
  } 

  @runtimeProperty("ModSettings.mod", "VEHICLES FAST TRAVEL")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.category.order", "1")
  @runtimeProperty("ModSettings.displayName", "Mod toggle")
  @runtimeProperty("ModSettings.description", "Enable or disable the mod if you need to revert back to the default system in certain situations.")
  let modON: Bool = true; 


  @runtimeProperty("ModSettings.mod", "VEHICLES FAST TRAVEL")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.category.order", "2")
  @runtimeProperty("ModSettings.displayName", "Restore Vehicle Recall Key")
  @runtimeProperty("ModSettings.description", "Turn ON to restore the vehicle summon on the 'V' key (instead of turning the radio on/off).")
  let enableVehicleRecallKeyON: Bool = false; 

  @runtimeProperty("ModSettings.mod", "VEHICLES FAST TRAVEL")
  @runtimeProperty("ModSettings.category", "Main switch")
  @runtimeProperty("ModSettings.category.order", "3")
  @runtimeProperty("ModSettings.displayName", "Restore Vehicle Menu Key")
  @runtimeProperty("ModSettings.description", "Turn ON to restore the vehicle garage menu on the 'V' key (instead of the Radio menu set by this mod).")
  let enableVehicleMenuKeyON: Bool = false; 

  @runtimeProperty("ModSettings.mod", "VEHICLES FAST TRAVEL")
  @runtimeProperty("ModSettings.category", "Malware System")
  @runtimeProperty("ModSettings.category.order", "4")
  @runtimeProperty("ModSettings.displayName", "Malware System Toggle")
  @runtimeProperty("ModSettings.description", "Turn ON to enable chances of malware attacks when using data terminals.")
  let malwareON: Bool = false; 

  @runtimeProperty("ModSettings.mod", "VEHICLES FAST TRAVEL")
  @runtimeProperty("ModSettings.category", "Malware System")
  @runtimeProperty("ModSettings.category.order", "5")
  @runtimeProperty("ModSettings.displayName", "Chance of Low Level Malware")
  @runtimeProperty("ModSettings.description", "Percent chance using the data terminal will result in an malware infection (low difficulty).")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceMalwareLow: Int32 = 15;
 
  @runtimeProperty("ModSettings.mod", "VEHICLES FAST TRAVEL")
  @runtimeProperty("ModSettings.category", "Malware System")
  @runtimeProperty("ModSettings.category.order", "6")
  @runtimeProperty("ModSettings.displayName", "Chance of Mid Level Malware")
  @runtimeProperty("ModSettings.description", "Percent chance using the data terminal will result in a  malware infection (medium difficulty).")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceMalwareMedium: Int32 = 10;
 
  @runtimeProperty("ModSettings.mod", "VEHICLES FAST TRAVEL")
  @runtimeProperty("ModSettings.category", "Malware System")
  @runtimeProperty("ModSettings.category.order", "7")
  @runtimeProperty("ModSettings.displayName", "Chance of High Level Malware")
  @runtimeProperty("ModSettings.description", "Percent chance using the data terminal will result in a malware infection (high difficulty).")
  @runtimeProperty("ModSettings.step", "5")
  @runtimeProperty("ModSettings.min", "0")
  @runtimeProperty("ModSettings.max", "100")
  let chanceMalwareHigh: Int32 = 5;
 
  @runtimeProperty("ModSettings.mod", "VEHICLES FAST TRAVEL")
  @runtimeProperty("ModSettings.category", "Notifications")
  @runtimeProperty("ModSettings.category.order", "8")
  @runtimeProperty("ModSettings.displayName", "Display Warning Messages")
  @runtimeProperty("ModSettings.description", "Toggles warnings when hacking a vehicle is successful.")
  let warningsON: Bool = true;

  @runtimeProperty("ModSettings.mod", "VEHICLES FAST TRAVEL")
  @runtimeProperty("ModSettings.category", "Testing only")
  @runtimeProperty("ModSettings.category.order", "9")
  @runtimeProperty("ModSettings.displayName", "Display Test Messages")
  @runtimeProperty("ModSettings.description", "Display Test Messages in the console and on screen")
  let debugON: Bool = true;

}

// Replace false with true to show full debug logs in CET console
public static func ShowDebugLogsVehiclesFastTravel() -> Bool = false
