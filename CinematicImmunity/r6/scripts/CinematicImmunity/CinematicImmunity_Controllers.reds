@wrapMethod(VehicleComponent)
protected cb func OnVehicleRaceQuestEvent(evt: ref<VehicleRaceQuestEvent>) -> Bool {
  let questSys: ref<QuestsSystem> = GameInstance.GetQuestsSystem(this.GetVehicle().GetGame());

  // Set your custom facts based on race state
  switch evt.mode {
    case vehicleRaceUI.RaceStart:
      questSys.SetFact(n"custom_race_started", 1);
      break;
    case vehicleRaceUI.RaceEnd:
      questSys.SetFact(n"custom_race_started", 0);
      break;
  };
  
  // Call original method
  wrappedMethod(evt);
  
}