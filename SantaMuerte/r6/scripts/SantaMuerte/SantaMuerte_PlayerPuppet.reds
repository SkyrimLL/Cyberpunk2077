
// Track time skip start to calculate duration
@addField(PlayerPuppetPS)
public let m_santaMuerteTimeBeforeSkip: Float;

@addField(PlayerPuppetPS)
public persistent let m_santaMuerteTracking: ref<SantaMuerteTracking>;

@addMethod(PlayerPuppetPS)
  private final func InitSantaMuerteSystem(playerPuppet: ref<GameObject>) -> Void {
    // set up tracker if it doesn't exist
    if !IsDefined(this.m_santaMuerteTracking) {
      // LogChannel(n"DEBUG", "::::: INIT NEW SANTA MUERTE OBJECT ");
      this.m_santaMuerteTracking = new SantaMuerteTracking();
      this.m_santaMuerteTracking.init(playerPuppet as PlayerPuppet);

    } else {
      // Reset if already exists (in case of changed default values)
      // LogChannel(n"DEBUG", "::::: RESET EXISTING SANTA MUERTE OBJECT ");
      this.m_santaMuerteTracking.reset(playerPuppet as PlayerPuppet);
    };
  }

// Initialize DarkFuture compatibility if the mod is installed
@if(ModuleExists("DarkFuture.System"))
@addMethod(PlayerPuppetPS)
  private final func InitDarkFutureCompatibility(playerPuppet: ref<PlayerPuppet>) -> Void {
    // Get the scriptable systems container to initialize DarkFuture compatibility systems
    let gameInstance: GameInstance = playerPuppet.GetGame();
    let systemsContainer: ref<ScriptableSystemsContainer> = GameInstance.GetScriptableSystemsContainer(gameInstance);
    
    // Get (and instantiate if needed) the compatibility systems
    let santaMuerteDF: ref<ScriptableSystem> = systemsContainer.Get(n"SantaMuerteCompatibility_DarkFuture");
    let negotiableAffectionDF: ref<ScriptableSystem> = systemsContainer.Get(n"NegotiableAffection_DarkFuture");

    // LogChannel(n"DEBUG", "SANTA MUERTE >>> InitDarkFutureCompatibility: SantaMuerteCompatibility_DarkFuture system: " + ToString(santaMuerteDF));
    // LogChannel(n"DEBUG", "SANTA MUERTE >>> InitDarkFutureCompatibility: NegotiableAffection_DarkFuture system: " + ToString(negotiableAffectionDF));
   
    // Queue PlayerAttachRequest to trigger OnPlayerAttach callbacks which register the fact listeners
    if IsDefined(santaMuerteDF) {
      let attachRequest1: ref<PlayerAttachRequest> = new PlayerAttachRequest();
      attachRequest1.owner = playerPuppet;
      santaMuerteDF.QueueRequest(attachRequest1);
    } 
    // else {
    //   LogChannel(n"DEBUG", "SANTA MUERTE >>> SantaMuerteCompatibility_DarkFuture not found - DarkFuture mod not installed");
    // }
    
    if IsDefined(negotiableAffectionDF) {
      let attachRequest2: ref<PlayerAttachRequest> = new PlayerAttachRequest();
      attachRequest2.owner = playerPuppet;
      negotiableAffectionDF.QueueRequest(attachRequest2);
    } 
    // else {
    //   LogChannel(n"DEBUG", "SANTA MUERTE >>> NegotiableAffection_DarkFuture not found - DarkFuture mod not installed");
    // }
  }

// No-op version when DarkFuture is not installed
@if(!ModuleExists("DarkFuture.System"))
@addMethod(PlayerPuppetPS)
  private final func InitDarkFutureCompatibility(playerPuppet: ref<PlayerPuppet>) -> Void {
    // Do nothing if DarkFuture is not installed
    // LogChannel(n"DEBUG", "SANTA MUERTE >>> InitDarkFutureCompatibility: DarkFuture module NOT found - compatibility disabled");
  }

// Bridge between PlayerPuppet and PlayerPuppetPS - Set up Player Puppet Persistent State when game loads (player is attached)
@wrapMethod(PlayerPuppet)
  private final func PlayerAttachedCallback(playerPuppet: ref<GameObject>) -> Void {  
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();
    let handler = GameInstance.GetSystemRequestsHandler();
    let savedGamesCount = handler.RequestSavesCountSync();
    let qs = GameInstance.GetQuestsSystem(this.GetGame());

    // LogChannel(n"DEBUG", "SANTA MUERTE >>> PlayerAttachedCallback: " + ToString(playerPuppet) + " - SavedGamesCount: " + ToString(savedGamesCount) + " - QuestsSystem: " + ToString(qs));

    GameInstance.GetQuestsSystem(this.GetGame()).SetFactStr("CheckSavedGamesCount", 1);
    GameInstance.GetQuestsSystem(this.GetGame()).SetFactStr("SavedGamesCount", savedGamesCount);

    _playerPuppetPS.InitSantaMuerteSystem(playerPuppet);  

    // Initialize DarkFuture compatibility systems (if DarkFuture is installed, the systems will be instantiated)
    _playerPuppetPS.InitDarkFutureCompatibility(this);

    // Check Permadeath flag with CET
    GameInstance.GetQuestsSystem(playerPuppet.GetGame()).SetFactStr("CheckPermadeath", 1); 

    wrappedMethod(playerPuppet);
}

// Hook into voluntary time skip (sleeping, waiting, etc.) to restore resurrections
@addMethod(PlayerPuppet)
protected cb func OnSantaMuerteTimeSkipEvent(evt: ref<SantaMuerteTimeSkipEvent>) -> Bool {
  let playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();
  
  if IsDefined(playerPuppetPS) && IsDefined(playerPuppetPS.m_santaMuerteTracking) {
    // Time skip has finished - restore resurrections based on configured duration
    // The event fires after any time skip (sleep, wait, etc.)
    let timeSkipped: Float = evt.timeSkipped;
    
    // Only restore if minimum duration is met (typically configured to require significant rest)
    if (timeSkipped >= playerPuppetPS.m_santaMuerteTracking.sleepRecoveryMinDuration) {
      playerPuppetPS.m_santaMuerteTracking.restoreResurrectionsAfterSleep(timeSkipped);
    }
  }
}

/*

  private final func Revive(percAmount: Float) -> Void {
    let playerID: StatsObjectID = Cast<StatsObjectID>(this.GetEntityID());
    let statPoolsSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.GetGame());
    if percAmount >= 0.00 && percAmount <= 100.00 {
      statPoolsSystem.RequestSettingStatPoolValue(playerID, gamedataStatPoolType.Health, percAmount, null, true);
    };
  }
*/



