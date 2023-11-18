/*
@addMethod(QuickSlotsManager) 

  public final func NCLAIMRemoveVehicle(vehicleData: PlayerVehicle, vehicleModel: String ) -> Void {
    let playerOwner: ref<PlayerPuppet>; 

    // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Removing model '" +StrLower(vehicleModel) + "'"); 
    let vehiclesList: array<PlayerVehicle>;

    let matchFound = 0;
    let i = 0;

    // First look for a match in unlocked vehicles
    playerOwner = this.m_Player;

    // set up tracker if it doesn't exist
    if !IsDefined(playerOwner.m_claimedVehicleTracking) {
      playerOwner.m_claimedVehicleTracking = new ClaimedVehicleTracking();
      playerOwner.m_claimedVehicleTracking.init(playerOwner);
    } else {
      // Reset if already exists (in case of changed default values)
      playerOwner.m_claimedVehicleTracking.reset(playerOwner);
    };

    if (playerOwner.m_claimedVehicleTracking.modON) {
      GameInstance.GetVehicleSystem(this.m_Player.GetGame()).GetPlayerUnlockedVehicles(vehiclesList);

      if (playerOwner.m_claimedVehicleTracking.warningsON) {
        // LogChannel(n"DEBUG", " ");
        // LogChannel(n"DEBUG", "----- ");
        // LogChannel(n"DEBUG", ">>> N.C.L.A.I.M:  Removing model '" +StrLower(vehicleModel) + "'");
        playerOwner.SetWarningMessage(ClaimVehiclesText.REMOVING() + "'"+vehicleModel+"'"); 
      }

      // Retrieve RecordID and vehicle type for the matched vehicle model
      while i < ArraySize(vehiclesList) { 
        let _this_vehicleRecord: ref<Vehicle_Record> = TweakDBInterface.GetVehicleRecord(vehiclesList[i].recordID);
        let _this_vehicleModel: String = GetLocalizedItemNameByCName(_this_vehicleRecord.DisplayName());

        if (playerOwner.m_claimedVehicleTracking.warningsON) {
          // LogChannel(n"DEBUG", "N.C.L.A.I.M: Checking database for '"+StrLower(_this_vehicleModel)+"' - isUnlocked: " + vehiclesList[i].isUnlocked);
        }

        if ( StrCmp(StrLower(_this_vehicleModel), StrLower(vehicleModel)) == 0 ) {
          if (playerOwner.m_claimedVehicleTracking.warningsON) { 
            // LogChannel(n"DEBUG", ">>> Found matching vehicle record ID.");
          }
          matchFound = 1;
   
          // GameInstance.GetVehicleSystem(this.m_Player.GetGame()).TogglePlayerActiveVehicle(Cast<GarageVehicleID>(vehicleData.recordID), vehicleData.vehicleType, true); 
          playerOwner.m_claimedVehicleTracking.getVehicleStringFromModel(vehiclesList[i].recordID, _this_vehicleModel);

          if (StrCmp(playerOwner.m_claimedVehicleTracking.matchVehicleString, "")!=0) {

            GameInstance.GetVehicleSystem(playerOwner.GetGame()).EnablePlayerVehicle( playerOwner.m_claimedVehicleTracking.matchVehicleString, false, false);
          }
        }

        i += 1;
      };  

    };

  }
*/