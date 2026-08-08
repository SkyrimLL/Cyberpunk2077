
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

