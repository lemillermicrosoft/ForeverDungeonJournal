local _, FDJ = ...

local TYPE_LABELS = { entrance = "Entrance", boss = "Boss", quest = "Quest", shortcut = "Shortcut", risky = "Risky pull" }
local BRONZE = { 0.78, 0.57, 0.25 }

local function bronzeBackdrop(frame)
    frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    frame:SetBackdropColor(0.045, 0.035, 0.025, 0.96)
    frame:SetBackdropBorderColor(unpack(BRONZE))
end

local function button(parent, text, width)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 100, 24); b:SetText(text)
    return b
end

function FDJ:InitializeUI()
    local f = CreateFrame("Frame", "ForeverDungeonJournalFrame", UIParent, "BackdropTemplate")
    f:SetSize(820, 560); f:SetPoint("CENTER"); f:SetMovable(true); f:SetClampedToScreen(true)
    f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetFrameStrata("HIGH")
    bronzeBackdrop(f); f:Hide(); table.insert(UISpecialFrames, f:GetName())
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        FDJ:SaveWindowPosition()
    end)
    if self.db.window and self.db.window.x and self.db.window.y then
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", self.db.window.x * UIParent:GetWidth(), self.db.window.y * UIParent:GetHeight())
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -15); title:SetText("Forever Dungeon Journal"); title:SetTextColor(unpack(BRONZE))
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -4, -4)
    local options = button(f, "Options", 80); options:SetPoint("TOPRIGHT", -38, -13)
    options:SetScript("OnClick", function() FDJ:OpenOptions() end)

    local search = CreateFrame("EditBox", nil, f, "SearchBoxTemplate")
    search:SetSize(230, 26); search:SetPoint("TOPLEFT", 16, -46); search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function() FDJ:RefreshUI() end); f.search = search

    local list = CreateFrame("Frame", nil, f, "BackdropTemplate")
    list:SetPoint("TOPLEFT", 14, -78); list:SetPoint("BOTTOMLEFT", 14, 14); list:SetWidth(240); bronzeBackdrop(list)
    f.dungeonButtons = {}
    for i = 1, 18 do
        local b = button(list, "", 216); b:SetPoint("TOPLEFT", 10, -10 - ((i - 1) * 25))
        local fontString = b:GetFontString()
        if fontString and fontString.SetJustifyH then fontString:SetJustifyH("LEFT") end
        f.dungeonButtons[i] = b
    end

    local detail = CreateFrame("Frame", nil, f, "BackdropTemplate")
    detail:SetPoint("TOPLEFT", 264, -46); detail:SetPoint("BOTTOMRIGHT", -14, 14); bronzeBackdrop(detail)
    local heading = detail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 14, -14); heading:SetText("No verified data packs installed"); f.heading = heading
    local source = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    source:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -4); source:SetPoint("RIGHT", -14, 0); source:SetJustifyH("LEFT"); f.source = source
    local map = detail:CreateTexture(nil, "ARTWORK")
    map:SetPoint("TOPLEFT", 12, -68); map:SetSize(510, 180); map:SetColorTexture(0.025, 0.02, 0.015, 1); f.map = map
    f.markerButtons = {}
    for i = 1, 8 do
        local b = button(detail, "", 510); b:SetPoint("TOPLEFT", 12, -258 - ((i - 1) * 28))
        local fontString = b:GetFontString()
        if fontString and fontString.SetJustifyH then fontString:SetJustifyH("LEFT") end
        f.markerButtons[i] = b
    end
    local empty = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    empty:SetPoint("CENTER"); empty:SetWidth(460); empty:SetText("This alpha intentionally contains no unverified dungeon facts.\nInstall an authored, verified data pack to populate the journal."); f.empty = empty
    self.frame = f
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
    for i, b in ipairs(self.frame.dungeonButtons) do
        local entry = entries[i]
        if entry then
            b:SetText(entry.dungeon.name); b.entry = entry; b:Show()
            b:SetScript("OnClick", function(btn) FDJ.selected = btn.entry; FDJ:RefreshUI() end)
        else b:Hide() end
    end
    if self.selected and not self.packs[self.selected.pack.id] then self.selected = nil end
    if not self.selected and entries[1] then self.selected = entries[1] end
    local selected = self.selected
    self.frame.empty:SetShown(not selected)
    if not selected then
        self.frame.heading:SetText("No verified data packs installed"); self.frame.source:SetText("")
        for _, b in ipairs(self.frame.markerButtons) do b:Hide() end
        return
    end
    self.frame.heading:SetText(selected.dungeon.name)
    self.frame.source:SetText("Data: " .. selected.pack.name .. " " .. selected.pack.version .. (selected.pack.source and (" — " .. selected.pack.source) or ""))
    if selected.dungeon.map and selected.dungeon.map.texture then
        self.frame.map:SetTexture(selected.dungeon.map.texture); self.frame.map:SetVertexColor(1, 1, 1, 1)
    else
        self.frame.map:SetColorTexture(0.025, 0.02, 0.015, 1)
    end
    local shown = {}
    for _, marker in ipairs(selected.dungeon.markers) do
        local enabled = self.db.settings.show[marker.type]
        local progress = self:GetMarkerProgress(selected.pack.id, selected.dungeon.id, marker.id, false)
        local revealed = progress and progress.revealed
        if enabled then table.insert(shown, { marker = marker, hidden = self.db.settings.discoveryMode and not revealed }) end
    end
    for i, b in ipairs(self.frame.markerButtons) do
        local row = shown[i]
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

