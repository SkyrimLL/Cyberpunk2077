public class SantaMuerteText {
 
  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSLATION GUIDE
  // ═══════════════════════════════════════════════════════════════════════════
  // This file contains all user-facing text for the Santa Muerte mod.
  // To translate this mod, simply replace the text strings in each function.
  //
  // IMPORTANT: Preserve placeholder values in your translations:
  //   %VAL%     - Will be replaced with a number
  //   %COUNT%   - Will be replaced with current resurrection count
  //   %MAX%     - Will be replaced with maximum resurrection count
  //   %PERCENT% - Will be replaced with percentage value
  //
  // Example: "Resurrections: %COUNT%/%MAX%" → "Resurrezioni: %COUNT%/%MAX%"
  // ═══════════════════════════════════════════════════════════════════════════

  // %VAL% will be replaced by a number, e.g. 3, 2.5, etc.
  // %COUNT% and %MAX% will be replaced by resurrection counts
  // %PERCENT% will be replaced by percentage values

  public static func RESURRECT() -> String { return "RELIC Protocol Initiated Load Address: 0x00R%VAL% STATUS: CRITICAL "; } 

  public static func RESURRECTUNLIMITED() -> String { return "RELIC Protocol Initiated Load Address: 0x00R%VAL%S: CRITICAL ::FATAL ERROR::"; } 

  public static func PERMADEATH() -> String { return "The Santa Muerte welcomes you: CORRUPTED ::FATAL ERROR::"; }
  
  public static func FINALDEATH() -> String { return "RELIC FAILURE: Resurrection limit reached. Game will load last save."; } 

  public static func SAFETELEPORTFEE() -> String { return "Safety Extraction Processing Fee: %VAL%"; } 

  public static func HARVESTED() -> String { return "You discover with horror that some of your cyberware was carved out of your body."; } 

  public static func TUTORIALRESET() -> String { return "Santa Muerte: Tutorials have been reset."; }

  // ═══════════════════════════════════════════════════════════════════════════
  // Tutorial Titles
  // ═══════════════════════════════════════════════════════════════════════════

  public static func TUTORIAL_TITLE_FIRST_RESURRECTION() -> String { return "RELIC MALFUNCTION: RESURRECTION PROTOCOL ACTIVATED"; }

  public static func TUTORIAL_TITLE_SAFE_TELEPORT() -> String { return "EMERGENCY MEDICAL EXTRACTION"; }

  public static func TUTORIAL_TITLE_DETOUR_TELEPORT() -> String { return "CONSCIOUSNESS RESTORED: UNKNOWN LOCATION"; }

  public static func TUTORIAL_TITLE_ROBBERY() -> String { return "WARNING: INVENTORY DISCREPANCY DETECTED"; }

  public static func TUTORIAL_TITLE_CYBERWARE_REMOVAL() -> String { return "CRITICAL ALERT: CYBERWARE EXTRACTION DETECTED"; }

  public static func TUTORIAL_TITLE_LOW_RESURRECTIONS() -> String { return "RELIC WARNING: DEGRADATION DETECTED"; }

  public static func TUTORIAL_TITLE_CRITICAL_RESURRECTIONS() -> String { return "CRITICAL ALERT: RELIC FAILURE IMMINENT"; }

  public static func TUTORIAL_TITLE_SLEEP_RECOVERY() -> String { return "RELIC STATUS: STABILIZATION DETECTED"; }

  // ═══════════════════════════════════════════════════════════════════════════
  // Tutorial Messages
  // ═══════════════════════════════════════════════════════════════════════════

  public static func TUTORIAL_MSG_FIRST_RESURRECTION() -> String {
    let msg: String = "";
    msg += "The Relic has initiated an emergency resurrection protocol. Your vital functions have been restored, but at a cost.\n\n";
    msg += "RELIC STATUS:\n";
    msg += "• Resurrections Remaining: %COUNT%/%MAX%\n";
    msg += "• Each death consumes one resurrection charge\n";
    msg += "• When charges are depleted, death will be permanent\n\n";
    msg += "• With the Soulkiller permadeath add-on, your last death means having to start a new game\n\n";
    msg += "The Relic's capabilities may evolve as your journey continues. Monitor your status carefully.";
    return msg;
  }

  public static func TUTORIAL_MSG_SAFE_TELEPORT() -> String {
    let msg: String = "";
    msg += "Emergency medical services have been automatically contacted. You've been extracted to a safe medical facility.\n\n";
    msg += "EXTRACTION DETAILS:\n";
    msg += "• Time has passed during transport and treatment\n";
    msg += "• A processing fee has been deducted from your account\n";
    msg += "• This service may not always be available\n\n";
    msg += "Consider this a second chance. Not all resurrections will be this clean.";
    return msg;
  }

  public static func TUTORIAL_MSG_DETOUR_TELEPORT() -> String {
    let msg: String = "";
    msg += "Your consciousness faded. When you came to, you were somewhere... different.\n\n";
    msg += "SITUATION ASSESSMENT:\n";
    msg += "• Significant time has passed\n";
    msg += "• Your location is unfamiliar\n";
    msg += "• Some of your belongings may be missing\n";
    msg += "• Hostile forces may have taken advantage of your vulnerability\n\n";
    msg += "The streets of Night City are unforgiving. Stay vigilant.";
    return msg;
  }

  public static func TUTORIAL_MSG_ROBBERY() -> String {
    let msg: String = "";
    msg += "While unconscious, someone took advantage of your vulnerable state.\n\n";
    msg += "LOSSES DETECTED:\n";
    msg += "• Credits have been stolen\n";
    msg += "• Equipment may be missing\n";
    msg += "• Check your inventory carefully\n\n";
    msg += "In Night City, weakness is an invitation. Every death carries risks beyond the loss of a resurrection charge.";
    return msg;
  }

  public static func TUTORIAL_MSG_CYBERWARE_REMOVAL() -> String {
    let msg: String = "";
    msg += "Your cyberware has been harvested while you were unconscious.\n\n";
    msg += "EXTRACTION DETECTED:\n";
    msg += "• One or more cyberware implants have been removed\n";
    msg += "• Your augmentations are valuable on the black market\n";
    msg += "• Check your cyberware inventory immediately\n";
    msg += "• You'll need to reinstall missing implants\n\n";
    msg += "Night City's ripperdocs aren't the only ones who know how to extract chrome. Death leaves you vulnerable to scavengers who see your body as merchandise.";
    return msg;
  }

  public static func TUTORIAL_MSG_LOW_RESURRECTIONS() -> String {
    let msg: String = "";
    msg += "Your Relic resurrection reserves are running low.\n\n";
    msg += "CURRENT STATUS: %PERCENT%%\n";
    msg += "Resurrections Remaining: %COUNT%/%MAX%\n\n";
    msg += "Consider playing more cautiously or finding ways to restore your Relic's capabilities.";
    return msg;
  }

  public static func TUTORIAL_MSG_CRITICAL_RESURRECTIONS() -> String {
    let msg: String = "";
    msg += "CRITICAL WARNING: Your Relic is nearly depleted.\n\n";
    msg += "Resurrections Remaining: %COUNT%/%MAX%\n\n";
    msg += "The next death could be your last. Extreme caution is advised.";
    return msg;
  }

  public static func TUTORIAL_MSG_SLEEP_RECOVERY() -> String {
    let msg: String = "";
    msg += "Rest has allowed the Relic to partially stabilize.\n\n";
    msg += "RECOVERY DETAILS:\n";
    msg += "• Resurrection charges have been restored\n";
    msg += "• Regular rest may help maintain Relic functionality\n";
    msg += "• Current Status: %COUNT%/%MAX%\n\n";
    msg += "Your body and the Relic are learning to coexist. Time and rest may be your allies.";
    return msg;
  }

}