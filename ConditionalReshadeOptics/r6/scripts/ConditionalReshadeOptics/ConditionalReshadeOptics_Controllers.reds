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