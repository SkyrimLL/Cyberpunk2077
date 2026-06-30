// Force refresh of the current Reshade profile when opening the radial menu 
// in public class RadialMenuHubGameController extends gameuiMenuGameController {

@wrapMethod(RadialMenuHubGameController)

  protected cb func OnOpenMenuRequest(evt: ref<OpenMenuRequest>) -> Bool {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();

    if !IsDefined(_playerPuppetPS.m_conditionalOptics) {
        _playerPuppetPS.InitConditionalOpticsSystem(this.m_player);
        LogChannel(n"DEBUG", "[ReshadeBridge] OnOpenMenuRequest: runtime not available yet.");
    } else {
        _playerPuppetPS.m_conditionalOptics.refresh();
        LogChannel(n"DEBUG", "[ReshadeBridge] OnOpenMenuRequest: runtime available, refreshed profile.");
    }
    
    wrappedMethod(evt);
  }


@wrapMethod(MenuHubGameController)

  protected cb func OnOpenMenuRequest(evt: ref<OpenMenuRequest>) -> Bool {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();

    if !IsDefined(_playerPuppetPS.m_conditionalOptics) {
        _playerPuppetPS.InitConditionalOpticsSystem(this.m_player);
        LogChannel(n"DEBUG", "[ReshadeBridge] OnOpenMenuRequest: runtime not available yet.");
    } else {
        _playerPuppetPS.m_conditionalOptics.refresh();
        // LogChannel(n"DEBUG", "[ReshadeBridge] OnOpenMenuRequest: runtime available, refreshed profile.");
    }
    
    wrappedMethod(evt);
  }


// public native class scannerGameController extends inkHUDGameController {
@wrapMethod(scannerGameController)

  private final func ShowScanner(show: Bool) -> Void {
    let _playerPuppet: ref<PlayerPuppet> = this.m_playerPuppet as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = _playerPuppet.GetPS();

    // LogChannel(n"DEBUG", "[ReshadeBridge] ScannerGameController: START SCANNING");

    if !IsDefined(_playerPuppetPS.m_conditionalOptics) {
        _playerPuppetPS.InitConditionalOpticsSystem(_playerPuppet);
        LogChannel(n"DEBUG", "[ReshadeBridge] ScannerGameController: runtime not available yet.");
    } else {
        _playerPuppetPS.m_conditionalOptics.refresh();
        // LogChannel(n"DEBUG", "[ReshadeBridge] ScannerGameController: runtime available, refreshed profile.");
    }
    
    wrappedMethod(show);
  }
 