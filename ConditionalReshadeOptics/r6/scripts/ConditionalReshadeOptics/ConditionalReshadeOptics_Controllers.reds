// Force refresh of the current Reshade profile when opening the radial menu 
// in public class RadialMenuHubGameController extends gameuiMenuGameController {

@wrapMethod(RadialMenuHubGameController)

  protected cb func OnOpenMenuRequest(evt: ref<OpenMenuRequest>) -> Bool {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();

    if !IsDefined(_playerPuppetPS.m_conditionalOptics) {
        _playerPuppetPS.InitConditionalOpticsSystem(this.m_player);
        _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] OnOpenMenuRequest: runtime not available yet.");
    } else {
        _playerPuppetPS.m_conditionalOptics.refresh();
        _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] OnOpenMenuRequest: runtime available, refreshed profile.");
    }
    
    wrappedMethod(evt);
  }


@wrapMethod(MenuHubGameController)

  protected cb func OnOpenMenuRequest(evt: ref<OpenMenuRequest>) -> Bool {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();

    if !IsDefined(_playerPuppetPS.m_conditionalOptics) {
        _playerPuppetPS.InitConditionalOpticsSystem(this.m_player);
        _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] OnOpenMenuRequest: runtime not available yet.");
    } else {
        _playerPuppetPS.m_conditionalOptics.refresh();
        // _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] OnOpenMenuRequest: runtime available, refreshed profile.");
    }
    
    wrappedMethod(evt);
  }


// public native class scannerGameController extends inkHUDGameController {
@wrapMethod(scannerGameController)

  private final func ShowScanner(show: Bool) -> Void {
    let _playerPuppet: ref<PlayerPuppet> = this.m_playerPuppet as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();

    // _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] ScannerGameController: START SCANNING");

    if !IsDefined(_playerPuppetPS.m_conditionalOptics) {
        _playerPuppetPS.InitConditionalOpticsSystem(_playerPuppet);
        _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] ScannerGameController: runtime not available yet.");
    } else {
        _playerPuppetPS.m_conditionalOptics.refresh();
        // _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] ScannerGameController: runtime available, refreshed profile.");
    }
    
    wrappedMethod(show);
  }
 

// @wrapMethod(ArcadeMachine)
// protected cb func OnBeginArcadeMinigameUI(evt: ref<BeginArcadeMinigameUI>) -> Bool  {
//   wrappedMethod(evt); 
//   let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
@wrapMethod(MenuScenario_ArcadeMinigame)
protected cb func OnEnterScenario(prevScenario: CName, userData: ref<IScriptable>) -> Bool {

  let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
  let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();

  wrappedMethod(prevScenario, userData);
 
  if IsDefined(_playerPuppet) {
    _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] Arcade started! Found player puppet" );
    _playerPuppetPS.m_conditionalOptics.isArcadeMachineON = true; 
    _playerPuppetPS.m_conditionalOptics.refreshReshadeProfile();
      
  } else {
    _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] Arcade started, but PlayerPuppet could not be found.");
  }
}

@wrapMethod(MenuScenario_ArcadeMinigame)
protected cb func OnArcadeMinigameEnd() -> Bool {
  let _playerPuppet: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(GetGameInstance()).GetLocalPlayerMainGameObject() as PlayerPuppet;
  let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();

  // 4. Safety check to make sure the player object is valid
  if IsDefined(_playerPuppet) {  

    _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] Arcade ended! " );
    _playerPuppetPS.m_conditionalOptics.isArcadeMachineON = false;
    _playerPuppetPS.m_conditionalOptics.refreshReshadeProfile();
 
     
  } else {
    _playerPuppetPS.m_conditionalOptics.showDebugMessage( "[ReshadeBridge] Arcade ended, but PlayerPuppet could not be found.");
  }

  wrappedMethod();
  
}