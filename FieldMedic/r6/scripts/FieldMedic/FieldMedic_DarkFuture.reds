// FieldMedic — Dark Future compatibility
//
// Restores a small amount of Nerve when the player consumes a FieldMedic Bubblegum.
// Bubblegum carries the `FieldMedic_Bubblegum` tag (see junk_consumables.yaml); that tag is
// the marker used here since ConsumeAction only exposes the gameItemData at consume time,
// not the TweakDBID directly.
//
// Uses the same @if(ModuleExists(...)) guard pattern as SantaMuerte_DarkFuture.reds so this
// file compiles cleanly whether or not Dark Future is installed, without any load-order
// dependency or missing-module errors.

@if(ModuleExists("DarkFuture.System"))
import DarkFuture.Needs.DFNerveSystem

@if(ModuleExists("DarkFuture.System"))
@wrapMethod(ConsumeAction)
public func CompleteAction(gameInstance: GameInstance) -> Void {
  let itemData: wref<gameItemData> = this.GetItemData();
  let isBubblegum: Bool = IsDefined(itemData) && itemData.HasTag(n"FieldMedic_Bubblegum");
  let executor: wref<GameObject>;
  if isBubblegum {
    executor = this.GetExecutor();
  }

  wrappedMethod(gameInstance);

  if !isBubblegum || !IsDefined(executor) {
    return;
  }

  let dfNerveSystem: ref<DFNerveSystem> = DFNerveSystem.GetInstance(executor.GetGame());
  if IsDefined(dfNerveSystem) {
    dfNerveSystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(4.0, 8.0), true);

    let cfg: ref<FieldMedicConfig> = FieldMedicConfig.Get();
    if cfg.debugLog {
      LogChannel(n"DEBUG", "[FieldMedic] DarkFuture: restored Nerve from Bubblegum");
    }
  }
}

// No-op fallback so the mod behaves identically to vanilla ConsumeAction when Dark Future
// isn't installed — nothing here needs Nerve, so there is nothing to restore.
@if(!ModuleExists("DarkFuture.System"))
public abstract final class FieldMedicDarkFutureUnavailable {}
