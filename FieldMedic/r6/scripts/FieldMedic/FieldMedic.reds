// FieldMedic — Runtime hooks for consumable swap + optional loot injection.
//
// TweakXL cannot change the record class of an existing vanilla record, so overriding
// vanilla junk records in YAML does not turn them into usable consumables. Instead we
// define new FieldMedic_* ConsumableItem_Record clones in YAML and swap the vanilla
// junk stack for the FieldMedic clone here, both on container fill and on pickup.
//
// Vanilla ID map (verified at runtime via the Pickup: diagnostic log):
//   Items.GenericJunkItem4      = Medical Gauze          -> Items.FieldMedic_MedicalGauze
//   Items.GenericPoorJunkItem1  = Antiseptic Disinfectant -> Items.FieldMedic_AntisepticDisinfectant
//   Items.GenericJunkItem18     = Medical Forceps         -> Items.FieldMedic_MedicalForceps (unverified)
//   Items.GenericJunkItem19     = Surgical Scissors       -> Items.FieldMedic_SurgicalScissors (unverified)

@wrapMethod(gameLootContainerBase)
protected cb func OnInventoryFilledEvent(evt: ref<ContainerFilledEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);

  LogChannel(n"DEBUG", s"[FieldMedic] OnInventoryFilledEvent fired on \(this.GetClassName())");
  let cfg: ref<FieldMedicConfig> = FieldMedicConfig.Get();
  if cfg.modON {
    FieldMedicLootInjector.InjectContainer(this, cfg);
  }
  return result;
}

// Convert any vanilla FieldMedic-eligible junk already sitting in the player's inventory when
// the save is loaded (or when V is re-attached after fast travel / cutscenes).
@wrapMethod(PlayerPuppet)
private final func PlayerAttachedCallback(playerPuppet: ref<GameObject>) -> Void {
  wrappedMethod(playerPuppet);

  LogChannel(n"DEBUG", s"[FieldMedic] PlayerAttachedCallback fired; this==arg: \(playerPuppet == this)");
  let cfg: ref<FieldMedicConfig> = FieldMedicConfig.Get();
  if cfg.modON && playerPuppet == this {
    FieldMedicLootInjector.SwapAllJunkConsumables(playerPuppet, cfg);
  }
}

// Per-item hook: fires every time an item is added to V's inventory (pickup, loot,
// container transfer, quest reward, mod inject). Cheaper than iterating inventory,
// and catches items long after the save was loaded.
@wrapMethod(PlayerPuppet)
protected cb func OnItemAddedToInventory(evt: ref<ItemAddedEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);

  if ItemID.IsValid(evt.itemID) {
    let tdbid: TweakDBID = ItemID.GetTDBID(evt.itemID);
    let rec: ref<Item_Record> = TweakDBInterface.GetItemRecord(tdbid);
    let localized: String = "";
    let friendly: String = "";
    if IsDefined(rec) {
      localized = rec.LocalizedName();
      friendly  = rec.FriendlyName();
    }
    LogChannel(n"DEBUG", s"[FieldMedic] Pickup: id=\(TDBID.ToStringDEBUG(tdbid)) friendly=\"\(friendly)\" localized=\"\(localized)\"");
  }

  let cfg: ref<FieldMedicConfig> = FieldMedicConfig.Get();
  if cfg.modON {
    FieldMedicLootInjector.SwapOnAdd(this, evt, cfg);
  }
  return result;
}

// Because our clones use raw-string displayNames (which the game treats as invalid
// LocKey lookups and resolves to empty), fall back to the paired vanilla junk record's
// resolved display name / description in the backpack UI.
@wrapMethod(UIInventoryItem)
public final func GetName() -> String {
  let name: String = wrappedMethod();
  if StrLen(name) > 0 {
    return name;
  }
  return FieldMedicLootInjector.GetVanillaDisplayNameFor(this.GetTweakDBID());
}

@wrapMethod(UIInventoryItem)
public final func GetDescription() -> String {
  let desc: String = wrappedMethod();
  if StrLen(desc) > 0 {
    return desc;
  }
  return FieldMedicLootInjector.GetVanillaDescriptionFor(this.GetTweakDBID());
}

// The vanilla injector bases (BonesMcCoy70V0 etc.) set removeAfterUse=false on their
// Consume action and rely on a delayed event driven by the injector animation state
// machine. Switching itemType to Con_Edible breaks that timing, so we force the stack
// to decrement immediately for our clones.
@wrapMethod(ConsumeAction)
public func CompleteAction(gameInstance: GameInstance) -> Void {
  wrappedMethod(gameInstance);

  let itemData: wref<gameItemData> = this.GetItemData();
  if !IsDefined(itemData) {
    LogChannel(n"DEBUG", s"[FieldMedic] ConsumeAction.CompleteAction: no itemData");
    return;
  }
  let tdbid: TweakDBID = ItemID.GetTDBID(itemData.GetID());
  let isOurs: Bool = FieldMedicLootInjector.IsFieldMedicClone(tdbid);
  let shouldRemove: Bool = this.ShouldRemoveAfterUse();
  let qty: Int32 = itemData.GetQuantity();
  LogChannel(n"DEBUG", s"[FieldMedic] ConsumeAction.CompleteAction fired: id=\(TDBID.ToStringDEBUG(tdbid)) isOurs=\(isOurs) shouldRemove=\(shouldRemove) qty=\(qty)");
  if !isOurs {
    return;
  }
  if shouldRemove {
    return;
  }
  let removed: Bool = GameInstance.GetTransactionSystem(gameInstance).RemoveItem(this.GetExecutor(), itemData.GetID(), 1);
  LogChannel(n"DEBUG", s"[FieldMedic] Forced consume-remove for \(TDBID.ToStringDEBUG(tdbid)) [removed=\(removed)]");
}

public abstract final class FieldMedicLootInjector {

  public final static func InjectContainer(container: ref<gameLootContainerBase>, cfg: ref<FieldMedicConfig>) -> Void {
    if !IsDefined(container) || container.IsQuest() || container.IsEmpty() {
      return;
    }

    let lootID: TweakDBID = container.GetContentAssignment();

    // Swap vanilla junk records the game already generated for our functional consumable clones.
    FieldMedicLootInjector.SwapAllJunkConsumables(container, cfg);

    if cfg.injectBloodyBandages && FieldMedicLootInjector.IsMedicalContainer(lootID) {
      FieldMedicLootInjector.RollAndAdd(container, t"Items.FieldMedic_BloodyBandage", cfg.bloodyBandageChance, cfg);
    }

    if cfg.injectBleachBottles && FieldMedicLootInjector.IsIndustrialContainer(lootID) {
      FieldMedicLootInjector.RollAndAdd(container, t"Items.FieldMedic_BleachBottle", cfg.bleachBottleChance, cfg);
    }
  }

  // Central swap table so container-fill and player-attach paths stay in sync.
  // Vanilla junk IDs verified via [FieldMedic] Pickup: log — the mod's original README
  // mapping (Items.MedicalGauze etc.) was fictional.
  public final static func SwapAllJunkConsumables(owner: ref<GameObject>, cfg: ref<FieldMedicConfig>) -> Void {
    FieldMedicLootInjector.SwapItem(owner, t"Items.GenericJunkItem4",     t"Items.FieldMedic_MedicalGauze",           cfg);
    FieldMedicLootInjector.SwapItem(owner, t"Items.GenericPoorJunkItem1", t"Items.FieldMedic_AntisepticDisinfectant", cfg);
  }

  // Reverse map: FieldMedic clone -> vanilla junk source. Used by the UI wraps below
  // to borrow the vanilla name/description because the game's LocKey resolver returns
  // empty for our raw-string displayName values.
  public final static func GetVanillaSourceFor(fieldMedicID: TweakDBID) -> TweakDBID {
    if fieldMedicID == t"Items.FieldMedic_MedicalGauze"           { return t"Items.GenericJunkItem4"; }
    if fieldMedicID == t"Items.FieldMedic_AntisepticDisinfectant" { return t"Items.GenericPoorJunkItem1"; } 
    return TDBID.None();
  }

  public final static func IsFieldMedicClone(tdbid: TweakDBID) -> Bool {
    return TDBID.IsValid(FieldMedicLootInjector.GetVanillaSourceFor(tdbid));
  }

  public final static func GetVanillaDisplayNameFor(fieldMedicID: TweakDBID) -> String {
    let vanilla: TweakDBID = FieldMedicLootInjector.GetVanillaSourceFor(fieldMedicID);
    if !TDBID.IsValid(vanilla) {
      return "";
    }
    let rec: ref<Item_Record> = TweakDBInterface.GetItemRecord(vanilla);
    if !IsDefined(rec) {
      return "";
    }
    return GetLocalizedItemNameByCName(rec.DisplayName());
  }

  public final static func GetVanillaDescriptionFor(fieldMedicID: TweakDBID) -> String {
    let vanilla: TweakDBID = FieldMedicLootInjector.GetVanillaSourceFor(fieldMedicID);
    if !TDBID.IsValid(vanilla) {
      return "";
    }
    let rec: ref<Item_Record> = TweakDBInterface.GetItemRecord(vanilla);
    if !IsDefined(rec) {
      return "";
    }
    return LocKeyToString(rec.LocalizedDescription());
  }

  // Called from OnItemAddedToInventory so we swap the single stack that was just added
  // instead of iterating the whole inventory.
  public final static func SwapOnAdd(owner: ref<GameObject>, evt: ref<ItemAddedEvent>, cfg: ref<FieldMedicConfig>) -> Void {
    if !IsDefined(owner) || !IsDefined(evt) || !ItemID.IsValid(evt.itemID) {
      return;
    }
    let tdbid: TweakDBID = ItemID.GetTDBID(evt.itemID);
    let target: TweakDBID;
    if tdbid == t"Items.GenericJunkItem4" {
      target = t"Items.FieldMedic_MedicalGauze";
    } else if tdbid == t"Items.GenericPoorJunkItem1" {
      target = t"Items.FieldMedic_AntisepticDisinfectant";
    } else {
      return;
    }

    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(owner.GetGame());
    if !IsDefined(ts) {
      return;
    }
    let qty: Int32 = 1;
    if IsDefined(evt.itemData) {
      qty = evt.itemData.GetQuantity();
    }
    let removed: Bool = ts.RemoveItem(owner, evt.itemID, qty);
    let given: Bool = ts.GiveItemByTDBID(owner, target, qty);
    let targetRecOk: Bool = IsDefined(TweakDBInterface.GetItemRecord(target));
    LogChannel(n"DEBUG", s"[FieldMedic] SwapOnAdd \(qty)x \(TDBID.ToStringDEBUG(tdbid)) -> \(TDBID.ToStringDEBUG(target)) on \(owner.GetClassName()) [removed=\(removed) given=\(given) targetRecExists=\(targetRecOk)]");
  }

  public final static func SwapItem(owner: ref<GameObject>, fromID: TweakDBID, toID: TweakDBID, cfg: ref<FieldMedicConfig>) -> Void {
    if !IsDefined(owner) {
      return;
    }
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(owner.GetGame());
    if !IsDefined(ts) {
      return;
    }

    let items: array<wref<gameItemData>>;
    ts.GetItemList(owner, items);
    LogChannel(n"DEBUG", s"[FieldMedic] SwapItem scanning \(ArraySize(items)) items on \(owner.GetClassName()) for \(TDBID.ToStringDEBUG(fromID))");

    let i: Int32 = 0;
    while i < ArraySize(items) {
      let itemID: ItemID = items[i].GetID();
      if ItemID.GetTDBID(itemID) == fromID {
        let qty: Int32 = items[i].GetQuantity();
        let removed: Bool = ts.RemoveItem(owner, itemID, qty);
        let given: Bool = ts.GiveItemByTDBID(owner, toID, qty);
        let targetRecOk: Bool = IsDefined(TweakDBInterface.GetItemRecord(toID));
        LogChannel(n"DEBUG", s"[FieldMedic] Swapped \(qty)x \(TDBID.ToStringDEBUG(fromID)) -> \(TDBID.ToStringDEBUG(toID)) on \(owner.GetClassName()) [removed=\(removed) given=\(given) targetRecExists=\(targetRecOk)]");
      }
      i += 1;
    }
  }

  private final static func RollAndAdd(container: ref<gameLootContainerBase>, itemID: TweakDBID, chance: Int32, cfg: ref<FieldMedicConfig>) -> Void {
    if chance <= 0 {
      return;
    }

    let roll: Int32 = RandRange(0, 100);
    if roll >= chance {
      return;
    }

    let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(container.GetGame());
    if !IsDefined(transactionSystem) {
      return;
    }

    transactionSystem.GiveItemByTDBID(container, itemID, 1);

    if cfg.debugLog {
      LogChannel(n"DEBUG", s"[FieldMedic] Injected \(TDBID.ToStringDEBUG(itemID)) into container \(TDBID.ToStringDEBUG(container.GetContentAssignment()))");
    }
  }

  // Loot tables that ambient / body / medical drops flow through. Kept narrow to avoid
  // sprinkling bandages into unrelated crates.
  private final static func IsMedicalContainer(lootID: TweakDBID) -> Bool {
    switch lootID {
      case t"LootTables.LCL_body": return true;
      case t"LootTables.LCM_body": return true;
      case t"LootTables.LCS_body": return true;
      case t"LootTables.LRL_body": return true;
      case t"LootTables.LRM_body": return true;
      case t"LootTables.LRS_body": return true;
      case t"LootTables.LIL_body": return true;
      case t"LootTables.LCS_consumables": return true;
      case t"LootTables.LRS_consumables": return true;
      default: return false;
    }
  }

  // Janitorial / industrial containers where bleach and detergents plausibly sit.
  private final static func IsIndustrialContainer(lootID: TweakDBID) -> Bool {
    switch lootID {
      case t"LootTables.LCL_decorative": return true;
      case t"LootTables.LCM_decorative": return true;
      case t"LootTables.LCS_decorative": return true;
      case t"LootTables.LRL_decorative": return true;
      case t"LootTables.LRM_decorative": return true;
      case t"LootTables.LRS_decorative": return true;
      case t"LootTables.LIL_decorative": return true;
      default: return false;
    }
  }
}
