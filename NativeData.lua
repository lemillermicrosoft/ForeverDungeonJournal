local _, FDJ = ...

local function callResult(ok, ...)
    if not ok then return nil end
    return ...
end

local function safeCall(func, ...)
    if type(func) ~= "function" then return nil end
    return callResult(pcall(func, ...))
end

local function addonLoaded(name)
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then return safeCall(C_AddOns.IsAddOnLoaded, name) and true or false end
    if type(IsAddOnLoaded) == "function" then return safeCall(IsAddOnLoaded, name) and true or false end
    return false
end

function FDJ:DetectIntegrations()
    self.integrations = {
        Atlas = addonLoaded("Atlas"),
        AtlasLoot = addonLoaded("AtlasLoot") or addonLoaded("AtlasLootClassic"),
        HandyNotes = addonLoaded("HandyNotes"),
        Questie = addonLoaded("Questie"),
    }
end

local function getInstance(index)
    if type(EJ_GetInstanceByIndex) ~= "function" then return nil end
    local instanceID, name, description, background, button, lore, _, mapID = safeCall(EJ_GetInstanceByIndex, index, false)
    if type(instanceID) ~= "number" or type(name) ~= "string" or name == "" then return nil end
    return {
        instanceID = instanceID, name = name, description = description,
        background = background, button = button, lore = lore, mapID = tonumber(mapID),
    }
end

local function scanEncounters(instance)
    local markers = {}
    if type(EJ_GetEncounterInfoByIndex) ~= "function" then return markers end
    for index = 1, 100 do
        local name, description, encounterID, _, _, _, _, mapID = safeCall(EJ_GetEncounterInfoByIndex, index, instance.instanceID)
        if type(name) ~= "string" or name == "" then break end
        if type(encounterID) == "number" and encounterID > 0 then
            table.insert(markers, {
                id = "encounter-" .. encounterID, type = "boss", label = name,
                encounterID = encounterID,
                description = type(description) == "string" and description ~= "" and description or "Encounter reported by the installed Forever client.",
                verification = "client",
                mapID = type(mapID) == "number" and mapID or nil,
            })
        end
    end
    return markers
end

function FDJ:RegisterNativeData()
    self:DetectIntegrations()
    if type(EJ_GetNumInstances) ~= "function" and C_AddOns and type(C_AddOns.LoadAddOn) == "function" then pcall(C_AddOns.LoadAddOn, "Blizzard_EncounterJournal") end
    if type(EJ_GetNumInstances) ~= "function" or type(EJ_GetInstanceByIndex) ~= "function" then
        self.nativeDataStatus = "Encounter Journal API unavailable on this client/build."
        return
    end
    local dungeons, seen = {}, {}
    local originalTier = tonumber(safeCall(EJ_GetCurrentTier))
    local tierCount = tonumber(safeCall(EJ_GetNumTiers)) or 1
    for tier = 1, math.max(1, tierCount) do
        if type(EJ_SelectTier) == "function" then safeCall(EJ_SelectTier, tier) end
        local count = tonumber(safeCall(EJ_GetNumInstances, false)) or 0
        for index = 1, math.min(count, 200) do
            local instance = getInstance(index)
            if instance and not seen[instance.instanceID] then
                seen[instance.instanceID] = true
                local markers = scanEncounters(instance)
                table.insert(dungeons, {
                    id = "instance-" .. instance.instanceID,
                    name = instance.name,
                    instanceID = instance.instanceID,
                    mapID = instance.mapID,
                    description = type(instance.description) == "string" and instance.description or nil,
                    verification = "client",
                    map = (type(instance.background) == "number" or type(instance.background) == "string") and { texture = instance.background, kind = "encounter-journal" } or nil,
                    markers = markers,
                    unknowns = {
                        entrances = "No verified entrance coordinates were reported by the Encounter Journal API.",
                        quests = "Quest associations require a verified external data pack or Questie integration.",
                        routes = "Shortcuts and risky pulls require authored in-client verification.",
                    },
                })
            end
        end
    end
    if originalTier and type(EJ_SelectTier) == "function" then safeCall(EJ_SelectTier, originalTier) end
    if #dungeons == 0 then
        self.nativeDataStatus = "Encounter Journal returned no dungeon instances for this character/client state."
        return
    end
    local version, build = safeCall(GetBuildInfo)
    local pack = {
        id = "fdj.native.forever", name = "Forever client Encounter Journal", version = tostring(version or build or "runtime"),
        build = tostring(build or version or "Interface 16001"), license = "Runtime API metadata; no third-party database or assets redistributed",
        verification = "client",
        sources = {{ title = "Installed WoW Forever Encounter Journal API", kind = "client-runtime", checked = date("%Y-%m-%d"), revision = tostring(build or "unknown") }},
        dungeons = dungeons,
    }
    local ok, problem = pcall(self.RegisterDataPack, self, pack)
    if ok then self.nativeDataStatus = "Loaded " .. #dungeons .. " client-reported dungeons."
    else self.nativeDataStatus = "Native data rejected: " .. tostring(problem) end
end

function FDJ:OpenDungeonMap(dungeon)
    if not dungeon or type(dungeon.mapID) ~= "number" then
        self:Message("No verified world-map reference is available for this dungeon.")
        return
    end
    if C_Map and type(C_Map.OpenWorldMap) == "function" then
        local ok = pcall(C_Map.OpenWorldMap, dungeon.mapID)
        if ok then return end
    end
    if WorldMapFrame and type(WorldMapFrame.SetMapID) == "function" then
        local ok = pcall(WorldMapFrame.SetMapID, WorldMapFrame, dungeon.mapID)
        if ok and type(ToggleWorldMap) == "function" then pcall(ToggleWorldMap); return end
    end
    self:Message("Map " .. dungeon.mapID .. " is verified, but this client exposes no supported map opener.")
end
