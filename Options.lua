local _, FDJ = ...

local function check(parent, label, key, x, y)
    local c = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    c:SetPoint("TOPLEFT", x, y); c.Text:SetText(label)
    c:SetScript("OnClick", function(self) FDJ.db.settings.show[key] = self:GetChecked() and true or false; FDJ:RefreshUI() end)
    c.key = key; return c
end

function FDJ:InitializeOptions()
    local panel = CreateFrame("Frame")
    panel.name = "Forever Dungeon Journal"
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 16, -16); title:SetText(panel.name)
    local discovery = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    discovery:SetPoint("TOPLEFT", 16, -52); discovery.Text:SetText("Discovery mode (hide unrevealed content)")
    discovery:SetScript("OnClick", function(self) FDJ.db.settings.discoveryMode = self:GetChecked() and true or false; FDJ:RefreshUI() end)
    local scopeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal"); scopeLabel:SetPoint("TOPLEFT", 16, -92); scopeLabel:SetText("Progress scope")
    local scope = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"); scope:SetSize(150, 24); scope:SetPoint("TOPLEFT", 16, -112)
    scope:SetScript("OnClick", function(self)
        FDJ.db.settings.progressScope = FDJ.db.settings.progressScope == "character" and "account" or "character"
        self:SetText(FDJ.db.settings.progressScope == "character" and "Per character" or "Account-wide"); FDJ:RefreshUI()
    end)
    local filterLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal"); filterLabel:SetPoint("TOPLEFT", 16, -158); filterLabel:SetText("Visible marker types")
    panel.checks = {
        check(panel, "Entrances", "entrance", 16, -180), check(panel, "Bosses", "boss", 16, -208),
        check(panel, "Quests", "quest", 16, -236), check(panel, "Shortcuts", "shortcut", 180, -180),
        check(panel, "Risky pulls", "risky", 180, -208),
    }
    panel.refresh = function()
        discovery:SetChecked(FDJ.db.settings.discoveryMode)
        scope:SetText(FDJ.db.settings.progressScope == "character" and "Per character" or "Account-wide")
        for _, c in ipairs(panel.checks) do c:SetChecked(FDJ.db.settings.show[c.key]) end
    end
    panel:SetScript("OnShow", panel.refresh)
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
        if ok then self.optionsCategory = panel end
    end
    self.optionsPanel = panel
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

