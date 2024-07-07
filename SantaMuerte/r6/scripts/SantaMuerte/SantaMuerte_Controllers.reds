// public native class healthbarWidgetGameController extends inkHUDGameController {

/* 
@replaceMethod(healthbarWidgetGameController)
  private final func UpdateCurrentHealthText() -> Void {
    let player: wref<PlayerPuppet>;
    player = this.m_playerObject as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = player.GetPS();

    _playerPuppetPS.m_santaMuerteTracking.refreshConfig();

    if (_playerPuppetPS.m_santaMuerteTracking.modON) && (_playerPuppetPS.m_santaMuerteTracking.isRelicInstalled()) && (player.IsInCombat())  && (_playerPuppetPS.m_santaMuerteTracking.santaMuerteWidgetON)  {
        // Custom Health Display
        inkWidgetRef.SetState(this.m_healthTextPath, this.m_currentOvershieldValue > 0 ? n"Overshield" : n"Default");
        inkTextRef.SetText(this.m_healthTextPath, "R::" +  ToString(_playerPuppetPS.m_santaMuerteTracking.resurrectCountMax - _playerPuppetPS.m_santaMuerteTracking.resurrectCount) );
      } else {
        // Default health display
        inkWidgetRef.SetState(this.m_healthTextPath, this.m_currentOvershieldValue > 0 ? n"Overshield" : n"Default");
        inkTextRef.SetText(this.m_healthTextPath, IntToString(this.m_currentHealth + this.m_currentOvershieldValue));        
      }
  }
*/

@wrapMethod(healthbarWidgetGameController)
  protected cb func OnInitialize() -> Bool {
    wrappedMethod();

    let player: wref<PlayerPuppet>;
    player = this.m_playerObject as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = player.GetPS();

    _playerPuppetPS.m_santaMuerteTracking.refreshConfig();

    if (_playerPuppetPS.m_santaMuerteTracking.informativeHUDCompatibilityON) {   

      //grabbing the root widget
      let root = this.GetRootCompoundWidget() as inkCompoundWidget;
      //removing fluff
      let fluff1 = root.GetWidget(n"buffsHolder/holder") as inkWidget;
      fluff1.SetVisible(false);
      let fluff2 = root.GetWidget(n"buffsHolder/hpbar_fluff") as inkWidget;
      fluff2.SetVisible(false);
    }
  }

@wrapMethod(healthbarWidgetGameController)
  private final func UpdateMemoryBarData() -> Void {
    wrappedMethod();

    let player: wref<PlayerPuppet>;
    player = this.m_playerObject as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = player.GetPS();

    _playerPuppetPS.m_santaMuerteTracking.refreshConfig();

    //grabbing the root widget
    let root = this.GetRootCompoundWidget() as inkCompoundWidget;
    //grabbing bars container
    let hPanel = root.GetWidget(n"buffsHolder/barsLayout/quickhacks/barsContainer") as inkHorizontalPanel;

    //adding memory text widget
    let canvas = new inkCanvas();
    canvas.SetName(n"santaMuerteRAM");
    canvas.SetAnchor(inkEAnchor.CenterFillHorizontaly);
    canvas.SetAnchorPoint(new Vector2(0.0, 0.5));
    hPanel.RemoveChildByName(n"santaMuerteRAM");
    canvas.Reparent(hPanel);

    if (_playerPuppetPS.m_santaMuerteTracking.informativeHUDCompatibilityON) {
      let numbers = new inkText();
      numbers.SetText("  " + ToString(FloorF(this.m_memoryFillCells)) + "/" + ToString(this.m_memoryMaxCells));
      numbers.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
      numbers.SetFontStyle(n"Regular");
      numbers.SetFontSize(20);
      //numbers.SetTintColor(new HDRColor(1.1761, 0.3809, 0.3476, 1.0)); //red version
      numbers.SetTintColor(new HDRColor(0.3686, 0.9647, 1.1888, 1.0)); //blue version
      numbers.SetAnchor(inkEAnchor.CenterFillHorizontaly);
      numbers.SetAnchorPoint(0.0, 0.5);
      numbers.Reparent(canvas);        
    }

    if (_playerPuppetPS.m_santaMuerteTracking.modON) && (_playerPuppetPS.m_santaMuerteTracking.isRelicInstalled()) && (_playerPuppetPS.m_santaMuerteTracking.santaMuerteWidgetON) {   
    // if (player.IsInCombat()) 
    // {
      let resurrections = new inkText();
      if (_playerPuppetPS.m_santaMuerteTracking.isRelicInstalled()) {
          resurrections.SetText("               0x00R" +  ToString(_playerPuppetPS.m_santaMuerteTracking.resurrectCountMax - _playerPuppetPS.m_santaMuerteTracking.resurrectCount));  
        } else {
          resurrections.SetText("               ");  
        }

      resurrections.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
      resurrections.SetFontStyle(n"Regular");
      resurrections.SetFontSize(20);
      resurrections.SetTintColor(new HDRColor(1.1761, 0.3809, 0.3476, 1.0)); //red version
      //numbers.SetTintColor(new HDRColor(0.3686, 0.9647, 1.1888, 1.0)); //blue version
      resurrections.SetAnchor(inkEAnchor.CenterFillHorizontaly);
      resurrections.SetAnchorPoint(0.0, 0.5);
      resurrections.Reparent(canvas);        
    // }

    }
  }


