
// Note: Using this file to test experimental features


// public native class DynamicSpawnSystem extends IDynamicSpawnSystem {
@replaceMethod(DynamicSpawnSystem)

  protected final func SpawnCallback(spawnedObject: ref<GameObject>) -> Void {
    let aiCommandEvent: ref<AICommandEvent>;
    let aiVehicleChaseCommand: ref<AIVehicleChaseCommand>;
    let wheeledObject: ref<WheeledObject>;
    let player: ref<GameObject> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject();
    if !IsDefined(spawnedObject) {
      return;
    };
    if spawnedObject.IsPuppet() {
      this.ChangeAttitude(spawnedObject, player, EAIAttitude.AIA_Hostile);
    } else {
      if spawnedObject.IsVehicle() {
        aiVehicleChaseCommand = new AIVehicleChaseCommand();
        aiVehicleChaseCommand.target = player;

        // DBF - change spawn distance
        aiVehicleChaseCommand.distanceMin = TweakDBInterface.GetFloat(t"DynamicSpawnSystem.dynamic_vehicles_chase_setup.distanceMin", 3.00);
        aiVehicleChaseCommand.distanceMax = TweakDBInterface.GetFloat(t"DynamicSpawnSystem.dynamic_vehicles_chase_setup.distanceMax", 5.00);
        aiVehicleChaseCommand.forcedStartSpeed = 10.00;
        aiVehicleChaseCommand.ignoreChaseVehiclesLimit = true;
        aiVehicleChaseCommand.boostDrivingStats = true;
        aiCommandEvent = new AICommandEvent();
        aiCommandEvent.command = aiVehicleChaseCommand;
        wheeledObject = spawnedObject as WheeledObject;
        wheeledObject.SetPoliceStrategyDestination(player.GetWorldPosition());
        wheeledObject.QueueEvent(aiCommandEvent);
        wheeledObject.GetAIComponent().SetInitCmd(aiVehicleChaseCommand);
      };
    };
  }

@wrapMethod(VehiclesManagerPopupGameController)

  protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool {

    let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(playerPuppet.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();

    _playerPuppetPS.m_claimedVehicleTracking.refreshConfig(); 

    _playerPuppetPS.m_claimedVehicleTracking.refreshGarage();

    wrappedMethod(playerPuppet);
}

//public class scannerDetailsGameController extends inkHUDGameController {
@replaceMethod(scannerDetailsGameController)
  private final const func ShouldDisplayTwintoneTab() -> Bool {
    let i: Int32;
    let playerVehicles: array<TweakDBID>;
    if !IsDefined(this.m_player) || Cast<Bool>(GetFact(this.m_player.GetGame(), n"twintone_scan_disabled")) || Cast<Bool>(GetFact(this.m_player.GetGame(), this.GetPlayAsJohnnyFactName())) {
      return false;
    };
    if NotEquals(this.m_scannedObjectType, ScannerObjectType.VEHICLE) || !IsDefined(this.m_scannedObject as VehicleObject) {
      return false;
    };

    // DBF - disable check for unlockable vehicles since Claim Vehicles tries to make all vehicles unlockable ahead of time
    
    // playerVehicles = TDB.GetForeignKeyArray(t"Vehicle.vehicle_list.list");
    // i = 0;
    // while i < ArraySize(playerVehicles) {
    //   if (this.m_scannedObject as VehicleObject).GetRecord().GetRecordID() == playerVehicles[i] {
    //     return false;
    //   };
    //   i += 1;
    // };
    return true;
  }

/*
@addMethod(VehiclesManagerPopupGameController)

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    if Equals(ListenerAction.GetName(action), n"popup_moveLeft") && Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_PRESSED) {
        let selectedItem: wref<VehiclesManagerListItemController> = super.m_listController.GetSelectedItem() as VehiclesManagerListItemController;
        let selectedVehicleData: ref<VehicleListItemData> = selectedItem.GetVehicleData();

        this.m_quickSlotsManager.NCLAIMRemoveVehicle(selectedVehicleData.m_data, GetLocalizedItemNameByCName(selectedVehicleData.m_displayName));
    };
  }

@wrapMethod(VehiclesManagerPopupGameController)
  
  protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool
  {
      wrappedMethod(playerPuppet);

      let playerControlledObject = this.GetPlayerControlledObject();
      playerControlledObject.RegisterInputListener(this, n"popup_moveLeft");
  }
*/

/*
  
  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    let actionType: gameinputActionType = ListenerAction.GetType(action);
    let actionName: CName = ListenerAction.GetName(action);
    if Equals(actionType, gameinputActionType.REPEAT) {
      switch actionName {
        case n"popup_moveUp":
          super.ScrollPrior();
          break;
        case n"popup_moveDown":
          super.ScrollNext();
      };
    } else {
      if Equals(actionType, gameinputActionType.BUTTON_PRESSED) {
        switch actionName {
          case n"proceed":
            this.Activate();
            break;
          case n"popup_moveUp":
            super.ScrollPrior();
            break;
          case n"popup_moveDown":
            super.ScrollNext();
            break;
          case n"popup_moveLeft":
            let selectedItem: wref<VehiclesManagerListItemController> = super.m_listController.GetSelectedItem() as VehiclesManagerListItemController;
            let selectedVehicleData: ref<VehicleListItemData> = selectedItem.GetVehicleData();

            this.m_quickSlotsManager.NCLAIMRemoveVehicle(selectedVehicleData.m_data, GetLocalizedItemNameByCName(selectedVehicleData.m_displayName));
            super.Close();
            break;
          case n"OpenPauseMenu":
            ListenerActionConsumer.DontSendReleaseEvent(consumer);
            super.Close();
            break;
          case n"cancel":
            super.Close();
        };
      } else {
        if Equals(actionType, gameinputActionType.BUTTON_HOLD_COMPLETE) {
          if Equals(actionName, n"left_stick_y_scroll_up") {
            super.ScrollPrior();
          } else {
            if Equals(actionName, n"left_stick_y_scroll_down") {
              super.ScrollNext();
            };
          };
        };
      };
    };
  }
*/
/**/

 
