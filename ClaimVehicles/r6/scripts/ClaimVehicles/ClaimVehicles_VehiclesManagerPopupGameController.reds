
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

 
