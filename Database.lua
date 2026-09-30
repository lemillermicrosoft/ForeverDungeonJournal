local _, FDJ = ...

local ACCOUNT_DEFAULTS = {
    schema = 1,
    settings = {
        discoveryMode = true,
        progressScope = "character",
        show = { entrance = true, boss = true, quest = true, shortcut = true, risky = true },
    },
    progress = {},
    annotations = {},
}

local CHARACTER_DEFAULTS = { schema = 1, progress = {}, annotations = {} }

local function copyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                copyDefaults(target[key], value)
            else target[key] = value end
        elseif type(value) == "table" and type(target[key]) == "table" then
            copyDefaults(target[key], value)
        end
    end
end

function FDJ:InitializeDatabase()
    ForeverDungeonJournalDB = ForeverDungeonJournalDB or {}
    ForeverDungeonJournalCharDB = ForeverDungeonJournalCharDB or {}
    copyDefaults(ForeverDungeonJournalDB, ACCOUNT_DEFAULTS)
    copyDefaults(ForeverDungeonJournalCharDB, CHARACTER_DEFAULTS)
    self.db = ForeverDungeonJournalDB
    self.charDB = ForeverDungeonJournalCharDB
end

function FDJ:GetStore()
    if self.db.settings.progressScope == "account" then return self.db end
    return self.charDB
end

function FDJ:GetMarkerProgress(packID, dungeonID, markerID, create)
    local store = self:GetStore()
    if create then
        store.progress[packID] = store.progress[packID] or {}
        store.progress[packID][dungeonID] = store.progress[packID][dungeonID] or {}
        store.progress[packID][dungeonID][markerID] = store.progress[packID][dungeonID][markerID] or {}
    end
    return store.progress[packID] and store.progress[packID][dungeonID] and store.progress[packID][dungeonID][markerID]
end

function FDJ:Reveal(packID, dungeonID, markerID, source)
    local progress = self:GetMarkerProgress(packID, dungeonID, markerID, true)
    if not progress.firstSeen then progress.firstSeen = time() end
    progress.revealed = true
    progress.revealSource = progress.revealSource or source or "manual"
    self:Fire("PROGRESS_CHANGED")
end

function FDJ:SetAnnotation(packID, dungeonID, markerID, note)
    local store = self:GetStore()
    store.annotations[packID] = store.annotations[packID] or {}
    store.annotations[packID][dungeonID] = store.annotations[packID][dungeonID] or {}
    store.annotations[packID][dungeonID][markerID] = note ~= "" and note or nil
    self:Fire("PROGRESS_CHANGED")
end

function FDJ:GetAnnotation(packID, dungeonID, markerID)
    local store = self:GetStore()
    return store.annotations[packID] and store.annotations[packID][dungeonID] and store.annotations[packID][dungeonID][markerID] or ""
end

