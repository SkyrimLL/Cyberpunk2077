public class CinematicImmunityConfig {

    public static func Get() -> ref<CinematicImmunityConfig> {
        return new CinematicImmunityConfig();
    }

    // ── Main switch ──────────────────────────────────────────────────────────

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Main Switch")
    @runtimeProperty("ModSettings.category.order", "1")
    @runtimeProperty("ModSettings.displayName", "Enable mod")
    @runtimeProperty("ModSettings.description", "Master toggle for Cinematic Immunity. When OFF, no invulnerability is ever granted.")
    public let modON: Bool = true;

    // ── Scene detection ──────────────────────────────────────────────────────

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Scene Detection")
    @runtimeProperty("ModSettings.category.order", "21")
    @runtimeProperty("ModSettings.displayName", "Johnny possession")
    @runtimeProperty("ModSettings.description", "Grant immunity during Johnny Silverhand possession sequences (Character.johnny_replacer).")
    public let immunityJohnnyON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Scene Detection")
    @runtimeProperty("ModSettings.category.order", "28")
    @runtimeProperty("ModSettings.displayName", "Generic scene tiers (SceneTier3-5)")
    @runtimeProperty("ModSettings.description", "Grant immunity when the game's high-level PSM is in SceneTier3, 4, or 5, or when time-skip / fast-travel is blocked by a scene restriction.")
    public let immunityInSceneON: Bool = true;

    // ── Cyberspace and Braindance ─────────────────────────────────────────────

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Virtual Environment")
    @runtimeProperty("ModSettings.category.order", "20")
    @runtimeProperty("ModSettings.displayName", "VR tutorial")
    @runtimeProperty("ModSettings.description", "Grant immunity during the VR tutorial opening (Character.q000_vr_replacer).")
    public let immunityVRTutorialON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Virtual Environment")
    @runtimeProperty("ModSettings.category.order", "26")
    @runtimeProperty("ModSettings.displayName", "Cyberspace / net dives")
    @runtimeProperty("ModSettings.description", "Grant immunity during cyberspace and net-dive sequences (cyberspace_on fact).")
    public let immunityCyberspaceON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Virtual Environment")
    @runtimeProperty("ModSettings.category.order", "27")
    @runtimeProperty("ModSettings.displayName", "Braindance")
    @runtimeProperty("ModSettings.description", "Grant immunity during braindance viewer and editor sessions.")
    public let immunityBraindanceON: Bool = true;

    // ── Prologue scenes ─────────────────────────────────────────────

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Prologue Scenes")
    @runtimeProperty("ModSettings.category.order", "23")
    @runtimeProperty("ModSettings.displayName", "Corpo lifepath intro")
    @runtimeProperty("ModSettings.description", "Grant immunity while the Arasaka UI is active during the corpo lifepath boardroom opening.")
    public let immunityCorpoIntroON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Prologue Scenes")
    @runtimeProperty("ModSettings.category.order", "24")
    @runtimeProperty("ModSettings.displayName", "Nomad / Street Kid prologue")
    @runtimeProperty("ModSettings.description", "Grant immunity during the Nomad and Street Kid lifepath prologues (before The Rescue begins).")
    public let immunityNomadSKPrologueON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Prologue Scenes")
    @runtimeProperty("ModSettings.category.order", "25")
    @runtimeProperty("ModSettings.displayName", "The Rescue: wakeup & car chase")
    @runtimeProperty("ModSettings.description", "Grant immunity during The Rescue's digital-sickness scene and the subsequent car chase with Jackie, up to Viktor's ripperdoc visit.")
    public let immunityRescueSceneON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Prologue Scenes")
    @runtimeProperty("ModSettings.category.order", "29")
    @runtimeProperty("ModSettings.displayName", "The Heist: Konpeki Plaza escape")
    @runtimeProperty("ModSettings.description", "Grant immunity during the escape car chase after The Heist goes wrong, from chip acquisition until the quest concludes at No Tell Motel.")
    public let immunityHeistEscapeON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Prologue Scenes")
    @runtimeProperty("ModSettings.category.order", "30")
    @runtimeProperty("ModSettings.displayName", "Act 1 -> Act 2 transition")
    @runtimeProperty("ModSettings.description", "Grant immunity during the No Tell Motel sequence through the H10 apartment scene with Johnny, between The Heist completing and Playing for Time beginning.")
    public let immunityActTransitionON: Bool = true;

    // ── Prologue scenes ─────────────────────────────────────────────

    @runtimeProperty("ModSettings.mod", "CINEMATIC IMMUNITY")
    @runtimeProperty("ModSettings.category", "Endgame")
    @runtimeProperty("ModSettings.category.order", "31")
    @runtimeProperty("ModSettings.displayName", "(Don't Fear) The Reaper")
    @runtimeProperty("ModSettings.description", "Grant immunity during the solo Arasaka Tower assault ending (q115). Covers both the Rogue-assisted and solo DFTR variants.")
    public let immunityDFTRON: Bool = true;

    // ── Listener registration ────────────────────────────────────────────────

    public func RegisterMyListeners() -> Void {
        ModSettings.RegisterListenerToClass(this);
        ModSettings.RegisterListenerToModifications(this);
    }
}
