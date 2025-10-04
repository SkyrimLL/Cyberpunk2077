public class SantaMuerteText {

  // defines the text that are dispayed in notifications
  // this file can be replaced for translations

  // %VAL% will be replaced by a number, e.g. 3, 2.5, etc.

  public static func RESURRECT() -> String { return "RELIC Protocol Initiated Load Address: 0x00R%VAL% STATUS: CRITICAL "; } 

  public static func RESURRECTUNLIMITED() -> String { return "RELIC Protocol Initiated Load Address: 0x00R%VAL%S: CRITICAL ::FATAL ERROR::"; } 

  public static func PERMADEATH() -> String { return "The Santa Muerte welcomes you: CORRUPTED ::FATAL ERROR::"; } 

}