
// public class PlayerPuppet extends ScriptedPuppet {
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

// Bridge between PlayerPuppet and PlayerPuppetPS - Set up Player Puppet Persistent State when game loads (player is attached)
@wrapMethod(PlayerPuppet)
  private final func PlayerAttachedCallback(playerPuppet: ref<GameObject>) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();

    _playerPuppetPS.InitSantaMuerteSystem(playerPuppet);

    wrappedMethod(playerPuppet);
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

