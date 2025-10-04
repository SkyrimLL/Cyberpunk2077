require("log")
require("utils")

local GameSession = require("GameSession") 

local FLAG_PATH = "mod/data/Permadeath.flag"  
local SAVES_PATH = "mod/data/Saves.flag"   
 
flagApplied = false
flagOnInit = false

function markSavesCount(savesCount)
    local f = io.open(SAVES_PATH, "w")
    if f then
        f:write(savesCount)
        f:close()
        print("[Permadeath] savesCount written.")
    end
end

function markPermadeath()
    local f = io.open(FLAG_PATH, "w")
    if f then
        f:write("1")
        f:close()
        print("[Permadeath] Flag written.")
    end
end

function clearPermadeath()
    local f = io.open(FLAG_PATH, "w")
    if f then
        f:write("0")
        f:close()
        print("[Permadeath] Flag written.")
    end
end

function readPermadeath()
    local f = io.open(FLAG_PATH, "r")
    if f then
        local content = f:read("*a")
        f:close()
        if content and content:match("1") then
            print("[Permadeath] Global death flag detected.")
            return true
        end
    end
    print("[Permadeath] Global death flag missing.")
    return false
end

function applyPermadeath() 
    -- print("[Permadeath] applyPermadeath: ") 
    Game.GetStatusEffectSystem():ApplyStatusEffect(Game.GetPlayer():GetEntityID(), "BaseStatusEffect.Electrocuted")
    Game.GetStatusEffectSystem():ApplyStatusEffect(Game.GetPlayer():GetEntityID(), "BaseStatusEffect.ForceKill")
end

registerForEvent("onInit", function()
    print("[Permadeath] Loaded.")  
    flagApplied = false

    -- Check for other saves to clear the flag automatically
    if Game and Game.GetQuestsSystem then
        local qs = Game.GetQuestsSystem()
        local savesCount = qs:GetFactStr("SavedGamesCount")
        print("[Permadeath] onInit: number of saves detected - " .. tostring(savesCount))

        if  savesCount <= 1 then
            print("[Permadeath] onInit: saves folder clean - reset permadeath")
            qs:SetFactStr("PermadeathTriggered", 0)
            qs:SetFactStr("MarkPermadeath", 0)
            clearPermadeath()
        end 
    end

    if readPermadeath() then       
        print("[Permadeath] onInit: Global death flag found. Setting fact.")  
        flagOnInit = true 
    else
        print("[Permadeath] onInit: Global death flag not found or not set.") 
    end
 
end)

registerForEvent("onUpdate", function(deltaTime)   
    local isPreGame = IsPreGame()
    -- log("[Permadeath] onUpdate: is pre game :" .. tostring(isPreGame))
    -- print(".")
    -- if Game == nil or Game.GetPlayer == nil then return end
    -- local player = Game.GetPlayer()
    -- if player == nil then return end

    if (not IsPreGame()) then  
        local qs = Game.GetQuestsSystem()
        if not flagApplied and  flagOnInit then
            print("[Permadeath] onUpdate: Detected Permadeath flag on init.")
            markPermadeath()
            qs:SetFactStr("PermadeathTriggered", 1) 
            -- Game.GetPlayer():SetWarningMessage("::Relic Malfunction::Corrupted Memory::") 
            flagApplied = true
            qs:SetFactStr("MarkPermadeath", 0) -- reset
        end

        if not flagApplied and  qs:GetFactStr("MarkPermadeath") == 1 then
            print("[Permadeath] onUpdate: Detected MarkPermadeath signal from Redscript.")
            markPermadeath()
            qs:SetFactStr("PermadeathTriggered", 1) 
            -- Game.GetPlayer():SetWarningMessage("::Relic Malfunction::Corrupted Memory::")
            flagApplied = true
            qs:SetFactStr("MarkPermadeath", 0) -- reset
        end

        if not flagApplied and qs:GetFactStr("CheckPermadeath") == 1 then
            print("[Permadeath] onUpdate: Detected CheckPermadeath signal from Redscript.")
            if readPermadeath() then
                qs:SetFactStr("PermadeathTriggered", 1) 
                -- Game.GetPlayer():SetWarningMessage("::Relic Malfunction::Corrupted Memory::")
                flagApplied = true
                print("[Permadeath] Permadeath flag set for this game.")
            end
            qs:SetFactStr("CheckPermadeath", 0) -- reset
        end

        if qs:GetFactStr("CheckSavedGamesCount") == 1 then
            print("[Permadeath] onUpdate: Detected CheckSavedGamesCount signal from Redscript.")
            markSavesCount(qs:GetFactStr("SavedGamesCount"))
            print("[Permadeath] Record number of saves.")
            qs:SetFactStr("CheckSavedGamesCount", 0) -- reset
        end

        if flagApplied then 
            applyPermadeath()
        end

    end
end)

registerHotkey("ResetPermadeath", "Reset perma-death flag", function()
    os.remove(FLAG_PATH)
    if Game and Game.GetQuestsSystem then
        local qs = Game.GetQuestsSystem()
        qs:SetFactStr("PermadeathTriggered", 0)
        qs:SetFactStr("MarkPermadeath", 0)
        clearPermadeath()
    end
    print("[Permadeath] All cleared.")
end)
 