BaseStats = {
	description = "Base Stat Changes"
}

function BaseStats:new()
	
	--=================================================
	--V's STATS
	--=================================================
	--Basic Stats
	      TweakDB:SetFlat("Character.Player_Primary_Stats_Base_inline10.value", 60) --<< Carry Capacity. Default >>> 200
	      TweakDB:SetFlat("Character.Player_Stat_Pools_Modifier_inline32.value", 1.0) --<< Out Of Combat Heal Regen Rate. Default >>> 3
	      TweakDB:SetFlat("Character.Player_Stat_Pools_Modifier_inline27.value", 30.0) --<< Out Of Combat Heal Regen End Threshold. Default >>> 60
	      TweakDB:SetFlat("Character.Player_Stat_Pools_Modifier_inline17.value", 0.5) --In Combat Heal Regen Rate. Default >>> 1

	--=================================================
	--NPC STATS
	--=================================================
	--Robots: Drone
	      TweakDB:SetFlat("Character.Drone_Primary_Stat_ModGroup_inline21.value", 9.2) --Health Multiplier: Default 0.4
	--Robots: Android
	      TweakDB:SetFlat("Character.Android_Primary_Stat_ModGroup_inline0.value", 9.5) --Health Multiplier: Default NoN
	--Robots: Mech
	      TweakDB:SetFlat("Character.Mech_Primary_Stat_ModGroup_inline0.value", 35.0) --Health Multiplier: Default 15.0
 
end

return BaseStats:new()