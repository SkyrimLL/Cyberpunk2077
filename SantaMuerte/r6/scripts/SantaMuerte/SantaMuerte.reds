/*
For redscript mod developers

:: Replaced methods
@replaceMethod(PlayerPuppet) public final func EvaluateEncumbrance() -> Void 

:: Added fields

:: New classes
public class SantaMuerteTracking 
*/  

import GameInstance
import gameuiGenericNotificationType
 
public class SantaMuerteTracking extends ScriptedPuppetPS {
  public let player: wref<PlayerPuppet>; 

  public persistent let resurrectCount:  Int32;
  public persistent let m_storedItems: array<ItemID>; 

  public let lastInstigatorFaction: String;
  public let lastInstigatorName: String;

  public let newDeathAnimationON: Bool; 
  public let randomDeathAnimationON: Bool; 
  public let santaMuerteRelicDifficulty: santaMuerteRelicMode;
  public let santaMuerteLoreDifficulty: santaMuerteRelicMode;
  public let santaMuerteLoreDifficultyON: Bool; 
  public let resurrectCountMax:  Int32;
  public let scaleResurrectionsModifier: Float;
  public let capResurrectionsOverride: Int32;
  public let deathLandingProtectionON: Bool;
  public let skipTimeON: Bool;
  public let minSkippedTime: Float;
  public let maxSkippedTime: Float;
  public let darkFutureEffectON: Bool;
  public let blackoutON: Bool;
  public let maxBlackoutTime: Float;
  public let teleportON: Bool;
  public let blackoutTeleportChance: Int32;
  public let blackoutSafeTeleportON: Bool;   
  public let blackoutSafeTeleportHospitalON: Bool;   
  public let safeTeleportFee: Int32;
  public let blackoutDetourTeleportON: Bool;  
  public let blackoutDetourTeleportChance: Int32;
  public let santaMuerteWidgetON: Bool;
  public let informativeHUDCompatibilityON: Bool;
  public let deathWhenImpersonatingJohnnyON: Bool;
  public let hardcoreDetourRobbedON: Bool; 
  public let hardcoreStealEquippedON: Bool;
  public let hardcoreDetourRobbedChance: Int32;
  public let hardcoreDetourRobbedClothingChance: Int32;
  public let hardcoreDetourRobbedMoneyPercent: Int32;

  public let config: ref<SantaMuerteConfig>;

  public let unlimitedResurrectON: Bool; 

  public let modON: Bool;  

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
    this.config = new SantaMuerteConfig(); 
    this.invalidateCurrentState();

    // Checks if stuck combat and clears it
    this.clearCombatIfStuck();
  }

  public func invalidateCurrentState() -> Void {    
    this.updateMaxResurrections();

    // Push into config
    this.config.resurrectCount = this.resurrectCount;
    this.config.resurrectCountMax = this.resurrectCountMax;
    this.config.santaMuerteRelicDifficulty = this.santaMuerteRelicDifficulty;

    // Pull from config
    this.newDeathAnimationON = this.config.newDeathAnimationON;
    this.randomDeathAnimationON = this.config.randomDeathAnimationON; 
    this.santaMuerteRelicDifficulty = this.config.santaMuerteRelicDifficulty;
    this.santaMuerteLoreDifficultyON = this.config.santaMuerteLoreDifficultyON;
    this.scaleResurrectionsModifier = this.config.scaleResurrectionsModifier;
    this.capResurrectionsOverride = this.config.capResurrectionsOverride;
    this.unlimitedResurrectON = this.config.unlimitedResurrectON;
    this.deathLandingProtectionON = this.config.deathLandingProtectionON;
    this.skipTimeON = this.config.skipTimeON;
    this.blackoutON = this.config.blackoutON;
    this.darkFutureEffectON = this.config.darkFutureEffectON; 
    this.maxBlackoutTime = this.config.maxBlackoutTime;
    this.teleportON = this.config.teleportON;
    this.minSkippedTime = this.config.minSkippedTime;
    this.maxSkippedTime = this.config.maxSkippedTime;
    this.blackoutTeleportChance = this.config.blackoutTeleportChance;
    this.blackoutSafeTeleportON = this.config.blackoutSafeTeleportON; 
    this.blackoutSafeTeleportHospitalON = this.config.blackoutSafeTeleportHospitalON; 
    this.safeTeleportFee = this.config.safeTeleportFee; 
    this.blackoutDetourTeleportON = this.config.blackoutDetourTeleportON;
    this.blackoutDetourTeleportChance = this.config.blackoutDetourTeleportChance;
    this.santaMuerteWidgetON = this.config.santaMuerteWidgetON;
    this.informativeHUDCompatibilityON = this.config.informativeHUDCompatibilityON;
    this.deathWhenImpersonatingJohnnyON = this.config.deathWhenImpersonatingJohnnyON;
    this.hardcoreDetourRobbedON = this.config.hardcoreDetourRobbedON;
    this.hardcoreDetourRobbedChance = this.config.hardcoreDetourRobbedChance;
    this.hardcoreDetourRobbedClothingChance = this.config.hardcoreDetourRobbedClothingChance;
    this.hardcoreDetourRobbedMoneyPercent = this.config.hardcoreDetourRobbedMoneyPercent;
    this.hardcoreStealEquippedON = this.config.hardcoreStealEquippedON;
    this.warningsON = this.config.warningsON;
    this.debugON = this.config.debugON;
    this.modON = this.config.modON;  
 
  } 

  public func updateResurrections(isSecondHeartInstalled: Bool) -> Void {    
    let relicMetaquestContribution: Int32 = this.getRelicMetaquestContribution() ;

    if (this.unlimitedResurrectON) || (isSecondHeartInstalled) {
      this.showDebugMessage( ">>> Santa Muerte: updateResurrections: skipped: isSecondHeartInstalled [" + ToString(isSecondHeartInstalled) + "] - unlimitedResurrectON [" + ToString(this.unlimitedResurrectON) + "]" );
      return;
    }

    if (!this.deathWhenImpersonatingJohnnyON) && (this.isPlayerImpersonatingJohnny()) {
      this.showDebugMessage( ">>> Santa Muerte: updateResurrections: skipped: deathWhenImpersonatingJohnnyON [" + ToString(this.deathWhenImpersonatingJohnnyON) + "] - isPlayerImpersonatingJohnny [" + ToString(this.isPlayerImpersonatingJohnny()) + "]" );
      return; 
    }

    this.showDebugMessage( ">>> Santa Muerte: updateResurrections: relicMetaquestContribution = " + ToString(relicMetaquestContribution) );
    if (this.santaMuerteLoreDifficultyON) {
      this.santaMuerteRelicDifficulty = this.santaMuerteLoreDifficulty;
    }

    this.updateMaxResurrections();
    this.incrementResurrections();
    this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCount going UP " );

    switch this.santaMuerteRelicDifficulty {
      case santaMuerteRelicMode.Low:
        if (RandRange(0,100) < (relicMetaquestContribution * 10)) {

          // Relic check successful, keep resurrection count level or add chance for a rebate
          if (RandRange(0,100) >= (100 - (4 * (relicMetaquestContribution)))) {
            this.decrementResurrections();
            this.decrementResurrections();
            this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCount going DOWN! " );

          }
        } 
        break; 
      case santaMuerteRelicMode.High: 
        if (RandRange(0,100) < (relicMetaquestContribution * 10)) {
          // Relic check successful, add chance for an extra removal of points
          if (RandRange(0,100) >= (100 - (4 * (relicMetaquestContribution)))) {
            this.incrementResurrections();
            this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCount going UP " );
          }  
        } 
        break;
    }

    // Safety reset in case of bad counter from previous versions
    if (this.resurrectCount < 0) {
      this.resurrectCount = this.resurrectCountMax;
    }    

    this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCount = " + ToString(this.resurrectCount) );
    this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCountMax = " + ToString(this.resurrectCountMax) );

    let message: String = StrReplace(SantaMuerteText.RESURRECT(), "%VAL%",  "-" + ToString(this.resurrectCount) + "-" + ToString(this.resurrectCountMax));

    if (this.warningsON) {
      this.player.SetWarningMessage(message, SimpleMessageType.Relic);  
    }
  } 

  public func incrementResurrections() -> Void {    

    this.resurrectCount += 1;  

    if (this.resurrectCount > this.resurrectCountMax) {
      this.resurrectCount = this.resurrectCountMax;
    }
  } 

  public func decrementResurrections() -> Void {    

    this.resurrectCount -= 1;  

    if (this.resurrectCount < 0) {
      this.resurrectCount = 0;
    }
  } 

  public func maxResurrectionReached(isSecondHeartInstalled: Bool) -> Bool {    
    this.updateMaxResurrections();

    if (this.unlimitedResurrectON) || (isSecondHeartInstalled) { 
      this.showDebugMessage( ">>> Santa Muerte: maxResurrectionReached: unlimitedResurrectON = " + ToString(this.unlimitedResurrectON) );
      this.showDebugMessage( ">>> Santa Muerte: maxResurrectionReached: isSecondHeartInstalled = " + ToString(isSecondHeartInstalled) );
      return false;
    }

    if (!this.deathWhenImpersonatingJohnnyON) && (this.isPlayerImpersonatingJohnny())  {
      this.showDebugMessage( ">>> Santa Muerte: maxResurrectionReached: Johnny cannot die ");
      return false;
    }

    if (this.resurrectCount <= this.resurrectCountMax) {
      this.showDebugMessage( ">>> Santa Muerte: maxResurrectionReached: resurrectCountMax NOT reached ");
      return false;
    }

    this.showDebugMessage( ">>> Santa Muerte: maxResurrectionReached: resurrectCountMax reached ");
    return true;
  } 

  public func getMaxResurrectionPercent() -> Float {    
    if (this.unlimitedResurrectON) { 
      return 100.0;
    }

    if (this.resurrectCountMax != 0) {
      return (Cast<Float>(this.resurrectCount) * 100.0) / Cast<Float>(this.resurrectCountMax) ;  
    } else {
      return 100.0;
    }

    
  } 

  public func updateMaxResurrections() -> Void {    

    let resurrectionFacts: Int32 = this.getResurrectionFacts();
    let playerLevelContribution: Int32 = this.getPlayerLevelContribution();
    let cyberwareContribution: Int32 = this.getCyberwareContribution();
    let relicMetaquestContribution: Int32 = this.getRelicMetaquestContribution();
    let tarotCardsContribution: Int32 = this.getTarotCardsContribution();

    // Check fact for Jackie's tomb 
    // Get player cyberware level

    // this.showDebugMessage( ">>> Santa Muerte: updateMaxResurrections: isRelicInstalled = " + ToString(this.isRelicInstalled()) );

    if this.isRelicInstalled() {
      if (this.capResurrectionsOverride==0) {

        // this.showDebugMessage( ">>> Santa Muerte: updateMaxResurrections: resurrectionFacts = " + ToString(resurrectionFacts) );
        // this.showDebugMessage( ">>> Santa Muerte: updateMaxResurrections: playerLevelContribution = " + ToString(playerLevelContribution) );
        // this.showDebugMessage( ">>> Santa Muerte: updateMaxResurrections: cyberwareContribution = " + ToString(cyberwareContribution) );
        // this.showDebugMessage( ">>> Santa Muerte: updateMaxResurrections: relicMetaquestContribution = " + ToString(relicMetaquestContribution) );
        // this.showDebugMessage( ">>> Santa Muerte: updateMaxResurrections: tarotCardsContribution = " + ToString(tarotCardsContribution) );

        this.resurrectCountMax = Cast<Int32>( (Cast<Float>(playerLevelContribution + relicMetaquestContribution + cyberwareContribution + resurrectionFacts + tarotCardsContribution)) * this.scaleResurrectionsModifier); 
      } else {
        this.resurrectCountMax = this.capResurrectionsOverride;
      }
 
    } else {
      this.resurrectCountMax = 0;
    }

    // this.showDebugMessage( ">>> Santa Muerte: updateMaxResurrections: resurrectCount = " + ToString(this.resurrectCount) );
    // this.showDebugMessage( ">>> Santa Muerte: updateMaxResurrections: resurrectCountMax = " + ToString(this.resurrectCountMax) );

  } 

  public func resurrectionCostsMemory() -> Bool {
    let statPoolsSystem: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(this.player.GetGame()); 
    let currentMemory: Float = statPoolsSystem.GetStatPoolValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatPoolType.Memory, false);
    let memoryConsumed: Bool = false;

    if currentMemory > 1.00 {
      statPoolsSystem.RequestChangingStatPoolValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatPoolType.Memory, -1.0, this.player, false, false);
      memoryConsumed = true;
    };

    return memoryConsumed;
  }

  /*

  https://github.com/DoctorPresto/Cyberpunk-File-Types/blob/main/questphase.txt
   
  sq018_03_padre_onspot 

  */


  public func isRelicInstalled() -> Bool {  
    // return GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q005_done") >= 1; // Heist + No tell motel
    return GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q005_done") >= 1; // After Heist + back to H10 building
  } 

  public func getResurrectionFacts() -> Int32 {  
    let jackieStayNotell: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q005_jackie_stay_notell") >= 1;
    let jackieToMama: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q005_jackie_to_mama") >= 1;
    let jackieAtVictors: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q005_14_body_at_victors") >= 1;

    let isVictorHUDInstalled: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q001_ripperdoc_done") >= 1;
    let isPhantomLiberyStandalone: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"ep1_standalone") >= 1;

    let factHeistDone: Int32 = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q005_done");

    let factMamaWellesMet: Int32 = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"sq018_01_mama_welles_talked") ;
    let factMandalaFound: Int32 = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"sq018_02_mandala") ;
    let factMistyInvited: Int32 = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"sq018_03a_misty_invited") ;
    let factOfrendaPicked: Int32 = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"sq018_ofrenda_picked") ;
    let factJackieFuneralDone: Int32 = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"sq018_done") ;
    let factMistyTarotDone: Int32 = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"mq033_misty_tarot_talk_needed") ;

    let _resurrectionFacts: Int32 = 0;

    _resurrectionFacts = factHeistDone * ( factMamaWellesMet + (factMandalaFound * 2) + factMistyInvited + factOfrendaPicked + (factJackieFuneralDone * 2) + (factMistyTarotDone * 2) );

    // Sets Lore Difficulty based on choice with Jackie's body
    if (jackieStayNotell) {
      this.santaMuerteLoreDifficulty = santaMuerteRelicMode.Low;
    }
    if (jackieToMama) {
      this.santaMuerteLoreDifficulty = santaMuerteRelicMode.Medium;
    }
    if (jackieAtVictors) {
      this.santaMuerteLoreDifficulty = santaMuerteRelicMode.High;
    }

    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: jackieStayNotell = " + ToString(jackieStayNotell) );
    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: jackieToMama = " + ToString(jackieToMama) );
    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: jackieAtVictors = " + ToString(jackieAtVictors) );
    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: isVictorHUDInstalled = " + ToString(isVictorHUDInstalled) );
    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: isPhantomLiberyStandalone = " + ToString(isPhantomLiberyStandalone) );
    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: factHeistDone = " + ToString(factHeistDone) );
    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: factMamaWellesMet = " + ToString(factMamaWellesMet) );
    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: factMandalaFound = " + ToString(factMandalaFound) );
    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: factMistyInvited = " + ToString(factMistyInvited) );
    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: factJackieFuneralDone = " + ToString(factJackieFuneralDone) );
    // this.showDebugMessage( ">>> Santa Muerte: getResurrectionFacts: factMistyTarotDone = " + ToString(factMistyTarotDone) ); 


    return(_resurrectionFacts);

  } 

  public func getPlayerLevelContribution() -> Int32 {   
    let playerLevel: Float = GameInstance.GetStatsSystem(this.player.GetGame()).GetStatValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatType.Level);
    let _playerLevelContribution: Int32 = 0;

    _playerLevelContribution = 5 + ((Cast<Int32>(playerLevel)) / 10);

    return(_playerLevelContribution);

  } 

  public func getCyberwareContribution() -> Int32 {   
    let m_statsSystem: wref<StatsSystem>;
    let _cyberwareContribution: Int32 = 0;

    m_statsSystem = GameInstance.GetStatsSystem(this.player.GetGame());
    _cyberwareContribution = (Cast<Int32>(m_statsSystem.GetStatValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatType.HumanityAllocated))) / 50;
    // this.showDebugMessage( ">>> Santa Muerte: updateMaxResurrections: cyberwareContribution = " + ToString(cyberwareContribution) );

    return(_cyberwareContribution);
  } 

  public func getRelicMetaquestContribution() -> Int32 {   
    let metaquestData: JournalMetaQuestScriptedData;
    let m_journalManager: wref<JournalManager>; 
    let _relicMetaquestContribution: Int32 = 0;

    m_journalManager = GameInstance.GetJournalManager(this.player.GetGame());
    metaquestData = m_journalManager.GetMetaQuestData(gamedataMetaQuest.MetaQuest3);
    _relicMetaquestContribution = (Cast<Int32>(metaquestData.percent))/10;

    // this.showDebugMessage( ">>> Santa Muerte: updateMaxResurrections: relicMetaquestContribution = " + ToString(_relicMetaquestContribution) ); 

    return(_relicMetaquestContribution);
  } 

  public func getTarotCardsContribution() -> Int32 {
    let manager: ref<JournalManager> = GameInstance.GetJournalManager(this.player.GetGame());
    let groups: array<wref<JournalEntry>>;
    let request: JournalRequestContext;
    let count: Int32 = 0;
    
    request.stateFilter.active = true;
    manager.GetTarots(request, groups);
    for group in groups {
      let entries: array<wref<JournalEntry>>;
      
      manager.GetChildren(group, request.stateFilter, entries);
      count += ArraySize(entries);
    }

    // this.showDebugMessage( ">>> Santa Muerte: getTarotCardsContribution: getTarotCardsContribution = " + ToString(count) );

    return count;
  }

/*
  public func getTarotCardsContribution() -> Int32 {   
    let journalManager: ref<JournalManager>;
    let journalContext: JournalRequestContext;
    let groupEntries: array<wref<JournalEntry>>;
    let tarotEntries: array<wref<JournalEntry>>;
    let entry: wref<JournalTarot>;
    let data: TarotCardData;
    let dataArray: array<TarotCardData>;
    let f: Int32;
    let i: Int32;
    let numberTarotCardsFound: Int32;

    journalManager = GameInstance.GetJournalManager(this.player.GetGame());
    journalContext.stateFilter.active = true;
    journalManager.GetTarots(journalContext, groupEntries); 

    i = 0;
    while i < ArraySize(groupEntries) {
      ArrayClear(tarotEntries);
      journalManager.GetChildren(groupEntries[i], journalContext.stateFilter, tarotEntries); 

      f = 0;
      while f < ArraySize(tarotEntries) {
        entry = tarotEntries[f] as JournalTarot;
        data.empty = false;
        data.index = entry.GetIndex();
        data.imagePath = entry.GetImagePart();
        data.label = entry.GetName();
        data.desc = entry.GetDescription();
        data.isEp1 = journalManager.IsEp1Entry(entry);
        ArrayPush(dataArray, data);
        f += 1;
      };
      i += 1;
    };

    numberTarotCardsFound = ArraySize(dataArray); 

    return numberTarotCardsFound;
  }
*/

  public func skipTimeWithBlackout(skipHoursAmount: Float) -> Void {
    let teleportSuccessful: Bool = false;
    let canBeTeleported: Bool = this.canBeTeleported();

    this.showDebugMessage( ">>> Santa Muerte: skipTime: lastInstigatorName = " + this.lastInstigatorName ); 
    this.showDebugMessage( ">>> Santa Muerte: skipTime: lastInstigatorFaction = " + this.lastInstigatorFaction ); 

    this.forceCombatExit();

    if (this.blackoutON) && (skipHoursAmount >= this.maxBlackoutTime) {
      // Apply blackout only after certain amount of time
      this.applyBlackout();
    }

    if ( RandRange(1,100) <= this.blackoutTeleportChance ) && (canBeTeleported)  && (this.teleportON) {
      // Test Detour teleports first
      if (this.blackoutDetourTeleportON) && (RandRange(1,100) <= this.blackoutDetourTeleportChance) {
          teleportSuccessful = this.tryResurrectionDetourTeleport();           
      }  

      // If Detour teleport failed, test safe teleports
      if (!teleportSuccessful) && ((this.blackoutSafeTeleportON) || (this.blackoutSafeTeleportHospitalON) ){
          if (this.safeTeleportFee>0) {
            if ( this.GetPlayerMoney() > this.safeTeleportFee ) {
              teleportSuccessful = this.tryResurrectionSafeTeleport();
              if (teleportSuccessful) {
                this.RemovePlayerMoney(this.safeTeleportFee);

                let message: String = StrReplace(SantaMuerteText.SAFETELEPORTFEE(), "%VAL%",  ToString(this.safeTeleportFee));
 
                this.player.SetWarningMessage(message);  
               }
            } else { 
              teleportSuccessful = false; 
            }

          } else {
            teleportSuccessful = this.tryResurrectionSafeTeleport(); 
          }
         
      }     

      if (teleportSuccessful) {
        // Force blackout on teleport
        this.applyBlackout();

        this.applyLoadingScreen();

        // Add 6 to 12 hours to account for transportation and healing
        skipHoursAmount += RandRangeF(6.0, 12.0);
      }
      
    }

    if (this.skipTimeON) && (!StatusEffectSystem.ObjectHasStatusEffectWithTag(this.player, n"NoTimeSkip")) {

      this.showDebugMessage( ">>> Santa Muerte: skipTime: skipHoursAmount = " + ToString(skipHoursAmount) ); 

      this.skipTimeForced(skipHoursAmount);
    } else {
      this.showDebugMessage( ">>> Santa Muerte: skipTime: Aborted due to timeskip restrictions" ); 
    }
  } 

  public func applyLoadingScreen() -> Void {
    this.showDebugMessage( ">>> Santa Muerte: applyLoadingScreen" );
    globalApplyLoadingScreen();

    // this.clearBlackout();
  }

  // @if(ModuleExists("DiverseDeathScreens.OnDeathEvent"))
  /*
  public func applyLoadingScreen() -> Void {
    let controller = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer").GetGameController() as inkGameController;

    if IsDefined(controller) { 
      let nextLoadingTypeEvt = new inkSetNextLoadingScreenEvent();
      nextLoadingTypeEvt.SetNextLoadingScreenType(inkLoadingScreenType.FastTravel);
      controller.QueueBroadcastEvent(nextLoadingTypeEvt);
        
      this.clearBlackout();
 
    };
  }
  */
  
  // @if(!ModuleExists("DiverseDeathScreens.OnDeathEvent"))
  // public func applyLoadingScreen() -> Void {
      // Do nothing
  // }

  public func skipTimeForced(skipHoursAmount: Float) -> Void {
      let timeSystem: ref<TimeSystem> = GameInstance.GetTimeSystem(this.player.GetGame());
      let currentTimestamp: Float = timeSystem.GetGameTimeStamp();
      let diff: Float = skipHoursAmount * 3600.0;
      let newTimeStamp: Float = currentTimestamp + diff;

      timeSystem.SetGameTimeBySeconds(Cast<Int32>(newTimeStamp));
      GameTimeUtils.FastForwardPlayerState(this.player);

      // this.clearBlackout();
 
  } 

  // FXRebootOpticsGrenade:NewFX('Reboot'   ,'FXRebootOpticsGrenade_Reboot'   ,'base\\fx\\player\\p_reboot_glitch\\p_reboot_glitch.effect')
  // FXRebootOpticsGrenade:NewFX('Burnout'  ,'FXRebootOpticsGrenade_Burnout'  ,'base\\fx\\player\\p_burnout_glitch\\p_burnout_glitch.effect')
  // FXRebootOpticsGrenade:NewFX('Blackwall','FXRebootOpticsGrenade_Blackwall','ep1\\fx\\quest\\q303\\voodoo_boys\\blackwall\\onscreen\\q303_blackwall_onscreen_contact.effect')
  // FXRebootOpticsGrenade:NewFX('Relic'    ,'FXRebootOpticsGrenade_Johnny'   ,'base\\fx\\player\\p_johnny_sickness_symptoms\\p_johnny_sickness_symptoms_blackout_short.effect')

  public func applyJohnnySickness() -> Void {
    let maxResurrectionPercent: Float;
    let sicknessDuration: Float;
    let m_statusEffectSystem: wref<StatusEffectSystem>;
    m_statusEffectSystem = GameInstance.GetStatusEffectSystem(this.player.GetGame());

    maxResurrectionPercent = this.getMaxResurrectionPercent();

    sicknessDuration = 2.0 + (maxResurrectionPercent / 10.0);

    if (maxResurrectionPercent <= 25.0) {
      StatusEffectHelper.ApplyStatusEffectForTimeWindow(this.player, t"BaseStatusEffect.JohnnySicknessLow", this.player.GetEntityID(), 0.00, sicknessDuration);
    }

    if (maxResurrectionPercent > 25.0) && (maxResurrectionPercent < 45.0) {
      StatusEffectHelper.ApplyStatusEffectForTimeWindow(this.player, t"BaseStatusEffect.JohnnySicknessMedium", this.player.GetEntityID(), 0.00, sicknessDuration);
    }

    if (maxResurrectionPercent > 45.0) && (maxResurrectionPercent < 65.0) {
      StatusEffectHelper.ApplyStatusEffectForTimeWindow(this.player, t"BaseStatusEffect.JohnnySicknessHeavy", this.player.GetEntityID(), 0.00, sicknessDuration);
    }

    if (maxResurrectionPercent > 65.0) && (maxResurrectionPercent < 85.0) {
      StatusEffectHelper.ApplyStatusEffectForTimeWindow(this.player, t"BaseStatusEffect.JohnnySicknessHeavy", this.player.GetEntityID(), 0.00, sicknessDuration);
    }

    if (maxResurrectionPercent >= 85.0) {
      // StatusEffectHelper.ApplyStatusEffectForTimeWindow(this.player, t"BaseStatusEffect.JohnnySicknessHeavy", this.player.GetEntityID(), 0.00, sicknessDuration);
      GameObjectEffectHelper.StartEffectEvent(this.player, n"p_songbird_sickness.effect", false);
    }

    // Trying to consumer 1 RAM to force a refresh of counter
    if (this.santaMuerteWidgetON) {
      this.resurrectionCostsMemory();      
    }

    // Remove blackwall effect in case it was added by Death Screens
    // GameObjectEffectHelper.BreakEffectLoopEvent(this.player, n"p_songbird_sickness.effect");

    // Attempt at removing second heart effect icon 
    // Commenting out because of hard crash when used here.
    // StatusEffectHelper.RemoveStatusEffect(this.player, t"BaseStatusEffect.SecondHeart");

    // Clear DarkFuture effect
    // GameInstance.GetQuestsSystem(this.player.GetGame()).SetFactStr("SantaMuerteDFState", 0);
  }
 
  public func applyBlackout() -> Void {
    let m_statusEffectSystem: wref<StatusEffectSystem>;
    m_statusEffectSystem = GameInstance.GetStatusEffectSystem(this.player.GetGame());

    if (this.blackoutON) {
      this.showDebugMessage( ">>> Santa Muerte: applyBlackout" ); 

      m_statusEffectSystem.ApplyStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.CyberwareInstallationAnimationBlackout");

    }
  } 

  public func clearBlackout() -> Void {
    let m_statusEffectSystem: wref<StatusEffectSystem>;
    m_statusEffectSystem = GameInstance.GetStatusEffectSystem(this.player.GetGame());

    if (this.blackoutON) {
      this.showDebugMessage( ">>> Santa Muerte: clearBlackout" ); 

      m_statusEffectSystem.RemoveStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.CyberwareInstallationAnimationBlackout");
    }
  } 
 
  public func forceBlackout() -> Void {
    let m_statusEffectSystem: wref<StatusEffectSystem>;
    m_statusEffectSystem = GameInstance.GetStatusEffectSystem(this.player.GetGame());

    this.showDebugMessage( ">>> Santa Muerte: forceBlackout" ); 
    m_statusEffectSystem.ApplyStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.CyberwareInstallationAnimationBlackout");

  } 

  public func clearCombatIfStuck() -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.player.GetPS();
    let hostileTargets: array<TrackedLocation>;

    hostileTargets = this.player.GetTargetTrackerComponent().GetHostileThreats(false);

    if ((this.player.IsInCombat()) && (ArraySize(hostileTargets)==0)) {
      this.showDebugMessage( ">>> Santa Muerte: clearCombatIfStuck: Stuck combat detected." ); 
      this.forceCombatExit() ;
    }
  }
 

  public func forceCombatExit() -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.player.GetPS();
    let currentTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.player.GetGame()));

    let j: Int32;
    let enableVisibilityEvt: ref<EnablePlayerVisibilityEvent>;
    let enableVisiblityDelay: Float;
    let exitCombatDelay: Float;
    let vanishEvt: ref<ExitCombatOnOpticalCamoActivatedEvent>;
    let hostileTarget: wref<GameObject>;
    let hostileTargetPuppet: wref<ScriptedPuppet>;
    let hostileTargets: array<TrackedLocation>;

    if this.player.IsInCombat() {
      this.showDebugMessage( ">>> Santa Muerte: forceCombatExit: Combat state detected." ); 

      // Apply code from Player -> ApplyStatusEffect
      exitCombatDelay = TweakDBInterface.GetFloat(t"Items.AdvancedOpticalCamoCommon.exitCombatDelay", 1.50);
      this.player.PromoteOpticalCamoEffectorToCompletelyBlocking(); 
      enableVisiblityDelay = GameInstance.GetStatsSystem(this.player.GetGame()).GetStatValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatType.OpticalCamoDuration);
      this.player.SetInvisible(true);
      hostileTargets = this.player.GetTargetTrackerComponent().GetHostileThreats(false);
      j = 0;
      while j < ArraySize(hostileTargets) {
        hostileTarget = hostileTargets[j].entity as GameObject;
        hostileTargetPuppet = hostileTarget as ScriptedPuppet;
        if IsDefined(hostileTargetPuppet) {
          hostileTargetPuppet.GetTargetTrackerComponent().DeactivateThreat(this.player);
        };
        vanishEvt = new ExitCombatOnOpticalCamoActivatedEvent();
        vanishEvt.npc = hostileTarget;
        GameInstance.GetDelaySystem(this.player.GetGame()).DelayEvent(this.player, vanishEvt, exitCombatDelay);
        j += 1;
      };
      enableVisibilityEvt = new EnablePlayerVisibilityEvent();
      GameInstance.GetDelaySystem(this.player.GetGame()).DelayEvent(this.player, enableVisibilityEvt, enableVisiblityDelay);
  

      // this.SetBlackboardIntVariable(GetAllBlackboardDefs().PlayerStateMachine.Combat, 2);
      // this.SendAnimFeatureData(false);
      // PlayerPuppet.ReevaluateAllBreathingEffects(this.m_owner as PlayerPuppet);
      // if !IsMultiplayer() && ScriptedPuppet.IsActive(this.m_owner) {
      //   GameInstance.GetStatPoolsSystem(this.m_owner.GetGame()).RequestSettingModifierWithRecord(Cast<StatsObjectID>(this.m_owner.GetEntityID()), gamedataStatPoolType.Health, gameStatPoolModificationTypes.Regeneration, t"BaseStatPools.PlayerBaseOutOfCombatHealthRegen");
      // };
      // ChatterHelper.TryPlayLeaveCombatChatter(this.m_owner);
      // GameInstance.GetAudioSystem(this.m_owner.GetGame()).NotifyGameTone(n"LeaveCombat");
      // GameInstance.GetAudioSystem(this.m_owner.GetGame()).HandleOutOfCombatMix(this.m_owner);
      // FastTravelSystem.RemoveFastTravelLock(n"InCombat", this.m_owner.GetGame());
      // GameObjectEffectHelper.BreakEffectLoopEvent(this.m_owner, n"stealth_mode");


      let invalidateEvent: ref<PlayerCombatControllerInvalidateEvent> = new PlayerCombatControllerInvalidateEvent();
      invalidateEvent.m_state = PlayerCombatState.OutOfCombat;
      this.player.QueueEvent(invalidateEvent);

      GameInstance.GetAudioSystem(this.player.GetGame()).NotifyGameTone(n"LeaveCombat");
      GameInstance.GetAudioSystem(this.player.GetGame()).HandleOutOfCombatMix(this.player);
      
      // 2024-12-07 - Testing shut down combat
      this.player.SetBlackboardIntVariable(GetAllBlackboardDefs().PlayerStateMachine.Combat, 2);   
      this.player.m_combatController.SendAnimFeatureData(false);
      PlayerPuppet.ReevaluateAllBreathingEffects(this.player as PlayerPuppet);
      // GameInstance.GetStatPoolsSystem(this.player.GetGame()).RequestSettingModifierWithRecord(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatPoolType.Health, gameStatPoolModificationTypes.Regeneration, t"BaseStatPools.PlayerBaseOutOfCombatHealthRegen");
      ChatterHelper.TryPlayLeaveCombatChatter(this.player);
      GameInstance.GetAudioSystem(this.player.GetGame()).NotifyGameTone(n"LeaveCombat");
      GameInstance.GetAudioSystem(this.player.GetGame()).HandleOutOfCombatMix(this.player);

      FastTravelSystem.RemoveFastTravelLock(n"InCombat", this.player.GetGame());
      GameObjectEffectHelper.BreakEffectLoopEvent(this.player, n"stealth_mode");   
 
    };

    this.clearBlackout();
  }


/*
  Didn't work to fix the stuck combat mode after resurrection:
  
    _playerPuppetPS.SetCombatExitTimestamp(currentTime);
    this.player.m_inCombat = false;
    this.player.SetIsBeingRevealed(false);
    this.player.m_hasBeenDetected = false;
    this.player.UpdateSecondaryVisibilityOffset(false);
    this.player.EnableCombatVisibilityDistances(false);
    this.player.UpdateVisibility();

    this.player.EnableInteraction(n"Revive", false);
*/

/*
    this.Revive(50.0);
    this.SetSlowMo(0.5, 2.0);

    this.showDebugMessage( "V is dead"  ); 

    this.OnResurrected();
    this.EnableInteraction(n"Revive", false);
    this.m_incapacitated = false;
    this.RefreshCPOVisionAppearance();
    this.CreateVendettaTimeDelayEvent();
    this.SetSenseObjectType(gamedataSenseObjectType.Player);
*/

  
  public func forceCameraReset() -> Void {
    let playerForward: Vector4 = this.player.GetWorldForward();
    let playerForwardAngle: EulerAngles = Vector4.ToRotation(playerForward);
    // let resetOrientation: EulerAngles = new EulerAngles(10, 0, 0);
    let resetPosition: Vector4 = new Vector4(0, 0, 0, 1.0);

    // this.player.GetFPPCameraComponent().ResetPitch();
    this.player.GetFPPCameraComponent().SetLocalOrientation(EulerAngles.ToQuat(playerForwardAngle));
    this.player.GetFPPCameraComponent().SetLocalPosition(resetPosition);
  }


  private func tryResurrectionSafeTeleport() -> Bool {
    let randNum: Int32;
    let teleportSuccessful: Bool = false;

    randNum = RandRange(0,100);

    if (this.blackoutSafeTeleportHospitalON)  {
      if (randNum >= 30) && (!(this.isInDogtown())) {
        this.showDebugMessage( ">>> Santa Muerte: Medevac to Hospital" ); 
        teleportSuccessful = this.tryTeleportMedicalCenter();
      }      
      if (randNum < 30) {
        this.showDebugMessage( ">>> Santa Muerte: Viktor only" ); 
        teleportSuccessful = this.tryTeleportViktor();
      }
    }

    if (this.blackoutSafeTeleportON)  {
      if (randNum < 90) && (randNum > 0) {
        this.showDebugMessage( ">>> Santa Muerte: Nearby RipperDoc" ); 
        teleportSuccessful = this.tryTeleportRipperDoc();
      }
    } 

    return teleportSuccessful;

  }
  
  private func tryTeleportMedicalCenter() -> Bool {
    let playerForward: Vector4 = this.player.GetWorldForward();
    let playerForwardAngle: EulerAngles = Vector4.ToRotation(playerForward);
    let rotation: EulerAngles;
    let position: Vector4;
    let isDestinationFound: Bool = false;

    //Player World Pos: Vector4[ X:-1367.995483, Y:1743.821655, Z:18.189995, W:1.000000 ]
    //Player World Rot: EulerAngles[ Pitch:-0.000000, Yaw:175.044250, Roll:0.000000 ]
    position = new Vector4(-1367.995483, 1743.821655, 18.189995, 1.000000);
    rotation = playerForwardAngle;
    isDestinationFound = true;

    GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(this.player, position, rotation);

    return isDestinationFound;

  }

  private func tryTeleportViktor()  -> Bool {
    let playerForward: Vector4 = this.player.GetWorldForward();
    let playerForwardAngle: EulerAngles = Vector4.ToRotation(playerForward);
    let rotation: EulerAngles;
    let position: Vector4;
    let isDestinationFound: Bool = false;

    // Viktor: 
    position = new Vector4(-1554.434, 1239.794, 11.520, 1.000000);
    rotation = playerForwardAngle;
    isDestinationFound = true;

    GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(this.player, position, rotation);

    return isDestinationFound;

  }
  
  private func tryTeleportRipperDoc() -> Bool{
    let playerForward: Vector4 = this.player.GetWorldForward();
    let playerForwardAngle: EulerAngles = Vector4.ToRotation(playerForward);
    let rotation: EulerAngles;
    let position: Vector4;
    let currentDistrict: gamedataDistrict = this.getCurrentDistrict();
    let randNum: Int32;
    let isDestinationFound: Bool = false;

    switch currentDistrict {
      case gamedataDistrict.Watson:
        // Doc Robert
        position = new Vector4(-1242.968, 1943.158, 8.066, 1.000000);
        rotation = playerForwardAngle; // new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.LittleChina:
        // Viktor: 
        position = new Vector4(-1554.434, 1239.794, 11.520, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Kabuki:
        // Instant Implants 
        position = new Vector4(-1040.569, 1443.039, 0.493, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Northside:
        // Cassius Ryder
        position = new Vector4(-1682.980, 2380.442, 18.344, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.ArasakaWaterfront:
        // Cassius Ryder
        position = new Vector4(-1682.980, 2380.442, 18.344, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.CityCenter:
        // City Center doc
        position = new Vector4(-2410.167, 393.338, 11.837, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Downtown:
        // City Center doc
        position = new Vector4(-2410.167, 393.338, 11.837, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.CorpoPlaza:
        // Nina Kraviz
        position = new Vector4(-40.149, -53.598, 7.180, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.Heywood:
        // Doc Ryder
        position = new Vector4(-2362.834, -927.831, 12.266, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Glen:
        // Doc Ryder
        position = new Vector4(-2362.834, -927.831, 12.266, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Wellsprings:
        // Doc Ryder
        position = new Vector4(-2362.834, -927.831, 12.266, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.VistaDelRey:
        // Arroyo Doc
        position = new Vector4(-1072.903, -1274.589, 11.457, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.Pacifica:
        // Voodoo Doc
        position = new Vector4(-2609.994, -2496.741, 17.335, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.WestWindEstate:
        // Voodoo Doc
        position = new Vector4(-2609.994, -2496.741, 17.335, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Coastview:
        // Voodoo Doc
        position = new Vector4(-2609.994, -2496.741, 17.335, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.SantoDomingo:
        // Arroyo Doc
        position = new Vector4(-1072.903, -1274.589, 11.457, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Arroyo:
        // Arroyo Doc
        position = new Vector4(-1072.903, -1274.589, 11.457, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.RanchoCoronado:
        // Doc Octavio 
        position = new Vector4(588.214, -2180.696, 42.437, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.Westbrook:
        // Nina Kraviz
        position = new Vector4(-40.149, -53.598, 7.180, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.JapanTown:
        // Japantown Ripper Doc
        position = new Vector4(-712.075, 871.053, 11.982, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.NorthOaks:
        // Nina Kraviz
        position = new Vector4(-40.149, -53.598, 7.180, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.CharterHill:
        // Nina Kraviz
        position = new Vector4(-40.149, -53.598, 7.180, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.Dogtown:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Church Clinic
          position = new Vector4(-1668.095, -2487.934, 37.151, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }  
        if (randNum > 20) && (randNum < 80) {
          // Doc Costyn Lahovary
          position = new Vector4(-2400.081, -2655.728, 27.842, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }  
        if (randNum <= 20) {
          // Doc Farida Clinic
          position = new Vector4(-1887.505, -2486.323, 28.052, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }  

        break;

      case gamedataDistrict.Badlands:
        // Doc Octavio 
        position = new Vector4(588.214, -2180.696, 42.437, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.NorthBadlands:
        // Doc Octavio 
        position = new Vector4(588.214, -2180.696, 42.437, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.SouthBadlands:
        // Doc Octavio 
        position = new Vector4(588.214, -2180.696, 42.437, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      default:
       // ABORT - could be in a unique place/quest related
        break;
    }

    if (isDestinationFound) {
      GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(this.player, position, rotation);      
    }

    return isDestinationFound;
    
  }

  private func tryResurrectionDetourTeleport() -> Bool {
    let randNum: Int32;
    let teleportSuccessful: Bool = false;

    // TO DO: Add more scenarios for 'detours'
    // this.showDebugMessage( ">>> Santa Muerte: skipTime: lastInstigatorName = " + this.lastInstigatorName ); 
    // this.showDebugMessage( ">>> Santa Muerte: skipTime: lastInstigatorFaction = " + this.lastInstigatorFaction ); 

    if ( !Equals( this.lastInstigatorFaction, "" ) && !Equals( this.lastInstigatorFaction, "Unknown" )) {
      teleportSuccessful = this.tryTeleportDetourByFaction(this.lastInstigatorFaction);
    }

    if (!teleportSuccessful) {
      teleportSuccessful = this.tryTeleportDetourByDistrict();
    }

    return teleportSuccessful;

  }

  private func tryTeleportDetourByDistrict() -> Bool{
    let playerForward: Vector4 = this.player.GetWorldForward();
    let playerForwardAngle: EulerAngles = Vector4.ToRotation(playerForward);
    let rotation: EulerAngles;
    let position: Vector4;
    let currentDistrict: gamedataDistrict = this.getCurrentDistrict();
    let randNum: Int32;
    let isDestinationFound: Bool = false;
    let triggerRobPlayer: Bool = true;

    switch currentDistrict {
      case gamedataDistrict.Watson:
        randNum = RandRange(0,100);

        if (randNum >= 20) {       // Back of Hospital
          position = new Vector4(-1409.463, 1857.142, 18.150, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
          triggerRobPlayer = false;
        }
        if (randNum <= 20) {
          // Rooftop Misty
          position = new Vector4(-1540.825, 1191.869, 57.000, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
          triggerRobPlayer = false;
        }        
        break;
      case gamedataDistrict.LittleChina:
        // Trash pile south west of Little China
        position = new Vector4(-1952.074, 997.060, 1.353, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Kabuki:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Kabuki temple
          position = new Vector4(-1164.046, 1765.699, 23.371, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
          triggerRobPlayer = false;
        }
        if (randNum > 20) && (randNum < 80) {
          // Dark alley
          position = new Vector4(-1188.267, 1205.526, 17.370, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum <= 20) {
          // Under overpass to Watson
          position = new Vector4(-1180.250, 1006.626, 0.221, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break;
      case gamedataDistrict.Northside:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Creepy Maelstrom BD shack 
          position = new Vector4(-1006.454, 3378.892, 8.540, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum > 20) && (randNum < 80) {
          // Oil Fields
          position = new Vector4(-1833.609, 3824.832, 5.484, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum <= 20) {
          // Northside beach dump
          position = new Vector4(-2346.953, 3687.689, 7.844, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }

        break;
      case gamedataDistrict.ArasakaWaterfront: 
        // Trash pile outside Konpeki Plaza
        position = new Vector4(-2174.469, 1904.703, 18.186, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.CityCenter:
        // Arasaka warehouse
        position = new Vector4(-1257.382, 429.609, 4.330, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Downtown:
        // Dino
        position = new Vector4(-40.149, -53.598, 7.180, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        triggerRobPlayer = false;
        break;
      case gamedataDistrict.CorpoPlaza:
        // Underwater - waterfront
        position = new Vector4(-1201.325, 685.873, -11.116, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.Heywood:
        // Padre
        position = new Vector4(-1807.022, -1281.709, 21.885, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        triggerRobPlayer = false;
        break;
      case gamedataDistrict.Glen:
        // Trash pile in Reconciliation Park
        position = new Vector4(-1561.247, -440.721, -11.796, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Wellsprings:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Valentinos scrap yard
          position = new Vector4(-506.051, -96.526, 7.770, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum < 80) {
          // Trash burning pits
          position = new Vector4(-2071.315, -1125.493, 10.963, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break;
      case gamedataDistrict.VistaDelRey:
        // Dark alley
        position = new Vector4(-605.527, -224.119, 7.678, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.Pacifica:
        // Homeless camp
        position = new Vector4(-2017.643, -2218.369, 19.741, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        triggerRobPlayer = false;
        break;
      case gamedataDistrict.WestWindEstate:
        // Beach Trash Pile
        position = new Vector4(-2672.360, -2340.655, 0.747, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Coastview:
        // Butcher shop
        position = new Vector4(-2286.622, -1931.526, 6.055, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.SantoDomingo:
        // Hazardous waste dumping ground
        position = new Vector4(-417.634, -2003.798, 6.860, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.Arroyo:
        // Trash pile under overpass
        position = new Vector4(157.737, -730.418, 4.276, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.RanchoCoronado:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Homeless camp
          position = new Vector4(449.555, -1686.285, 9.842, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
          triggerRobPlayer = false;
        }
        if (randNum >= 40) && (randNum < 80)  {
          // Dump near new tower
          position = new Vector4(908.807, -1545.698, 45.001, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum < 40) {
          // Warehouse
          position = new Vector4(1080.595, -722.294, 22.271, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break;

      case gamedataDistrict.Westbrook:
        // Trash pile under overpass
        position = new Vector4(-40.149, -53.598, 7.180, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.JapanTown:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Creepy Scav BD shack 
          position = new Vector4(-697.153, 956.792, 12.368, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum >= 40) && (randNum < 80)  {
          // Japantown reservoir
          position = new Vector4(-445.489, 417.814, 131.998, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        let isAutomaticLoveCompleted: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"sq032_q105_done") >= 1;
        if (randNum >= 20) && (randNum < 40) && (isAutomaticLoveCompleted) {
          // Fingers MD
          position = new Vector4(-569.782, 799.393, 24.908, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum < 20) {
          // Tyger Claw's Cages Hideout
          position = new Vector4(-529.289, 521.130, 18.297, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }

        break;
      case gamedataDistrict.NorthOaks:
        // Under overpass to Japantown
        position = new Vector4(-238.494, 1336.841, 33.166, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;
      case gamedataDistrict.CharterHill:
        // Elevated dumping ground
        position = new Vector4(-305.537, 631.754, 42.855, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        break;

      case gamedataDistrict.Dogtown:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Somi's favorite spot
          position = new Vector4(-1732.673, -2683.120, 78.083, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
          triggerRobPlayer = false;
        }
        if (randNum >= 60) && (randNum < 80) {
          // Water hole
          position = new Vector4(-1843.006, -2496.886, 25.165, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum >= 40) && (randNum < 60) {
          // Dogtown wasteland
          position = new Vector4(-1661.173, -2882.097, 79.999, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum < 40) {
          // Scav container
          position = new Vector4(-1777.360, -2160.756, 41.821, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break;

      case gamedataDistrict.Badlands:
        // Sunset Motel - room 102
        position = new Vector4(1662.659, -791.086, 49.826, 1.000000);
        rotation = playerForwardAngle;
        isDestinationFound = true;
        triggerRobPlayer = false;
        break;
      case gamedataDistrict.NorthBadlands:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Safe garage 
          position = new Vector4(2575.148, 0.298, 80.875, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
          triggerRobPlayer = false;
        }
        if (randNum <= 20) {
          // Trash Dump
          position = new Vector4(2329.168, -1826.530, 79.302, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break;
      case gamedataDistrict.SouthBadlands:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Trailer Arm Dealer
          position = new Vector4(131.666, -4679.567, 54.711, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
          triggerRobPlayer = false;
        }
        if (randNum <= 20) {
          // Gas station with Wraiths
          position = new Vector4(-1705.800, -5016.451, 80.346, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break;

      default:
       // ABORT - could be in a unique place/quest related
        break;
    }

    if (isDestinationFound) && (triggerRobPlayer) {
      if (this.hardcoreDetourRobbedON) {
        this.robPlayer();
      }
      this.showDebugMessage( ">>> Santa Muerte: Detour teleport by district" ); 
      this.showDebugMessage( ToString(position) ); 
      GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(this.player, position, rotation);      
    }

    return isDestinationFound;
    
  }


// 1. Cops Arrest - Jail teleport - pay jail fees
// 2. Killed in mission with friendly NPC - favorite Ripperdoc teleport - pay ripperdoc fees
// 3. Cops/Civilians murder - Hospital teleport - pay hospital fees
// 4. Gang murder - Alley way teleport - lose items with minor injuries
// 5. Gang purge = in a basement/sewers/junkyard with cyberware stripped, lost items and with serious injuries (and force time skip)

  private func tryTeleportDetourByFaction(faction: String) -> Bool{
    let playerForward: Vector4 = this.player.GetWorldForward();
    let playerForwardAngle: EulerAngles = Vector4.ToRotation(playerForward);
    let rotation: EulerAngles;
    let position: Vector4; 
    let currentDistrict: gamedataDistrict = this.getCurrentDistrict();
    let randNum: Int32;
    let isDestinationFound: Bool = false;

    // Leave 20% chance of failure to switch to regular detour teleports
    switch faction { 

      case "Mox":
        randNum = RandRange(0,100);
        if (randNum >= 40) {
          // JigJig Street
          position = new Vector4(-701.322, 827.524, 19.449, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum >= 20) && (randNum < 40)  {
          // Arasaka warehouse
          position = new Vector4(-1122.185, 1641.365, -2.056, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break; 

      case "Militech":
        randNum = RandRange(0,100);
        if (randNum >= 40) {
          // Northside industrial
          position = new Vector4(-1030.324, 2769.734, 20.062, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        } 
        if (randNum >= 20) && (randNum < 40) {
          // Militech warehouse
          position = new Vector4(-1720.908, 1889.363, 18.150, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break; 

      case "KangTao":
        randNum = RandRange(0,100);
        if (randNum >= 20) {
          // Arasaka warehouse
          position = new Vector4(-1669.258, 3433.807, -3.183, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break; 

      case "Animals":
        randNum = RandRange(0,100);
        // if (randNum >= 20) {
        //   // Arasaka warehouse
        //   position = new Vector4(-1257.382, 429.609, 4.330, 1.000000);
        //   rotation = playerForwardAngle;
        //   isDestinationFound = true;
        // }
        break; 

      case "Adelcaldos":
        randNum = RandRange(0,100);
        // if (randNum >= 20) {
        //   // Arasaka warehouse
        //   position = new Vector4(-1257.382, 429.609, 4.330, 1.000000);
        //   rotation = playerForwardAngle;
        //   isDestinationFound = true;
        // }
        break; 

      case "Nomads":
        randNum = RandRange(0,100);
        // if (randNum >= 20) {
        //   // Arasaka warehouse
        //   position = new Vector4(-1257.382, 429.609, 4.330, 1.000000);
        //   rotation = playerForwardAngle;
        //   isDestinationFound = true;
        // }
        break; 

      case "Netrunners":
        randNum = RandRange(0,100);
        // if (randNum >= 20) {
        //   // Arasaka warehouse
        //   position = new Vector4(-1257.382, 429.609, 4.330, 1.000000);
        //   rotation = playerForwardAngle;
        //   isDestinationFound = true;
        // }
        break; 

      case "Netwatch":
        randNum = RandRange(0,100);
        // if (randNum >= 20) {
        //   // Arasaka warehouse
        //   position = new Vector4(-1257.382, 429.609, 4.330, 1.000000);
        //   rotation = playerForwardAngle;
        //   isDestinationFound = true;
        // }
        break; 

      case "TraumaTeam":
        randNum = RandRange(0,100);
        // if (randNum >= 20) {
        //   // Arasaka warehouse
        //   position = new Vector4(-1257.382, 429.609, 4.330, 1.000000);
        //   rotation = playerForwardAngle;
        //   isDestinationFound = true;
        // }
        break; 

      case "Scavengers":
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Creepy Scav BD shack 
          position = new Vector4(-697.153, 956.792, 12.368, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum >= 40) && (randNum < 80) {
          // Northside dock
          position = new Vector4(-2114.406, 2692.709, 7.100, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        } 
        if (randNum >= 20) && (randNum < 40) {
          // Northside dock
          position = new Vector4(-1142.092, 2804.941, 7.156, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        } 

        break;

      case "Maelstrom":
        randNum = RandRange(0,100);

        if (randNum >= 40) {
          // Creepy Maelstrom BD shack 
          position = new Vector4(-1006.454, 3378.892, 8.540, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        } 
        if  (randNum >= 20) && (randNum < 40) {
          // Northside warehouse
          position = new Vector4(-1048.417, 3125.615, 7.118, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if  (randNum >= 20) && (randNum < 40) {
          // Trainyard cyber psycho
          position = new Vector4(-1093.090, 2840.227, 7.135, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if  (randNum >= 20) && (randNum < 40) {
          // Northside containers
          position = new Vector4(-1245.751, 2717.268, 7.294, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }

        break;

      case "Arasaka":
        randNum = RandRange(0,100);
        if (randNum >= 40) {
          // Arasaka warehouse
          position = new Vector4(-1257.382, 429.609, 4.330, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum >= 20) && (randNum < 40) {
          // Arasaka dock
          position = new Vector4(-2262.508, 2885.318, -6.049, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break; 

      case "NCPD":
        randNum = RandRange(0,100);
        if (randNum >= 20) {
          // Underwater - waterfront
          position = new Vector4(-1201.325, 685.873, -11.116, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break;
  
      case "Valentinos":
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Valentinos scrap yard
          position = new Vector4(-506.051, -96.526, 7.770, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if  (randNum >= 20) && (randNum < 80) {
          // Trash burning pits
          position = new Vector4(-2071.315, -1125.493, 10.963, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break; 
 
      case "VoodooBoys":
        randNum = RandRange(0,100);
        if (randNum >= 20) {
          // Butcher shop
          position = new Vector4(-2286.622, -1931.526, 6.055, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break;

      case "SixthStreet": 
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Hazardous waste dumping ground
          position = new Vector4(-417.634, -2003.798, 6.860, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if (randNum >= 40) && (randNum < 80)  {
          // Trash pile under overpass
          position = new Vector4(157.737, -730.418, 4.276, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if  (randNum >= 20) && (randNum < 40) {
          // Warehouse
          position = new Vector4(1080.595, -722.294, 22.271, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break; 

      case "TigerClaws":
        randNum = RandRange(0,100); 
        if (randNum >= 90) {
          // Tyger Claw's Trash Dump
          position = new Vector4(-458.519, 858.722, -4.567, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if  (randNum >= 20) && (randNum < 90)  {
          // Tyger Claw's Cages Hideout
          position = new Vector4(-529.289, 521.130, 18.297, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }  
        if  (randNum >= 20) && (randNum < 40)  {
          // Japantown reservoir
          position = new Vector4(-576.191, 994.016, 11.908, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }  
        break; 

      case "Barghest":
        // Additional safety to ensure this happens only in dogtown
        if (Equals(currentDistrict, gamedataDistrict.Dogtown)) {
          randNum = RandRange(0,100);
   
          if (randNum >= 60)  {
            // Water hole
            position = new Vector4(-1843.006, -2496.886, 25.165, 1.000000);
            rotation = playerForwardAngle;
            isDestinationFound = true;
          }
          if  (randNum >= 20) && (randNum < 60) {
            // Dogtown wasteland
            position = new Vector4(-1661.173, -2882.097, 79.999, 1.000000);
            rotation = playerForwardAngle;
            isDestinationFound = true;
          } 
          
        }
        break; 

      case "Wraiths":
        randNum = RandRange(0,100);

        if (randNum > 40) {
          // Gas station with Wraiths
          position = new Vector4(-1705.800, -5016.451, 80.346, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        if  (randNum >= 20) && (randNum <= 40) {
          // Trash Dump
          position = new Vector4(2329.168, -1826.530, 79.302, 1.000000);
          rotation = playerForwardAngle;
          isDestinationFound = true;
        }
        break;

      default:
       // ABORT - could be in a unique place/quest related
        break;
    }

    if (isDestinationFound) {
      if (this.hardcoreDetourRobbedON) {
        this.robPlayer();
      }
      this.showDebugMessage( ">>> Santa Muerte: Detour teleport by faction" ); 
      this.showDebugMessage( ToString(position) ); 
      GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(this.player, position, rotation);      
    }

    return isDestinationFound;
  }

  private func getCurrentDistrict() -> gamedataDistrict {
    let preventionSys: ref<PreventionSystem>;
    preventionSys =  this.player.GetPreventionSystem();
    return preventionSys.m_districtManager.GetCurrentDistrict().GetDistrictRecord().Type();
  }

  private func isPlayerInGenericDistrict() -> Bool {
    let currentDistrict: gamedataDistrict = this.getCurrentDistrict();
    let isDestinationFound: Bool = false;

    switch currentDistrict {
      case gamedataDistrict.Watson:
        this.showDebugMessage( ">>> Santa Muerte: Player in Watson" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.LittleChina:
        this.showDebugMessage( ">>> Santa Muerte: Player in Watson (LittleChina)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.Northside:
        this.showDebugMessage( ">>> Santa Muerte: Player in Watson (Northside)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.Kabuki:
        this.showDebugMessage( ">>> Santa Muerte: Player in Watson (Kabuki)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.ArasakaWaterfront:
        this.showDebugMessage( ">>> Santa Muerte: Player in Watson (ArasakaWaterfront)" ); 
        isDestinationFound = true;
        break;

      case gamedataDistrict.CityCenter:
        this.showDebugMessage( ">>> Santa Muerte: Player in City Center" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.Downtown:
        this.showDebugMessage( ">>> Santa Muerte: Player in City Center (Downtown)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.CorpoPlaza:
        this.showDebugMessage( ">>> Santa Muerte: Player in City Center (Corpo Plaza)" ); 
        isDestinationFound = true;
        break;

      case gamedataDistrict.Heywood:
        this.showDebugMessage( ">>> Santa Muerte: Player in Heywood" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.Glen:
        this.showDebugMessage( ">>> Santa Muerte: Player in Heywood (Glen)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.Wellsprings:
        this.showDebugMessage( ">>> Santa Muerte: Player in Heywood (Wellsprings)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.VistaDelRey:
        this.showDebugMessage( ">>> Santa Muerte: Player in Heywood (Vista del Rey)" ); 
        isDestinationFound = true;
        break;

      case gamedataDistrict.Pacifica:
        this.showDebugMessage( ">>> Santa Muerte: Player in Pacifica (WestWindEstate)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.WestWindEstate:
        this.showDebugMessage( ">>> Santa Muerte: Player in Pacifica (WestWindEstate)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.Coastview:
        this.showDebugMessage( ">>> Santa Muerte: Player in Pacifica (Coastview)" ); 
        isDestinationFound = true;
        break;

      case gamedataDistrict.SantoDomingo:
        this.showDebugMessage( ">>> Santa Muerte: Player in Santo Domingo" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.Arroyo:
        this.showDebugMessage( ">>> Santa Muerte: Player in Santo Domingo (Arroyo)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.RanchoCoronado:
        this.showDebugMessage( ">>> Santa Muerte: Player in Santo Domingo (RanchoCoronado)" ); 
        isDestinationFound = true;
        break;

      case gamedataDistrict.Westbrook:
        this.showDebugMessage( ">>> Santa Muerte: Player in Westbrook" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.JapanTown:
        this.showDebugMessage( ">>> Santa Muerte: Player in Westbrook (JapanTown)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.NorthOaks:
        this.showDebugMessage( ">>> Santa Muerte: Player in Westbrook (NorthOaks)" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.CharterHill:
        this.showDebugMessage( ">>> Santa Muerte: Player in Westbrook (CharterHill)" ); 
        isDestinationFound = true;
        break;

      case gamedataDistrict.Dogtown:
        this.showDebugMessage( ">>> Santa Muerte: Player in Dogtown" ); 
        isDestinationFound = true;
        break;

      case gamedataDistrict.Badlands:
        this.showDebugMessage( ">>> Santa Muerte: Player in Badlands" ); 
        isDestinationFound = true;
        break;
      case gamedataDistrict.NorthBadlands:
        this.showDebugMessage( ">>> Santa Muerte: Player in Badlands (NorthBadlands)" ); 
        isDestinationFound = true;
        break; 
      case gamedataDistrict.SouthBadlands:
        this.showDebugMessage( ">>> Santa Muerte: Player in Badlands (SouthBadlands)" ); 
        isDestinationFound = true;
        break;

      default:
        this.showDebugMessage( ">>> Santa Muerte: Player is elsewhere" ); 
        // ABORT - could be in a unique place/quest related
        isDestinationFound = false;
        break;
    }

    return isDestinationFound;
    
  }

  private final func canBeTeleported() -> Bool {
    let bb: ref<IBlackboard> = this.player.GetPlayerStateMachineBlackboard();

    this.showDebugMessage(">>> Santa Muerte: Teleport check");

    let endgameStarted: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q115_embers_elevator_unlocked") >= 1);
    let endgameDone: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"loaded_ponr_save") >= 1);
    let endgame: Bool = (endgameStarted) && (!endgameDone);

    let playerInsideDogtown: Bool = GameInstance.GetPreventionSpawnSystem(this.player.GetGame()).IsPlayerInDogTown();
    this.showDebugMessage( s">>>    Player in Dogtown " + ToString(playerInsideDogtown));

    let dogtownIntroStarted: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q301_sb_agreed") >= 1);
    let dogtownIntroDone: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q302_done") >= 1);
    let dogtownIntroFailed: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q302_failed") >= 1);
    let dogtownIntroEp1Over: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q302_ep1_over") >= 1);
    let dogtownIntroCalienteDone: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q302_caliente_finished") >= 1);
    let dogtownIntroEnded: Bool = (dogtownIntroDone) || (dogtownIntroFailed) || (dogtownIntroEp1Over) || (dogtownIntroCalienteDone);
    this.showDebugMessage( s">>>    dogtownIntroStarted \(dogtownIntroStarted)");
    this.showDebugMessage( s">>>    dogtownIntroDone \(dogtownIntroDone)");
    this.showDebugMessage( s">>>    dogtownIntroFailed \(dogtownIntroFailed)");
    this.showDebugMessage( s">>>    dogtownIntroEp1Over \(dogtownIntroEp1Over)");
    this.showDebugMessage( s">>>    dogtownIntroCalienteDone \(dogtownIntroCalienteDone)");
    let dogtownIntro: Bool = (dogtownIntroStarted) && (!dogtownIntroEnded);
    this.showDebugMessage( s">>>    dogtownIntro \(dogtownIntro)");

    let somiStadiumStarted: Bool = (playerInsideDogtown) && (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q304_started") >= 1);
    let somiStadiumDone: Bool = (playerInsideDogtown) && (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q304_done") >= 1);
    let somiStadium: Bool = (somiStadiumStarted) && (!somiStadiumDone);
    this.showDebugMessage( s">>>    somiStadium \(somiStadium)");

    let cynosureStarted: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q305_started") >= 1);
    let cynosureDone: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q305_done") >= 1);
    let cynosure: Bool = (cynosureStarted) && (!cynosureDone);
    this.showDebugMessage( s">>>    cynosure \(cynosure)");

    let dogtown: Bool = (dogtownIntro) || (somiStadium) || (cynosure);

    let isInNamedDistrict: Bool = (!this.isPlayerInGenericDistrict());

    let isImpersonating: Bool = this.isPlayerImpersonating();

    let paused: Bool = GameInstance.GetTimeSystem(this.player.GetGame()).IsPausedState();
    let noTimeSkip: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.player, n"NoTimeSkip"); 
    let noFastTravel: Bool = StatusEffectSystem.ObjectHasStatusEffect(this.player, t"GameplayRestriction.BlockFastTravel");

    let tier: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.HighLevel);
    let scene: Bool = tier >= EnumInt(gamePSMHighLevel.SceneTier3) && tier <= EnumInt(gamePSMHighLevel.SceneTier5);

    let mounted: Bool = VehicleComponent.IsMountedToVehicle(this.player.GetGame(), this.player);
    let swimming: Bool = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Swimming) == EnumInt(gamePSMSwimming.Diving);
    let carrying: Bool = bb.GetBool(GetAllBlackboardDefs().PlayerStateMachine.Carrying);
    let lore_animation: Bool = bb.GetBool(GetAllBlackboardDefs().PlayerStateMachine.IsInLoreAnimationScene);

    let training_bot: Bool = Equals(this.lastInstigatorName, "Training Bot");

    if endgame || dogtown || isImpersonating || isInNamedDistrict || paused || noTimeSkip || noFastTravel || scene || mounted || swimming || carrying || lore_animation || training_bot {
      this.showDebugMessage( s">>> Santa Muerte: Teleport canceled: ");
      this.showDebugMessage( s">>>    Endgame \(endgame)"); 
      this.showDebugMessage( s">>>    dogtown \(dogtown)"); 
      this.showDebugMessage( s">>>    isImpersonating \(isImpersonating)"); 
      this.showDebugMessage( s">>>    isInNamedDistrict \(isInNamedDistrict)"); 
      this.showDebugMessage( s">>>    paused: \(paused)"); 
      this.showDebugMessage( s">>>    noTimeSkip: \(noTimeSkip)"); 
      this.showDebugMessage( s">>>    noFastTravel: \(noFastTravel)");
      this.showDebugMessage( s">>>    scene: \(scene)"); 
      this.showDebugMessage( s">>>    mounted: \(mounted)");
      this.showDebugMessage( s">>>    swimming: \(swimming)");
      this.showDebugMessage( s">>>    carrying: \(carrying)");
      this.showDebugMessage( s">>>    lore_animation: \(lore_animation)");
      this.showDebugMessage( s">>>    training_bot: \(training_bot)");
      return false;
    };

    return true;
  }

  private final func isInDogtown() -> Bool {
    let currentDistrict: gamedataDistrict = this.getCurrentDistrict();
    
    return Equals(currentDistrict, gamedataDistrict.Dogtown);
  }

  private final func isPlayerImpersonating() -> Bool {
    // let mainObj: wref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.player.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    // let controlledObj: wref<PlayerPuppet> = GameInstance.GetPlayerSystem(this.player.GetGame()).GetLocalPlayerControlledGameObject() as PlayerPuppet;
    let controlledObjRecordID: TweakDBID = this.player.GetRecord().GetID() ; // controlledObj.GetRecordID();
    let isImpersonating: Bool = false;

    switch controlledObjRecordID {
      case t"Character.johnny_replacer":
        isImpersonating=true;
        break;
      case t"Character.q000_vr_replacer":
        isImpersonating=true;
        break;
      case t"Character.mq304_assassin_replacer_male":
        isImpersonating=true;
        break;
      case t"Character.mq304_assassin_replacer_female":
        isImpersonating=true;
        break;
      case t"Character.Player_Puppet_Base":
        isImpersonating=false;
        break;
      case t"Character.kurt_replacer":
        isImpersonating=true;
        break;
      default:
        isImpersonating=false;
    };

    return isImpersonating;
  }


  private final func isPlayerImpersonatingJohnny() -> Bool {
    return this.player.IsJohnnyReplacer();
  }


/* 
  HARDCORE MODE: STRIPPED AND LEFT FOR DEAD
*/
// From: public class InvisibleSceneStash extends Device {

  protected cb func robPlayer() -> Bool {
    let i: Int32;
    let id: ItemID;
    let itemList: array<ItemID>;
    // let player: ref<PlayerPuppet> = GetPlayer(this.GetGame());
    let equipmentSystem: ref<EquipmentSystem>;
    let equipmentData: ref<EquipmentSystemPlayerData> = EquipmentSystem.GetData(this.player);
    let slotList: array<gamedataEquipmentArea> = this.GetSlots(equipmentData.IsBuildCensored());
    let unequipSetRequest: ref<QuestDisableWardrobeSetRequest> = new QuestDisableWardrobeSetRequest();
    equipmentSystem = EquipmentSystem.GetInstance(this.player);
    unequipSetRequest.owner = this.player;

    // Equipped items
    i = 0;
    while i < ArraySize(slotList) {
      id = equipmentData.GetActiveItem(slotList[i]);
      if ItemID.IsValid(id) {
        ArrayPush(itemList, id);
        equipmentSystem.QueueRequest(this.CreateUnequipRequest(this.player, slotList[i], 0));

        if (Equals(slotList[i], gamedataEquipmentArea.Weapon)) {
          equipmentSystem.QueueRequest(this.CreateUnequipRequest(this.player, slotList[i], 1));
          equipmentSystem.QueueRequest(this.CreateUnequipRequest(this.player, slotList[i], 2));
        }
      };
      i += 1;
    };


    // Steal all equipped items
    if (this.hardcoreStealEquippedON) {
      for itemID in itemList { 
           GameInstance.GetTransactionSystem(this.player.GetGame()).RemoveItem(this.player, itemID, 1);
      }      
    }

    // Note: Hardcore mode - stripped items are lost forever
    //        Maybe extend to a safe locker at some point
    if (RandRange(1,100) <= this.hardcoreDetourRobbedChance) {
      this.disposeItems(itemList);

      // Remove percent of player money
      // Set up Mod Settings later
      if (this.hardcoreDetourRobbedMoneyPercent > 0) {
        this.RemovePlayerMoneyPercent(this.hardcoreDetourRobbedMoneyPercent);
      }
    }

    equipmentSystem.QueueRequest(unequipSetRequest);

  }

  private final const func GetSlots(censored: Bool) -> array<gamedataEquipmentArea> {
    let slots: array<gamedataEquipmentArea>;
    ArrayPush(slots, gamedataEquipmentArea.Weapon);  
    ArrayPush(slots, gamedataEquipmentArea.Face);
    ArrayPush(slots, gamedataEquipmentArea.Head);
    ArrayPush(slots, gamedataEquipmentArea.Feet);
    ArrayPush(slots, gamedataEquipmentArea.Legs);
    ArrayPush(slots, gamedataEquipmentArea.InnerChest);
    ArrayPush(slots, gamedataEquipmentArea.OuterChest);
    ArrayPush(slots, gamedataEquipmentArea.Outfit);
    if !censored {
      ArrayPush(slots, gamedataEquipmentArea.UnderwearBottom);
      ArrayPush(slots, gamedataEquipmentArea.UnderwearTop);
    };
    return slots;
  }

  private final const func CreateUnequipRequest(player: ref<PlayerPuppet>, area: gamedataEquipmentArea, slotIndex: Int32 ) -> ref<UnequipRequest> {
    let unequipRequest: ref<UnequipRequest> = new UnequipRequest();
    unequipRequest.owner = player;
    unequipRequest.slotIndex = slotIndex;
    unequipRequest.areaType = area;
    return unequipRequest;
  }

  public final func disposeItems(itemList: array<ItemID>) -> Void {
    let i: Int32; 
    let item: ItemModParams;
    let m_inventoryManager: wref<InventoryDataManagerV2> = EquipmentSystem.GetData(this.player).GetInventoryManager();

    // Add chance of rest of inventory being stolen
    for itemData in m_inventoryManager.GetPlayerInventoryData() { 
      let itemID = itemData.ID;

      if this.IsValidItem(itemData) {
        if (RandRange(1,100) <= this.hardcoreDetourRobbedClothingChance) {
          // Tentative solution to record list of lost items
          // ArrayPush(this.m_storedItems, itemID);
     
          GameInstance.GetTransactionSystem(this.player.GetGame()).RemoveItem(this.player, itemID, 1);

        }

      }
    }
 
  }

  public func IsValidItem(itemData: InventoryItemData) -> Bool { 
    let itemRecordId = ItemID.GetTDBID(itemData.ID);
    let itemCategory: gamedataItemCategory = RPGManager.GetItemCategory(itemData.ID);
    let itemType: gamedataItemType = InventoryItemData.GetGameItemData(itemData).GetItemType();
    let isValid: Bool = true;

    // let itemRecord = TweakDBInterface.GetClothingRecord(itemRecordId);

    // Exclude unequipable items
    if InventoryItemData.GetGameItemData(itemData).HasTag(n"UnequipBlocked") || InventoryItemData.GetGameItemData(itemData).HasTag(n"Quest") {
      isValid = false;
    };

    // Exclude equipped cyberware 
    if (RPGManager.IsItemCyberware(itemData.ID)) || (RPGManager.IsItemTypeCyberwareWeapon(itemType)) {
      isValid = false;
    }

    // Exclude inhalers and injectors
    if Equals(itemType, gamedataItemType.Con_Inhaler) || Equals(itemType, gamedataItemType.Con_Injector) {
      isValid = false;
    }

    // return IsDefined(itemRecord);
    return isValid;
  }


  private final func RemovePlayerMoneyPercent(percentAmount: Int32) -> Bool {
    let gi: GameInstance = this.player.GetGame(); 
    let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gi);
    let currentPlayerAmount = transactionSystem.GetItemQuantity(this.player, MarketSystem.Money());

    return transactionSystem.RemoveItem(this.player, MarketSystem.Money(), (currentPlayerAmount / 100) * percentAmount );
  }

  private final func RemovePlayerMoney(removeAmount: Int32) -> Bool {
    let gi: GameInstance = this.player.GetGame(); 
    let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gi);
    let currentPlayerAmount = transactionSystem.GetItemQuantity(this.player, MarketSystem.Money());

    return transactionSystem.RemoveItem(this.player, MarketSystem.Money(), removeAmount );
  }

  private final func GetPlayerMoney() -> Int32 {
    let gi: GameInstance = this.player.GetGame(); 
    let transactionSystem: ref<TransactionSystem> = GameInstance.GetTransactionSystem(gi);
    let currentPlayerAmount = transactionSystem.GetItemQuantity(this.player, MarketSystem.Money());

    return currentPlayerAmount;
  }
/* 
let currentValue: Float = itemData.GetStatValueByType(this.m_statType);

telemetryItem.friendlyName = InventoryItemData.GetGameItemData(inventoryItemData).GetNameAsString();
telemetryItem.localizedName = InventoryItemData.GetName(inventoryItemData);
telemetryItem.itemID = InventoryItemData.GetID(inventoryItemData);
telemetryItem.quality = InventoryItemData.GetComparedQuality(inventoryItemData);
telemetryItem.itemType = InventoryItemData.GetItemType(inventoryItemData);
telemetryItem.itemLevel = InventoryItemData.GetItemLevel(inventoryItemData);
telemetryItem.iconic = InventoryItemData.GetGameItemData(inventoryItemData).GetStatValueByType(gamedataStatType.IsItemIconic) > 0.00;

NotEquals(this.GetItemData().GetItemType(), gamedataItemType.Con_Skillbook)


  public final static func IsItemWeapon(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemCategory(itemID), gamedataItemCategory.Weapon);
  }

  public final static func IsItemClothing(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemCategory(itemID), gamedataItemCategory.Clothing);
  }

  public final static func IsItemCyberware(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemCategory(itemID), gamedataItemCategory.Cyberware);
  }

  public final static func IsItemGadget(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemCategory(itemID), gamedataItemCategory.Gadget);
  }

  public final static func IsItemProgram(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemType(itemID), gamedataItemType.Prt_Program);
  }

  public final static func IsItemMisc(itemID: ItemID) -> Bool {
    return Equals(RPGManager.GetItemType(itemID), gamedataItemType.Gen_Misc);
  }
*/

/* 
  PERMADEATH TEST
*/

  public func markGameForPermaDeath() -> Void { 
    // let SavedGamesController: ref<LoadGameMenuGameController> = new LoadGameMenuGameController();
    // SavedGamesController.setGameForPermaDeath();

    if ((!this.isRelicInstalled()) || (!this.modON) ) {
      this.showDebugMessage( ">>> Santa Muerte: markGameForPermaDeath: skipped: mod is not active" );
      return;
    }

    // Guardrails to avoid setting permadeath when it is not needed
    if (this.unlimitedResurrectON) {
      this.showDebugMessage( ">>> Santa Muerte: markGameForPermaDeath: skipped: unlimitedResurrectON [" + ToString(this.unlimitedResurrectON) + "]" );
      return;
    }

    if (!this.deathWhenImpersonatingJohnnyON) && (this.isPlayerImpersonatingJohnny()) {
      this.showDebugMessage( ">>> Santa Muerte: markGameForPermaDeath: skipped: deathWhenImpersonatingJohnnyON [" + ToString(this.deathWhenImpersonatingJohnnyON) + "] - isPlayerImpersonatingJohnny [" + ToString(this.isPlayerImpersonatingJohnny()) + "]" );
      return; 
    }

    if this.maxResurrectionReached(false) {
      // Send signal to CET to write flag
      GameInstance.GetQuestsSystem(this.player.GetGame()).SetFactStr("MarkPermadeath", 1);
    } else {
      if this.darkFutureEffectON {
        if (this.getMaxResurrectionPercent() < 50.0) {
            // Resurrections are punishing at first
            GameInstance.GetQuestsSystem(this.player.GetGame()).SetFactStr("SantaMuerteDFState", 2);

          } else {
            // With less than 50% resurrections left, resurrections have a healing effect
            GameInstance.GetQuestsSystem(this.player.GetGame()).SetFactStr("SantaMuerteDFState", 1);
          }
      }
    }

    this.showDebugMessage( ">>> Santa Muerte: Final Death" ); 
    // this.tryPermadeathExit();
  }


  public func tryPermadeathExit() -> Void {
    let game = this.player.GetGame();
    let factValue = GameInstance.GetQuestsSystem(game).GetFactStr("PermadeathTriggered");
    let m_statusEffectSystem: wref<StatusEffectSystem>;
    m_statusEffectSystem = GameInstance.GetStatusEffectSystem(this.player.GetGame());
 
    let message: String = SantaMuerteText.PERMADEATH();

    this.player.SetWarningMessage(message, SimpleMessageType.Relic);  

    // Show death overlay

    m_statusEffectSystem.ApplyStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.CyberwareInstallationAnimationBlackout");
    m_statusEffectSystem.ApplyStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.ForceKill");

  }


/* 
  SHOWMESSAGE OVERRIDE FOR DEBUGGING
*/
  private func showDebugMessage(debugMessage: String) {
    // LogChannel(n"DEBUG", debugMessage ); 
  }
 
}

// Moving this code here for compatibility with Codeware
@if(ModuleExists("Codeware"))
public func globalApplyLoadingScreen() -> Void {
  let controller = GameInstance.GetInkSystem().GetLayer(n"inkHUDLayer").GetGameController() as inkGameController;

  if IsDefined(controller) { 
    let nextLoadingTypeEvt = new inkSetNextLoadingScreenEvent();
    nextLoadingTypeEvt.SetNextLoadingScreenType(inkLoadingScreenType.FastTravel);
    controller.QueueBroadcastEvent(nextLoadingTypeEvt);
  };
} 

@if(!ModuleExists("Codeware"))
public func globalApplyLoadingScreen() -> Void {
    // Do nothing
}
 



