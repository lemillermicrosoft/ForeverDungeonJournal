local ADDON, FDJ = ...

FDJ.name = ADDON
FDJ.version = "0.1.0-alpha"
FDJ.events = CreateFrame("Frame")
FDJ.callbacks = {}

local function message(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc89b3cForever Dungeon Journal:|r " .. tostring(text))
end
FDJ.Message = message

function FDJ:On(event, callback)
    self.callbacks[event] = self.callbacks[event] or {}
    table.insert(self.callbacks[event], callback)
end

function FDJ:Fire(event, ...)
    local listeners = self.callbacks[event]
    if not listeners then return end
    for _, callback in ipairs(listeners) do callback(...) end
end

FDJ.events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded ~= ADDON then return end
        FDJ:InitializeDatabase()
        FDJ:InitializeRegistry()
        FDJ:InitializeUI()
        FDJ:InitializeOptions()
        FDJ:RefreshUI()
        message("loaded. Type /fdj to open.")
        return
    end
    FDJ:Observe(event, ...)
end)

FDJ.events:RegisterEvent("ADDON_LOADED")
local function registerOptionalEvent(event)
    pcall(FDJ.events.RegisterEvent, FDJ.events, event)
end
registerOptionalEvent("BOSS_KILL")
registerOptionalEvent("ENCOUNTER_LOOT_RECEIVED")
registerOptionalEvent("QUEST_TURNED_IN")
registerOptionalEvent("PLAYER_TARGET_CHANGED")

SLASH_FOREVERDUNGEONJOURNAL1 = "/fdj"
SLASH_FOREVERDUNGEONJOURNAL2 = "/foreverjournal"
SlashCmdList.FOREVERDUNGEONJOURNAL = function(input)
    input = strtrim(input or "")
    if input == "resetwindow" then
        FDJ.db.window = nil
        message("window position reset.")
    elseif input == "help" then
        message("/fdj — open; /fdj resetwindow — reset position")
    else
        FDJ:ToggleUI()
    end
end

