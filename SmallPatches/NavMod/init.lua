NavMod = { 
    isUIVisible = false, 
    UI = require("modules/ui/ui.lua"), 
    ns = nil,
    player = nil,
    curPos = nil,
    updateTimerTick = 0.25, -- in seconds
    elapsedDelta = 0,
    vehicleCheckTick = 5,
    vehicleCheckDelta = 0
}

function NavMod:new()
    registerForEvent("onInit", function ()
        NavMod.ns = Game.GetNavigationSystem()
        NavMod.player = Game.GetPlayer()
        NavMod.curPos = NavMod.player:GetWorldPosition()
        NavMod.updateTimerTick = 0.25 -- in seconds
        NavMod.elapsedDelta = 0
        NavMod.vehicleCheckTick = 5
        NavMod.vehicleCheckDelta = 0
        NavMod.UI.init(NavMod)

        function isInVehicle()
            return Game['GetMountedVehicle;GameObject'](NavMod.player)
        end

        print("NavMod initialized!")
    end)

    registerForEvent("onUpdate", function (timeDelta)
        NavMod.elapsedDelta = NavMod.elapsedDelta + timeDelta
        NavMod.vehicleCheckDelta = NavMod.vehicleCheckDelta + timeDelta

        if NavMod.elapsedDelta >= NavMod.updateTimerTick then
            NavMod.curPos = player:GetWorldPosition()
            -- print(vecToString(curPos))
            NavMod.elapsedDelta = 0
        end

        if NavMod.vehicleCheckDelta >= NavMod.vehicleCheckTick then
            -- veh = isInVehicle()
            NavMod.vehicleCheckDelta = 0
        end

    end)

    -- registerForEvent("onDraw", function ()
        
    --     if ImGui.Begin("NavMod") then
    --         ImGui.SetWindowSize(400, 50)
    --         if ImGui.SmallButton("To Clipboard") then
    --             ImGui.SetClipboardText(vecToString(curPos))
    --         end
    --         ImGui.SameLine()
    --         ImGui.Text(vecToString(curPos))
    --         ImGui.End()
    --     end
    -- end)


    registerForEvent("onDraw", function()
        if (NavMod.isUIVisible) then
            NavMod.ns = Game.GetNavigationSystem()
            NavMod.player = Game.GetPlayer()
            NavMod.curPos = NavMod.player:GetWorldPosition()
            NavMod.UI.draw(NavMod.curPos)
        end
    end)

    registerForEvent("onOverlayOpen", function()
        NavMod.isUIVisible = true
    end)
    
    registerForEvent("onOverlayClose", function()
        NavMod.isUIVisible = false
    end)

    return NavMod
end


return NavMod:new()