local _, FDJ = ...

local ACCOUNT_DEFAULTS = {
    schema = 2,
    settings = {
        appearance = "blizzard",
        discoveryMode = true,
        progressScope = "character",
        show = { entrance = true, boss = true, quest = true, shortcut = true, risky = true },
    },
    progress = {},
    annotations = {},
    generalNotes = "",
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
    local existingAccount = type(ForeverDungeonJournalDB) == "table"
    if not existingAccount then ForeverDungeonJournalDB = {} end
    if type(ForeverDungeonJournalCharDB) ~= "table" then ForeverDungeonJournalCharDB = {} end
    if type(ForeverDungeonJournalDB.settings) ~= "table" then ForeverDungeonJournalDB.settings = {} end

    -- Appearance was not user-selectable before schema 2, so missing values
    -- migrate to the product-wide Blizzard/native default. An explicit bronze
    -- selection made after this migration remains untouched.
    local oldSchema = tonumber(ForeverDungeonJournalDB.schema) or (existingAccount and 1 or 0)
    if oldSchema < 2 then
        if ForeverDungeonJournalDB.settings.appearance == nil then
            ForeverDungeonJournalDB.settings.appearance = "blizzard"
        end
        -- Seed onboarding metadata only during this migration. It is not a
        -- recurring default, so later user changes are never replaced.
        if ForeverDungeonJournalDB.settings.onboardingVersion == nil then
            ForeverDungeonJournalDB.settings.onboardingVersion = 1
        end
        ForeverDungeonJournalDB.schema = 2
    end

    -- Repair malformed saved variables before recursively filling nil values.
    -- Empty strings and all other user values remain untouched.
    if type(ForeverDungeonJournalDB.settings.show) ~= "table" then ForeverDungeonJournalDB.settings.show = {} end
    if type(ForeverDungeonJournalDB.progress) ~= "table" then ForeverDungeonJournalDB.progress = {} end
    if type(ForeverDungeonJournalDB.annotations) ~= "table" then ForeverDungeonJournalDB.annotations = {} end
    if type(ForeverDungeonJournalCharDB.progress) ~= "table" then ForeverDungeonJournalCharDB.progress = {} end
    if type(ForeverDungeonJournalCharDB.annotations) ~= "table" then ForeverDungeonJournalCharDB.annotations = {} end
    copyDefaults(ForeverDungeonJournalDB, ACCOUNT_DEFAULTS)
    copyDefaults(ForeverDungeonJournalCharDB, CHARACTER_DEFAULTS)
    if ForeverDungeonJournalDB.settings.appearance ~= "blizzard" and ForeverDungeonJournalDB.settings.appearance ~= "bronze" then
        ForeverDungeonJournalDB.settings.appearance = "blizzard"
    end
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
    if not progress.revealedAt then progress.revealedAt = time() end
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

