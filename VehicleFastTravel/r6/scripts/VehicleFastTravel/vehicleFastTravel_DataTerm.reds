// public class DataTerm extends InteractiveDevice { 
@replaceMethod(DataTerm)
  private final func RequestFastTravelMenu() -> Void {
    let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();
    _playerPuppetPS.m_vehicleFasTravelTracking.refreshConfig();
    if Equals(this.GetFastravelDeviceType(), EFastTravelDeviceType.SubwayGate) && (!_playerPuppetPS.m_vehicleFasTravelTracking.modON) {
      this.UpdateFastTravelPointRecord();
      GameInstance.GetUISystem(this.GetGame()).RequestFastTravelMenu();
    } else {
      this.RequestVehicleMenu();
    }
 
  }
@addMethod(DataTerm)
  private final func RequestVehicleMenu() -> Void {
    let player: ref<GameObject> = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject();
    let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();
    _playerPuppetPS.m_vehicleFasTravelTracking.refreshConfig();
    // trying with events system 
    if (_playerPuppetPS.m_vehicleFasTravelTracking.iVehicleMenuOpen) {
        // necessary to prevent vehicle menu to open again when player confirms a vehicle (with same hotkey as key to open menu)
        _playerPuppetPS.m_vehicleFasTravelTracking.iVehicleMenuOpen = false;
      } else {
        _playerPuppetPS.m_vehicleFasTravelTracking.iVehicleMenuOpen = true;
        let evt: ref<TriggeredVehicleManagerEvent> = new TriggeredVehicleManagerEvent();
        evt.dPadItemDirection = EDPadSlot.VehicleWheel;
        player.QueueEvent(evt);
     
      }
  }
@replaceMethod(DataTerm)
  protected cb func OnAreaEnter(evt: ref<AreaEnteredEvent>) -> Bool {
    let activator: ref<GameObject>;
    let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();
    _playerPuppetPS.m_vehicleFasTravelTracking.refreshConfig();
    if Equals(evt.componentName, n"fastTravelArea") {
      // Catch data terminal entity ID for correct malware source attribution
      _playerPuppetPS.m_vehicleFasTravelTracking.terminalEntityID = this.GetEntityID();
      if (!_playerPuppetPS.m_vehicleFasTravelTracking.modON) {
          if NotEquals(this.GetDevicePS().GetFastravelTriggerType(), EFastTravelTriggerType.Auto) {
            return false;
          };
          if this.m_linkedFastTravelPoint == null || IsDefined(this.m_linkedFastTravelPoint) && !this.m_linkedFastTravelPoint.IsValid() {
            return false;
          };
          if this.GetFastTravelSystem().IsFastTravelEnabledOnMap() {
            return false;
          };
          activator = EntityGameInterface.GetEntity(evt.activator) as GameObject;
          if activator.IsPlayer() { 
            this.RequestFastTravelMenu();
            this.TeleportToExitNode(activator);
          };
      }  
      return false;        
 
 
    } else {
      if Equals(evt.componentName, n"SubwayGateArea") && Equals(this.GetFastravelDeviceType(), EFastTravelDeviceType.SubwayGate) {
        activator = EntityGameInterface.GetEntity(evt.activator) as GameObject;
        if (activator as ScriptedPuppet).IsCrowd() {
          this.ProcessSubwayGateNPCPresence(true);
        } else {
          if activator.IsPlayer() && Equals(this.GetDeviceState(), EDeviceStatus.ON) {
            if this.m_linkedFastTravelPoint == null || IsDefined(this.m_linkedFastTravelPoint) && !this.m_linkedFastTravelPoint.IsValid() {
              return false;
            };
            if this.GetFastTravelSystem().IsFastTravelEnabledOnMap() {
              return false;
            };
            SetFactValue(this.GetGame(), n"ue_metro_display_options", 1);
            this.SendThisSubwayGateToFastTravelSystem();
            this.PrepareMetroAnimEntityPosition();
          };
        };
      };
    };
  }