
// public class PlayerPuppet extends ScriptedPuppet {
@addField(PlayerPuppetPS)
public persistent let m_repeatDisassemblyTracking: ref<RepeatDisassemblyTracking>;

@addMethod(PlayerPuppetPS)
  private final func InitRepeatDisassemblySystem(playerPuppet: ref<GameObject>) -> Void {
    // set up tracker if it doesn't exist
    if !IsDefined(this.m_repeatDisassemblyTracking) {
      // LogChannel(n"DEBUG", "::::: INIT NEW SANTA MUERTE OBJECT ");
      this.m_repeatDisassemblyTracking = new RepeatDisassemblyTracking();
      this.m_repeatDisassemblyTracking.init(playerPuppet as PlayerPuppet);

    } else {
      // Reset if already exists (in case of changed default values)
      // LogChannel(n"DEBUG", "::::: RESET EXISTING SANTA MUERTE OBJECT ");
      this.m_repeatDisassemblyTracking.reset(playerPuppet as PlayerPuppet);
    };
  }

// Bridge between PlayerPuppet and PlayerPuppetPS - Set up Player Puppet Persistent State when game loads (player is attached)
@wrapMethod(PlayerPuppet)
  private final func PlayerAttachedCallback(playerPuppet: ref<GameObject>) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();

    _playerPuppetPS.InitRepeatDisassemblySystem(playerPuppet);

    wrappedMethod(playerPuppet);
}
