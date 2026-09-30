local _, FDJ = ...

local VALID_TYPES = { entrance = true, boss = true, quest = true, shortcut = true, risky = true }

function FDJ:InitializeRegistry()
    self.packs = self.packs or {}
    self.markerIndex = self.markerIndex or { encounter = {}, quest = {} }
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

local function isSafeNumber(value)
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret then return false end
    end
    return type(value) == "number"
end

local function record(ref, field)
    if not ref then return end
    FDJ:Reveal(ref.pack.id, ref.dungeon.id, ref.marker.id, "observed")
    local progress = FDJ:GetMarkerProgress(ref.pack.id, ref.dungeon.id, ref.marker.id, true)
    if not progress[field] then progress[field] = time() end
end

function FDJ:Observe(event, ...)
    local observedID = ...
    if not isSafeNumber(observedID) then return end
    if event == "BOSS_KILL" then
        record(self.markerIndex.encounter[observedID], "firstKill")
    elseif event == "QUEST_TURNED_IN" then
        record(self.markerIndex.quest[observedID], "firstCompleted")
    end
end

