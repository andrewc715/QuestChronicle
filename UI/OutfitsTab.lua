local QC = QuestChronicle
local UI = QC.UI
local Wardrobe = QC.Wardrobe

local SOURCE_ROWS = 7
local SOURCE_ROW_HEIGHT = 37
local SOURCE_ROW_SPACING = 2

local SAVE_CONCEPT_DIALOG = "QUEST_CHRONICLE_SAVE_OUTFIT_CONCEPT"
if StaticPopupDialogs and not StaticPopupDialogs[SAVE_CONCEPT_DIALOG] then
    StaticPopupDialogs[SAVE_CONCEPT_DIALOG] = {
        text = "Name this Quest Chronicle outfit concept:",
        button1 = SAVE,
        button2 = CANCEL,
        hasEditBox = true,
        maxLetters = 48,
        OnShow = function(self, pane)
            local suggested = pane and pane.GetSuggestedConceptName and pane:GetSuggestedConceptName() or "Outfit Concept"
            self.editBox:SetText(suggested)
            self.editBox:HighlightText()
            self.editBox:SetFocus()
        end,
        OnAccept = function(self, pane)
            if pane and pane.SaveConcept then
                pane:SaveConcept(self.editBox:GetText())
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local dialog = self:GetParent()
            if dialog and dialog.button1 then
                dialog.button1:Click()
            end
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

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

local function ShowConceptMenu(button, pane)
    local concepts = Wardrobe.GetConcepts()
    if #concepts == 0 then
        pane:Refresh("No outfit concepts have been saved yet.")
        return
    end

    if MenuUtil and type(MenuUtil.CreateContextMenu) == "function" then
        MenuUtil.CreateContextMenu(button, function(_, rootDescription)
            if rootDescription.CreateTitle then
                rootDescription:CreateTitle("Load Outfit Concept")
            end
            for _, concept in ipairs(concepts) do
                local label = concept.name or "Unnamed Concept"
                local conceptID = concept.id
                rootDescription:CreateButton(label, function()
                    pane:LoadConcept(conceptID)
                end)
            end
        end)
    else
        pane:LoadConcept(concepts[1].id)
    end
end

local function CacheSummary(cache, diagnostics, sourceCount)
    if cache.scanState == "NEVER" or cache.scanState == "STALE" then
        return "Collection scan required."
    elseif cache.scanState == "PREPARING" then
        return "Preparing WoW's wardrobe collection..."
    elseif cache.scanState == "SCANNING" then
        return "Scanning collected appearances..."
    elseif cache.scanState == "FAILED" then
        return UI.red .. "Last scan failed. Previous cache preserved.|r"
    end

    local scanned = cache.scanCompletedAt and UI.FormatShortTimestamp(cache.scanCompletedAt) or "unknown"
    local expected = diagnostics and tonumber(diagnostics.expectedCollected) or 0
    if expected > 0 then
        return string.format(
            "%s previewable visuals • %s collected sources • Scanned %s%s",
            UI.FormatNumber(sourceCount),
            UI.FormatNumber(expected),
            scanned,
            cache.dirty and " • Refresh recommended" or ""
        )
    end

    return string.format(
        "%s previewable visuals • Scanned %s%s",
        UI.FormatNumber(sourceCount),
        scanned,
        cache.dirty and " • Refresh recommended" or ""
    )
end

local function BuildDiagnosticsTooltip(cache, diagnostics, sourceCount, selected)
    local lines = {}
    if selected then
        table.insert(lines, "Selected appearance: " .. tostring(selected.name or selected.sourceID or "Unknown"))
    else
        table.insert(lines, "Selected appearance: currently equipped gear")
    end

    table.insert(lines, "Cached previewable visuals: " .. UI.FormatNumber(sourceCount))

    if diagnostics then
        if diagnostics.expectedCollected ~= nil then
            table.insert(lines, "WoW collected source count: " .. UI.FormatNumber(diagnostics.expectedCollected))
        end
        if diagnostics.returnedAppearances ~= nil then
            table.insert(lines, "Appearance rows returned: " .. UI.FormatNumber(diagnostics.returnedAppearances))
        end
        if diagnostics.returnedSources ~= nil then
            table.insert(lines, "Source rows examined: " .. UI.FormatNumber(diagnostics.returnedSources))
        end
        if diagnostics.compatibleVisuals ~= nil then
            table.insert(lines, "Validated unique visuals: " .. UI.FormatNumber(diagnostics.compatibleVisuals))
        end
        if diagnostics.error then
            table.insert(lines, "Scan error: " .. tostring(diagnostics.error))
        end
    end

    if cache.scanError then
        table.insert(lines, "Last scan error: " .. tostring(cache.scanError))
    end

    table.insert(lines, "")
    table.insert(lines, "These counts are not expected to match exactly. Multiple item sources can share one visual, and unusable appearances are excluded from the preview cache.")
    return table.concat(lines, "\n")
end

function UI.CreateOutfitsTab(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent)

    local _, subtitle = UI.CreatePaneTitle(
        pane,
        "Outfits",
        "Browse collected appearances and assemble a manual character preview. Nothing is applied to your equipped transmog."
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
        local button = UI.CreateButton(slotPanel, definition.label, 108, 22)
        if previous then
            button:SetPoint("TOP", previous, "BOTTOM", 0, -3)
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
    model:SetPoint("BOTTOMRIGHT", modelPanel, "BOTTOMRIGHT", -8, 112)
    model:SetUnit("player")
    if model.SetFacing then model:SetFacing(0) end
    pane.model = model

    local rotateLeft = UI.CreateButton(modelPanel, "Rotate Left", 88, 23)
    rotateLeft:SetPoint("BOTTOMLEFT", modelPanel, "BOTTOMLEFT", 8, 78)
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

    local generateButton = UI.CreateButton(modelPanel, "Generate Outfit", 128, 24)
    generateButton:SetPoint("BOTTOMLEFT", modelPanel, "BOTTOMLEFT", 18, 44)
    local rerollUnlocked = UI.CreateButton(modelPanel, "Reroll Unlocked", 128, 24)
    rerollUnlocked:SetPoint("BOTTOMRIGHT", modelPanel, "BOTTOMRIGHT", -18, 44)

    local saveConcept = UI.CreateButton(modelPanel, "Save Concept", 88, 24)
    saveConcept:SetPoint("BOTTOMLEFT", modelPanel, "BOTTOMLEFT", 8, 10)
    local loadConcept = UI.CreateButton(modelPanel, "Load Concept", 88, 24)
    loadConcept:SetPoint("LEFT", saveConcept, "RIGHT", 4, 0)
    local clearAll = UI.CreateButton(modelPanel, "Reset Outfit", 100, 24)
    clearAll:SetPoint("LEFT", loadConcept, "RIGHT", 4, 0)

    UI.SetTooltip(generateButton, "Generate Outfit", "Build a complete random outfit from cached appearances. Locked slots and hidden helm, cloak, shirt, or tabard choices are preserved.")
    UI.SetTooltip(rerollUnlocked, "Reroll Unlocked", "Replace every unlocked armor and weapon choice while preserving locked slots and visibility choices.")
    UI.SetTooltip(saveConcept, "Save Concept", "Save the current selections, locks, hidden slots, and weapon configuration for this character.")
    UI.SetTooltip(loadConcept, "Load Concept", "Choose one of this character's saved outfit concepts.")
    UI.SetTooltip(clearAll, "Reset Outfit", "Clear selections, locks, and hidden-slot choices, returning the preview to currently equipped gear.")

    generateButton:SetScript("OnClick", function()
        local ok, message = Wardrobe.GenerateOutfit(false)
        if ok then Wardrobe.ApplyPreview(model) end
        pane:Refresh(message)
    end)
    rerollUnlocked:SetScript("OnClick", function()
        local ok, message = Wardrobe.GenerateOutfit(true)
        if ok then Wardrobe.ApplyPreview(model) end
        pane:Refresh(message)
    end)
    saveConcept:SetScript("OnClick", function()
        if StaticPopup_Show then
            StaticPopup_Show(SAVE_CONCEPT_DIALOG, nil, nil, pane)
        end
    end)
    loadConcept:SetScript("OnClick", function(self)
        ShowConceptMenu(self, pane)
    end)
    clearAll:SetScript("OnClick", function()
        Wardrobe.ClearAllSelections()
        Wardrobe.ApplyPreview(model)
        pane:Refresh("Outfit preview reset to currently equipped gear.")
    end)

    local scanButton = UI.CreateButton(sourcePanel, "Scan Collection", 125, 24)
    scanButton:SetPoint("TOPRIGHT", sourcePanel, "TOPRIGHT", -10, -8)
    pane.scanButton = scanButton
    UI.SetTooltip(scanButton, "Scan Collection", "Refresh the local cache of collected, previewable appearances. Keep Blizzard's Wardrobe and Transmogrify windows closed during the scan.", "ANCHOR_LEFT")

    local sourceTitle = sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sourceTitle:SetPoint("TOPLEFT", sourcePanel, "TOPLEFT", 10, -10)
    sourceTitle:SetPoint("RIGHT", scanButton, "LEFT", -8, 0)
    sourceTitle:SetJustifyH("LEFT")
    pane.sourceTitle = sourceTitle

    local clearSlot = UI.CreateButton(sourcePanel, "Clear Slot", 82, 22)
    clearSlot:SetPoint("TOPRIGHT", sourcePanel, "TOPRIGHT", -10, -37)
    pane.clearSlot = clearSlot

    local selectedText = sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    selectedText:SetPoint("TOPLEFT", sourcePanel, "TOPLEFT", 10, -40)
    selectedText:SetPoint("RIGHT", clearSlot, "LEFT", -8, 0)
    selectedText:SetJustifyH("LEFT")
    selectedText:SetWordWrap(false)
    pane.selectedText = selectedText

    local statusText = sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    statusText:SetPoint("TOPLEFT", sourcePanel, "TOPLEFT", 10, -91)
    statusText:SetPoint("RIGHT", sourcePanel, "RIGHT", -10, 0)
    statusText:SetHeight(28)
    statusText:SetJustifyH("LEFT")
    statusText:SetJustifyV("TOP")
    statusText:SetWordWrap(true)
    if statusText.SetMaxLines then statusText:SetMaxLines(2) end
    pane.statusText = statusText

    local statusHitbox = CreateFrame("Button", nil, sourcePanel)
    statusHitbox:SetPoint("TOPLEFT", statusText, "TOPLEFT", -2, 2)
    statusHitbox:SetPoint("BOTTOMRIGHT", statusText, "BOTTOMRIGHT", 2, -2)
    statusHitbox:RegisterForClicks()
    statusHitbox:SetScript("OnEnter", function(self)
        local cache = Wardrobe.GetCache()
        local slotKey = GetCurrentSlot()
        local diagnostics = Wardrobe.GetSlotDiagnostics(slotKey)
        local sources = Wardrobe.GetSlotSources(slotKey)
        local selected = Wardrobe.GetSelectedSource(slotKey)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Wardrobe Scan Details", 1, 0.82, 0)
        GameTooltip:AddLine(BuildDiagnosticsTooltip(cache, diagnostics, #sources, selected), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    statusHitbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pane.statusHitbox = statusHitbox

    local rerollSlot = UI.CreateButton(sourcePanel, "Reroll Slot", 90, 22)
    rerollSlot:SetPoint("TOPLEFT", sourcePanel, "TOPLEFT", 10, -63)
    local lockSlot = UI.CreateButton(sourcePanel, "Lock Slot", 82, 22)
    lockSlot:SetPoint("LEFT", rerollSlot, "RIGHT", 5, 0)
    local hideSlot = UI.CreateButton(sourcePanel, "Hide Slot", 82, 22)
    hideSlot:SetPoint("LEFT", lockSlot, "RIGHT", 5, 0)
    pane.rerollSlot = rerollSlot
    pane.lockSlot = lockSlot
    pane.hideSlot = hideSlot

    UI.SetTooltip(rerollSlot, "Reroll Selected Slot", "Choose another cached appearance for the active equipment slot.")
    UI.SetTooltip(lockSlot, "Lock Selected Slot", "Locked slots survive Generate Outfit and Reroll Unlocked.")
    UI.SetTooltip(hideSlot, "Toggle Slot Visibility", "Hide or show helm, cloak, shirt, or tabard while preserving its selected appearance.")

    rerollSlot:SetScript("OnClick", function()
        local slotKey = GetCurrentSlot()
        local ok, message = Wardrobe.RerollSlot(slotKey)
        if ok then Wardrobe.ApplyPreview(model) end
        pane:Refresh(message)
    end)
    lockSlot:SetScript("OnClick", function()
        local ok, message = Wardrobe.ToggleSlotLocked(GetCurrentSlot())
        if ok then Wardrobe.ApplyPreview(model) end
        pane:Refresh(message)
    end)
    hideSlot:SetScript("OnClick", function()
        local ok, message = Wardrobe.ToggleSlotHidden(GetCurrentSlot())
        if ok then Wardrobe.ApplyPreview(model) end
        pane:Refresh(message)
    end)

    pane.sourceRows = {}
    for index = 1, SOURCE_ROWS do
        local row = CreateFrame("Button", nil, sourcePanel)
        row:SetHeight(SOURCE_ROW_HEIGHT)
        row:SetPoint("LEFT", sourcePanel, "LEFT", 10, 0)
        row:SetPoint("RIGHT", sourcePanel, "RIGHT", -10, 0)
        if index == 1 then
            row:SetPoint("TOP", sourcePanel, "TOP", 0, -122)
        else
            row:SetPoint("TOP", pane.sourceRows[index - 1], "BOTTOM", 0, -SOURCE_ROW_SPACING)
        end

        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(row)
        background:SetColorTexture(0.08, 0.08, 0.08, 0.72)
        row.background = background

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(28, 28)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        row.icon = icon

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 7, -1)
        name:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name

        local detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        detail:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 7, 1)
        detail:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        detail:SetJustifyH("LEFT")
        detail:SetWordWrap(false)
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
                self.background:SetColorTexture(0.13, 0.13, 0.13, 0.9)
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
        row:SetScript("OnLeave", function(self)
            local selected = Wardrobe.GetSelectedSource(GetCurrentSlot())
            local isSelected = self.source and selected and selected.sourceID == self.source.sourceID
            self.background:SetColorTexture(isSelected and 0.12 or 0.08, isSelected and 0.18 or 0.08, isSelected and 0.10 or 0.08, 0.78)
            GameTooltip:Hide()
        end)
        pane.sourceRows[index] = row
    end

    local previousPage = UI.CreateButton(sourcePanel, "Previous", 78, 23)
    previousPage:SetPoint("BOTTOMLEFT", sourcePanel, "BOTTOMLEFT", 10, 10)
    local pageText = sourcePanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    pageText:SetPoint("BOTTOM", sourcePanel, "BOTTOM", 0, 16)
    pageText:SetWidth(120)
    pageText:SetJustifyH("CENTER")
    pane.pageText = pageText
    local nextPage = UI.CreateButton(sourcePanel, "Next", 78, 23)
    nextPage:SetPoint("BOTTOMRIGHT", sourcePanel, "BOTTOMRIGHT", -10, 10)

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

    sourcePanel:EnableMouseWheel(true)
    sourcePanel:SetScript("OnMouseWheel", function(_, delta)
        local slotKey = GetCurrentSlot()
        local sources = Wardrobe.GetSlotSources(slotKey)
        local pageCount = math.max(1, math.ceil(#sources / SOURCE_ROWS))
        local page = GetPage(slotKey)
        if delta > 0 and page > 1 then
            SetPage(slotKey, page - 1)
            pane:Refresh()
        elseif delta < 0 and page < pageCount then
            SetPage(slotKey, page + 1)
            pane:Refresh()
        end
    end)

    scanButton:SetScript("OnClick", function()
        local started, message = Wardrobe.Scan(true)
        if message then
            statusText:SetText(message)
        elseif started then
            statusText:SetText("Wardrobe scan started.")
        else
            statusText:SetText("Unable to scan.")
        end
        pane:Refresh()
    end)

    function pane:GetSuggestedConceptName()
        local concept = Wardrobe.GetCurrentConcept()
        if concept and concept.name then
            return concept.name
        end
        return "Outfit Concept " .. tostring(#Wardrobe.GetConcepts() + 1)
    end

    function pane:SaveConcept(name)
        local ok, message = Wardrobe.SaveConcept(name)
        self:Refresh(message)
        if not ok and UIErrorsFrame then
            UIErrorsFrame:AddMessage(message or "Unable to save outfit concept.", 1, 0.25, 0.25)
        end
    end

    function pane:LoadConcept(conceptID)
        local ok, message = Wardrobe.LoadConcept(conceptID)
        if ok then
            Wardrobe.ApplyPreview(model)
        elseif UIErrorsFrame then
            UIErrorsFrame:AddMessage(message or "Unable to load outfit concept.", 1, 0.25, 0.25)
        end
        self:Refresh(message)
    end

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
            local markers = ""
            if Wardrobe.IsSlotLocked(key) then markers = markers .. " L" end
            if Wardrobe.IsSlotHidden(key) then markers = markers .. " H" end
            button:SetText(string.format("%s (%d)%s", Wardrobe.GetSlotDefinition(key).label, count, markers))
        end

        sourceTitle:SetText((definition and definition.label or "Appearance") .. " Appearances")
        scanButton:SetEnabled(not Wardrobe.IsScanning())
        scanButton:SetText(Wardrobe.IsScanning() and "Scanning..." or (cache.dirty and "Rescan Collection" or "Scan Collection"))

        local selected = Wardrobe.GetSelectedSource(slotKey)
        local hidden = Wardrobe.IsSlotHidden(slotKey)
        local locked = Wardrobe.IsSlotLocked(slotKey)
        local selectedLabel = selected and tostring(selected.name or selected.sourceID) or "currently equipped appearance"
        selectedText:SetText(string.format("Selected: %s%s%s", selectedLabel, locked and " • Locked" or "", hidden and " • Hidden" or ""))
        clearSlot:SetEnabled(selected ~= nil or hidden or locked)
        clearSlot:SetText((selected or hidden or locked) and "Clear Slot" or "No Selection")
        rerollSlot:SetEnabled(not locked and #sources > 0)
        lockSlot:SetText(locked and "Unlock Slot" or "Lock Slot")
        lockSlot:SetEnabled(true)
        hideSlot:SetShown(Wardrobe.IsSlotHideable(slotKey))
        hideSlot:SetText(hidden and "Show Slot" or "Hide Slot")

        local diagnostics = Wardrobe.GetSlotDiagnostics(slotKey)
        statusText:SetText(message or CacheSummary(cache, diagnostics, #sources))

        local canGenerate = not Wardrobe.IsScanning() and cache.totalVisuals > 0
        generateButton:SetEnabled(canGenerate)
        rerollUnlocked:SetEnabled(canGenerate)
        saveConcept:SetEnabled(next(GetState().selections) ~= nil or next(GetState().hidden) ~= nil)
        loadConcept:SetEnabled(#Wardrobe.GetConcepts() > 0)

        local startIndex = ((page - 1) * SOURCE_ROWS) + 1
        for rowIndex, row in ipairs(self.sourceRows) do
            local source = sources[startIndex + rowIndex - 1]
            row.source = source
            row:SetShown(source ~= nil)
            if source then
                row.icon:SetTexture(source.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.name:SetText(SourceLabel(source))
                local valid, reason = Wardrobe.ValidateSource(source, slotKey)
                local isSelected = selected and selected.sourceID == source.sourceID
                local marker = isSelected and (UI.green .. "Selected|r") or (valid and "Collected" or (UI.red .. "Unavailable|r"))
                row.detail:SetText(string.format("%s • Source %d%s", marker, source.sourceID or 0, valid and "" or (" • " .. tostring(reason))))
                row:SetEnabled(valid)
                row.background:SetColorTexture(isSelected and 0.12 or 0.08, isSelected and 0.18 or 0.08, isSelected and 0.10 or 0.08, 0.78)
            end
        end

        pageText:SetText(string.format("Page %d of %d", page, pageCount))
        previousPage:SetEnabled(page > 1)
        nextPage:SetEnabled(page < pageCount)
        local concept = Wardrobe.GetCurrentConcept()
        local conceptText = concept and (" • Concept: " .. tostring(concept.name or "Unnamed")) or ""
        subtitle:SetText(string.format("%s collected appearances cached for %s%s. Preview only; no outfit is applied.", UI.FormatNumber(#sources), definition and definition.label or slotKey, conceptText))
    end

    QC.RegisterCallback("WARDROBE_SCAN_PROGRESS", pane, function(index, total, slotKey, count, diagnostics)
        if pane:IsShown() then
            local expected = diagnostics and diagnostics.expectedCollected or 0
            pane:Refresh(string.format("Scanning %d of %d: %s • %s visuals from %s collected sources", index or 0, total or 0, Wardrobe.GetSlotDefinition(slotKey) and Wardrobe.GetSlotDefinition(slotKey).label or slotKey, UI.FormatNumber(count or 0), UI.FormatNumber(expected or 0)))
        end
    end)
    QC.RegisterCallback("WARDROBE_SCAN_COMPLETE", pane, function(cache)
        Wardrobe.ApplyPreview(model)
        if pane:IsShown() then
            pane:Refresh(cache and cache.scanError or "Wardrobe collection scan complete.")
        end
    end)
    QC.RegisterCallback("WARDROBE_CACHE_DIRTY", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("WARDROBE_SELECTION_CHANGED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("WARDROBE_WORKBENCH_CHANGED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("WARDROBE_CONCEPTS_CHANGED", pane, function()
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
