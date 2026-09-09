local interaction = require("modules/classes/interaction")
local utils = require("modules/utils/utils")
local world = require("modules/utils/worldInteraction")
local resourceHelper = require("modules/utils/resourceHelper")
local Cron = require("modules/utils/Cron")
local sceneDirectorModule = require("modules/classes/interactions/jotaroSceneDirector")

local route = setmetatable({}, { __index = interaction })

local FACT = {
    state = "jjr_jotaro_joytoy_route_state",
    stage = "jjr_jotaro_joytoy_route_stage",
    complete = "jjr_jotaro_joytoy_route_complete",
    gigStart = "kab_07_start",
    gigDone = "kab_07_done",
    gigFinished = "kab_07_finished",
    gigFailed = "kab_07_failed",
    jotaroKilled = "kab_07_jotaro_killed",
    alerted = "kab_07_enemies_alerted",
    truce = "jjr_jotaro_truce_active",
    security = "jjr_jotaro_security_authorized",
    sceneSignal = "jjr_scene_start_signal",
    sceneID = "jjr_scene_id"
}

local PROMPT_SCENE = "mod\\jotaro_joytoy_route\\quest\\bartender_prompt.scene"
local PROMPT_END_EVENT = "nif_exit_teleport"
local SECURITY_NODE_REF = "#kab_07_security_system"
-- Consecutive onUpdate polls the alerted fact must stay set before we treat it as a real break.
local ALERT_DEBOUNCE_POLLS = 2

local POSES = {
    oral01 = {
        name = "oral01",
        playerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\oral\\ponc_synced_oral_01_b.workspot",
        partnerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\oral\\ponc_synced_oral_01_a.workspot",
        duration = 45.0
    },
    oral05 = {
        name = "oral05",
        playerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\oral\\ponc_synced_oral_05_b.workspot",
        partnerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\oral\\ponc_synced_oral_05_a.workspot",
        duration = 45.0
    },
    cowgirl02 = {
        name = "cowgirl02",
        playerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\cowgirl\\ponc_synced_cowgirl_02_b.workspot",
        partnerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\cowgirl\\ponc_synced_cowgirl_02_a.workspot",
        duration = 45.0
    },
    missionary = {
        name = "missionary01",
        partnerProfile = "jotaro",
        playerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\missionary\\ponc_synced_missionary_01_b.workspot",
        partnerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\missionary\\ponc_synced_missionary_01_a.workspot",
        duration = 45.0
    },
    cowgirl = {
        name = "cowgirl01",
        partnerProfile = "jotaro",
        playerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\cowgirl\\ponc_synced_cowgirl_01_b.workspot",
        partnerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\cowgirl\\ponc_synced_cowgirl_01_a.workspot",
        duration = 45.0
    },
    doggy = {
        name = "doggy01",
        playerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\doggy\\ponc_synced_doggy_01_b.workspot",
        partnerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\doggy\\ponc_synced_doggy_01_a.workspot",
        duration = 45.0
    }
}

local function log(message)
    -- print("[JoytoysMissionsAndGigs:Monsterhunt] " .. tostring(message))
end

local function quests()
    return Game.GetQuestsSystem()
end

local function getFact(name)
    local qs = quests()
    if not qs then return 0 end
    return qs:GetFactStr(name) or 0
end

local function setFact(name, value)
    local qs = quests()
    if qs then qs:SetFactStr(name, value) end
end

-- Reset the framework-shared NIF prompt facts. These are NOT namespaced per pack, so this
-- route can leave nif_skip_teleport / nif_scene_active set and suppress the first
-- interaction of a sibling gig route (e.g. A Lack of Empathy) played afterwards. Call this
-- when the gig ends so the next NIF route always starts from a clean shared state.
local function clearSharedNifState()
    setFact("nif_skip_teleport", 0)
    setFact("nif_scene_active", 0)
end

local function screenMessage(text, duration)
    local ok = pcall(function()
        local message = SimpleScreenMessage.new()
        message.message = text
        message.duration = duration or 5.0
        message.isShown = true
        local definitions = Game.GetAllBlackboardDefs().UI_Notifications
        local blackboard = Game.GetBlackboardSystem():Get(definitions)
        blackboard:SetVariant(definitions.OnscreenMessage, ToVariant(message), true)
    end)
    if not ok then log("Could not display route message: " .. tostring(text)) end
end

local function resolveTransform(nodeRef)
    if not nodeRef or nodeRef == "" then return nil end
    local ok, success, transform = pcall(function()
        local entityRef = CreateEntityReference(nodeRef, {})
        local globalRef = ResolveNodeRef(entityRef.reference, GlobalNodeID.GetRoot())
        local found, nodeTransform = Game.GetNodeTransform(globalRef)
        return found, nodeTransform
    end)
    if not ok or not success or not transform then return nil end
    return transform
end

local function queueSecurityEvent(event)
    if not event then return false end
    return pcall(function()
        local entityRef = CreateEntityReference(SECURITY_NODE_REF, {})
        local globalRef = ResolveNodeRef(entityRef.reference, GlobalNodeID.GetRoot())
        local entityID = entEntityID.new({ hash = globalRef.hash })
        local persistentID = PersistentID.ForComponent(entityID, CName.new("controller"))
        Game.GetPersistencySystem():QueuePSEvent(
            persistentID,
            CName.new("SecuritySystemControllerPS"),
            event
        )
    end)
end

local function authorizeHoOhSecurity(authorize)
    local authorizationOK = false
    local stateOK = false
    pcall(function()
        local event = AuthorizePlayerInSecuritySystem.new()
        event.authorize = authorize == true
        event.forceRemoveFromBlacklist = authorize == true
        authorizationOK = queueSecurityEvent(event)
    end)
    if authorize then
        pcall(function()
            local event = SetSecuritySystemState.new()
            event.state = ESecuritySystemState.SAFE
            stateOK = queueSecurityEvent(event)
        end)
    else
        stateOK = true
    end
    if authorizationOK then setFact(FACT.security, authorize and 1 or 0) end
    return authorizationOK and stateOK
end

local bridgeMissingLogged = false

local function getBridge()
    local ok, bridge = pcall(function()
        return Game.GetScriptableSystemsContainer():Get("JJR_RouteBridge")
    end)
    if not ok or not bridge then
        if not bridgeMissingLogged then
            bridgeMissingLogged = true
            log("JJR_RouteBridge is unavailable (redscript system not found); truce logic cannot run")
        end
        return nil
    end
    bridgeMissingLogged = false
    return bridge
end

function route:new(mod, project)
    local o = interaction.new(self, mod, project)
    o.interactionType = "Joytoys Missions and Gigs - Monsterhunt"
    o.modulePath = "interactions/jotaroJoytoyRoute"
    o.name = "Monsterhunt - Ho-Oh joytoy route"
    o.worldIcon = "ChoiceIcons.UseIcon"
    -- Hot-pink HDR tint so the route pins stand out from NIF's default blue icons.
    o.useWorldIconColor = true
    o.worldIconColor = { Red = 1.8, Green = 0.25, Blue = 1.35, Alpha = 1.0 }
    o.scene = PROMPT_SCENE
    o.skipFact = "nif_skip_teleport"
    o.endEvent = PROMPT_END_EVENT
    o.startFactID = 24
    -- Native Interactions Framework 1.1.2 only dispatches onUpdate to
    -- interactions that explicitly opt in.
    o.needsUpdate = true

    o.locStringIDOverride = "945077401258010624"
    o.upstairsOralLocStringID = "945077401258010625"
    o.bedroomSexLocStringID = "945077401258010626"
    o.bedroomDoggyLocStringID = "945077401258010627"
    o.bedroomCowgirlLocStringID = "945077401258010628"
    o.hallwayCowgirlLocStringID = "945077401258010629"
    o.upstairsOralChoiceUniqueID = 407240002
    o.bedroomSexChoiceUniqueID = 407240003
    o.bedroomDoggyChoiceUniqueID = 407240004
    o.bedroomCowgirlChoiceUniqueID = 407240005
    o.hallwayCowgirlChoiceUniqueID = 407240006

    o.promptNodeRef = "#wat_kab_food_04_tr_barman_at_position"
    o.bedroomRotationRef = "#kab_07_tr_jotaro_watching_001"
    o.fallbackBedroomRotationRef = "#kab_07_ws_jotaro_coach"
    o.entryScenePosition = { x = -1022.981, y = 1339.328, z = 5.291, w = 1.0 }
    o.upstairsOralPosition = { x = -1034.082, y = 1339.896, z = 9.291, w = 1.0 }
    o.hallwayCowgirlPosition = { x = -1029.723, y = 1330.183, z = 13.281, w = 1.0 }
    o.hallwayCowgirlPlayerPosition = { x = -1030.302, y = 1329.613, z = 13.281, w = 1.0 }
    o.bedroomSexPosition = { x = -1045.278, y = 1343.613, z = 13.378, w = 1.0 }
    o.bedroomCowgirlPosition = { x = -1045.233, y = 1343.808, z = 13.378, w = 1.0 }
    o.bedroomDoggyPosition = { x = -1045.267, y = 1343.662, z = 13.378, w = 1.0 }
    o.entrySceneRotation = { roll = 0.0, pitch = 0.0, yaw = 272.178 }
    o.hallwayCowgirlRotation = { roll = 0.0, pitch = 0.0, yaw = 177.961 }
    o.bedroomSexRotation = { roll = 0.0, pitch = 0.0, yaw = 257.037 }
    o.bedroomCowgirlRotation = { roll = 0.0, pitch = 0.0, yaw = 167.037 }
    o.bedroomDoggyRotation = { roll = 0.0, pitch = 0.0, yaw = 257.037 }
    o.entryYawOffset = 0.0
    o.upstairsOralYawOffset = 0.0
    o.hallwayCowgirlYawOffset = 0.0
    o.bedroomSexYawOffset = 0.0
    o.bedroomCowgirlYawOffset = 0.0
    o.bedroomDoggyYawOffset = 0.0
    o.stageInteractionRange = 2.5
    o.stageInteractionAngle = 120.0
    o.stageIconRange = 12.0

    o.promptResolved = false
    o.sceneDirector = sceneDirectorModule.get(log)
    o.pendingRole = nil
    o.activeRole = nil
    o.encounterStartedAt = 0.0
    o.lastPoll = 0.0
    o.directorLastUpdate = os.clock()
    o.securityLastUpdate = 0.0
    o.alertedStreak = 0
    o.stageInteractionIDs = {}

    setmetatable(o, { __index = self })
    return o
end

function route:getRole(roleName)
    if roleName == "bartender" then
        return {
            key = "bartender", availableStage = 0, runningStage = 1, nextStage = 2,
            locStringID = self.locStringIDOverride, choiceID = self.choiceUniqueID,
            position = self.entryScenePosition, rotationRef = self.promptNodeRef,
            rotation = self.entrySceneRotation,
            yawOffset = self.entryYawOffset, pose = POSES.oral01
        }
    elseif roleName == "upstairs_oral" then
        return {
            key = "upstairs_oral", availableStage = 2, runningStage = 3, nextStage = 4,
            locStringID = self.upstairsOralLocStringID, choiceID = self.upstairsOralChoiceUniqueID,
            position = self.upstairsOralPosition, rotationRef = self.bedroomRotationRef,
            yawOffset = self.upstairsOralYawOffset, pose = POSES.oral05
        }
    elseif roleName == "hallway_cowgirl" then
        return {
            key = "hallway_cowgirl", availableStage = 4, runningStage = 5, nextStage = 6,
            locStringID = self.hallwayCowgirlLocStringID, choiceID = self.hallwayCowgirlChoiceUniqueID,
            position = self.hallwayCowgirlPosition, rotationRef = self.bedroomRotationRef,
            playerPosition = self.hallwayCowgirlPlayerPosition,
            rotation = self.hallwayCowgirlRotation,
            yawOffset = self.hallwayCowgirlYawOffset, pose = POSES.cowgirl02
        }
    elseif roleName == "bedroom_sex" then
        return {
            key = "bedroom_sex", availableStage = 6, runningStage = 7, nextStage = 8,
            locStringID = self.bedroomSexLocStringID, choiceID = self.bedroomSexChoiceUniqueID,
            position = self.bedroomSexPosition, rotationRef = self.bedroomRotationRef,
            rotation = self.bedroomSexRotation,
            yawOffset = self.bedroomSexYawOffset, pose = POSES.missionary
        }
    elseif roleName == "bedroom_doggy" then
        return {
            key = "bedroom_doggy", availableStage = 10, runningStage = 11, nextStage = 12,
            locStringID = self.bedroomDoggyLocStringID, choiceID = self.bedroomDoggyChoiceUniqueID,
            position = self.bedroomDoggyPosition, rotationRef = self.bedroomRotationRef,
            rotation = self.bedroomDoggyRotation,
            yawOffset = self.bedroomDoggyYawOffset, pose = POSES.doggy
        }
    elseif roleName == "bedroom_cowgirl" then
        return {
            key = "bedroom_cowgirl", availableStage = 8, runningStage = 9, nextStage = 10,
            locStringID = self.bedroomCowgirlLocStringID, choiceID = self.bedroomCowgirlChoiceUniqueID,
            position = self.bedroomCowgirlPosition, rotationRef = self.bedroomRotationRef,
            rotation = self.bedroomCowgirlRotation,
            yawOffset = self.bedroomCowgirlYawOffset, pose = POSES.cowgirl
        }
    end
    return nil
end

function route:addStageInteraction(roleName)
    local roleData = self:getRole(roleName)
    if not roleData then return nil end
    local position = roleData.position
    local id = world.addInteraction(
        self.modulePath .. "/" .. roleName,
        Vector4.new(position.x, position.y, position.z, position.w or 1.0),
        self.stageInteractionRange,
        self.stageInteractionAngle,
        self.worldIcon,
        self.stageIconRange,
        self.useWorldIconColor and self.worldIconColor or nil,
        function(state)
            if state then self:startRolePrompt(roleName) else self:stopRolePrompt(roleName) end
        end
    )
    world.disableInteraction(id, true)
    self.stageInteractionIDs[roleName] = id
    return id
end

function route:load(data)
    interaction.load(self, data)
    self.stageInteractionIDs = {}
    self:addStageInteraction("upstairs_oral")
    self:addStageInteraction("hallway_cowgirl")
    self:addStageInteraction("bedroom_sex")
    self:addStageInteraction("bedroom_cowgirl")
    self:addStageInteraction("bedroom_doggy")
end

function route:remove()
    for _, id in pairs(self.stageInteractionIDs or {}) do world.removeInteraction(id) end
    self.stageInteractionIDs = {}
    interaction.remove(self)
end

local maintainCallCounter = 0

function route:callBridge(methodName)
    local bridge = getBridge()
    if not bridge then return false end
    if methodName == "BeginInfiltration" then
        log("callBridge: dispatching BeginInfiltration")
    elseif methodName == "MaintainInfiltration" then
        maintainCallCounter = maintainCallCounter + 1
        if maintainCallCounter % 10 == 1 then
            log("callBridge: dispatching MaintainInfiltration (call #" .. maintainCallCounter .. ")")
        end
    end
    local ok, result = pcall(function()
        if methodName == "CanStart" then return bridge:CanStart() end
        if methodName == "BeginInfiltration" then return bridge:BeginInfiltration() end
        if methodName == "MaintainInfiltration" then return bridge:MaintainInfiltration() end
        if methodName == "EndInfiltration" then return bridge:EndInfiltration() end
        return false
    end)
    if not ok then
        log("Bridge call failed: " .. tostring(methodName))
        return false
    end
    return result ~= false
end

function route:gigAllowsRoute()
    return getFact(FACT.gigStart) > 0
        and getFact(FACT.gigDone) == 0
        and getFact(FACT.gigFinished) == 0
        and getFact(FACT.gigFailed) == 0
        and getFact(FACT.jotaroKilled) == 0
        and getFact(FACT.alerted) == 0
end

-- Gig-ended conditions only; deliberately excludes the alerted fact, which is
-- debounced separately in onUpdate so a same-frame set/reset by the redscript
-- bridge doesn't tear down the truce before it can self-heal.
function route:gigTerminated()
    return getFact(FACT.gigStart) == 0
        or getFact(FACT.gigDone) > 0
        or getFact(FACT.gigFinished) > 0
        or getFact(FACT.gigFailed) > 0
        or getFact(FACT.jotaroKilled) > 0
end

function route:isRoleAvailable(roleName)
    local roleData = self:getRole(roleName)
    if not roleData then return false end
    if not self:gigAllowsRoute() or getFact(FACT.stage) ~= roleData.availableStage then return false end
    if roleName == "bartender" then
        local state = getFact(FACT.state)
        local available = state == 0 or (state == 3 and getFact(FACT.truce) > 0)
        return available
            and getFact(FACT.complete) == 0
            and self.promptResolved
            and self:callBridge("CanStart")
    end
    return getFact(FACT.state) == 3 and getFact(FACT.truce) > 0
end

function route:canStartRole(roleName)
    if self.sceneRunning or self.sceneDirector.status().phase ~= "idle" then return false end
    return self:isRoleAvailable(roleName)
end

function route:canOffer()
    -- Keep the marker alive while the private choice prompt is launching.
    -- Tying visibility to sceneRunning made worldInteraction emit callback(false)
    -- during the launch window, which repeatedly set the skip fact and caused
    -- the bartender option to flash on and off.
    return self:isRoleAvailable("bartender")
end

function route:getPromptPatch(roleData)
    local patch = { choiceID = roleData.choiceID }
    if roleData.locStringID and roleData.locStringID ~= "" then
        patch.locMap = {
            [6146] = CreateCRUID(loadstring("return " .. roleData.locStringID .. "ULL", "")())
        }
    end
    return patch
end

function route:getSceneAnchor(roleData)
    local sourceRotation = roleData.rotation
    if not sourceRotation then
        local transform = resolveTransform(roleData.rotationRef)
        if not transform and roleData.rotationRef ~= self.fallbackBedroomRotationRef then
            transform = resolveTransform(self.fallbackBedroomRotationRef)
        end
        if not transform then return nil end
        sourceRotation = transform:ToEulerAngles()
    end
    local playerPosition = roleData.playerPosition or roleData.position
    return {
        position = {
            x = roleData.position.x,
            y = roleData.position.y,
            z = roleData.position.z,
            w = roleData.position.w or 1.0
        },
        playerPosition = {
            x = playerPosition.x,
            y = playerPosition.y,
            z = playerPosition.z,
            w = playerPosition.w or 1.0
        },
        spawnPosition = {
            x = playerPosition.x,
            y = playerPosition.y,
            z = playerPosition.z,
            w = playerPosition.w or 1.0
        },
        rotation = {
            roll = sourceRotation.roll or 0.0,
            pitch = sourceRotation.pitch or 0.0,
            yaw = (sourceRotation.yaw or 0.0) + (roleData.yawOffset or 0.0)
        }
    }
end

function route:teleportToScene(anchor)
    local player = GetPlayer()
    if not player or not anchor then return false end
    local playerPosition = anchor.playerPosition or anchor.position
    return pcall(function()
        Game.GetTeleportationFacility():Teleport(
            player,
            Vector4.new(playerPosition.x, playerPosition.y, playerPosition.z, playerPosition.w or 1.0),
            EulerAngles.new(anchor.rotation.roll or 0.0, anchor.rotation.pitch or 0.0, anchor.rotation.yaw or 0.0)
        )
    end)
end

function route:triggerScene(sceneID)
    setFact(FACT.sceneID, sceneID)
    setFact(FACT.sceneSignal, 1)
end

function route:restoreAvailableRole(roleData, preserveTruce)
    self.pendingRole = nil
    self.activeRole = nil
    self.encounterStartedAt = 0.0
    setFact(FACT.stage, roleData.availableStage)
    if roleData.key == "bartender" then
        if preserveTruce and getFact(FACT.truce) > 0 and getFact(FACT.jotaroKilled) == 0 then
            setFact(FACT.state, 3)
            self:callBridge("MaintainInfiltration")
            authorizeHoOhSecurity(true)
            log("First encounter recovered at the bartender with the Jotaro truce intact")
        else
            setFact(FACT.state, 0)
            authorizeHoOhSecurity(false)
            self:callBridge("EndInfiltration")
        end
    else
        setFact(FACT.state, 3)
        self:callBridge("MaintainInfiltration")
        authorizeHoOhSecurity(true)
    end
end

function route:failStart(reason)
    log("Encounter did not start: " .. tostring(reason))
    self.sceneDirector.stop(tostring(reason), "failed")
    utils.removeSaveLock()
    setFact(FACT.sceneSignal, 0)
    setFact(FACT.sceneID, 0)
    setFact("nif_scene_active", 0)
    local roleData = self:getRole(self.activeRole or self.pendingRole or "bartender")
    self:restoreAvailableRole(roleData, true)
end

function route:beginEncounter(roleName, attempt)
    attempt = attempt or 1
    local roleData = self:getRole(roleName)
    if not roleData then return self:failStart("unknown route stage") end
    local player = GetPlayer()
    local tier = player and player:GetSceneTier() or 0
    local active = getFact("nif_scene_active")
    local pendingSignal = getFact(FACT.sceneSignal)
    local activeSceneID = getFact(FACT.sceneID)

    if active > 0 or tier >= 3 or pendingSignal > 0 or activeSceneID ~= 0 then
        if attempt <= 100 then
            Cron.After(0.20, function() self:beginEncounter(roleName, attempt + 1) end)
        else
            self:failStart(string.format(
                "interaction prompt did not release (active=%d, signal=%d, id=%d, tier=%d)",
                active, pendingSignal, activeSceneID, tier
            ))
        end
        return
    end

    local anchor = self:getSceneAnchor(roleData)
    if not anchor then return self:failStart("scene rotation node is not streamed") end
    local ready, detail = self.sceneDirector.preflight(anchor, roleData.pose)
    if not ready then return self:failStart(detail) end
    if not self:teleportToScene(anchor) then return self:failStart("direct scene relocation failed") end

    self.activeRole = roleName
    self.pendingRole = nil
    self.encounterStartedAt = os.clock()
    setFact(FACT.state, 2)
    utils.addSaveLock()
    log("V moved to " .. roleName .. "; starting pose " .. roleData.pose.name)
    Cron.After(0.65, function()
        if getFact(FACT.state) ~= 2 or self.activeRole ~= roleName then return end
        local started, startDetail = self.sceneDirector.start(anchor, roleData.pose)
        if not started then return self:failStart(startDetail) end
        log("Embedded Tyger Claw scene spawn requested for " .. roleName)
    end)
end

function route:completeStage(roleName)
    local roleData = self:getRole(roleName)
    if not roleData then return self:failStart("completed an unknown stage") end
    utils.removeSaveLock()
    self.activeRole = nil
    self.encounterStartedAt = 0.0
    setFact(FACT.stage, roleData.nextStage)
    setFact(FACT.state, 3)

    if roleName == "bartender" then
        screenMessage("Take your clothes off and head upstairs to the bar.", 6.0)
    elseif roleName == "upstairs_oral" then
        screenMessage("A Tyger Claw upstairs calls you over and demands you ride him on the couch.", 6.0)
    elseif roleName == "hallway_cowgirl" then
        screenMessage("Head to Jotaro's room. Maybe I can turn off the cameras on the way there.", 7.0)
    elseif roleName == "bedroom_sex" then
        screenMessage("Stay on the bed. Jotaro wants you on top.", 5.0)
    elseif roleName == "bedroom_cowgirl" then
        screenMessage("One more Tyger Claw is waiting nearby.", 5.0)
    elseif roleName == "bedroom_doggy" then
        setFact(FACT.complete, 1)
        screenMessage("I think they are bored of me for now. I just need to find the right time to kill Jotaro.", 9.0)
        log("All route scenes complete; the Ho-Oh truce stays active until Jotaro is killed")
    end
end

function route:startRolePrompt(roleName)
    if not self:canStartRole(roleName) then return end
    local roleData = self:getRole(roleName)
    self.sceneRunning = true
    self.pendingRole = roleName

    self.pendingStartTimer = Cron.AfterTicks(2, function()
        self.pendingStartTimer = nil
        if not self.sceneRunning or self.pendingRole ~= roleName then return end

        local success = resourceHelper.registerSceneEnd(PROMPT_END_EVENT, function(sceneActive)
            utils.removeSaveLock()
            self.sceneRunning = false
            if sceneActive == 1 then
                world.forceIcons()
                setFact(FACT.stage, roleData.runningStage)
                setFact(FACT.state, 1)
                log("Accepted interaction for " .. roleName .. "; waiting for dispatcher idle")
                Cron.After(0.25, function() self:beginEncounter(roleName, 1) end)
            else
                self:restoreAvailableRole(roleData)
            end
        end)
        if not success then
            self.sceneRunning = false
            self.pendingRole = nil
            return
        end

        -- NIF 1.1.2 serializes scene launches because every interaction shares
        -- nif_interaction_id. Joining its queue prevents prompt collisions.
        resourceHelper.requestSceneSignal(self, function()
            if not self.sceneRunning or self.pendingRole ~= roleName then
                resourceHelper.endEvents[PROMPT_END_EVENT] = nil
                return
            end

            if roleName == "bartender" then
                if not self:callBridge("BeginInfiltration") then
                    resourceHelper.endEvents[PROMPT_END_EVENT] = nil
                    self.sceneRunning = false
                    self.pendingRole = nil
                    log("Could not establish the temporary Tyger Claw truce")
                    return
                end
            else
                self:callBridge("MaintainInfiltration")
            end
            if not authorizeHoOhSecurity(true) then
                log("Ho-Oh security authorization request could not be queued")
            end

            Game.GetResourceDepot():RemoveResourceFromCache(PROMPT_SCENE)
            resourceHelper.registerPatch(PROMPT_SCENE, self:getPromptPatch(roleData))
            self:triggerScene(24)
            utils.addSaveLock()
        end)
    end)
end

function route:start()
    self:startRolePrompt("bartender")
end

function route:stopRolePrompt(roleName)
    if not self.sceneRunning or self.pendingRole ~= roleName then return end
    self.sceneRunning = false

    if resourceHelper.cancelSceneSignal(self) then
        resourceHelper.endEvents[PROMPT_END_EVENT] = nil
        self.pendingRole = nil
        return
    end

    if self.pendingStartTimer then
        Cron.Halt(self.pendingStartTimer)
        self.pendingStartTimer = nil
        self.pendingRole = nil
        return
    end

    setFact(self.skipFact, 1)
end

function route:stop()
    self:stopRolePrompt("bartender")
end

function route:sessionStart()
    self.sceneRunning = false
    self.promptResolved = false
    self.pendingRole = nil
    self.activeRole = nil
    self.encounterStartedAt = 0.0
    self.lastPoll = 0.0
    self.directorLastUpdate = os.clock()
    self.securityLastUpdate = 0.0
    self.alertedStreak = 0

    local state = getFact(FACT.state)
    local stage = getFact(FACT.stage)
    if state == 1 or state == 2 then
        self.sceneDirector.shutdown()
        utils.removeSaveLock()
        setFact(FACT.sceneSignal, 0)
        setFact(FACT.sceneID, 0)
        setFact("nif_scene_active", 0)
        if stage <= 1 then
            setFact(FACT.stage, 0)
            setFact(FACT.state, 0)
            if getFact(FACT.security) > 0 then authorizeHoOhSecurity(false) end
            self:callBridge("EndInfiltration")
        else
            setFact(FACT.stage, stage - 1)
            setFact(FACT.state, 3)
            self:callBridge("MaintainInfiltration")
            authorizeHoOhSecurity(true)
        end
        log("Recovered an interrupted route at the previous interaction marker")
    elseif state == 3 and getFact(FACT.jotaroKilled) == 0 then
        self:callBridge("MaintainInfiltration")
        authorizeHoOhSecurity(true)
    elseif state == 0 and getFact(FACT.truce) > 0 then
        self:callBridge("EndInfiltration")
        if getFact(FACT.security) > 0 then authorizeHoOhSecurity(false) end
    elseif state == 0 and getFact(FACT.security) > 0 then
        authorizeHoOhSecurity(false)
    end
end

function route:sessionEnd()
    self.sceneDirector.shutdown()
    self.promptResolved = false
    self.pendingRole = nil
    self.activeRole = nil
end

function route:updateStageInteractions(stage, state)
    self.lastInteractionEnabled = self.lastInteractionEnabled or {}
    for roleName, id in pairs(self.stageInteractionIDs or {}) do
        local roleData = self:getRole(roleName)
        local enabled = state == 3
            and stage == roleData.availableStage
            and self:gigAllowsRoute()
            and getFact(FACT.truce) > 0
        world.disableInteraction(id, not enabled)

        if enabled ~= self.lastInteractionEnabled[roleName] then
            self.lastInteractionEnabled[roleName] = enabled
            if not enabled then
                log(roleName .. " interaction disabled: state=" .. state ..
                    " stage=" .. stage .. "/" .. roleData.availableStage ..
                    " gigAllowsRoute=" .. tostring(self:gigAllowsRoute()) ..
                    " alerted=" .. getFact(FACT.alerted) ..
                    " truce=" .. getFact(FACT.truce))
            else
                log(roleName .. " interaction enabled")
            end
        end
    end
end

function route:onUpdate(_playerPosition)
    local now = os.clock()
    local directorDelta = math.max(0.0, now - (self.directorLastUpdate or now))
    self.directorLastUpdate = now
    self.sceneDirector.update(directorDelta)

    local result = self.sceneDirector.consumeResult()
    if result and getFact(FACT.state) == 2 then
        if result.outcome == "completed" then
            self:completeStage(self.activeRole)
        else
            self:failStart(result.reason)
        end
    end

    if now - self.lastPoll < 0.20 then return end
    self.lastPoll = now

    local promptTransform = resolveTransform(self.promptNodeRef)
    if promptTransform then
        local position = promptTransform:GetPosition()
        world.updateInteractionPosition(
            self.worldInteractionID,
            Vector4.new(position.x, position.y, position.z + 0.20, position.w or 1.0)
        )
        self.promptResolved = true
    else
        self.promptResolved = false
    end

    local state = getFact(FACT.state)
    local stage = getFact(FACT.stage)
    world.disableInteraction(self.worldInteractionID, not self:canOffer())
    self:updateStageInteractions(stage, state)

    -- Give the redscript bridge a chance to reconcile a transient alerted fact
    -- before we decide whether to tear the truce down below.
    if state ~= 0 then
        self:callBridge("MaintainInfiltration")
    end

    local alertedNow = getFact(FACT.alerted) > 0
    if alertedNow then
        self.alertedStreak = self.alertedStreak + 1
        log("Alerted fact still set after MaintainInfiltration; streak=" .. self.alertedStreak .. "/" .. ALERT_DEBOUNCE_POLLS)
    else
        if self.alertedStreak > 0 then
            log("Alerted fact cleared; truce holding")
        end
        self.alertedStreak = 0
    end

    if state ~= 0 and (self:gigTerminated() or self.alertedStreak >= ALERT_DEBOUNCE_POLLS) then
        if self:gigTerminated() then
            log("Route teardown: gig ended (done/finished/failed/jotaroKilled)")
        else
            log("Route teardown: alerted fact persisted for " .. self.alertedStreak .. " consecutive polls")
        end
        self.sceneDirector.shutdown()
        utils.removeSaveLock()
        self.pendingRole = nil
        self.activeRole = nil
        self.encounterStartedAt = 0.0
        self.alertedStreak = 0
        setFact(FACT.sceneSignal, 0)
        setFact(FACT.sceneID, 0)
        clearSharedNifState()
        setFact(FACT.state, 0)
        if getFact(FACT.security) > 0 then authorizeHoOhSecurity(false) end
        self:callBridge("EndInfiltration")
        log("Monsterhunt route and scene audio stopped because the gig ended, Jotaro died, or Ho-Oh was alerted")
        return
    end

    if state == 0 then
        if getFact(FACT.security) > 0 then authorizeHoOhSecurity(false) end
        return
    end

    if getFact(FACT.jotaroKilled) > 0 then
        if getFact(FACT.security) > 0 and authorizeHoOhSecurity(false) then
            log("Jotaro killed; Ho-Oh security authorization revoked")
        end
    elseif now - (self.securityLastUpdate or 0.0) >= 1.0 then
        self.securityLastUpdate = now
        authorizeHoOhSecurity(true)
    end

    if state == 2 then
        local status = self.sceneDirector.status()
        if status.phase == "idle" and now - self.encounterStartedAt > 5.0 then
            self:failStart("embedded scene director returned to idle without a completion result")
        end
    end
end

function route:save()
    local data = interaction.save(self)
    data.locStringIDOverride = self.locStringIDOverride
    data.upstairsOralLocStringID = self.upstairsOralLocStringID
    data.bedroomSexLocStringID = self.bedroomSexLocStringID
    data.bedroomDoggyLocStringID = self.bedroomDoggyLocStringID
    data.bedroomCowgirlLocStringID = self.bedroomCowgirlLocStringID
    data.hallwayCowgirlLocStringID = self.hallwayCowgirlLocStringID
    data.upstairsOralChoiceUniqueID = self.upstairsOralChoiceUniqueID
    data.bedroomSexChoiceUniqueID = self.bedroomSexChoiceUniqueID
    data.bedroomDoggyChoiceUniqueID = self.bedroomDoggyChoiceUniqueID
    data.bedroomCowgirlChoiceUniqueID = self.bedroomCowgirlChoiceUniqueID
    data.hallwayCowgirlChoiceUniqueID = self.hallwayCowgirlChoiceUniqueID
    data.promptNodeRef = self.promptNodeRef
    data.bedroomRotationRef = self.bedroomRotationRef
    data.fallbackBedroomRotationRef = self.fallbackBedroomRotationRef
    data.entryScenePosition = utils.deepcopy(self.entryScenePosition)
    data.upstairsOralPosition = utils.deepcopy(self.upstairsOralPosition)
    data.hallwayCowgirlPosition = utils.deepcopy(self.hallwayCowgirlPosition)
    data.hallwayCowgirlPlayerPosition = utils.deepcopy(self.hallwayCowgirlPlayerPosition)
    data.bedroomSexPosition = utils.deepcopy(self.bedroomSexPosition)
    data.bedroomCowgirlPosition = utils.deepcopy(self.bedroomCowgirlPosition)
    data.bedroomDoggyPosition = utils.deepcopy(self.bedroomDoggyPosition)
    data.entrySceneRotation = utils.deepcopy(self.entrySceneRotation)
    data.hallwayCowgirlRotation = utils.deepcopy(self.hallwayCowgirlRotation)
    data.bedroomSexRotation = utils.deepcopy(self.bedroomSexRotation)
    data.bedroomCowgirlRotation = utils.deepcopy(self.bedroomCowgirlRotation)
    data.bedroomDoggyRotation = utils.deepcopy(self.bedroomDoggyRotation)
    data.entryYawOffset = self.entryYawOffset
    data.upstairsOralYawOffset = self.upstairsOralYawOffset
    data.hallwayCowgirlYawOffset = self.hallwayCowgirlYawOffset
    data.bedroomSexYawOffset = self.bedroomSexYawOffset
    data.bedroomCowgirlYawOffset = self.bedroomCowgirlYawOffset
    data.bedroomDoggyYawOffset = self.bedroomDoggyYawOffset
    data.stageInteractionRange = self.stageInteractionRange
    data.stageInteractionAngle = self.stageInteractionAngle
    data.stageIconRange = self.stageIconRange
    return data
end

return route
