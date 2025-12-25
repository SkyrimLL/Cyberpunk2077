public class VehicleProperties {

  public let vehicleRecordID: TweakDBID; 
  public let vehicleString: String; 

  // public static func createItem(_id: TweakDBID, _string: String) -> ref<VehicleProperties> {
  //   let Item = new VehicleProperties();
  //   Item.vehicleRecordID = _id; 
  //   Item.vehicleString = _string;
  //   return Item;
  // }
}

public class VehicleUnlockState extends ScriptedPuppetPS {

  public persistent let vehicleRecordID: TweakDBID; 
  public persistent let vehicleUnlocked: Bool; 
  public persistent let vehicleFavorite: Bool; 

  public static func createItem(_id: TweakDBID, _state: Bool) -> ref<VehicleUnlockState> {
    let Item = new VehicleUnlockState();
    Item.vehicleRecordID = _id;  
    Item.vehicleUnlocked = _state;
    Item.vehicleFavorite = false;
    return Item;
  }
}

public class ClaimVehicleDB extends ScriptedPuppetPS {

  // public let vehiclesDB: array<ref<VehicleProperties>>;
  public persistent let vehiclesUnlockStateDB: array<ref<VehicleUnlockState>>;

  public func lookupVehicle(_id: TweakDBID) -> ref<VehicleProperties> {
    let ownableVehicleList = TweakDBInterface.GetForeignKeyArray(t"Vehicle.vehicle_list.list"); 
    let vehicleIsOwnable = ArrayFindFirst(ownableVehicleList, _id) != -1;

    this.showDebugMessage(">>> ClaimVehicleDB: lookupVehicle()..." );
    this.showDebugMessage(">>> ClaimVehicleDB: searching for:" + TDBID.ToStringDEBUG(_id));  

    if (vehicleIsOwnable) {
      this.showDebugMessage(">>>>>> ClaimVehicleDB: entry found!");

      let Item = new VehicleProperties();
      Item.vehicleRecordID = _id; 
      Item.vehicleString = TDBID.ToStringDEBUG(_id);
      return Item;

    }  else {
      // this.showDebugMessage(">>> ClaimVehicleDB: entry not found (slot empty / unregistered item)"); 
      let Item = new VehicleProperties();
      Item.vehicleRecordID = t"Vehicle.av_scanning_drone"; 
      Item.vehicleString = "";
      return Item;
    }
 

 
  }

  public func lookupVehicleString(_id: TweakDBID) -> String {
    this.showDebugMessage(">>> ClaimVehicleDB: lookupVehicleString()..." );
    this.showDebugMessage(">>> ClaimVehicleDB: searching for:" + TDBID.ToStringDEBUG(_id));

    let thisVehicle: ref<VehicleProperties> = this.lookupVehicle(_id);

    // if (Equals(thisVehicle.vehicleString, "")) {
    //  LogChannel(n"DEBUG",">>> ClaimVehicleDB: entry not found (slot empty / unregistered item)"); 
    // } else {
    //  LogChannel(n"DEBUG",">>> ClaimVehicleDB: entry found!"); 
    // }
    	  
    return thisVehicle.vehicleString;
 
  };

  public func lookupVehicleUnlockState(_id: TweakDBID) -> Bool { 

    for thisVehicle in this.vehiclesUnlockStateDB { 
      if (Equals(thisVehicle.vehicleRecordID, _id)) { 
        return thisVehicle.vehicleUnlocked;
      }  
    };
 
    return false;
  }

  public func isVehicleUnlockStateDefined(_id: TweakDBID) -> Bool { 

    if (ArraySize(this.vehiclesUnlockStateDB) == 0) {
      return false;
    }

    for thisVehicle in this.vehiclesUnlockStateDB { 
      if (Equals(thisVehicle.vehicleRecordID, _id)) { 

        return true;
      }  
    };
 
    return false;
  }

  public func setVehicleUnlockState(_id: TweakDBID, _state: Bool) { 
    // Add vehicle to unlocked state array if not defined yet
    if (!this.isVehicleUnlockStateDefined(_id)) {
      ArrayPush(this.vehiclesUnlockStateDB, VehicleUnlockState.createItem(_id, _state));
      // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  " + ToString(ArraySize(this.vehiclesUnlockStateDB)) + " in vehicles unlock history.");

    } else {
      for thisVehicle in this.vehiclesUnlockStateDB { 
        if (Equals(thisVehicle.vehicleRecordID, _id)) { 
          thisVehicle.vehicleRecordID = _id;  
          thisVehicle.vehicleUnlocked = _state;
        }  
      };      
    }
  }

  public func setVehicleFavoriteState(_id: TweakDBID, _favorite: Bool) { 
    // Add vehicle to unlocked state array if not defined yet
    if (!this.isVehicleUnlockStateDefined(_id)) {
      // ArrayPush(this.vehiclesUnlockStateDB, VehicleUnlockState.createItem(_id, _state));
      // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  " + ToString(ArraySize(this.vehiclesUnlockStateDB)) + " in vehicles unlock history.");

    } else {
      for thisVehicle in this.vehiclesUnlockStateDB { 
        if (Equals(thisVehicle.vehicleRecordID, _id)) { 
          thisVehicle.vehicleRecordID = _id;  
          thisVehicle.vehicleFavorite = _favorite;
        }  
      };      
    }
  }


  public func init() -> Void { 
  }

  private func showDebugMessage(debugMessage: String) {
    // LogChannel(n"DEBUG", debugMessage ); 
  }
} 

/* 
VehicleObject has a GetRecord() method that returns the TweakDB record for the vehicle, the ID of which will be the TweakDBID of the vehicle, aka the"internal vehicle string"

TweakDBID's are 64-bit hashes that can be written in redscript as a t prefixed string, i.e. t"Vehicle.v_sport1_herrera_outlaw_player"

Awkwardly, the method you're calling takes a string, not a TDBID, so you'll need to convert it with TDBID.ToStringDEBUG(...)
 */
 