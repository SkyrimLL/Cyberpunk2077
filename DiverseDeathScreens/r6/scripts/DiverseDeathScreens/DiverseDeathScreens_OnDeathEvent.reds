module DiverseDeathScreens.OnDeathEvent

@if(!ModuleExists("SantaMuerte.OnDeathEvent"))
@wrapMethod(PlayerPuppet)
  protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    // LogChannel(n"DEBUG", ">>> DiverseDeathScreens: Santa Muerte not available - Change anim for regular death" );  

    // GameObject.PlaySoundEvent(this, n"ONO_V_LongPain");

    let DeathSequenceController: ref<FullScreenDeathSequenceController> = new FullScreenDeathSequenceController();
    DeathSequenceController.init(this.GetGame());

    wrappedMethod( evt );  
  }
 
@if(ModuleExists("SantaMuerte.OnDeathEvent"))
@replaceMethod(PlayerPuppet)
  protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
    // LogChannel(n"DEBUG", ">>> DiverseDeathScreens: Santa Muerte detected! - Change anim for resurrection" );  

    // GameObject.PlaySoundEvent(this, n"ONO_V_LongPain");

    let DeathSequenceController: ref<FullScreenDeathSequenceController> = new FullScreenDeathSequenceController();
    DeathSequenceController.init(this.GetGame());

    this.ForceCloseRadialWheel();
    // StatusEffectHelper.ApplyStatusEffect(this, t"GameplayRestriction.BlockAllHubMenu");
    super.OnDeath(evt);
    // GameInstance.GetTelemetrySystem(this.GetGame()).LogPlayerDeathEvent(evt);
    // GameInstance.GetAutoSaveSystem(this.GetGame()).InvalidateAutoSaveRequests();
 
  }

  
@wrapMethod(ResurrectEvents)
protected func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void 
{
    let inkSystem = GameInstance.GetInkSystem();
    let hudRoot = inkSystem.GetLayer(n"inkHUDLayer").GetVirtualWindow();
    hudRoot.SetOpacity(1.0);
 
    wrappedMethod( stateContext, scriptInterface ); 
}

 