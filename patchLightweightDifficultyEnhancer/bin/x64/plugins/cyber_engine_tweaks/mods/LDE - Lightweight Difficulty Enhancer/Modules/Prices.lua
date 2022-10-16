Prices = {
	description = "Prices Multiplier Adjuster"
}

function Prices:new()
	
	--=================================================
	--PRICES - RESPEC
	--=================================================
		  TweakDB:SetFlat("Price.RespecBase.value", 10000) --Vanilla 2000
		  TweakDB:SetFlat("Price.RespecSinglePerk.value", 2000) --Vanilla 200

	--=================================================
	--PRICES - VENDORS BUY/SELL MULTIPLIERS
	--=================================================
	      --Buy Main:          
	      TweakDB:SetFlat("Price.BuyMultiplier.value", 1.5) --Vanilla 1.0
	      --Buy Additional:   
	      TweakDB:SetFlat("Price.CraftingMaterial.value", 6.0) --Vanilla 4.0
		  TweakDB:SetFlat("Price.Cyberware.value", 1600.0) --Vanilla 800.0
		  TweakDB:SetFlat("Price.RangedWeapon.value", 900.0) --Vanilla 700.0
		  TweakDB:SetFlat("Price.MeleeWeapon.value", 830.0) --Vanilla 550.0
		  TweakDB:SetFlat("Price.Clothing.value", 240.0) --Vanilla 120.0
	      TweakDB:SetFlat("Price.Scope.value", 300.0) --Vanilla 150.0
		  TweakDB:SetFlat("Price.SniperScope.value", 10.0) --Vanilla 5.0
		  TweakDB:SetFlat("Price.LongScope.value", 4.0) --Vanilla 2.0
		  TweakDB:SetFlat("Price.ShortScope.value", 2.0) --Vanilla 1.0
		  TweakDB:SetFlat("Price.Muzzle.value", 200.0) --Vanilla 100.0
	      TweakDB:SetFlat("Price.WeaponMod.value", 500.0) --Vanilla 250.0
		  TweakDB:SetFlat("Price.MeleeWeaponMod.value", 2.4) --Vanilla 1.2
		  TweakDB:SetFlat("Price.Grenade.value", 100.0) --Vanilla 8.2
		  TweakDB:SetFlat("Price.Injector.value", 60.0) --Vanilla 30.0
		  TweakDB:SetFlat("Price.Inhaler.value", 60.0) --Vanilla 30.0		  
		  TweakDB:SetFlat("Price.LongLastingConsumable.value", 600.0) --Vanilla 300.0
		  TweakDB:SetFlat("Price.Ammo.value", 6.0) --Vanilla 2.0	

	      --Sell Main: 
	      TweakDB:SetFlat("Price.SellMultiplier.value", 0.2) --Vanilla 0.1
	      --Sell Additional: 
	      TweakDB:SetFlat("Price.WeaponSellMultiplier.value", 0.41) --Vanilla 0.31
	      TweakDB:SetFlat("Price.CyberwareSellMultiplier.value", 0.4) --Vanilla 0.2
	
end

return Prices:new()