local interaction = require("modules/classes/interaction")
local utils = require("modules/utils/utils")
local world = require("modules/utils/worldInteraction")
local resourceHelper = require("modules/utils/resourceHelper")
local Cron = require("modules/utils/Cron")
local sceneDirectorModule = require("modules/classes/interactions/playingForKeepsSceneDirector")

local route = setmetatable({}, { __index = interaction })

local FACT = {
    state = "pfk_joytoy_route_state",
    complete = "pfk_joytoy_route_complete",
    revision = "pfk_joytoy_route_revision",
    gigStart = "lch_05_start",
    gigFinished = "lch_05_finished",
    alarm = "lch_05_alarm",
    combat = "lch_05_combat_started",
    haveEye = "lch_05_have_eye",
    reginaTipAcknowledged = "pfk_regina_tip_acknowledged",
    truce = "pfk_tyger_truce_active",
    security = "pfk_security_authorized",
    areaTypesCaptured = "pfk_area_types_captured",
    areasDisabled = "pfk_back_room_areas_disabled",
    storageDoorUnlocked = "pfk_storage_door_unlocked",
    sceneSignal = "pfk_scene_start_signal",
    sceneID = "pfk_scene_id"
}

-- Route state machine (FACT.state):
--   0  idle                       marker at the bar
--   1  transition scene playing    a native-interactions prompt is launching
--   2  a pose is running           sequenceIndex says which
--   4  awaiting a NIF trigger      self.awaitingKind = "oral5" | "group"
--   3  sequence complete           afterglow until the gig ends, then despawn
local ROUTE_REVISION = 11
local PROMPT_SCENE = "mod\\playing_for_keeps_joytoy_route\\quest\\client_prompt.scene"
local PROMPT_END_EVENT = "pfk_prompt_exit"
local SECURITY_NODE_REF = "#lch_05_security_system"
local STORAGE_DOOR_REF = "#lch_05_dvc_door_storage"

-- Production duration shared by all six synchronized scenes.
local PRODUCTION_SCENE_DURATION = 45.0
-- Never replace one dialogue card with another before it has had four seconds
-- onscreen. Group transitions contain a spoken line followed by a direction,
-- so they reserve one hold interval for each before launching the next pose.
local DIALOGUE_HOLD_SECONDS = 4.0
local LONG_DIALOGUE_HOLD_SECONDS = 8.0
local LONG_DIALOGUE_MIN_CHARACTERS = 65

-- Back-room native-interactions marker used for both the oral-5 trigger and the
-- group-encounter trigger. Defaults to the office node so V has to walk to the
-- back from the bar; tune CONTINUE_MARKER_OFFSET / the JSON overrides in-game.
local CONTINUE_NODE_REF = "#lch_05_tr_office"
local CONTINUE_MARKER_OFFSET = { x = 0.0, y = 0.0, z = 0.20 }

local WORKSPOT_ROOT = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\"

-- Ordered poses. Index 1 (oral05, Keisuke) is its own back-room interaction.
-- Indices 2..6 make up the single group-encounter interaction and auto-chain.
-- V is in B for every pose except Oral 02, which reverses so V is in A.
-- "activeMember" names the watching stand-in that becomes this pose's partner
-- (removed from the standing pool for that pose); Keisuke is not a stand-in.
-- "transition" is the dialogue shown after the pose completes.
local SEQUENCE = {
    {
        index = 1,
        name = "oral05",
        partnerProfile = "keisuke",
        activeMember = "keisuke",
        playerWorkspot = WORKSPOT_ROOT .. "oral\\ponc_synced_oral_05_b.workspot",
        partnerWorkspot = WORKSPOT_ROOT .. "oral\\ponc_synced_oral_05_a.workspot",
        duration = PRODUCTION_SCENE_DURATION,
        intro = "Keisuke: So the little slut from the net actually showed. Let's see if you're worth the trouble.",
        playerLine = "Mmph... mmh...",
        dialogue = {
            "Keisuke: So the little slut from the net actually showed. Let's see if you're worth the trouble.",
            "V: Tell me what you want me to do.",
            "V: Mmph... mmh...",
            "Keisuke: That's better. Maybe KabukiRose wasn't all talk."
        },
        transition = {
            line = "Keisuke: We didn't invite you here just to suck my dick. Take your clothes off.\nFemale Tyger: You heard him, slut. Clothes off. Then get down here and show me what you're good for.",
            trigger = "[Joytoy] Fuck the group."
        }
    },
    {
        index = 2,
        name = "oral02",
        partnerProfile = "tyger_kunoichi",
        activeMember = "female",
        -- Reversed assignment: V performs, so V takes the A workspot.
        playerWorkspot = WORKSPOT_ROOT .. "oral\\ponc_synced_oral_02_a.workspot",
        partnerWorkspot = WORKSPOT_ROOT .. "oral\\ponc_synced_oral_02_b.workspot",
        duration = PRODUCTION_SCENE_DURATION,
        intro = "Female Tyger: Don't keep me waiting, slut. Make me come and maybe the boys will let you stay.",
        playerLine = "Mmph...",
        dialogue = {
            "Female Tyger: Don't keep me waiting, slut. Make me cum and maybe the boys will let you stay.",
            "V: Mmph...",
            "Female Tyger: Eager little slut, aren't you?",
            "Ogawa: She follows orders well enough. Send her over."
        },
        transition = {
            line = "Ogawa: Not completely useless. My turn, slut.",
            trigger = "[Joytoy] Take care of Ogawa."
        }
    },
    {
        index = 3,
        name = "missionary07",
        partnerProfile = "tyger_gangster_2",
        activeMember = "ogawa",
        playerWorkspot = WORKSPOT_ROOT .. "missionary\\ponc_synced_missionary_07_b.workspot",
        partnerWorkspot = WORKSPOT_ROOT .. "missionary\\ponc_synced_missionary_07_a.workspot",
        duration = PRODUCTION_SCENE_DURATION,
        intro = "Ogawa: Over here. Let's see if you're as good with the rest of your body.",
        playerLine = "F-fuck...",
        dialogue = {
            "Ogawa: Over here. Let's see if you're as good with the rest of your body.",
            "Female Tyger: Don't wear the slut out yet. She's got more work to do.",
            "V: F-fuck...",
            "Ogawa: You really did come here ready for anything.",
            "V: U-use me... however you want...",
            "Female Tyger: Listen to her. KabukiRose loves an audience."
        },
        transition = {
            line = "Other Tyger: Enough, Ogawa. Send the slut over here.",
            trigger = "[Joytoy] Show the other Tyger a good time."
        }
    },
    {
        index = 4,
        name = "doggy07",
        partnerProfile = "tyger_gangster_1",
        activeMember = "male",
        playerWorkspot = WORKSPOT_ROOT .. "doggy\\ponc_synced_doggy_07_b.workspot",
        partnerWorkspot = WORKSPOT_ROOT .. "doggy\\ponc_synced_doggy_07_a.workspot",
        duration = PRODUCTION_SCENE_DURATION,
        intro = "Standard male Tyger: Turn around. I want to see how well KabukiRose follows orders.",
        playerLine = "Y-yes... please keep fucking me...",
        dialogue = {
            "Standard male Tyger: Turn around. I want to see how well KabukiRose follows orders.",
            "V: Y-yes... sir...",
            "Standard male Tyger: Tell everyone how much you are enjoying this.",
            "V: Y-yes... please keep fucking me...",
            "Standard male Tyger: That's right, slut. Give everyone a good view.",
            "Ogawa: Don't get comfortable. You're coming back to me."
        },
        transition = {
            line = "Ogawa: Get back over here, slut. I'm not finished with you yet.",
            trigger = "[Joytoy] Go back to Ogawa."
        }
    },
    {
        index = 5,
        name = "doggy04",
        partnerProfile = "tyger_gangster_2",
        activeMember = "ogawa",
        playerWorkspot = WORKSPOT_ROOT .. "doggy\\ponc_synced_doggy_04_b.workspot",
        partnerWorkspot = WORKSPOT_ROOT .. "doggy\\ponc_synced_doggy_04_a.workspot",
        duration = PRODUCTION_SCENE_DURATION,
        intro = "Ogawa: That's it. Do what you're told and this stays easy.",
        playerLine = "Harder... please...",
        dialogue = {
            "Ogawa: That's it. Do what you're told and this stays easy.",
            "Female Tyger: Look at her pretending she isn't enjoying the attention.",
            "V: Harder... please...",
            "Ogawa: Greedy slut. One round was never going to be enough for you.",
            "V: N-not when there's... so many of you... waiting to use me..."
        },
        transition = {
            line = "Standard male Tyger: Come back here, I am not done with you yet slut..",
            trigger = "[Joytoy] Finish with the other Tyger."
        }
    },
    {
        index = 6,
        name = "cowgirl05",
        partnerProfile = "tyger_gangster_1",
        activeMember = "male",
        playerWorkspot = WORKSPOT_ROOT .. "cowgirl\\ponc_synced_cowgirl_05_b.workspot",
        partnerWorkspot = WORKSPOT_ROOT .. "cowgirl\\ponc_synced_cowgirl_05_a.workspot",
        duration = PRODUCTION_SCENE_DURATION,
        intro = "Standard male Tyger: On top. Show us you know how to ride a cock.",
        playerLine = "F-fuck...your cock feels so good",
        dialogue = {
            "Standard male Tyger: On top. Show us you know how to ride a cock.",
            "V: F-fuck...your cock feels so good"
        },
        transition = {
            line = "Keisuke: Good work, slut. Keycard's on the table. Your clothes are in the storeroom—get changed, then get out."
        }
    }
}
local FIRST_GROUP_INDEX = 2
local FINAL_SCENE_INDEX = #SEQUENCE

local function sceneIntro(index)
    local scene = SEQUENCE[index]
    if not scene then return nil end
    if scene.intro and scene.playerLine then
        return scene.intro .. "\nV: " .. scene.playerLine
    end
    return scene.intro or (scene.playerLine and ("V: " .. scene.playerLine)) or nil
end

-- Route-owned nude stand-ins that make up the watching group. Spawned in the
-- back after V's arrival; each is despawned only while it is the active pose's
-- partner (the scene director spawns its own matching clone), then respawned.
-- Fully removed on gig completion / route invalidation.
local GUEST_SOURCE_RECORD = "Character.jpn_tyger_claws_biker1_melee1_fists_ma"
local GUEST_TAG = "PFKStoreroomGuest"
local ROUTE_TAG = "PlayingForKeepsJoytoyRoute"
local GROUP_MEMBERS = {
    female = {
        record = "Character.PFK_StoreroomKunoichi",
        template = "mod\\arman3_lizzies_bds\\characters\\entities\\gang__tyger_wa.ent",
        appearance = "gang__tyger_wa_kunoichi__lvl3_01_naked",
        offset = { x = 1.720, y = -0.400, z = 0.0 },
        yaw = 101.0
    },
    ogawa = {
        record = "Character.PFK_StoreroomOgawaEquivalent",
        template = "mod\\arman3_lizzies_bds\\characters\\entities\\gang__tyger_ma.ent",
        appearance = "gang__tyger_ma_gangster__lvl2_03_naked",
        offset = { x = -1.415, y = -2.605, z = 0.0 },
        yaw = -34.0
    },
    male = {
        record = "Character.PFK_StoreroomTygerMale",
        template = "mod\\arman3_lizzies_bds\\characters\\entities\\gang__tyger_ma.ent",
        appearance = "gang__tyger_ma_gangster__lvl1_03_naked",
        offset = { x = 1.356, y = 0.855, z = 0.0 },
        yaw = 146.0
    }
}
-- Clothed originals hidden while the route-owned nude stand-ins are staged.
local HIDE_ORIGINAL_APPEARANCES = {
    ["gang__tyger_wa_kunoichi__lvl3_01"] = true,
    ["gang__tyger_ma_gangster__lvl2_03"] = true,
    ["gang__tyger_ma_gangster__lvl1_03"] = true
}
-- AMM showed the existing back-room woman as record 0x8C793E69, length 42.
-- Matching the record as well as the appearance means she is still found if
-- another appearance mod changes what she is wearing before this route starts.
local HIDE_ORIGINAL_RECORDS = {
    ["0x8c793e69,42"] = true
}
local DISPOSE_ORIGINAL_APPEARANCES = {
    ["gang__tyger_wa_kunoichi__lvl3_01"] = true
}

local SECURITY_AREAS = {
    { nodeRef = "#lch_05_restricted_area_002", previousFact = "pfk_previous_area_type_002" },
    { nodeRef = "#lch_05_restricted_area_003", previousFact = "pfk_previous_area_type_003" },
    { nodeRef = "#lch_05_dangerous_area", previousFact = "pfk_previous_area_type_dangerous" }
}

local function log(message)
    print("[JoytoysMissionsAndGigs:PlayingForKeeps] " .. tostring(message))
end

local function quests()
    return Game.GetQuestsSystem()
end

local function getFact(name)
    local qs = quests()
    return qs and (qs:GetFactStr(name) or 0) or 0
end

local function setFact(name, value)
    local qs = quests()
    if qs then qs:SetFactStr(name, value) end
end

-- NIF's helper removes the engine lock only when its shared counter reaches
-- zero. Keep normal acquisitions balanced, then use the manager call as an
-- idempotent terminal safeguard so the completed gig can never leave saving
-- disabled because of a stale counter from an interrupted transition.
local function forceRemoveNIFSaveLock()
    pcall(function()
        SaveLocksManager.RequestSaveLockRemove("nif")
    end)
end

local function screenMessage(text, duration)
    local ok = pcall(function()
        local message = SimpleScreenMessage.new()
        message.message = text
        message.duration = duration or 7.0
        message.isShown = true
        local definitions = Game.GetAllBlackboardDefs().UI_Notifications
        Game.GetBlackboardSystem():Get(definitions):SetVariant(
            definitions.OnscreenMessage,
            ToVariant(message),
            true
        )
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

local function offsetPosition(position, offset)
    offset = type(offset) == "table" and offset or {}
    return {
        x = position.x + (tonumber(offset.x) or 0.0),
        y = position.y + (tonumber(offset.y) or 0.0),
        z = position.z + (tonumber(offset.z) or 0.0),
        w = 1.0
    }
end

local function currentAppearance(entity)
    if not entity then return nil end
    local ok, appearance = pcall(function()
        return NameToString(entity:GetCurrentAppearanceName())
    end)
    return ok and appearance or nil
end

local function recordFingerprint(entity)
    if not entity then return nil end
    local ok, recordID = pcall(function() return entity:GetRecordID() end)
    if not ok or not recordID then return nil end
    local value = tostring(recordID)
    local hash = value:match("hash%s*=%s*(0x%x+)")
    local length = value:match("length%s*=%s*(%d+)")
    if not hash or not length then return nil end
    return string.lower(hash) .. "," .. length
end

local function nearbyNPCs(maxDistance)
    local entities = {}
    local ok = pcall(function()
        local query = Game["TSQ_NPC;"]()
        query.maxDistance = maxDistance or 20.0
        local success, parts = Game.GetTargetingSystem():GetTargetParts(Game.GetPlayer(), query)
        if not success then return end
        for _, part in ipairs(parts) do
            local entity = part:GetComponent(part):GetEntity()
            if entity and entity:IsNPC() then table.insert(entities, entity) end
        end
    end)
    return ok and entities or {}
end

local function ensureGuestRecord(member)
    local ok = pcall(function()
        if not TweakDB:GetRecord(member.record) then
            TweakDB:CloneRecord(member.record, GUEST_SOURCE_RECORD)
        end
        TweakDB:SetFlat(member.record .. ".entityTemplatePath", member.template)
    end)
    return ok
end

local function persistentIDForNode(nodeRef)
    local entityRef = CreateEntityReference(nodeRef, {})
    local globalRef = ResolveNodeRef(entityRef.reference, GlobalNodeID.GetRoot())
    local entityID = entEntityID.new({ hash = globalRef.hash })
    return PersistentID.ForComponent(entityID, CName.new("controller"))
end

local function queuePersistentEvent(nodeRef, className, event)
    if not event then return false end
    return pcall(function()
        Game.GetPersistencySystem():QueuePSEvent(
            persistentIDForNode(nodeRef),
            CName.new(className),
            event
        )
    end)
end

local function queueSecurityEvent(event)
    return queuePersistentEvent(SECURITY_NODE_REF, "SecuritySystemControllerPS", event)
end

local function unlockStorageDoor()
    local unlocked = false
    local ok = pcall(function()
        unlocked = queuePersistentEvent(
            STORAGE_DOOR_REF,
            "DoorControllerPS",
            QuestForceUnlock.new()
        )
    end)
    if ok and unlocked then setFact(FACT.storageDoorUnlocked, 1) end
    return ok and unlocked
end

local function getBridge()
    local ok, bridge = pcall(function()
        return Game.GetScriptableSystemsContainer():Get("PFK_RouteBridge")
    end)
    return ok and bridge or nil
end

local function readSecurityAreaType(nodeRef)
    local ok, areaType = pcall(function()
        local bridge = getBridge()
        if not bridge then return nil end
        return bridge:GetSecurityAreaType(persistentIDForNode(nodeRef))
    end)
    areaType = tonumber(areaType)
    if not ok or areaType == nil or areaType < 0 then return nil end
    return areaType
end

local function queueSecurityAreaTransition(nodeRef, areaType)
    local ok, queued = pcall(function()
        local bridge = getBridge()
        if not bridge then return false end
        return bridge:SetSecurityAreaType(
            persistentIDForNode(nodeRef),
            tonumber(areaType)
        )
    end)
    return ok and queued == true
end

local function captureSecurityAreaTypes()
    if getFact(FACT.areaTypesCaptured) > 0 then return true end
    for _, area in ipairs(SECURITY_AREAS) do
        local areaType = readSecurityAreaType(area.nodeRef)
        if areaType == nil then
            log("Could not read security area type for " .. tostring(area.nodeRef))
            return false
        end
        -- Store value + 1 so zero remains an unambiguous uncaptured sentinel.
        setFact(area.previousFact, areaType + 1)
    end
    setFact(FACT.areaTypesCaptured, 1)
    return true
end

local function disableBackRoomSecurityAreas()
    if not captureSecurityAreaTypes() then return false end
    local success = true
    for _, area in ipairs(SECURITY_AREAS) do
        if not queueSecurityAreaTransition(area.nodeRef, 0) then
            success = false
            log("Could not disable security area " .. tostring(area.nodeRef))
        end
    end
    if success then setFact(FACT.areasDisabled, 1) end
    return success
end

local function restoreBackRoomSecurityAreas()
    if getFact(FACT.areaTypesCaptured) == 0 then return end
    -- Once the vanilla gig has finished, its own cleanup deliberately disables
    -- these areas. Do not resurrect restricted volumes after quest completion.
    if getFact(FACT.gigFinished) == 0 then
        for _, area in ipairs(SECURITY_AREAS) do
            local stored = getFact(area.previousFact)
            if stored > 0 and not queueSecurityAreaTransition(area.nodeRef, stored - 1) then
                log("Could not restore security area " .. tostring(area.nodeRef))
            end
        end
    end
    for _, area in ipairs(SECURITY_AREAS) do setFact(area.previousFact, 0) end
    setFact(FACT.areaTypesCaptured, 0)
    setFact(FACT.areasDisabled, 0)
end

local function authorizeSecurity(authorize)
    local authorizationOK = false
    local stateOK = not authorize
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
    end
    if authorizationOK then setFact(FACT.security, authorize and 1 or 0) end
    return authorizationOK and stateOK
end

function route:new(mod, project)
    local o = interaction.new(self, mod, project)
    o.interactionType = "Joytoys Missions and Gigs - Playing for Keeps"
    o.modulePath = "interactions/playingForKeepsJoytoyRoute"
    o.name = "Playing for Keeps - undercover manager booking"
    o.worldIcon = "ChoiceIcons.UseIcon"
    o.useWorldIconColor = true
    o.worldIconColor = { Red = 1.8, Green = 0.25, Blue = 1.35, Alpha = 1.0 }
    o.scene = PROMPT_SCENE
    o.skipFact = "pfk_skip_teleport"
    o.endEvent = PROMPT_END_EVENT
    o.startFactID = 24
    o.needsUpdate = true

    o.locStringIDOverride = "945077401258010800"
    o.oral5LocStringIDOverride = "945077401258010806"
    o.groupLocStringIDOverride = "945077401258010801"
    o.promptNodeRef = "#lch_05_tr_bar"
    o.anchorNodeRef = "#lch_05_tr_office"
    o.markerOffset = { x = 0.0, y = 0.0, z = 0.20 }
    o.sceneOffset = { x = 0.0, y = 0.0, z = 0.0 }
    o.scenePosition = { x = -1919.756, y = 1158.130, z = 12.175, w = 1.0 }
    o.playerOffset = { x = 0.0, y = 0.0, z = 0.0 }
    o.sceneYawOffset = 0.0
    o.sceneDuration = PRODUCTION_SCENE_DURATION

    -- Back-room continue marker + tunable standing positions for the trio.
    o.continueNodeRef = CONTINUE_NODE_REF
    o.continueMarkerOffset = { x = 0.0, y = 0.0, z = 0.20 }
    o.guestFemaleOffset = { x = 1.720, y = -0.400, z = 0.0 }
    o.guestOgawaOffset = { x = -1.415, y = -2.605, z = 0.0 }
    o.guestMaleOffset = { x = 1.356, y = 0.855, z = 0.0 }
    o.guestFemaleYaw = 101.0
    o.guestOgawaYaw = -34.0
    o.guestMaleYaw = 146.0

    o.promptResolved = false
    o.sceneDirector = sceneDirectorModule.get(log)
    o.pendingEncounter = false
    o.encounterStartedAt = 0.0
    o.sequenceIndex = 0
    o.awaitingKind = nil
    o.transitionActive = false
    o.transitionTimer = nil
    o.dialogueTimers = {}
    o.groupRevealed = false
    o.guestEntityIDs = {}
    o.hiddenOriginals = {}
    o.hiddenOriginalKeys = {}
    o.lastOriginalHidePoll = 0.0
    o.lastPoll = 0.0
    o.directorLastUpdate = os.clock()
    o.securityLastUpdate = 0.0
    setmetatable(o, { __index = self })
    return o
end

-- ===== Watching group stand-ins =====================================

function route:guestOffset(memberKey)
    local overrides = {
        female = self.guestFemaleOffset,
        ogawa = self.guestOgawaOffset,
        male = self.guestMaleOffset
    }
    return overrides[memberKey] or GROUP_MEMBERS[memberKey].offset
end

function route:guestYaw(memberKey)
    local overrides = {
        female = self.guestFemaleYaw,
        ogawa = self.guestOgawaYaw,
        male = self.guestMaleYaw
    }
    return tonumber(overrides[memberKey]) or tonumber(GROUP_MEMBERS[memberKey].yaw) or 0.0
end

function route:configureGuest(entityID, attempt)
    attempt = attempt or 1
    local entity = nil
    pcall(function() entity = Game.GetDynamicEntitySystem():GetEntity(entityID) end)
    if not entity then
        if attempt < 20 then
            Cron.After(0.25, function() self:configureGuest(entityID, attempt + 1) end)
        end
        return
    end
    pcall(function()
        local player = Game.GetPlayer()
        local agent = entity:GetAttitudeAgent()
        if agent and player then
            agent:SetAttitudeGroup(CName.new("TygerClaws"))
            agent:SetAttitudeTowards(player:GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
        end
        if entity.reactionComponent then
            local preset = TweakDBInterface.GetReactionPresetRecord(TweakDBID.new("ReactionPresets.NoReaction"))
            if preset then entity.reactionComponent:SetReactionPreset(preset) end
        end
    end)
end

function route:spawnGuest(memberKey, anchor)
    if not anchor then return end
    if self.guestEntityIDs[memberKey] then return end
    local member = GROUP_MEMBERS[memberKey]
    if not member or not ensureGuestRecord(member) then return end
    local position = offsetPosition(anchor.position, self:guestOffset(memberKey))
    local spec = DynamicEntitySpec.new()
    spec.recordID = TweakDBID.new(member.record)
    spec.appearanceName = member.appearance
    spec.position = Vector4.new(position.x, position.y, position.z, position.w)
    spec.orientation = EulerAngles.new(
        anchor.rotation.roll,
        anchor.rotation.pitch,
        self:guestYaw(memberKey)
    ):ToQuat()
    spec.persistState = false
    spec.persistSpawn = false
    spec.alwaysSpawned = true
    spec.spawnInView = false
    spec.tags = { CName.new(GUEST_TAG), CName.new(ROUTE_TAG) }
    local entityID = Game.GetDynamicEntitySystem():CreateEntity(spec)
    if entityID then
        self.guestEntityIDs[memberKey] = entityID
        self:configureGuest(entityID, 1)
    end
end

function route:despawnGuest(memberKey)
    local entityID = self.guestEntityIDs[memberKey]
    if not entityID then return end
    pcall(function() Game.GetDynamicEntitySystem():DeleteEntity(entityID) end)
    self.guestEntityIDs[memberKey] = nil
end

-- Stand the watching group up as everyone except the pose's active partner.
-- activeMember == nil (or "keisuke") stands all three up.
function route:reconcileStandingGuests(activeMember, anchor)
    if not self.groupRevealed then return end
    anchor = anchor or self:getSceneAnchor()
    for key in pairs(GROUP_MEMBERS) do
        if key == activeMember then
            self:despawnGuest(key)
        else
            self:spawnGuest(key, anchor)
        end
    end
end

-- Tracked despawn plus a tag sweep so no route-owned actor is ever left behind.
function route:cleanupGuests()
    for key in pairs(GROUP_MEMBERS) do self:despawnGuest(key) end
    self.guestEntityIDs = {}
    pcall(function()
        local des = Game.GetDynamicEntitySystem()
        for _, tag in ipairs({ GUEST_TAG, ROUTE_TAG }) do
            local ids = des:GetTaggedIDs(CName.new(tag))
            if ids then
                for _, id in ipairs(ids) do
                    pcall(function() des:DeleteEntity(id) end)
                end
            end
        end
    end)
end

function route:hideOriginals()
    local newlyHidden = 0
    local newlyDisposed = 0
    for _, entity in ipairs(nearbyNPCs(45.0)) do
        local appearance = currentAppearance(entity)
        local record = recordFingerprint(entity)
        if (appearance and HIDE_ORIGINAL_APPEARANCES[appearance])
            or (record and HIDE_ORIGINAL_RECORDS[record]) then
            local key = tostring(entity:GetEntityID().hash)
            if not self.hiddenOriginalKeys[key] then
                local mustDispose = (appearance and DISPOSE_ORIGINAL_APPEARANCES[appearance])
                    or (record and HIDE_ORIGINAL_RECORDS[record])
                local removed = false
                if mustDispose then
                    removed = pcall(function() entity:Dispose() end)
                else
                    removed = pcall(function() entity:SetInvisible(true) end)
                end
                if removed then
                    self.hiddenOriginalKeys[key] = true
                    if mustDispose then
                        newlyDisposed = newlyDisposed + 1
                    else
                        table.insert(self.hiddenOriginals, entity)
                        newlyHidden = newlyHidden + 1
                    end
                end
            else
                -- Reassert the hidden state in case a community reload or an
                -- appearance system made the actor visible again.
                if appearance and DISPOSE_ORIGINAL_APPEARANCES[appearance] then
                    pcall(function() entity:Dispose() end)
                else
                    pcall(function() entity:SetInvisible(true) end)
                end
            end
        end
    end
    if newlyHidden > 0 then
        log("Removed " .. tostring(newlyHidden) .. " original back-room Tyger NPC(s) from the staged encounter")
    end
    if newlyDisposed > 0 then
        log("Despawned the original back-room female Tyger community actor")
    end
end

function route:restoreOriginals()
    for _, entity in ipairs(self.hiddenOriginals or {}) do
        pcall(function() entity:SetInvisible(false) end)
    end
    self.hiddenOriginals = {}
    self.hiddenOriginalKeys = {}
end

-- ===== Bridge / gating ==============================================

function route:callBridge(methodName)
    local bridge = getBridge()
    if not bridge then return false end
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

function route:gigAllowsCover()
    local routeActive = getFact(FACT.state) > 0
    return getFact(FACT.gigStart) > 0
        and getFact(FACT.gigFinished) == 0
        and (routeActive or (getFact(FACT.alarm) == 0 and getFact(FACT.combat) == 0))
end

function route:canOffer()
    -- Keep the world marker enabled while a confirmation prompt is launching.
    if self.sceneRunning and self.pendingEncounter then
        return self.promptResolved and self:gigAllowsCover()
    end
    -- Back-room trigger for the oral-5 pose or the group encounter.
    if self.awaitingKind then
        return self.promptResolved
            and self:gigAllowsCover()
            and getFact(FACT.haveEye) == 0
            and not self.sceneRunning
            and self.sceneDirector.status().phase == "idle"
    end
    -- Initial bar interaction.
    return self.promptResolved
        and self:gigAllowsCover()
        and getFact(FACT.haveEye) == 0
        and getFact(FACT.reginaTipAcknowledged) > 0
        and getFact(FACT.complete) == 0
        and getFact(FACT.state) == 0
        and not self.sceneRunning
        and self.sceneDirector.status().phase == "idle"
        and self:callBridge("CanStart")
end

function route:getPromptPatch()
    local locStringID = self.locStringIDOverride
    if self.awaitingKind == "oral5" then
        locStringID = self.oral5LocStringIDOverride
    elseif self.awaitingKind == "group" then
        locStringID = self.groupLocStringIDOverride
    end
    return {
        choiceID = self.choiceUniqueID,
        locMap = {
            [6146] = CreateCRUID(loadstring("return " .. locStringID .. "ULL", "")())
        }
    }
end

-- ===== Scene definitions / anchor ===================================

function route:getSceneDefinition(index)
    local scene = SEQUENCE[index]
    if not scene then return nil end
    local duration = scene.duration or PRODUCTION_SCENE_DURATION
    if index == 1 then duration = tonumber(self.sceneDuration) or duration end
    return {
        name = scene.name,
        partnerProfile = scene.partnerProfile,
        playerWorkspot = scene.playerWorkspot,
        partnerWorkspot = scene.partnerWorkspot,
        duration = math.max(1.0, duration)
    }
end

function route:getSceneAnchor()
    local transform = resolveTransform(self.anchorNodeRef)
    if not transform then return nil end
    local basePosition = transform:GetPosition()
    local requestedPosition = type(self.scenePosition) == "table" and self.scenePosition or basePosition
    local scenePosition = offsetPosition(requestedPosition, self.sceneOffset)
    local playerPosition = offsetPosition(scenePosition, self.playerOffset)
    local rotation = transform:ToEulerAngles()
    return {
        position = scenePosition,
        playerPosition = playerPosition,
        spawnPosition = playerPosition,
        rotation = {
            roll = rotation.roll or 0.0,
            pitch = rotation.pitch or 0.0,
            yaw = (rotation.yaw or 0.0) + (tonumber(self.sceneYawOffset) or 0.0)
        }
    }
end

function route:teleportToScene(anchor)
    local player = GetPlayer()
    if not player or not anchor then return false end
    return pcall(function()
        local position = anchor.playerPosition or anchor.position
        Game.GetTeleportationFacility():Teleport(
            player,
            Vector4.new(position.x, position.y, position.z, position.w or 1.0),
            EulerAngles.new(anchor.rotation.roll, anchor.rotation.pitch, anchor.rotation.yaw)
        )
    end)
end

function route:triggerPrompt()
    setFact(FACT.sceneID, 24)
    setFact(FACT.sceneSignal, 1)
end

-- ===== Cover lifecycle ==============================================

function route:clearDialogueTimers()
    for _, timer in ipairs(self.dialogueTimers or {}) do
        pcall(function() Cron.Halt(timer) end)
    end
    self.dialogueTimers = {}
end

local function dialogueCardDuration(line)
    if type(line) ~= "string" then return DIALOGUE_HOLD_SECONDS end
    if string.find(line, "\n", 1, true) or #line >= LONG_DIALOGUE_MIN_CHARACTERS then
        return LONG_DIALOGUE_HOLD_SECONDS
    end
    return DIALOGUE_HOLD_SECONDS
end

function route:queueDialogue(lines)
    self:clearDialogueTimers()
    if type(lines) ~= "table" then return 0.0 end

    local delay = 0.0
    for _, line in ipairs(lines) do
        if type(line) == "string" and line ~= "" then
            local hold = dialogueCardDuration(line)
            local message = line
            local messageHold = hold
            if delay <= 0.0 then
                screenMessage(message, messageHold)
            else
                local timer = Cron.After(delay, function()
                    if getFact(FACT.state) == 0 then return end
                    screenMessage(message, messageHold)
                end)
                table.insert(self.dialogueTimers, timer)
            end
            delay = delay + hold
        end
    end
    return delay
end

-- Spread animation dialogue across the whole pose rather than exhausting it
-- at the start. The final card begins one hold interval before the pose ends,
-- so every card remains readable for the full minimum display time.
function route:queueSceneDialogue(lines, sceneDuration)
    self:clearDialogueTimers()
    if type(lines) ~= "table" then return end

    local cards = {}
    local totalHold = 0.0
    for _, line in ipairs(lines) do
        if type(line) == "string" and line ~= "" then
            local hold = dialogueCardDuration(line)
            table.insert(cards, { line = line, hold = hold })
            totalHold = totalHold + hold
        end
    end
    if #cards == 0 then return end

    local duration = math.max(DIALOGUE_HOLD_SECONDS, tonumber(sceneDuration) or PRODUCTION_SCENE_DURATION)
    local gap = 0.0
    if #cards > 1 and totalHold < duration then
        gap = (duration - totalHold) / (#cards - 1)
    end

    local delay = 0.0
    for _, card in ipairs(cards) do
        local message = card.line
        local messageHold = card.hold
        if delay <= 0.0 then
            screenMessage(message, messageHold)
        else
            local timer = Cron.After(delay, function()
                if getFact(FACT.state) ~= 2 then return end
                screenMessage(message, messageHold)
            end)
            table.insert(self.dialogueTimers, timer)
        end
        delay = delay + card.hold + gap
    end
end

function route:clearAwaiting()
    self:clearDialogueTimers()
    self.awaitingKind = nil
    if self.transitionTimer then
        Cron.Halt(self.transitionTimer)
        self.transitionTimer = nil
    end
    self.transitionActive = false
end

function route:releaseCover(resetCompletion)
    self.sceneDirector.shutdown()
    self:clearAwaiting()
    self:cleanupGuests()
    self:restoreOriginals()
    self.groupRevealed = false
    self.sequenceIndex = 0
    self.pendingEncounter = false
    self.encounterStartedAt = 0.0
    setFact(FACT.sceneSignal, 0)
    setFact(FACT.sceneID, 0)
    restoreBackRoomSecurityAreas()
    setFact(FACT.state, 0)
    if resetCompletion then setFact(FACT.complete, 0) end
    if getFact(FACT.security) > 0 then authorizeSecurity(false) end
    self:callBridge("EndInfiltration")
    forceRemoveNIFSaveLock()
end

function route:failStart(reason)
    log("Playing for Keeps encounter aborted: " .. tostring(reason))
    self.sceneDirector.stop(tostring(reason), "failed")
    utils.removeSaveLock()
    setFact("nif_scene_active", 0)
    self:releaseCover(true)
    screenMessage("The private booking could not continue. You can try again.", 6.0)
end

-- Play the native-interactions confirmation/transition scene, then run onConfirm.
-- establishCover is true only for the initial bar interaction.
function route:launchTransition(establishCover, onConfirm)
    if not self:gigAllowsCover() then return end
    if self.sceneRunning then return end
    self.sceneRunning = true
    self.pendingEncounter = true
    self.pendingStartTimer = Cron.AfterTicks(2, function()
        self.pendingStartTimer = nil
        if not self.sceneRunning or not self.pendingEncounter then return end

        local success = resourceHelper.registerSceneEnd(PROMPT_END_EVENT, function(sceneActive)
            -- Balances the lock added immediately after triggerPrompt().
            utils.removeSaveLock()
            self.sceneRunning = false
            if sceneActive == 1 then
                world.forceIcons()
                Cron.After(0.25, function() onConfirm() end)
            elseif establishCover then
                self:releaseCover(true)
            else
                -- Player backed out; keep the marker offered for another try.
                self.pendingEncounter = false
            end
        end)
        if not success then
            self.sceneRunning = false
            self.pendingEncounter = false
            return
        end

        resourceHelper.requestSceneSignal(self, function()
            if not self.sceneRunning or not self.pendingEncounter then
                resourceHelper.endEvents[PROMPT_END_EVENT] = nil
                return
            end
            if establishCover then
                -- Mark active before the bridge establishes cover; it rejects
                -- stale state 0.
                setFact(FACT.state, 1)
                if not self:callBridge("BeginInfiltration") then
                    resourceHelper.endEvents[PROMPT_END_EVENT] = nil
                    self.sceneRunning = false
                    self.pendingEncounter = false
                    self:releaseCover(true)
                    log("Could not establish the temporary Tyger Claw cover")
                    return
                end
            else
                self:callBridge("MaintainInfiltration")
            end
            if not authorizeSecurity(true) then
                log("Kashuu Hanten security authorization could not be queued")
            end
            if not disableBackRoomSecurityAreas() and establishCover then
                resourceHelper.endEvents[PROMPT_END_EVENT] = nil
                self.sceneRunning = false
                self.pendingEncounter = false
                self:releaseCover(true)
                screenMessage("The back-office cover could not be established. You can try again.", 7.0)
                return
            end
            Game.GetResourceDepot():RemoveResourceFromCache(PROMPT_SCENE)
            resourceHelper.registerPatch(PROMPT_SCENE, self:getPromptPatch())
            self:triggerPrompt()
            utils.addSaveLock()
        end)
    end)
end

-- After the bar interaction: reveal the back-room group and hand control back so
-- V can walk to the private area. No teleport into a pose here.
function route:interactionArrive()
    self.groupRevealed = true
    self:hideOriginals()
    self:reconcileStandingGuests(nil, self:getSceneAnchor())
    self.sequenceIndex = 0
    self.awaitingKind = "oral5"
    setFact(FACT.state, 4)
    self:queueDialogue({
        "Keisuke: Huh. KabukiRose. I am liking what I am seeing.",
        "V: So where do you want to do this?",
        "Keisuke: Come around behind the bar and undress in the kitchen. The gang are waiting for you in the back office.",
        "[Undercover] Head to the private area at the back and meet Keisuke look to swipe the eye when you have the opportunity."
    })
    log("Arrived: nude group staged in the back; awaiting the oral-5 trigger")
end

-- Shared pose launcher. Waits for the interaction prompt to release, positions
-- the watching group, teleports V to the scanned spot, and starts the director.
function route:enterPose(index, introMessage, attempt)
    attempt = attempt or 1
    local player = GetPlayer()
    local tier = player and player:GetSceneTier() or 0
    if getFact("nif_scene_active") > 0 or tier >= 3
        or getFact(FACT.sceneSignal) > 0 or getFact(FACT.sceneID) ~= 0 then
        if attempt <= 100 then
            Cron.After(0.20, function() self:enterPose(index, introMessage, attempt + 1) end)
        else
            self:failStart("interaction prompt did not release")
        end
        return
    end

    local anchor = self:getSceneAnchor()
    if not anchor then return self:failStart("scanned storeroom scene position is not streamed") end
    local definition = self:getSceneDefinition(index)
    local ready, detail = self.sceneDirector.preflight(anchor, definition)
    if not ready then return self:failStart(detail) end

    self:hideOriginals()
    self:reconcileStandingGuests(SEQUENCE[index].activeMember, anchor)

    if not self:teleportToScene(anchor) then return self:failStart("scene relocation failed") end

    self.pendingEncounter = false
    self.awaitingKind = nil
    self.sequenceIndex = index
    self.encounterStartedAt = os.clock()
    setFact(FACT.state, 2)
    utils.addSaveLock()
    Cron.After(0.65, function()
        if getFact(FACT.state) ~= 2 or self.sequenceIndex ~= index then return end
        local started, startDetail = self.sceneDirector.start(anchor, definition)
        if not started then return self:failStart(startDetail) end
        local dialogue = SEQUENCE[index].dialogue
        if type(dialogue) == "table" then
            self:queueSceneDialogue(dialogue, definition.duration)
        elseif introMessage then
            self:queueSceneDialogue({ introMessage }, definition.duration)
        end
        log(string.format("Pose %d (%s) requested for %0.1f seconds", index, SEQUENCE[index].name, definition.duration))
    end)
end

-- Called when the director reports a pose completed.
function route:onSceneCompleted(index)
    self:clearDialogueTimers()
    -- Every enterPose() owns exactly one lock. Release it before moving to the
    -- next prompt or automatically chained pose.
    utils.removeSaveLock()
    if index == 1 then
        -- Oral 5 done -> offer the group encounter as its own interaction.
        local t = SEQUENCE[1].transition or {}
        local lines = {}
        if t.line then table.insert(lines, t.line) end
        if t.trigger then table.insert(lines, t.trigger .. "  (interact to join the group)") end
        self:queueDialogue(lines)
        self.sequenceIndex = 0
        self.awaitingKind = "group"
        setFact(FACT.state, 4)
        return
    end

    if index >= FINAL_SCENE_INDEX then
        return self:completeSequence()
    end

    -- Inside the group encounter: auto-chain to the next pose.
    local transition = SEQUENCE[index].transition or {}
    local lines = {}
    if transition.line then table.insert(lines, transition.line) end
    if transition.trigger then table.insert(lines, transition.trigger) end
    local transitionDuration = self:queueDialogue(lines)
    self.transitionActive = true
    self.transitionTimer = Cron.After(transitionDuration + 0.25, function()
        self.transitionTimer = nil
        self.transitionActive = false
        if getFact(FACT.state) ~= 2 or self.sequenceIndex ~= index then return end
        if not self:gigAllowsCover() then return self:failStart("cover was lost between poses") end
        self:enterPose(index + 1, sceneIntro(index + 1), 1)
    end)
end

function route:completeSequence()
    self:clearAwaiting()
    -- onSceneCompleted() balanced the final pose. This direct removal is the
    -- terminal fail-safe requested for the end-of-quest save-lock regression.
    forceRemoveNIFSaveLock()
    self.encounterStartedAt = 0.0
    self.sequenceIndex = FINAL_SCENE_INDEX

    -- Afterglow: the whole nude group stays until the gig completes.
    self:reconcileStandingGuests(nil, self:getSceneAnchor())

    disableBackRoomSecurityAreas()
    if not unlockStorageDoor() then
        log("The storage door unlock event could not be queued")
    end
    setFact(FACT.complete, 1)
    setFact(FACT.state, 3)

    local finalLine = (SEQUENCE[FINAL_SCENE_INDEX].transition or {}).line
    self:queueDialogue({
        finalLine,
        "Female Tyger: And don't get curious back there. We catch you snooping, the friendly part of the night is over.",
        "[Undercover] Take the keycard, get changed in the storeroom, and look for Jacob Lamb's eye before leaving."
    })
    log("Group encounter completed; storeroom unlocked, nude group remains until gig completion")
end

-- ===== NIF entry lifecycle ==========================================

function route:start()
    if self.awaitingKind == "oral5" then
        return self:launchTransition(false, function() self:enterPose(1, sceneIntro(1), 1) end)
    elseif self.awaitingKind == "group" then
        return self:launchTransition(false, function()
            self:enterPose(FIRST_GROUP_INDEX, sceneIntro(FIRST_GROUP_INDEX), 1)
        end)
    end
    if not self:canOffer() then return end
    self:launchTransition(true, function() self:interactionArrive() end)
end

function route:stop()
    if not self.sceneRunning then return end
    self.sceneRunning = false
    if resourceHelper.cancelSceneSignal(self) then
        resourceHelper.endEvents[PROMPT_END_EVENT] = nil
        self.pendingEncounter = false
        -- Only release the whole route if we were still establishing cover.
        if not self.awaitingKind and getFact(FACT.state) <= 1 then
            self:releaseCover(true)
        end
        return
    end
    if self.pendingStartTimer then
        Cron.Halt(self.pendingStartTimer)
        self.pendingStartTimer = nil
        self.pendingEncounter = false
        return
    end
    setFact(self.skipFact, 1)
end

function route:sessionStart()
    self.sceneRunning = false
    self.promptResolved = false
    self.pendingEncounter = false
    self.encounterStartedAt = 0.0
    self.sequenceIndex = 0
    self.awaitingKind = nil
    self.transitionActive = false
    self.transitionTimer = nil
    self.dialogueTimers = {}
    self.groupRevealed = false
    self.guestEntityIDs = {}
    self.hiddenOriginals = {}
    self.hiddenOriginalKeys = {}
    self.lastOriginalHidePoll = 0.0
    self.lastPoll = 0.0
    self.directorLastUpdate = os.clock()
    self.securityLastUpdate = 0.0

    if getFact(FACT.revision) ~= ROUTE_REVISION then
        self.sceneDirector.shutdown()
        utils.removeSaveLock()
        setFact(FACT.revision, ROUTE_REVISION)
        self:releaseCover(true)
    elseif getFact(FACT.state) == 1 or getFact(FACT.state) == 2 or getFact(FACT.state) == 4 then
        -- A save taken mid-cover, mid-pose, or between triggers is recovered by
        -- cleanly releasing the route rather than resuming a partial encounter.
        self.sceneDirector.shutdown()
        utils.removeSaveLock()
        setFact("nif_scene_active", 0)
        self:releaseCover(true)
        log("Recovered an interrupted Playing for Keeps encounter")
    elseif getFact(FACT.state) == 3 and self:gigAllowsCover() then
        self.groupRevealed = true
        self:callBridge("MaintainInfiltration")
        authorizeSecurity(true)
        disableBackRoomSecurityAreas()
        unlockStorageDoor()
        self:hideOriginals()
        self.sequenceIndex = FINAL_SCENE_INDEX
        self:reconcileStandingGuests(nil, self:getSceneAnchor())
    elseif getFact(FACT.truce) > 0 or getFact(FACT.security) > 0 then
        self:releaseCover(false)
    end
end

function route:sessionEnd()
    self.sceneDirector.shutdown()
    self:clearAwaiting()
    self:cleanupGuests()
    self:restoreOriginals()
    self.groupRevealed = false
    self.promptResolved = false
    self.pendingEncounter = false
end

function route:updatePromptPosition()
    local nodeRef = self.awaitingKind and self.continueNodeRef or self.promptNodeRef
    local offset = self.awaitingKind and self.continueMarkerOffset or self.markerOffset
    local transform = resolveTransform(nodeRef)
    if not transform then
        self.promptResolved = false
        return
    end
    local markerPosition = offsetPosition(transform:GetPosition(), offset)
    world.updateInteractionPosition(
        self.worldInteractionID,
        Vector4.new(markerPosition.x, markerPosition.y, markerPosition.z, markerPosition.w)
    )
    self.promptResolved = true
end

function route:onUpdate(_playerPosition)
    local now = os.clock()
    local delta = math.max(0.0, now - (self.directorLastUpdate or now))
    self.directorLastUpdate = now
    self.sceneDirector.update(delta)

    local result = self.sceneDirector.consumeResult()
    if result and getFact(FACT.state) == 2 and not self.transitionActive then
        if result.outcome == "completed" then
            self:onSceneCompleted(self.sequenceIndex)
        else
            self:failStart(result.reason)
        end
    end

    if now - self.lastPoll < 0.20 then return end
    self.lastPoll = now
    self:updatePromptPosition()
    world.disableInteraction(self.worldInteractionID, not self:canOffer())

    local state = getFact(FACT.state)
    if state ~= 0 and not self:gigAllowsCover() then
        self.sceneDirector.shutdown()
        utils.removeSaveLock()
        setFact("nif_scene_active", 0)
        self:releaseCover(false)
        log("Cover released (gig ended, combat, or alarm); nude group despawned")
        return
    end
    if state == 0 then return end

    self:callBridge("MaintainInfiltration")
    -- The back room may not be streamed when V first accepts the booking. Keep
    -- looking while the encounter is active so the original woman is removed
    -- as soon as her community actor actually exists.
    if self.groupRevealed and now - (self.lastOriginalHidePoll or 0.0) >= 0.75 then
        self.lastOriginalHidePoll = now
        self:hideOriginals()
    end
    if now - (self.securityLastUpdate or 0.0) >= 1.0 then
        self.securityLastUpdate = now
        authorizeSecurity(true)
        disableBackRoomSecurityAreas()
        if state == 3 then unlockStorageDoor() end
    end

    -- Keep the nude group standing while awaiting a trigger and during afterglow.
    if (state == 3 or state == 4) and self.groupRevealed then
        local standing = 0
        for _ in pairs(self.guestEntityIDs) do standing = standing + 1 end
        if standing < 3 then self:reconcileStandingGuests(nil, self:getSceneAnchor()) end
    end

    if state == 2 and not self.transitionActive then
        local status = self.sceneDirector.status()
        if status.phase == "idle" and now - self.encounterStartedAt > 5.0 then
            self:failStart("embedded scene director returned to idle without a completion result")
        end
    end
end

function route:save()
    local data = interaction.save(self)
    data.locStringIDOverride = self.locStringIDOverride
    data.oral5LocStringIDOverride = self.oral5LocStringIDOverride
    data.groupLocStringIDOverride = self.groupLocStringIDOverride
    data.promptNodeRef = self.promptNodeRef
    data.anchorNodeRef = self.anchorNodeRef
    data.markerOffset = self.markerOffset
    data.sceneOffset = self.sceneOffset
    data.scenePosition = self.scenePosition
    data.playerOffset = self.playerOffset
    data.sceneYawOffset = self.sceneYawOffset
    data.sceneDuration = self.sceneDuration
    data.continueNodeRef = self.continueNodeRef
    data.continueMarkerOffset = self.continueMarkerOffset
    data.guestFemaleOffset = self.guestFemaleOffset
    data.guestOgawaOffset = self.guestOgawaOffset
    data.guestMaleOffset = self.guestMaleOffset
    data.guestFemaleYaw = self.guestFemaleYaw
    data.guestOgawaYaw = self.guestOgawaYaw
    data.guestMaleYaw = self.guestMaleYaw
    return data
end

return route
