public abstract final class DiverseLootDarkFutureLootInjector {
  public final static func InjectContainer(container: ref<gameLootContainerBase>) -> Void {
    let lootID: TweakDBID;

    if !IsDefined(container) || container.IsQuest() || container.IsEmpty() {
      return;
    };

    lootID = container.GetContentAssignment();
    if DiverseLootDarkFutureLootInjector.IsFoodContainer(lootID) {
      DiverseLootDarkFutureLootInjector.AddFoodItems(container, 8.00);
    };

    if DiverseLootDarkFutureLootInjector.IsDrugContainer(lootID) {
      DiverseLootDarkFutureLootInjector.AddDrugItems(container, 12.00);
      DiverseLootDarkFutureLootInjector.AddDarkFutureOnlyDrugItems(container, 8.00);
    };

    if DiverseLootDarkFutureLootInjector.IsFactionEquipment(lootID) {
      DiverseLootDarkFutureLootInjector.AddRareFoodItems(container, 2.50);
      DiverseLootDarkFutureLootInjector.AddRareDrugItems(container, 2.00);
      DiverseLootDarkFutureLootInjector.AddDarkFutureOnlyDrugItems(container, 1.50);
    };
  }

  public final static func InjectPuppet(puppet: ref<NPCPuppet>) -> Void {
    let affiliation: String;

    if !IsDefined(puppet) || puppet.IsCrowd() {
      return;
    };

    affiliation = puppet.GetAffiliation();
    if DiverseLootDarkFutureLootInjector.IsFactionFoodAffiliation(affiliation) {
      DiverseLootDarkFutureLootInjector.AddRareFoodItems(puppet, 2.50);
    };

    if DiverseLootDarkFutureLootInjector.IsFactionDrugAffiliation(affiliation) {
      DiverseLootDarkFutureLootInjector.AddRareDrugItems(puppet, 2.00);
      DiverseLootDarkFutureLootInjector.AddDarkFutureOnlyDrugItems(puppet, 1.50);
    };
  }

  private final static func IsFoodContainer(lootID: TweakDBID) -> Bool {
    switch lootID {
      case t"LootTables.LCL_body": return true;
      case t"LootTables.LCL_decorative": return true;
      case t"LootTables.LCM_freezer": return true;
      case t"LootTables.LCM_decorative": return true;
      case t"LootTables.LCS_consumables": return true;
      case t"LootTables.LCS_decorative": return true;
      case t"LootTables.LCS_freezer": return true;
      case t"LootTables.LRL_body": return true;
      case t"LootTables.LRL_decorative": return true;
      case t"LootTables.LRM_freezer": return true;
      case t"LootTables.LRM_decorative": return true;
      case t"LootTables.LRS_consumables": return true;
      case t"LootTables.LRS_decorative": return true;
      case t"LootTables.LIL_body": return true;
      case t"LootTables.LIL_decorative": return true;
      case t"LootTables.LIM_freezer": return true;
      case t"LootTables.LIM_decorative": return true;
      case t"LootTables.LIS_consumables": return true;
      case t"LootTables.LIS_decorative": return true;
      case t"LootTables.LIS_freezer": return true;
      case t"LootTables.MCL_body": return true;
      case t"LootTables.MCL_decorative": return true;
      case t"LootTables.MCM_freezer": return true;
      case t"LootTables.MCM_decorative": return true;
      case t"LootTables.MCS_consumables": return true;
      case t"LootTables.MCS_decorative": return true;
      case t"LootTables.MCS_freezer": return true;
      case t"LootTables.MRL_body": return true;
      case t"LootTables.MRL_decorative": return true;
      case t"LootTables.MRM_freezer": return true;
      case t"LootTables.MRM_decorative": return true;
      case t"LootTables.MRS_consumables": return true;
      case t"LootTables.MRS_decorative": return true;
      case t"LootTables.MIL_body": return true;
      case t"LootTables.MIL_decorative": return true;
      case t"LootTables.MIM_freezer": return true;
      case t"LootTables.MIM_decorative": return true;
      case t"LootTables.MIS_consumables": return true;
      case t"LootTables.MIS_decorative": return true;
      case t"LootTables.HCL_body": return true;
      case t"LootTables.HCL_decorative": return true;
      case t"LootTables.HCM_freezer": return true;
      case t"LootTables.HCM_decorative": return true;
      case t"LootTables.HCS_consumables": return true;
      case t"LootTables.HCS_decorative": return true;
      case t"LootTables.HRL_body": return true;
      case t"LootTables.HRL_decorative": return true;
      case t"LootTables.HRM_freezer": return true;
      case t"LootTables.HRM_decorative": return true;
      case t"LootTables.HRS_consumables": return true;
      case t"LootTables.HRS_decorative": return true;
      case t"LootTables.HIL_body": return true;
      case t"LootTables.HIL_decorative": return true;
      case t"LootTables.HIM_freezer": return true;
      case t"LootTables.HIM_decorative": return true;
      case t"LootTables.HIS_consumables": return true;
    };

    return false;
  }

  private final static func IsDrugContainer(lootID: TweakDBID) -> Bool {
    switch lootID {
      case t"LootTables.LCM_chemicals": return true;
      case t"LootTables.LCM_ripperdoc": return true;
      case t"LootTables.LCS_consumables": return true;
      case t"LootTables.LCS_first_aid": return true;
      case t"LootTables.LRM_chemicals": return true;
      case t"LootTables.LRM_ripperdoc": return true;
      case t"LootTables.LRS_consumables": return true;
      case t"LootTables.LRS_first_aid": return true;
      case t"LootTables.LIM_chemicals": return true;
      case t"LootTables.LIM_ripperdoc": return true;
      case t"LootTables.LIS_consumables": return true;
      case t"LootTables.LIS_first_aid": return true;
      case t"LootTables.MCM_chemicals": return true;
      case t"LootTables.MCM_ripperdoc": return true;
      case t"LootTables.MCS_consumables": return true;
      case t"LootTables.MCS_first_aid": return true;
      case t"LootTables.MRM_chemicals": return true;
      case t"LootTables.MRM_ripperdoc": return true;
      case t"LootTables.MRS_consumables": return true;
      case t"LootTables.MRS_first_aid": return true;
      case t"LootTables.MIM_chemicals": return true;
      case t"LootTables.MIM_ripperdoc": return true;
      case t"LootTables.MIS_consumables": return true;
      case t"LootTables.MIS_first_aid": return true;
      case t"LootTables.HCM_chemicals": return true;
      case t"LootTables.HCM_ripperdoc": return true;
      case t"LootTables.HCS_consumables": return true;
      case t"LootTables.HCS_first_aid": return true;
      case t"LootTables.HRM_chemicals": return true;
      case t"LootTables.HRM_ripperdoc": return true;
      case t"LootTables.HRS_consumables": return true;
      case t"LootTables.HRS_first_aid": return true;
      case t"LootTables.HIM_chemicals": return true;
      case t"LootTables.HIM_ripperdoc": return true;
      case t"LootTables.HIS_consumables": return true;
      case t"LootTables.HIS_first_aid": return true;
    };

    return false;
  }

  private final static func IsFactionEquipment(lootID: TweakDBID) -> Bool {
    switch lootID {
      case t"LootTables.TygerClaws_LGM_equipment": return true;
      case t"LootTables.TygerClaws_LGS_equipment": return true;
      case t"LootTables.TygerClaws_MGM_equipment": return true;
      case t"LootTables.TygerClaws_MGS_equipment": return true;
      case t"LootTables.Maelstrom_LGM_equipment": return true;
      case t"LootTables.Maelstrom_LGS_equipment": return true;
      case t"LootTables.Maelstrom_MGM_equipment": return true;
      case t"LootTables.Sixthstreet_LGS_equipment": return true;
      case t"LootTables.Animals_LGM_equipment": return true;
      case t"LootTables.Animals_MGS_equipment": return true;
      case t"LootTables.Wraiths_LGS_equipment": return true;
      case t"LootTables.Valentinos_LGM_equipment": return true;
      case t"LootTables.Valentinos_LGS_equipment": return true;
    };

    return false;
  }

  private final static func IsFactionFoodAffiliation(affiliation: String) -> Bool {
    switch affiliation {
      case "SixthStreet": return true;
      case "Aldecaldos": return true;
      case "Animals": return true;
      case "Arasaka": return true;
      case "KangTao": return true;
      case "Maelstrom": return true;
      case "Militech": return true;
      case "Moxes": return true;
      case "NCPD": return true;
      case "Scavengers": return true;
      case "TraumaTeam": return true;
      case "TygerClaws": return true;
      case "Valentinos": return true;
      case "VoodooBoys": return true;
      case "Wraiths": return true;
      case "KurtzMilitia": return true;
      case "Barghest": return true;
    };

    return false;
  }

  private final static func IsFactionDrugAffiliation(affiliation: String) -> Bool {
    switch affiliation {
      case "SixthStreet": return true;
      case "Animals": return true;
      case "Maelstrom": return true;
      case "Scavengers": return true;
      case "TygerClaws": return true;
      case "Valentinos": return true;
      case "VoodooBoys": return true;
      case "Wraiths": return true;
      case "KurtzMilitia": return true;
      case "Barghest": return true;
    };

    return false;
  }

  private final static func AddFoodItems(target: ref<GameObject>, chance: Float) -> Void {
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.GoodQualityDrink2", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.GoodQualityDrink4", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityDrink4", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityDrink5", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityDrink6", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityDrink7", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityDrink8", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityDrink9", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityDrink10", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityDrink1", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityDrink2", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityDrink5", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityDrink6", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityDrink7", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood5", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood7", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood8", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood9", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood11", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood12", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood13", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood14", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood15", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood16", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood17", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood18", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood19", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood20", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood21", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood22", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood23", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood24", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood25", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood26", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood27", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood28", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood3", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood4", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood7", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood12", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood13", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood17", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood18", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood19", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood20", chance);
  }

  private final static func AddDrugItems(target: ref<GameObject>, chance: Float) -> Void {
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood6", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood11", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood14", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood15", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.BlackLaceV0", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.BlackLaceV1", chance);
  }

  private final static func AddRareFoodItems(target: ref<GameObject>, chance: Float) -> Void {
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityDrink6", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood5", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood4", chance);
  }

  private final static func AddRareDrugItems(target: ref<GameObject>, chance: Float) -> Void {
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.LowQualityFood6", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.MediumQualityFood11", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"Items.BlackLaceV0", chance);
  }

  private final static func AddDarkFutureOnlyDrugItems(target: ref<GameObject>, chance: Float) -> Void {
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"DarkFutureItem.NerveRestoreDrug", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"DarkFutureItem.Glitter", chance);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"DarkFutureItem.AddictionTreatmentDrug", chance * 0.50);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"DarkFutureItem.EndotrisineDrug", chance * 0.25);
    DiverseLootDarkFutureLootInjector.TryGiveItem(target, t"DarkFutureItem.ImmunosuppressantDrug", chance * 0.25);
  }

  private final static func TryGiveItem(target: ref<GameObject>, itemTDBID: TweakDBID, chance: Float) -> Void {
    let itemRecord: ref<Item_Record>;

    if !IsDefined(target) || RandRangeF(0.00, 100.00) > chance {
      return;
    };

    itemRecord = TweakDBInterface.GetItemRecord(itemTDBID);
    if !IsDefined(itemRecord) {
      return;
    };

    GameInstance.GetTransactionSystem(target.GetGame()).GiveItem(target, ItemID.FromTDBID(itemTDBID), 1);
  }
}

@wrapMethod(gameLootContainerBase)
protected cb func OnInventoryFilledEvent(evt: ref<ContainerFilledEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  DiverseLootDarkFutureLootInjector.InjectContainer(this);
  return result;
}

@wrapMethod(NPCPuppet)
protected func OnIncapacitated() -> Void {
  wrappedMethod();
  DiverseLootDarkFutureLootInjector.InjectPuppet(this);
}
