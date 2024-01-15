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
        this.m_vehicleFasTravelTracking.refreshConfig();

        if (!this.m_vehicleFasTravelTracking.modON) {
          this.SpawnVehiclesManagerPopup();

        } else {
          // LogChannel(n"DEBUG", ">>> vehicleFasTravel : enableVehicleMenuKeyON: " + this.m_vehicleFasTravelTracking.enableVehicleMenuKeyON  );
          // LogChannel(n"DEBUG", ">>>     isVictorHUDInstalled: " + isVictorHUDInstalled  );
          // LogChannel(n"DEBUG", ">>>     isPhantomLiberyStandalone: " + isPhantomLiberyStandalone  );

          if ( ((isVictorHUDInstalled) || (isPhantomLiberyStandalone)) && (!this.m_vehicleFasTravelTracking.enableVehicleMenuKeyON) ) {
              // If Victor HUD installed or DLC standalone is ON, or key menu override is OFF, do Nothing
              this.SpawnVehicleRadioPopup();
              // m_player.SetWarningMessage("Hailing network out of range. Please use your nearest transport terminal.");  
          } else {
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
    this.m_vehicleFasTravelTracking.refreshConfig();

    if (!this.MalwareAttack()) {
      this.SpawnVehiclesManagerPopup();
    } else {
      // Reset 'data term open' flag to allow activation again
      this.m_vehicleFasTravelTracking.iVehicleMenuOpen = false;      
    }
  }


@addMethod(PopupsManager)

  // https://www.youtube.com/watch?v=wxwdft_O45w&ab_channel=GameTrusTv

  public func MalwareAttack() -> Bool {
    let evt: ref<HackTargetEvent>;
    let hackingMinigameBB: ref<IBlackboard>; 
    let player: wref<PlayerPuppet>; 
    let ownerPuppet: wref<ScriptedPuppet>;

    let chanceHack: Int32 = RandRange(1,100);
    let randomMalwareType: Int32 = RandRange(1,100);
    let malwareType: TweakDBID = t"TrackedVirus"; 
    let chanceMalwareLow: Int32 = Cast<Int32>(this.m_vehicleFasTravelTracking.chanceMalwareLow);
    let chanceMalwareMedium: Int32 = Cast<Int32>(this.m_vehicleFasTravelTracking.chanceMalwareMedium);
    let chanceMalwareHigh: Int32 = Cast<Int32>(this.m_vehicleFasTravelTracking.chanceMalwareHigh);

    // Master switch for malware system
    if (!this.m_vehicleFasTravelTracking.malwareON) { 
      return false;
    }

    // Reset 'data term open' flag to allow activation again
    this.m_vehicleFasTravelTracking.iVehicleMenuOpen = false;

    // player = GameInstance.FindEntityByID(ownerPuppet.GetGame(), playerID) as PlayerPuppet;
    player = this.m_vehicleFasTravelTracking.player;

    if (RandRange(1,100) < chanceMalwareLow) {
      if (randomMalwareType < 100) {
        malwareType = t"AIQuickHack.HackBlind";
      }      
      if (randomMalwareType < 80) {
        malwareType = t"AIQuickHack.HackBurning";
      }      
      if (randomMalwareType < 70) {
        malwareType = t"AIQuickHack.HackCyberware";
      }      
      if (randomMalwareType < 60) {
        malwareType = t"AIQuickHack.HackLocomotion";
      }      
      if (randomMalwareType < 50) {
        malwareType = t"AIQuickHack.HackOverheat";
      }      
      if (randomMalwareType < 40) {
        malwareType = t"AIQuickHack.HackOverload";
      }      
      if (randomMalwareType < 30) {
        malwareType = t"AIQuickHack.HackWeaponJam";
      }      
      if (randomMalwareType < 20) {
        malwareType = t"AIQuickHack.HackWeaponMalfunction";
      }      
    }

    if (RandRange(1,100) < chanceMalwareMedium) {
      if (randomMalwareType < 100) {
        malwareType = t"AIQuickHack.HackBlind_Hard";
      }     
      if (randomMalwareType < 80) {
        malwareType = t"AIQuickHack.HackCyberware_Hard";
      }      
      if (randomMalwareType < 60) {
        malwareType = t"AIQuickHack.HackOverheat_Hard";
      }      
      if (randomMalwareType < 40) {
        malwareType = t"AIQuickHack.HackOverload_Hard";
      }     
      if (randomMalwareType < 20) {
        malwareType = t"AIQuickHack.HackWeaponMalfunction_Hard";
      }      
    }

    if (RandRange(1,100) < chanceMalwareHigh) {
      if (randomMalwareType < 100) {
        malwareType = t"AIQuickHack.HackBlind_VeryHard";
      }      
      if (randomMalwareType < 80) {
        malwareType = t"AIQuickHack.HackCyberware_VeryHard";
      }      
      if (randomMalwareType < 60) {
        malwareType = t"AIQuickHack.HackOverheat_VeryHard";
      }      
      if (randomMalwareType < 40) {
        malwareType = t"AIQuickHack.HackOverload_VeryHard";
      }      
      if (randomMalwareType < 20) {
        malwareType = t"AIQuickHack.HackWeaponMalfunction_VeryHard";
      }      
    }
 
    if !(malwareType == t"TrackedVirus") {
      // LogChannel(n"DEBUG",">>>>>> MalwareAttack: malwareType :" + TDBID.ToStringDEBUG(malwareType));

      evt = new HackTargetEvent();
      evt.targetID = player.GetEntityID();
      evt.netrunnerID = player.GetEntityID();
      evt.objectRecord = TweakDBInterface.GetObjectActionRecord(malwareType);
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
    }

    return false;
  }

/*

HackBlind
HackBlind_Hard
HackBlind_VeryHard
HackBurning
HackCyberware
HackCyberware_Hard
HackCyberware_VeryHard
HackLocomotion
HackOverheat
HackOverheat_Hard
HackOverheat_VeryHard
HackOverload
HackOverload_Hard
HackOverload_VeryHard
HackWeaponJam
HackWeaponJam_VeryHard
HackWeaponMalfunction
HackWeaponMalfunction_Hard
HackWeaponMalfunction_VeryHard
TrackedVirus


  private final func SpawnVehiclesManagerPopup() -> Void {
    let data: ref<inkGameNotificationData> = new inkGameNotificationData();
    data.notificationName = n"base\\gameplay\\gui\\widgets\\vehicle_control\\vehicles_manager.inkwidget";
    data.queueName = n"VehiclesManager";
    data.isBlocking = false;
    this.m_vehiclesManagerToken = this.ShowGameNotification(data);
    this.m_vehiclesManagerToken.RegisterListener(this, n"OnVehiclesManagerCloseRequest");
  }
  */
