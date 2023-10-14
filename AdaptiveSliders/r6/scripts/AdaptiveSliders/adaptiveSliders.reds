/*
For redscript mod developers

:: Replaced methods
@replaceMethod(ItemQuantityPickerController) private final func SetData() -> Void 

*/


// public class ItemQuantityPickerController extends inkGameController {
@replaceMethod(ItemQuantityPickerController)

  private final func SetData() -> Void {
    let itemData: ref<gameItemData>;
    let itemRecord: ref<Item_Record>;
    this.m_maxValue = this.m_data.maxValue;
    this.m_gameData = this.m_data.gameItemData;
    this.m_inventoryItem = this.m_data.inventoryItem;
    this.m_actionType = this.m_data.actionType;
    this.m_isBuyback = this.m_data.isBuyback;
    this.m_sendQuantityChangedEvent = this.m_data.sendQuantityChangedEvent;
    if this.m_sendQuantityChangedEvent {
      this.m_quantityChangedEvent = new PickerChoosenQuantityChangedEvent();
    };
    this.m_choosenQuantity = 1;

    // Patch - Set slider to max items by default if dropping or selling
    // // LogChannel(n"DEBUG", ">>> this.m_actionType: '"+ToString(this.m_actionType)+"'"  );

    switch ToString(this.m_actionType) {
      // Craft?
      // case "Buy":
      case "Drop":
      case "Sell":
      case "Disassembly":
      case "TransferToStorage":
        this.m_choosenQuantity = this.m_maxValue;
        break;
      default:
        this.m_choosenQuantity = 1;
        break;
    };
    // End of patch

    this.m_sliderController.Setup(1.00, Cast<Float>(this.m_maxValue), Cast<Float>(this.m_choosenQuantity), 1.00);
    if IsDefined(this.m_inventoryItem) {
      itemRecord = this.m_inventoryItem.GetItemRecord();
      itemData = this.m_inventoryItem.GetItemData();
    } else {
      itemRecord = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(InventoryItemData.GetID(this.m_gameData)));
      itemData = InventoryItemData.GetGameItemData(this.m_gameData);
    };
    inkTextRef.SetText(this.m_itemNameText, UIItemsHelper.GetItemName(itemRecord, itemData));
    inkTextRef.SetText(this.m_quantityTextMax, IntToString(this.m_maxValue));
    inkTextRef.SetText(this.m_quantityTextMin, "1");
    inkTextRef.SetText(this.m_quantityTextChoosen, IntToString(this.m_choosenQuantity));
    inkWidgetRef.SetVisible(this.m_priceText, IsDefined(this.m_data.vendor));
    if IsDefined(this.m_data.vendor) {
      this.m_itemPrice = Equals(this.m_actionType, QuantityPickerActionType.Buy) && !this.m_isBuyback ? MarketSystem.GetBuyPrice(this.m_data.vendor, itemData.GetID()) : RPGManager.CalculateSellPrice(this.m_data.vendor.GetGame(), this.m_data.vendor, itemData.GetID());
    };
    this.m_itemWeight = itemData.GetStatValueByType(gamedataStatType.Weight);
    switch this.m_actionType {
      case QuantityPickerActionType.Drop:
        inkTextRef.SetText(this.m_buttonOkText, "UI-ScriptExports-Drop0");
        inkWidgetRef.SetVisible(this.m_priceWrapper, false);
        break;
      case QuantityPickerActionType.Disassembly:
        inkTextRef.SetText(this.m_buttonOkText, "Gameplay-Devices-DisplayNames-DisassemblableItem");
        inkWidgetRef.SetVisible(this.m_priceWrapper, false);
        break;
      case QuantityPickerActionType.Craft:
        inkTextRef.SetText(this.m_buttonOkText, "UI-Crafting-CraftItem");
        inkWidgetRef.SetVisible(this.m_priceWrapper, false);
        break;
      case QuantityPickerActionType.TransferToStorage:
      case QuantityPickerActionType.TransferToPlayer:
        inkWidgetRef.SetVisible(this.m_priceWrapper, false);
        break;
      default:
        inkTextRef.SetText(this.m_buttonOkText, "LocKey#22269");
        inkWidgetRef.SetVisible(this.m_priceWrapper, true);
    };
    if IsDefined(this.m_inventoryItem) {
      inkWidgetRef.SetState(this.m_rairtyBar, this.m_inventoryItem.GetQualityName());
    } else {
      if !InventoryItemData.IsEmpty(this.m_gameData) {
        inkWidgetRef.SetState(this.m_rairtyBar, InventoryItemData.GetQuality(this.m_gameData));
      } else {
        inkWidgetRef.SetState(this.m_rairtyBar, n"Common");
      };
    };
    this.UpdatePriceText();
    this.UpdateWeight();
    this.GetRootWidget().SetVisible(true);
  }
