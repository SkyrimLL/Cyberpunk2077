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

@if(ModuleExists("DarkFuture.System"))
import DarkFuture.Needs.DFNerveSystem

@if(ModuleExists("DarkFuture.System"))
import DarkFuture.Needs.DFEnergySystem

@if(ModuleExists("DarkFuture.System"))
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

			this.showDebugMessage("SANTA MUERTE >>> SantaMuerteCompatibility_DarkFuture: Player attached, registering listener for fact " + ToString(this.baseFact));
			this.baseFactListenerId = this.questsSystem.RegisterListener(this.baseFact, this, n"OnFactChange");
		}
	}

	private final func OnPlayerDetach(request: ref<PlayerDetachRequest>) -> Void {
		this.questsSystem.UnregisterListener(this.baseFact, this.baseFactListenerId);
	}

	protected cb func OnFactChange(factValue: Int32) -> Bool {
		if factValue == 1 { // Beneficial effect: resurrections have a healing effect
			this.showDebugMessage("SantaMuerteCompatibility_DarkFuture: Beneficial effect: resurrections have a healing effect");
			this.dfNerveSystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(20.0, 40.0), true);
			this.dfEnergySystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(10.0, 20.0), true);
		} else {
			if factValue == 2 { // Detrimental effect: resurrections have a damaging effect
				this.showDebugMessage("SantaMuerteCompatibility_DarkFuture: Detrimental effect: resurrections have a damaging effect");
				this.dfNerveSystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(-10.0, -20.0), true);
				this.dfEnergySystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(-20.0, -40.0), true);
			}

		}
	}

	private func showDebugMessage(debugMessage: String) {
		// LogChannel(n"DEBUG", debugMessage ); 
	}
}


// NegotiableAffection compatibility
@if(ModuleExists("DarkFuture.System"))
public class NegotiableAffection_DarkFuture extends ScriptableSystem {
	private let questsSystem: wref<QuestsSystem>;
	private let dfNerveSystem: ref<DFNerveSystem>;
	private let dfEnergySystem: ref<DFEnergySystem>;

	private let baseFact: CName = n"na_v_is_working";

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

			this.showDebugMessage("SANTA MUERTE >>> NegotiableAffection_DarkFuture: Player attached, registering listener for fact " + ToString(this.baseFact));
			this.baseFactListenerId = this.questsSystem.RegisterListener(this.baseFact, this, n"OnFactChange");
		}
	}

	private final func OnPlayerDetach(request: ref<PlayerDetachRequest>) -> Void {
		this.questsSystem.UnregisterListener(this.baseFact, this.baseFactListenerId);
	}

	protected cb func OnFactChange(factValue: Int32) -> Bool {
		if factValue == 1 { // Beneficial effect: resurrections have a healing effect
			this.showDebugMessage("NegotiableAffection_DarkFuture: Beneficial effect: sex has a healing effect");
			this.dfNerveSystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(20.0, 40.0), true);
			this.dfEnergySystem.QueueContextuallyDelayedNeedValueChange(RandRangeF(10.0, 20.0), true);
		}  
	}

	private func showDebugMessage(debugMessage: String) {
		// LogChannel(n"DEBUG", debugMessage ); 
	}
}
 