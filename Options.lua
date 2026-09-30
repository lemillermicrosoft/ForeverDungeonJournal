local _, FDJ = ...

local function setControlText(control, text, width)
    local label = control.Text or (control:GetName() and _G[control:GetName() .. "Text"])
    if not label then
        -- Forever omits the standard .Text region on some radio/check
        -- templates. Create an addon-owned label instead of aborting Options.
        label = control:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", control, "RIGHT", 4, 0)
        label:SetJustifyH("LEFT")
        control.FDJText = label
    end
    label:SetText(text)
    label:SetWidth(width or 145)
    return label
end

local function check(parent, label, key, x, y)
    local c = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    c:SetPoint("TOPLEFT", x, y); setControlText(c, label, 120)
    c:SetScript("OnClick", function(self) FDJ.db.settings.show[key] = self:GetChecked() and true or false; FDJ:RefreshUI() end)
    c.key = key; return c
end

function FDJ:InitializeOptions()
    if self.optionsPanel then return end
    local panel = CreateFrame("Frame", "ForeverDungeonJournalOptions", UIParent)
    panel.name = "Forever Dungeon Journal"
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 16, -16); title:SetText(panel.name)
    self.appearanceTitles = self.appearanceTitles or {}; table.insert(self.appearanceTitles, title)
    local presentation = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    presentation:SetPoint("TOPLEFT", 8, -42); presentation:SetSize(430, 310)
    self.appearanceFrames = self.appearanceFrames or {}; table.insert(self.appearanceFrames, presentation)
    local appearanceLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    appearanceLabel:SetPoint("TOPLEFT", 16, -52); appearanceLabel:SetText("Appearance")
    local native = CreateFrame("CheckButton", nil, panel, "UIRadioButtonTemplate")
    native:SetPoint("TOPLEFT", 16, -70); setControlText(native, "Blizzard / native", 140)
    native:SetScript("OnClick", function() FDJ:SetAppearance("blizzard") end)
    local bronze = CreateFrame("CheckButton", nil, panel, "UIRadioButtonTemplate")
    bronze:SetPoint("TOPLEFT", 210, -70); setControlText(bronze, "Bronze / custom", 140)
    bronze:SetScript("OnClick", function() FDJ:SetAppearance("bronze") end)
    local discovery = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    discovery:SetPoint("TOPLEFT", 16, -104); setControlText(discovery, "Discovery mode (hide unrevealed content)", 300)
    discovery:SetScript("OnClick", function(self) FDJ.db.settings.discoveryMode = self:GetChecked() and true or false; FDJ:RefreshUI() end)
    local scopeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal"); scopeLabel:SetPoint("TOPLEFT", 16, -144); scopeLabel:SetText("Progress storage")
    local characterScope = CreateFrame("CheckButton", nil, panel, "UIRadioButtonTemplate")
    characterScope:SetPoint("TOPLEFT", 16, -164); setControlText(characterScope, "Per character", 130)
    characterScope:SetScript("OnClick", function()
        FDJ.db.settings.progressScope = "character"
        FDJ:RefreshUI()
        panel.refresh()
    end)
    local accountScope = CreateFrame("CheckButton", nil, panel, "UIRadioButtonTemplate")
    accountScope:SetPoint("TOPLEFT", 210, -164); setControlText(accountScope, "Account-wide", 130)
    accountScope:SetScript("OnClick", function()
        FDJ.db.settings.progressScope = "account"
        FDJ:RefreshUI()
        panel.refresh()
    end)
    local scopeHelp = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    scopeHelp:SetPoint("TOPLEFT", 16, -188); scopeHelp:SetText("Choose one place to store discoveries and notes.")
    local filterLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal"); filterLabel:SetPoint("TOPLEFT", 16, -220); filterLabel:SetText("Visible marker types")
    panel.checks = {
        check(panel, "Entrances", "entrance", 16, -242), check(panel, "Bosses", "boss", 16, -270),
        check(panel, "Quests", "quest", 16, -298), check(panel, "Shortcuts", "shortcut", 180, -242),
        check(panel, "Risky pulls", "risky", 180, -270),
    }
    panel.refresh = function()
        native:SetChecked(FDJ.db.settings.appearance == "blizzard")
        bronze:SetChecked(FDJ.db.settings.appearance == "bronze")
        discovery:SetChecked(FDJ.db.settings.discoveryMode)
        characterScope:SetChecked(FDJ.db.settings.progressScope == "character")
        accountScope:SetChecked(FDJ.db.settings.progressScope == "account")
        for _, c in ipairs(panel.checks) do c:SetChecked(FDJ.db.settings.show[c.key]) end
    end
    panel:SetScript("OnShow", panel.refresh)
    self:On("APPEARANCE_CHANGED", panel.refresh)
    local registered = false
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function" and type(Settings.RegisterAddOnCategory) == "function" then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, panel.name)
        if ok and category then
            local addOK = pcall(Settings.RegisterAddOnCategory, category)
            if addOK then
                local idOK, categoryID = pcall(category.GetID, category)
                self.optionsCategory = idOK and categoryID or category
                registered = true
            end
        end
    end
    if not registered and type(InterfaceOptions_AddCategory) == "function" then
        local ok = pcall(InterfaceOptions_AddCategory, panel)
        if ok then self.optionsCategory = panel; registered = true end
    end
    self.optionsPanel = panel
    self:ApplyAppearance()
    if not registered then self:Message("Could not register the AddOns options category; use /fdj and report this client build.") end
end

function FDJ:OpenOptions()
    if Settings and type(Settings.OpenToCategory) == "function" and type(self.optionsCategory) ~= "table" then
        if pcall(Settings.OpenToCategory, self.optionsCategory) then return end
    end
    if type(InterfaceOptionsFrame_OpenToCategory) == "function" and self.optionsPanel then
        pcall(InterfaceOptionsFrame_OpenToCategory, self.optionsPanel)
        pcall(InterfaceOptionsFrame_OpenToCategory, self.optionsPanel)
    else
        self:Message("Options are unavailable on this client build.")
    end
end

