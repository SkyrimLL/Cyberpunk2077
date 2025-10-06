// ************************************************************************************************
// ***  Source: Lizzie's Braindances - DF compatibility
// ***    Author: ArmanIII
// ***
// *** Please, if you will have unconquerable lust to edit this file (which I don't recommend),
// *** then please do not report any bugs you will encounter in the mod, because I don't want
// *** then spend X hours of searching of a bug which doesn't exist and in the end we find that
// *** it's all your fault. Help me save my nerves. Thanks.
// ***
// ************************************************************************************************

module SantaMuerte.Compatibility

@if(ModuleExists("DarkFuture"))
import DarkFuture.Needs.DFNerveSystem

@if(ModuleExists("DarkFuture"))
import DarkFuture.Needs.DFEnergySystem

@if(ModuleExists("DarkFuture"))
public class SantaMuerteCompatibility_DarkFuture extends ScriptableSystem {
	private let questsSystem: wref<QuestsSystem>;
	private let dfNerveSystem: ref<DFNerveSystem>;
	private let dfEnergySystem: ref<DFEnergySystem>;

	private let baseFact: CName = n"SantaMuerteDFState";

	private let baseFactListenerId: Uint32;

	private final func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
		if GameInstance.GetSystemRequestsHandler().IsPreGame() {
			return;
		}

		let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(request.owner.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
		if IsDefined(player) {
			let gameInst: GameInstance = player.GetGame();

			this.questsSystem = GameInstance.GetQuestsSystem(gameInst);
			this.dfNerveSystem = DFNerveSystem.GetInstance(gameInst);
			this.dfEnergySystem = DFEnergySystem.GetInstance(gameInst);

			this.baseFactListenerId = this.questsSystem.RegisterListener(this.baseFact, this, n"OnFactChange");
		}
	}

	private final func OnPlayerDetach(request: ref<PlayerDetachRequest>) -> Void {
		this.questsSystem.UnregisterListener(this.baseFact, this.baseFactListenerId);
	}

	protected cb func OnFactChange(factValue: Int32) -> Bool {
		if factValue == 1 {
			this.dfNerveSystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(10.0, 20.0), true);
			this.dfEnergySystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(20.0, 40.0), true);
		} else {
			if factValue == 2 {
				this.dfNerveSystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(-10.0, -20.0), true);
				this.dfEnergySystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(-20.0, -40.0), true);
			}

		}
	}
}