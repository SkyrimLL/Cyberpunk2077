// public native class healthbarWidgetGameController extends inkHUDGameController {

/* 
    this.m_buffWidget = this.SpawnFromExternal(inkWidgetRef.Get(this.m_buffsHolder), r"base\\gameplay\\gui\\widgets\\healthbar\\playerbuffbar.inkwidget", n"VertRoot");
*/

@replaceMethod(healthbarWidgetGameController)
  private final func UpdateCurrentHealthText() -> Void {
    let player: wref<PlayerPuppet>;
    player = this.m_playerObject as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = player.GetPS();

    _playerPuppetPS.m_santaMuerteTracking.refreshConfig();

    if (_playerPuppetPS.m_santaMuerteTracking.modON) && (_playerPuppetPS.m_santaMuerteTracking.isRelicInstalled()) && (player.IsInCombat())  && (_playerPuppetPS.m_santaMuerteTracking.santaMuerteWidgetON) {

      if !(this.IsCyberdeckEquipped()) {
        inkWidgetRef.SetVisible(this.m_quickhacksContainer, true);        
      }

    }
    
    // Default health display
    inkWidgetRef.SetState(this.m_healthTextPath, this.m_currentOvershieldValue > 0 ? n"Overshield" : n"Default");
    inkTextRef.SetText(this.m_healthTextPath, IntToString(this.m_currentHealth + this.m_currentOvershieldValue));        

  }

@wrapMethod(healthbarWidgetGameController)
  protected cb func OnUpdateHealthBarVisibility() -> Bool {
    wrappedMethod();

    // force RAM widget regardless of cyberdeck equipped or not
    //inkWidgetRef.SetVisible(this.m_quickhacksContainer, this.IsCyberdeckEquipped());
    inkWidgetRef.SetVisible(this.m_quickhacksContainer, true); 
  }

@wrapMethod(healthbarWidgetGameController)
  protected cb func OnInitialize() -> Bool {
    wrappedMethod();

    let player: wref<PlayerPuppet>;
    player = this.m_playerObject as PlayerPuppet;
    let _playerPuppetPS: ref<PlayerPuppetPS> = player.GetPS();

    _playerPuppetPS.m_santaMuerteTracking.refreshConfig();

    if (_playerPuppetPS.m_santaMuerteTracking.informativeHUDCompatibilityON) {  
      // LogChannel(n"DEBUG", ">>> Santa Muerte: healthbarWidgetGameController - init informativeHUDCompatibilityON" );   

      //grabbing the root widget
      let root = this.GetRootCompoundWidget() as inkCompoundWidget;
      //removing fluff
      let fluff1 = root.GetWidget(n"buffsHolder/holder") as inkWidget;
      fluff1.SetVisible(false);
      let fluff2 = root.GetWidget(n"buffsHolder/hpbar_fluff") as inkWidget;
      fluff2.SetVisible(false);
    }
  }

@replaceMethod(healthbarWidgetGameController)
  private final func UpdateMemoryBarData() -> Void {
    let quickhackBar: wref<inkWidget>;
    let quickhackBarController: wref<QuickhackBarController>;
    let fillCellsInt: Int32 = FloorF(this.m_memoryFillCells);
    let i: Int32 = 0;

    if (this.IsCyberdeckEquipped()) {
        while i < ArraySize(this.m_quickhackBarArray) {
          if i >= this.m_memoryMaxCells {
            this.m_quickhackBarArray[i].SetVisible(false);
          } else {
            quickhackBar = this.m_quickhackBarArray[i];
            quickhackBarController = quickhackBar.GetController() as QuickhackBarController;
            if fillCellsInt < this.m_memoryMaxCells {
              if i < fillCellsInt {
                quickhackBarController.SetStatus(1.00);
              } else {
                if i == fillCellsInt {
                  quickhackBarController.SetStatus(this.m_memoryFillCells - Cast<Float>(fillCellsInt));
                } else {
                  quickhackBarController.SetStatus(0.00);
                };
              };
            } else {
              quickhackBarController.SetStatus(1.00);
            };
            quickhackBar.SetVisible(true);
          };
          i += 1;
        };
        this.RequestHealthBarVisibilityUpdate();
    }

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

    // Display RAM bars only if Cyberdeck is installed
    if (_playerPuppetPS.m_santaMuerteTracking.informativeHUDCompatibilityON) {
      // LogChannel(n"DEBUG", ">>> Santa Muerte: healthbarWidgetGameController - draw" );   

      let numbers = new inkText();

      if (this.IsCyberdeckEquipped()) {
        numbers.SetText("  " + ToString(FloorF(this.m_memoryFillCells)) + "/" + ToString(this.m_memoryMaxCells));
        numbers.SetTintColor(new HDRColor(0.3686, 0.9647, 1.1888, 1.0)); //blue version
        } else {
        numbers.SetText("  N/A");
        numbers.SetTintColor(new HDRColor(1.1761, 0.3809, 0.3476, 1.0)); //red version
        }
      numbers.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
      numbers.SetFontStyle(n"Regular");
      numbers.SetFontSize(20);
      numbers.SetAnchor(inkEAnchor.CenterFillHorizontaly);
      numbers.SetAnchorPoint(0.0, 0.5);
      numbers.Reparent(canvas);        
    }

    // Display relic resurrections
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
      // numbers.SetTintColor(new HDRColor(0.3686, 0.9647, 1.1888, 1.0)); //blue version
      // resurrections.SetAnchor(inkEAnchor.CenterFillHorizontaly);
      resurrections.SetAnchorPoint(-0.5, 2.4); // Just above Health counter
      resurrections.Reparent(canvas);        
    // }

    }
  }


// public final native class DamageSystem extends IDamageSystem {
@wrapMethod(DamageSystem)
  private final func ProcessLocalizedDamage(hitEvent: ref<gameHitEvent>) -> Void {
    wrappedMethod(hitEvent);

    let playerAsTarget: wref<PlayerPuppet> = hitEvent.target as PlayerPuppet; 
    let instigator: wref<GameObject> = hitEvent.attackData.GetInstigator() ;
    let instigatorPuppet: wref<NPCPuppet> = hitEvent.attackData.GetInstigator() as NPCPuppet;
    let attackData: ref<AttackData> = hitEvent.attackData; 
    
    if (IsDefined(playerAsTarget) && instigator.IsNPC()) {
      let _playerPuppetPS: ref<PlayerPuppetPS> = playerAsTarget.GetPS();
      _playerPuppetPS.m_santaMuerteTracking.lastInstigatorFaction = "Unknown";
      _playerPuppetPS.m_santaMuerteTracking.lastInstigatorName = "Unknown Source";
      // Check if the instigator is an NPC and retrieve its faction 
      if IsDefined(instigatorPuppet) {
          let affiliation: wref<Affiliation_Record> = TweakDBInterface.GetCharacterRecord(instigatorPuppet.GetRecordID()).Affiliation();   
          let characterRecord: ref<Character_Record> = TweakDBInterface.GetCharacterRecord(instigatorPuppet.GetRecordID());

          if IsDefined(affiliation) {       
            // _playerPuppetPS.m_santaMuerteTracking.lastInstigatorFaction = LocKeyToString(characterRecord.Affiliation().LocalizedName());
            _playerPuppetPS.m_santaMuerteTracking.lastInstigatorFaction = ToString(characterRecord.Affiliation().EnumName());

            if IsNameValid(characterRecord.DisplayName()) {
              // _playerPuppetPS.m_santaMuerteTracking.lastInstigatorName = LocKeyToString(characterRecord.DisplayName());
              _playerPuppetPS.m_santaMuerteTracking.lastInstigatorName = ToString(characterRecord.DisplayName());
            } else {
              _playerPuppetPS.m_santaMuerteTracking.lastInstigatorName = instigatorPuppet.GetDisplayName();
            };
          }
      }      
    }

  }