module DiverseDeathScreens.OnDeathEvent

@if(!ModuleExists("SantaMuerte.OnDeathEvent"))
@wrapMethod(PlayerPuppet)
  protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    // LogChannel(n"DEBUG", ">>> DiverseDeathScreens: Santa Muerte not available - Change anim for regular death" );  

    let DeathSequenceController: ref<FullScreenDeathSequenceController> = new FullScreenDeathSequenceController();
    DeathSequenceController.init(this.GetGame());

    wrappedMethod( evt );  
  }
 
@if(ModuleExists("SantaMuerte.OnDeathEvent"))
@replaceMethod(PlayerPuppet)
  protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    // LogChannel(n"DEBUG", ">>> DiverseDeathScreens: Santa Muerte detected! - Change anim for resurrection" );  

    let DeathSequenceController: ref<FullScreenDeathSequenceController> = new FullScreenDeathSequenceController();
    DeathSequenceController.init(this.GetGame());

    this.ForceCloseRadialWheel();
    // StatusEffectHelper.ApplyStatusEffect(this, t"GameplayRestriction.BlockAllHubMenu");
    super.OnDeath(evt);
    // GameInstance.GetTelemetrySystem(this.GetGame()).LogPlayerDeathEvent(evt);
    // GameInstance.GetAutoSaveSystem(this.GetGame()).InvalidateAutoSaveRequests();
 
  }