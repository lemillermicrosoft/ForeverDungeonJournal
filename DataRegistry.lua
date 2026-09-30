local _, FDJ = ...

local VALID_TYPES = { entrance = true, boss = true, quest = true, shortcut = true, risky = true }

function FDJ:InitializeRegistry()
    self.packs = self.packs or {}
    self.markerIndex = self.markerIndex or { encounter = {}, quest = {}, npc = {} }
end

local function assertString(value, label)
    assert(type(value) == "string" and value ~= "", label .. " must be a non-empty string")
end

function FDJ:RegisterDataPack(pack)
    assert(type(pack) == "table", "data pack must be a table")
    assertString(pack.id, "pack.id")
    assertString(pack.name, "pack.name")
    assertString(pack.version, "pack.version")
    assert(type(pack.dungeons) == "table", "pack.dungeons must be a table")
    assert(not self.packs[pack.id], "duplicate data pack: " .. pack.id)

    for _, dungeon in ipairs(pack.dungeons) do
        assertString(dungeon.id, "dungeon.id")
        assertString(dungeon.name, "dungeon.name")
        assert(type(dungeon.markers) == "table", "dungeon.markers must be a table")
        for _, marker in ipairs(dungeon.markers) do
            assertString(marker.id, "marker.id")
            assertString(marker.label, "marker.label")
            assert(VALID_TYPES[marker.type], "invalid marker type: " .. tostring(marker.type))
            if marker.x then assert(marker.x >= 0 and marker.x <= 1, "marker.x must be normalized") end
            if marker.y then assert(marker.y >= 0 and marker.y <= 1, "marker.y must be normalized") end
            local ref = { pack = pack, dungeon = dungeon, marker = marker }
            if marker.encounterID then self.markerIndex.encounter[marker.encounterID] = ref end
            if marker.questID then self.markerIndex.quest[marker.questID] = ref end
            if marker.npcID then self.markerIndex.npc[marker.npcID] = ref end
        end
    end
    self.packs[pack.id] = pack
    self:Fire("DATA_CHANGED")
end

_G.ForeverDungeonJournalAPI = _G.ForeverDungeonJournalAPI or {}
function _G.ForeverDungeonJournalAPI:RegisterDataPack(pack)
    return FDJ:RegisterDataPack(pack)
end
_G.ForeverDungeonJournalAPI.API_VERSION = 1

function FDJ:GetDungeons()
    local result = {}
    for _, pack in pairs(self.packs) do
        for _, dungeon in ipairs(pack.dungeons) do
            table.insert(result, { pack = pack, dungeon = dungeon })
        end
    end
    table.sort(result, function(a, b) return a.dungeon.name < b.dungeon.name end)
    return result
end

local function record(ref, field, detail)
    if not ref then return end
    FDJ:Reveal(ref.pack.id, ref.dungeon.id, ref.marker.id, "observed")
    local progress = FDJ:GetMarkerProgress(ref.pack.id, ref.dungeon.id, ref.marker.id, true)
    if not progress[field] then progress[field] = time() end
    if detail and not progress.firstLootItem then progress.firstLootItem = detail end
end

function FDJ:Observe(event, ...)
    if event == "BOSS_KILL" then
        local encounterID = ...
        record(self.markerIndex.encounter[encounterID], "firstKill")
    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        record(self.markerIndex.quest[questID], "firstCompleted")
    elseif event == "PLAYER_TARGET_CHANGED" then
        local guid = UnitGUID("target")
        if guid then
            local _, _, _, _, _, npcID = strsplit("-", guid)
            record(self.markerIndex.npc[tonumber(npcID)], "firstSeen")
        end
    elseif event == "ENCOUNTER_LOOT_RECEIVED" then
        local encounterID, itemID, itemLink, _, playerName = ...
        local mine = UnitName("player")
        if playerName == mine or playerName == (mine .. "-" .. GetRealmName()) then
            record(self.markerIndex.encounter[encounterID], "firstLoot", itemLink or ("item:" .. tostring(itemID)))
        end
    end
end

