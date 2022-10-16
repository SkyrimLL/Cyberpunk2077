WeightAdder = {
	description = "Adds Weight to NonWeight Items"
}

function WeightAdder:new()

	--=================================================
	--WEIGHT ADDER - WEAPONS 
	--=================================================
	--Melee:
	      TweakDB:SetFlat("Items.Base_Baton_RPG_Stats_inline1.value", 8.4)
	      TweakDB:SetFlat("Items.Base_Axe_RPG_Stats_inline1.value", 4.4)
	      TweakDB:SetFlat("Items.Base_Chainsword_RPG_Stats_inline1.value", 8.8)
	      TweakDB:SetFlat("Items.Base_Katana_RPG_Stats_inline1.value", 2.0)
	      TweakDB:SetFlat("Items.Base_Knife_RPG_Stats_inline1.value", 1.2)
	      TweakDB:SetFlat("Items.Base_Machete_RPG_Stats_inline1.value", 1.5)
	      TweakDB:SetFlat("Items.Base_One_Hand_Blade_RPG_Stats_inline1.value", 1.4)
	      TweakDB:SetFlat("Items.Base_One_Hand_Blunt_RPG_Stats_inline1.value", 2.8)
	      TweakDB:SetFlat("Items.Base_Two_Hand_Blunt_RPG_Stats_inline1.value", 5.4)
	      TweakDB:SetFlat("Items.Base_Two_Hand_Hammer_RPG_Stats_inline1.value", 3.6)

	--Ranged:
	      TweakDB:SetFlat("Items.Base_Handgun_RPG_Stats_inline1.value", 1.6)
	      TweakDB:SetFlat("Items.Base_Lightmachinegun_RPG_Stats_inline1.value", 12.2)
	      TweakDB:SetFlat("Items.Base_Revolver_RPG_Stats_inline1.value", 2.2)
	      TweakDB:SetFlat("Items.Base_Assault_Rifle_RPG_Stats_inline1.value", 24.4)
	      TweakDB:SetFlat("Items.Base_Precision_Rifle_RPG_Stats_inline1.value", 13.6)
	      TweakDB:SetFlat("Items.Base_Sniper_Rifle_RPG_Stats_inline1.value", 14.3)
	      TweakDB:SetFlat("Items.Base_Shotgun_RPG_Stats_inline1.value", 6.4)
	      TweakDB:SetFlat("Items.Base_Dual_Shotgun_RPG_Stats_inline1.value", 8.5)
	      TweakDB:SetFlat("Items.Base_Submachinegun_RPG_Stats_inline1.value", 8.9)

	--=================================================
	--WEIGHT ADDER - WEAPONS ATTACHMENTS
	--=================================================
	--Muzzles:
	      TweakDB:SetFlat("Items.SilencerBase_inline3.value", 0.5)
	      TweakDB:SetFlat("Items.MuzzleBrakeBase_inline6.value", 0.4)

	--Scopes:
	      TweakDB:SetFlat("Items.Base_Short_Scope_inline2.value", 0.4)
	      TweakDB:SetFlat("Items.Base_Long_Scope_inline2.value", 0.6)
	      TweakDB:SetFlat("Items.Base_Sniper_Scope_inline2.value", 0.9)

	--=================================================
	--WEIGHT ADDER - MODIFICATIONS
	--=================================================
	      TweakDB:SetFlat("Items.Mod_inline0.value", 0.2)

	--=================================================
	--WEIGHT ADDER - GRENADE/GADGETS 
	--=================================================
	      TweakDB:SetFlat("Items.GrenadeOzobsNose_inline10.value", 0.5)
	      TweakDB:SetFlat("Items.Preset_Grenade_Cutting_Default_inline8.value", 0.8)
	      TweakDB:SetFlat("Items.Preset_Grenade_Recon_Default_inline4.value", 2.0)
	      TweakDB:SetFlat("Items.Preset_Grenade_Incendiary_Default_inline7.value", 1.0)
	      TweakDB:SetFlat("Items.Preset_Grenade_Biohazard_Default_inline7.value", 1.0)
	      TweakDB:SetFlat("Items.Preset_Grenade_EMP_Default_inline8.value", 1.0)
	      TweakDB:SetFlat("Items.Preset_Grenade_Flash_Default_inline4.value", 1.5)
	      TweakDB:SetFlat("Items.Preset_Grenade_Frag_Default_inline10.value", 1.0)

	--=================================================
	--WEIGHT ADDER - CRAFTING MATERIALS
	--=================================================
	      TweakDB:SetFlat("Items.CraftingPart_inline0.value", 0.03)

	--=================================================
	--WEIGHT ADDER - CONSUMABLES
	--=================================================
	      TweakDB:SetFlat("Items.Alcohol_inline0.value", 1.0)
	      TweakDB:SetFlat("Items.Drink_inline2.value", 0.5)
	      TweakDB:SetFlat("Items.Food_inline2.value", 0.5)
	      TweakDB:SetFlat("Items.Inhaler_inline2.value", 0.3)
		  TweakDB:SetFlat("Items.Injector_inline2.value", 0.3)
		  TweakDB:SetFlat("Items.LongLasting_inline0.value", 3.0)

	--=================================================
	--WEIGHT ADDER - JEWELRY ITEMS
	--=================================================
	--Low Quality Jewelry:
	      TweakDB:SetFlat("Items.LowQualityJewellery1_inline0.value", 0.1)
          TweakDB:SetFlat("Items.LowQualityJewellery2_inline0.value", 0.3)
          TweakDB:SetFlat("Items.LowQualityJewellery3_inline0.value", 0.3)
          TweakDB:SetFlat("Items.LowQualityJewellery4_inline0.value", 0.1)
          TweakDB:SetFlat("Items.LowQualityJewellery5_inline0.value", 0.2)
	--Medium Quality Jewelry:
	      TweakDB:SetFlat("Items.MediumQualityJewellery1_inline0.value", 0.1)
          TweakDB:SetFlat("Items.MediumQualityJewellery2_inline0.value", 0.2)
          TweakDB:SetFlat("Items.MediumQualityJewellery3_inline0.value", 0.4)
          TweakDB:SetFlat("Items.MediumQualityJewellery4_inline0.value", 0.3)
          TweakDB:SetFlat("Items.MediumQualityJewellery5_inline0.value", 0.2)
	--High Quality Jewelry:
	      TweakDB:SetFlat("Items.HighQualityJewellery1_inline0.value", 0.3)
          TweakDB:SetFlat("Items.HighQualityJewellery2_inline0.value", 0.5)
          TweakDB:SetFlat("Items.HighQualityJewellery3_inline0.value", 0.2)
          TweakDB:SetFlat("Items.HighQualityJewellery4_inline0.value", 0.1)
          TweakDB:SetFlat("Items.HighQualityJewellery5_inline0.value", 0.1)
	--Valentinos Jewelry:
	      TweakDB:SetFlat("Items.ValentinosJewellery1_inline0.value", 0.2)
          TweakDB:SetFlat("Items.ValentinosJewellery3_inline0.value", 0.1)
          TweakDB:SetFlat("Items.ValentinosJewellery4_inline0.value", 0.5)
          TweakDB:SetFlat("Items.ValentinosJewellery5_inline0.value", 0.2)
	--Tiger Claws Jewelry:
	      TweakDB:SetFlat("Items.TygerClawsJewellery1_inline0.value", 0.2)
          TweakDB:SetFlat("Items.TygerClawsJewellery2_inline0.value", 0.3)
          TweakDB:SetFlat("Items.TygerClawsJewellery3_inline0.value", 0.3)
	--Animals Jewelry:
	      TweakDB:SetFlat("Items.AnimalsJewellery1_inline0.value", 0.3)
          TweakDB:SetFlat("Items.AnimalsJewellery2_inline0.value", 0.4)
          TweakDB:SetFlat("Items.AnimalsJewellery3_inline0.value", 0.3)

	--=================================================
	--WEIGHT ADDER - JUNK ITEMS
	--=================================================
	--Generic Junk:
	      TweakDB:SetFlat("Items.GenericJunkItem1_inline0.value", 2.0)
          TweakDB:SetFlat("Items.GenericJunkItem2_inline0.value", 2.0)
          TweakDB:SetFlat("Items.GenericJunkItem3_inline0.value", 2.0)
          TweakDB:SetFlat("Items.GenericJunkItem4_inline0.value", 0.2)
          TweakDB:SetFlat("Items.GenericJunkItem5_inline0.value", 0.1)
	      TweakDB:SetFlat("Items.GenericJunkItem6_inline0.value", 1.0)
          TweakDB:SetFlat("Items.GenericJunkItem7_inline0.value", 0.5)
          TweakDB:SetFlat("Items.GenericJunkItem8_inline0.value", 1.8)
          TweakDB:SetFlat("Items.GenericJunkItem9_inline0.value", 1.8)
          TweakDB:SetFlat("Items.GenericJunkItem10_inline0.value", 1.4)
	      TweakDB:SetFlat("Items.GenericJunkItem11_inline0.value", 2.0)
          TweakDB:SetFlat("Items.GenericJunkItem12_inline0.value", 1.3)
          TweakDB:SetFlat("Items.GenericJunkItem13_inline0.value", 1.3)
          TweakDB:SetFlat("Items.GenericJunkItem14_inline0.value", 0.1)
          TweakDB:SetFlat("Items.GenericJunkItem15_inline0.value", 0.2)		  
	      TweakDB:SetFlat("Items.GenericJunkItem16_inline0.value", 0.4)
          TweakDB:SetFlat("Items.GenericJunkItem17_inline0.value", 0.4)
          TweakDB:SetFlat("Items.GenericJunkItem18_inline0.value", 1.0)
          TweakDB:SetFlat("Items.GenericJunkItem19_inline0.value", 0.8)
          TweakDB:SetFlat("Items.GenericJunkItem20_inline0.value", 0.3)
	      TweakDB:SetFlat("Items.GenericJunkItem21_inline0.value", 0.3)
          TweakDB:SetFlat("Items.GenericJunkItem22_inline0.value", 0.6)
          TweakDB:SetFlat("Items.GenericJunkItem23_inline0.value", 0.3)
          TweakDB:SetFlat("Items.GenericJunkItem24_inline0.value", 0.3)
          TweakDB:SetFlat("Items.GenericJunkItem25_inline0.value", 0.2)
	      TweakDB:SetFlat("Items.GenericJunkItem26_inline0.value", 0.6)
          TweakDB:SetFlat("Items.GenericJunkItem27_inline0.value", 0.7)
          TweakDB:SetFlat("Items.GenericJunkItem28_inline0.value", 0.1)
          TweakDB:SetFlat("Items.GenericJunkItem29_inline0.value", 0.3)
          TweakDB:SetFlat("Items.GenericJunkItem30_inline0.value", 0.3)	
	--Corpo Junk:
	      TweakDB:SetFlat("Items.GenericCorporationJunkItem1_inline0.value", 0.3)
          TweakDB:SetFlat("Items.GenericCorporationJunkItem2_inline0.value", 1.6)
          TweakDB:SetFlat("Items.GenericCorporationJunkItem3_inline0.value", 0.1)
          TweakDB:SetFlat("Items.GenericCorporationJunkItem4_inline0.value", 1.0)
          TweakDB:SetFlat("Items.GenericCorporationJunkItem5_inline0.value", 1.1)
	--Gang Junk:
	      TweakDB:SetFlat("Items.GenericGangJunkItem1_inline0.value", 1.2)
          TweakDB:SetFlat("Items.GenericGangJunkItem2_inline0.value", 0.1)
          TweakDB:SetFlat("Items.GenericGangJunkItem3_inline0.value", 0.1)
          TweakDB:SetFlat("Items.GenericGangJunkItem4_inline0.value", 1.3)
          TweakDB:SetFlat("Items.GenericGangJunkItem5_inline0.value", 0.8)
	--Poor Junk:
	      TweakDB:SetFlat("Items.GenericPoorJunkItem1_inline0.value", 1.3)
          TweakDB:SetFlat("Items.GenericPoorJunkItem2_inline0.value", 0.9)
          TweakDB:SetFlat("Items.GenericPoorJunkItem3_inline0.value", 0.6)
          TweakDB:SetFlat("Items.GenericPoorJunkItem4_inline0.value", 3.0)
          TweakDB:SetFlat("Items.GenericPoorJunkItem5_inline0.value", 1.4)
	--Rich Junk:
	      TweakDB:SetFlat("Items.GenericRichJunkItem1_inline0.value", 4.0)
          TweakDB:SetFlat("Items.GenericRichJunkItem2_inline0.value", 5.0)
          TweakDB:SetFlat("Items.GenericRichJunkItem3_inline0.value", 3.0)
          TweakDB:SetFlat("Items.GenericRichJunkItem4_inline0.value", 0.2)
          TweakDB:SetFlat("Items.GenericRichJunkItem5_inline0.value", 2.5)
	--Casion Junk:
	      TweakDB:SetFlat("Items.CasinoJunkItem1_inline0.value", 0.1)
          TweakDB:SetFlat("Items.CasinoJunkItem2_inline0.value", 0.1)
          TweakDB:SetFlat("Items.CasinoJunkItem3_inline0.value", 0.3)
	--Casion Poor Junk:
	      TweakDB:SetFlat("Items.CasinoPoorJunkItem1_inline0.value", 0.1)
          TweakDB:SetFlat("Items.CasinoPoorJunkItem2_inline0.value", 0.1)
          TweakDB:SetFlat("Items.CasinoPoorJunkItem3_inline0.value", 0.7)
	--Casion Rich Junk:
	      TweakDB:SetFlat("Items.CasinoRichJunkItem1_inline0.value", 0.2)
          TweakDB:SetFlat("Items.CasinoRichJunkItem2_inline0.value", 0.1)
          TweakDB:SetFlat("Items.CasinoRichJunkItem3_inline0.value", 0.2)
	--Sexy Toys Junk:
	      TweakDB:SetFlat("Items.SexToyJunkItem1_inline0.value", 2.2)
          TweakDB:SetFlat("Items.SexToyJunkItem2_inline0.value", 2.0)
          TweakDB:SetFlat("Items.SexToyJunkItem3_inline0.value", 0.3)
	      TweakDB:SetFlat("Items.SexToyJunkItem1_inline0.value", 0.7)
          TweakDB:SetFlat("Items.SexToyJunkItem2_inline0.value", 0.8)
          TweakDB:SetFlat("Items.SexToyJunkItem3_inline0.value", 3.5)
	--Souvenir Junk:
	      TweakDB:SetFlat("Items.SouvenirJunkItem1_inline0.value", 0.1)
          TweakDB:SetFlat("Items.SouvenirJunkItem2_inline0.value", 0.5)
          TweakDB:SetFlat("Items.SouvenirJunkItem3_inline0.value", 0.3)
	      TweakDB:SetFlat("Items.SouvenirJunkItem1_inline0.value", 1.0)
	--Nomads Junk:
	      TweakDB:SetFlat("Items.NomadsJunkItem1_inline0.value", 2.0)
          TweakDB:SetFlat("Items.NomadsJunkItem2_inline0.value", 0.4)
          TweakDB:SetFlat("Items.NomadsJunkItem3_inline0.value", 0.6)
	--Valentinos Junk:
	      TweakDB:SetFlat("Items.ValentinosJunkItem1_inline0.value", 0.6)
          TweakDB:SetFlat("Items.ValentinosJunkItem2_inline0.value", 0.4)
          TweakDB:SetFlat("Items.ValentinosJunkItem3_inline0.value", 0.6)
	--6th Street Junk:
	      TweakDB:SetFlat("Items.SixthStreetJunkItem1_inline0.value", 0.1)
          TweakDB:SetFlat("Items.SixthStreetJunkItem2_inline0.value", 0.9)
          TweakDB:SetFlat("Items.SixthStreetJunkItem3_inline0.value", 1.0)
	--Animals Junk:
	      TweakDB:SetFlat("Items.AnimalsJunkItem1_inline0.value", 0.3)
          TweakDB:SetFlat("Items.AnimalsJunkItem2_inline0.value", 2.5)
          TweakDB:SetFlat("Items.AnimalsJunkItem3_inline0.value", 1.0)
	--Maelstrom Junk:
	      TweakDB:SetFlat("Items.MaelstromJunkItem1_inline0.value", 1.8)
          TweakDB:SetFlat("Items.MaelstromJunkItem2_inline0.value", 2.3)
          TweakDB:SetFlat("Items.MaelstromJunkItem3_inline0.value", 0.2)
	--Moxis Junk:
	      TweakDB:SetFlat("Items.MoxiesJunkItem1_inline0.value", 0.1)
          TweakDB:SetFlat("Items.MoxiesJunkItem2_inline0.value", 0.2)
          TweakDB:SetFlat("Items.MoxiesJunkItem3_inline0.value", 0.1)
	--Voodoo Boys Junk:
	      TweakDB:SetFlat("Items.VoodooBoysJunkItem1_inline0.value", 0.1)
          TweakDB:SetFlat("Items.VoodooBoysJunkItem2_inline0.value", 0.1)
          TweakDB:SetFlat("Items.VoodooBoysJunkItem3_inline0.value", 0.6)
	--Militech Junk:
	      TweakDB:SetFlat("Items.MilitechJunkItem1_inline0.value", 2.2)
          TweakDB:SetFlat("Items.MilitechJunkItem2_inline0.value", 0.2)
          TweakDB:SetFlat("Items.MilitechJunkItem3_inline0.value", 0.3)
	--Tiger Claws Junk:
	      TweakDB:SetFlat("Items.TygerClawsJunkItem1_inline0.value", 3.0)
          TweakDB:SetFlat("Items.TygerClawsJunkItem2_inline0.value", 0.5)
          TweakDB:SetFlat("Items.TygerClawsJunkItem3_inline0.value", 1.0)
	--Scavengers Junk:
	      TweakDB:SetFlat("Items.ScavengersJunkItem1_inline0.value", 0.6)
          TweakDB:SetFlat("Items.ScavengersJunkItem2_inline0.value", 2.3)
          TweakDB:SetFlat("Items.ScavengersJunkItem3_inline0.value", 1.4)
	--Wraiths Junk:
	      TweakDB:SetFlat("Items.WraithsJunkItem1_inline0.value", 3.5)
          TweakDB:SetFlat("Items.WraithsJunkItem2_inline0.value", 0.1)
          TweakDB:SetFlat("Items.WraithsJunkItem3_inline0.value", 0.7)

	--=================================================
	--WEIGHT ADDER - AMMO
	--=================================================
	      TweakDB:SetFlat("Ammo.HandgunAmmo_inline1.value", 0.1)
		  TweakDB:SetFlat("Ammo.RifleAmmo_inline1.value", 0.2)
		  TweakDB:SetFlat("Ammo.ShotgunAmmo_inline1.value", 0.5)
		  TweakDB:SetFlat("Ammo.SniperRifleAmmo_inline1.value", 0.3)
	
end

return WeightAdder:new()