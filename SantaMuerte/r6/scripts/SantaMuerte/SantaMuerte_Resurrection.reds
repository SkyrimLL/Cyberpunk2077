
@wrapMethod(ResurrectEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void 
{
	let owner : ref<PlayerPuppet> = scriptInterface.owner as PlayerPuppet;
    let enableVisibilityEvt : ref<EnablePlayerVisibilityEvent> = new EnablePlayerVisibilityEvent();

    // Skip time and chance of teleport.
    let _playerPuppetPS: ref<PlayerPuppetPS> = owner.GetPS();

    _playerPuppetPS.m_santaMuerteTracking.forceCombatExit();

    // // borrowed from: public class ExplorationEvents extends HighLevelTransition { -> OnEnter()
    // let animFeature: ref<AnimFeature_SceneSystem>;
    // PlayerPuppet.ReevaluateAllBreathingEffects(scriptInterface.owner as PlayerPuppet);
    // this.BlockMovement(scriptInterface, false);
    // this.ResetForceFlags(stateContext);
    // this.ResetForceWalkSpeed(stateContext);
    // this.RemoveAllTierLocomotions(scriptInterface);
    // this.ForceDefaultLocomotion(stateContext, scriptInterface);
    // GameObject.PlaySoundEvent(scriptInterface.owner, n"ST_Health_Status_Hi_Set_State");
    // // this.ClearSceneGameplayOverrides(scriptInterface);
    // let animFeatureOverrides: ref<AnimFeature_SceneGameplayOverrides> = new AnimFeature_SceneGameplayOverrides();
    // scriptInterface.localBlackboard.SetBool(GetAllBlackboardDefs().PlayerStateMachine.SceneAimForced, false);
    // scriptInterface.localBlackboard.SetBool(GetAllBlackboardDefs().PlayerStateMachine.SceneSafeForced, false);
    // animFeatureOverrides.aimForced = false;
    // animFeatureOverrides.safeForced = false;
    // animFeatureOverrides.isAimOutTimeOverridden = false;
    // animFeatureOverrides.aimOutTimeOverride = 0.00;
    // scriptInterface.SetAnimationParameterFeature(n"SceneGameplayOverrides", animFeatureOverrides);
    // //
    // animFeature = new AnimFeature_SceneSystem();
    // animFeature.tier = 0;
    // scriptInterface.SetAnimationParameterFeature(n"Scene", animFeature);
    // this.SetBlackboardIntVariable(scriptInterface, GetAllBlackboardDefs().PlayerStateMachine.HighLevel, 1);
    // this.SetBlackboardIntVariable(scriptInterface, GetAllBlackboardDefs().PlayerStateMachine.Vitals, 0);
    // this.SetPlayerVitalsAnimFeatureData(stateContext, scriptInterface, 0, 0.00);
    // this.SetPlayerDeathAnimFeatureData(stateContext, scriptInterface, 0);
    // scriptInterface.GetAudioSystem().Play(n"global_death_exit");          
    // //

    // // Borrowed from public abstract class LocomotionGroundEvents extends LocomotionEventsTransition {
    // stateContext.SetPermanentFloatParameter(n"DeathLandingHeight", 0.0, false);
    // stateContext.SetPermanentBoolParameter(n"groundedGroundSlam", false, false);

    // this.StopEffect(scriptInterface, n"landing_death");

    // let animFeature: ref<AnimFeature_PlayerLocomotionStateMachine>;
    // super.OnEnter(stateContext, scriptInterface);
    // stateContext.RemovePermanentBoolParameter(n"enteredFallFromAirDodge");
    // stateContext.SetPermanentIntParameter(n"currentNumberOfJumps", 0, true);
    // stateContext.SetPermanentIntParameter(n"currentNumberOfAirDodges", 0, true);
    // this.SetAudioParameter(n"RTPC_Vertical_Velocity", 0.00, scriptInterface);
    // animFeature = new AnimFeature_PlayerLocomotionStateMachine();
    // animFeature.inAirState = false;
    // scriptInterface.SetAnimationParameterFeature(n"LocomotionStateMachine", animFeature);
    // this.SetBlackboardIntVariable(scriptInterface, GetAllBlackboardDefs().PlayerStateMachine.Fall, 0);
    // scriptInterface.GetAudioSystem().NotifyGameTone(n"EnterOnGround");
    // this.StopEffect(scriptInterface, n"falling");
    // stateContext.SetConditionBoolParameter(n"JumpPressed", false, true);
    // stateContext.SetPermanentBoolParameter(n"disableAirDash", false, true);
    // stateContext.SetPermanentBoolParameter(n"isGravityAffectedByChargedJump", false, true);

    //
    _playerPuppetPS.m_santaMuerteTracking.applyJohnnySickness();

    // _playerPuppetPS.m_santaMuerteTracking.forceCameraReset();

	  wrappedMethod( stateContext, scriptInterface );
    GameInstance.GetDelaySystem( owner.GetGame() ).DelayEvent( owner, enableVisibilityEvt, 0.1 );
}



@replaceMethod(HighLevelTransition)
  protected final func SetIsResurrectionAllowedBasedOnState(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
    let locomotionState: gamePSMDetailedLocomotionStates;
    let wasPlayerForceKilled: Bool;
    let _playerPuppet: ref<PlayerPuppet> = DefaultTransition.GetPlayerPuppet(scriptInterface) as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();
    let factPermadeathValue = GameInstance.GetQuestsSystem(_playerPuppet.GetGame()).GetFactStr("PermadeathTriggered");
    let doResurrect: Bool = false;
    let ses: ref<StatusEffectSystem>;
    ses = GameInstance.GetStatusEffectSystem(_playerPuppet.GetGame());

    _playerPuppetPS.m_santaMuerteTracking.refreshConfig();

    if (_playerPuppetPS.m_santaMuerteTracking.modON) || ( (scriptInterface.GetStatsSystem().GetStatValue(Cast<StatsObjectID>(scriptInterface.ownerEntityID), gamedataStatType.ForcePreventResurrect) == 0.00) && this.HasSecondHeart(scriptInterface)) {
      // if this.HasSecondHeart(scriptInterface) {
        locomotionState = IntEnum<gamePSMDetailedLocomotionStates>(scriptInterface.localBlackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.LocomotionDetailed));
        wasPlayerForceKilled = StatusEffectSystem.ObjectHasStatusEffect(scriptInterface.owner, t"BaseStatusEffect.ForceKill");

        if (_playerPuppetPS.m_santaMuerteTracking.modON) {
          // Resurrect is mod is ON and max resurrections is not reached
          if (_playerPuppetPS.m_santaMuerteTracking.isRelicInstalled()) && (!_playerPuppetPS.m_santaMuerteTracking.maxResurrectionReached(this.HasSecondHeart(scriptInterface))) {
            doResurrect = true;
          }      

          // Resurrect if mod is ON and death landing is detected and allowed
          if (Equals(locomotionState, gamePSMDetailedLocomotionStates.DeathLand)) {
            if (_playerPuppetPS.m_santaMuerteTracking.deathLandingProtectionON) {
              doResurrect = true;
            } else {
              doResurrect = false;
            }            
          }
          // Do NOT resurrect if player is impersonating Johnny and safety check if ON in the menu
          if (_playerPuppetPS.m_santaMuerteTracking.deathWhenImpersonatingJohnnyON) && (_playerPuppetPS.m_santaMuerteTracking.isPlayerImpersonatingJohnny()) {
            doResurrect = false;
          }       

          // Do NOT Resurrect is mod is ON and max resurrections is reached
          if (_playerPuppetPS.m_santaMuerteTracking.isRelicInstalled()) && (_playerPuppetPS.m_santaMuerteTracking.maxResurrectionReached(false)) {
            doResurrect = false;
          }  
        } else {
          // Resurrect if mod is OFF and Second Heart is installed
          if ( (scriptInterface.GetStatsSystem().GetStatValue(Cast<StatsObjectID>(scriptInterface.ownerEntityID), gamedataStatType.ForcePreventResurrect) == 0.00) && this.HasSecondHeart(scriptInterface)) {
            doResurrect = true;
          }

          // Resurrection if mod is OFF and death landing is detected  
          if (NotEquals(locomotionState, gamePSMDetailedLocomotionStates.DeathLand))  {
            doResurrect = true;
          }          
        }

        // No resurrection if player is forced killed by game/quest event
        if (wasPlayerForceKilled)  {
          doResurrect = false;
        }

        // No resurrection if player is in a vehicle
        if (IsDefined(_playerPuppetPS.m_santaMuerteTracking.player.m_mountedVehicle))  {
          doResurrect = false;
        }

        // Certainly no resurrection if Permadeath is set
        if (factPermadeathValue >= 1) {
          doResurrect = false;
        }
      	
        if (doResurrect) {

          _playerPuppetPS.m_santaMuerteTracking.updateResurrections(this.HasSecondHeart(scriptInterface));

          _playerPuppetPS.m_santaMuerteTracking.player.SetSlowMo(1.0,20.0);

          _playerPuppetPS.m_santaMuerteTracking.player.GetPreventionSystem().HeatPipelineCooldown("CrimeWitness");

          stateContext.SetPermanentBoolParameter(n"isResurrectionAllowed", true, true);
          return;
        
        } else {
          // Final death detected
          _playerPuppetPS.m_santaMuerteTracking.markGameForPermaDeath();

        };      		
      	

      // };
    };
    stateContext.SetPermanentBoolParameter(n"isResurrectionAllowed", false, true);
    if !this.IsDeathMenuBlocked(scriptInterface) {
      this.SetBlackboardBoolVariable(scriptInterface, GetAllBlackboardDefs().PlayerStateMachine.DisplayDeathMenu, true);
    };
    scriptInterface.GetStatPoolsSystem().RequestSettingStatPoolValueIgnoreChangeMode(Cast<StatsObjectID>(scriptInterface.ownerEntityID), gamedataStatPoolType.Health, 0.00, null);
  }

// public class PreventionSystem extends ScriptableSystem {
@addMethod(PreventionSystem)
  private final func HeatPipelineCooldown(heatChangeReason: String) -> Void {
    if (EnumInt(this.m_heatStage)>0) {
      let heatStageToSet: EPreventionHeatStage = IntToEPreventionHeatStage(EnumInt(this.m_heatStage) - 1);
      this.ChangeHeatStage(heatStageToSet, heatChangeReason);
    }
  }