// Tutorial System for Santa Muerte
// Manages display of informative tutorial screens at key events
// Uses blackboard system for proper UI popups (inspired by Dark Future mod)

public enum SantaMuerteTutorialType {
  FirstResurrection = 0,
  FirstSafeTeleport = 1,
  FirstDetourTeleport = 2,
  FirstRobbery = 3,
  FirstCyberwareRemoval = 4,
  LowResurrections = 5,
  CriticalResurrections = 6,
  SleepRecovery = 7
}

// Tutorial data structure for blackboard-based display
public struct SantaMuerteTutorial {
  public let title: String;
  public let message: String;
  public let iconID: TweakDBID;
  public let video: ResourceAsyncRef;
  public let videoType: VideoType;
}

// Tracks which tutorials have been shown to the player
public class SantaMuerteTutorialTracker {
  public persistent let firstResurrectionShown: Bool;
  public persistent let firstSafeTeleportShown: Bool;
  public persistent let firstDetourTeleportShown: Bool;
  public persistent let firstRobberyShown: Bool;
  public persistent let firstCyberwareRemovalShown: Bool;
  public persistent let lowResurrectionsWarningShown: Bool;
  public persistent let criticalResurrectionsWarningShown: Bool;
  public persistent let sleepRecoveryShown: Bool;

  public let showTutorialsON: Bool;
  public let tutorialDisplayDuration: Float;

  public func init() -> Void {
    this.firstResurrectionShown = false;
    this.firstSafeTeleportShown = false;
    this.firstDetourTeleportShown = false;
    this.firstRobberyShown = false;
    this.firstCyberwareRemovalShown = false;
    this.lowResurrectionsWarningShown = false;
    this.criticalResurrectionsWarningShown = false;
    this.sleepRecoveryShown = false;

    this.showTutorialsON = true;
    this.tutorialDisplayDuration = 15.0; // seconds
  }

  public func resetAll() -> Void {
    this.firstResurrectionShown = false;
    this.firstSafeTeleportShown = false;
    this.firstDetourTeleportShown = false;
    this.firstRobberyShown = false;
    this.firstCyberwareRemovalShown = false;
    this.lowResurrectionsWarningShown = false;
    this.criticalResurrectionsWarningShown = false;
    this.sleepRecoveryShown = false;
  }

  public func shouldShow(tutorialType: SantaMuerteTutorialType) -> Bool {
    if !this.showTutorialsON {
      return false;
    }

    switch tutorialType {
      case SantaMuerteTutorialType.FirstResurrection:
        return !this.firstResurrectionShown;
      case SantaMuerteTutorialType.FirstSafeTeleport:
        return !this.firstSafeTeleportShown;
      case SantaMuerteTutorialType.FirstDetourTeleport:
        return !this.firstDetourTeleportShown;
      case SantaMuerteTutorialType.FirstRobbery:
        return !this.firstRobberyShown;
      case SantaMuerteTutorialType.FirstCyberwareRemoval:
        return !this.firstCyberwareRemovalShown;
      case SantaMuerteTutorialType.LowResurrections:
        return !this.lowResurrectionsWarningShown;
      case SantaMuerteTutorialType.CriticalResurrections:
        return !this.criticalResurrectionsWarningShown;
      case SantaMuerteTutorialType.SleepRecovery:
        return !this.sleepRecoveryShown;
    }

    return false;
  }

  public func markAsShown(tutorialType: SantaMuerteTutorialType) -> Void {
    switch tutorialType {
      case SantaMuerteTutorialType.FirstResurrection:
        this.firstResurrectionShown = true;
        break;
      case SantaMuerteTutorialType.FirstSafeTeleport:
        this.firstSafeTeleportShown = true;
        break;
      case SantaMuerteTutorialType.FirstDetourTeleport:
        this.firstDetourTeleportShown = true;
        break;
      case SantaMuerteTutorialType.FirstRobbery:
        this.firstRobberyShown = true;
        break;
      case SantaMuerteTutorialType.FirstCyberwareRemoval:
        this.firstCyberwareRemovalShown = true;
        break;
      case SantaMuerteTutorialType.LowResurrections:
        this.lowResurrectionsWarningShown = true;
        break;
      case SantaMuerteTutorialType.CriticalResurrections:
        this.criticalResurrectionsWarningShown = true;
        break;
      case SantaMuerteTutorialType.SleepRecovery:
        this.sleepRecoveryShown = true;
        break;
    }
  }

  // Reset warning flags so they can be shown again when conditions are met
  public func resetWarnings() -> Void {
    this.lowResurrectionsWarningShown = false;
    this.criticalResurrectionsWarningShown = false;
  }
}

// Delayed callback for displaying queued tutorials
public class DisplayNextSantaMuerteTutorialDelayCallback extends DelayCallback {
  public let tutorialManager: wref<SantaMuerteTutorialManager>;

  public static func Create(tutorialManager: wref<SantaMuerteTutorialManager>) -> ref<DisplayNextSantaMuerteTutorialDelayCallback> {
    let self: ref<DisplayNextSantaMuerteTutorialDelayCallback> = new DisplayNextSantaMuerteTutorialDelayCallback();
    self.tutorialManager = tutorialManager;
    return self;
  }

  public func Call() -> Void {
    this.tutorialManager.OnDisplayNextTutorial();
  }
}

// Main tutorial manager class
public class SantaMuerteTutorialManager {
  private let player: wref<PlayerPuppet>;
  private let tracker: ref<SantaMuerteTutorialTracker>;
  private let tracking: ref<SantaMuerteTracking>;
  private let tutorialQueue: array<SantaMuerteTutorial>;
  private let displayNextTutorialDelayID: DelayID;
  private let displayNextTutorialDelayInterval: Float = 1.0;

  public func init(player: wref<PlayerPuppet>, tracking: ref<SantaMuerteTracking>) -> Void {
    this.player = player;
    this.tracking = tracking;
    this.tracker = new SantaMuerteTutorialTracker();
    this.tracker.init();
    this.displayNextTutorialDelayID = GetInvalidDelayID();
  }

  public func initWithTracker(player: wref<PlayerPuppet>, tracking: ref<SantaMuerteTracking>, tracker: ref<SantaMuerteTutorialTracker>) -> Void {
    this.player = player;
    this.tracking = tracking;
    this.tracker = tracker;
    this.displayNextTutorialDelayID = GetInvalidDelayID();
  }

  public func getTracker() -> ref<SantaMuerteTutorialTracker> {
    return this.tracker;
  }

  public func showTutorial(tutorialType: SantaMuerteTutorialType) -> Void {
    if !this.tracker.shouldShow(tutorialType) {
      return;
    }

    let tutorial: SantaMuerteTutorial;

    switch tutorialType {
      case SantaMuerteTutorialType.FirstResurrection:
        tutorial.title = SantaMuerteText.TUTORIAL_TITLE_FIRST_RESURRECTION();
        tutorial.message = this.buildFirstResurrectionMessage();
        tutorial.iconID = t"UIIcon.second_heart"; // Skull/danger icon for death
        break;

      case SantaMuerteTutorialType.FirstSafeTeleport:
        tutorial.title = SantaMuerteText.TUTORIAL_TITLE_SAFE_TELEPORT();
        tutorial.message = SantaMuerteText.TUTORIAL_MSG_SAFE_TELEPORT();
        tutorial.iconID = t"UIIcon.regeneration_icon"; // Generic icon for teleport
        break;

      case SantaMuerteTutorialType.FirstDetourTeleport:
        tutorial.title = SantaMuerteText.TUTORIAL_TITLE_DETOUR_TELEPORT();
        tutorial.message = SantaMuerteText.TUTORIAL_MSG_DETOUR_TELEPORT();
        tutorial.iconID = t"UIIcon.quickhack_memory_wipe"; // Electric/tech icon for detour
        break;

      case SantaMuerteTutorialType.FirstRobbery:
        tutorial.title = SantaMuerteText.TUTORIAL_TITLE_ROBBERY();
        tutorial.message = SantaMuerteText.TUTORIAL_MSG_ROBBERY();
        tutorial.iconID = t"UIIcon.fat_wallet"; // Toxic/danger icon for robbery
        break;

      case SantaMuerteTutorialType.FirstCyberwareRemoval:
        tutorial.title = SantaMuerteText.TUTORIAL_TITLE_CYBERWARE_REMOVAL();
        tutorial.message = SantaMuerteText.TUTORIAL_MSG_CYBERWARE_REMOVAL();
        tutorial.iconID = t"UIIcon.cyberware_disabled_icon"; // Generic icon for cyberware
        break;

      case SantaMuerteTutorialType.LowResurrections:
        tutorial.title = SantaMuerteText.TUTORIAL_TITLE_LOW_RESURRECTIONS();
        tutorial.message = this.buildLowResurrectionsMessage();
        tutorial.iconID = t"UIIcon.johnny_sickness_icon"; // Warning/heat icon for low resurrections
        break;

      case SantaMuerteTutorialType.CriticalResurrections:
        tutorial.title = SantaMuerteText.TUTORIAL_TITLE_CRITICAL_RESURRECTIONS();
        tutorial.message = this.buildCriticalResurrectionsMessage();
        tutorial.iconID = t"UIIcon.quickhack_systemcollapse"; // Danger icon for critical state
        break;

      case SantaMuerteTutorialType.SleepRecovery:
        tutorial.title = SantaMuerteText.TUTORIAL_TITLE_SLEEP_RECOVERY();
        tutorial.message = this.buildSleepRecoveryMessage();
        tutorial.iconID = t"UIIcon.health_booster"; // Generic icon for recovery
        break;
    }

    // Set default video type
    tutorial.videoType = VideoType.Unknown;
    
    // Queue the tutorial for display
    this.queueTutorial(tutorial);
    
    // Mark as shown
    this.tracker.markAsShown(tutorialType);
  }

  // Queue a tutorial for display using blackboard system
  private func queueTutorial(tutorial: SantaMuerteTutorial) -> Void {
    ArrayPush(this.tutorialQueue, tutorial);
    this.registerDisplayNextTutorialCallback();
  }

  // Display the next tutorial in the queue using blackboard system
  public func OnDisplayNextTutorial() -> Void {
    if ArraySize(this.tutorialQueue) > 0 {
      if IsDefined(this.player) && !this.player.IsInCombat() {
        let tutorial: SantaMuerteTutorial = ArrayPop(this.tutorialQueue);
        
        let blackboardSystem: ref<BlackboardSystem> = GameInstance.GetBlackboardSystem(this.player.GetGame());
        let blackboardDef: ref<IBlackboard> = blackboardSystem.Get(GetAllBlackboardDefs().UIGameData);
        
        // Configure popup settings
        let popupSettings: PopupSettings;
        popupSettings.closeAtInput = true;
        popupSettings.pauseGame = true;
        popupSettings.fullscreen = true;
        popupSettings.position = PopupPosition.Center;
        popupSettings.hideInMenu = true;
        popupSettings.margin = inkMargin(0.0, 0.0, 0.0, 0.0);
        
        // Configure popup data
        let popupData: PopupData;
        popupData.title = tutorial.title;
        popupData.message = tutorial.message;
        popupData.isModal = true;
        
        // Use video if provided, otherwise use icon
        if Equals(ResourceAsyncRef.GetPath(tutorial.video), r"") {
          popupData.videoType = VideoType.Unknown;
          popupData.iconID = tutorial.iconID;
        } else {
          popupData.videoType = tutorial.videoType;
          popupData.video = tutorial.video;
        }
        
        // Set blackboard data and signal
        blackboardDef.SetVariant(GetAllBlackboardDefs().UIGameData.Popup_Settings, ToVariant(popupSettings));
        blackboardDef.SetVariant(GetAllBlackboardDefs().UIGameData.Popup_Data, ToVariant(popupData));
        blackboardDef.SignalVariant(GetAllBlackboardDefs().UIGameData.Popup_Data);
        
        // Log for debugging
        if this.tracking.debugON {
          this.tracking.showDebugMessage("[TUTORIAL] Displayed: " + tutorial.title);
        }
        
        // If more tutorials are queued, schedule next display
        if ArraySize(this.tutorialQueue) > 0 {
          this.registerDisplayNextTutorialCallback();
        }
      } else {
        // Player is in combat or not available, try again later
        this.registerDisplayNextTutorialCallback();
      }
    }
  }

  // Register callback to display next tutorial
  private func registerDisplayNextTutorialCallback() -> Void {
    if !Equals(this.displayNextTutorialDelayID, GetInvalidDelayID()) {
      return; // Already registered
    }
    
    let delaySystem: ref<DelaySystem> = GameInstance.GetDelaySystem(this.player.GetGame());
    let callback: ref<DisplayNextSantaMuerteTutorialDelayCallback> = DisplayNextSantaMuerteTutorialDelayCallback.Create(this);
    this.displayNextTutorialDelayID = delaySystem.DelayCallback(callback, this.displayNextTutorialDelayInterval);
  }

  // Tutorial Message Builders - Replace placeholders with dynamic values

  private func buildFirstResurrectionMessage() -> String {
    let msg: String = SantaMuerteText.TUTORIAL_MSG_FIRST_RESURRECTION();
    msg = StrReplace(msg, "%COUNT%", ToString(this.tracking.resurrectCountMax - this.tracking.resurrectCount));
    msg = StrReplace(msg, "%MAX%", ToString(this.tracking.resurrectCountMax));
    return msg;
  }

  private func buildLowResurrectionsMessage() -> String {
    let percent: Float = this.tracking.getMaxResurrectionPercent();
    let msg: String = SantaMuerteText.TUTORIAL_MSG_LOW_RESURRECTIONS();
    msg = StrReplace(msg, "%PERCENT%", ToString(Cast<Int32>(percent)));
    msg = StrReplace(msg, "%COUNT%", ToString(this.tracking.resurrectCountMax - this.tracking.resurrectCount));
    msg = StrReplace(msg, "%MAX%", ToString(this.tracking.resurrectCountMax));
    return msg;
  }

  private func buildCriticalResurrectionsMessage() -> String {
    let msg: String = SantaMuerteText.TUTORIAL_MSG_CRITICAL_RESURRECTIONS();
    msg = StrReplace(msg, "%COUNT%", ToString(this.tracking.resurrectCountMax - this.tracking.resurrectCount));
    msg = StrReplace(msg, "%MAX%", ToString(this.tracking.resurrectCountMax));
    return msg;
  }

  private func buildSleepRecoveryMessage() -> String {
    let msg: String = SantaMuerteText.TUTORIAL_MSG_SLEEP_RECOVERY();
    msg = StrReplace(msg, "%COUNT%", ToString(this.tracking.resurrectCountMax - this.tracking.resurrectCount));
    msg = StrReplace(msg, "%MAX%", ToString(this.tracking.resurrectCountMax));
    return msg;
  }

  // Utility methods for triggering tutorials at appropriate times

  public func checkResurrectionWarnings() -> Void {
    let percent: Float = this.tracking.getMaxResurrectionPercent();
    
    // Critical warning at 25% or less
    if percent <= 25.0 {
      if this.tracker.shouldShow(SantaMuerteTutorialType.CriticalResurrections) {
        this.showTutorial(SantaMuerteTutorialType.CriticalResurrections);
      }
    }
    // Low warning at 50% or less
    else if percent <= 50.0 {
      if this.tracker.shouldShow(SantaMuerteTutorialType.LowResurrections) {
        this.showTutorial(SantaMuerteTutorialType.LowResurrections);
      }
    }
  }

  public func resetTutorials() -> Void {
    this.tracker.resetAll();
  }

  public func resetWarnings() -> Void {
    this.tracker.resetWarnings();
  }
}

// Event class for delayed tutorial display
public class DelayedTutorialEvent extends Event {
  public let tutorialType: SantaMuerteTutorialType;
}

// Extension to PlayerPuppet for handling delayed tutorial events
@addMethod(PlayerPuppet)
protected cb func OnDelayedTutorialEvent(evt: ref<DelayedTutorialEvent>) -> Bool {
  let playerPuppetPS: ref<PlayerPuppetPS> = this.GetPS();
  
  if IsDefined(playerPuppetPS.m_santaMuerteTracking) && IsDefined(playerPuppetPS.m_santaMuerteTracking.tutorialManager) {
    playerPuppetPS.m_santaMuerteTracking.tutorialManager.showTutorial(evt.tutorialType);
  }
}
