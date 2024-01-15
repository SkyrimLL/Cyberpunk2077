// public native class PopupsManager extends inkGameController {
@addField(PopupsManager)
public let m_vehicleFasTravelTracking: ref<VehicleFastTravelTracking>;

@replaceMethod(PopupsManager)

  protected cb func OnPlayerAttach(playerPuppet: ref<GameObject>) -> Bool {
    this.m_blackboard = this.GetUIBlackboard();
    this.m_bbDefinition = GetAllBlackboardDefs().UIGameData;
    this.m_journalManager = GameInstance.GetJournalManager(playerPuppet.GetGame());
    this.m_uiSystemBB = this.GetBlackboardSystem().Get(GetAllBlackboardDefs().UI_System);
    this.m_uiSystemBBDef = GetAllBlackboardDefs().UI_System;
    this.m_uiSystemId = this.m_uiSystemBB.RegisterListenerBool(this.m_uiSystemBBDef.IsInMenu, this, n"OnMenuUpdate");
    this.m_isShownBbId = this.m_blackboard.RegisterDelayedListenerBool(this.m_bbDefinition.Popup_IsShown, this, n"OnUpdateVisibility");
    this.m_dataBbId = this.m_blackboard.RegisterDelayedListenerVariant(this.m_bbDefinition.Popup_Data, this, n"OnUpdateData");
    this.m_photomodeActiveId = this.GetBlackboardSystem().Get(GetAllBlackboardDefs().PhotoMode).RegisterListenerBool(GetAllBlackboardDefs().PhotoMode.IsActive, this, n"OnPhotomodeUpdate");

    // set up tracker if it doesn't exist
    if !IsDefined(this.m_vehicleFasTravelTracking) {
      let m_player: wref<PlayerPuppet> = GetPlayer(playerPuppet.GetGame());
      this.m_vehicleFasTravelTracking = new VehicleFastTravelTracking();
      this.m_vehicleFasTravelTracking.init(m_player);
    } else {
      // Reset if already exists (in case of changed default values)
      let m_player: wref<PlayerPuppet> = GetPlayer(playerPuppet.GetGame()) ;
      this.m_vehicleFasTravelTracking.reset(m_player);
    };
  }

@replaceMethod(PopupsManager)

  protected cb func OnQuickSlotButtonHoldStartEvent(evt: ref<QuickSlotButtonHoldStartEvent>) -> Bool {
    switch evt.dPadItemDirection {
      case EDPadSlot.VehicleWheel:
      /* Patch - disable popup menu on action key hold 
        this.SpawnVehiclesManagerPopup();
        */
        let m_player: wref<PlayerPuppet> = this.m_vehicleFasTravelTracking.player;
        let isVictorHUDInstalled: Bool = GameInstance.GetQuestsSystem(m_player.GetGame()).GetFact(n"q001_ripperdoc_done") >= 1;
        let isPhantomLiberyStandalone: Bool = GameInstance.GetQuestsSystem(m_player.GetGame()).GetFact(n"ep1_standalone") >= 1;

        // LogChannel(n"DEBUG", ">>> vehicleFasTravel : enableVehicleMenuKeyON: " + this.m_vehicleFasTravelTracking.enableVehicleMenuKeyON  );
        // LogChannel(n"DEBUG", ">>>     isVictorHUDInstalled: " + isVictorHUDInstalled  );
        // LogChannel(n"DEBUG", ">>>     isPhantomLiberyStandalone: " + isPhantomLiberyStandalone  );

        if ((isVictorHUDInstalled) || (isPhantomLiberyStandalone)) && (!this.m_vehicleFasTravelTracking.enableVehicleMenuKeyON) {
            // If Victor HUD installed or DLC standalone is ON, or key menu override is OFF, do Nothing
            this.SpawnVehicleRadioPopup();
            // m_player.SetWarningMessage("Hailing network out of range. Please use your nearest transport terminal.");  
        } else {
            if (!this.MalwareAttack()) {
              this.SpawnVehiclesManagerPopup();
            }
            
        }
        
        break;
      case EDPadSlot.VehicleInsideWheel:
        this.SpawnVehicleRadioPopup();
        break;
      case EDPadSlot.PocketRadio:
        this.TrySpawnPocketRadioPopup();
        break;
      default:
    };
  } 

@addMethod(PopupsManager)

  protected cb func OnTriggeredVehicleManagerEvent(evt: ref<TriggeredVehicleManagerEvent>) -> Bool {
    // Event is triggered by custom code on Data Terminals used for Fast Travel

    if (!this.MalwareAttack()) {
      this.SpawnVehiclesManagerPopup();
    }
  }


@addMethod(PopupsManager)

  // https://www.youtube.com/watch?v=wxwdft_O45w&ab_channel=GameTrusTv

  public func MalwareAttack() -> Bool {
    let evt: ref<HackTargetEvent>;
    let hackingMinigameBB: ref<IBlackboard>; 
    let player: wref<PlayerPuppet>; 
    let ownerPuppet: wref<ScriptedPuppet>;

    // Disabled for now
    return false;

    // player = GameInstance.FindEntityByID(ownerPuppet.GetGame(), playerID) as PlayerPuppet;
    player = this.m_vehicleFasTravelTracking.player;

    evt = new HackTargetEvent();
    evt.targetID = player.GetEntityID();
    evt.netrunnerID = player.GetEntityID();
    evt.objectRecord = TweakDBInterface.GetObjectActionRecord(t"AIQuickHack.HackOverheat_Hard");
    evt.settings.showDirectionalIndicator = false;
    evt.settings.isRevealPositionAction = false;
    evt.settings.HUDData.bottomText = "Firmware downloading";
    evt.settings.HUDData.failedText = "Firmware update - FAILED";
    evt.settings.HUDData.completedText = "Firmware update - SUCCESS";
    evt.settings.HUDData.type = SimpleMessageType.Reveal;

    if IsDefined(evt.objectRecord) {
      player.QueueEvent(evt);
      hackingMinigameBB = GameInstance.GetBlackboardSystem(player.GetGame()).Get(GetAllBlackboardDefs().HackingMinigame);
      hackingMinigameBB.SetVector4(GetAllBlackboardDefs().HackingMinigame.LastPlayerHackPosition, player.GetWorldPosition());
      return true;
    };
    return false;
  }

/*

overheatT1 = t"AIQuickHackStatusEffect.HackOverheat";
overheatT2 = t"AIQuickHackStatusEffect.HackOverheatTier2";
overheatT3 = t"AIQuickHackStatusEffect.HackOverheatTier3";
hackMalfunctiontT1 = t"AIQuickHackStatusEffect.HackWeaponMalfunction";
hackMalfunctionT2 = t"AIQuickHackStatusEffect.HackWeaponMalfunctionTier2";
hackMalfunctionT3 = t"AIQuickHackStatusEffect.HackWeaponMalfunctionTier3";
hackLocomotionT1 = t"AIQuickHackStatusEffect.HackLocomotion";
hackLocomotionT2 = t"AIQuickHackStatusEffect.HackLocomotionTier2";
hackLocomotionT3 = t"AIQuickHackStatusEffect.HackLocomotionTier3";


  private final func SpawnVehiclesManagerPopup() -> Void {
    let data: ref<inkGameNotificationData> = new inkGameNotificationData();
    data.notificationName = n"base\\gameplay\\gui\\widgets\\vehicle_control\\vehicles_manager.inkwidget";
    data.queueName = n"VehiclesManager";
    data.isBlocking = false;
    this.m_vehiclesManagerToken = this.ShowGameNotification(data);
    this.m_vehiclesManagerToken.RegisterListener(this, n"OnVehiclesManagerCloseRequest");
  }
  */
