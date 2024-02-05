
// public class PlayerPuppet extends ScriptedPuppet {
@addField(PlayerPuppetPS)
public let m_vehicleFasTravelTracking: ref<VehicleFastTravelTracking>;

@addMethod(PlayerPuppetPS)
  private final func InitVehicleFasTravelSystem(playerPuppet: ref<GameObject>) -> Void {
    // set up tracker if it doesn't exist
    if !IsDefined(this.m_vehicleFasTravelTracking) {
      // LogChannel(n"DEBUG", "::::: INIT NEW VEHICLE FAST TRAVEL OBJECT ");
      this.m_vehicleFasTravelTracking = new VehicleFastTravelTracking();
      this.m_vehicleFasTravelTracking.init(playerPuppet as PlayerPuppet);

    } else {
      // Reset if already exists (in case of changed default values)
      // LogChannel(n"DEBUG", "::::: RESET EXISTING VEHICLE FAST TRAVEL OBJECT ");
      this.m_vehicleFasTravelTracking.reset(playerPuppet as PlayerPuppet);
    };
  }

// Bridge between PlayerPuppet and PlayerPuppetPS - Set up Player Puppet Persistent State when game loads (player is attached)
@wrapMethod(PlayerPuppet)
  private final func PlayerAttachedCallback(playerPuppet: ref<GameObject>) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();

    _playerPuppetPS.InitVehicleFasTravelSystem(playerPuppet);

    wrappedMethod(playerPuppet);
}

@replaceMethod(PlayerPuppet)

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();

    if Equals(ListenerAction.GetName(action), n"ToggleWalk") && ListenerAction.IsButtonJustReleased(action) {
      this.ProcessToggleWalkInput();
      return true;
    };
    if Equals(ListenerAction.GetName(action), n"IconicCyberware") {
      if this.HasCWMask() && NotEquals(this.m_vehicleState, gamePSMVehicle.Default) {
        if Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_RELEASED) && this.m_CWMaskInVehicleInputHeld {
          this.m_CWMaskInVehicleInputHeld = false;
          this.ActivateIconicCyberware();
        } else {
          if Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_HOLD_COMPLETE) {
            this.m_CWMaskInVehicleInputHeld = false;
            this.ExecuteCWMask();
          } else {
            if Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_PRESSED) {
              this.m_CWMaskInVehicleInputHeld = true;
            };
          };
        };
      } else {
        if Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_PRESSED) {
          this.ActivateIconicCyberware();
        };
      };
    } else {
      /* Patch - Disable call vehicle key -> replaced by fast travel action     */
      if Equals(ListenerAction.GetName(action), n"CallVehicle") {
          _playerPuppetPS.m_vehicleFasTravelTracking.refreshConfig();
 
          if (!_playerPuppetPS.m_vehicleFasTravelTracking.modON) {
            if !GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).GetBool(GetAllBlackboardDefs().UI_PlayerStats.isReplacer) && Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_RELEASED) {
              this.ProcessCallVehicleAction(ListenerAction.GetType(action));
            };
            
          } else {
            let isVictorHUDInstalled: Bool = GameInstance.GetQuestsSystem(this.GetGame()).GetFact(n"q001_ripperdoc_done") >= 1;
            let isPhantomLiberyStandalone: Bool = GameInstance.GetQuestsSystem(this.GetGame()).GetFact(n"ep1_standalone") >= 1;

            // LogChannel(n"DEBUG", ">>> enableVehicleRecallKeyON: " + _playerPuppetPS.m_vehicleFasTravelTracking.enableVehicleRecallKeyON  );
            // LogChannel(n"DEBUG", ">>>     isVictorHUDInstalled: " + isVictorHUDInstalled  );
            // LogChannel(n"DEBUG", ">>>     isPhantomLiberyStandalone: " + isPhantomLiberyStandalone  );

            if  ((isVictorHUDInstalled) || (isPhantomLiberyStandalone)) && (!_playerPuppetPS.m_vehicleFasTravelTracking.enableVehicleRecallKeyON) {
              // If Victor HUD installed or DLC standalone is ON, or key menu override is OFF, do Nothing
            } else {
              if !GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).GetBool(GetAllBlackboardDefs().UI_PlayerStats.isReplacer) && Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_RELEASED) {
                this.ProcessCallVehicleAction(ListenerAction.GetType(action));
              };
            };             
          }

      } else {
        if Equals(ListenerAction.GetName(action), n"SceneFastForward") {
          if this.m_customFastForwardPossible {
            if Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_PRESSED) {
              GameInstance.GetTimeSystem(this.GetGame()).SetTimeDilation(n"customFFTimeDilation", 10.00);
              GameObjectEffectHelper.StartEffectEvent(this, n"transition_glitch_loop", false);
              GameInstance.GetAudioSystem(this.GetGame()).Play(n"motion_light_fast_2d");
            } else {
              if Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_RELEASED) && !DefaultTransition.IsFastForwardByLine(this) {
                GameInstance.GetTimeSystem(this.GetGame()).UnsetTimeDilation(n"customFFTimeDilation");
                GameObjectEffectHelper.StopEffectEvent(this, n"transition_glitch_loop");
              };
            };
          };
        } else {
          if Equals(ListenerAction.GetName(action), n"PocketRadio") {
            this.m_pocketRadio.HandleInputAction(action);
          };
        };
      };
    };
  }