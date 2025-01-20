@addMethod(gameuiInGameMenuGameController)
protected cb func RegisterMrBunnyStore(event: ref<VirtualShopRegistration>) -> Bool {
  event.AddStore(
    n"MrBunny",
    "MrBunny",
    ["Items.caibro_bunny_default","Items.caibro_bunny_default2","Items.caibro_bunny_default3","Items.caibro_courrier_default"],
    [500, 500, 500, 800],
    r"base/gameplay/gui/world/internet/templates/atlases/mrbunnystore_icon.inkatlas",
    n"icon_part",
    ["Legendary", "Legendary", "Legendary", "Legendary"],
    [1, 1, 1, 1]
  );
}