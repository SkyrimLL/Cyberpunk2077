// public class ItemQuantityPickerController extends inkGameController {
@replaceMethod(ItemQuantityPickerController)

  private final func SetData() -> Void {
    let itemRecord: ref<Item_Record>;
    this.m_maxValue = this.m_data.maxValue;
    this.m_gameData = this.m_data.gameItemData;
    this.m_actionType = this.m_data.actionType;
    this.m_isBuyback = this.m_data.isBuyback;
    this.m_sendQuantityChangedEvent = this.m_data.sendQuantityChangedEvent;
    if this.m_sendQuantityChangedEvent {
      this.m_quantityChangedEvent = new PickerChoosenQuantityChangedEvent();
    };
    // Patch - Set slider to max items by default if dropping or selling
    switch this.m_actionType {
      case QuantityPickerActionType.Drop:
      case QuantityPickerActionType.TransferToStorage:
        this.m_choosenQuantity = this.m_maxValue;
        break;
      case  QuantityPickerActionType.TransferToPlayer:
        this.m_choosenQuantity = 1;
        break;
      default:
        this.m_choosenQuantity = 1;
        break;
    }

    this.m_sliderController.Setup(1.00, Cast<Float>(this.m_maxValue), Cast<Float>(this.m_choosenQuantity), 1.00);
    itemRecord = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(InventoryItemData.GetID(this.m_gameData)));
    inkTextRef.SetText(this.m_itemNameText, UIItemsHelper.GetItemName(itemRecord, InventoryItemData.GetGameItemData(this.m_gameData)));
    inkTextRef.SetText(this.m_quantityTextMax, IntToString(this.m_maxValue));
    inkTextRef.SetText(this.m_quantityTextMin, "1");
    inkTextRef.SetText(this.m_quantityTextChoosen, IntToString(this.m_choosenQuantity));
    inkWidgetRef.SetVisible(this.m_priceText, IsDefined(this.m_data.vendor));
    if IsDefined(this.m_data.vendor) {
      this.m_itemPrice = Equals(this.m_actionType, QuantityPickerActionType.Buy) ? MarketSystem.GetBuyPrice(this.m_data.vendor, InventoryItemData.GetGameItemData(this.m_gameData).GetID()) : RPGManager.CalculateSellPrice(this.m_data.vendor.GetGame(), this.m_data.vendor, InventoryItemData.GetGameItemData(this.m_gameData).GetID());
    };
    this.m_itemWeight = InventoryItemData.GetGameItemData(this.m_gameData).GetStatValueByType(gamedataStatType.Weight);
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
    };
    inkWidgetRef.SetVisible(this.m_priceWrapper, true);
    if !InventoryItemData.IsEmpty(this.m_gameData) {
      inkWidgetRef.SetState(this.m_rairtyBar, InventoryItemData.GetQuality(this.m_gameData));
    } else {
      inkWidgetRef.SetState(this.m_rairtyBar, n"Common");
    };
    this.UpdatePriceText();
    this.UpdateWeight();
    this.GetRootWidget().SetVisible(true);
  }
