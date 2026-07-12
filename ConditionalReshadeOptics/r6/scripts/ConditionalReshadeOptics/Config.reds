public class ConditionalReshadeOpticsConfig {

    public static func Get() -> ref<ConditionalReshadeOpticsConfig> {
        let self: ref<ConditionalReshadeOpticsConfig> = new ConditionalReshadeOpticsConfig();
        return self;
    }

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Main switch")
    @runtimeProperty("ModSettings.category.order", "1")
    @runtimeProperty("ModSettings.displayName", "Enable mod")
    @runtimeProperty("ModSettings.description", "Master toggle for Conditional ReShade Optics.")
    let modON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Heartbeat")
    @runtimeProperty("ModSettings.category.order", "10")
    @runtimeProperty("ModSettings.displayName", "Continuous heartbeat timer")
    @runtimeProperty("ModSettings.description", "If ON, periodic checks run in the background to auto-switch profiles.")
    let heartbeatContinuousON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Effect detection")
    @runtimeProperty("ModSettings.category.order", "20")
    @runtimeProperty("ModSettings.displayName", "Enable VR profile")
    @runtimeProperty("ModSettings.description", "Allow profile switching to VR when VR tutorial conditions are detected.")
    let effectVRON: Bool = true; 

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Effect detection")
    @runtimeProperty("ModSettings.category.order", "21")
    @runtimeProperty("ModSettings.displayName", "Enable cyberspace profile")
    @runtimeProperty("ModSettings.description", "Allow profile switching to Cyberspace when cyberspace is detected.")
    let effectCyberspaceON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Effect detection")
    @runtimeProperty("ModSettings.category.order", "21")
    @runtimeProperty("ModSettings.displayName", "Enable arcade game profile")
    @runtimeProperty("ModSettings.description", "Allow profile switching to Arcade Game when arcade game is detected.")
    let effectArcadeGameON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Effect detection")
    @runtimeProperty("ModSettings.category.order", "22")
    @runtimeProperty("ModSettings.displayName", "Enable braindance profile")
    @runtimeProperty("ModSettings.description", "Allow profile switching to Braindance when braindance is detected in View mode.")
    let effectBraindanceON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Effect detection")
    @runtimeProperty("ModSettings.category.order", "22")
    @runtimeProperty("ModSettings.displayName", "Enable braindance editor profile")
    @runtimeProperty("ModSettings.description", "Allow profile switching to BraindanceEditor when braindance editor is detected.")
    let effectBraindanceEditorON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Effect detection")
    @runtimeProperty("ModSettings.category.order", "23")
    @runtimeProperty("ModSettings.displayName", "Enable Johnny profile")
    @runtimeProperty("ModSettings.description", "Allow profile switching to Johnny when Johnny conditions are detected.")
    let effectJohnnyON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Effect detection")
    @runtimeProperty("ModSettings.category.order", "24")
    @runtimeProperty("ModSettings.displayName", "Enable Kiroshi profile")
    @runtimeProperty("ModSettings.description", "Allow profile switching to Kiroshi when Viktor HUD eyes are detected.")
    let effectKiroshiON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Effect detection")
    @runtimeProperty("ModSettings.category.order", "25")
    @runtimeProperty("ModSettings.displayName", "Enable cheap cyberware profile")
    @runtimeProperty("ModSettings.description", "Allow profile switching to CheapCyberware during prologue HUD corruption stages.")
    let effectCheapCyberwareON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Effect detection")
    @runtimeProperty("ModSettings.category.order", "26")
    @runtimeProperty("ModSettings.displayName", "Enable glitched cyberware profile")
    @runtimeProperty("ModSettings.description", "Allow profile switching to RescueGlitched when digital sickness is detected.")
    let effectGlitchedCyberwareON: Bool = true;

    @runtimeProperty("ModSettings.mod", "CONDITIONAL RESHADE OPTICS")
    @runtimeProperty("ModSettings.category", "Effect detection")
    @runtimeProperty("ModSettings.category.order", "27")
    @runtimeProperty("ModSettings.displayName", "Enable no cyberware profile")
    @runtimeProperty("ModSettings.description", "Allow profile switching to NoCyberware for fallback/default state.")
    let effectNoCyberwareON: Bool = true;


    public func RegisterMyListeners() {
        // Automatically updates your class variables when changed in the UI
        ModSettings.RegisterListenerToClass(this);
        
        // Essential: Tells Mod Settings to trigger callbacks on this object
        ModSettings.RegisterListenerToModifications(this);
    }
}