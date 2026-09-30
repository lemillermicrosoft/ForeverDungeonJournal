local ADDON, FDJ = ...

FDJ.name = ADDON
FDJ.version = "0.2.0-alpha.1"
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
        FDJ:RegisterNativeData()
        -- Register Options before creating the main window so a client-specific
        -- widget failure cannot hide the addon's configuration category.
        local optionsOK, optionsError = pcall(FDJ.InitializeOptions, FDJ)
        if not optionsOK then message("Options registration failed: " .. tostring(optionsError)) end
        local uiOK, uiError = pcall(FDJ.InitializeUI, FDJ)
        if uiOK then
            FDJ:RefreshUI()
        else
            message("Window creation failed: " .. tostring(uiError))
        end
        message("Loaded. Type /fdj to open or /fdj help for commands. Configuration: Esc > Options > AddOns > Forever Dungeon Journal.")
        return
    end
    FDJ:Observe(event, ...)
end)

FDJ.events:RegisterEvent("ADDON_LOADED")
local function registerOptionalEvent(event)
    pcall(FDJ.events.RegisterEvent, FDJ.events, event)
end
registerOptionalEvent("BOSS_KILL")
registerOptionalEvent("QUEST_TURNED_IN")

SLASH_FOREVERDUNGEONJOURNAL1 = "/fdj"
SLASH_FOREVERDUNGEONJOURNAL2 = "/foreverjournal"
SlashCmdList.FOREVERDUNGEONJOURNAL = function(input)
    input = strtrim(input or "")
    if input == "resetwindow" then
        FDJ.db.window = nil
        if FDJ.frame then FDJ:ResetWindowPosition() end
        message("window position reset.")
    elseif input == "diagnostics" then
        local d = FDJ:GetDiagnostics()
        message(string.format("v%s; %d pack(s), %d dungeon(s), %d marker(s), %d rejected pack(s).", FDJ.version, d.packs, d.dungeons, d.markers, d.errors))
        message(FDJ.nativeDataStatus or "Native data provider has no status.")
        for name, loaded in pairs(d.integrations) do message(name .. ": " .. (loaded and "loaded" or "not loaded")) end
    elseif input == "help" then
        message("/fdj — open; /fdj diagnostics — pack/integration status; /fdj resetwindow — reset position")
    else
        FDJ:ToggleUI()
    end
end

