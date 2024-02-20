
@wrapMethod(ResurrectEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void 
{
	let owner : ref<PlayerPuppet> = scriptInterface.owner as PlayerPuppet;
    let enableVisibilityEvt : ref<EnablePlayerVisibilityEvent> = new EnablePlayerVisibilityEvent();

    // Skip time and chance of teleport.
    let _playerPuppetPS: ref<PlayerPuppetPS> = owner.GetPS();

    _playerPuppetPS.m_santaMuerteTracking.forceCombatExit();

    _playerPuppetPS.m_santaMuerteTracking.applyJohnnySickness();

	  wrappedMethod( stateContext, scriptInterface );
    GameInstance.GetDelaySystem( owner.GetGame() ).DelayEvent( owner, enableVisibilityEvt, 0.1 );
}



@replaceMethod(HighLevelTransition)
  protected final func SetIsResurrectionAllowedBasedOnState(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
    let locomotionState: gamePSMDetailedLocomotionStates;
    let wasPlayerForceKilled: Bool;
    let _playerPuppet: ref<PlayerPuppet> = DefaultTransition.GetPlayerPuppet(scriptInterface) as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();
    let doResurrect: Bool = false;

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
          if (!_playerPuppetPS.m_santaMuerteTracking.deathLandingProtectionON) && (Equals(locomotionState, gamePSMDetailedLocomotionStates.DeathLand))  {
            doResurrect = true;
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
      	
        if (doResurrect) {

          _playerPuppetPS.m_santaMuerteTracking.updateResurrections(this.HasSecondHeart(scriptInterface));

          _playerPuppetPS.m_santaMuerteTracking.player.SetSlowMo(1.0,20.0);

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

