// public class gameuiInventoryGameController extends gameuiMenuGameController {

/*
@replaceMethod(gameuiInventoryGameController)

  protected cb func OnEquipmentClick(evt: ref<ItemDisplayClickEvent>) -> Bool {
    let hotkey: EHotkey;
    let itemData: InventoryItemData;
    let controller: wref<InventoryItemDisplayController> = evt.display;

    this.PlaySound(n"Button", n"OnPress");

    if Equals(this.m_mode, InventoryModes.Item) {
      return false;
    };
    if evt.actionName.IsAction(n"unequip_item") {
      itemData = controller.GetItemData();
      if !InventoryItemData.IsEmpty(itemData) {
        this.m_InventoryManager.GetHotkeyTypeForItemID(InventoryItemData.GetID(itemData), hotkey);
        if NotEquals(hotkey, EHotkey.INVALID) {
          this.m_equipmentSystem.GetPlayerData(this.m_player).ClearItemFromHotkey(hotkey);
          this.NotifyItemUpdate(hotkey);
        } else {
          if this.IsEquipmentAreaCyberware(itemData) {
            return false;
          };
          if !InventoryGPRestrictionHelper.CanUse(itemData, this.m_player) || this.IsUnequipBlocked(InventoryItemData.GetID(itemData)) {
            this.ShowNotification(this.m_player.GetGame(), UIMenuNotificationType.InventoryActionBlocked);
            return false;
          };
          if controller.IsLocked() {
            this.ShowNotification(this.m_player.GetGame(), UIMenuNotificationType.InventoryActionBlocked);
            return false;
          };
          this.UnequipItem(controller, itemData);
        };
        this.PlaySound(n"ItemAdditional", n"OnUnequip");
      };
    } else {
      if evt.actionName.IsAction(n"select") || evt.actionName.IsAction(n"click") {
        this.PlaySound(n"Button", n"OnPress");
        if Equals(controller.GetEquipmentArea(), gamedataEquipmentArea.Invalid) {
          return false;
        };
        if controller.IsLocked() {
          this.ShowNotification(this.m_player.GetGame(), UIMenuNotificationType.InventoryActionBlocked);
          return false;
        };
        itemData = controller.GetItemData();
        if InventoryDataManagerV2.IsEquipmentAreaCyberware(controller.GetEquipmentArea()) && (InventoryItemData.IsEmpty(itemData) || controller.GetAttachmentsSize() <= 0) {
          return false;
        };
        if !evt.toggleVisibilityRequest {
          this.OpenItemMode(controller.GetItemDisplayData());
        };
      };
    };
  }
*/
/*
@replaceMethod(gameuiInventoryGameController)

  protected cb func OnInventoryHold(evt: ref<inkPointerEvent>) -> Bool {
    let controller: wref<InventoryItemDisplay> = this.GetInventoryItemControllerFromTarget(evt);
    let itemData: InventoryItemData = controller.GetItemData();
    let progress: Float = evt.GetHoldProgress();
    if progress >= 1.00 {
      if evt.IsAction(n"disassemble_item") && !this.m_isE3Demo {
        if InventoryItemData.GetQuantity(itemData) > 1 {
          this.OpenQuantityPicker(itemData, QuantityPickerActionType.Disassembly);
        } else {
          this.PlaySound(n"ItemGeneric", n"OnDisassemble");
          ItemActionsHelper.DisassembleItem(this.m_player, InventoryItemData.GetID(itemData));
        };
      } else {

        this.PlaySound(n"Button", n"OnPress");

        if evt.IsAction(n"use_item") {
          if !InventoryGPRestrictionHelper.CanUse(itemData, this.m_player) {
            this.ShowNotification(this.m_player.GetGame(), UIMenuNotificationType.InventoryActionBlocked);
            return false;
          };
          this.PlaySound(n"ItemConsumableFood", n"OnUse");
          ItemActionsHelper.PerformItemAction(this.m_player, InventoryItemData.GetID(itemData));
          this.m_InventoryManager.MarkToRebuild();
        };
      };
    };
  }
  */

