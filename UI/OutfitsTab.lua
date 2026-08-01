local QC = QuestChronicle
local UI = QC.UI
local Wardrobe = QC.Wardrobe

local SOURCE_ROWS = Wardrobe.PAGE_SIZE or 8

local function GetState()
    return Wardrobe.GetPreviewState()
end

local function GetCurrentSlot()
    return GetState().selectedSlot or "HEAD"
end

local function GetPage(slotKey)
    return math.max(1, tonumber(GetState().pages[slotKey]) or 1)
end

local function SetPage(slotKey, value)
    GetState().pages[slotKey] = math.max(1, tonumber(value) or 1)
end

local function SourceLabel(source)
    local qualityColor = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[source.quality or 1]
    local color = qualityColor and qualityColor.hex or UI.white
    return string.format("%s%s|r", color, source.name or ("Appearance " .. tostring(source.sourceID or 0)))
end

function UI.CreateOutfitsTab(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent)

    local _, subtitle = UI.CreatePaneTitle(
        pane,
        "Outfits",
        "Scan collected appearances, build a manual look, and preview it on your character. Dynamic generation arrives in later releases."
    )
    pane.subtitle = subtitle

    local slotPanel = UI.CreateInsetPanel(pane)
    slotPanel:SetPoint("TOPLEFT", pane, "TOPLEFT", 12, -56)
    slotPanel:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 12, 12)
    slotPanel:SetWidth(128)

    local modelPanel = UI.CreateInsetPanel(pane)
    modelPanel:SetPoint("TOPLEFT", slotPanel, "TOPRIGHT", 8, 0)
    modelPanel:SetPoint("BOTTOM", pane, "BOTTOM", 0, 12)
    modelPanel:SetWidth(300)

    local sourcePanel = UI.CreateInsetPanel(pane)
    sourcePanel:SetPoint("TOPLEFT", modelPanel, "TOPRIGHT", 8, 0)
    sourcePanel:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -12, 12)

    local slotTitle = slotPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slotTitle:SetPoint("TOP", slotPanel, "TOP", 0, -10)
    slotTitle:SetText("Equipment Slot")

    pane.slotButtons = {}
    local previous
    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        local button = UI.CreateButton(slotPanel, definition.label, 108, 23)
        if previous then
            button:SetPoint("TOP", previous, "BOTTOM", 0, -5)
        else
            button:SetPoint("TOP", slotTitle, "BOTTOM", 0, -9)
        end
        button.slotKey = definition.key
        button:SetScript("OnClick", function(self)
            GetState().selectedSlot = self.slotKey
            pane:Refresh()
        end)
        pane.slotButtons[definition.key] = button
        previous = button
    end

    local modelTitle = modelPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    modelTitle:SetPoint("TOP", modelPanel, "TOP", 0, -10)
    modelTitle:SetText("Character Preview")

    local model = CreateFrame("DressUpModel", nil, modelPanel)
    model:SetPoint("TOPLEFT", modelPanel, "TOPLEFT", 8, -32)
    model:SetPoint("BOTTOMRIGHT", modelPanel, "BOTTOMRIGHT", -8, 74)
    model:SetUnit("player")
    if model.SetFacing then model:SetFacing(0) end
    pane.model = model

    local rotateLeft = UI.CreateButton(modelPanel, "Rotate Left", 88, 23)
    rotateLeft:SetPoint("BOTTOMLEFT", modelPanel, "BOTTOMLEFT", 8, 40)
    local rotateRight = UI.CreateButton(modelPanel, "Rotate Right", 88, 23)
    rotateRight:SetPoint("LEFT", rotateLeft, "RIGHT", 6, 0)
    local resetModel = UI.CreateButton(modelPanel, "Reset View", 88, 23)
    resetModel:SetPoint("LEFT", rotateRight, "RIGHT", 6, 0)

    rotateLeft:SetScript("OnClick", function()
        if model.SetFacing and model.GetFacing then model:SetFacing((model:GetFacing() or 0) - 0.35) end
    end)
    rotateRight:SetScript("OnClick", function()
        if model.SetFacing and model.GetFacing then model:SetFacing((model:GetFacing() or 0) + 0.35) end
    end)
    resetModel:SetScript("OnClick", function()
        if model.SetFacing then model:SetFacing(0) end
        Wardrobe.ApplyPreview(model)
    end)

    local clearAll = UI.CreateButton(modelPanel, "Clear Selections", 140, 24)
    clearAll:SetPoint("BOTTOM", modelPanel, "BOTTOM", 0, 10)
    clearAll:SetScript("OnClick", function()
        Wardrobe.ClearAllSelections()
        Wardrobe.ApplyPreview(model)
        pane:Refresh()
    end)

    local sourceTitle = sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sourceTitle:SetPoint("TOPLEFT", sourcePanel, "TOPLEFT", 10, -10)
    sourceTitle:SetPoint("RIGHT", sourcePanel, "RIGHT", -10, 0)
    sourceTitle:SetJustifyH("LEFT")
    pane.sourceTitle = sourceTitle

    local scanButton = UI.CreateButton(sourcePanel, "Scan Collection", 125, 24)
    scanButton:SetPoint("TOPRIGHT", sourcePanel, "TOPRIGHT", -10, -8)
    pane.scanButton = scanButton

    local statusText = sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", sourceTitle, "BOTTOMLEFT", 0, -8)
    statusText:SetPoint("RIGHT", sourcePanel, "RIGHT", -10, 0)
    statusText:SetJustifyH("LEFT")
    statusText:SetTextColor(0.7, 0.7, 0.7)
    pane.statusText = statusText

    pane.sourceRows = {}
    local rowAnchor = statusText
    for index = 1, SOURCE_ROWS do
        local row = CreateFrame("Button", nil, sourcePanel)
        row:SetHeight(42)
        row:SetPoint("LEFT", sourcePanel, "LEFT", 10, 0)
        row:SetPoint("RIGHT", sourcePanel, "RIGHT", -10, 0)
        if index == 1 then
            row:SetPoint("TOP", rowAnchor, "BOTTOM", 0, -8)
        else
            row:SetPoint("TOP", pane.sourceRows[index - 1], "BOTTOM", 0, -3)
        end

        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(row)
        background:SetColorTexture(0.08, 0.08, 0.08, 0.72)
        row.background = background

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(32, 32)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        row.icon = icon

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 7, -1)
        name:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        name:SetJustifyH("LEFT")
        row.name = name

        local detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        detail:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 7, 1)
        detail:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        detail:SetJustifyH("LEFT")
        row.detail = detail

        row:SetScript("OnClick", function(self)
            if self.source then
                local ok, reason = Wardrobe.SelectSource(GetCurrentSlot(), self.source.sourceID)
                if ok then
                    Wardrobe.ApplyPreview(model)
                else
                    UIErrorsFrame:AddMessage(reason or "Appearance cannot be previewed.", 1, 0.25, 0.25)
                end
                pane:Refresh()
            end
        end)
        row:SetScript("OnEnter", function(self)
            if self.source then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetText(self.source.name or "Appearance", 1, 0.82, 0)
                GameTooltip:AddLine("Click to preview this collected appearance.", 1, 1, 1, true)
                GameTooltip:AddLine("Source ID: " .. tostring(self.source.sourceID or 0), 0.65, 0.65, 0.65)
                if self.source.itemID then
                    GameTooltip:AddLine("Item ID: " .. tostring(self.source.itemID), 0.65, 0.65, 0.65)
                end
                local valid, reason = Wardrobe.ValidateSource(self.source, GetCurrentSlot())
                GameTooltip:AddLine(valid and "Compatible" or reason, valid and 0.2 or 1, valid and 1 or 0.25, valid and 0.2 or 0.25, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        pane.sourceRows[index] = row
    end

    local previousPage = UI.CreateButton(sourcePanel, "Previous", 88, 23)
    previousPage:SetPoint("BOTTOMLEFT", sourcePanel, "BOTTOMLEFT", 10, 10)
    local pageText = sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    pageText:SetPoint("LEFT", previousPage, "RIGHT", 8, 0)
    pageText:SetWidth(110)
    pageText:SetJustifyH("CENTER")
    pane.pageText = pageText
    local nextPage = UI.CreateButton(sourcePanel, "Next", 88, 23)
    nextPage:SetPoint("LEFT", pageText, "RIGHT", 8, 0)

    local clearSlot = UI.CreateButton(sourcePanel, "Clear Slot", 95, 23)
    clearSlot:SetPoint("BOTTOMRIGHT", sourcePanel, "BOTTOMRIGHT", -10, 10)

    previousPage:SetScript("OnClick", function()
        local slotKey = GetCurrentSlot()
        SetPage(slotKey, GetPage(slotKey) - 1)
        pane:Refresh()
    end)
    nextPage:SetScript("OnClick", function()
        local slotKey = GetCurrentSlot()
        SetPage(slotKey, GetPage(slotKey) + 1)
        pane:Refresh()
    end)
    clearSlot:SetScript("OnClick", function()
        Wardrobe.ClearSelection(GetCurrentSlot())
        Wardrobe.ApplyPreview(model)
        pane:Refresh()
    end)

    scanButton:SetScript("OnClick", function()
        local started, message = Wardrobe.Scan(true)
        statusText:SetText(message or (started and "Wardrobe scan started." or "Unable to scan."))
        pane:Refresh()
    end)

    function pane:Refresh(message)
        local cache = Wardrobe.GetCache()
        local slotKey = GetCurrentSlot()
        local definition = Wardrobe.GetSlotDefinition(slotKey) or Wardrobe.slotDefinitions[1]
        local sources = Wardrobe.GetSlotSources(slotKey)
        local pageCount = math.max(1, math.ceil(#sources / SOURCE_ROWS))
        local page = math.min(GetPage(slotKey), pageCount)
        SetPage(slotKey, page)

        for key, button in pairs(self.slotButtons) do
            button:SetEnabled(key ~= slotKey)
            local count = #(Wardrobe.GetSlotSources(key) or {})
            button:SetText(string.format("%s (%d)", Wardrobe.GetSlotDefinition(key).label, count))
        end

        sourceTitle:SetText((definition and definition.label or "Appearance") .. " Appearances")
        scanButton:SetEnabled(not Wardrobe.IsScanning())
        scanButton:SetText(Wardrobe.IsScanning() and "Scanning..." or (cache.dirty and "Rescan Collection" or "Scan Collection"))

        local selected = Wardrobe.GetSelectedSource(slotKey)
        local selectedText = selected and ("Selected: " .. selected.name) or "Selected: current equipped appearance"
        local cacheText
        if cache.scanState == "NEVER" or cache.scanState == "STALE" then
            cacheText = "Collection needs a full account wardrobe scan."
        elseif cache.scanState == "PREPARING" then
            cacheText = "Waiting for WoW's wardrobe search database to become ready..."
        elseif cache.scanState == "SCANNING" then
            cacheText = "Scanning WoW's collected appearances in small batches..."
        elseif cache.scanState == "FAILED" then
            cacheText = "The last collection scan failed. Any previous healthy cache was preserved."
        else
            cacheText = string.format("%s cached visuals • Last scan %s%s", UI.FormatNumber(cache.totalVisuals or 0), cache.scanCompletedAt and UI.FormatShortTimestamp(cache.scanCompletedAt) or "unknown", cache.dirty and " • Collection changed" or "")
        end
        local diagnostics = Wardrobe.GetSlotDiagnostics(slotKey)
        if diagnostics and diagnostics.expectedCollected then
            cacheText = cacheText .. string.format("\nWoW reports %s collected for these categories • %s compatible visuals cached", UI.FormatNumber(diagnostics.expectedCollected or 0), UI.FormatNumber(diagnostics.compatibleVisuals or #sources))
        elseif diagnostics and diagnostics.error then
            cacheText = cacheText .. "\n" .. UI.red .. tostring(diagnostics.error) .. "|r"
        end
        if cache.scanError then
            cacheText = cacheText .. "\n" .. UI.red .. cache.scanError .. "|r"
        elseif cache.scanWarning then
            cacheText = cacheText .. "\n" .. UI.red .. cache.scanWarning .. "|r"
        end
        statusText:SetText(message or (selectedText .. "\n" .. cacheText))

        local startIndex = ((page - 1) * SOURCE_ROWS) + 1
        for rowIndex, row in ipairs(self.sourceRows) do
            local source = sources[startIndex + rowIndex - 1]
            row.source = source
            row:SetShown(source ~= nil)
            if source then
                row.icon:SetTexture(source.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.name:SetText(SourceLabel(source))
                local valid, reason = Wardrobe.ValidateSource(source, slotKey)
                local marker = selected and selected.sourceID == source.sourceID and (UI.green .. "Selected|r") or (valid and "Collected" or (UI.red .. "Unavailable|r"))
                row.detail:SetText(string.format("%s • Source %d%s", marker, source.sourceID or 0, valid and "" or (" • " .. tostring(reason))))
                row:SetEnabled(valid)
                row.background:SetColorTexture(selected and selected.sourceID == source.sourceID and 0.12 or 0.08, selected and selected.sourceID == source.sourceID and 0.18 or 0.08, selected and selected.sourceID == source.sourceID and 0.10 or 0.08, 0.78)
            end
        end

        pageText:SetText(string.format("Page %d of %d", page, pageCount))
        previousPage:SetEnabled(page > 1)
        nextPage:SetEnabled(page < pageCount)
        clearSlot:SetEnabled(selected ~= nil)
        subtitle:SetText(string.format("%s collected appearances cached for %s. Manual preview only; no outfit is applied to the character.", UI.FormatNumber(#sources), definition and definition.label or slotKey))
    end

    QC.RegisterCallback("WARDROBE_SCAN_PROGRESS", pane, function(index, total, slotKey, count, diagnostics)
        if pane:IsShown() then
            local expected = diagnostics and diagnostics.expectedCollected or 0
            pane:Refresh(string.format("Scanning %d of %d: %s (%d compatible of %d collected)", index or 0, total or 0, Wardrobe.GetSlotDefinition(slotKey) and Wardrobe.GetSlotDefinition(slotKey).label or slotKey, count or 0, expected or 0))
        end
    end)
    QC.RegisterCallback("WARDROBE_SCAN_COMPLETE", pane, function(cache)
        Wardrobe.ApplyPreview(model)
        if pane:IsShown() then
            pane:Refresh(cache and cache.scanWarning or cache and cache.scanError or "Wardrobe collection scan complete.")
        end
    end)
    QC.RegisterCallback("WARDROBE_CACHE_DIRTY", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("WARDROBE_SELECTION_CHANGED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("PLAYER_READY", pane, function()
        if model.SetUnit then model:SetUnit("player") end
        Wardrobe.ApplyPreview(model)
        pane:Refresh()
    end)

    pane:SetScript("OnShow", function()
        Wardrobe.ApplyPreview(model)
        pane:Refresh()
    end)

    return pane
end
