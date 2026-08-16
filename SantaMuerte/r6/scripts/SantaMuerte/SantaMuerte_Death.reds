// Interception of Second Heart mechanics

// Event for delayed skip time to allow death animation to play
public class DelayedSkipTimeEvent extends Event {
  public let timeSkipped: Float;
}

// Event for delayed Second Heart status effect removal
public class DelayedClearSecondHeartEvent extends Event {}

@addMethod(PlayerPuppet)
protected cb func OnDelayedSkipTimeEvent(evt: ref<DelayedSkipTimeEvent>) -> Bool {
  let playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();
  playerPuppetPS.m_santaMuerteTracking.skipTimeWithBlackout(evt.timeSkipped);
}

@addMethod(PlayerPuppet)
protected cb func OnDelayedClearSecondHeartEvent(evt: ref<DelayedClearSecondHeartEvent>) -> Bool {
  let playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();
  playerPuppetPS.m_santaMuerteTracking.clearSecondHeart();
}

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
				
				// Add delay before resurrection to show death animation
				let deathAnimDelay = _playerPuppetPS.m_santaMuerteTracking.deathAnimationDelay;
				if (deathAnimDelay > 0.0) {
					let delayedEvent: ref<DelayedSkipTimeEvent> = new DelayedSkipTimeEvent();
					delayedEvent.timeSkipped = timeSkipped;
					GameInstance.GetDelaySystem(_playerPuppet.GetGame()).DelayEvent(_playerPuppet, delayedEvent, deathAnimDelay);
				} else {
					_playerPuppetPS.m_santaMuerteTracking.skipTimeWithBlackout(timeSkipped);
				}

				GameInstance.GetTimeSystem( scriptInterface.GetGame() ).UnsetTimeDilation( n"" );
				GameInstance.GetTimeSystem( scriptInterface.GetGame() ).UnsetTimeDilationOnLocalPlayerZero( n"" );

				stateContext.SetTemporaryBoolParameter( n"requestSandevistanDeactivation", true, true );
				stateContext.SetTemporaryBoolParameter( n"requestKerenzikovDeactivation", true, true );		

				GameInstance.GetRazerChromaEffectsSystem( scriptInterface.GetGame() ).StopAnimation( n"SlowMotion" );

				this.StartDeathEffects( stateContext, scriptInterface );
				this.isDyingEffectPlaying = false;
				super.OnEnter ( stateContext, scriptInterface );
				this.ForceDisableToggleWalk( stateContext );			
				// FIX: Clean up any lingering audio effects from previous deaths
				// This helps prevent audio degradation after multiple deaths
				scriptInterface.GetAudioSystem().NotifyGameTone(n"EnterDeath");
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
	// FIX: Use a safe minimum delay of 0.5 seconds if OpticalCamoDuration is 0 or very small
	if enableVisiblityDelay < 0.5 {
		enableVisiblityDelay = 0.5;
	};
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
		GameInstance.GetDelaySystem( owner.GetGame() ).DelayEvent( owner, vanishEvt, exitCombatDelay );  
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
*/

