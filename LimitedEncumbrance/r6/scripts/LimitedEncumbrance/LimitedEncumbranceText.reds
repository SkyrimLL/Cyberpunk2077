public class LimitedEncumbranceText {

  // defines the text that are dispayed in notifications
  // this file can be replaced for translations

  // %VAL% will be replaced by a number, e.g. 3, 2.5, etc.

  public static func HEAVY() -> String { return "Warning: severe encumbrance detected (%VAL% capacity left)"; }

  public static func OVERWEIGHT() -> String { return "Warning: critical encumbrance detected"; }

  public static func LIGHTER() -> String { return "Warning: encumbrance restored"; }

  // Weapon Limit System messages
  // %VAL% is replaced with maximum weapon slots
  public static func WEAPON_SLOTS_FULL() -> String { return "Weapon slots full! Maximum %VAL% slots"; }

  // %VAL% is replaced with current/max weapon slots (e.g., "4.5 / 3.0")
  public static func WEAPON_SLOTS_EXCEEDED() -> String { return "Too many weapons! Carrying %VAL% slots"; }

}