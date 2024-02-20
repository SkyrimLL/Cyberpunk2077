
/*
public class FullScreenDeathSequenceController extends inkHUDGameController {

  public func init() -> Void {
    let inkSystem = GameInstance.GetInkSystem();
    let hudRoot = inkSystem.GetLayer(n"inkHUDLayer").GetVirtualWindow();

    let hello = new inkVideo();
    hello.SetText("HELLO HUD");
    hello.SetFontFamily("base\\gameplay\\gui\\fonts\\orbitron\\orbitron.inkfontfamily");
    hello.SetFontStyle(n"Bold");
    hello.SetFontSize(200);
    hello.SetTintColor(new HDRColor(1.1761, 0.3809, 0.3476, 1.0));
    hello.SetAnchor(inkEAnchor.Centered);
    hello.SetAnchorPoint(0.5, 0.5);
    hello.Reparent(hudRoot);
  }

}

1st argument: expected wref<inkCompoundWidget>, given ref<FullScreenDeathSequenceController>

*/
import Codeware.UI.* 

public class FullScreenDeathSequenceController  {  
  public let config: ref<DiverseDeathScreensConfig>;
  private let player: wref<GameObject>;

  public let modON: Bool; 

  public let randomizeDeathScreensON: Bool ;  
  public let enableLongAnimationsON: Bool ;  
  public let chanceLongAnimation: Int32 ;
  public let deathScreensOpacity: Int32 ;

  public let debugON: Bool;
  public let warningsON: Bool;   

  private let m_videoWidget: wref<inkVideo>;
  private let m_videoWrapper: ref<inkCanvas>;
  private let m_video_sequence: Int32 = 0;

  protected cb func OnCreate() { }

  public func init() -> Void {
    this.reset();
  }

  private func reset() -> Void {

    this.player = GetPlayer(GetGameInstance());
    this.refreshConfig();

    // ------------------ Edit these values to configure the mod
    // Toggle warnings when exceeding your carry capacity without powerlevel bonus
    // this.warningsON = true;

    // ------------------ End of Mod Options

    // For developers only 
    // this.debugON = true;

    // To enable call vehicle key for emergencies
    // this.enableVehicleRecallKeyON = false;

    // To enable vehicle menu key for emergencies (Hold)
    // this.enableVehicleMenuKeyON = false;

  }

  public func refreshConfig() -> Void {
    this.config = new DiverseDeathScreensConfig(); 
    this.invalidateCurrentState();
  }

  public func invalidateCurrentState() -> Void {  
    this.randomizeDeathScreensON = this.config.randomizeDeathScreensON;
    this.enableLongAnimationsON = this.config.enableLongAnimationsON;
    this.chanceLongAnimation = this.config.chanceLongAnimation;
    this.deathScreensOpacity = this.config.deathScreensOpacity;

    this.debugON = this.config.debugON;
    this.modON = this.config.modON;  
  } 
 
  // Called when component is attached to the widget tree
  protected cb func OnInitialize() {}

  // Called when component is no longer used anywhere
  protected cb func OnUninitialize() -> Bool { 
    this.m_videoWidget.Stop();
    // Uncomment once callbacks are wroking properly for a sequence
    // this.m_videoWidget.UnregisterFromCallback(n"OnVideoFinished", this, n"OnVideoFinished");
  }

  public func isRelicInstalled() -> Bool {  
    // return GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q005_done") >= 1; // Heist + No tell motel
    return GameInstance.GetQuestsSystem(this.player.GetGame()).GetFact(n"q101_done") >= 1; // After Heist + back to H10 building
  }

  public  func PlayVideoSequence() -> Void {
    // Only allow random animations when Relic is installed.
    if (this.randomizeDeathScreensON) && (this.isRelicInstalled()) {
      // Comment out once callbacks are working properly for a sequence
   
      // this.Fade(0.00, 1.00, n"OnFadeInEnd"); 
      // this.Fade(0.00, 1.00, n"OnFadeOutEnd"); 

      // Small chance of long video
      if (RandRange(0,100)> (100 - this.chanceLongAnimation)) && (this.isRelicInstalled())  && (this.enableLongAnimationsON) {
        this.m_video_sequence = RandRange(20,25);

        switch this.m_video_sequence {
          case 20: this.PlayVideoFile(r"base\\movies\tv\\quest\\tv_sq017_1_us_cracks_music_video.bk2", 0.3, false, n"None");
            break;
          case 21: this.PlayVideoFile(r"base\\movies\\misc\\arcade\\roach_race.bk2", 0.4, false, n"None");
            break;
          case 22: this.PlayVideoFile(r"base\\movies\\fullscreen\\q110_chronology.bk2", 0.3, false, n"None");
            break;
          case 23: this.PlayVideoFile(r"base\\movies\\fullscreen\\q108\\q108_17_riots.bk2", 0.3, false, n"None");
            break;
          case 24: this.PlayVideoFile(r"base\\movies\\ads\\uscracks\\ad_uscracks_01.bk2", 0.4, false, n"None");
            break;
          case 25: this.PlayVideoFile(r"base\\movies\\fullscreen\\common\\intro_after_splash_screens.bk2", 0.5, false, n"None");
            break;
        }      
      } else {
        this.m_video_sequence = RandRange(0,16);

        switch this.m_video_sequence {
          case 0: this.PlayVideoFile(r"base\\movies\\fullscreen\\q104\\q104_bg.bk2", 0.7, false, n"None");
            break;
          case 1: this.PlayVideoFile(r"base\\movies\\fullscreen\\q101\\broken-ui.bk2", 0.7, false, n"None");
            break;
          case 2: this.PlayVideoFile(r"base\\movies\\misc\\generic_noise_white.bk2", 0.9, false, n"None");
            break;
          case 3: this.PlayVideoFile(r"base\\movies\\fullscreen\\reboot-skin.bk2", 0.9, false, n"None");
            break;
          case 4: this.PlayVideoFile(r"base\\movies\\misc\\generic_noise_red.bk2", 0.9, false, n"None");
            break;
          case 5: this.PlayVideoFile(r"base\\movies\\misc\\confessional_booth\\confessional_s.bk2", 0.4, false, n"None");
            break;
          case 6: this.PlayVideoFile(r"base\\movies\\fluff\\q201\\q201_voidkampf_brain.bk2", 0.9, false, n"None");
            break;
          case 7: this.PlayVideoFile(r"base\\movies\\fullscreen\\q101\\q101_07_ripperdoc_critical_state.bk2", 0.9, false, n"None");
            break;
          case 8: this.PlayVideoFile(r"base\\movies\\fullscreen\\q005\\q005_briefing_relic_chip.bk2", 0.8, false, n"None");
            break;
          case 9: this.PlayVideoFile(r"base\\movies\\fullscreen\\q110_cyberspace_data_scan.bk2", 0.7, false, n"None");
            break;
          case 10: this.PlayVideoFile(r"base\\movies\\fullscreen\\logo_splashscreen\\cp_bg_alpha_faded.bk2", 0.7, false, n"None");
            break;
          case 11: this.PlayVideoFile(r"base\\movies\\misc\\q003\\loop_1.bk2", 0.7, false, n"None");
            break;
          case 12: this.PlayVideoFile(r"base\\movies\\misc\\q003\\loop_2.bk2", 0.7, false, n"None");
            break;
          case 13: this.PlayVideoFile(r"base\\movies\\misc\\q003\\trans.bk2", 0.7, false, n"None");
            break;
          case 14: this.PlayVideoFile(r"base\\movies\\misc\\distraction_generic.bk2", 0.7, false, n"None");
            break;
          case 15: this.PlayVideoFile(r"base\\movies\\misc\\main_menu_splash_screen-solid.bk2", 0.7, false, n"None");
            break;
          case 16: this.PlayVideoFile(r"base\\movies\\misc\\main_menu_splash_screen-alpha.bk2", 0.7, false, n"None");
            break;
        }            
      } 
    } else {
        // If relic is not installed, only allow two fixed animations - one before the Heist and one after (if randomization is turned off)
        if (this.isRelicInstalled()) {
          this.m_video_sequence = 1;
          this.PlayVideoFile(r"base\\movies\\fullscreen\\q101\\broken-ui.bk2", 0.7, false, n"None");

        } else {
          this.m_video_sequence = 2;
          this.PlayVideoFile(r"base\\movies\\misc\\generic_noise_white.bk2", 0.9, false, n"None");

        }

    }


    // LogChannel(n"DEBUG", ">>> FullScreenDeathSequenceController: PlayDeathSquence ["+ToString(this.m_video_sequence)+"] " );


    // Uncomment once callbacks are wroking properly for a sequence
    // this.m_video_sequence += 1;

  }

  public  func PlayVideoFile(videoPath: ResRef, opacity: Float, looped: Bool, audioEvent: CName) -> Void {
    // Add code to wait for video to end before starting the next one

    // LogChannel(n"DEBUG", ">>> FullScreenDeathSequenceController: PlayVideoFile " );   

    this.m_videoWidget.Stop();
    this.m_videoWrapper.SetOpacity(opacity);
    this.m_videoWidget.SetOpacity(opacity);
    this.m_videoWidget.SetVideoPath(videoPath);
    this.m_videoWidget.SetLoop(looped);

    if IsNameValid(audioEvent) {
      this.m_videoWidget.SetAudioEvent(audioEvent);
    };

    this.m_videoWidget.Play();
    // Uncomment once callbacks are wroking properly for a sequence
    // this.m_videoWidget.RegisterToCallback(n"OnVideoFinished", this, n"OnVideoFinished");

  }

  protected cb func OnVideoFinished(target: wref<inkVideo>) -> Bool {
    let isVideoWidgetValid: Bool = Equals(target.GetName(), this.m_videoWidget.GetName());
    if isVideoWidgetValid {
      this.FinishVideo();
    };
  }

  private final func FinishVideo() -> Void { 
    if ( this.m_video_sequence <= 4) {
      // Play next video in sequence
      this.PlayVideoSequence();
    } else {
      this.m_videoWidget.SetVisible(false);
      this.m_videoWrapper.SetVisible(false);

    }
  }

  public func init(game: GameInstance)  {

    this.init();

    if (this.modON) {
      // let video = new FullScreenDeathSequenceController();

      // LogChannel(n"DEBUG", ">>> FullScreenDeathSequenceController: init " );  
      let videoOpacity: Float = Cast<Float>(this.deathScreensOpacity) / 100.0;
      let inkSystem = GameInstance.GetInkSystem();
      let layers = inkSystem.GetLayers();

      // for layer in layers {
      //   LogChannel(n"DEBUG", s"UI Layer: \(layer.GetLayerName()) \(layer.GetGameController().GetClassName())");
      // }
      
   
      let hudRoot = inkSystem.GetLayer(n"inkHUDLayer").GetVirtualWindow();

      let resolution = ScreenHelper.GetResolution(game);
      let dimensions = StrSplit(resolution, "x");

      // width - StringToFloat(dimensions[0])
      // height - StringToFloat(dimensions[1]) 

      /*
          let hello = new inkText();
          hello.SetText("HELLO HUD");
          hello.SetFontFamily("base\\gameplay\\gui\\fonts\\orbitron\\orbitron.inkfontfamily");
          hello.SetFontStyle(n"Bold");
          hello.SetFontSize(200);
          hello.SetTintColor(new HDRColor(1.1761, 0.3809, 0.3476, 1.0));
          hello.SetAnchor(inkEAnchor.Centered);
          hello.SetAnchorPoint(0.5, 0.5);
          hello.Reparent(hudRoot);

          hudRoot.SetVisible(true);
      */
      let videoPlayerPanel: ref<inkVerticalPanel> = new inkVerticalPanel();
      videoPlayerPanel.SetMargin(0,0,0,0);
      videoPlayerPanel.SetVAlign(inkEVerticalAlign.Top);
      videoPlayerPanel.SetFitToContent(true);
      videoPlayerPanel.SetTintColor(new HDRColor(1, 1, 1, 1));
      videoPlayerPanel.Reparent(hudRoot);


      let videoWrapper: ref<inkCanvas> = new inkCanvas();
      this.m_videoWrapper = videoWrapper;
      videoWrapper.SetHAlign(inkEHorizontalAlign.Left);
      videoWrapper.SetVAlign(inkEVerticalAlign.Top);
      videoWrapper.SetSize(StringToFloat(dimensions[0]), StringToFloat(dimensions[1]));  // REQUIRED
      videoWrapper.Reparent(videoPlayerPanel);
   
      let videoWidget: ref<inkVideo> = new inkVideo();
      this.m_videoWidget = videoWidget;
      videoWidget.SetHAlign(inkEHorizontalAlign.Center);
      videoWidget.SetVAlign(inkEVerticalAlign.Bottom);
      videoWidget.SetAnchor(inkEAnchor.Fill); 
      videoWidget.SetSize(StringToFloat(dimensions[0]), StringToFloat(dimensions[1]));  // REQUIRED
      videoWidget.Reparent(videoWrapper);  

      // ---
      hudRoot.SetOpacity(videoOpacity);
      videoWidget.SetVisible(true);
      
      videoWrapper.SetOpacity(0.9);
      videoWrapper.SetVisible(true);

      videoPlayerPanel.SetOpacity(0.9);
      videoPlayerPanel.SetVisible(true);

      hudRoot.SetVisible(true);
   
      this.PlayVideoSequence(); 

      // hudRoot.SetVisible(false);      
    }


   }
}


 