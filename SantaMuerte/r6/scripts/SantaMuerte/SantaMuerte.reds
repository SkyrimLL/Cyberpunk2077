/*
For redscript mod developers

:: Replaced methods
@replaceMethod(PlayerPuppet) public final func EvaluateEncumbrance() -> Void 

:: Added fields

:: New classes
public class SantaMuerteTracking 
*/  

public class SantaMuerteTracking extends ScriptedPuppetPS {
  public let player: wref<PlayerPuppet>; 

  public persistent let resurrectCount:  Int32;

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
  public let maxSkippedTime: Float;
  public let blackoutON: Bool;
  public let teleportON: Bool;
  public let blackoutTeleportChance: Int32;
  public let blackoutSafeTeleportON: Bool;  
  public let blackoutSafeTeleportChance: Int32;
  public let blackoutDetourTeleportON: Bool;  
  public let blackoutDetourTeleportChance: Int32;
  public let santaMuerteWidgetON: Bool;
  public let informativeHUDCOmpatibilityON: Bool;

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
    this.teleportON = this.config.teleportON;
    this.maxSkippedTime = this.config.maxSkippedTime;
    this.blackoutTeleportChance = this.config.blackoutTeleportChance;
    this.blackoutSafeTeleportON = this.config.blackoutSafeTeleportON;
    this.blackoutSafeTeleportChance = this.config.blackoutSafeTeleportChance;
    this.blackoutDetourTeleportON = this.config.blackoutDetourTeleportON;
    this.blackoutDetourTeleportChance = this.config.blackoutDetourTeleportChance;
    this.santaMuerteWidgetON = this.config.santaMuerteWidgetON;
    this.informativeHUDCOmpatibilityON = this.config.informativeHUDCOmpatibilityON;
    this.warningsON = this.config.warningsON;
    this.debugON = this.config.debugON;
    this.modON = this.config.modON;  
  } 

  public func updateResurrections(isSecondHeartInstalled: Bool) -> Void {    
    let relicMetaquestContribution: Int32 = this.getRelicMetaquestContribution() ;
    // this.showDebugMessage( ">>> Santa Muerte: updateResurrections: relicMetaquestContribution = " + ToString(relicMetaquestContribution) );
    if (this.santaMuerteLoreDifficultyON) {
      this.santaMuerteRelicDifficulty = this.santaMuerteLoreDifficulty;
    }

    switch this.santaMuerteRelicDifficulty {
    case santaMuerteRelicMode.Low:
      if (RandRange(0,100) < (relicMetaquestContribution * 10)) {
        // Relic check successful, keep resurrection count level or add chance for a rebate
        if (RandRange(0,100) >= (100 - (4 * (relicMetaquestContribution)))) {
          this.decrementResurrections();
          // this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCount going DOWN! " );

        } else {
          // this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCount unchanged " );

        }

      } else {
        // Relic check failed - increase resurrection count towards Max value
        this.incrementResurrections();
        // this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCount going UP " );

      }
      break;
    case santaMuerteRelicMode.Medium:
      this.incrementResurrections();
      break;
    case santaMuerteRelicMode.High:
      this.incrementResurrections(); 

      if (RandRange(0,100) < (relicMetaquestContribution * 10)) {
        // Relic check successful, add chance for an extra removal of points
        if (RandRange(0,100) >= (100 - (4 * (relicMetaquestContribution)))) {
          this.incrementResurrections();
          // this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCount going UP " )
        }  
      } 
      break;
      break;

    }

    
    this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCount = " + ToString(this.resurrectCount) );
    this.showDebugMessage( ">>> Santa Muerte: updateResurrections: resurrectCountMax = " + ToString(this.resurrectCountMax) );

    let message: String = StrReplace(SantaMuerteText.RESURRECT(), "%VAL%",  "-" + ToString(this.resurrectCount) + "-" + ToString(this.resurrectCountMax));

    if (this.unlimitedResurrectON) || (isSecondHeartInstalled) {
      message = StrReplace(SantaMuerteText.RESURRECTUNLIMITED(), "%VAL%", "");
    }

    if (this.warningsON) {
      this.player.SetWarningMessage(message, SimpleMessageType.Relic);  
    }
  } 

  public func incrementResurrections() -> Void {    

    this.resurrectCount += 1;  
  } 

  public func decrementResurrections() -> Void {    

    this.resurrectCount -= 1;  

    if (this.resurrectCount < 0) {
      this.resurrectCount = 0;
    }
  } 

  public func maxResurrectionReached(isSecondHeartInstalled: Bool) -> Bool {    
    if (this.unlimitedResurrectON) || (isSecondHeartInstalled) { 
      return false;
    }

    return (this.resurrectCount >= this.resurrectCountMax);  
  } 

  public func getMaxResurrectionPercent() -> Float {    
    if (this.unlimitedResurrectON) { 
      return 100.0;
    }

    return (Cast<Float>(this.resurrectCount) * 100.0) / Cast<Float>(this.resurrectCountMax) ;  
  } 

  public func updateMaxResurrections() -> Void {    

    let resurrectionFacts: Int32 = this.getResurrectionFacts();
    let playerLevelContribution: Int32 = this.getPlayerLevelContribution();
    let cyberwareContribution: Int32 = this.getCyberwareContribution();
    let relicMetaquestContribution: Int32 = this.getRelicMetaquestContribution();
    let tarotCardsContribution: Int32 = this.getTarotCardsContribution();

    // Check fact for Jackie's tomb 
    // Get player cyberware level

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
    return GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q101_done") >= 1; // After Heist + back to H10 building
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


    return(_resurrectionFacts);

  } 

  public func getPlayerLevelContribution() -> Int32 {   
    let playerLevel: Float = GameInstance.GetStatsSystem(this.player.GetGame()).GetStatValue(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatType.Level);
    let _playerLevelContribution: Int32 = 0;

    _playerLevelContribution = 1 + ((Cast<Int32>(playerLevel)) / 10);

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

    if ( RandRange(1,100) <= this.blackoutTeleportChance ) && (canBeTeleported)  && (this.teleportON) {
      this.applyBlackout();
      // Test Detour teleports first
      if (this.blackoutDetourTeleportON) && (RandRange(0,100)> (100 - this.blackoutDetourTeleportChance)) {
          teleportSuccessful = this.tryResurrectionDetourTeleport();           
      }  

      // If Detour teleport failed, test safe teleports
      if (!teleportSuccessful) && (this.blackoutSafeTeleportON) && (RandRange(0,100)> (100 - this.blackoutSafeTeleportChance)) {
          teleportSuccessful = this.tryResurrectionSafeTeleport();           
      }     

      if (teleportSuccessful) {

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
    globalApplyLoadingScreen();

    this.clearBlackout();
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

      this.clearBlackout();
 
  } 

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

    if (maxResurrectionPercent > 25.0) && (maxResurrectionPercent < 85.0) {
      StatusEffectHelper.ApplyStatusEffectForTimeWindow(this.player, t"BaseStatusEffect.JohnnySicknessMedium", this.player.GetEntityID(), 0.00, sicknessDuration);
    }

    if (maxResurrectionPercent >= 85.0) {
      StatusEffectHelper.ApplyStatusEffectForTimeWindow(this.player, t"BaseStatusEffect.JohnnySicknessHeavy", this.player.GetEntityID(), 0.00, sicknessDuration);
    }

    // Trying to consumer 1 RAM to force a refresh of counter
    if (this.santaMuerteWidgetON) {
      this.resurrectionCostsMemory();      
    }

    // Attempt at removing second heart effect icon 
    // Commenting out because of hard crash when used here.
    // StatusEffectHelper.RemoveStatusEffect(this.player, t"BaseStatusEffect.SecondHeart");

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

    m_statusEffectSystem.ApplyStatusEffect(this.player.GetEntityID(), t"BaseStatusEffect.CyberwareInstallationAnimationBlackout");

  } 
 

  public func forceCombatExit() -> Void {
    let _playerPuppetPS: ref<PlayerPuppetPS> = this.player.GetPS();
    let currentTime: Float = EngineTime.ToFloat(GameInstance.GetSimTime(this.player.GetGame()));

    if this.player.IsInCombat() {
      this.showDebugMessage( ">>> Santa Muerte: forceCombatExit: Combat state detected." ); 
      let invalidateEvent: ref<PlayerCombatControllerInvalidateEvent> = new PlayerCombatControllerInvalidateEvent();
      invalidateEvent.m_state = PlayerCombatState.OutOfCombat;
      this.player.QueueEvent(invalidateEvent);

      GameInstance.GetAudioSystem(this.player.GetGame()).NotifyGameTone(n"LeaveCombat");
      GameInstance.GetAudioSystem(this.player.GetGame()).HandleOutOfCombatMix(this.player);
      
      /*
      this.SetBlackboardIntVariable(GetAllBlackboardDefs().PlayerStateMachine.Combat, 2);
      this.SendAnimFeatureData(false);
      PlayerPuppet.ReevaluateAllBreathingEffects(this.player as PlayerPuppet);
      GameInstance.GetStatPoolsSystem(this.player.GetGame()).RequestSettingModifierWithRecord(Cast<StatsObjectID>(this.player.GetEntityID()), gamedataStatPoolType.Health, gameStatPoolModificationTypes.Regeneration, t"BaseStatPools.PlayerBaseOutOfCombatHealthRegen");
      ChatterHelper.TryPlayLeaveCombatChatter(this.player);
      FastTravelSystem.RemoveFastTravelLock(n"InCombat", this.player.GetGame());
      GameObjectEffectHelper.BreakEffectLoopEvent(this.player, n"stealth_mode");   
      */   
    };

    this.clearBlackout();
  }
  
  private func tryResurrectionSafeTeleport() -> Bool {
    let randNum: Int32;
    let teleportSuccessful: Bool = false;

    randNum = RandRange(0,100);

    if (randNum >= 90) {
      this.showDebugMessage( ">>> Santa Muerte: Medevac to Hospital" ); 
      teleportSuccessful = this.tryTeleportMedicalCenter();
    }

    if (randNum < 90) && (randNum > 0) {
      this.showDebugMessage( ">>> Santa Muerte: Nearby RipperDoc" ); 
      teleportSuccessful = this.tryTeleportRipperDoc();
    }

    // if (randNum <= 20) {
    //   this.showDebugMessage( ">>> Santa Muerte: Viktor only" ); 
    //   teleportSuccessful = this.tryTeleportViktor();
    // }

    return teleportSuccessful;

  }
  
  private func tryTeleportMedicalCenter() -> Bool {
    let rotation: EulerAngles;
    let position: Vector4;
    let isDestinationFound: Bool = false;

    //Player World Pos: Vector4[ X:-1367.995483, Y:1743.821655, Z:18.189995, W:1.000000 ]
    //Player World Rot: EulerAngles[ Pitch:-0.000000, Yaw:175.044250, Roll:0.000000 ]
    position = new Vector4(-1367.995483, 1743.821655, 18.189995, 1.000000);
    rotation = new EulerAngles(0.0, 175.0, 0.0);
    isDestinationFound = true;

    GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(this.player, position, rotation);

    return isDestinationFound;

  }

  private func tryTeleportViktor()  -> Bool {
    let rotation: EulerAngles;
    let position: Vector4;
    let isDestinationFound: Bool = false;

    // Viktor: 
    position = new Vector4(-1554.434, 1239.794, 11.520, 1.000000);
    rotation = new EulerAngles(0.0, -30.0, 0.0);
    isDestinationFound = true;

    GameInstance.GetTeleportationFacility(this.player.GetGame()).Teleport(this.player, position, rotation);

    return isDestinationFound;

  }
  
  private func tryTeleportRipperDoc() -> Bool{
    let rotation: EulerAngles;
    let position: Vector4;
    let currentDistrict: gamedataDistrict = this.getCurrentDistrict();
    let randNum: Int32;
    let isDestinationFound: Bool = false;

    switch currentDistrict {
      case gamedataDistrict.Watson:
        // Doc Robert
        position = new Vector4(-1242.968, 1943.158, 8.066, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.LittleChina:
        // Viktor: 
        position = new Vector4(-1554.434, 1239.794, 11.520, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Kabuki:
        // Instant Implants 
        position = new Vector4(-1040.569, 1443.039, 0.493, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Northside:
        // Cassius Ryder
        position = new Vector4(-1682.980, 2380.442, 18.344, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.ArasakaWaterfront:
        // Cassius Ryder
        position = new Vector4(-1682.980, 2380.442, 18.344, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;

      case gamedataDistrict.CityCenter:
        // City Center doc
        position = new Vector4(-2410.167, 393.338, 11.837, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Downtown:
        // City Center doc
        position = new Vector4(-2410.167, 393.338, 11.837, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.CorpoPlaza:
        // Nina Kraviz
        position = new Vector4(-40.149, -53.598, 7.180, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;

      case gamedataDistrict.Heywood:
        // Doc Ryder
        position = new Vector4(-2362.834, -927.831, 12.266, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Glen:
        // Doc Ryder
        position = new Vector4(-2362.834, -927.831, 12.266, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Wellsprings:
        // Doc Ryder
        position = new Vector4(-2362.834, -927.831, 12.266, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.VistaDelRey:
        // Arroyo Doc
        position = new Vector4(-1072.903, -1274.589, 11.457, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;

      case gamedataDistrict.Pacifica:
        // Voodoo Doc
        position = new Vector4(-2609.994, -2496.741, 17.335, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.WestWindEstate:
        // Voodoo Doc
        position = new Vector4(-2609.994, -2496.741, 17.335, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Coastview:
        // Voodoo Doc
        position = new Vector4(-2609.994, -2496.741, 17.335, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;

      case gamedataDistrict.SantoDomingo:
        // Arroyo Doc
        position = new Vector4(-1072.903, -1274.589, 11.457, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Arroyo:
        // Arroyo Doc
        position = new Vector4(-1072.903, -1274.589, 11.457, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.RanchoCoronado:
        // Doc Octavio 
        position = new Vector4(588.214, -2180.696, 42.437, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;

      case gamedataDistrict.Westbrook:
        // Nina Kraviz
        position = new Vector4(-40.149, -53.598, 7.180, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.JapanTown:
        // Japantown Ripper Doc
        position = new Vector4(-712.075, -871.053, 11.982, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.NorthOaks:
        // Nina Kraviz
        position = new Vector4(-40.149, -53.598, 7.180, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.CharterHill:
        // Nina Kraviz
        position = new Vector4(-40.149, -53.598, 7.180, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;

      case gamedataDistrict.Dogtown:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Church Clinic
          position = new Vector4(-1668.095, -2487.934, 37.151, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }  
        if (randNum > 20) && (randNum < 80) {
          // Doc Costyn Lahovary
          position = new Vector4(-2400.081, -2655.728, 27.842, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }  
        if (randNum <= 20) {
          // Doc Farida Clinic
          position = new Vector4(-1887.505, -2486.323, 28.052, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }  

        break;

      case gamedataDistrict.Badlands:
        // Doc Octavio 
        position = new Vector4(588.214, -2180.696, 42.437, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.NorthBadlands:
        // Doc Octavio 
        position = new Vector4(588.214, -2180.696, 42.437, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.SouthBadlands:
        // Doc Octavio 
        position = new Vector4(588.214, -2180.696, 42.437, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
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

    teleportSuccessful = this.tryTeleportDetourByDistrict();

    return teleportSuccessful;

  }

  private func tryTeleportDetourByDistrict() -> Bool{
    let rotation: EulerAngles;
    let position: Vector4;
    let currentDistrict: gamedataDistrict = this.getCurrentDistrict();
    let randNum: Int32;
    let isDestinationFound: Bool = false;

    switch currentDistrict {
      case gamedataDistrict.Watson:
        // Back of Hospital
        position = new Vector4(-1279.890, 1858.963, 18.163, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;

        break;
      case gamedataDistrict.LittleChina:
        // Regina Fixer Hideout
        position = new Vector4(-1147.539, 1573.210, 71.712, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Kabuki:
        // Regina Fixer Hideout
        position = new Vector4(-1147.539, 1573.210, 71.712, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Northside:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Creepy Maelstrom BD shack 
          position = new Vector4(-1006.454, 3378.892, 8.540, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        if (randNum > 20) && (randNum < 80) {
          // Oil Fields
          position = new Vector4(-1833.609, 3824.832, 5.484, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        if (randNum <= 20) {
          // Northside beach dump
          position = new Vector4(-2346.953, 3687.689, 7.844, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }

        break;
      case gamedataDistrict.ArasakaWaterfront:
        break;

      case gamedataDistrict.CityCenter:
        break;
      case gamedataDistrict.Downtown:
        break;
      case gamedataDistrict.CorpoPlaza:
        break;

      case gamedataDistrict.Heywood:
        break;
      case gamedataDistrict.Glen:
        // Trash pile in Reconciliation Park
        position = new Vector4(-1561.247, -440.721, -11.796, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Wellsprings:
        // Valentinos scrap yard
        position = new Vector4(-506.051, -96.526, 7.770, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.VistaDelRey:
        // Dark alley
        position = new Vector4(-605.527, -224.119, 7.678, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;

      case gamedataDistrict.Pacifica:
        break;
      case gamedataDistrict.WestWindEstate:
        // Beach Trash Pile
        position = new Vector4(-2672.360, -2340.655, 0.747, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.Coastview:
        // Butcher shop
        position = new Vector4(-2286.622, -1931.526, 6.055, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;

      case gamedataDistrict.SantoDomingo:
        break;
      case gamedataDistrict.Arroyo:
        // Trash pile under overpass
        position = new Vector4(157.737, -730.418, 4.276, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.RanchoCoronado:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Homeless camp
          position = new Vector4(449.555, -1686.285, 9.842, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        if (randNum >= 40) && (randNum < 80)  {
          // Dump near new tower
          position = new Vector4(908.807, -1545.698, 45.001, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        if (randNum < 40) {
          // Warehouse
          position = new Vector4(1080.595, -722.294, 22.271, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        break;

      case gamedataDistrict.Westbrook:
        break;
      case gamedataDistrict.JapanTown:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Creepy Scav BD shack 
          position = new Vector4(-697.153, 956.792, 12.368, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        if (randNum >= 40) && (randNum < 80)  {
          // Japantown reservoir
          position = new Vector4(-445.489, 417.814, 131.998, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        let isAutomaticLoveCompleted: Bool = GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"sq032_q105_done") >= 1;
        if (randNum >= 20) && (randNum < 40) && (isAutomaticLoveCompleted) {
          // Fingers MD
          position = new Vector4(-569.782, 799.393, 24.908, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        if (randNum < 20) {
          // Tyger Claw's Cages Hideout
          position = new Vector4(-529.289, 521.130, 18.297, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }

        break;
      case gamedataDistrict.NorthOaks:
        break;
      case gamedataDistrict.CharterHill:
        break;

      case gamedataDistrict.Dogtown:
        // Somi's favorite spot
        position = new Vector4(-1732.673, -2683.120, 78.083, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;

      case gamedataDistrict.Badlands:
        // Sunset Motel - room 102
        position = new Vector4(1662.659, -791.086, 49.826, 1.000000);
        rotation = new EulerAngles(0.0, -30.0, 0.0);
        isDestinationFound = true;
        break;
      case gamedataDistrict.NorthBadlands:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Safe garage 
          position = new Vector4(2575.148, 0.298, 80.875, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        if (randNum <= 20) {
          // Trash Dump
          position = new Vector4(2329.168, -1826.530, 79.302, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        break;
      case gamedataDistrict.SouthBadlands:
        randNum = RandRange(0,100);

        if (randNum >= 80) {
          // Trailer Arm Dealer
          position = new Vector4(131.666, -4679.567, 54.711, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
        if (randNum <= 20) {
          // Gas station with Wraiths
          position = new Vector4(-1705.800, -5016.451, 80.346, 1.000000);
          rotation = new EulerAngles(0.0, -30.0, 0.0);
          isDestinationFound = true;
        }
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

    let endgameStarted: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q115_embers_elevator_unlocked") >= 1);
    let endgameDone: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"loaded_ponr_save") >= 1);
    let endgame: Bool = (endgameStarted) && (!endgameDone);

    let dogtownIntroStarted: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q301_sb_agreed") >= 1);
    let dogtownIntroDone: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q302_done") >= 1);
    let dogtownIntro: Bool = (dogtownIntroStarted) && (!dogtownIntroDone);

    let somiStadiumStarted: Bool = (GameInstance.GetPreventionSpawnSystem(this.player.GetGame()).IsPlayerInDogTown()) && (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q304_started") >= 1);
    let somiStadiumDone: Bool = (GameInstance.GetPreventionSpawnSystem(this.player.GetGame()).IsPlayerInDogTown()) && (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q304_done") >= 1);
    let somiStadium: Bool = (somiStadiumStarted) && (!somiStadiumDone);

    let cynosureStarted: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q305_started") >= 1);
    let cynosureDone: Bool = (GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q305_done") >= 1);
    let cynosure: Bool = (cynosureStarted) && (!cynosureDone);

    let dogtown: Bool = (dogtownIntro) || (somiStadium) || (cynosure);

    this.showDebugMessage( s">>> Santa Muerte: Teleport check: Player in Dogtown " + ToString((GameInstance.GetPreventionSpawnSystem(this.player.GetGame()).IsPlayerInDogTown())));
    this.showDebugMessage( s">>> Santa Muerte: Teleport check: dogtownIntro \(dogtownIntro)");
    this.showDebugMessage( s">>> Santa Muerte: Teleport check: somiStadium \(somiStadium)");
    this.showDebugMessage( s">>> Santa Muerte: Teleport check: cynosure \(cynosure)");
    this.showDebugMessage( s">>> Santa Muerte: Teleport check: dogtown \(dogtown)"); 

    let isInNamedDistrict: Bool = (!this.isPlayerInGenericDistrict());

    let paused: Bool = GameInstance.GetTimeSystem(this.player.GetGame()).IsPausedState();
    let noTimeSkip: Bool = StatusEffectSystem.ObjectHasStatusEffectWithTag(this.player, n"NoTimeSkip"); 
    let noFastTravel: Bool = StatusEffectSystem.ObjectHasStatusEffect(this.player, t"GameplayRestriction.BlockFastTravel");

    let tier: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.HighLevel);
    let scene: Bool = tier >= EnumInt(gamePSMHighLevel.SceneTier3) && tier <= EnumInt(gamePSMHighLevel.SceneTier5);

    let mounted: Bool = VehicleComponent.IsMountedToVehicle(this.player.GetGame(), this.player);
    let swimming: Bool = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Swimming) == EnumInt(gamePSMSwimming.Diving);
    let carrying: Bool = bb.GetBool(GetAllBlackboardDefs().PlayerStateMachine.Carrying);
    let lore_animation: Bool = bb.GetBool(GetAllBlackboardDefs().PlayerStateMachine.IsInLoreAnimationScene);

    if dogtown || somiStadium || cynosure || isInNamedDistrict || paused || noTimeSkip || noFastTravel || scene || mounted || swimming || carrying || lore_animation {
      this.showDebugMessage( s">>> Santa Muerte: Teleport canceled: Endgame \(endgame), Dogtown \(dogtown), somiStadium \(somiStadium), Cynosure \(cynosure), paused: \(paused), noTimeSkip: \(noTimeSkip), noFastTravel: \(noFastTravel), scene: \(scene), mounted: \(mounted), swimming: \(swimming), carrying: \(carrying), lore_animation: \(lore_animation)");
      return false;
    };

    return true;
  }
  
  private func showDebugMessage(debugMessage: String) {
    // LogChannel(n"DEBUG", debugMessage ); 
  }

  public func markGameForPermaDeath() -> Void {
    this.showDebugMessage( ">>> Santa Muerte: Final Death" ); 
    this.forceBlackout();
  }

/* 

*/

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


