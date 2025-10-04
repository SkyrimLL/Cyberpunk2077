
// in public class RadialMenuHubGameController extends gameuiMenuGameController {

@wrapMethod(RadialMenuHubGameController)

  protected cb func OnOpenMenuRequest(evt: ref<OpenMenuRequest>) -> Bool {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();

    if (_playerPuppetPS.m_limitedEncumbranceTracking.modON) {
      _playerPuppetPS.m_limitedEncumbranceTracking.refreshConfig();
    }
    
    wrappedMethod(evt);
  }


// in public class MenuHubGameController extends gameuiMenuGameController 

@replaceMethod(MenuHubGameController)

  protected cb func OnPlayerMaxWeightUpdated(value: Int32) -> Bool {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();
    let gameInstance: GameInstance = this.m_player.GetGame();
    // let carryCapacity: Int32 = Cast<Int32>(GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(this.m_player.GetEntityID()), gamedataStatType.CarryCapacity));
    let carryCapacity: Int32 = Cast<Int32>(_playerPuppetPS.m_limitedEncumbranceTracking.getCarryCapacity());

    // Update m_player for easy access by SubMenuPanelLogicController
    this.m_subMenuCtrl.m_player = this.m_player;   

    this.m_subMenuCtrl.HandlePlayerMaxWeightUpdated(carryCapacity, this.m_player.m_curInventoryWeight);
    if RoundF(this.m_player.m_curInventoryWeight) >= carryCapacity {
      this.PlayLibraryAnimation(n"overburden");
    };
  
  }

@replaceMethod(MenuHubGameController)

  public final func HandlePlayerWeightUpdated(opt dropQueueWeight: Float) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();
    let gameInstance: GameInstance = this.m_player.GetGame();
    // let carryCapacity: Int32 = Cast<Int32>(GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(this.m_player.GetEntityID()), gamedataStatType.CarryCapacity));
    let carryCapacity: Int32 = Cast<Int32>(_playerPuppetPS.m_limitedEncumbranceTracking.getCarryCapacity());

    // Update m_player for easy access by SubMenuPanelLogicController
    this.m_subMenuCtrl.m_player = this.m_player;    

    this.m_subMenuCtrl.HandlePlayerWeightUpdated(this.m_player.m_curInventoryWeight - dropQueueWeight, carryCapacity);

  }


// in public class SubMenuPanelLogicController extends PlayerStatsUIHolder 
@addField(SubMenuPanelLogicController)
public let m_player: wref<PlayerPuppet>;

@replaceMethod(SubMenuPanelLogicController)

  public final func HandlePlayerWeightUpdated(value: Float, maxWeight: Int32) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();
       
    if (_playerPuppetPS.m_limitedEncumbranceTracking.modON) {
      _playerPuppetPS.m_limitedEncumbranceTracking.applyWeightEffects();  

      inkTextRef.SetText(this.m_weightValue, _playerPuppetPS.m_limitedEncumbranceTracking.printEncumbrance(value));

    } else {
      // Vanilla code

      inkTextRef.SetText(this.m_weightValue, ToString(Cast<Int32>(value)) + "/" + ToString(maxWeight));
    }
      
    // GameObject.PlaySoundEvent(this.m_player, n"ui_menu_item_consumable_generic");
 
  }

@replaceMethod(SubMenuPanelLogicController)

  public final func HandlePlayerMaxWeightUpdated(value: Int32, curInventoryWeight: Float) -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();

    if (_playerPuppetPS.m_limitedEncumbranceTracking.modON) { 
      _playerPuppetPS.m_limitedEncumbranceTracking.applyWeightEffects(); 

      inkTextRef.SetText(this.m_weightValue, _playerPuppetPS.m_limitedEncumbranceTracking.printEncumbrance(curInventoryWeight));
    } else {
      // Vanilla code

      inkTextRef.SetText(this.m_weightValue, ToString(Cast<Int32>(curInventoryWeight)) + "/" + ToString(value));

    }
  }

// public class VendorHubMenuGameController extends gameuiMenuGameController {
@replaceMethod(VendorHubMenuGameController)
  protected cb func OnPlayerWeightUpdated(value: Float) -> Bool {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS();
    let gameInstance: GameInstance = this.m_player.GetGame();
    let carryCapacity: Int32 = Cast<Int32>(GameInstance.GetStatsSystem(gameInstance).GetStatValue(Cast<StatsObjectID>(this.m_player.GetEntityID()), gamedataStatType.CarryCapacity));

    if (_playerPuppetPS.m_limitedEncumbranceTracking.modON) {
      _playerPuppetPS.m_limitedEncumbranceTracking.applyWeightEffects();

      inkTextRef.SetText(this.m_playerWeightValue, _playerPuppetPS.m_limitedEncumbranceTracking.printEncumbrance(this.m_player.m_curInventoryWeight));
    } else {
      // Vanilla code
      inkTextRef.SetText(this.m_playerWeightValue, IntToString(RoundF(this.m_player.m_curInventoryWeight)) + " / " + carryCapacity);

    }
  }

// public native class AttachmentSlotsScriptCallback extends IScriptable {
@addField(AttachmentSlotsScriptCallback)
public let m_player: wref<PlayerPuppet>;

@wrapMethod(AttachmentSlotsScriptCallback)
  public func OnItemEquipped(slot: TweakDBID, item: ItemID) -> Void { 
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.m_player.GetPS(); 

    if (_playerPuppetPS.m_limitedEncumbranceTracking.modON) {
      _playerPuppetPS.m_limitedEncumbranceTracking.applyWeightEffects();  
    }
    
    wrappedMethod(slot, item);
  }