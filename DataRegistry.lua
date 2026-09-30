local _, FDJ = ...

local VALID_TYPES = { entrance = true, boss = true, quest = true, shortcut = true, risky = true }
local VALID_VERIFICATION = { verified = true, client = true, community = true, unconfirmed = true }

function FDJ:InitializeRegistry()
    self.packs = self.packs or {}
    self.packErrors = self.packErrors or {}
    self.markerIndex = self.markerIndex or { encounter = {}, quest = {} }
end

local function fail(label, message) error(label .. " " .. message, 0) end
local function stringField(value, label)
    if type(value) ~= "string" or value == "" then fail(label, "must be a non-empty string") end
end
local function integer(value) return type(value) == "number" and value > 0 and value == math.floor(value) end
local function normalized(value) return type(value) == "number" and value >= 0 and value <= 1 end
local function denseArray(value, label, allowEmpty)
    if type(value) ~= "table" then fail(label, "must be a table") end
    local count = 0
    for key in pairs(value) do
        if not integer(key) then fail(label, "must be a dense array") end
        count = count + 1
    end
    if count ~= #value then fail(label, "must be a dense array") end
    if not allowEmpty and count == 0 then fail(label, "must not be empty") end
end

local function validateSource(source, label)
    if type(source) ~= "table" then fail(label, "must be a table") end
    stringField(source.title, label .. ".title")
    stringField(source.kind, label .. ".kind")
    stringField(source.checked, label .. ".checked")
    if source.url ~= nil then stringField(source.url, label .. ".url") end
    if source.revision ~= nil then stringField(source.revision, label .. ".revision") end
end

local function validatePack(pack)
    if type(pack) ~= "table" then fail("data pack", "must be a table") end
    stringField(pack.id, "pack.id"); stringField(pack.name, "pack.name"); stringField(pack.version, "pack.version")
    stringField(pack.build, "pack.build"); stringField(pack.license, "pack.license")
    if not VALID_VERIFICATION[pack.verification] then fail("pack.verification", "is invalid") end
    denseArray(pack.sources, "pack.sources", false)
    for i, source in ipairs(pack.sources) do validateSource(source, "pack.sources[" .. i .. "]") end
    denseArray(pack.dungeons, "pack.dungeons", true)

    local dungeonIDs, markerIDs, encounterIDs, questIDs = {}, {}, {}, {}
    for di, dungeon in ipairs(pack.dungeons) do
        local prefix = "pack.dungeons[" .. di .. "]"
        stringField(dungeon.id, prefix .. ".id"); stringField(dungeon.name, prefix .. ".name")
        if dungeonIDs[dungeon.id] then fail(prefix .. ".id", "is duplicated") end
        dungeonIDs[dungeon.id] = true
        if dungeon.instanceID ~= nil and not integer(dungeon.instanceID) then fail(prefix .. ".instanceID", "must be a positive integer") end
        if dungeon.mapID ~= nil and not integer(dungeon.mapID) then fail(prefix .. ".mapID", "must be a positive integer") end
        if dungeon.floor ~= nil and not integer(dungeon.floor) then fail(prefix .. ".floor", "must be a positive integer") end
        if dungeon.verification and not VALID_VERIFICATION[dungeon.verification] then fail(prefix .. ".verification", "is invalid") end
        if dungeon.description ~= nil and type(dungeon.description) ~= "string" then fail(prefix .. ".description", "must be a string") end
        if dungeon.map ~= nil then
            if type(dungeon.map) ~= "table" then fail(prefix .. ".map", "must be a table") end
            local textureType = type(dungeon.map.texture)
            if textureType ~= "string" and textureType ~= "number" then fail(prefix .. ".map.texture", "must be a texture path or file ID") end
            if textureType == "string" and dungeon.map.texture == "" then fail(prefix .. ".map.texture", "must not be empty") end
            if textureType == "number" and not integer(dungeon.map.texture) then fail(prefix .. ".map.texture", "must be a positive integer file ID") end
        end
        denseArray(dungeon.markers, prefix .. ".markers", true)
        for mi, marker in ipairs(dungeon.markers) do
            local mp = prefix .. ".markers[" .. mi .. "]"
            stringField(marker.id, mp .. ".id"); stringField(marker.label, mp .. ".label")
            if markerIDs[marker.id] then fail(mp .. ".id", "is duplicated in pack") end
            markerIDs[marker.id] = true
            if not VALID_TYPES[marker.type] then fail(mp .. ".type", "is invalid") end
            if (marker.x == nil) ~= (marker.y == nil) then fail(mp, "must provide x and y together") end
            if marker.x ~= nil and (not normalized(marker.x) or not normalized(marker.y)) then fail(mp, "coordinates must be normalized") end
            if marker.encounterID ~= nil and not integer(marker.encounterID) then fail(mp .. ".encounterID", "must be a positive integer") end
            if marker.questID ~= nil and not integer(marker.questID) then fail(mp .. ".questID", "must be a positive integer") end
            if marker.description ~= nil and type(marker.description) ~= "string" then fail(mp .. ".description", "must be a string") end
            if marker.encounterID and encounterIDs[marker.encounterID] then fail(mp .. ".encounterID", "is duplicated in pack") end
            if marker.questID and questIDs[marker.questID] then fail(mp .. ".questID", "is duplicated in pack") end
            if marker.encounterID then encounterIDs[marker.encounterID] = true end
            if marker.questID then questIDs[marker.questID] = true end
            if marker.verification and not VALID_VERIFICATION[marker.verification] then fail(mp .. ".verification", "is invalid") end
        end
    end
end

function FDJ:RegisterDataPack(pack)
    self:InitializeRegistry()
    local ok, problem = pcall(validatePack, pack)
    if not ok then
        table.insert(self.packErrors, tostring(problem))
        error(problem, 0)
    end
    if self.packs[pack.id] then
        local problem = "duplicate data pack: " .. pack.id
        table.insert(self.packErrors, problem); error(problem, 0)
    end

    -- Commit only after complete validation, so malformed packs cannot partially poison indexes.
    self.packs[pack.id] = pack
    for _, dungeon in ipairs(pack.dungeons) do
        for _, marker in ipairs(dungeon.markers) do
            local ref = { pack = pack, dungeon = dungeon, marker = marker }
            if marker.encounterID then
                self.markerIndex.encounter[marker.encounterID] = self.markerIndex.encounter[marker.encounterID] or {}
                table.insert(self.markerIndex.encounter[marker.encounterID], ref)
            end
            if marker.questID then
                self.markerIndex.quest[marker.questID] = self.markerIndex.quest[marker.questID] or {}
                table.insert(self.markerIndex.quest[marker.questID], ref)
            end
        end
    end
    self:Fire("DATA_CHANGED")
end

_G.ForeverDungeonJournalAPI = _G.ForeverDungeonJournalAPI or {}
function _G.ForeverDungeonJournalAPI:RegisterDataPack(pack) return FDJ:RegisterDataPack(pack) end
_G.ForeverDungeonJournalAPI.API_VERSION = 2

function FDJ:GetDungeons()
    local result = {}
    for _, pack in pairs(self.packs) do
        for _, dungeon in ipairs(pack.dungeons) do table.insert(result, { pack = pack, dungeon = dungeon }) end
    end
    table.sort(result, function(a, b)
        local an, bn = string.lower(a.dungeon.name), string.lower(b.dungeon.name)
        if an == bn then return a.pack.id < b.pack.id end
        return an < bn
    end)
    return result
end

function FDJ:GetDiagnostics()
    local diagnostics = { packs = 0, dungeons = 0, markers = 0, errors = #self.packErrors, integrations = self.integrations or {} }
    for _, pack in pairs(self.packs) do
        diagnostics.packs = diagnostics.packs + 1
        diagnostics.dungeons = diagnostics.dungeons + #pack.dungeons
        for _, dungeon in ipairs(pack.dungeons) do diagnostics.markers = diagnostics.markers + #dungeon.markers end
    end
    return diagnostics
end

local function isSafeNumber(value)
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret then return false end
    end
    return type(value) == "number"
end

local function record(refs, field)
    if not refs then return end
    for _, ref in ipairs(refs) do
        FDJ:Reveal(ref.pack.id, ref.dungeon.id, ref.marker.id, "observed")
        local progress = FDJ:GetMarkerProgress(ref.pack.id, ref.dungeon.id, ref.marker.id, true)
        if not progress[field] then progress[field] = time() end
    end
end

function FDJ:Observe(event, ...)
    local observedID = ...
    if not isSafeNumber(observedID) then return end
    if event == "BOSS_KILL" then record(self.markerIndex.encounter[observedID], "firstKill")
    elseif event == "QUEST_TURNED_IN" then record(self.markerIndex.quest[observedID], "firstCompleted") end
end
