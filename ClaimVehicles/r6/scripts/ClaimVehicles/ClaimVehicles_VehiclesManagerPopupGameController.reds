
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

@addMethod(VehiclesManagerPopupGameController)
public func forceRefreshVehicleList() -> Void {
  // m_dataSource.Reset() repopulates the popup's virtual list from a live
  // GetPlayerUnlockedVehicles() query.  Called after wrappedMethod() so that
  // any vehicle registration that settled asynchronously after SetupData() ran
  // inside super.OnPlayerAttach() is captured.
  if IsDefined(this.m_dataSource) {
    this.m_dataSource.Reset(VehiclesManagerDataHelper.GetVehicles(this.m_playerPuppet));
  }
}

@wrapMethod(VehiclesManagerPopupGameController)

  protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool {

    let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(playerPuppet.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();

    _playerPuppetPS.m_claimedVehicleTracking.refreshConfig(); 

    // Re-register all claimed vehicles in the game's vehicle system before
    // wrappedMethod calls SetupData() -> GetPlayerUnlockedVehicles().
    // The game engine can evict NPC-origin vehicles between the claim event
    // and popup open, so they must be re-asserted here to appear in the list.
    if (_playerPuppetPS.m_claimedVehicleTracking.debugON) {
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(">>> OnPlayerAttach: garage state BEFORE reapplyClaimedVehicles:");
      _playerPuppetPS.m_claimedVehicleTracking.printGarage();
    }
    
    _playerPuppetPS.m_claimedVehicleTracking.reapplyClaimedVehicles();
    
    if (_playerPuppetPS.m_claimedVehicleTracking.debugON) {
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(">>> OnPlayerAttach: garage state AFTER reapplyClaimedVehicles:");
      _playerPuppetPS.m_claimedVehicleTracking.printGarage();
    }

    // Apply current summon mode restrictions (Last/Random/etc.) after re-registration.
    // Do this BEFORE wrappedMethod so SetupData() sees the filtered list
    _playerPuppetPS.m_claimedVehicleTracking.refreshGarage();
    
    if (_playerPuppetPS.m_claimedVehicleTracking.debugON) {
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(">>> OnPlayerAttach: garage state AFTER refreshGarage, BEFORE wrappedMethod:");
      _playerPuppetPS.m_claimedVehicleTracking.printGarage();
    }

    // Capture vehicle state BEFORE wrappedMethod for validation
    let _preWrappedVehicles: array<PlayerVehicle>;
    GameInstance.GetVehicleSystem(playerPuppet.GetGame()).GetPlayerUnlockedVehicles(_preWrappedVehicles);
    let _preWrappedCount: Int32 = ArraySize(_preWrappedVehicles);
    let _preWrappedTarget: TweakDBID = _playerPuppetPS.m_claimedVehicleTracking.lastVehicleRecordID;

    wrappedMethod(playerPuppet);

    // VALIDATION: Check if a vehicle was evicted by SetupData()
    // This happens with some NCTO faction vehicles that lack proper player-variant data
    let _postWrappedVehicles: array<PlayerVehicle>;
    GameInstance.GetVehicleSystem(playerPuppet.GetGame()).GetPlayerUnlockedVehicles(_postWrappedVehicles);
    let _postWrappedCount: Int32 = ArraySize(_postWrappedVehicles);
    
    if _postWrappedCount == 0 && _preWrappedCount > 0 {
      // Vehicle was evicted - likely invalid player variant
      if (Equals(_playerPuppetPS.m_claimedVehicleTracking.summonMode, vehicleSummonMode.Random)) {
        _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(">>> ERROR: Vehicle evicted by SetupData during Random mode: " + TDBID.ToStringDEBUG(_preWrappedTarget));
        _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(">>>   This vehicle lacks proper player-variant data and cannot be used in Random mode.");
        _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(">>>   Removing from claimed vehicles DB to prevent future issues.");
        
        // Remove this problematic vehicle from the claimed DB
        _playerPuppetPS.m_claimedVehicleTracking.removeVehicleFromClaimed(_preWrappedTarget);
      }
    }

    // SetupData() (called inside super.OnPlayerAttach inside wrappedMethod) may have
    // snapshotted the vehicle list before TogglePlayerActiveVehicle finished committing
    // to the vehicle system.  Force one more reset now that all initialization has run.
    if (_playerPuppetPS.m_claimedVehicleTracking.debugON) {
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(">>> OnPlayerAttach: garage state BEFORE forceRefreshVehicleList:");
      _playerPuppetPS.m_claimedVehicleTracking.printGarage();
    }
    this.forceRefreshVehicleList();
    
    if (_playerPuppetPS.m_claimedVehicleTracking.debugON) {
      _playerPuppetPS.m_claimedVehicleTracking.showDebugMessage(">>> OnPlayerAttach: FINAL garage state after all processing:");
      _playerPuppetPS.m_claimedVehicleTracking.printGarage();
    }
}

@wrapMethod(VehiclesManagerPopupGameController)
protected func Select(previous: ref<inkVirtualCompoundItemController>, next: ref<inkVirtualCompoundItemController>) -> Void {
  let selectedVehicle: ref<VehiclesManagerListItemController> = next as VehiclesManagerListItemController;
  if IsDefined(selectedVehicle) {
    let selectedVehicleData: ref<VehicleListItemData> = selectedVehicle.GetVehicleData();
    if IsDefined(selectedVehicleData) {
      inkWidgetRef.SetOpacity(this.m_vehicleIconContainer, selectedVehicleData.m_repairTimeRemaining == 0.00 ? 1.00 : 0.08);
      if IsDefined(selectedVehicleData.m_icon) {
        InkImageUtils.RequestSetImage(this, this.m_vehicleIcon, selectedVehicleData.m_icon.GetID());
      }
      inkWidgetRef.SetVisible(this.m_repairOverlay, selectedVehicleData.m_repairTimeRemaining > 0.00);
      inkWidgetRef.SetVisible(this.m_confirmButton, selectedVehicleData.m_repairTimeRemaining == 0.00);
      inkTextRef.SetLocalizedTextScript(this.m_favoriteInputHint, selectedVehicleData.m_data.uiFavoriteIndex >= 0 ? "LocKey#96331" : "LocKey#95061");
      return;
    }
  }
  wrappedMethod(previous, next);
}

@replaceMethod(VehiclesManagerListItemController)
protected cb func OnDataChanged(value: Variant) -> Bool {
  let repairTextParams: ref<inkTextParams>;
  this.m_vehicleData = FromVariant<ref<IScriptable>>(value) as VehicleListItemData;
  if !IsDefined(this.m_vehicleData) {
    return false;
  }
  let vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(this.m_vehicleData.m_data.recordID);
  if this.m_vehicleData.m_data.overrideDisplay {
    inkImageRef.SetTexturePart(this.m_typeIcon, this.m_vehicleData.m_data.icon);
  } else {
    if Equals(this.m_vehicleData.m_data.vehicleType, gamedataVehicleType.Bike) {
      inkImageRef.SetTexturePart(this.m_typeIcon, n"motorcycle");
    } else {
      if IsDefined(vehicleRecord) && IsDefined(vehicleRecord.VehDataPackageHandle()) && IsDefined(vehicleRecord.VehDataPackageHandle().DriverCombat()) && Equals(vehicleRecord.VehDataPackageHandle().DriverCombat().Type(), gamedataDriverCombatType.MountedWeapons) {
        inkImageRef.SetTexturePart(this.m_typeIcon, n"vehicle_weaponized");
      } else {
        inkImageRef.SetTexturePart(this.m_typeIcon, n"car");
      };
    };
  };
  if IsDefined(vehicleRecord) {
    inkWidgetRef.SetVisible(this.m_customizableIcon, vehicleRecord.HasVisualCustomization() && !vehicleRecord.VisualCustomizationTeaser());
  } else {
    inkWidgetRef.SetVisible(this.m_customizableIcon, false);
  };
  inkTextRef.SetLocalizedTextScript(this.m_label, this.m_vehicleData.m_displayName);
  if this.m_vehicleData.m_repairTimeRemaining > 0.00 {
    inkTextRef.SetText(this.m_repairTime, "{TIME,time,mm:ss}");
    repairTextParams = new inkTextParams();
    repairTextParams.AddTime("TIME", GameTime.MakeGameTime(0, 0, 0, Cast<Int32>(this.m_vehicleData.m_repairTimeRemaining)));
    inkTextRef.SetTextParameters(this.m_repairTime, repairTextParams);
    inkWidgetRef.SetVisible(this.m_repairTime, true);
    this.GetRootWidget().SetState(n"Disabled");
  } else {
    inkWidgetRef.SetVisible(this.m_repairTime, false);
    if this.m_vehicleData.m_data.overrideDisplay {
      this.GetRootWidget().SetState(this.m_vehicleData.m_data.activeState);
    } else {
      this.GetRootWidget().SetState(n"Default");
    };
  };
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

 
