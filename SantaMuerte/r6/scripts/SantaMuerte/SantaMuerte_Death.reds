// Interception of Second Heart mechanics

@replaceMethod(DeathDecisions)
protected final const func EnterCondition(const stateContext: ref<StateContext>, const scriptInterface: ref<StateGameScriptInterface>) -> Bool {
  let _playerPuppet: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
  let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();

  if _playerPuppetPS.GetIsDead() {
    return true;
  };
  if scriptInterface.GetStatPoolsSystem().HasStatPoolValueReachedMin(Cast<StatsObjectID>(scriptInterface.ownerEntityID), gamedataStatPoolType.Health) {
    return true;
  };
  if ( (_playerPuppetPS.m_santaMuerteTracking.modON) || this.HasSecondHeart(scriptInterface)) && scriptInterface.GetStatPoolsSystem().IsStatPoolAdded(Cast<StatsObjectID>(scriptInterface.ownerEntityID), gamedataStatPoolType.Health) {
    if GameInstance.GetGodModeSystem(scriptInterface.GetGame()).HasGodMode(scriptInterface.ownerEntityID, gameGodModeType.Invulnerable) {
      return false;
    };
    return scriptInterface.GetStatPoolsSystem().GetStatPoolValue(Cast<StatsObjectID>(scriptInterface.ownerEntityID), gamedataStatPoolType.Health, true) <= 1.10;
  };
  return false;
}

@wrapMethod(DeathEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void
{
	let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(scriptInterface.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();

    _playerPuppetPS.m_santaMuerteTracking.refreshConfig();

    if (_playerPuppetPS.m_santaMuerteTracking.modON) {
    	if (_playerPuppetPS.m_santaMuerteTracking.isRelicInstalled()) {
			// if ( this.HasSecondHeart( scriptInterface ) )
			// {

				let minSkippedTime = _playerPuppetPS.m_santaMuerteTracking.minSkippedTime;
				let maxSkippedTime = _playerPuppetPS.m_santaMuerteTracking.maxSkippedTime;
		    let timeSkipped = RandRangeF(minSkippedTime, maxSkippedTime);
		    _playerPuppetPS.m_santaMuerteTracking.skipTimeWithBlackout(timeSkipped);

				GameInstance.GetTimeSystem( scriptInterface.GetGame() ).UnsetTimeDilation( n"" );
				GameInstance.GetTimeSystem( scriptInterface.GetGame() ).UnsetTimeDilationOnLocalPlayerZero( n"" );

				stateContext.SetTemporaryBoolParameter( n"requestSandevistanDeactivation", true, true );
				stateContext.SetTemporaryBoolParameter( n"requestKerenzikovDeactivation", true, true );		

				GameInstance.GetRazerChromaEffectsSystem( scriptInterface.GetGame() ).StopAnimation( n"SlowMotion" );

				this.StartDeathEffects( stateContext, scriptInterface );
				this.isDyingEffectPlaying = false;
				super.OnEnter ( stateContext, scriptInterface );
				this.ForceDisableToggleWalk( stateContext );
				return;
			// }
			}
    }

	wrappedMethod ( stateContext, scriptInterface );
}

// Tweaks to resurrect effect 
// Source: Second Heart Fix - https://www.nexusmods.com/cyberpunk2077/mods/11100?tab=posts

@wrapMethod(HighLevelTransition)
protected final func EvaluateSettingCustomDeathAnimation(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void 
{
    let _playerPuppet: ref<PlayerPuppet> = DefaultTransition.GetPlayerPuppet(scriptInterface) as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS(); 

    if (_playerPuppetPS.m_santaMuerteTracking.modON) {
	// if ( this.HasSecondHeart( scriptInterface ) )
	// { 
			if (_playerPuppetPS.m_santaMuerteTracking.newDeathAnimationON) {
				if ((_playerPuppetPS.m_santaMuerteTracking.randomDeathAnimationON) && (RandRange(0,100)>=50)) || (!_playerPuppetPS.m_santaMuerteTracking.randomDeathAnimationON) {
		    	this.SetPlayerDeathAnimFeatureData(stateContext, scriptInterface, 1);			
					return;
				}
			}
	// }    	
    }

	wrappedMethod( stateContext, scriptInterface );
}

@replaceMethod(DeathDecisionsWithResurrection)
protected func ToResurrect( stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Bool
{
	if( this.IsResurrectionAllowed( stateContext, scriptInterface ) )
	{
		if( this.GetInStateTime() >= this.GetStaticFloatParameterDefault( "stateDuration", 8.0 ) )
		{
			return true;
		}
	}
	return false;
}
 
@wrapMethod(HighLevelTransition)
protected final func StartDeathEffects(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void
{
	this.DeathVanish( scriptInterface );
	wrappedMethod( stateContext, scriptInterface );
}


@addMethod(HighLevelTransition)
private func DeathVanish( scriptInterface : ref<StateGameScriptInterface> )
{
	let owner : ref<PlayerPuppet> = scriptInterface.owner as PlayerPuppet;
	let exitCombatDelay : Float = TweakDBInterface.GetFloat( t"Items.AdvancedOpticalCamoCommon.exitCombatDelay", 0.5);

	// 2024-12-07 - Testing optical camo effect to shut down combat
	owner.PromoteOpticalCamoEffectorToCompletelyBlocking();

	let enableVisiblityDelay : Float = GameInstance.GetStatsSystem( owner.GetGame() ).GetStatValue( Cast<StatsObjectID>( owner.GetEntityID() ), gamedataStatType.OpticalCamoDuration );
	let hostileTargets : array<TrackedLocation> = owner.GetTargetTrackerComponent().GetHostileThreats( false );
	let hostileTarget : wref<GameObject>;
	let hostileTargetPuppet : wref<ScriptedPuppet>;
  let j : Int32 = 0;
	let vanishEvt : ref<ExitCombatOnOpticalCamoActivatedEvent>;
	let enableVisibilityEvt: ref<EnablePlayerVisibilityEvent>;

	owner.SetInvisible( true );

  while j < ArraySize( hostileTargets )
	{
		hostileTarget = hostileTargets[j].entity as GameObject;
		hostileTargetPuppet = hostileTarget as ScriptedPuppet;
		if IsDefined( hostileTargetPuppet )
		{
			hostileTargetPuppet.GetTargetTrackerComponent().DeactivateThreat( owner );
		}
		vanishEvt = new ExitCombatOnOpticalCamoActivatedEvent();
		vanishEvt.npc = hostileTarget;
		GameInstance.GetDelaySystem( owner.GetGame() ).DelayEvent( owner, vanishEvt, 0.1  );  
		j += 1;
	} 

	// 2024-12-07 - Testing optical camo effect to shut down combat
  enableVisibilityEvt = new EnablePlayerVisibilityEvent();
  GameInstance.GetDelaySystem(owner.GetGame()).DelayEvent(owner, enableVisibilityEvt, enableVisiblityDelay);
}



/*
Original code from active camo escape:

  exitCombatDelay = TweakDBInterface.GetFloat(t"Items.AdvancedOpticalCamoCommon.exitCombatDelay", 1.50);
  this.PromoteOpticalCamoEffectorToCompletelyBlocking();
  if this.m_inCombat {
    enableVisiblityDelay = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatType.OpticalCamoDuration);
    this.SetInvisible(true);
    hostileTargets = this.GetTargetTrackerComponent().GetHostileThreats(false);
    j = 0;
    while j < ArraySize(hostileTargets) {
      hostileTarget = hostileTargets[j].entity as GameObject;
      hostileTargetPuppet = hostileTarget as ScriptedPuppet;
      if IsDefined(hostileTargetPuppet) {
        hostileTargetPuppet.GetTargetTrackerComponent().DeactivateThreat(this);
      };
      vanishEvt = new ExitCombatOnOpticalCamoActivatedEvent();
      vanishEvt.npc = hostileTarget;
      GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, vanishEvt, exitCombatDelay);
      j += 1;
    };
    enableVisibilityEvt = new EnablePlayerVisibilityEvent();
    GameInstance.GetDelaySystem(this.GetGame()).DelayEvent(this, enableVisibilityEvt, enableVisiblityDelay);
  };


public class ResurrectEvents extends HighLevelTransition {

  protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
    StatusEffectHelper.ApplyStatusEffect(scriptInterface.owner, t"BaseStatusEffect.SecondHeart");
    this.ForceFreeze(stateContext);
    this.SetBlackboardIntVariable(scriptInterface, GetAllBlackboardDefs().PlayerStateMachine.HighLevel, 1);
    this.SetBlackboardIntVariable(scriptInterface, GetAllBlackboardDefs().PlayerStateMachine.Vitals, 2);
    this.SetPlayerVitalsAnimFeatureData(stateContext, scriptInterface, 2, 2.00);
    scriptInterface.PushAnimationEvent(n"PlayerResurrect");
    super.OnEnter(stateContext, scriptInterface);
  }

  protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
    let playerPuppet: ref<PlayerPuppet>;
    this.SendResurrectEvent(scriptInterface);
    this.ForceTemporaryUnequip(stateContext, false);
    scriptInterface.PushAnimationEvent(n"PlayerResurrected");
    playerPuppet = scriptInterface.executionOwner as PlayerPuppet;
    if playerPuppet.IsControlledByLocalPeer() {
      GameInstance.GetDebugVisualizerSystem(scriptInterface.GetGame()).ClearAll();
    };
    if Equals(this.GetDeathType(stateContext, scriptInterface), EDeathType.Swimming) {
      this.StopStatPoolDecayAndRegenerate(scriptInterface, gamedataStatPoolType.Oxygen);
    };
    super.OnExit(stateContext, scriptInterface);
  }

  private final func SendResurrectEvent(scriptInterface: ref<StateGameScriptInterface>) -> Void {
    let player: ref<PlayerPuppet> = scriptInterface.executionOwner as PlayerPuppet;
    let resurrectEvent: ref<ResurrectEvent> = new ResurrectEvent();
    player.QueueEvent(resurrectEvent);
  }
}


  
*/