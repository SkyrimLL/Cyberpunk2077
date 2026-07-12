
// ── PlayerPuppetPS field ─────────────────────────────────────────────────────

@addField(PlayerPuppetPS)
public let m_cinematicImmunity: ref<CinematicImmunity>;

// ── PlayerPuppetPS init method ───────────────────────────────────────────────

@addMethod(PlayerPuppetPS)
private final func InitCinematicImmunitySystem(playerPuppet: ref<GameObject>) -> Void {
    if !IsDefined(this.m_cinematicImmunity) {
        this.m_cinematicImmunity = new CinematicImmunity();
        this.m_cinematicImmunity.init(playerPuppet as PlayerPuppet);
    } else {
        this.m_cinematicImmunity.reset(playerPuppet as PlayerPuppet);
    };
}

// ── PlayerPuppet attachment hook ─────────────────────────────────────────────

@wrapMethod(PlayerPuppet)
private final func PlayerAttachedCallback(playerPuppet: ref<GameObject>) -> Void {
    let ps: ref<PlayerPuppetPS> = this.GetPS();
    ps.InitCinematicImmunitySystem(playerPuppet);
    ps.m_cinematicImmunity.startHeartbeatIfNeeded();
    wrappedMethod(playerPuppet);
}