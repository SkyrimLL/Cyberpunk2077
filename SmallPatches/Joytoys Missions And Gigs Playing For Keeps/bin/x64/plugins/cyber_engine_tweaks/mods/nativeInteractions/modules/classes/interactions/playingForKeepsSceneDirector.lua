-- Joytoys Missions and Gigs: Playing for Keeps - embedded two-actor scene director
--
-- This runtime owns its actors, paired workspot devices, FreeFly viewing,
-- player restrictions, timed completion, and cleanup. It deliberately does
-- not call Negotiable Affection, JoytoysOfNightCity, or a vanilla quest scene.

local M = {}

local WORKSPOT_DEVICE = "base\\spawner\\workspot_device.ent"
local DEFAULT_SCENE = {
    name = "missionary",
    playerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\missionary\\ponc_synced_missionary_01_b.workspot",
    partnerWorkspot = "pinkydude\\pleasures_of_nightcity\\anims_vol1\\workspots\\missionary\\ponc_synced_missionary_01_a.workspot",
    duration = 28.0
}
local PARTNER_SOURCE_RECORD = "Character.jpn_tyger_claws_biker1_melee1_fists_ma"
local PARTNER_PROFILES = {
    keisuke = {
        label = "Keisuke Kagawa",
        record = "Character.PFK_PlayingForKeepsKeisukePartner",
        template = "base\\open_world\\street_stories\\watson\\little_china\\sts_wat_lch_05\\characters\\sts_wat_lch_05_keisuke_kagawa.ent",
        appearance = "service__vendor_ma__wbr_ich_foodshop_02",
        usesLizziesBody = false,
        isFemale = false
    },
    tyger_kunoichi = {
        label = "Tyger Claw kunoichi",
        record = "Character.PFK_PlayingForKeepsKunoichiPartner",
        template = "mod\\arman3_lizzies_bds\\characters\\entities\\gang__tyger_wa.ent",
        appearance = "gang__tyger_wa_kunoichi__lvl3_01_naked",
        -- Female partner: no Lizzie's BDs erect-penis component work.
        usesLizziesBody = false,
        isFemale = true
    },
    tyger_biker = {
        label = "Tyger Claw biker",
        record = "Character.PFK_PlayingForKeepsTygerPartner",
        template = "mod\\arman3_lizzies_bds\\characters\\entities\\gang__tyger_ma.ent",
        appearance = "gang__tyger_ma_biker__lvl1_01_naked",
        usesLizziesBody = true
    },
    tyger_gangster_1 = {
        label = "Tyger Claw gangster 1",
        record = "Character.PFK_PlayingForKeepsTygerGangster1Partner",
        template = "mod\\arman3_lizzies_bds\\characters\\entities\\gang__tyger_ma.ent",
        appearance = "gang__tyger_ma_gangster__lvl1_03_naked",
        usesLizziesBody = true
    },
    tyger_gangster_2 = {
        label = "Tyger Claw gangster 2",
        record = "Character.PFK_PlayingForKeepsTygerGangster2Partner",
        template = "mod\\arman3_lizzies_bds\\characters\\entities\\gang__tyger_ma.ent",
        appearance = "gang__tyger_ma_gangster__lvl2_03_naked",
        usesLizziesBody = true
    },
    jotaro = {
        label = "Jotaro",
        record = "Character.PFK_PlayingForKeepsJotaroPartner",
        template = "mod\\arman3_lizzies_bds\\characters\\entities\\sts_wat_kab_07_jotaro.ent",
        appearance = "gang__tyger_ma__sts_wat_kab_07_jotaro_naked",
        usesLizziesBody = true
    }
}
local PARTNER_BASE_PENIS_COMPONENT = "i0_000_pma_base__penis"
local PARTNER_ERECT_COMPONENT = "lizzies_bds_component_penis"
local PARTNER_ERECT_MESH = "mod\\arman3_lizzies_bds\\characters\\common\\dp77_x_dicks\\i1_penis_extra_large_ma.mesh"

local ENTITY_SETTLE_SECONDS = 0.85
local ENTRY_RETRY_SECONDS = 1.25
local ENTRY_RETRY_PAUSE_SECONDS = 0.50
local ENTRY_TIMEOUT_SECONDS = 8.0
local STOP_SETTLE_SECONDS = 0.75
local PARTNER_MESH_REFRESH_SECONDS = 0.25
local MOAN_REPEAT_SECONDS = 4.5
local PLAYER_CLONE_HIDDEN_Z_OFFSET = -10.0

local RESTRICTIONS = {
    "GameplayRestriction.NoMovement",
    "GameplayRestriction.NoCombat",
    "GameplayRestriction.NoPhone",
    "GameplayRestriction.NoWorldInteractions"
}

local VIEW_OFFSET = { x = 0.0, y = -3.20, z = 0.55, w = 0.0 }
-- FreeFly's speed setting persists globally in its own config and can be left
-- at its 0.001 floor (e.g. from repeated PreviousWeapon presses while flying),
-- which is visually indistinguishable from the camera not moving at all.
local MIN_SCENE_VIEW_SPEED = 1.0

local singleton = nil

local function vectorFrom(data)
    return Vector4.new(data.x, data.y, data.z, data.w or 1.0)
end

local function rotationFrom(data)
    return EulerAngles.new(data.roll or 0.0, data.pitch or 0.0, data.yaw or 0.0)
end

local function normalizeScene(definition)
    definition = type(definition) == "table" and definition or DEFAULT_SCENE
    local partnerProfile = definition.partnerProfile or "keisuke"
    if not PARTNER_PROFILES[partnerProfile] then partnerProfile = "keisuke" end
    return {
        name = definition.name or DEFAULT_SCENE.name,
        playerWorkspot = definition.playerWorkspot or DEFAULT_SCENE.playerWorkspot,
        partnerWorkspot = definition.partnerWorkspot or DEFAULT_SCENE.partnerWorkspot,
        duration = math.max(1.0, tonumber(definition.duration) or DEFAULT_SCENE.duration),
        partnerProfile = partnerProfile
    }
end

local function getFreeFly()
    local ok, mod = pcall(function() return GetMod("freefly") end)
    if ok and type(mod) == "table" then return mod end
    if type(freefly) == "table" then return freefly end
    return nil
end

local function entityKey(entityOrID)
    if not entityOrID then return nil end
    local id = entityOrID
    local okGetter, getter = pcall(function() return entityOrID.GetEntityID end)
    if okGetter and type(getter) == "function" then
        pcall(function() id = entityOrID:GetEntityID() end)
    end
    local hash = nil
    pcall(function() hash = id.hash end)
    return hash ~= nil and tostring(hash) or nil
end

local function resourceExists(path)
    local ok, exists = pcall(function()
        return Game.GetResourceDepot():ResourceExists(ResRef.FromString(path))
    end)
    return ok and exists == true
end

local function actorInWorkspot(actor)
    if not actor then return false end
    local ok, result = pcall(function()
        return Game.GetWorkspotSystem():IsActorInWorkspot(actor)
    end)
    return ok and result == true
end

local function getDynamicEntity(id)
    if not id then return nil end
    local ok, entity = pcall(function() return Game.GetDynamicEntitySystem():GetEntity(id) end)
    return ok and entity or nil
end

local function getStaticEntity(id)
    if not id then return nil end
    local ok, entity = pcall(function() return Game.GetStaticEntitySystem():GetEntity(id) end)
    return ok and entity or nil
end

local function playerRecord()
    local player = Game.GetPlayer()
    if not player then return nil end
    local gender = "Female"
    pcall(function() gender = NameToString(player:GetResolvedGenderName()) end)
    if gender == "Male" then return "Character.TPP_Player_Cutscene_Male" end
    return "Character.TPP_Player_Cutscene_Female"
end

local function playerIsFemale()
    local player = Game.GetPlayer()
    if not player then return true end
    local gender = "Female"
    pcall(function() gender = NameToString(player:GetResolvedGenderName()) end)
    return gender ~= "Male"
end

local function recordExists(record)
    local path = nil
    pcall(function() path = TweakDB:GetFlat(record .. ".entityTemplatePath") end)
    return path ~= nil
end

local function ensurePartnerRecord(profile)
    local ok = pcall(function()
        if not TweakDB:GetRecord(profile.record) then
            TweakDB:CloneRecord(profile.record, PARTNER_SOURCE_RECORD)
        end
        TweakDB:SetFlat(profile.record .. ".entityTemplatePath", profile.template)
    end)
    return ok and recordExists(profile.record)
end

local function createDirector(logger)
    local director = {
        initialized = false,
        lifecycleReady = false,
        assembleCallbacks = {},
        attachCallbacks = {},
        active = nil,
        result = nil,
        lastError = "",
        lastEvent = "not initialized"
    }

    local function log(message)
        if type(logger) == "function" then
            logger("Scene director: " .. tostring(message))
        end
    end

    local function setError(message)
        director.lastError = tostring(message or "unknown scene error")
        director.lastEvent = director.lastError
        log(director.lastError)
        return false, director.lastError
    end

    local function registerCallback(bucket, id, callback)
        local key = entityKey(id)
        if not key then return false end
        bucket[key] = callback
        return true
    end

    local function dispatchCallback(bucket, event)
        if not event or type(event.GetEntity) ~= "function" then return end
        local ok, entity = pcall(function() return event:GetEntity() end)
        if not ok or not entity then return end
        local key = entityKey(entity)
        local callback = key and bucket[key] or nil
        if not callback then return end
        bucket[key] = nil
        local callbackOK, callbackError = pcall(callback, entity)
        if not callbackOK then setError(callbackError) end
    end

    local function initialize()
        if director.initialized then return director.lifecycleReady end
        director.initialized = true
        local assembleOK = pcall(function()
            Observe("PFK_EmbeddedSceneEntityService", "OnAssemble", function(_, event)
                dispatchCallback(director.assembleCallbacks, event)
            end)
        end)
        local attachOK = pcall(function()
            Observe("PFK_EmbeddedSceneEntityService", "OnAttached", function(_, event)
                dispatchCallback(director.attachCallbacks, event)
            end)
        end)
        director.lifecycleReady = assembleOK and attachOK
        if not director.lifecycleReady then
            return setError("Codeware lifecycle service is unavailable")
        end
        director.lastEvent = "embedded scene director ready"
        log(director.lastEvent)
        return true
    end

    local function fastExit(actor)
        if not actor then return end
        pcall(function()
            Game.GetWorkspotSystem():SendFastExitSignal(actor, Vector3.new(), false, false, true)
        end)
    end

    local function routeBridge()
        local ok, bridge = pcall(function()
            return Game.GetScriptableSystemsContainer():Get("PFK_RouteBridge")
        end)
        return ok and bridge or nil
    end

    local function partnerOnlyMoaning(active)
        -- Poses where V is the giver (mouth occupied): only the partner moans.
        local poseName = string.lower(tostring(active and active.scene and active.scene.name or ""))
        return poseName == "oral01" or poseName == "oral02" or poseName == "oral05"
    end

    local function partnerIsFemale(active)
        return active ~= nil and active.partnerProfile ~= nil
            and active.partnerProfile.isFemale == true
    end

    local function startMoaning(active)
        if not active or active.moaningStarted then return end
        local playerActor = active.playerActor or getDynamicEntity(active.playerActorID)
        local partnerActor = active.partnerActor or getDynamicEntity(active.partnerActorID)
        local bridge = routeBridge()
        if not playerActor or not partnerActor or not bridge then return end
        local ok, started = pcall(function()
            return bridge:StartSceneMoaning(
                playerActor:GetEntityID(),
                partnerActor:GetEntityID(),
                playerIsFemale(),
                partnerIsFemale(active),
                partnerOnlyMoaning(active)
            )
        end)
        if ok and started ~= false then
            active.moaningStarted = true
            active.nextMoanAt = MOAN_REPEAT_SECONDS
            log("Lizzie's BDs moaning started")
        else
            log("Lizzie's BDs moaning could not start")
        end
    end

    local function continueMoaning(active)
        if not active or not active.moaningStarted then return end
        if active.runningElapsed < (active.nextMoanAt or MOAN_REPEAT_SECONDS) then return end
        local playerActor = active.playerActor or getDynamicEntity(active.playerActorID)
        local partnerActor = active.partnerActor or getDynamicEntity(active.partnerActorID)
        local bridge = routeBridge()
        if not playerActor or not partnerActor or not bridge then return end
        pcall(function()
            bridge:ContinueSceneMoaning(
                playerActor:GetEntityID(),
                partnerActor:GetEntityID(),
                partnerOnlyMoaning(active)
            )
        end)
        active.nextMoanAt = active.runningElapsed + MOAN_REPEAT_SECONDS
    end

    local function stopMoaning(active)
        if not active or not active.moaningStarted then return end
        active.moaningStarted = false
        local playerActor = active.playerActor or getDynamicEntity(active.playerActorID)
        local partnerActor = active.partnerActor or getDynamicEntity(active.partnerActorID)
        local bridge = routeBridge()
        if playerActor and partnerActor and bridge then
            pcall(function()
                bridge:StopSceneMoaning(playerActor:GetEntityID(), partnerActor:GetEntityID())
            end)
        end
    end

    local function restoreCamera(active)
        if not active or active.cameraRestored then return end
        active.cameraRestored = true
        local player = Game.GetPlayer()
        if not player then return end
        pcall(function()
            local camera = player:GetFPPCameraComponent()
            camera:SetLocalPosition(Vector4.new(0.0, 0.0, 0.0, 0.0))
            camera:SetLocalOrientation(Quaternion.new(0.0, 0.0, 0.0, 1.0))
        end)

        local mod = active.freeFly
        if mod and active.freeFlyActivatedByScene and mod.runtimeData and mod.runtimeData.active then
            pcall(function()
                mod.runtimeData.active = false
                mod.logic.toggleFlight(mod, false)
            end)
        end
        if mod and active.savedFreeFlyTimeStop ~= nil and mod.settings then
            mod.settings.timeStop = active.savedFreeFlyTimeStop
            if active.freeFlyWasActive and active.savedFreeFlyTimeStop then
                pcall(function() Game.GetTimeSystem():SetTimeDilation("console", 0.000000001) end)
            end
        end
        if mod and active.savedFreeFlySpeed ~= nil and mod.settings then
            mod.settings.speed = active.savedFreeFlySpeed
        end

        -- FreeFly moves the invisible live player to act as the viewing camera.
        -- Return V to the owned bedroom anchor when the scene finishes, unless
        -- FreeFly was already active before this scene and remains user-owned.
        if not active.freeFlyWasActive and active.anchor and active.anchor.position then
            pcall(function()
                local playerPosition = active.anchor.playerPosition or active.anchor.position
                Game.GetTeleportationFacility():Teleport(
                    player,
                    vectorFrom(playerPosition),
                    rotationFrom(active.anchor.rotation)
                )
            end)
        end
    end

    local function restorePlayer(active)
        if not active then return end
        local player = Game.GetPlayer()
        if not player then return end
        if active.playerHidden then
            pcall(function() player:SetInvisible(false) end)
            active.playerHidden = false
        end
        for _, effect in ipairs(active.appliedRestrictions or {}) do
            pcall(function()
                StatusEffectHelper.RemoveStatusEffect(player, effect)
            end)
        end
        active.appliedRestrictions = {}
    end

    local function applyPlayerRestrictions(active)
        local player = Game.GetPlayer()
        if not player then return false end
        active.appliedRestrictions = {}
        for _, name in ipairs(RESTRICTIONS) do
            local effect = TweakDBID.new(name)
            local alreadyApplied = false
            pcall(function()
                alreadyApplied = StatusEffectSystem.ObjectHasStatusEffect(player, effect)
            end)
            if not alreadyApplied then
                local applied = pcall(function()
                    StatusEffectHelper.ApplyStatusEffect(player, effect)
                end)
                if applied then table.insert(active.appliedRestrictions, effect) end
            end
        end
        return true
    end

    local function startFreeFlyView(active)
        local player = Game.GetPlayer()
        if not player then return false end
        local mod = getFreeFly()
        if not mod or type(mod.runtimeData) ~= "table" or type(mod.logic) ~= "table"
            or type(mod.logic.toggleFlight) ~= "function" then
            log("FreeFly diagnostic: getFreeFly() unavailable (mod=" .. tostring(mod) .. ")")
            return false
        end

        active.freeFly = mod
        active.freeFlyWasActive = mod.runtimeData.active == true
        active.savedFreeFlyTimeStop = mod.settings and mod.settings.timeStop or false
        active.savedFreeFlySpeed = mod.settings and mod.settings.speed or nil
        if mod.settings then
            mod.settings.timeStop = false
            if type(mod.settings.speed) ~= "number" or mod.settings.speed < MIN_SCENE_VIEW_SPEED then
                mod.settings.speed = MIN_SCENE_VIEW_SPEED
            end
        end

        local ok = pcall(function()
            local camera = player:GetFPPCameraComponent()
            camera:SetLocalPosition(Vector4.new(0.0, 0.0, 0.0, 0.0))
            camera:SetLocalOrientation(Quaternion.new(0.0, 0.0, 0.0, 1.0))

            local offset = rotationFrom(active.anchor.rotation):ToQuat():Transform(vectorFrom(VIEW_OFFSET))
            local position = Vector4.new(
                active.anchor.position.x + offset.x,
                active.anchor.position.y + offset.y,
                active.anchor.position.z + offset.z,
                active.anchor.position.w or 1.0
            )
            Game.GetTeleportationFacility():Teleport(player, position, rotationFrom(active.anchor.rotation))

            mod.runtimeData.active = true
            mod.logic.toggleFlight(mod, true)
            if not active.freeFlyWasActive then
                active.freeFlyActivatedByScene = true
            else
                Game.GetTimeSystem():UnsetTimeDilation("console")
            end
        end)
        if not ok then return false end
        director.lastEvent = "FreeFly scene view active"
        local tierOK, tier = pcall(function() return player:GetSceneTier() end)
        log(string.format(
            "FreeFly diagnostic: wasActive=%s active=%s inGame=%s inMenu=%s sceneTier=%s savedSpeed=%s speed=%s",
            tostring(active.freeFlyWasActive), tostring(mod.runtimeData.active),
            tostring(mod.runtimeData.inGame), tostring(mod.runtimeData.inMenu),
            tostring(tierOK and tier or "?"), tostring(active.savedFreeFlySpeed),
            tostring(mod.settings and mod.settings.speed)
        ))
        return true
    end

    local function deleteEntities(active)
        director.assembleCallbacks = {}
        director.attachCallbacks = {}
        if active.playerDeviceID then
            pcall(function() Game.GetStaticEntitySystem():DespawnEntity(active.playerDeviceID) end)
        end
        if active.partnerDeviceID then
            pcall(function() Game.GetStaticEntitySystem():DespawnEntity(active.partnerDeviceID) end)
        end
        if active.partnerActorID then
            pcall(function() Game.GetDynamicEntitySystem():DeleteEntity(active.partnerActorID) end)
        end
        if active.playerActorID then
            pcall(function() Game.GetDynamicEntitySystem():DeleteEntity(active.playerActorID) end)
        end
    end

    local function finalizeActive()
        local active = director.active
        if not active then return end
        stopMoaning(active)
        restoreCamera(active)
        restorePlayer(active)
        deleteEntities(active)
        director.result = {
            outcome = active.outcome or "aborted",
            reason = active.stopReason or "scene stopped"
        }
        director.lastEvent = director.result.reason
        director.active = nil
        log("cleanup complete: " .. director.result.reason)
    end

    local function requestStop(reason, outcome)
        local active = director.active
        if not active then return true end
        if active.phase == "stopping" then return true end
        active.stopReason = tostring(reason or "scene stopped")
        active.outcome = tostring(outcome or "aborted")
        stopMoaning(active)
        fastExit(active.playerActor or getDynamicEntity(active.playerActorID))
        fastExit(active.partnerActor or getDynamicEntity(active.partnerActorID))
        restoreCamera(active)
        restorePlayer(active)
        active.phase = "stopping"
        active.stopElapsed = 0.0
        director.lastEvent = active.stopReason
        return true
    end

    local function failActive(message)
        setError(message)
        requestStop("failed: " .. tostring(message), "failed")
        return false
    end

    local function configureDevice(active, role, entity, workspotPath)
        if director.active ~= active or active.phase ~= "spawning" then return end
        local ok, component = pcall(function() return entity:FindComponentByName("workspot") end)
        if not ok or not component then
            failActive(role .. " workspot component did not assemble")
            return
        end
        local configured = pcall(function()
            component.workspotResource = ResRef.FromString(workspotPath)
        end)
        if not configured then
            failActive(role .. " workspot resource could not be assigned")
            return
        end
        active[role .. "Device"] = entity
        active[role .. "Assembled"] = true
    end

    local function spawnDevice(active, role, workspotPath)
        local spec = StaticEntitySpec.new()
        spec.templatePath = WORKSPOT_DEVICE
        spec.position = vectorFrom(active.anchor.position)
        spec.orientation = rotationFrom(active.anchor.rotation):ToQuat()
        spec.attached = true
        local id = Game.GetStaticEntitySystem():SpawnEntity(spec)
        if not id then return nil end
        active[role .. "DeviceID"] = id
        registerCallback(director.assembleCallbacks, id, function(entity)
            configureDevice(active, role, entity, workspotPath)
        end)
        registerCallback(director.attachCallbacks, id, function(entity)
            if director.active ~= active or active.phase ~= "spawning" then return end
            active[role .. "Device"] = entity
            active[role .. "Attached"] = true
        end)
        return id
    end

    local function configurePartnerBehavior(active, entity)
        local ok, detail = pcall(function()
            local player = Game.GetPlayer()
            if not player then error("player is unavailable") end
            local partnerAgent = entity:GetAttitudeAgent()
            local playerAgent = player:GetAttitudeAgent()
            if not partnerAgent or not playerAgent then error("attitude agent is unavailable") end
            partnerAgent:SetAttitudeGroup(CName.new("TygerClaws"))
            partnerAgent:SetAttitudeTowards(playerAgent, EAIAttitude.AIA_Friendly)

            local reaction = entity.reactionComponent
            if reaction then
                local preset = TweakDBInterface.GetReactionPresetRecord(
                    TweakDBID.new("ReactionPresets.NoReaction")
                )
                if preset then reaction:SetReactionPreset(preset) end
            end
        end)
        if not ok then
            failActive((active.partnerLabel or "partner") .. " scene behavior setup failed: " .. tostring(detail))
            return false
        end
        active.partnerBehaviorConfigured = true
        return true
    end

    local function configureNudePartner(active, entity)
        if not active.partnerProfile.usesLizziesBody then
            active.partnerNudeConfigured = true
            active.partnerMeshReady = true
            return true
        end
        local ok, detail = pcall(function()
            local baseComponent = entity:FindComponentByName(PARTNER_BASE_PENIS_COMPONENT)
            if baseComponent then baseComponent:Toggle(false) end

            local erectComponent = entity:FindComponentByName(PARTNER_ERECT_COMPONENT)
            if not erectComponent then error("Lizzie's BDs erect component is missing") end
            erectComponent:Toggle(false)
            erectComponent:ChangeResource(PARTNER_ERECT_MESH)
            erectComponent.chunkMask = 1
            active.partnerErectComponent = erectComponent
        end)
        if not ok then
            failActive("nude " .. (active.partnerLabel or "partner") .. " setup failed: " .. tostring(detail))
            return false
        end
        active.partnerNudeConfigured = true
        return true
    end

    local function configureScenePartner(active, entity)
        if not configurePartnerBehavior(active, entity) then return false end
        return configureNudePartner(active, entity)
    end

    local function refreshNudePartner(active)
        if not active.partnerProfile.usesLizziesBody then
            active.partnerMeshReady = true
            return true
        end
        local ok, detail = pcall(function()
            if not active.partnerErectComponent then error("erect component reference was lost") end
            active.partnerErectComponent:Toggle(false)
            active.partnerErectComponent:Toggle(true)
        end)
        if not ok then
            failActive("nude " .. (active.partnerLabel or "partner") .. " refresh failed: " .. tostring(detail))
            return false
        end
        active.partnerMeshReady = true
        return true
    end

    local function spawnActor(active, role, record, appearance, hiddenOffset)
        local spawnPosition = active.anchor.spawnPosition or active.anchor.position
        local spec = DynamicEntitySpec.new()
        spec.recordID = TweakDBID.new(record)
        if appearance and appearance ~= "" then spec.appearanceName = appearance end
        spec.position = Vector4.new(
            spawnPosition.x,
            spawnPosition.y,
            spawnPosition.z + (hiddenOffset or 0.0),
            spawnPosition.w or 1.0
        )
        spec.orientation = rotationFrom(active.anchor.rotation):ToQuat()
        spec.persistState = false
        spec.persistSpawn = false
        spec.alwaysSpawned = true
        spec.spawnInView = false
        spec.tags = {
            CName.new(role == "player" and "PFKScenePlayer" or "PFKScenePartner"),
            CName.new("PlayingForKeepsJoytoyRoute")
        }
        local id = Game.GetDynamicEntitySystem():CreateEntity(spec)
        if not id then return nil end
        active[role .. "ActorID"] = id
        registerCallback(director.attachCallbacks, id, function(entity)
            if director.active ~= active or active.phase ~= "spawning" then return end
            if role == "partner" and not configureScenePartner(active, entity) then return end
            active[role .. "Actor"] = entity
            active[role .. "ActorAttached"] = true
        end)
        return id
    end

    local function playInDevice(actor, device)
        local ok = pcall(function()
            Game.GetWorkspotSystem():PlayInDeviceSimple(
                device,
                actor,
                false,
                "workspot",
                "",
                "",
                0,
                gameWorkspotSlidingBehaviour.PlayAtResourcePosition
            )
        end)
        return ok
    end

    local function entryState(active)
        local playerActor = active.playerActor or getDynamicEntity(active.playerActorID)
        local partner = active.partnerActor or getDynamicEntity(active.partnerActorID)
        return actorInWorkspot(playerActor), actorInWorkspot(partner), playerActor, partner
    end

    local function requestEntries(active)
        local playerIn, partnerIn, playerActor, partner = entryState(active)
        local playerDevice = active.playerDevice or getStaticEntity(active.playerDeviceID)
        local partnerDevice = active.partnerDevice or getStaticEntity(active.partnerDeviceID)
        if not playerActor or not partner or not playerDevice or not partnerDevice then
            return false, "spawned scene entities are unavailable"
        end
        local playerOK = playerIn or playInDevice(playerActor, playerDevice)
        local partnerOK = partnerIn or playInDevice(partner, partnerDevice)
        active.entryAttempts = (active.entryAttempts or 0) + 1
        if not playerOK or not partnerOK then return false, "workspot entry call failed" end
        log(string.format("workspot entry attempt %d", active.entryAttempts))
        return true
    end

    local function beginWorkspots(active)
        local player = Game.GetPlayer()
        if not player then return failActive("player disappeared before scene start") end
        if not applyPlayerRestrictions(active) then return failActive("player restrictions could not be applied") end
        local hidden = pcall(function() player:SetInvisible(true) end)
        if not hidden then return failActive("live player body could not be hidden") end
        active.playerHidden = true
        if not startFreeFlyView(active) then return failActive("FreeFly scene view could not start") end
        local requested, detail = requestEntries(active)
        if not requested then return failActive(detail) end
        active.phase = "starting"
        active.phaseElapsed = 0.0
        active.nextRetryAt = ENTRY_RETRY_SECONDS
        active.retryAt = nil
        director.lastEvent = "workspot entry requested"
        return true
    end

    function director.preflight(anchor, definition)
        if not initialize() then return false, director.lastError end
        if director.active then return false, "an embedded scene is already active or cleaning up" end
        if type(anchor) ~= "table" or type(anchor.position) ~= "table" or type(anchor.rotation) ~= "table" then
            return false, "Playing for Keeps anchor is incomplete"
        end
        if not resourceExists(WORKSPOT_DEVICE) then
            return false, "base workspot-device resource is missing"
        end
        local scene = normalizeScene(definition)
        local profile = PARTNER_PROFILES[scene.partnerProfile]
        if not resourceExists(scene.playerWorkspot) or not resourceExists(scene.partnerWorkspot) then
            return false, "Pleasures of Night City paired workspots are missing for pose " .. tostring(scene.name)
        end
        local record = playerRecord()
        if not record or not recordExists(record) then return false, "V cutscene-body record is unavailable" end
        if not resourceExists(profile.template) then
            return false, profile.label .. " template is unavailable"
        end
        if profile.usesLizziesBody and not resourceExists(PARTNER_ERECT_MESH) then
            return false, "Lizzie's BDs extra-large erect mesh is unavailable"
        end
        if not recordExists(PARTNER_SOURCE_RECORD) then
            return false, "source Tyger Claw character record is unavailable"
        end
        if not ensurePartnerRecord(profile) then
            return false, "route-owned " .. profile.label .. " character record could not be created"
        end
        if not Game.GetPlayer() then return false, "player is unavailable" end
        local freeFly = getFreeFly()
        if not freeFly or type(freeFly.runtimeData) ~= "table" or type(freeFly.logic) ~= "table"
            or type(freeFly.logic.toggleFlight) ~= "function" then
            return false, "FreeFly 2.4 runtime is unavailable"
        end
        return true, "ready"
    end

    function director.start(anchor, definition)
        local scene = normalizeScene(definition)
        local profile = PARTNER_PROFILES[scene.partnerProfile]
        local allowed, detail = director.preflight(anchor, scene)
        if not allowed then return setError(detail) end
        director.result = nil
        director.lastError = ""
        local active = {
            anchor = anchor,
            scene = scene,
            partnerProfile = profile,
            partnerLabel = profile.label,
            phase = "spawning",
            phaseElapsed = 0.0,
            runningElapsed = 0.0,
            stopElapsed = 0.0,
            cameraRestored = false,
            appliedRestrictions = {}
        }
        director.active = active
        director.lastEvent = "spawning embedded " .. profile.label .. " scene"

        local ok, errorMessage = pcall(function()
            if not spawnDevice(active, "player", active.scene.playerWorkspot) then error("player workspot device spawn failed") end
            if not spawnDevice(active, "partner", active.scene.partnerWorkspot) then error("partner workspot device spawn failed") end
            if not spawnActor(active, "player", playerRecord(), nil, PLAYER_CLONE_HIDDEN_Z_OFFSET) then
                error("V cutscene body spawn failed")
            end
            if not spawnActor(active, "partner", profile.record, profile.appearance, 0.0) then
                error(profile.label .. " partner spawn failed")
            end
        end)
        if not ok then
            failActive(errorMessage)
            return false, tostring(errorMessage)
        end
        log(director.lastEvent)
        return true, "scene spawn started"
    end

    function director.stop(reason, outcome)
        return requestStop(reason or "manual stop", outcome or "aborted")
    end

    function director.shutdown()
        if not director.active then return end
        local active = director.active
        stopMoaning(active)
        fastExit(active.playerActor or getDynamicEntity(active.playerActorID))
        fastExit(active.partnerActor or getDynamicEntity(active.partnerActorID))
        restoreCamera(active)
        restorePlayer(active)
        deleteEntities(active)
        director.active = nil
        director.result = { outcome = "aborted", reason = "session ended" }
    end

    function director.consumeResult()
        local result = director.result
        director.result = nil
        return result
    end

    function director.update(deltaTime)
        local active = director.active
        if not active then return end
        local dt = math.max(0.0, tonumber(deltaTime) or 0.0)

        if active.phase == "stopping" then
            active.stopElapsed = active.stopElapsed + dt
            if active.stopElapsed >= STOP_SETTLE_SECONDS then finalizeActive() end
            return
        end

        active.phaseElapsed = active.phaseElapsed + dt
        if active.phase == "spawning" then
            if not active.playerAssembled then
                local entity = getStaticEntity(active.playerDeviceID)
                if entity then
                    configureDevice(active, "player", entity, active.scene.playerWorkspot)
                    active.playerAttached = true
                end
            end
            if not active.partnerAssembled then
                local entity = getStaticEntity(active.partnerDeviceID)
                if entity then
                    configureDevice(active, "partner", entity, active.scene.partnerWorkspot)
                    active.partnerAttached = true
                end
            end
            if not active.playerActorAttached then
                local entity = getDynamicEntity(active.playerActorID)
                if entity then active.playerActor = entity; active.playerActorAttached = true end
            end
            if not active.partnerActorAttached then
                local entity = getDynamicEntity(active.partnerActorID)
                if entity and configureScenePartner(active, entity) then
                    active.partnerActor = entity
                    active.partnerActorAttached = true
                end
            end
            if active.playerAssembled and active.playerAttached
                and active.partnerAssembled and active.partnerAttached
                and active.playerActorAttached and active.partnerActorAttached
                and active.partnerBehaviorConfigured and active.partnerNudeConfigured then
                active.phase = "settling"
                active.phaseElapsed = 0.0
                director.lastEvent = "scene entities attached"
            elseif active.phaseElapsed >= 8.0 then
                failActive("scene entities did not attach within eight seconds")
            end
            return
        end

        if active.phase == "settling" then
            if not active.partnerMeshReady and active.phaseElapsed >= PARTNER_MESH_REFRESH_SECONDS then
                if not refreshNudePartner(active) then return end
            end
            if active.phaseElapsed >= ENTITY_SETTLE_SECONDS then beginWorkspots(active) end
            return
        end

        local player = Game.GetPlayer()
        local playerIn, partnerIn, playerActor, partner = entryState(active)
        if not player or not playerActor or not partner then
            failActive("player or a scene actor disappeared")
            return
        end

        if active.phase == "starting" then
            if playerIn and partnerIn then
                active.phase = "running"
                active.phaseElapsed = 0.0
                active.runningElapsed = 0.0
                startMoaning(active)
                director.lastEvent = "embedded " .. (active.partnerLabel or "partner") .. " scene running"
                log(director.lastEvent)
            elseif active.phaseElapsed >= ENTRY_TIMEOUT_SECONDS then
                failActive(string.format(
                    "workspot entry timeout (V=%s, %s=%s, attempts=%d)",
                    tostring(playerIn), active.partnerLabel or "partner", tostring(partnerIn), active.entryAttempts or 0
                ))
            elseif active.retryAt and active.phaseElapsed >= active.retryAt then
                active.retryAt = nil
                local requested, retryDetail = requestEntries(active)
                if not requested then failActive(retryDetail) else active.nextRetryAt = active.phaseElapsed + ENTRY_RETRY_SECONDS end
            elseif not active.retryAt and active.phaseElapsed >= (active.nextRetryAt or ENTRY_RETRY_SECONDS) then
                if not playerIn then fastExit(playerActor) end
                if not partnerIn then fastExit(partner) end
                active.retryAt = active.phaseElapsed + ENTRY_RETRY_PAUSE_SECONDS
                active.nextRetryAt = nil
            end
            return
        end

        if active.phase == "running" then
            if not playerIn or not partnerIn then
                requestStop("one actor exited the synchronized workspot", "completed")
                return
            end
            active.runningElapsed = active.runningElapsed + dt
            continueMoaning(active)
            if active.runningElapsed >= active.scene.duration then
                requestStop("scene completed", "completed")
            end
        end
    end

    function director.status()
        local active = director.active
        return {
            initialized = director.initialized,
            lifecycleReady = director.lifecycleReady,
            running = active ~= nil and active.phase ~= "stopping",
            phase = active and active.phase or "idle",
            freeFly = active and active.freeFly ~= nil or false,
            elapsed = active and (active.runningElapsed or 0.0) or 0.0,
            lastError = director.lastError,
            lastEvent = director.lastEvent
        }
    end

    initialize()
    return director
end

function M.get(logger)
    if not singleton then singleton = createDirector(logger) end
    return singleton
end

return M

