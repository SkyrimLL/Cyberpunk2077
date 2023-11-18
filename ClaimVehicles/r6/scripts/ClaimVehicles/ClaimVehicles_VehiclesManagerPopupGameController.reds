
// Note: Yes.. this should go in the VehicleComponent file.
// I put it here for now.. it may go in the right file if I can't find a solution to the broken menu key.

// public class VehicleComponent extends ScriptableDeviceComponent {
@replaceMethod(VehicleComponent)

  protected cb func OnRemoteControlEvent(evt: ref<VehicleRemoteControlEvent>) -> Bool {
    let playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetVehicle().GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    // set up tracker if it doesn't exist
    if !IsDefined(playerPuppet.m_claimedVehicleTracking) {
      playerPuppet.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      playerPuppet.m_claimedVehicleTracking.init(playerPuppet);
    } else {
      // Reset if already exists (in case of changed default values)
      playerPuppet.m_claimedVehicleTracking.reset(playerPuppet);
    };

    if (playerPuppet.m_claimedVehicleTracking.modON) {
      playerPuppet.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), true);  
    }

    let vehicleQuestEvent: ref<VehicleQuestChangeDoorStateEvent> = new VehicleQuestChangeDoorStateEvent();
    let maxDelayToUnseatPassengers: Float = 5.00;
    if evt.shouldModifyInteractionState {
      if evt.remoteControl {
        vehicleQuestEvent.newState = EQuestVehicleDoorState.DisableAllInteractions;
      } else {
        vehicleQuestEvent.newState = EQuestVehicleDoorState.ResetInteractions;
      };
      GameInstance.GetPersistencySystem(this.GetVehicle().GetGame()).QueuePSEvent(this.GetPS().GetID(), this.GetPS().GetClassName(), vehicleQuestEvent);
    };
    if evt.shouldUnseatPassengers {
      this.GetVehicle().TriggerExitBehavior(maxDelayToUnseatPassengers);
    };
    if !evt.remoteControl {
      this.GetPS().EndStimsOnVehicleQuickhack();
    };
    this.PushVehicleNPCDataToAllPassengers(this.GetVehicle().GetGame(), this.GetVehicle().GetEntityID());
  }

@replaceMethod(VehicleComponent)

  protected cb func OnForceBrakesQuickhackEvent(evt: ref<VehicleForceBrakesQuickhackEvent>) -> Bool {
    let playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetVehicle().GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    // set up tracker if it doesn't exist
    if !IsDefined(playerPuppet.m_claimedVehicleTracking) {
      playerPuppet.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      playerPuppet.m_claimedVehicleTracking.init(playerPuppet);
    } else {
      // Reset if already exists (in case of changed default values)
      playerPuppet.m_claimedVehicleTracking.reset(playerPuppet);
    };

    // TO DO: Add method to remove a vehicle from Manager List
    if (playerPuppet.m_claimedVehicleTracking.modON) {
      playerPuppet.m_claimedVehicleTracking.tryClaimVehicle(this.GetVehicle(), false);  
    }

    if evt.active {
      this.SetDelayDisableCarAlarm(evt.alarmDuration);
    };
    this.PushVehicleNPCDataToAllPassengers(this.GetVehicle().GetGame(), this.GetVehicle().GetEntityID());
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

 
