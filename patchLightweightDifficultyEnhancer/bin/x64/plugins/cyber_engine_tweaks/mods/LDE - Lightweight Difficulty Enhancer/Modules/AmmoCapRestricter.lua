AmmoCapRestricter = {
	description = "Lowers Maximum Ammo Capacity"
}

function AmmoCapRestricter:new()
	
		 if TweakDB:GetFlat("Ammo.AmmoWasResized") ~= true then 
			TweakDB:SetFlat("Ammo.AmmoWasResized", true)
			TweakDB:SetFlat("Ammo.HandgunAmmo_inline0.value", TweakDB:GetFlat("Ammo.HandgunAmmo_inline0.value") - 428)
			TweakDB:SetFlat("Ammo.RifleAmmo_inline0.value",  TweakDB:GetFlat("Ammo.RifleAmmo_inline0.value") - 460)
			TweakDB:SetFlat("Ammo.ShotgunAmmo_inline0.value",  TweakDB:GetFlat("Ammo.ShotgunAmmo_inline0.value") - 64)
			TweakDB:SetFlat("Ammo.SniperRifleAmmo_inline0.value",  TweakDB:GetFlat("Ammo.SniperRifleAmmo_inline0.value") - 76)
		end
	
end

return AmmoCapRestricter:new()