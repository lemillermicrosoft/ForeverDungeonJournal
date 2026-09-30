local _, FDJ = ...

local function check(parent, label, key, x, y)
    local c = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    c:SetPoint("TOPLEFT", x, y); c.Text:SetText(label)
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
    native:SetPoint("TOPLEFT", 16, -70); native.Text:SetText("Blizzard / native")
    native:SetScript("OnClick", function() FDJ:SetAppearance("blizzard") end)
    local bronze = CreateFrame("CheckButton", nil, panel, "UIRadioButtonTemplate")
    bronze:SetPoint("TOPLEFT", 180, -70); bronze.Text:SetText("Bronze / custom")
    bronze:SetScript("OnClick", function() FDJ:SetAppearance("bronze") end)
    local discovery = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    discovery:SetPoint("TOPLEFT", 16, -104); discovery.Text:SetText("Discovery mode (hide unrevealed content)")
    discovery:SetScript("OnClick", function(self) FDJ.db.settings.discoveryMode = self:GetChecked() and true or false; FDJ:RefreshUI() end)
    local scopeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal"); scopeLabel:SetPoint("TOPLEFT", 16, -144); scopeLabel:SetText("Progress scope")
    local scope = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate,BackdropTemplate"); scope:SetSize(150, 24); scope:SetPoint("TOPLEFT", 16, -164)
    scope.nativeTextures = { scope:GetNormalTexture(), scope:GetPushedTexture(), scope:GetHighlightTexture(), scope:GetDisabledTexture() }
    self.appearanceButtons = self.appearanceButtons or {}; table.insert(self.appearanceButtons, scope)
    scope:SetScript("OnClick", function(self)
        FDJ.db.settings.progressScope = FDJ.db.settings.progressScope == "character" and "account" or "character"
        self:SetText(FDJ.db.settings.progressScope == "character" and "Per character" or "Account-wide"); FDJ:RefreshUI()
    end)
    local filterLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal"); filterLabel:SetPoint("TOPLEFT", 16, -210); filterLabel:SetText("Visible marker types")
    panel.checks = {
        check(panel, "Entrances", "entrance", 16, -232), check(panel, "Bosses", "boss", 16, -260),
        check(panel, "Quests", "quest", 16, -288), check(panel, "Shortcuts", "shortcut", 180, -232),
        check(panel, "Risky pulls", "risky", 180, -260),
    }
    panel.refresh = function()
        native:SetChecked(FDJ.db.settings.appearance == "blizzard")
        bronze:SetChecked(FDJ.db.settings.appearance == "bronze")
        discovery:SetChecked(FDJ.db.settings.discoveryMode)
        scope:SetText(FDJ.db.settings.progressScope == "character" and "Per character" or "Account-wide")
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

