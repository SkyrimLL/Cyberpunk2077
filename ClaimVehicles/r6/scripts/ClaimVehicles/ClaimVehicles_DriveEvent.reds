
// public class DriveEvents extends VehicleEventsTransition {

@replaceMethod(DriveEvents) 

public final func OnExit(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
    let owner: ref<PlayerPuppet>;
    let transition: PuppetVehicleState = this.GetPuppetVehicleSceneTransition(stateContext);


    if Equals(transition, PuppetVehicleState.CombatSeated) || Equals(transition, PuppetVehicleState.CombatWindowed) {
      this.SendEquipmentSystemWeaponManipulationRequest(scriptInterface, EquipmentManipulationAction.RequestLastUsedOrFirstAvailableWeapon);
    };

    let playerOwner: ref<PlayerPuppet>;
    let vehicle: ref<VehicleObject>;
    let currentData: ref<VehicleListItemData>;
 
    playerOwner = scriptInterface.executionOwner as PlayerPuppet;
    if IsDefined(playerOwner) {
      playerOwner.InitClaimVehicleSystem();
      
      if (playerOwner.m_claimedVehicleTracking.modON) {

        vehicle = scriptInterface.owner as VehicleObject;

        // Added here to display vehicle Model strings in logs even when mod doesn't trigger - Remove once testing is done
        let claimedVehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehicle.GetRecordID());
        let claimedVehicleModel: String = GetLocalizedItemNameByCName(claimedVehicleRecord.DisplayName());

        playerOwner.m_claimedVehicleTracking.getVehicleStringFromModel(vehicle.GetRecordID(), claimedVehicleModel);

        // if (playerOwner.m_claimedVehicleTracking.debugON) {  playerOwner.SetWarningMessage("Vehicle state - abandonned: " + ToString(vehicle.m_abandoned) ); }
 
        // // LogChannel(n"DEBUG", ":: OnExit - q001_victor_char_entry: " + GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"q001_victor_char_entry"));
        // // LogChannel(n"DEBUG", ":: OnExit - tutorial_ripperdoc_slots: " + GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"tutorial_ripperdoc_slots"));
        // // LogChannel(n"DEBUG", ":: OnExit - tutorial_ripperdoc_buy: " + GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"tutorial_ripperdoc_buy"));

        let isVictorHUDInstalled: Bool = GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"q001_ripperdoc_done") >= 1;
        let isPhantomLiberyStandalone: Bool = GameInstance.GetQuestsSystem(playerOwner.GetGame()).GetFact(n"ep1_standalone") >= 1;

        if (playerOwner.m_claimedVehicleTracking.debugON) {
          // LogChannel(n"DEBUG", ":: tryClaimVehicle - isVictorHUDInstalled: " + isVictorHUDInstalled);
          // LogChannel(n"DEBUG", ":: tryClaimVehicle - isPhantomLiberyStandalone: " + isPhantomLiberyStandalone);
        }

        let playerDevSystem: ref<PlayerDevelopmentSystem> = GameInstance.GetScriptableSystemsContainer(playerOwner.GetGame()).Get(n"PlayerDevelopmentSystem") as PlayerDevelopmentSystem;

        // New perk system
        // PlayerDevelopmentSystem.GetData(player).IsNewPerkBought(gamedataNewPerkType.Intelligence_Central_Milestone_3)

        // 
        // Technical - Gearhead - Tech_Right_Milestone_1 - 4 -  +33% vehicle health.
        // Intelligence - Carhacker - Intelligence_Right_Milestone_1 - 4 - Unlocks Vehicle quickhacks, allowing you to take control, set off alarms or even blow them up.
        // Cool - Road Warrior - Cool_Left_Milestone_1 - 4 - Allows you to use Sandevistan to slow time while driving.
        // 20% chance of registering vehicle on exit
        let playerGearheadLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Tech_Right_Milestone_1);
        let playerCarhackerLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Intelligence_Right_Milestone_1);
        let playerRoadWarriorLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Cool_Left_Milestone_1);

        // Technical - Driver Update - Tech_Central_Perk_2_1 - 9 - All cyberware gain an additional stat modifier.  
        // Intelligence - System Overwhelm - Intelligence_Central_Perk_2_3 - 9 - +7% quickhack damage for each unique quickhack and DOT effect affecting the target.
        // Cool - Sleight of Hand - Cool_Right_Perk_3_4 - 15 - +20% Crit damage for 8 sec. whenever Juggler is activated.
        // 50% chance of registering vehicle on exit
        let playerDriverUpdateLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Tech_Central_Perk_2_1);
        let playerSystemOverwhelmLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Intelligence_Central_Perk_2_3);
        let playerSleightofHandLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Cool_Right_Perk_3_4);

        // Technical - Edgerunner - Tech_Master_Perk_3 - 20 - Allows you to exceed your Cyberware Capacity by up to 50 points, but at the cost of -0.5% Max Health per point.
        // Intelligence - Smart Synergy - Intelligence_Master_Perk_4 - 20 - When Overclock is active, smart weapons gain instant target lock, and +25% damage if the enemy is affected by a quickhack.
        // Cool - Style Over Substance - Cool_Master_Perk_4 - 20 - Guaranteed Crit Hits with throwable weapons when crouch-sprinting, sliding, dodging or Dashing.
        // 100% chance of registering vehicle on exit
        let playerEdgerunnerLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Tech_Master_Perk_3);
        let playerSmartSynergyLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Intelligence_Master_Perk_4);
        let playerStyleOverSubstanceLevel = playerDevSystem.GetPerkLevel(playerOwner, gamedataNewPerkType.Cool_Master_Perk_4);

        if (playerOwner.m_claimedVehicleTracking.debugON) {
          // LogChannel(n"DEBUG", "::: addClaimedVehicle - Gearhead perk level: '"+playerGearheadLevel+"'"  );
          // LogChannel(n"DEBUG", "::: addClaimedVehicle - Car Hacker perk level: '"+playerCarhackerLevel+"'"  );
          // LogChannel(n"DEBUG", "::: addClaimedVehicle - Road Warrior level: '"+playerRoadWarriorLevel+"'"  );
        }

        // Ignore automatic hacking of car if:
        // - car already belongs to player
        // - player doesn't have the Field Technician perk
        // - eventually, player has received HUD enhancements from Victor (TO DO)

        if ((isVictorHUDInstalled) || (isPhantomLiberyStandalone)) && (playerCarhackerLevel>0) {
            let isVehicleHackable: Bool = false;
            let chanceHack: Int32 = RandRange(1,100);
            let playerOnStealTrigger: Int32 = Cast<Int32>(100.0 - playerOwner.m_claimedVehicleTracking.chanceOnSteal);
            let chanceLowPerkHack: Int32 = Cast<Int32>(playerOwner.m_claimedVehicleTracking.chanceLowPerkHack);
            let chanceMidPerkHack: Int32 = Cast<Int32>(playerOwner.m_claimedVehicleTracking.chanceMidPerkHack);
            let chanceHighPerkHack: Int32 = Cast<Int32>(playerOwner.m_claimedVehicleTracking.chanceHighPerkHack);
            let playerOnPerkTrigger: Int32 = 0;
            let numPlayerPerks: Int32 = 0;

            // Low level
            if (playerGearheadLevel > 0) {
              playerOnPerkTrigger += chanceLowPerkHack;
              numPlayerPerks += 1;
            }
            if (playerCarhackerLevel > 0) {
              playerOnPerkTrigger += chanceLowPerkHack;
              numPlayerPerks += 1;
            }
            if (playerRoadWarriorLevel > 0) {
              playerOnPerkTrigger += chanceLowPerkHack;
              numPlayerPerks += 1;
            }

            // Mid level
            if (playerDriverUpdateLevel > 0){
              playerOnPerkTrigger = chanceMidPerkHack;
              numPlayerPerks += 1;
            }
            if (playerSystemOverwhelmLevel > 0) {
              playerOnPerkTrigger += chanceMidPerkHack;
              numPlayerPerks += 1;
            }
            if (playerSleightofHandLevel > 0) {
              playerOnPerkTrigger += chanceMidPerkHack;
              numPlayerPerks += 1;
            }

            // High level
            if (playerEdgerunnerLevel > 0) {
              playerOnPerkTrigger += chanceHighPerkHack;
              numPlayerPerks += 1;
            }
            if (playerSmartSynergyLevel > 0) {
              playerOnPerkTrigger += chanceHighPerkHack;
              numPlayerPerks += 1;
            }
            if (playerStyleOverSubstanceLevel > 0) {
              playerOnPerkTrigger += chanceHighPerkHack;
              numPlayerPerks += 1;
            }

            if (numPlayerPerks>0) {
              playerOnPerkTrigger = 100 - Min( ( (playerOnPerkTrigger + (numPlayerPerks * 5)) / numPlayerPerks), 100);

              // LogChannel(n"DEBUG", "::: addClaimedVehicle - numPlayerPerks: '"+ToString(numPlayerPerks)+"'"  );
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - playerOnPerkTrigger: '"+ToString(playerOnPerkTrigger)+"'"  );
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - chanceHack: '"+ToString(chanceHack)+"'"  );

              if (chanceHack > playerOnPerkTrigger) {
                isVehicleHackable = true;
              }  

            }

            // Hack until Perks are restored
            // if (chanceHack  > (playerOnStealTrigger / 4)) {
            //   isVehicleHackable = true;
            // } 

            if (playerOwner.m_claimedVehicleTracking.debugON) {
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - chanceHack: '"+ToString(chanceHack)+"'"  );
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - chanceLowPerkHack: '"+ToString(chanceLowPerkHack)+"'"  );
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - chanceMidPerkHack: '"+ToString(chanceMidPerkHack)+"'"  );
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - chanceHighPerkHack: '"+ToString(chanceHighPerkHack)+"'"  );
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - isVehicleHackable: "+ToString(isVehicleHackable)  );
            }
     
            if (isVehicleHackable){ 
               playerOwner.m_claimedVehicleTracking.tryClaimVehicle(vehicle, true);   

            }  else {
              // LogChannel(n"DEBUG", "::: addClaimedVehicle - Claim failed - reporting a crime"  );

              // vehicle.StealVehicle(playerOwner as ref<GameObject>);

              let stealEvent: ref<StealVehicleEvent>;
              stealEvent = new StealVehicleEvent();
              vehicle.QueueEvent(stealEvent);

            }


            // Commented out for 2.0.2 testing
            // playerOwner.m_claimedVehicleTracking.tryPersistVehicle(vehicle);
          }
        }


    };

    this.SetIsVehicleDriver(stateContext, false);
    this.SendAnimFeature(stateContext, scriptInterface);
    this.ResetVehFppCameraParams(stateContext, scriptInterface);
    this.isCameraTogglePressed = false;
    this.ResumeStateMachines(scriptInterface.executionOwner);
    GameInstance.GetRazerChromaEffectsSystem(scriptInterface.executionOwner.GetGame()).SetIdleAnimation(n"HotKeys", true);
    if this.m_inCombatBlockingForbiddenZone {
      this.m_inCombatBlockingForbiddenZone = false;
      StatusEffectHelper.RemoveStatusEffect(scriptInterface.executionOwner, t"GameplayRestriction.NoWeapons", 1u);
    };
}
