// ConditionalReshadeOptics - PlayerPuppet hooks

@addField(PlayerPuppetPS)
public let m_conditionalOptics: ref<ConditionalOptics>;

@addMethod(PlayerPuppetPS)
  private final func InitConditionalOpticsSystem(playerPuppet: ref<GameObject>) -> Void {
    if !IsDefined(this.m_conditionalOptics) {
      this.m_conditionalOptics = new ConditionalOptics();
      this.m_conditionalOptics.init(playerPuppet as PlayerPuppet);
    } else {
      this.m_conditionalOptics.reset(playerPuppet as PlayerPuppet);
    };
  }

// Bridge between PlayerPuppet and PlayerPuppetPS - initialise when the player is attached
@wrapMethod(PlayerPuppet)
  private final func PlayerAttachedCallback(playerPuppet: ref<GameObject>) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();

    _playerPuppetPS.InitConditionalOpticsSystem(playerPuppet);

    let heartbeat: ref<ConditionalOpticsHeartbeatCallback> = ConditionalOpticsHeartbeatCallback.create();
    heartbeat.init(playerPuppet as PlayerPuppet); 
    // let delaySystem = GameInstance.GetDelaySystem(GetGameInstance());
    // delaySystem.DelayCallback(heartbeat, 5.0, false);

    wrappedMethod(playerPuppet);
  }
