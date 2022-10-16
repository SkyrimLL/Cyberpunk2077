LDE = { 
    description = "Temp"
}

function LDE:new()
		
    registerForEvent("onInit", function() 
	
	dofile("Modules/AmmoCapRestricter.lua")
	print("LDE - AmmoCapRestricter module loaded")

	dofile("Modules/Prices.lua")
	print("LDE - Prices module loaded")
	
	dofile("Modules/BaseStats.lua")
	print("LDE - Base Stats module loaded")

	dofile("Modules/WeightsAdder.lua")
	print("LDE - WeightsAdder module loaded")	
	
	print("Lightweight Difficulty Enhancer fully loaded!")

    end)
end

return LDE:new()