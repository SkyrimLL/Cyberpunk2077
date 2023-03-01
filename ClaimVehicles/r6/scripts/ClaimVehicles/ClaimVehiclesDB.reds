public class VehicleProperties {

  let key: String;
  let vehicleModel: String;
  let vehicleString: String;

  public static func CreateItem(_key: String, _model: String, _string: String) -> ref<VehicleProperties> {
    let Item = new VehicleProperties();
    Item.key = _key;
    Item.vehicleModel = _model;
    Item.vehicleString = _string;
    return Item;
  }
}

public class ClaimVehicleDB {

  public let vehiclesDB: array<ref<VehicleProperties>>;

  public func lookupVehicleKey(_key: String) -> ref<VehicleProperties> {
    LogChannel(n"DEBUG", ">>> ClaimVehicleDB: lookupVehicleKey()...");

    let undefinedvehicle: ref<VehicleProperties>; 

    for thisVehicle in this.vehiclesDB { 
      if (Equals(thisVehicle.key, _key)) {
    	LogChannel(n"DEBUG", ">>> ClaimVehicleDB: entry found!"); 

        return thisVehicle;
      } 

      if (Equals(thisVehicle.key, "undefined")) {
        undefinedvehicle = thisVehicle;
      }
    };

    LogChannel(n"DEBUG", ">>> ClaimVehicleDB: entry not found (slot empty / unregistered item)"); 
    return undefinedvehicle;
  }

  public func init() -> Void {
    	ArrayPush(this.vehiclesDB, VehicleProperties.CreateItem("undefined", "", ""));

    // ======================================================================================================================================
    // 																TRANSLATIONS START HERE 
    // Only translate the first two model names.
    // Do not edit the Vehicle code

  	// Cars - Hypercars    
      // Herrera - Outlaw GTS
    	ArrayPush(this.vehiclesDB, VehicleProperties.CreateItem(	"outlaw gts", "Outlaw GTS", "Vehicle.v_sport1_herrera_outlaw_player"));

      // Rayfield - Aerondight
    	ArrayPush(this.vehiclesDB, VehicleProperties.CreateItem(	"aerondight \"guinevere\"", "Aerondight \"Guinevere\"", "Vehicle.v_sport1_rayfield_aerondight_player"));

      // Rayfield - Caliburn
      // v_sport1_rayfield_caliburn_player is the default model
      // v_sport1_rayfield_caliburn_02_player is the Black model (free in a tunnel in the badlands)
    	ArrayPush(this.vehiclesDB, VehicleProperties.CreateItem(	"caliburn", "Caliburn", "Vehicle.v_sport1_rayfield_caliburn_player"));

    //																TRANSLATIONS END HERE 
    // ======================================================================================================================================

  }

} 
 