public class AdaptiveSlidersConfig {

    public static func Get() -> ref<AdaptiveSlidersConfig> {
        let self: ref<AdaptiveSlidersConfig> = new AdaptiveSlidersConfig();
        return self;
    }

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Master")
    @runtimeProperty("ModSettings.category.order", "1")
    @runtimeProperty("ModSettings.displayName", "Enable mod")
    @runtimeProperty("ModSettings.description", "Master toggle for Adaptive Sliders.")
    let modON: Bool = true;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Set slider to max")
    @runtimeProperty("ModSettings.category.order", "10")
    @runtimeProperty("ModSettings.displayName", "Drop")
    @runtimeProperty("ModSettings.description", "Set slider to max items by default when dropping items.")
    let setMaxOnDrop: Bool = true;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Set slider to max")
    @runtimeProperty("ModSettings.category.order", "11")
    @runtimeProperty("ModSettings.displayName", "Sell")
    @runtimeProperty("ModSettings.description", "Set slider to max items by default when selling items.")
    let setMaxOnSell: Bool = true;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Set slider to max")
    @runtimeProperty("ModSettings.category.order", "12")
    @runtimeProperty("ModSettings.displayName", "Disassembly")
    @runtimeProperty("ModSettings.description", "Set slider to max items by default when disassembling items.")
    let setMaxOnDisassembly: Bool = true;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Set slider to max")
    @runtimeProperty("ModSettings.category.order", "13")
    @runtimeProperty("ModSettings.displayName", "Craft")
    @runtimeProperty("ModSettings.description", "Set slider to max items by default when crafting items.")
    let setMaxOnCraft: Bool = true;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Set slider to max")
    @runtimeProperty("ModSettings.category.order", "14")
    @runtimeProperty("ModSettings.displayName", "Transfer to Storage")
    @runtimeProperty("ModSettings.description", "Set slider to max items by default when transferring items to storage.")
    let setMaxOnTransferToStorage: Bool = true;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Set slider to max")
    @runtimeProperty("ModSettings.category.order", "15")
    @runtimeProperty("ModSettings.displayName", "Transfer to Player")
    @runtimeProperty("ModSettings.description", "Set slider to max items by default when transferring items to player inventory.")
    let setMaxOnTransferToPlayer: Bool = false;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Set slider to max")
    @runtimeProperty("ModSettings.category.order", "16")
    @runtimeProperty("ModSettings.displayName", "Buy")
    @runtimeProperty("ModSettings.description", "Set slider to max items by default when buying items.")
    let setMaxOnBuy: Bool = false;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Auto-click OK")
    @runtimeProperty("ModSettings.category.order", "20")
    @runtimeProperty("ModSettings.displayName", "Drop")
    @runtimeProperty("ModSettings.description", "Automatically confirm quantity picker when dropping items.")
    let autoClickOnDrop: Bool = false;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Auto-click OK")
    @runtimeProperty("ModSettings.category.order", "21")
    @runtimeProperty("ModSettings.displayName", "Sell")
    @runtimeProperty("ModSettings.description", "Automatically confirm quantity picker when selling items.")
    let autoClickOnSell: Bool = false;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Auto-click OK")
    @runtimeProperty("ModSettings.category.order", "22")
    @runtimeProperty("ModSettings.displayName", "Disassembly")
    @runtimeProperty("ModSettings.description", "Automatically confirm quantity picker when disassembling items.")
    let autoClickOnDisassembly: Bool = true;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Auto-click OK")
    @runtimeProperty("ModSettings.category.order", "23")
    @runtimeProperty("ModSettings.displayName", "Craft")
    @runtimeProperty("ModSettings.description", "Automatically confirm quantity picker when crafting items.")
    let autoClickOnCraft: Bool = false;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Auto-click OK")
    @runtimeProperty("ModSettings.category.order", "24")
    @runtimeProperty("ModSettings.displayName", "Transfer to Storage")
    @runtimeProperty("ModSettings.description", "Automatically confirm quantity picker when transferring items to storage.")
    let autoClickOnTransferToStorage: Bool = false;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Auto-click OK")
    @runtimeProperty("ModSettings.category.order", "25")
    @runtimeProperty("ModSettings.displayName", "Transfer to Player")
    @runtimeProperty("ModSettings.description", "Automatically confirm quantity picker when transferring items to player inventory.")
    let autoClickOnTransferToPlayer: Bool = false;

    @runtimeProperty("ModSettings.mod", "ADAPTIVE SLIDERS")
    @runtimeProperty("ModSettings.category", "Auto-click OK")
    @runtimeProperty("ModSettings.category.order", "26")
    @runtimeProperty("ModSettings.displayName", "Buy")
    @runtimeProperty("ModSettings.description", "Automatically confirm quantity picker when buying items.")
    let autoClickOnBuy: Bool = false;
}
