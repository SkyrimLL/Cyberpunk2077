// LimitedEncumbrance - by DeepBlueFrog
// Inspired by modNoEncumbrance - by rfuzzo

// 2.0 notes on Carry Capacity upgrades - https://game8.co/games/Cyberpunk-2077/archives/315020
// List of all perks - https://game8.co/games/Cyberpunk-2077/archives/309686

// - add support for Solo skill
// - add support for carry capacity shard
// - remove support for Pack Mule perk
// done - update code for carry capacity boosters consumables
// - update code for cyberware
// done - fix code for backpacks

// Known issues
// - Max capacity recalculated only when item is picked up or dropped. Find way to update on clothing equipped or unequipped.

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

public class LimitedEncumbranceTracking extends ScriptedPuppetPS {
  public let player: wref<PlayerPuppet>;

  public let config: ref<LimitedEncumbranceConfig>;

  public let modON: Bool;
  public let debugON: Bool;
  public let warningsON: Bool;
  public let newEncumbranceDisplayON: Bool;

  public let limitedCarryCapacity: Float;
  public let carryCapacityContribution: Float;
  public let carryCapacityOverride: Float;

  public let carryCapacityBase: Float; 
  public let carryCapacityBackpack: Float; 
  public let playerLevelMod: Float; 
  public let carryCapacityAlertTheshold: Int32;
  public let playerPerkMod: Float;
  public let encumbranceEquipmentBonus: Float;
  public let carryCapacityCapMod: Float;

  public let lastInventoryWeight: Float; 


  public func init(player: wref<PlayerPuppet>) -> Void {
    this.reset(player);
  }

  private func reset(player: wref<PlayerPuppet>) -> Void {
    this.player = player;

    this.refreshConfig();

    // ------------------ Edit these values to configure the mod

    // How much you can carry if you had only your backpack (no clothes)
    // this.carryCapacityBase = 25.0;

    // Contribution of player level to the carry capacity bonus. 
    // this.playerLevelMod = 0.5;   

    // Contribution of player Pack Mule perk to the base carry capacity. By default, (1.5 * base capacity, or 50% more). 
    // Simulates being able to function with larger/heavier backpacks
    // this.playerPerkMod = 1.5;   

    // Multiplier to the base Capacity to create a max value. By default, (2.0 * base capacity). Should be > 1.0.
    // this.carryCapacityCapMod = 2.0;   

    // Add a bonus to compensate for the weight of items already equiped. By default (0.8 * player equipment weight). Should be < 1.0 to account for pockets, or > 1.0 to add to encumbrance.  
    // this.encumbranceEquipmentBonus = 0.8; 

    // Toggle warnings when exceeding your carry capacity without powerlevel bonus
    // this.warningsON = true;

    // For developers only 
    // this.debugON = true;

    // Set to true to replace the default display of how much you are carrying, by a display of how much you CAN carry.
    // this.newEncumbranceDisplayON = true;

    // ------------------ End of Mod Options


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
    this.carryCapacityContribution = Cast<Float>(this.config.carryCapacityContribution) / 100.0;  
    this.playerLevelMod = Cast<Float>(this.config.playerLevelMod) / 100.0;  
    this.playerPerkMod = Cast<Float>(this.config.playerPerkMod) / 100.0;  
    this.carryCapacityCapMod = Cast<Float>(this.config.carryCapacityCapMod);  
    this.carryCapacityOverride = Cast<Float>(this.config.carryCapacityOverride);  
    this.encumbranceEquipmentBonus = Cast<Float>(this.config.encumbranceEquipmentBonus) / 100.0;
    this.carryCapacityAlertTheshold = this.config.carryCapacityAlertTheshold; 
    this.warningsON = this.config.warningsON;
    this.debugON = this.config.debugON;
    this.modON = this.config.modON;
    this.newEncumbranceDisplayON = this.config.newEncumbranceDisplayON;    
  }  

  public func getPlayerSlotItemWeight(object: ref<GameObject>, slot: TweakDBID) -> Float {
    let slotName: String = TweakDBInterface.GetAttachmentSlotRecord(slot).EntitySlotName();
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

  public func calculatePlayerClothMod() -> Float {
    let clothModWeight: Float;

    // Find weight of equiped clothing
    clothModWeight = 0.0;

    clothModWeight += this.GetClothSlotMods(gamedataEquipmentArea.OuterChest);  
    clothModWeight += this.GetClothSlotMods(gamedataEquipmentArea.InnerChest);  
    clothModWeight += this.GetClothSlotMods(gamedataEquipmentArea.Head);  
    clothModWeight += this.GetClothSlotMods(gamedataEquipmentArea.Face);  
    clothModWeight += this.GetClothSlotMods(gamedataEquipmentArea.Outfit);  

    if (this.debugON) {
      // LogChannel(n"DEBUG", "::: calculatePlayerClothMod  - clothModWeight: " + clothModWeight);
    }

    return clothModWeight;
  }

  // Check mods on item
  public func GetClothSlotMods(slotArea: gamedataEquipmentArea) -> Float {
      let equipmentSystem: ref<EquipmentSystem>; 
      let currentItem: ItemID;
      let currentItemTweakID: TweakDBID;
      let playerData: ref<EquipmentSystemPlayerData>;
      let itemData: ref<gameItemData>;
      let inventoryManager: wref<InventoryDataManagerV2>;
      let inventoryItem: InventoryItemData;

      let innerPart: InnerItemData;
      let innerPartID: ItemID;
      let innerPartTweakID: TweakDBID;
      let innerPartData: ref<gameItemData>;
      let innerPartEntityName: CName;
      let innerPartFriendlyName: String;

      let clothFriendlyName: String;

      let currentItemEntityName: CName;
      let currentItemFriendlyName: String;
      let clothModQuality: wref<Quality_Record>;
      let clothModQualityName: String;
      let clothModQualityValue: Int32;

      let clothSlotBonus: Float;
      let clothSlotMod: Float;

      let i: Int32;

      let clothMod: ItemID;
      let clothSlots: array<TweakDBID>;

      let equipmentData = EquipmentSystem.GetData(this.player);
      currentItem = equipmentData.GetActiveItem(slotArea);
 
      clothSlotBonus = 0.0;
      clothSlotMod = 0.0;

      // Improvements to research
      // - Detect multiple items are on the same slot
      // - Detect transmogrify outfit system is used
       
      // --
      // Alternate ways of getting the equiped item on that slot

      // equipmentSystem = EquipmentSystem.GetInstance(this.player);
      // currentItem = equipmentSystem.GetItemInEquipSlot(this.player, slotArea, 0);

      // --
      // playerData = equipmentSystem.GetPlayerData(this.player);
      // currentItem = playerData.GetItemInEquipSlot(slotArea, 0);


      itemData = RPGManager.GetItemData(this.player.GetGame(), this.player, currentItem);
      if IsDefined(itemData) {

        // --
        // friendlyName through inventoryManager comes up empty
      
        // inventoryManager = equipmentSystem.GetInventoryManager(this.player);
        // inventoryItem = inventoryManager.GetInventoryItemData(itemData);

        // friendlyName = InventoryItemData.GetGameItemData(inventoryItem).GetNameAsString();
        // localizedName = InventoryItemData.GetName(inventoryItem);
        // itemID = InventoryItemData.GetID(inventoryItem);
        // quality = InventoryItemData.GetComparedQuality(inventoryItem);
        // itemType = InventoryItemData.GetItemType(inventoryItem);
        // itemLevel = InventoryItemData.GetItemLevel(inventoryItem);
        // iconic = InventoryItemData.GetGameItemData(inventoryItem).GetStatValueByType(gamedataStatType.IsItemIconic) > 0.00;

        currentItemTweakID = ItemID.GetTDBID(itemData.GetID()); 
        currentItemEntityName = TweakDBInterface.GetItemRecord(currentItemTweakID).AppearanceName();
        currentItemFriendlyName = s"\(currentItemEntityName)";

        // --
        // GetName, FriendlNames come up empty for some reason ??!
        // currentItemFriendlyName = TweakDBInterface.GetItemRecord(currentItemTweakID).FriendlyName();

        // --
        // TDBID.ToStringDEBUG() is meant for debug and shouldn't be used this way
        // currentItemFriendlyName = TDBID.ToStringDEBUG(currentItemTweakID);

        // --
        // Record -> Entity name returns a generic name without possibility of distinction between types of backpacks
        // currentItemEntityName = TweakDBInterface.GetItemRecord(currentItemTweakID).EntityName();
        // currentItemFriendlyName = GetLocalizedItemNameByCName(currentItemEntityName);

        if (this.debugON) {
          // // LogChannel(n"DEBUG", "::: GetClothSlotMods  - checking item : " + InventoryItemData.GetGameItemData(inventoryItem).GetNameAsString() );
          // // LogChannel(n"DEBUG", "::: GetClothSlotMods  - checking item : " + itemData.GetNameAsString());
          // LogChannel(n"DEBUG", "::: GetClothSlotMods  - checking item : " + currentItemFriendlyName);  
          // LogChannel(n"DEBUG", "::: GetClothSlotMods  - item type : " + ToString(itemData.GetItemType()));
          // // LogChannel(n"DEBUG", "::: GetClothSlotMods  - item weight : " + ToString(itemData.GetStatValueByType(gamedataStatType.Weight)) );
        }

        // Detection of Backpacks cloth items from mods - ex: Items.sp0backpack0305
        // Assign larger values to backpack to compensate for influence of perks modifiers (multiplication by several factors lower than 1)


        // ----
        // Generic backpack and bag detection 
        // Lara Croft Unified Outfit (Archive XL - FemV) - https://www.nexusmods.com/cyberpunk2077/mods/12452

        if StrContains(currentItemFriendlyName,"backpack") {
          clothSlotMod = 30.0 ;
          if (this.debugON) {
            // LogChannel(n"DEBUG", "::: GetClothSlotMods  - fashion backpack bonus : " + clothSlotMod);
          }
        }

        if StrContains(currentItemFriendlyName,"bag") {
          clothSlotMod = 5.0  ;
          if (this.debugON) {
            // LogChannel(n"DEBUG", "::: GetClothSlotMods  - waistbag bonus : " + clothSlotMod);
          }
        }
                
        // ----
        // spawn0 - TRUE BAGS AND BACKPACKS - https://www.nexusmods.com/cyberpunk2077/mods/6616
        // Kabuki Bags and Backpacks - TweakXL ArchiveXL addon - https://www.nexusmods.com/cyberpunk2077/mods/11658?tab=description

        if StrContains(currentItemFriendlyName,"milbackpack") {
          clothSlotMod = 100.0 ;
          if (this.debugON) {
            // LogChannel(n"DEBUG", "::: GetClothSlotMods  - military backpack bonus : " + clothSlotMod);
          }
        }

        if StrContains(currentItemFriendlyName,"fashbackpack") {
          clothSlotMod = 30.0 ;
          if (this.debugON) {
            // LogChannel(n"DEBUG", "::: GetClothSlotMods  - fashion backpack bonus : " + clothSlotMod);
          }
        }

        if StrContains(currentItemFriendlyName,"bandoleer") {
          clothSlotMod = 20.0 ;

          if (this.debugON) {
            // LogChannel(n"DEBUG", "::: GetClothSlotMods  - bandoleer bonus : " + clothSlotMod);
          }
        }

        if StrContains(currentItemFriendlyName,"waistbag") {
          clothSlotMod = 5.0  ;
          if (this.debugON) {
            // LogChannel(n"DEBUG", "::: GetClothSlotMods  - waistbag bonus : " + clothSlotMod);
          }
        }

        // ----
        // OneSlowZZ Tactical Backpack - https://www.nexusmods.com/cyberpunk2077/mods/12031?tab=description

        if  (Equals(currentItemFriendlyName,"oneslowzz_zz_default_") || Equals(currentItemFriendlyName,"oneslowzz_zz_militech_") || Equals(currentItemFriendlyName,"oneslowzz_zz_arasaka_") || Equals(currentItemFriendlyName,"oneslowzz_zz_brown_") || Equals(currentItemFriendlyName,"oneslowzz_zz_gray_") || Equals(currentItemFriendlyName,"oneslowzz_zz_carbon_fiber_") || Equals(currentItemFriendlyName,"oneslowzz_zz_carbon_fiber_backpack_juice_")) {
          clothSlotMod = 40.0 ;
          if (this.debugON) {
            // LogChannel(n"DEBUG", "::: GetClothSlotMods  - fashion backpack bonus : " + clothSlotMod);
          }
        }


        clothSlotBonus = clothSlotBonus + clothSlotMod;

      } else {         
        // // LogChannel(n"DEBUG", "::: GetClothSlotMods  - Item undefined " );
      };

      return clothSlotBonus;
  }

  public func calculatePlayerEquipmentWeights() -> Float {
    let i: Int32;
    let slots: array<wref<AttachmentSlot_Record>>; 
    let slotName: String;
    let equipmentSystem: ref<EquipmentSystem>;
    let playerData: ref<EquipmentSystemPlayerData>;
    let equipmentWeight: Float;
    let slotWeight: Float;

    // Find weight of equiped clothing
    equipmentWeight = 0.0;
    slotWeight = 0.0;

    TweakDBInterface.GetCharacterRecord(this.player.GetRecordID()).AttachmentSlots(slots);
    i = 0;
    while i < ArraySize(slots) {
      slotName = TweakDBInterface.GetAttachmentSlotRecord(slots[i].GetID()).EntitySlotName(); 
        
      // // LogChannel(n"DEBUG", "::: calculatePlayerEquipmentWeights  - slot name: " + slotName + " - weight: " + slotWeight);

      if ( ( StrCmp(slotName, "Chest") == 0 ) || ( StrCmp(slotName, "Torso") == 0 ) || ( StrCmp(slotName, "Legs") == 0 ) || ( StrCmp(slotName, "Feet") == 0 ) || ( StrCmp(slotName, "Head") == 0 ) || ( StrCmp(slotName, "Eyes") == 0 ) || ( StrCmp(slotName, "Outfit") == 0 ) ) {
        equipmentWeight += this.getPlayerSlotItemWeight(this.player, slots[i].GetID());
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
    //   // LogChannel(n"DEBUG", "::: calculatePlayerEquipmentWeights  - Player is wearing outer torso item"  );
    // } else {
    //   // LogChannel(n"DEBUG", "::: calculatePlayerEquipmentWeights  - Player is NOT wearing outer torso item"  );      
    // }

    // Find weight of equipped weapons

    let currentItem: ItemID;
    let itemData: ref<gameItemData>;
    // let weaponWeight: Float;
    currentItem = equipmentSystem.GetItemInEquipSlot(this.player, gamedataEquipmentArea.Weapon, 0);
    itemData = RPGManager.GetItemData(this.player.GetGame(), this.player, currentItem);
    if IsDefined(itemData) {
      equipmentWeight +=  itemData.GetStatValueByType(gamedataStatType.Weight);
    }

    currentItem = equipmentSystem.GetItemInEquipSlot(this.player, gamedataEquipmentArea.Weapon, 1);
    itemData = RPGManager.GetItemData(this.player.GetGame(), this.player, currentItem);
    if IsDefined(itemData) {
      equipmentWeight +=  itemData.GetStatValueByType(gamedataStatType.Weight);
    }

    currentItem = equipmentSystem.GetItemInEquipSlot(this.player, gamedataEquipmentArea.Weapon, 2);
    itemData = RPGManager.GetItemData(this.player.GetGame(), this.player, currentItem);
    if IsDefined(itemData) {
      equipmentWeight +=  itemData.GetStatValueByType(gamedataStatType.Weight);
    }

    if (this.debugON) {
      // LogChannel(n"DEBUG", "::: calculatePlayerEquipmentWeights  - equipmentWeight: " + equipmentWeight);
    }

    return equipmentWeight;
  }

  public func calculatePlayerEquipmentBonus() -> Float {
    let i: Int32;
    let slots: array<wref<AttachmentSlot_Record>>; 
    let slotName: String;
    let equipmentSystem: ref<EquipmentSystem>;
    let playerData: ref<EquipmentSystemPlayerData>;
    let equipmentWeight: Float;
    let slotBonus: Float;

    // Find weight of equiped clothing
    equipmentWeight = 0.0;
    slotBonus = 0.0;

    TweakDBInterface.GetCharacterRecord(this.player.GetRecordID()).AttachmentSlots(slots);
    i = 0;
    while i < ArraySize(slots) {
      slotName = TweakDBInterface.GetAttachmentSlotRecord(slots[i].GetID()).EntitySlotName(); 
        
      // // LogChannel(n"DEBUG", "::: calculatePlayerInventoryWeights  - slot name: " + slotName + " - weight: " + slotWeight);

      if ( StrCmp(slotName, "Chest") == 0 ) {
        slotBonus += 2.0;
      }
      if ( StrCmp(slotName, "Legs") == 0 ) {
        slotBonus += 1.0;
      }
      if ( StrCmp(slotName, "Outfit") == 0 ) {
        slotBonus += 5.0;
      }
      i += 1;
    };

    return slotBonus;
  }

  public func GetCyberwareFromSkeletonSlots(cyberwareString: String) -> Float {
    let result: array<ref<Item_Record>>;
    let record: ref<Item_Record>;
    let equipSlots: array<SEquipSlot>;
    let i: Int32;
    let cyberwareType: CName;
    let hasCyberwareBuffs: Bool;
    let qualityCyberwareBuffs: Float;
    let equipmentSystem: ref<EquipmentSystem>;
    let playerData: ref<EquipmentSystemPlayerData>;
    let currentItem: ItemID;
    let itemData: ref<gameItemData>;
    let cyberwareQuality: gamedataQuality;

    equipmentSystem = EquipmentSystem.GetInstance(this.player);
    playerData = equipmentSystem.GetPlayerData(this.player);
    hasCyberwareBuffs = false;
    qualityCyberwareBuffs = 0.0;

    i = 0;
    while i < 2 {
      currentItem = equipmentSystem.GetItemInEquipSlot(this.player, gamedataEquipmentArea.MusculoskeletalSystemCW, i);
      itemData = RPGManager.GetItemData(this.player.GetGame(), this.player, currentItem);
      if IsDefined(itemData) {
        cyberwareType = TweakDBInterface.GetCName(ItemID.GetTDBID(itemData.GetID()) + t".cyberwareType", n"type");
        cyberwareQuality = RPGManager.GetItemDataQuality(itemData);

        if ( StrCmp(NameToString(cyberwareType), cyberwareString) == 0 ) {
          hasCyberwareBuffs = true;
        }
        
        if (this.debugON) {
          // LogChannel(n"DEBUG", "::: GetCyberwareFromSkeletonSlots  - MusculoskeletalSystemCW "+ ToString(i) +" : " + NameToString(cyberwareType));
        }
      }
      i += 1;
    };

    if (hasCyberwareBuffs) { 
      // LogChannel(n"DEBUG", "::: GetCyberwareFromSkeletonSlots  - " + cyberwareString + " Quality : " + ToString(cyberwareQuality));

      switch (cyberwareQuality) {
        case gamedataQuality.Common:
          qualityCyberwareBuffs = 1.0;
          break;
        case gamedataQuality.Uncommon:
          qualityCyberwareBuffs = 1.5;
          break;
        case gamedataQuality.Rare:
          qualityCyberwareBuffs = 2.0;
          break;
        case gamedataQuality.Epic:
          qualityCyberwareBuffs = 3.0;
          break;
        case gamedataQuality.Legendary:
          qualityCyberwareBuffs = 5.0;
          break;
      };      
    }


    if (this.debugON) {
      // LogChannel(n"DEBUG", "::: calculatePlayerInventoryWeights  - " + cyberwareString + " : " + ToString(hasCyberwareBuffs) + "");
    }
 
    return qualityCyberwareBuffs;
  }


  public func calculateLimitedEncumbrance() -> Void {
    let playerLevel: Float = GameInstance.GetStatsSystem(this.player.GetGame()).GetStatValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatType.Level);
    let playerEquipmentWeight = this.calculatePlayerEquipmentWeights();
    let playerClothSlot = this.calculatePlayerClothMod();
    let playerEquipmentBonus = this.calculatePlayerEquipmentBonus();
    let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(this.player.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;

    // Like a Feather - Body_Left_Perk_2_4 - 9 - No movement speed penalty with Shotguns, Light Machine Guns and Heavy Machine Guns.
    // Juggernaut - Body_Central_Perk_3_2 - 15 - When Adrenaline Rush is active: +20% movement speed, +10% damage
    // Unstoppable Force - Body_Central_Perk_3_4 - 15 - When Adrenaline Rush is active: Gain immunity to movement penalties and non-damaging status effects such as Knockdown, Blinding, etc.
    let playerLikeaFeatherLevel = playerDevSystem.GetPerkLevel(this.player, gamedataNewPerkType.Body_Left_Perk_2_4);
    let playerJuggernautLevel = playerDevSystem.GetPerkLevel(this.player, gamedataNewPerkType.Body_Central_Perk_3_2);
    let playerUnstoppableForceLevel = playerDevSystem.GetPerkLevel(this.player, gamedataNewPerkType.Body_Central_Perk_3_4);

    let statsSystem: ref<StatsSystem> = GameInstance.GetStatsSystem(this.player.GetGame());
 
    let playerPerks = 1.0;
    let playerPerksBonus = 1.0;
    // let ses: ref<StatusEffectSystem>;
    let hasCarryCapacityBoosterEffect: Bool;
    let qualityAgileJoints: Float;
    let qualityTitaniumBones: Float;

    this.refreshConfig();

    // Reduce base carry capacity
    // 1 Rifle + 2 Handguns + 1 long blade + 1 knife + coat + outer torso + inner torso + pants + shoes + headgear = about 30 weight
    // Carry capacity is default capacity (30) + a bonus based on player power level -> capped at 60 total to allow for combat/runnning

    // ses = GameInstance.GetStatusEffectSystem(this.player.GetGame()); 
    hasCarryCapacityBoosterEffect = StatusEffectSystem.ObjectHasStatusEffect(this.player, t"BaseStatusEffect.CarryCapacityBooster");  
    qualityAgileJoints = this.GetCyberwareFromSkeletonSlots("AgileJoints");
    qualityTitaniumBones = this.GetCyberwareFromSkeletonSlots("TitaniumInfusedBones");
    // TO DO: Check also for Scarab cyberware

    if (playerLikeaFeatherLevel > 0) {
      playerPerks += 1.0;
    }

    if (playerJuggernautLevel > 0) {
      playerPerks += 2.0;
    }

    if (playerUnstoppableForceLevel > 0) {
      playerPerks += 3.0;
    }

    if (qualityAgileJoints > 0.0) {
      playerPerks += 1.0;
      // playerPerksBonus += qualityAgileJoints;
    }

    if (qualityTitaniumBones > 0.0) {
      playerPerks += 1.0;
      playerPerksBonus += qualityTitaniumBones;
    }

    if (hasCarryCapacityBoosterEffect) {
      playerPerks += 1.0;
      playerPerksBonus += 2.0;
    }

    this.limitedCarryCapacity = this.carryCapacityBase + this.carryCapacityBackpack + ((this.carryCapacityBackpack + playerEquipmentBonus + playerClothSlot ) * (playerPerks + playerPerksBonus ) * this.playerPerkMod) + (playerLevel * this.playerLevelMod) + ( playerEquipmentWeight * this.encumbranceEquipmentBonus );

    if (this.debugON) {
    /*    
      LogChannel(n"DEBUG", "::: calculateLimitedEncumbrance - hasCarryCapacityBoosterEffect: " + ToString(hasCarryCapacityBoosterEffect)); 
      LogChannel(n"DEBUG", "::: calculateLimitedEncumbrance - playerLikeaFeatherLevel: " + ToString(playerLikeaFeatherLevel));
      LogChannel(n"DEBUG", "::: calculateLimitedEncumbrance - playerJuggernautLevel: " + ToString(playerJuggernautLevel));
      LogChannel(n"DEBUG", "::: calculateLimitedEncumbrance - playerUnstoppableForceLevel: " + ToString(playerUnstoppableForceLevel));

      LogChannel(n"DEBUG", "::: calculateLimitedEncumbrance"  ); 
      LogChannel(n"DEBUG", ":::       carryCapacityBase: '"+this.carryCapacityBase+"'"  ); 
      LogChannel(n"DEBUG", ":::     + carryCapacityBackpack: " + this.carryCapacityBackpack); 
      LogChannel(n"DEBUG", ":::     + ( ( playerEquipmentBonus: " + playerEquipmentBonus); 
      LogChannel(n"DEBUG", ":::           + playerClothSlot: '"+playerClothSlot+"'"  );
      LogChannel(n"DEBUG", ":::         ) * ( playerPerks: " + ToString(playerPerks));
      LogChannel(n"DEBUG", ":::               + playerPerksBonus: " + ToString(playerPerksBonus));
      LogChannel(n"DEBUG", ":::             ) ");
      LogChannel(n"DEBUG", ":::           * playerPerkMod: " + ToString(this.playerPerkMod));
      LogChannel(n"DEBUG", ":::         ) ");
      LogChannel(n"DEBUG", ":::       ) ");
      LogChannel(n"DEBUG", ":::     + ( playerLevel: '"+playerLevel+"'"  );
      LogChannel(n"DEBUG", ":::           * playerLevelMod: '"+this.playerLevelMod+"'"  );
      LogChannel(n"DEBUG", ":::       ) ");
      LogChannel(n"DEBUG", ":::     + ( playerEquipmentWeight: '"+playerEquipmentWeight+"'"  );
      LogChannel(n"DEBUG", ":::         * encumbranceEquipmentBonus: '"+this.encumbranceEquipmentBonus+"'"  );
      LogChannel(n"DEBUG", ":::       ) ");
      LogChannel(n"DEBUG", ":::     = limitedCarryCapacity: '"+this.limitedCarryCapacity+"'"  );
    */


      // LogChannel(n"DEBUG", ":::     <= carryCapacityCapMod: '"+this.carryCapacityCapMod+"'"  );

    }

  }

  public func getCarryCapacity() -> Float {
    let carryCapacity: Float; 
    let baseCarryCapacity: Float; 
    let limitedCarryCapacity: Float; 

    this.refreshConfig();

    baseCarryCapacity = GameInstance.GetStatsSystem(this.player.GetGame()).GetStatValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatType.CarryCapacity);
    limitedCarryCapacity = this.limitedCarryCapacity;

    carryCapacity = (baseCarryCapacity * this.carryCapacityContribution) + this.limitedCarryCapacity;

    if (carryCapacity >= this.carryCapacityCapMod ) {
      carryCapacity = this.carryCapacityCapMod;
    } 

    if (this.carryCapacityOverride > 0.0) {
      carryCapacity = this.carryCapacityOverride;
    }

    return carryCapacity;
  }

  public func printEncumbrance(playerWeight: Float) -> String {
    let carryCapacity: Float; 
    let encumbranceMsg: String;

    // this.player.m_curInventoryWeight
    carryCapacity = this.getCarryCapacity();

    if (this.newEncumbranceDisplayON) {
      return IntToString(Cast<Int32>(carryCapacity) - Cast<Int32>(playerWeight)) + " (" + IntToString(Cast<Int32>(carryCapacity)) + ")";
      } else {
      return IntToString(Cast<Int32>(playerWeight)) + " / " + IntToString(Cast<Int32>(carryCapacity)); 
      }

  }
}

 
