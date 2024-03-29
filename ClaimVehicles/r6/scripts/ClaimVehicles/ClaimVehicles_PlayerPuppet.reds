
@addField(PlayerPuppetPS)
public persistent let m_claimedVehicleTracking: ref<ClaimedVehicleTracking>;

@addMethod(PlayerPuppetPS)
  private final func InitClaimVehicleSystem(playerPuppet: ref<GameObject>) -> Void {
    // set up tracker if it doesn't exist
    if !IsDefined(this.m_claimedVehicleTracking) {
      // LogChannel(n"DEBUG", "::::: INIT NEW CLAIM TRACKING OBJECT ");
      this.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      this.m_claimedVehicleTracking.init(playerPuppet as PlayerPuppet);

    } else {
      // Reset if already exists (in case of changed default values)
      // LogChannel(n"DEBUG", "::::: RESET EXISTING CLAIM TRACKING OBJECT ");
      this.m_claimedVehicleTracking.reset(playerPuppet as PlayerPuppet);
    };
  }

// Bridge between PlayerPuppet and PlayerPuppetPS - Set up Player Puppet Persistent State when game loads (player is attached)
@wrapMethod(PlayerPuppet)
  private final func PlayerAttachedCallback(playerPuppet: ref<GameObject>) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();

    _playerPuppetPS.InitClaimVehicleSystem(playerPuppet);

    if (!_playerPuppetPS.m_claimedVehicleTracking.refreshPlayerGarageOnLoad) {
      _playerPuppetPS.m_claimedVehicleTracking.refreshClaimedVehiclesOnLoad();
      _playerPuppetPS.m_claimedVehicleTracking.refreshPlayerGarageOnLoad = true;
    }

    wrappedMethod(playerPuppet);
}