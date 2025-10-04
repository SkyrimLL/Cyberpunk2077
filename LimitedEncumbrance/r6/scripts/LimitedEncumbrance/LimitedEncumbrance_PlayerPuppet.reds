@addField(PlayerPuppetPS)
public let m_limitedEncumbranceTracking: ref<LimitedEncumbranceTracking>;

@addMethod(PlayerPuppetPS)
  private final func InitLimitedEncumbranceSystem(playerPuppet: ref<GameObject>) -> Void {
    // set up tracker if it doesn't exist
    if !IsDefined(this.m_limitedEncumbranceTracking) {
      // LogChannel(n"DEBUG", "::::: INIT NEW LIMITED ENCUMBRANCE OBJECT ");
      this.m_limitedEncumbranceTracking = new LimitedEncumbranceTracking();
      this.m_limitedEncumbranceTracking.init(playerPuppet as PlayerPuppet);

    } else {
      // Reset if already exists (in case of changed default values)
      // LogChannel(n"DEBUG", "::::: RESET EXISTING LIMITED ENCUMBRANCE OBJECT ");
      this.m_limitedEncumbranceTracking.reset(playerPuppet as PlayerPuppet);
    };
  }

// Bridge between PlayerPuppet and PlayerPuppetPS - Set up Player Puppet Persistent State when game loads (player is attached)
@wrapMethod(PlayerPuppet)
  private final func PlayerAttachedCallback(playerPuppet: ref<GameObject>) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();

    // LogChannel(n"DEBUG", "::::: PlayerAttachedCallback: PLAYER ATTACHED ");
    _playerPuppetPS.InitLimitedEncumbranceSystem(playerPuppet);
    this.EvaluateEncumbrance();

    wrappedMethod(playerPuppet);
}

// -- PlayerPuppet
@replaceMethod(PlayerPuppet)
// Overload method from - https://codeberg.org/adamsmasher/cyberpunk/src/branch/master/cyberpunk/player/player.swift#L1974
public final func EvaluateEncumbrance(opt isLootBroken: Bool) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();
    let _encumbranceTracker: ref<LimitedEncumbranceTracking>;

    let carryCapacity: Float; 
    let carryCapacityDelta: Int32; 
    let hasExhaustedEffect: Bool;
    let hasEncumbranceEffect: Bool;
    let isApplyingRestricted: Bool;
    let exhaustedEffectID: TweakDBID;
    let overweightEffectID: TweakDBID;
    let ses: ref<StatusEffectSystem>;


    // Refresh config in case of changes to Mod Settings menu
    _encumbranceTracker = _playerPuppetPS.m_limitedEncumbranceTracking;
    _encumbranceTracker.refreshConfig();

    // Do not apply weight effect if player equipment weight is 0 - likely at start of game
    if (_encumbranceTracker.calculatePlayerEquipmentWeights() == 0.0) {
      return;
    }

    if (_encumbranceTracker.modON) {

      if this.m_curInventoryWeight < 0.00 {
        this.m_curInventoryWeight = 0.00;
      };

      _encumbranceTracker.currentInventoryWeight = this.m_curInventoryWeight;

      _encumbranceTracker.applyWeightEffects(isLootBroken);

    } else {
      // Vanilla code

      if this.m_curInventoryWeight < 0.00 {
        this.m_curInventoryWeight = 0.00;
      };
      ses = GameInstance.GetStatusEffectSystem(this.GetGame());
      overweightEffectID = t"BaseStatusEffect.Encumbered";
      hasEncumbranceEffect = ses.HasStatusEffect(this.GetEntityID(), overweightEffectID);
      isApplyingRestricted = StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"NoEncumbrance");
      carryCapacity = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatType.CarryCapacity);
      if this.m_curInventoryWeight > carryCapacity && !isApplyingRestricted && !isLootBroken {
        this.SetWarningMessage(GetLocalizedText("UI-Notifications-Overburden"));
      };
      if this.m_curInventoryWeight > carryCapacity && !hasEncumbranceEffect && !isApplyingRestricted && !isLootBroken {
        ses.ApplyStatusEffect(this.GetEntityID(), overweightEffectID);
      } else {
        if this.m_curInventoryWeight <= carryCapacity && hasEncumbranceEffect || hasEncumbranceEffect && isApplyingRestricted {
          ses.RemoveStatusEffect(this.GetEntityID(), overweightEffectID);
        };
      };
      GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).SetFloat(GetAllBlackboardDefs().UI_PlayerStats.currentInventoryWeight, this.m_curInventoryWeight, true);

    }

  }

@wrapMethod(PlayerPuppet) 
  protected cb func OnItemChangedEvent(evt: ref<ItemChangedEvent>) -> Bool {
    let itemData: ref<gameItemData>;
    let maxAmount: Float;
    let itemType: gamedataItemType = gamedataItemType.Invalid;
    let eqSystem: wref<EquipmentSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGame()).Get(n"EquipmentSystem") as EquipmentSystem;

    if IsDefined(eqSystem) {
      itemData = evt.itemData;
      maxAmount = itemData.GetStatValueByType(gamedataStatType.Quantity);
      if IsDefined(itemData) {
        itemType = itemData.GetItemType();
      };

      if (Equals(itemType, gamedataItemType.Con_Edible) || Equals(itemType, gamedataItemType.Con_LongLasting)) {
        if itemData.HasTag(n"Alcohol") || itemData.HasTag(n"LongLasting") || itemData.HasTag(n"Drink") || itemData.HasTag(n"Food") { 
          GameObject.PlaySoundEvent(this, n"ui_menu_item_consumable_generic");
        };
      };
    };

    wrappedMethod(evt);
}

// -- PlayerPuppet
// @replaceMethod(EquipmentBaseTransition) 
//   protected final const func HandleWeaponEquip(scriptInterface: ref<StateGameScriptInterface>, stateContext: ref<StateContext>, stateMachineInstanceData:  
//     autoRefillRatio = statSystem.GetStatValue(Cast<StatsObjectID>(itemObject.GetEntityID()), gamedataStatType.MagazineAutoRefill);
//     if autoRefillRatio > 0.00 {
//       // DBF - Hijack auto-refill for certain ammo type
//       // (t"Ammo.HandgunAmmo")
//       // (t"Ammo.ShotgunAmmo")
//       // (t"Ammo.RifleAmmo")
//       // (t"Ammo.SniperRifleAmmo")
//       if ItemID.GetTDBID(WeaponObject.GetAmmoType(itemObject)) = t"Ammo.HandgunAmmo" {
//         magazineCapacity = WeaponObject.GetMagazineCapacity(itemObject);
//         autoRefillEvent = new SetAmmoCountEvent();
//         autoRefillEvent.ammoTypeID = WeaponObject.GetAmmoType(itemObject);
//         autoRefillEvent.count = Cast<Uint32>(Cast<Float>(magazineCapacity) * autoRefillRatio);
//         itemObject.QueueEvent(autoRefillEvent);  
//       }
 