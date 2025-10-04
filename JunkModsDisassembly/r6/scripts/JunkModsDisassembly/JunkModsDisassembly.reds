/*
For redscript mod developers

:: Replaced methods
@replaceMethod(PlayerPuppet) public final func EvaluateEncumbrance() -> Void 

:: Added fields

:: New classes
public class RepeatDisassemblyTracking 
*/  

public class DisassemblyListItem extends ScriptedPuppetPS {

  let itemRecordID: TweakDBID;  
  let itemType: gamedataItemType;
  let itemQuality: RepeatDisassemblyQuality;
  let itemQuantity: Int32;
  let itemSaved: wref<gameItemData>;
  let itemCanDisassemble: Bool;

}

public class RepeatDisassemblyTracking extends ScriptedPuppetPS {
  public let player: wref<PlayerPuppet>; 
 
  public let disassemblyList: array<ref<DisassemblyListItem>>;
  public let itemQualityMax: RepeatDisassemblyQuality;

  public let repeatDisassemblyRepeatMode: RepeatDisassemblyRepeatModes;
  public let repeatDisassemblyQualityMode: RepeatDisassemblyQualityModes;
  public let repeatDisassemblyQualityMax: RepeatDisassemblyQuality;

  public let config: ref<RepeatDisassemblyConfig>;

  public let modON: Bool;  
  public let disassembleJunkON: Bool;  

  public let debugON: Bool;
  public let warningsON: Bool;   


  public func init(player: wref<PlayerPuppet>) -> Void {
    this.reset(player);
  }

  private func reset(player: wref<PlayerPuppet>) -> Void {
    this.player = player;

    this.refreshConfig();

    // ------------------ Edit these values to configure the mod
    // Toggle warnings when exceeding your carry capacity without powerlevel bonus
    // this.warningsON = true;

    // ------------------ End of Mod Options

    // For developers only 
    // this.debugON = true;

  }

  public func refreshConfig() -> Void {
    this.config = new RepeatDisassemblyConfig(); 
    this.invalidateCurrentState();
  }

  public func invalidateCurrentState() -> Void {    

    // Pull from config

    // enum RepeatDisassemblyRepeatModes {
    //   SelectionOnly = 0,
    //   AllButOne = 1,
    //   All = 2 
    // }

    // enum RepeatDisassemblyQualityModes {
    //   OneOfEach = 0,
    //   TopQualityOnly = 1,
    //   All = 2 
    // }

    this.disassembleJunkON = this.config.disassembleJunkON;

    this.repeatDisassemblyRepeatMode = this.config.repeatDisassemblyRepeatMode;
    this.repeatDisassemblyQualityMode = this.config.repeatDisassemblyQualityMode;
    this.repeatDisassemblyQualityMax = this.config.repeatDisassemblyQualityMax;

    this.warningsON = this.config.warningsON;
    this.debugON = this.config.debugON;
    this.modON = this.config.modON;  
  } 


  // ------------------ End of Mod Init
  
  public func createItem(_id: TweakDBID, _itemType: gamedataItemType, _itemQuality: gamedataQuality, _itemQuantity: Int32, _itemData: wref<gameItemData>) -> ref<DisassemblyListItem> {

    let Item = new DisassemblyListItem();
    Item.itemRecordID = _id;  
    Item.itemType = _itemType; 
    Item.itemQuantity = _itemQuantity;
    Item.itemSaved = _itemData;
    Item.itemCanDisassemble = true;

    // Mapping to my own quality scale because CDPR's quality enum is not ordered by increasing quality levels :(
    if Equals(_itemQuality, gamedataQuality.Common) {
      Item.itemQuality = RepeatDisassemblyQuality.Common;
    } else {
      if Equals(_itemQuality, gamedataQuality.Uncommon)  {
        Item.itemQuality = RepeatDisassemblyQuality.Uncommon;
      } else {
        if Equals(_itemQuality, gamedataQuality.Rare)   {
          Item.itemQuality = RepeatDisassemblyQuality.Rare;
        } else {
          if Equals(_itemQuality, gamedataQuality.Epic)   {
            Item.itemQuality = RepeatDisassemblyQuality.Epic;
          } else {
            if Equals(_itemQuality, gamedataQuality.Legendary)  {
              Item.itemQuality = RepeatDisassemblyQuality.Legendary;
            } else {
              if Equals(_itemQuality, gamedataQuality.Iconic)  {
                Item.itemQuality = RepeatDisassemblyQuality.Iconic;
              };
              };
            };
          };
        };
      };

    return Item;
  }

  public func lookupDisassemblyItem(_id: TweakDBID) -> Bool { 

    for thisItem in this.disassemblyList { 
      if (Equals(thisItem.itemRecordID, _id)) { 
        return true;
      }  
    };
 
    return false;
  }

  public func getDisassemblyItem(_id: TweakDBID) -> ref<DisassemblyListItem> { 

    for thisItem in this.disassemblyList { 
      if (Equals(thisItem.itemRecordID, _id)) { 
        return thisItem;
      }  
    }; 
  }

  public func addDisassemblyItem(_id: TweakDBID, _itemType: gamedataItemType, _itemQuality: gamedataQuality, _itemQuantity: Int32, _itemData: wref<gameItemData>) {   

    if (!this.lookupDisassemblyItem(_id)) {
      ArrayPush(this.disassemblyList, this.createItem(_id, _itemType, _itemQuality, _itemQuantity, _itemData));
      //this.showDebugMessage(">>>  " + ToString(ArraySize(this.disassemblyList)) + " items in disassembly list.");

    } else {
      let Item = this.getDisassemblyItem(_id);

      Item.itemQuantity += _itemQuantity;
    } 

    if Equals(_itemQuality, gamedataQuality.Common) && Equals(this.itemQualityMax, RepeatDisassemblyQuality.Common) {
      this.itemQualityMax = RepeatDisassemblyQuality.Common;
    } else {
      if Equals(_itemQuality, gamedataQuality.Uncommon) && (EnumInt(this.itemQualityMax) < EnumInt(RepeatDisassemblyQuality.Uncommon)) {
        this.itemQualityMax = RepeatDisassemblyQuality.Uncommon;
      } else {
        if Equals(_itemQuality, gamedataQuality.Rare) && (EnumInt(this.itemQualityMax) < EnumInt(RepeatDisassemblyQuality.Rare)) {
          this.itemQualityMax = RepeatDisassemblyQuality.Rare;
        } else {
          if Equals(_itemQuality, gamedataQuality.Epic) && (EnumInt(this.itemQualityMax) < EnumInt(RepeatDisassemblyQuality.Epic)) {
            this.itemQualityMax = RepeatDisassemblyQuality.Epic;
          } else {
            if Equals(_itemQuality, gamedataQuality.Legendary) && (EnumInt(this.itemQualityMax) < EnumInt(RepeatDisassemblyQuality.Legendary)) {
              this.itemQualityMax = RepeatDisassemblyQuality.Legendary;
            } else {
              if Equals(_itemQuality, gamedataQuality.Iconic) && (EnumInt(this.itemQualityMax) < EnumInt(RepeatDisassemblyQuality.Iconic)) {
                this.itemQualityMax = RepeatDisassemblyQuality.Iconic;
              };
              };
            };
          };
        };
      };

  }

  public func removeDisassemblyItem(_id: TweakDBID) -> Bool {   

    if (this.lookupDisassemblyItem(_id)) {
      let thisItem = this.getDisassemblyItem(_id);

      // RemoveAllButOne = 0,
      // RemoveAll = 1 

      if (Equals(this.repeatDisassemblyRepeatMode, RepeatDisassemblyRepeatModes.RemoveAllButOne)) && (thisItem.itemQuantity>1) {
        thisItem.itemCanDisassemble = true;
        }  

      if (Equals(this.repeatDisassemblyRepeatMode, RepeatDisassemblyRepeatModes.RemoveAllButOne)) && (thisItem.itemQuantity<=1) {
        thisItem.itemCanDisassemble = false;
        }  

      if (Equals(this.repeatDisassemblyRepeatMode, RepeatDisassemblyRepeatModes.RemoveAll)) {
        thisItem.itemCanDisassemble = true;
        }  

      // IgnoreQuality = 0,
      // SelectMinQuality = 1,
      // TopQualityOnly = 2,
 
      // By default, keep only one of each item and quality
      // Add overrides if quality mode is not 'IgnoreQuality'

      if (Equals(this.repeatDisassemblyQualityMode, RepeatDisassemblyQualityModes.SelectMaxQuality)) && (EnumInt(thisItem.itemQuality) <= EnumInt(this.repeatDisassemblyQualityMax)) {
        thisItem.itemCanDisassemble = true;
      }

      if (Equals(this.repeatDisassemblyQualityMode, RepeatDisassemblyQualityModes.TopQualityOnly)) && (EnumInt(thisItem.itemQuality) < EnumInt(this.itemQualityMax)) {
        thisItem.itemCanDisassemble = true;
      }          

      if (Equals(this.repeatDisassemblyQualityMode, RepeatDisassemblyQualityModes.SelectMaxQuality)) && (EnumInt(thisItem.itemQuality) > EnumInt(this.repeatDisassemblyQualityMax)) {
        thisItem.itemCanDisassemble = false;
      }

      if (Equals(this.repeatDisassemblyQualityMode, RepeatDisassemblyQualityModes.TopQualityOnly)) && (EnumInt(thisItem.itemQuality) >= EnumInt(this.itemQualityMax)) {
        thisItem.itemCanDisassemble = false;
      } 

      //this.showDebugMessage(">>>         itemQuality: " + EnumInt(thisItem.itemQuality) + " repeatDisassemblyQualityMax : " + EnumInt(this.repeatDisassemblyQualityMax) );  
      //this.showDebugMessage(">>>         itemQuality: " + EnumInt(thisItem.itemQuality) + " itemQualityMax : " + EnumInt(this.itemQualityMax) );  

      //this.showDebugMessage(">>>         removeDisassemblyItem: " + TDBID.ToStringDEBUG(thisItem.itemRecordID) + " Quality : " + ToString(thisItem.itemQuality)  + " Quantity : " + ToString(thisItem.itemQuantity)  + " CanDisassemble : " + ToString(thisItem.itemCanDisassemble) );  

      if ( thisItem.itemCanDisassemble ) {
        thisItem.itemQuantity -= 1;
        return true;
      }

    } 

    return false;
  }

  public func showDisassemblyItemsList() -> Void { 

    for thisItem in this.disassemblyList { 
      this.showDebugMessage(">>> Disassembly Item: " + TDBID.ToStringDEBUG(thisItem.itemRecordID) + " Quality : " + ToString(thisItem.itemQuality)  + " Quantity : " + ToString(thisItem.itemQuantity) );  
    }; 
  }
/* 
  SHOWMESSAGE OVERRIDE FOR DEBUGGING
*/
  private func showDebugMessage(debugMessage: String) {
    // LogChannel(n"DEBUG", debugMessage ); 
  }


}


 
@replaceMethod(BackpackMainGameController)
  protected cb func OnDisassembleJunkPopupClosed(data: ref<inkGameNotificationData>) -> Bool {
    // let owner = GetPlayer(this.GetGameInstance());
    let itemName: String;
    let itemType: gamedataItemType;
    let itemQuality: gamedataQuality;
    let itemQuantity: Int32;
    let itemCanDisassemble: Bool;
    let list: array<wref<gameItemData>>; 

    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();
    let i: Int32;
    let limit: Int32;
    this.m_disassembleJunkPopupToken = null;
    let sellJunkData: ref<VendorSellJunkPopupCloseData> = data as VendorSellJunkPopupCloseData;
    if sellJunkData.confirm {

      if (_playerPuppetPS.m_repeatDisassemblyTracking.modON) {
        _playerPuppetPS.m_repeatDisassemblyTracking.refreshConfig();
        ArrayClear(_playerPuppetPS.m_repeatDisassemblyTracking.disassemblyList);
        _playerPuppetPS.m_repeatDisassemblyTracking.itemQualityMax = RepeatDisassemblyQuality.Common; 
        //this.showDebugMessage(">>> AUTO DISASSEMBLY: Attachment detected: " ); 
  
        // Loop through inventory to build list of weapon mods class items

        GameInstance.GetTransactionSystem(this.m_player.GetGame()).GetItemListByTag(this.m_player, n"itemPart", list);
        i = 0;
        while i < ArraySize(list) { 
          if !list[i].HasTag(n"Fragment") && !list[i].HasTag(n"SoftwareShard") {
            itemName = list[i].GetNameAsString();
            itemType = list[i].GetItemType();
            itemQuantity = list[i].GetQuantity();
            itemQuality = RPGManager.GetItemDataQuality(list[i]);
            //this.showDebugMessage(">>> Attachment found: " + TDBID.ToStringDEBUG(ItemID.GetTDBID(list[i].GetID())) + " Quality : " + ToString(itemQuality) );

            _playerPuppetPS.m_repeatDisassemblyTracking.addDisassemblyItem( ItemID.GetTDBID(list[i].GetID()), itemType, itemQuality, 1, list[i]);
          };
          i += 1;
        };

        if (_playerPuppetPS.m_repeatDisassemblyTracking.debugON) {
          _playerPuppetPS.m_repeatDisassemblyTracking.showDisassemblyItemsList();
        }

        // Loop through weapons mods list of each type and disassemble accorning to mod settings 
        i = 0;
        while i < ArraySize(list) { 
          if !list[i].HasTag(n"Fragment") && !list[i].HasTag(n"SoftwareShard") {

            itemCanDisassemble = _playerPuppetPS.m_repeatDisassemblyTracking.removeDisassemblyItem( ItemID.GetTDBID(list[i].GetID()));
            // _playerPuppetPS.m_repeatDisassemblyTracking.showDebugMessage(">>> Disassembling attachment ["+ToString(i) + "]: " + TDBID.ToStringDEBUG(ItemID.GetTDBID(list[i].GetID())));

            if (itemCanDisassemble) {
              // if this.CanItemBeDisassembled(this.m_player, list[i].GetID()) {
                ItemActionsHelper.DisassembleItem(this.m_player, list[i].GetID(), list[i].GetQuantity());
                // _playerPuppetPS.m_repeatDisassemblyTracking.showDebugMessage(">>>         REMOVE");
              // };              
            } // else {
                // _playerPuppetPS.m_repeatDisassemblyTracking.showDebugMessage(">>>         KEEP");

            // }
 
          };
          i += 1;
        };

      } 

      if (_playerPuppetPS.m_repeatDisassemblyTracking.disassembleJunkON) {
        // Disassemble Junk but always keep one junk to allow disassembly of weapon mods
        i = 0;
        limit = ArraySize(this.m_junkItems) - 1;
        if (limit>1) {
          while i < limit {
            ItemActionsHelper.DisassembleItem(this.m_player, this.m_junkItems[i].GetID(), this.m_junkItems[i].GetQuantity());
            i += 1;
          };          
        }

      }


      this.PlaySound(n"Item", n"OnDisassemble");
      this.m_TooltipsManager.HideTooltips();
    } else {
      this.PlaySound(n"Button", n"OnPress");
    };
    this.m_buttonHintsController.Show();
  }

