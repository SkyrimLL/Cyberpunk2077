-------------------------------------------------------------------------------------------------------------------------------
-- This mod was created by keanuWheeze from CP2077 Modding Tools Discord.
--
-- You are free to use this mod as long as you follow the following license guidelines:
--    * It may not be uploaded to any other site without my express permission.
--    * Using any code contained herein in another mod requires credits / asking me.
--    * You may not fork this code and make your own competing version of this mod available for download without my permission.
-------------------------------------------------------------------------------------------------------------------------------

local GameUI = require("modules/utils/GameUI")

freefly = {
    runtimeData = {
        inMenu = false,
        inGame = false,
        cetOpen = false,
        active = false
    },
    settings = {},
    defaultSettings = {
		speed = 2,
		speedIncrementStep = 0.2,
		angle = 0,
		noWeapon = true,
        timeStop = false,
        noController = false,
        lockVertical = false
    },
    config = require("modules/utils/config"),
    ui = require("modules/ui/generalSettingsUI"),
    logic = require("modules/utils/logic"),
    nUI = require("modules/ui/settingsUI")
}

function freefly:new()
    registerForEvent("onInit", function()
        self.config.tryCreateConfig("config/config.json", self.defaultSettings)
        self.config.backwardComp("config/config.json", self.defaultSettings)
        self.settings = self.config.loadFile("config/config.json")
        self.settings.speed = math.max(self.settings.speed, 0.001)

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu) -- Setup observer and GameUI to detect inGame / inMenu
            self.runtimeData.inMenu = isInMenu
            -- Safeguard: If entering menu while flying, force deactivation
            if isInMenu and self.runtimeData.active then
                print("[FreeFly] DEBUG: Menu opened while flying - DEACTIVATING flight")
                self.runtimeData.active = false
                self.logic.toggleFlight(self, false)
            end
        end)

        GameUI.OnSessionStart(function()
            self.runtimeData.inGame = true
            self.logic.registerInput(GetPlayer())
            print("[FreeFly] DEBUG: Session started - game active")
        end)

        GameUI.OnSessionEnd(function()
            self.runtimeData.inGame = false
            -- CRITICAL: Force cleanup of flight effects when session ends
            -- Prevents NoCombat from being stuck if player was flying during transition
            if self.runtimeData.active then
                print("[FreeFly] DEBUG: Session ended - FORCING cleanup (was active)")
                self.runtimeData.active = false
                self.logic.forceCleanupFlightEffects()
            else
                print("[FreeFly] DEBUG: Session ended (flight was not active)")
            end
        end)

        self.runtimeData.inGame = not GameUI.IsDetached() -- Required to check if ingame after reloading all mods
        self.logic.registerObservers(self)

        Override("ZoomEventsTransition", "OnEnter", function (_, context, interface, wrapped)
            if self.runtimeData.active then return end
            wrapped(context, interface)
        end)

        self.nUI.setupNative(self)
    end)

    registerForEvent("onUpdate", function(deltaTime)
        if not self.runtimeData.inMenu and self.runtimeData.inGame and self.runtimeData.active then
            self.logic.fly(self, deltaTime)
        end
        self.logic.time = self.logic.time + deltaTime
        
        -- Periodic validation: Every 0.5 seconds, verify flight state consistency
        if self.logic.time - self.logic.lastStatusCheck > 0.5 then
            self.logic.lastStatusCheck = self.logic.time
            
            -- If flight is marked active but we're in menu/not in game, force deactivation
            if self.runtimeData.active and (self.runtimeData.inMenu or not self.runtimeData.inGame) then
                print("[FreeFly] DEBUG: State mismatch detected - active=true but inMenu=" .. tostring(self.runtimeData.inMenu) .. " inGame=" .. tostring(self.runtimeData.inGame) .. " - FORCING cleanup")
                self.runtimeData.active = false
                self.logic.forceCleanupFlightEffects()
            end
        end
    end)

    registerForEvent("onDraw", function()
        if not self.runtimeData.cetOpen then return end
        self.ui.draw(self)
    end)

    registerForEvent("onOverlayOpen", function()
        self.runtimeData.cetOpen = true
    end)

    registerForEvent("onOverlayClose", function()
        self.runtimeData.cetOpen = false
    end)

    registerForEvent("onShutdown", function()
        -- Always clean up status effects, regardless of flight state
        -- This ensures they are removed even if mod crashes, is reloaded, or game closes unexpectedly
        miscUtil.removeStatus("GameplayRestriction.NoMovement")
        miscUtil.removeStatus("GameplayRestriction.NoZooming")
        miscUtil.removeStatus("GameplayRestriction.NoCombat")
    end)

    registerInput("freeFlySwitch", "Invert turning angle", function(down)
        if down then
            self.settings.angle = - self.settings.angle
            self.config.saveFile("config/config.json", self.settings)
        end
    end)

    registerInput("freeflyActivationIn", "Activation Key", function(down)
        if down and not self.runtimeData.active then
            print("[FreeFly] DEBUG: Input detected - ACTIVATING flight")
            self.runtimeData.active = true
            self.logic.toggleFlight(self, self.runtimeData.active)
        elseif down and self.runtimeData.active then
            print("[FreeFly] DEBUG: Input detected - DEACTIVATING flight")
            self.runtimeData.active = false
            self.logic.toggleFlight(self, self.runtimeData.active)
            -- Extra safeguard: Ensure NoCombat is removed when toggling off
            print("[FreeFly] DEBUG: Running extra safeguard cleanup after deactivation")
            self.logic.forceCleanupFlightEffects()
        end
    end)

    return self
end

return freefly:new()