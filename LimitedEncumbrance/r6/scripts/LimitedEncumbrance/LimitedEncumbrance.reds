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

  public let config: ref<LimitedEncumbranceConfig>;

  public let debugON: Bool;
  public let warningsON: Bool;
  public let newEncumbranceDisplayON: Bool;

  public let limitedCarryCapacity: Float;

  public let carryCapacityBase: Float; 
  public let carryCapacityBackpack: Float; 
  public let playerLevelMod: Float;
  public let playerPackMuleMod: Float;
  public let encumbranceEquipmentBonus: Float;
  public let carryCapacityCapMod: Float;

  public let lastInventoryWeight: Float; 


  public func init(player: wref<PlayerPuppet>) -> Void {
    this.player = player;
    this.reset();
  }

  private func reset() -> Void {

    this.refreshConfig();

    // ------------------ Edit these values to configure the mod

    // How much you can carry if you had only your backpack (no clothes)
    // this.carryCapacityBase = 25.0;

    // Contribution of player level to the carry capacity bonus. 
    // this.playerLevelMod = 0.5;   

    // Contribution of player Pack Mule perk to the base carry capacity. By default, (1.5 * base capacity, or 50% more). 
    // Simulates being able to function with larger/heavier backpacks
    // this.playerPackMuleMod = 1.5;   

    // Multiplier to the base Capacity to create a max value. By default, (2.0 * base capacity). Should be > 1.0.
    // this.carryCapacityCapMod = 2.0;   

    // Add a bonus to compensate for the weight of items already equiped. By default (0.8 * player equipment weight). Should be < 1.0 to account for pockets, or > 1.0 to add to encumbrance.  
    // this.encumbranceEquipmentBonus = 0.8; 

    // Toggle warnings when exceeding your carry capacity without powerlevel bonus
    // this.warningsON = true;

    // Set to true to replace the default display of how much you are carrying, by a display of how much you CAN carry.
    // this.newEncumbranceDisplayON = true;

    // ------------------ End of Mod Options

    // For developers only 
    this.debugON = false;
    // Internal variable - gets recalculated all the time - no need to edit
    this.limitedCarryCapacity = 30.0;

  }

  public func refreshConfig() -> Void {
    this.config = new LimitedEncumbranceConfig();
    this.invalidateCurrentState();
  }

  public func invalidateCurrentState() -> Void {
    this.carryCapacityBase = Cast<Float>(this.config.carryCapacityBase);
    this.carryCapacityBackpack= Cast<Float>(this.config.carryCapacityBackpack);
    this.playerLevelMod = Cast<Float>(this.config.playerLevelMod) / 100.0; 
    this.playerPackMuleMod = Cast<Float>(this.config.playerPackMuleMod) / 100.0;  
    this.carryCapacityCapMod = Cast<Float>(this.config.carryCapacityCapMod);  
    this.encumbranceEquipmentBonus = Cast<Float>(this.config.encumbranceEquipmentBonus) / 100.0;
    this.warningsON = this.config.warningsON;
    this.newEncumbranceDisplayON = this.config.newEncumbranceDisplayON;    
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
    let slotName: String;
    let equipmentSystem: ref<EquipmentSystem>;
    let playerData: ref<EquipmentSystemPlayerData>;
    let equipmentWeight: Float;
    let slotWeight: Float;

    equipmentWeight = 0.0;
    slotWeight = 0.0;

    TweakDBInterface.GetCharacterRecord(this.player.GetRecordID()).AttachmentSlots(slots);
    i = 0;
    while i < ArraySize(slots) {
      slotName = TweakDBInterface.GetAttachmentSlotRecord(slots[i].GetID()).EntitySlotName();
      slotWeight = this.getPlayerSlotItemWeight(this.player, slots[i].GetID());
        
      // LogChannel(n"DEBUG", "::: calculatePlayerInventoryWeights  - slot name: " + slotName + " - weight: " + slotWeight);

      if ( ( StrCmp(slotName, "Chest") == 0 ) || ( StrCmp(slotName, "Torso") == 0 ) || ( StrCmp(slotName, "Legs") == 0 ) || ( StrCmp(slotName, "Feet") == 0 ) || ( StrCmp(slotName, "Head") == 0 ) || ( StrCmp(slotName, "Eyes") == 0 ) || ( StrCmp(slotName, "Outfit") == 0 ) ) {
        equipmentWeight += slotWeight;

      }
      i += 1;
    };

    equipmentSystem = EquipmentSystem.GetInstance(this.player);
    playerData = equipmentSystem.GetPlayerData(this.player);
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.Head, 0));
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.Face, 0));
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.OuterChest, 0));
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.InnerChest, 0));
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.Legs, 0));
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.Feet, 0));
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.Outfit, 0));
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.Weapon, 0));
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.Weapon, 1));
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.Weapon, 2));
    // ArrayPush(this.m_equippedItems, playerData.GetItemInEquipSlot(gamedataEquipmentArea.QuickSlot, 0));

    // if (ItemID.IsValid(playerData.GetItemInEquipSlot(gamedataEquipmentArea.OuterChest, 0))) { 
    //   LogChannel(n"DEBUG", "::: calculatePlayerInventoryWeights  - Player is wearing outer torso item"  );
    // } else {
    //   LogChannel(n"DEBUG", "::: calculatePlayerInventoryWeights  - Player is NOT wearing outer torso item"  );      
    // }

    LogChannel(n"DEBUG", "::: calculatePlayerInventoryWeights  - equipmentWeight: " + equipmentWeight);

    return equipmentWeight;
  }

  public func calculateLimitedEncumbrance() -> Void {
    let playerLevel: Float = GameInstance.GetStatsSystem(this.player.GetGame()).GetStatValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatType.Level);
    let playerInventoryWeight = this.calculatePlayerInventoryWeights();
    let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(this.player.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;
    let playerPackMuleLevel = playerDevSystem.GetPerkLevel(this.player, gamedataPerkType.Athletics_Area_01_Perk_2);
    let playerPackMuleMod = 1.0;

    // Reduce base carry capacity
    // 1 Rifle + 2 Handguns + 1 long blade + 1 knife + coat + outer torso + inner torso + pants + shoes + headgear = about 30 weight
    // Carry capacity is default capacity (30) + a bonus based on player power level -> capped at 60 total to allow for combat/runnning

    if (playerPackMuleLevel > 0) {
      playerPackMuleMod = this.playerPackMuleMod;
    }

    this.limitedCarryCapacity = this.carryCapacityBase + (this.carryCapacityBackpack * playerPackMuleMod) + (playerLevel * this.playerLevelMod);


    if (playerInventoryWeight > 0.0) {
      this.limitedCarryCapacity = this.limitedCarryCapacity + ( playerInventoryWeight * this.encumbranceEquipmentBonus );
    }

    if (this.limitedCarryCapacity >= this.carryCapacityCapMod ) {
      this.limitedCarryCapacity = this.carryCapacityCapMod;
    } 

    if (this.debugON) {
      LogChannel(n"DEBUG", "::: EvaluateEncumbrance - carryCapacityBase: '"+this.carryCapacityBase+"'"  );
      LogChannel(n"DEBUG", "::: EvaluateEncumbrance - Pack Mule level: '"+playerPackMuleLevel+"'"  );
      LogChannel(n"DEBUG", "::: EvaluateEncumbrance - playerLevel: '"+playerLevel+"'"  );
      LogChannel(n"DEBUG", "::: EvaluateEncumbrance - playerLevelMod: '"+this.playerLevelMod+"'"  );
      LogChannel(n"DEBUG", "::: EvaluateEncumbrance - playerInventoryWeight: '"+playerInventoryWeight+"'"  );
      LogChannel(n"DEBUG", "::: EvaluateEncumbrance - encumbranceEquipmentBonus: '"+this.encumbranceEquipmentBonus+"'"  );
      LogChannel(n"DEBUG", "::: EvaluateEncumbrance - carryCapacityCapMod: '"+this.carryCapacityCapMod+"'"  );
      LogChannel(n"DEBUG", "::: EvaluateEncumbrance - limitedCarryCapacity: '"+this.limitedCarryCapacity+"'"  );
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
      // GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).SetInt(GetAllBlackboardDefs().UI_PlayerStats.weightMax, Cast<Int32>(carryCapacity), true);

      // This works to display new inventory weight
      GameInstance.GetBlackboardSystem(this.GetGame()).Get(GetAllBlackboardDefs().UI_PlayerStats).SetFloat(GetAllBlackboardDefs().UI_PlayerStats.currentInventoryWeight, this.m_curInventoryWeight, true);
    }

  }



// in public class MenuHubGameController extends gameuiMenuGameController 

@replaceMethod(MenuHubGameController)

  protected cb func OnPlayerMaxWeightUpdated(value: Int32) -> Bool {
    let gameInstance: GameInstance = this.m_player.GetGame();
    let carryCapacity: Int32 = Cast<Int32>(GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(this.m_player.GetEntityID()), gamedataStatType.CarryCapacity));

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
       
    this.m_player.m_limitedEncumbranceTracking.calculateLimitedEncumbrance(); 

    inkTextRef.SetText(this.m_weightValue, this.m_player.m_limitedEncumbranceTracking.printEncumbrance(value));
    GameObject.PlaySoundEvent(this.m_player, n"ui_menu_onpress");
  }

@replaceMethod(SubMenuPanelLogicController)

  public final func HandlePlayerMaxWeightUpdated(value: Int32, curInventoryWeight: Float) -> Void {
 
    this.m_player.m_limitedEncumbranceTracking.calculateLimitedEncumbrance(); 

    inkTextRef.SetText(this.m_weightValue, this.m_player.m_limitedEncumbranceTracking.printEncumbrance(curInventoryWeight));

  }


// public class VendorHubMenuGameController extends gameuiMenuGameController {
@replaceMethod(VendorHubMenuGameController)

  protected cb func OnPlayerWeightUpdated(value: Float) -> Bool {
    let gameInstance: GameInstance = this.m_player.GetGame();

    this.m_player.m_limitedEncumbranceTracking.calculateLimitedEncumbrance();

    inkTextRef.SetText(this.m_playerWeight, this.m_player.m_limitedEncumbranceTracking.printEncumbrance(this.m_player.m_curInventoryWeight));

  }