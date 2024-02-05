// public class VehiclesManagerDataHelper extends IScriptable {

/* Class override not needed anymore

@replaceMethod(VehiclesManagerDataHelper)

  public final static func GetVehicles(player: ref<GameObject>) -> array<ref<IScriptable>> {
    let owner: ref<PlayerPuppet> = player as PlayerPuppet;
    let currentData: ref<VehicleListItemData>;
    let i: Int32;
    let result: array<ref<IScriptable>>;
    let vehicle: PlayerVehicle;
    let vehicleRecord: ref<Vehicle_Record>;
    let vehiclesList: array<PlayerVehicle>; 
 
    // Original list of player owned vehicles
    // GameInstance.GetVehicleSystem(player.GetGame()).GetPlayerVehicles(vehiclesList);

    // GameInstance.GetVehicleSystem(player.GetGame()).GetPlayerUnlockedVehicles(vehiclesList);
    i = 0;
    while i < ArraySize(vehiclesList) {
      vehicle = vehiclesList[i];
      if (TDBID.IsValid(vehicle.recordID)){
        vehicleRecord = TweakDBInterface.GetVehicleRecord(vehicle.recordID);
        currentData = new VehicleListItemData();
        currentData.m_displayName = vehicleRecord.DisplayName();
        currentData.m_icon = vehicleRecord.Icon();
        currentData.m_data = vehicle;
        ArrayPush(result, currentData);
      };
      i += 1;
    };

      

    return result;
  }


  public final static func GetVehicles(player: ref<GameObject>) -> array<ref<IScriptable>> {
    let currentData: ref<VehicleListItemData>;
    let i: Int32;
    let repairElapsedTime: Float;
    let result: array<ref<IScriptable>>;
    let vehicle: PlayerVehicle;
    let vehicleRecord: ref<Vehicle_Record>;
    let vehiclesList: array<PlayerVehicle>;
    let repairTime: Float = TweakDBInterface.GetFloat(t"Vehicle.summon_setup.repairCooldownMax", 0.00);
    let currentSimTime: EngineTime = GameInstance.GetSimTime(player.GetGame());
    GameInstance.GetVehicleSystem(player.GetGame()).GetPlayerUnlockedVehicles(vehiclesList);
    i = 0;
    while i < ArraySize(vehiclesList) {
      vehicle = vehiclesList[i];
      if TDBID.IsValid(vehicle.recordID) {
        vehicleRecord = TweakDBInterface.GetVehicleRecord(vehicle.recordID);
        currentData = new VehicleListItemData();
        currentData.m_displayName = vehicleRecord.DisplayName();
        currentData.m_icon = vehicleRecord.Icon();
        currentData.m_data = vehicle;
        repairElapsedTime = EngineTime.ToFloat(currentSimTime - vehicle.destructionTimeStamp);
        currentData.m_repairTimeRemaining = repairElapsedTime > repairTime ? 0.00 : repairTime - repairElapsedTime;
        ArrayPush(result, currentData);
      };
      i += 1;
    };
    return result;
  }
*/