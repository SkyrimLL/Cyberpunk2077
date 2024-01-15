
// public class PlayerPuppet extends ScriptedPuppet {
@addField(PlayerPuppet)
public let m_vehicleFasTravelTracking: ref<VehicleFastTravelTracking>;

@replaceMethod(PlayerPuppet)

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
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
          // set up tracker if it doesn't exist
          if !IsDefined(this.m_vehicleFasTravelTracking) {
            this.m_vehicleFasTravelTracking = new VehicleFastTravelTracking();
            this.m_vehicleFasTravelTracking.init(this);
            // LogChannel(n"DEBUG", ">>> VehicleFastTravelTracking not found - initializing"  );
          } else {
            // Reset if already exists (in case of changed default values) 
            this.m_vehicleFasTravelTracking.reset(this);
            // LogChannel(n"DEBUG", ">>> VehicleFastTravelTracking found - resetting"  );
          };
 
          if (!this.m_vehicleFasTravelTracking.modON) {
            if !GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).GetBool(GetAllBlackboardDefs().UI_PlayerStats.isReplacer) && Equals(ListenerAction.GetType(action), gameinputActionType.BUTTON_RELEASED) {
              this.ProcessCallVehicleAction(ListenerAction.GetType(action));
            };
            
          } else {
            let isVictorHUDInstalled: Bool = GameInstance.GetQuestsSystem(this.GetGame()).GetFact(n"q001_ripperdoc_done") >= 1;
            let isPhantomLiberyStandalone: Bool = GameInstance.GetQuestsSystem(this.GetGame()).GetFact(n"ep1_standalone") >= 1;

            // LogChannel(n"DEBUG", ">>> enableVehicleRecallKeyON: " + this.m_vehicleFasTravelTracking.enableVehicleRecallKeyON  );
            // LogChannel(n"DEBUG", ">>>     isVictorHUDInstalled: " + isVictorHUDInstalled  );
            // LogChannel(n"DEBUG", ">>>     isPhantomLiberyStandalone: " + isPhantomLiberyStandalone  );

            if  ((isVictorHUDInstalled) || (isPhantomLiberyStandalone)) && (!this.m_vehicleFasTravelTracking.enableVehicleRecallKeyON) {
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