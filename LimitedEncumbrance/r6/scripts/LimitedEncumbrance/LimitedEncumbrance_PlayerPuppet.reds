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

    _playerPuppetPS.InitLimitedEncumbranceSystem(playerPuppet);

    wrappedMethod(playerPuppet);
}

// -- PlayerPuppet
@replaceMethod(PlayerPuppet)
// Overload method from - https://codeberg.org/adamsmasher/cyberpunk/src/branch/master/cyberpunk/player/player.swift#L1974
public final func EvaluateEncumbrance(opt isLootBroken: Bool) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();

    let carryCapacity: Float; 
    let carryCapacityDelta: Int32; 
    let hasExhaustedEffect: Bool;
    let hasEncumbranceEffect: Bool;
    let isApplyingRestricted: Bool;
    let exhaustedEffectID: TweakDBID;
    let overweightEffectID: TweakDBID;
    let ses: ref<StatusEffectSystem>;

    // Refresh config in case of changes to Mod Settings menu
    _playerPuppetPS.m_limitedEncumbranceTracking.refreshConfig();

    if (_playerPuppetPS.m_limitedEncumbranceTracking.modON) {
      if this.m_curInventoryWeight < 0.00 {
        this.m_curInventoryWeight = 0.00;
      };

      if (this.m_curInventoryWeight!=_playerPuppetPS.m_limitedEncumbranceTracking.lastInventoryWeight) {
        _playerPuppetPS.m_limitedEncumbranceTracking.lastInventoryWeight = this.m_curInventoryWeight;

        // Only calculate effect if inventory weight actually changed

        ses = GameInstance.GetStatusEffectSystem(this.GetGame());
        exhaustedEffectID = t"BaseStatusEffect.PlayerExhausted";
        overweightEffectID = t"BaseStatusEffect.Encumbered";
        hasExhaustedEffect = ses.HasStatusEffect(this.GetEntityID(), exhaustedEffectID);
        hasEncumbranceEffect = ses.HasStatusEffect(this.GetEntityID(), overweightEffectID);
        isApplyingRestricted = StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"NoEncumbrance");

        _playerPuppetPS.m_limitedEncumbranceTracking.calculateLimitedEncumbrance();

        carryCapacity = _playerPuppetPS.m_limitedEncumbranceTracking.getCarryCapacity();

        if this.m_curInventoryWeight > carryCapacity && !isApplyingRestricted {
          // this.SetWarningMessage(GetLocalizedText("UI-Notifications-Overburden"));

        } else { 
          // if (this.m_curInventoryWeight >= _playerPuppetPS.m_limitedEncumbranceTracking.carryCapacityBase) {
          carryCapacityDelta = Cast<Int32>(carryCapacity) - Cast<Int32>(this.m_curInventoryWeight);

          if (carryCapacityDelta <= _playerPuppetPS.m_limitedEncumbranceTracking.carryCapacityAlertTheshold) {
            if (_playerPuppetPS.m_limitedEncumbranceTracking.warningsON) { 
              let message: String = StrReplace(LimitedEncumbranceText.HEAVY(), "%VAL%", ToString(carryCapacityDelta));
    
              this.SetWarningMessage(message); }
          } 
        }

        if this.m_curInventoryWeight > carryCapacity && !hasEncumbranceEffect && !isApplyingRestricted && !isLootBroken  {
          if (_playerPuppetPS.m_limitedEncumbranceTracking.warningsON) { this.SetWarningMessage(LimitedEncumbranceText.OVERWEIGHT()); }
          ses.ApplyStatusEffect(this.GetEntityID(), overweightEffectID);
        } else {
          if this.m_curInventoryWeight <= carryCapacity && hasEncumbranceEffect || hasEncumbranceEffect && isApplyingRestricted && !isLootBroken  {
            if (_playerPuppetPS.m_limitedEncumbranceTracking.debugON) { this.SetWarningMessage(LimitedEncumbranceText.LIGHTER()); }
            ses.RemoveStatusEffect(this.GetEntityID(), overweightEffectID);
          };
        };


        if (hasEncumbranceEffect) {
            if (_playerPuppetPS.m_limitedEncumbranceTracking.debugON) { 
              // LogChannel(n"DEBUG", "Current weight:" + FloatToString(this.m_curInventoryWeight) + " - " + "Carry capacity:" + FloatToString(carryCapacity) + " - " + "hasEncumbranceEffect ON"  ); 
            }

            if (_playerPuppetPS.m_limitedEncumbranceTracking.debugON) { this.SetWarningMessage("Current weight:" + FloatToString(this.m_curInventoryWeight) + " - " + "Carry capacity:" + FloatToString(carryCapacity) + " - " + "hasEncumbranceEffect ON"); }

            if this.m_curInventoryWeight <= carryCapacity  {
              if (_playerPuppetPS.m_limitedEncumbranceTracking.debugON) { this.SetWarningMessage(LimitedEncumbranceText.LIGHTER()); }
              ses.RemoveStatusEffect(this.GetEntityID(), overweightEffectID);
            };
        } else {
            // if (debugON) { this.SetWarningMessage("hasEncumbranceEffect OFF"); }
        }

        // Why isn't this working to display the adjusted carry Capacity?
        // GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).SetInt(GetAllBlackboardDefs().UI_PlayerStats.weightMax, Cast<Int32>(carryCapacity), true);

        // This works to display new inventory weight
        GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).SetFloat(GetAllBlackboardDefs().UI_PlayerStats.currentInventoryWeight, this.m_curInventoryWeight, true);
      }
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
        // ses.ApplyStatusEffect(this.GetEntityID(), t"BaseStatusEffect.PlayerExhausted");
        // ses.ApplyStatusEffect(this.GetEntityID(), t"BaseStatusEffect.BreathingHeavy");
        // AnimationControllerComponent.SetAnimWrapperWeight(this, n"BeatenLocomotion", 1.00); 
      } else {
        if this.m_curInventoryWeight <= carryCapacity && hasEncumbranceEffect || hasEncumbranceEffect && isApplyingRestricted {
          ses.RemoveStatusEffect(this.GetEntityID(), overweightEffectID);
          // ses.RemoveStatusEffect(this.GetEntityID(), t"BaseStatusEffect.BreathingHeavy");
          // ses.RemoveStatusEffect(this.GetEntityID(), t"BaseStatusEffect.PlayerExhausted");
          // AnimationControllerComponent.SetAnimWrapperWeight(this, n"BeatenLocomotion", 0.00);
        };
      };
      GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).SetFloat(GetAllBlackboardDefs().UI_PlayerStats.currentInventoryWeight, this.m_curInventoryWeight, true);

    }

  }

