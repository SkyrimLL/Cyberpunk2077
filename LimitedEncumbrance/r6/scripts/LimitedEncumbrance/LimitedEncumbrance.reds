// LimitedEncumbrance - by DeepBlueFrog
// Inspired by modNoEncumbrance - by rfuzzo

/*
For redscript mod developers

:: Replaced methods
@replaceMethod(PlayerPuppet) public final func EvaluateEncumbrance() -> Void 
@replaceMethod(MenuHubGameController) protected cb func OnPlayerMaxWeightUpdated(value: Int32) -> Bool 
@replaceMethod(MenuHubGameController) public final func HandlePlayerWeightUpdated(opt dropQueueWeight: Float) -> Void 
@replaceMethod(SubMenuPanelLogicController) public final func HandlePlayerWeightUpdated(value: Float, maxWeight: Int32) -> Void 
@replaceMethod(SubMenuPanelLogicController) public final func HandlePlayerMaxWeightUpdated(value: Int32, curInventoryWeight: Float) -> Void 
@replaceMethod(VendorHubMenuGameController) protected cb func OnPlayerWeightUpdated(value: Float) -> Bool 

:: Added methods which can cause incompatibilities

:: Added fields
@addField(GameObject) public let m_limitedEncumbranceTracking: ref<LimitedEncumbranceTracking>;
@addField(PlayerPuppet) public let m_limitedEncumbranceTracking: ref<LimitedEncumbranceTracking>;
@addField(SubMenuPanelLogicController) public let m_player: wref<PlayerPuppet>;

:: New classes
public class LimitedEncumbranceTracking
*/

public class LimitedEncumbranceTracking {
  public let player: wref<PlayerPuppet>;
  public let debugON: Bool;
  public let warningsON: Bool;
  public let newEncumbranceDisplayON: Bool;

  public let carryCapacityBase: Float; 
  public let limitedCarryCapacity: Float;
  public let playerPowerlevelMod: Float;
  public let playerPackMuleMod: Float;
  public let carryCapacityCapMod: Float;
  public let encumbranceEquipmentBonus: Float;
  public let lastInventoryWeight: Float; 


  public func init(player: wref<PlayerPuppet>) -> Void {
    this.player = player;
    this.reset();
  }

  private func reset() -> Void {
    // ------------------ Edit these values to configure the mod

    // Toggle warnings when exceeding your carry capacity without powerlevel bonus
    this.warningsON = true;

    // Set to true to replace the default display of how much you are carrying, by a display of how much you CAN carry.
    this.newEncumbranceDisplayON = true;

    // How much you can carry if you had only your backpack (no clothes)
    this.carryCapacityBase = 25.0;

    // Contribution of player powerlevel to the carry capacity bonus. By default, 1/10 of playerPowerlevel.
    this.playerPowerlevelMod = 0.1;   

    // Contribution of player Pack Mule perk to the base carry capacity. By default, (1.5 * base capacity, or 50% more). 
    // Simulates being able to function with larger/heavier backpacks
    this.playerPackMuleMod = 1.5;   

    // Multiplier to the base Capacity to create a max value. By default, (2.0 * base capacity). Should be > 1.0.
    this.carryCapacityCapMod = 2.0;   

    // Add a bonus to compensate for the weight of items already equiped. By default (0.8 * player equipment weight). Should be < 1.0 to account for pockets, or > 1.0 to add to encumbrance.  
    this.encumbranceEquipmentBonus = 0.8; 

    // ------------------ End of Mod Options

    // For developers only 
    this.debugON = false;
    // Internal variable - gets recalculated all the time - no needto edit
    this.limitedCarryCapacity = 30.0;

  }

  public func getPlayerSlotItemWeight(object: ref<GameObject>, slot: TweakDBID) -> Float {
    let slotName: String = TweakDBInterface.GetAttachmentSlotRecord(slot).EntitySlotName();

    // Can't coerce ref<ItemObject> to ref<gameItemData>
    // Figure out the link between gameItemData and ItemObject
    let itemObj: ref<ItemObject> = GameInstance.GetTransactionSystem(this.player.GetGame()).GetItemInSlot(object as PlayerPuppet, slot);

    let itemWeight: Float;

    itemWeight = 0.0;

    if !IsDefined(itemObj) {
      // LogItems("Item in slot: " + slotName + " NULL ");
      return itemWeight;
    };

    let weight: Float;
    // inkTextRef.SetText(this.m_itemWeightText, FloatToStringPrec(weight, 2));
    // LogItems("Item in slot: " + slotName + " : " + TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemObj.GetItemID())).FriendlyName() + " - Weight: " + FloatToStringPrec(weight, 2));

    itemWeight = RPGManager.GetItemWeight(itemObj.GetItemData()) * Cast<Float>(itemObj.GetItemData().GetQuantity());

    return itemWeight;
  }

  public exec func calculatePlayerInventoryWeights() -> Float {
    let i: Int32;
    let slots: array<wref<AttachmentSlot_Record>>; 
    let equipmentWeight: Float;

    equipmentWeight = 0.0;

    TweakDBInterface.GetCharacterRecord(this.player.GetRecordID()).AttachmentSlots(slots);
    i = 0;
    while i < ArraySize(slots) {
      equipmentWeight += 0.2 + this.getPlayerSlotItemWeight(this.player, slots[i].GetID());
      i += 1;
    };

    return equipmentWeight;
  }

  public func calculateLimitedEncumbrance() -> Void {
    let playerPowerLevel = GameInstance.GetStatsSystem(this.player.GetGame()).GetStatValue(Cast(this.player.GetEntityID()), gamedataStatType.PowerLevel);
    let playerInventoryWeight = this.calculatePlayerInventoryWeights();
    let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(this.player.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    let playerPackMuleLevel = playerDevSystem.GetPerkLevel(this.player, gamedataPerkType.Athletics_Area_01_Perk_2);
    let playerPackMuleMod = 1.0;

    if (this.debugON) {
      LogChannel(n"DEBUG", "::: EvaluateEncumbrance - Pack Mule level: '"+playerPackMuleLevel+"'"  );
    }

    // Reduce base carry capacity
    // 1 Rifle + 2 Handguns + 1 long blade + 1 knife + coat + outer torso + inner torso + pants + shoes + headgear = about 30 weight
    // Carry capacity is default capacity (30) + a bonus based on player power level -> capped at 60 total to allow for combat/runnning

    if (playerPackMuleLevel > 0) {
      playerPackMuleMod = this.playerPackMuleMod;
    }

    this.limitedCarryCapacity = (this.carryCapacityBase * playerPackMuleMod) + (playerPowerLevel * this.playerPowerlevelMod);


    if (playerInventoryWeight > 0.0) {
      this.limitedCarryCapacity = this.limitedCarryCapacity + ( playerInventoryWeight * this.encumbranceEquipmentBonus );
    }

    if (this.limitedCarryCapacity >= (this.carryCapacityBase * this.carryCapacityCapMod ) ) {
      this.limitedCarryCapacity = (this.carryCapacityBase * this.carryCapacityCapMod );
    } 
  }

  public func printEncumbrance(playerWeight: Float) -> String {
    let encumbranceMsg: String;
    // this.player.m_curInventoryWeight

    if (this.newEncumbranceDisplayON) {
      return ToString(Cast<Int32>(this.limitedCarryCapacity) - Cast<Int32>(playerWeight)) + " (" + ToString(Cast<Int32>(this.limitedCarryCapacity)) + ")";
      } else {
      return ToString(Cast<Int32>(playerWeight)) + " / " + ToString(Cast<Int32>(this.limitedCarryCapacity)); 
      }

  }
}

@addField(GameObject)
public let m_limitedEncumbranceTracking: ref<LimitedEncumbranceTracking>;

@addField(PlayerPuppet)
public let m_limitedEncumbranceTracking: ref<LimitedEncumbranceTracking>;

// -- PlayerPuppet
@replaceMethod(PlayerPuppet)
// Overload method from - https://codeberg.org/adamsmasher/cyberpunk/src/branch/master/cyberpunk/player/player.swift#L1974
public final func EvaluateEncumbrance() -> Void {
    let carryCapacity: Float; 
    let hasExhaustedEffect: Bool;
    let hasEncumbranceEffect: Bool;
    let isApplyingRestricted: Bool;
    let exhaustedEffectID: TweakDBID;
    let overweightEffectID: TweakDBID;
    let ses: ref<StatusEffectSystem>;
    let playerPowerLevel = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast(this.GetEntityID()), gamedataStatType.PowerLevel);

    // set up tracker if it doesn't exist
    if !IsDefined(this.m_limitedEncumbranceTracking) {
      this.m_limitedEncumbranceTracking = new LimitedEncumbranceTracking();
      this.m_limitedEncumbranceTracking.init(this);
    } else {
      this.m_limitedEncumbranceTracking.reset();
    };

    if this.m_curInventoryWeight < 0.00 {
      this.m_curInventoryWeight = 0.00;
    };

    if (this.m_curInventoryWeight!=this.m_limitedEncumbranceTracking.lastInventoryWeight) {
      this.m_limitedEncumbranceTracking.lastInventoryWeight = this.m_curInventoryWeight;

      // Only calculate effect if inventory weight actually changed

      ses = GameInstance.GetStatusEffectSystem(this.GetGame());
      exhaustedEffectID = t"BaseStatusEffect.PlayerExhausted";
      overweightEffectID = t"BaseStatusEffect.Encumbered";
      hasExhaustedEffect = ses.HasStatusEffect(this.GetEntityID(), exhaustedEffectID);
      hasEncumbranceEffect = ses.HasStatusEffect(this.GetEntityID(), overweightEffectID);
      isApplyingRestricted = StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"NoEncumbrance");

      // carryCapacity = GameInstance.GetStatsSystem(this.GetGame()).GetStatValue(Cast<StatsObjectID>(this.GetEntityID()), gamedataStatType.CarryCapacity);

      this.m_limitedEncumbranceTracking.calculateLimitedEncumbrance();

      carryCapacity = this.m_limitedEncumbranceTracking.limitedCarryCapacity;

      if (this.m_limitedEncumbranceTracking.debugON) { this.SetWarningMessage("Current weight:" + FloatToString(this.m_curInventoryWeight) + " - " + "Carry capacity:" + FloatToString(carryCapacity) + " - " + "playerPowerLevel:" + FloatToString(playerPowerLevel) ); }

      if this.m_curInventoryWeight > carryCapacity && !isApplyingRestricted {
        // this.SetWarningMessage(GetLocalizedText("UI-Notifications-Overburden"));

      } else { 
        if (this.m_curInventoryWeight >= this.m_limitedEncumbranceTracking.carryCapacityBase) {
          if (this.m_limitedEncumbranceTracking.warningsON) { 
            let message: String = StrReplace(LimitedEncumbranceText.HEAVY(), "%VAL%", ToString(Cast<Int32>(carryCapacity) - Cast<Int32>(this.m_curInventoryWeight)));
  
            this.SetWarningMessage(message); }
        } 
      }

      if this.m_curInventoryWeight > carryCapacity && !hasEncumbranceEffect && !isApplyingRestricted {
        if (this.m_limitedEncumbranceTracking.warningsON) { this.SetWarningMessage(LimitedEncumbranceText.OVERWEIGHT()); }
        ses.ApplyStatusEffect(this.GetEntityID(), overweightEffectID);
      } else {
        if this.m_curInventoryWeight <= carryCapacity && hasEncumbranceEffect || hasEncumbranceEffect && isApplyingRestricted {
          if (this.m_limitedEncumbranceTracking.debugON) { this.SetWarningMessage(LimitedEncumbranceText.LIGHTER()); }
          ses.RemoveStatusEffect(this.GetEntityID(), overweightEffectID);
        };
      };


      if (hasEncumbranceEffect) {
          if (this.m_limitedEncumbranceTracking.debugON) { this.SetWarningMessage("Current weight:" + FloatToString(this.m_curInventoryWeight) + " - " + "Carry capacity:" + FloatToString(carryCapacity) + " - " + "hasEncumbranceEffect ON"); }

          if this.m_curInventoryWeight <= carryCapacity && hasEncumbranceEffect {
            if (this.m_limitedEncumbranceTracking.debugON) { this.SetWarningMessage(LimitedEncumbranceText.LIGHTER()); }
            ses.RemoveStatusEffect(this.GetEntityID(), overweightEffectID);
          };
      } else {
          // if (debugON) { this.SetWarningMessage("hasEncumbranceEffect OFF"); }
      }

      // Why isn't this working to display the adjusted carry Capacity?
      GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).SetInt(GetAllBlackboardDefs().UI_PlayerStats.weightMax, Cast<Int32>(carryCapacity), true);

      // This works to display new inventory weight
      GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).SetFloat(GetAllBlackboardDefs().UI_PlayerStats.currentInventoryWeight, this.m_curInventoryWeight, true);
    }

  }



// in public class MenuHubGameController extends gameuiMenuGameController 

@replaceMethod(MenuHubGameController)

  protected cb func OnPlayerMaxWeightUpdated(value: Int32) -> Bool {
    let gameInstance: GameInstance = this.m_player.GetGame();
    let carryCapacity: Int32 = Cast<Int32>(GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(this.m_player.GetEntityID()), gamedataStatType.CarryCapacity));
    let playerPowerLevel = GameInstance.GetStatsSystem(this.m_player.GetGame()).GetStatValue(Cast(this.m_player.GetEntityID()), gamedataStatType.PowerLevel);

    this.m_subMenuCtrl.m_player = this.m_player;

    // set up tracker if it doesn't exist
    if !IsDefined(this.m_player.m_limitedEncumbranceTracking) {
      this.m_player.m_limitedEncumbranceTracking = new LimitedEncumbranceTracking();
      this.m_player.m_limitedEncumbranceTracking.init(this.m_player);
    } else {
      this.m_player.m_limitedEncumbranceTracking.reset();
    };    

    this.m_subMenuCtrl.HandlePlayerMaxWeightUpdated(carryCapacity, this.m_player.m_curInventoryWeight);
    if RoundF(this.m_player.m_curInventoryWeight) >= carryCapacity {
      this.PlayLibraryAnimation(n"overburden");
    };
  }

@replaceMethod(MenuHubGameController)

  public final func HandlePlayerWeightUpdated(opt dropQueueWeight: Float) -> Void {
    let gameInstance: GameInstance = this.m_player.GetGame();
    let carryCapacity: Int32 = Cast<Int32>(GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(this.m_player.GetEntityID()), gamedataStatType.CarryCapacity));
    let playerPowerLevel = GameInstance.GetStatsSystem(this.m_player.GetGame()).GetStatValue(Cast(this.m_player.GetEntityID()), gamedataStatType.PowerLevel);

    this.m_subMenuCtrl.m_player = this.m_player;

    // set up tracker if it doesn't exist
    if !IsDefined(this.m_player.m_limitedEncumbranceTracking) {
      this.m_player.m_limitedEncumbranceTracking = new LimitedEncumbranceTracking();
      this.m_player.m_limitedEncumbranceTracking.init(this.m_player);
    };     

    this.m_subMenuCtrl.HandlePlayerWeightUpdated(this.m_player.m_curInventoryWeight - dropQueueWeight, carryCapacity);
  }


// in public class SubMenuPanelLogicController extends PlayerStatsUIHolder 
@addField(SubMenuPanelLogicController)
public let m_player: wref<PlayerPuppet>;

@replaceMethod(SubMenuPanelLogicController)

  public final func HandlePlayerWeightUpdated(value: Float, maxWeight: Int32) -> Void {
    // let player: wref<GameObject> = GetPlayer(this.GetGameInstance());
    //let playerPowerLevel = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast(player.GetEntityID()), gamedataStatType.PowerLevel);
    // let player: wref<GameObject> =  super.m_player; 
       
    this.m_player.m_limitedEncumbranceTracking.calculateLimitedEncumbrance(); 

    inkTextRef.SetText(this.m_weightValue, this.m_player.m_limitedEncumbranceTracking.printEncumbrance(value));
    // this.PlaySound(n"Item", n"OnBuy");
    GameObject.PlaySoundEvent(this.m_player, n"ui_menu_onpress");
  }

@replaceMethod(SubMenuPanelLogicController)

  public final func HandlePlayerMaxWeightUpdated(value: Int32, curInventoryWeight: Float) -> Void {
    // let player: wref<GameObject> = GetPlayer(this.GetGameInstance());
    // let playerPowerLevel = GameInstance.GetStatsSystem(player.GetGame()).GetStatValue(Cast(player.GetEntityID()), gamedataStatType.PowerLevel); 
       
    this.m_player.m_limitedEncumbranceTracking.calculateLimitedEncumbrance(); 

    // inkTextRef.SetText(this.m_weightValue, ToString(Cast<Int32>(curInventoryWeight)) + "/" + ToString(value));
    inkTextRef.SetText(this.m_weightValue, this.m_player.m_limitedEncumbranceTracking.printEncumbrance(curInventoryWeight));
    // this.PlaySound(n"Item", n"OnBuy");
    // GameObject.PlaySoundEvent(this.m_player, n"ui_menu_perk_buy");
  }


// public class VendorHubMenuGameController extends gameuiMenuGameController {
@replaceMethod(VendorHubMenuGameController)

  protected cb func OnPlayerWeightUpdated(value: Float) -> Bool {
    let gameInstance: GameInstance = this.m_player.GetGame();
    // let carryCapacity: Int32 = Cast<Int32>(GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(this.m_player.GetEntityID()), gamedataStatType.CarryCapacity));
       
    this.m_player.m_limitedEncumbranceTracking.calculateLimitedEncumbrance();

    // inkTextRef.SetText(this.m_playerWeight, IntToString(RoundF(this.m_player.m_curInventoryWeight)) + " / " + carryCapacity);
    inkTextRef.SetText(this.m_playerWeight, this.m_player.m_limitedEncumbranceTracking.printEncumbrance(this.m_player.m_curInventoryWeight));


    // this.PlaySound(n"Item", n"OnBuy");
    // GameObject.PlaySoundEvent(this.m_player, n"ui_menu_perk_buy");


  }