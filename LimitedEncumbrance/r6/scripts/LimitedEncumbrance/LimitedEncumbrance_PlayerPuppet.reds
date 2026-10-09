@addField(PlayerPuppetPS)
public let m_limitedEncumbranceTracking: ref<LimitedEncumbranceTracking>;

// Event for delayed encumbrance evaluation to ensure weight is updated
public class EvaluateEncumbranceDelayedEvent extends Event {
}

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
    let _encumbranceTracker: ref<LimitedEncumbranceTracking>;

    // LogChannel(n"DEBUG", "::::: PlayerAttachedCallback: PLAYER ATTACHED ");
    _playerPuppetPS.InitLimitedEncumbranceSystem(playerPuppet);
    
    // Schedule weight calculation after a delay to ensure player equipment is fully loaded
    _encumbranceTracker = _playerPuppetPS.m_limitedEncumbranceTracking;
    if IsDefined(_encumbranceTracker) {
      _encumbranceTracker.ScheduleInitialWeightCheck();
    }

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

    // Only skip for a zero equipment weight during the initial load window, not on every call
    // (a player with nothing equipped/no equipped weapon legitimately has 0 equipment weight)
    if (_encumbranceTracker.needsInitialWeightCheck && _encumbranceTracker.calculatePlayerEquipmentWeights() == 0.0) {
      return;
    }

    if (_encumbranceTracker.modON) {

      if this.m_curInventoryWeight < 0.00 {
        this.m_curInventoryWeight = 0.00;
      };

      _encumbranceTracker.currentInventoryWeight = this.m_curInventoryWeight;

      // applyWeightEffects already handles weapon slot checks internally (forces carry capacity
      // to 0 and applies/removes Encumbered effect + warning when slots are exceeded)
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

@addMethod(PlayerPuppet)
  protected cb func OnInitialWeightCheckEvent(evt: ref<InitialWeightCheckEvent>) -> Bool {
    if IsDefined(evt.tracker) {
      // Lift the load-window guard regardless of equipment weight so later calls always evaluate
      evt.tracker.needsInitialWeightCheck = false;
      this.EvaluateEncumbrance();
      if (evt.tracker.debugON) {
        evt.tracker.showDebugMessage("[LimitedEncumbrance] Initial weight check executed after player load delay");
      }
    }
    return true;
  }

@addMethod(PlayerPuppet)
  protected cb func OnEvaluateEncumbranceDelayedEvent(evt: ref<EvaluateEncumbranceDelayedEvent>) -> Bool {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();
    let _encumbranceTracker: ref<LimitedEncumbranceTracking>;
    
    _encumbranceTracker = _playerPuppetPS.m_limitedEncumbranceTracking;
    if IsDefined(_encumbranceTracker) && _encumbranceTracker.debugON {
      _encumbranceTracker.showDebugMessage("[LimitedEncumbrance] OnEvaluateEncumbranceDelayedEvent fired - evaluating encumbrance and weapon slots");
    }
    
    // Evaluate weight effects and weapon slots together
    this.EvaluateEncumbrance();
    
    return true;
  }

@wrapMethod(PlayerPuppet) 
  protected cb func OnItemChangedEvent(evt: ref<ItemChangedEvent>) -> Bool {
    let itemData: ref<gameItemData>;
    let maxAmount: Float;
    let itemType: gamedataItemType = gamedataItemType.Invalid;
    let eqSystem: wref<EquipmentSystem> = GameInstance.GetScriptableSystemsContainer(this.GetGame()).Get(n"EquipmentSystem") as EquipmentSystem;
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();
    let _encumbranceTracker: ref<LimitedEncumbranceTracking>;

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

    // Re-evaluate encumbrance for ANY item change (picks up, drops, looting, etc)
    // Use QueueEvent which auto-dispatches to OnEvaluateEncumbranceDelayedEvent handler by naming convention
    _encumbranceTracker = _playerPuppetPS.m_limitedEncumbranceTracking;
    if IsDefined(_encumbranceTracker) && _encumbranceTracker.modON {
      let delayedEvalEvent: ref<EvaluateEncumbranceDelayedEvent> = new EvaluateEncumbranceDelayedEvent();
      if _encumbranceTracker.debugON {
        _encumbranceTracker.showDebugMessage("[LimitedEncumbrance] Queueing delayed encumbrance evaluation from OnItemChangedEvent");
      }
      this.QueueEvent(delayedEvalEvent);
    }

    wrappedMethod(evt);
}

// Additional handler for looting from containers/ground - ensures evaluation even if OnItemChangedEvent is batched
@wrapMethod(PlayerPuppet)
  protected cb func OnItemAddedToInventory(evt: ref<ItemAddedEvent>) -> Bool {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();
    let _encumbranceTracker: ref<LimitedEncumbranceTracking>;
    let itemData: ref<gameItemData>;

    // Re-evaluate encumbrance when item is added (looting, picking up, etc)
    // Use QueueEvent which auto-dispatches to OnEvaluateEncumbranceDelayedEvent handler by naming convention
    _encumbranceTracker = _playerPuppetPS.m_limitedEncumbranceTracking;
    if IsDefined(_encumbranceTracker) && _encumbranceTracker.modON {
      let delayedEvalEvent: ref<EvaluateEncumbranceDelayedEvent> = new EvaluateEncumbranceDelayedEvent();
      if _encumbranceTracker.debugON {
        _encumbranceTracker.showDebugMessage("[LimitedEncumbrance] Queueing delayed encumbrance evaluation from OnItemAddedToInventory");
      }
      this.QueueEvent(delayedEvalEvent);
    }

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
 