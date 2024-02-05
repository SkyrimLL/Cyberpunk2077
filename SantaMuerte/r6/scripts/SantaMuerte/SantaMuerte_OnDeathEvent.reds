module SantaMuerte.OnDeathEvent

@if(!ModuleExists("DiverseDeathScreens.OnDeathEvent"))
@replaceMethod(PlayerPuppet)
  protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    // LogChannel(n"DEBUG", ">>> Santa Muerte: DDS not available - Simple death sequence" );  
    // let DeathSequenceController: ref<FullScreenDeathSequenceController> = new FullScreenDeathSequenceController();
    // DeathSequenceController.init(this.GetGame());

    this.ForceCloseRadialWheel();
    // StatusEffectHelper.ApplyStatusEffect(this, t"GameplayRestriction.BlockAllHubMenu");
    super.OnDeath(evt);
    // GameInstance.GetTelemetrySystem(this.GetGame()).LogPlayerDeathEvent(evt);
    // GameInstance.GetAutoSaveSystem(this.GetGame()).InvalidateAutoSaveRequests();
 
  }