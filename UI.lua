local _, FDJ = ...

local TYPE_LABELS = { entrance = "Entrance", boss = "Boss", quest = "Quest", shortcut = "Shortcut", risky = "Risky pull" }
local TYPE_COLORS = { entrance = {0.25, 0.85, 1}, boss = {1, 0.3, 0.2}, quest = {1, 0.82, 0.2}, shortcut = {0.35, 1, 0.45}, risky = {1, 0.45, 0.05} }
local BRONZE = { 0.78, 0.57, 0.25 }
local BLIZZARD_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 11, top = 11, bottom = 11 },
}
local BRONZE_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local NATIVE_INNER_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function applyBackdrop(frame, appearance)
    if appearance == "bronze" then
        frame:SetBackdrop(BRONZE_BACKDROP)
        frame:SetBackdropColor(0.045, 0.035, 0.025, 0.96)
        frame:SetBackdropBorderColor(unpack(BRONZE))
    elseif frame._fdjMain then
        -- Match DPSPulse Forever: one warm native outer frame, rather than a
        -- stack of bright silver dialog borders around every child panel.
        frame:SetBackdrop(BLIZZARD_BACKDROP)
        frame:SetBackdropColor(0.30, 0.20, 0.11, 1)
        frame:SetBackdropBorderColor(0.72, 0.47, 0.20, 1)
    else
        frame:SetBackdrop(NATIVE_INNER_BACKDROP)
        frame:SetBackdropColor(0.055, 0.032, 0.018, 0.94)
        frame:SetBackdropBorderColor(0.72, 0.47, 0.16, 0.58)
    end
end

local function button(parent, text, width)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate,BackdropTemplate")
    b:SetSize(width or 100, 24); b:SetText(text)
    FDJ.appearanceButtons = FDJ.appearanceButtons or {}
    table.insert(FDJ.appearanceButtons, b)
    return b
end

local function tint(texture, r, g, b, a)
    if texture and texture.SetVertexColor then texture:SetVertexColor(r, g, b, a or 1) end
end

function FDJ:SetAppearance(appearance)
    if appearance ~= "bronze" then appearance = "blizzard" end
    self.db.settings.appearance = appearance
    self:ApplyAppearance()
    self:RefreshUI()
    self:Fire("APPEARANCE_CHANGED", appearance)
end

function FDJ:ApplyAppearance()
    if not self.db or not self.db.settings then return end
    local appearance = self.db.settings.appearance == "bronze" and "bronze" or "blizzard"
    for _, frame in ipairs(self.appearanceFrames or {}) do applyBackdrop(frame, appearance) end
    for _, b in ipairs(self.appearanceButtons or {}) do
        b:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        b:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
        b:SetDisabledTexture("Interface\\Buttons\\WHITE8X8")
        b:SetHighlightTexture("Interface\\Buttons\\WHITE8X8", "ADD")
        if appearance == "bronze" then
            tint(b:GetNormalTexture(), 0.22, 0.12, 0.045); tint(b:GetPushedTexture(), 0.12, 0.06, 0.02)
            tint(b:GetDisabledTexture(), 0.08, 0.07, 0.06, 0.65); tint(b:GetHighlightTexture(), 0.72, 0.47, 0.16, 0.28)
        else
            tint(b:GetNormalTexture(), 0.16, 0.085, 0.025); tint(b:GetPushedTexture(), 0.09, 0.045, 0.015)
            tint(b:GetDisabledTexture(), 0.07, 0.06, 0.05, 0.65); tint(b:GetHighlightTexture(), 0.88, 0.62, 0.28, 0.32)
        end
        b:SetBackdrop(NATIVE_INNER_BACKDROP)
        b:SetBackdropColor(0.055, 0.032, 0.018, 1)
        b:SetBackdropBorderColor(0.72, 0.47, 0.16, 0.78)
        local font = b:GetFontString(); if font then font:SetTextColor(1, 0.82, 0.20) end
    end
    for _, title in ipairs(self.appearanceTitles or {}) do
        if appearance == "bronze" then title:SetTextColor(unpack(BRONZE)) else title:SetTextColor(1, 0.82, 0.20) end
    end
    if self.nativeHeader then
        self.nativeHeader:SetShown(appearance == "blizzard")
        self.nativeHeaderHighlight:SetShown(appearance == "blizzard")
        self.nativeHeaderAccent:SetShown(appearance == "blizzard")
        self.nativeHeaderShadow:SetShown(appearance == "blizzard")
    end
end

function FDJ:InitializeUI()
    local f = CreateFrame("Frame", "ForeverDungeonJournalFrame", UIParent, "BackdropTemplate")
    f:SetSize(820, 560); f:SetPoint("CENTER"); f:SetMovable(true); f:SetClampedToScreen(true)
    f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetFrameStrata("HIGH")
    f._fdjMain = true
    self.appearanceFrames = self.appearanceFrames or {}; table.insert(self.appearanceFrames, f)
    f:Hide(); table.insert(UISpecialFrames, f:GetName())
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        FDJ:SaveWindowPosition()
    end)
    if self.db.window and self.db.window.x and self.db.window.y then
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", self.db.window.x * UIParent:GetWidth(), self.db.window.y * UIParent:GetHeight())
    end

    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -4); header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -4)
    header:SetHeight(28); header:SetColorTexture(0.13, 0.055, 0.012, 0.98); self.nativeHeader = header
    local headerHighlight = f:CreateTexture(nil, "OVERLAY")
    headerHighlight:SetPoint("TOPLEFT", header, "TOPLEFT", 3, -2); headerHighlight:SetPoint("TOPRIGHT", header, "TOPRIGHT", -3, -2)
    headerHighlight:SetHeight(1); headerHighlight:SetColorTexture(0.88, 0.62, 0.28, 0.52); self.nativeHeaderHighlight = headerHighlight
    local headerAccent = f:CreateTexture(nil, "OVERLAY")
    headerAccent:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 3, 1); headerAccent:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", -3, 1)
    headerAccent:SetHeight(1); headerAccent:SetColorTexture(0.72, 0.47, 0.16, 0.95); self.nativeHeaderAccent = headerAccent
    local headerShadow = f:CreateTexture(nil, "ARTWORK")
    headerShadow:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -1); headerShadow:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -1)
    headerShadow:SetHeight(3); headerShadow:SetColorTexture(0, 0, 0, 0.72); self.nativeHeaderShadow = headerShadow

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -11); title:SetText("Forever Dungeon Journal")
    self.appearanceTitles = self.appearanceTitles or {}; table.insert(self.appearanceTitles, title)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -4, -4)
    local options = button(f, "Options", 80); options:SetPoint("TOPRIGHT", -42, -35)
    options:SetScript("OnClick", function() FDJ:OpenOptions() end)

    local search = CreateFrame("EditBox", nil, f, "SearchBoxTemplate")
    search:SetSize(230, 26); search:SetPoint("TOPLEFT", 16, -46); search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function() FDJ.dungeonPage = 1; FDJ:RefreshUI() end); f.search = search

    local list = CreateFrame("Frame", nil, f, "BackdropTemplate")
    list:SetPoint("TOPLEFT", 14, -78); list:SetPoint("BOTTOMLEFT", 14, 14); list:SetWidth(240); table.insert(self.appearanceFrames, list)
    f.dungeonButtons = {}
    for i = 1, 16 do
        local b = button(list, "", 216); b:SetPoint("TOPLEFT", 10, -10 - ((i - 1) * 25))
        local fontString = b:GetFontString()
        if fontString and fontString.SetJustifyH then fontString:SetJustifyH("LEFT") end
        f.dungeonButtons[i] = b
    end
    local dungeonPrevious = button(list, "<", 34); dungeonPrevious:SetPoint("BOTTOMLEFT", 10, 10)
    dungeonPrevious:SetScript("OnClick", function() FDJ.dungeonPage = math.max(1, (FDJ.dungeonPage or 1) - 1); FDJ.selected = nil; FDJ:RefreshUI() end); f.dungeonPrevious = dungeonPrevious
    local dungeonPage = list:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); dungeonPage:SetPoint("LEFT", dungeonPrevious, "RIGHT", 10, 0); dungeonPage:SetWidth(118); dungeonPage:SetJustifyH("CENTER"); f.dungeonPageLabel = dungeonPage
    local dungeonNext = button(list, ">", 34); dungeonNext:SetPoint("BOTTOMRIGHT", -10, 10)
    dungeonNext:SetScript("OnClick", function() FDJ.dungeonPage = (FDJ.dungeonPage or 1) + 1; FDJ.selected = nil; FDJ:RefreshUI() end); f.dungeonNext = dungeonNext

    local detail = CreateFrame("Frame", nil, f, "BackdropTemplate")
    detail:SetPoint("TOPLEFT", 264, -46); detail:SetPoint("BOTTOMRIGHT", -14, 14); table.insert(self.appearanceFrames, detail)
    local heading = detail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 14, -14); heading:SetText("No verified data packs installed"); f.heading = heading
    local source = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    source:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -4); source:SetPoint("RIGHT", -14, 0); source:SetJustifyH("LEFT"); f.source = source
    local map = detail:CreateTexture(nil, "ARTWORK")
    map:SetPoint("TOPLEFT", 12, -68); map:SetSize(510, 180); map:SetColorTexture(0.025, 0.02, 0.015, 1); f.map = map
    f.mapPins = {}
    for i = 1, 24 do
        local pin = CreateFrame("Button", nil, detail)
        pin:SetSize(14, 14); pin:SetFrameLevel(detail:GetFrameLevel() + 5)
        local dot = pin:CreateTexture(nil, "OVERLAY"); dot:SetAllPoints(); dot:SetTexture("Interface\\Buttons\\WHITE8X8"); pin.dot = dot
        pin:Hide(); f.mapPins[i] = pin
    end
    local legend = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    legend:SetPoint("TOPLEFT", 12, -251); legend:SetText("|cff40d9ffEntrance|r  |cffff4d33Boss|r  |cffffd133Quest|r  |cff59ff73Shortcut|r  |cffff730dRisky pull|r"); f.legend = legend
    local openMap = button(detail, "Open world map", 120); openMap:SetPoint("TOPRIGHT", -12, -244)
    openMap:SetScript("OnClick", function() if FDJ.selected then FDJ:OpenDungeonMap(FDJ.selected.dungeon) end end); f.openMap = openMap
    f.markerButtons = {}
    for i = 1, 7 do
        local b = button(detail, "", 510); b:SetPoint("TOPLEFT", 12, -274 - ((i - 1) * 28))
        local fontString = b:GetFontString()
        if fontString and fontString.SetJustifyH then fontString:SetJustifyH("LEFT") end
        f.markerButtons[i] = b
    end
    local previous = button(detail, "Previous", 80); previous:SetPoint("BOTTOMLEFT", 12, 8)
    previous:SetScript("OnClick", function() FDJ.markerPage = math.max(1, (FDJ.markerPage or 1) - 1); FDJ:RefreshUI() end); f.previous = previous
    local page = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); page:SetPoint("LEFT", previous, "RIGHT", 12, 0); f.page = page
    local nextPage = button(detail, "Next", 80); nextPage:SetPoint("BOTTOMRIGHT", -12, 8)
    nextPage:SetScript("OnClick", function() FDJ.markerPage = (FDJ.markerPage or 1) + 1; FDJ:RefreshUI() end); f.nextPage = nextPage
    local empty = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    empty:SetPoint("TOPLEFT", 24, -86); empty:SetWidth(470); empty:SetJustifyH("LEFT")
    empty:SetText("WELCOME TO YOUR JOURNAL\n\nDiscovery mode hides authored entries until you reveal them. Click an unknown entry to reveal it; right-click a revealed entry to add a personal annotation.\n\nDungeon facts only come from installed, verified data packs. The addon safely observes boss kills and quest turn-ins when matching verified entries exist—it does not inspect combat logs, targets, loot, names, or realms.\n\nNext: open Options to choose discovery filters and progress scope, or keep general expedition notes below while waiting for a verified pack.")
    f.empty = empty
    local notesLabel = detail:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    notesLabel:SetPoint("TOPLEFT", 24, -330); notesLabel:SetText("General expedition notes (saved automatically)"); f.notesLabel = notesLabel
    local notes = CreateFrame("EditBox", nil, detail, "BackdropTemplate")
    notes:SetPoint("TOPLEFT", 28, -354); notes:SetSize(466, 80); notes:SetMultiLine(true); notes:SetAutoFocus(false); notes:SetMaxLetters(2000)
    notes:SetFontObject("ChatFontNormal"); notes:SetTextInsets(8, 8, 8, 8)
    table.insert(self.appearanceFrames, notes)
    notes:SetText(self.db.generalNotes or "")
    notes:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    notes:SetScript("OnTextChanged", function(self, userInput)
        if userInput then FDJ.db.generalNotes = self:GetText() or "" end
    end)
    f.notes = notes
    self.frame = f
    self:ApplyAppearance()
    self:On("DATA_CHANGED", function() FDJ:RefreshUI() end)
    self:On("PROGRESS_CHANGED", function() FDJ:RefreshUI() end)
end

function FDJ:SaveWindowPosition()
    if not self.frame then return end
    local frameX, frameY = self.frame:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    if not frameX or not parentX or UIParent:GetWidth() == 0 or UIParent:GetHeight() == 0 then return end
    local scaleRatio = self.frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    self.db.window = {
        x = ((frameX * scaleRatio) - parentX) / UIParent:GetWidth(),
        y = ((frameY * scaleRatio) - parentY) / UIParent:GetHeight(),
    }
end

function FDJ:ResetWindowPosition()
    if not self.frame then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function FDJ:ToggleUI()
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show(); self:RefreshUI() end
end

local function matches(entry, query)
    if query == "" then return true end
    query = string.lower(query)
    if string.find(string.lower(entry.dungeon.name), query, 1, true) then return true end
    for _, marker in ipairs(entry.dungeon.markers) do
        local progress = FDJ:GetMarkerProgress(entry.pack.id, entry.dungeon.id, marker.id, false)
        if (not FDJ.db.settings.discoveryMode or (progress and progress.revealed)) and string.find(string.lower(marker.label), query, 1, true) then return true end
    end
    return false
end

function FDJ:RefreshUI()
    if not self.frame then return end
    local query = string.lower(self.frame.search:GetText() or "")
    local entries = {}
    for _, entry in ipairs(self:GetDungeons()) do if matches(entry, query) then table.insert(entries, entry) end end
    local dungeonPageSize = #self.frame.dungeonButtons
    local dungeonMaxPage = math.max(1, math.ceil(#entries / dungeonPageSize))
    self.dungeonPage = math.min(math.max(1, self.dungeonPage or 1), dungeonMaxPage)
    self.frame.dungeonPageLabel:SetText(string.format("%d / %d", self.dungeonPage, dungeonMaxPage))
    self.frame.dungeonPrevious:SetEnabled(self.dungeonPage > 1); self.frame.dungeonNext:SetEnabled(self.dungeonPage < dungeonMaxPage)
    local dungeonFirst = ((self.dungeonPage - 1) * dungeonPageSize) + 1
    for i, b in ipairs(self.frame.dungeonButtons) do
        local entry = entries[dungeonFirst + i - 1]
        if entry then
            b:SetText(entry.dungeon.name); b.entry = entry; b:Show()
            b:SetScript("OnClick", function(btn) FDJ.selected = btn.entry; FDJ.markerPage = 1; FDJ:RefreshUI() end)
        else b:Hide() end
    end
    local selectionVisible = false
    if self.selected then
        for index = dungeonFirst, math.min(#entries, dungeonFirst + dungeonPageSize - 1) do
            local entry = entries[index]
            if entry and entry.pack.id == self.selected.pack.id and entry.dungeon.id == self.selected.dungeon.id then selectionVisible = true; break end
        end
    end
    if not selectionVisible then self.selected = nil end
    if not self.selected and entries[dungeonFirst] then self.selected = entries[dungeonFirst] end
    local selected = self.selected
    self.frame.empty:SetShown(not selected)
    self.frame.notesLabel:SetShown(not selected)
    self.frame.notes:SetShown(not selected)
    self.frame.map:SetShown(selected and true or false)
    self.frame.legend:SetShown(selected and true or false); self.frame.openMap:SetShown(selected and true or false)
    self.frame.previous:SetShown(selected and true or false); self.frame.nextPage:SetShown(selected and true or false); self.frame.page:SetShown(selected and true or false)
    for _, pin in ipairs(self.frame.mapPins) do pin:Hide() end
    if not selected then
        local d = self:GetDiagnostics()
        self.frame.heading:SetText("No verified dungeon data available")
        self.frame.source:SetText(string.format("%s  •  %d rejected pack(s)  •  /fdj diagnostics", self.nativeDataStatus or "Install a verified pack or enable the client Encounter Journal.", d.errors))
        for _, b in ipairs(self.frame.markerButtons) do b:Hide() end
        return
    end
    self.frame.heading:SetText(selected.dungeon.name)
    local source = selected.pack.sources and selected.pack.sources[1]
    self.frame.source:SetText(string.format("%s %s • build %s • %s • checked %s", selected.pack.name, selected.pack.version, selected.pack.build, selected.pack.verification, source and source.checked or "unknown"))
    if selected.dungeon.map and selected.dungeon.map.texture then
        self.frame.map:SetTexture(selected.dungeon.map.texture); self.frame.map:SetVertexColor(1, 1, 1, 1)
    else
        if self.db.settings.appearance == "bronze" then self.frame.map:SetColorTexture(0.025, 0.02, 0.015, 1)
        else self.frame.map:SetColorTexture(0.06, 0.06, 0.06, 1) end
    end
    local shown = {}
    for _, marker in ipairs(selected.dungeon.markers) do
        local enabled = self.db.settings.show[marker.type]
        local progress = self:GetMarkerProgress(selected.pack.id, selected.dungeon.id, marker.id, false)
        local revealed = progress and progress.revealed
        if enabled then table.insert(shown, { marker = marker, hidden = self.db.settings.discoveryMode and not revealed }) end
    end
    local pageSize = #self.frame.markerButtons
    local maxPage = math.max(1, math.ceil(#shown / pageSize))
    self.markerPage = math.min(math.max(1, self.markerPage or 1), maxPage)
    self.frame.page:SetText(string.format("%d / %d  •  %d entries", self.markerPage, maxPage, #shown))
    self.frame.previous:SetEnabled(self.markerPage > 1); self.frame.nextPage:SetEnabled(self.markerPage < maxPage)
    for pinIndex, row in ipairs(shown) do
        local marker, pin = row.marker, self.frame.mapPins[pinIndex]
        if not pin and not row.hidden and marker.x and marker.y then
            pin = CreateFrame("Button", nil, self.frame.map:GetParent()); pin:SetSize(14, 14)
            pin:SetFrameLevel(self.frame.map:GetParent():GetFrameLevel() + 5)
            local dot = pin:CreateTexture(nil, "OVERLAY"); dot:SetAllPoints(); dot:SetTexture("Interface\\Buttons\\WHITE8X8"); pin.dot = dot
            self.frame.mapPins[pinIndex] = pin
        end
        if pin and not row.hidden and marker.x and marker.y then
            pin.marker = marker
            pin:ClearAllPoints(); pin:SetPoint("CENTER", self.frame.map, "TOPLEFT", marker.x * 510, -marker.y * 180)
            local color = TYPE_COLORS[marker.type] or {1, 1, 1}; pin.dot:SetVertexColor(color[1], color[2], color[3], 0.95)
            pin:SetScript("OnEnter", function(mapPin) GameTooltip:SetOwner(mapPin, "ANCHOR_RIGHT"); GameTooltip:SetText(mapPin.marker.label); GameTooltip:Show() end)
            pin:SetScript("OnLeave", GameTooltip_Hide); pin:Show()
        end
    end
    local first = ((self.markerPage - 1) * pageSize) + 1
    for i, b in ipairs(self.frame.markerButtons) do
        local row = shown[first + i - 1]
        if row then
            local marker = row.marker
            if row.hidden then
                b:SetText("Unknown discovery — click to reveal")
            else
                local note = self:GetAnnotation(selected.pack.id, selected.dungeon.id, marker.id)
                b:SetText(TYPE_LABELS[marker.type] .. ": " .. marker.label .. (note ~= "" and (" — " .. note) or ""))
            end
            b.marker = marker; b.hidden = row.hidden; b:Show()
            b:SetScript("OnClick", function(btn, mouseButton)
                if btn.hidden or mouseButton ~= "RightButton" then FDJ:Reveal(selected.pack.id, selected.dungeon.id, btn.marker.id, "manual")
                else FDJ:OpenAnnotation(btn.marker) end
            end); b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            b:SetScript("OnEnter", function(btn)
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                if btn.hidden then GameTooltip:SetText("Unrevealed discovery"); GameTooltip:AddLine("Click to reveal this entry.", 1, 1, 1)
                else
                    GameTooltip:SetText(btn.marker.label); GameTooltip:AddLine(btn.marker.description or "No spoiler-free description supplied.", 1, 1, 1, true)
                    GameTooltip:AddLine("Verification: " .. (btn.marker.verification or selected.dungeon.verification or selected.pack.verification), 0.65, 0.8, 1)
                    if btn.marker.encounterID then GameTooltip:AddLine("Encounter ID: " .. btn.marker.encounterID, 0.75, 0.75, 0.75) end
                    if btn.marker.questID then GameTooltip:AddLine("Quest ID: " .. btn.marker.questID, 0.75, 0.75, 0.75) end
                    local progress = FDJ:GetMarkerProgress(selected.pack.id, selected.dungeon.id, btn.marker.id, false)
                    if progress and progress.revealedAt then GameTooltip:AddLine("First revealed: " .. date("%Y-%m-%d %H:%M", progress.revealedAt), 0.75, 0.75, 0.75) end
                    if progress and progress.firstKill then GameTooltip:AddLine("First kill: " .. date("%Y-%m-%d %H:%M", progress.firstKill), 0.75, 0.75, 0.75) end
                    if progress and progress.firstCompleted then GameTooltip:AddLine("Quest completed: " .. date("%Y-%m-%d %H:%M", progress.firstCompleted), 0.75, 0.75, 0.75) end
                    GameTooltip:AddLine("Right-click to annotate.", unpack(BRONZE))
                end
                GameTooltip:Show()
            end); b:SetScript("OnLeave", GameTooltip_Hide)
        else b:Hide() end
    end
end

function FDJ:OpenAnnotation(marker)
    local selected = self.selected
    StaticPopupDialogs.FDJ_ANNOTATE = {
        text = "Personal note for %s", button1 = SAVE, button2 = CANCEL, hasEditBox = true, editBoxWidth = 260,
        OnShow = function(popup) popup.editBox:SetText(FDJ:GetAnnotation(selected.pack.id, selected.dungeon.id, marker.id)); popup.editBox:HighlightText() end,
        OnAccept = function(popup) FDJ:SetAnnotation(selected.pack.id, selected.dungeon.id, marker.id, popup.editBox:GetText()) end,
        EditBoxOnEnterPressed = function(editBox) editBox:GetParent().button1:Click() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopup_Show("FDJ_ANNOTATE", marker.label)
end

