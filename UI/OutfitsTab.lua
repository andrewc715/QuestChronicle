local QC = QuestChronicle
local UI = QC.UI
local Wardrobe = QC.Wardrobe
local ZoneStyle = QC.ZoneStyle

local SOURCE_ROWS = 7
local SOURCE_ROW_HEIGHT = 37
local SOURCE_ROW_SPACING = 2
local CONCEPT_ROWS = 4

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

local function ShowAppearanceTooltip(owner, source, slotKey, leadText)
    if not source then return end
    local styleMode = ZoneStyle.GetMode()
    local styleContext = ZoneStyle.GetCurrentContext()
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:SetText(source.name or "Appearance", 1, 0.82, 0)
    GameTooltip:AddLine(leadText or "Click to preview this collected appearance.", 1, 1, 1, true)
    GameTooltip:AddLine("Source ID: " .. tostring(source.sourceID or 0), 0.65, 0.65, 0.65)
    if source.itemID then
        GameTooltip:AddLine("Item ID: " .. tostring(source.itemID), 0.65, 0.65, 0.65)
    end

    local valid, reason = Wardrobe.ValidateSource(source, slotKey)
    GameTooltip:AddLine(valid and "Compatible" or reason, valid and 0.2 or 1, valid and 1 or 0.25, valid and 0.2 or 0.25, true)
    if valid then
        local definition = Wardrobe.GetSlotDefinition(slotKey)
        local eligible, _, eligibilityReason = ZoneStyle.GetEligibilitySummary(source, styleMode, styleContext)
        GameTooltip:AddLine((eligible and "Generated pool: " or "Excluded from generation: ") .. tostring(eligibilityReason), eligible and 0.2 or 1, eligible and 1 or 0.35, eligible and 0.2 or 0.2, true)
        GameTooltip:AddLine(ZoneStyle.GetScoreSummary(source, definition, styleMode, styleContext), 1, 0.82, 0, true)
        local preference = Wardrobe.GetSourceZonePreference(source, styleContext)
        if preference == "favorite" then
            GameTooltip:AddLine("Zone favorite: strongly weighted when eligible.", 1, 0.82, 0, true)
        elseif preference == "excluded" then
            GameTooltip:AddLine("Zone exclusion: never generated here; manual preview remains available.", 1, 0.25, 0.25, true)
        end
    end
    GameTooltip:Show()
end

local function CountMap(values)
    local count = 0
    for _, value in pairs(values or {}) do
        if value ~= nil and value ~= false then
            count = count + 1
        end
    end
    return count
end

local function ConceptDetail(concept)
    local updated = concept.updatedAt and UI.FormatShortTimestamp(concept.updatedAt) or "Unknown time"
    local mode = concept.styleMode and ZoneStyle and ZoneStyle.GetModeInfo(concept.styleMode)
    return string.format(
        "%d appearances • %d locked • %d hidden • %s • %s",
        CountMap(concept.selections),
        CountMap(concept.locks),
        CountMap(concept.hidden),
        mode and mode.label or "Current mode",
        updated
    )
end

local function CreateLockedSlotVisual(button)
    local previewBackground = button:CreateTexture(nil, "BORDER")
    previewBackground:SetSize(19, 19)
    previewBackground:SetPoint("LEFT", button, "LEFT", 3, 0)
    previewBackground:SetColorTexture(0.02, 0.02, 0.02, 0.9)
    previewBackground:Hide()
    button.previewIconBackground = previewBackground

    local previewIcon = button:CreateTexture(nil, "ARTWORK")
    previewIcon:SetSize(17, 17)
    previewIcon:SetPoint("CENTER", previewBackground, "CENTER", 0, 0)
    previewIcon:Hide()
    button.previewIcon = previewIcon

    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetSize(15, 15)
    icon:SetPoint("RIGHT", button, "RIGHT", -4, 0)
    icon:SetTexture("Interface\\Buttons\\LockButton-Locked-Up")
    icon:SetVertexColor(1, 0.82, 0.12)
    icon:Hide()
    button.lockIcon = icon

    local edges = {}
    local function Edge(point1, point2, width, height)
        local edge = button:CreateTexture(nil, "OVERLAY")
        edge:SetColorTexture(1, 0.72, 0.08, 0.95)
        edge:SetPoint(point1, button, point1, 0, 0)
        edge:SetPoint(point2, button, point2, 0, 0)
        if width then edge:SetWidth(width) end
        if height then edge:SetHeight(height) end
        edge:Hide()
        table.insert(edges, edge)
    end
    Edge("TOPLEFT", "TOPRIGHT", nil, 2)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 2)
    Edge("TOPLEFT", "BOTTOMLEFT", 2, nil)
    Edge("TOPRIGHT", "BOTTOMRIGHT", 2, nil)
    button.lockEdges = edges

    local label = button:GetFontString()
    if label then
        label:ClearAllPoints()
        label:SetPoint("LEFT", button, "LEFT", 23, 0)
        label:SetPoint("RIGHT", button, "RIGHT", -20, 0)
        label:SetJustifyH("CENTER")
    end
end

local function SetLockedSlotVisual(button, locked)
    button.lockIcon:SetShown(locked)
    for _, edge in ipairs(button.lockEdges or {}) do
        edge:SetShown(locked)
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
    local maintenance = cache.autoRefreshPending and " • Auto refresh queued" or (cache.dirty and " • Refresh recommended" or "")
    local expected = diagnostics and tonumber(diagnostics.expectedCollected) or 0
    if expected > 0 then
        return string.format(
            "%s previewable visuals • %s collected sources • Scanned %s%s",
            UI.FormatNumber(sourceCount),
            UI.FormatNumber(expected),
            scanned,
            maintenance
        )
    end

    return string.format(
        "%s previewable visuals • Scanned %s%s",
        UI.FormatNumber(sourceCount),
        scanned,
        maintenance
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
    if cache.scanDurationMS then
        table.insert(lines, string.format("Last scan duration: %.1f seconds", cache.scanDurationMS / 1000))
    end
    if cache.autoRefreshPending then
        table.insert(lines, "Automatic refresh: waiting for a quiet moment")
    elseif cache.lastAutoRefreshAt then
        table.insert(lines, "Last automatic refresh: " .. UI.FormatShortTimestamp(cache.lastAutoRefreshAt))
    end
    if cache.lastRecovery then
        local recovered = (cache.lastRecovery.previewRecovered or 0) + (cache.lastRecovery.conceptRecovered or 0)
        table.insert(lines, string.format("Last recovery: %d rebound • %d still unavailable", recovered, cache.lastRecovery.missing or 0))
    end

    table.insert(lines, "")
    table.insert(lines, "These counts are not expected to match exactly. Multiple item sources can share one visual, and unusable appearances are excluded from the preview cache.")
    return table.concat(lines, "\n")
end

local function SetSourceRowBackground(row, selected, preference)
    local highContrast = QC.GetSettings and QC.GetSettings().highContrastOutfitStates == true
    if preference == "excluded" then
        row.background:SetColorTexture(highContrast and 0.34 or 0.16, highContrast and 0.035 or 0.055, highContrast and 0.035 or 0.055, highContrast and 0.96 or 0.82)
    elseif preference == "favorite" then
        row.background:SetColorTexture(highContrast and 0.32 or 0.16, highContrast and 0.22 or 0.13, highContrast and 0.025 or 0.045, highContrast and 0.96 or 0.82)
    elseif selected then
        row.background:SetColorTexture(highContrast and 0.055 or 0.12, highContrast and 0.32 or 0.18, highContrast and 0.055 or 0.10, highContrast and 0.96 or 0.78)
    else
        local shade = highContrast and 0.035 or 0.08
        row.background:SetColorTexture(shade, shade, shade, highContrast and 0.94 or 0.78)
    end
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
    local lookPanel

    local slotTitle = slotPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slotTitle:SetPoint("TOP", slotPanel, "TOP", 0, -10)
    slotTitle:SetText("Equipment Slot")

    pane.slotButtons = {}
    local previous
    for _, definition in ipairs(Wardrobe.slotDefinitions) do
        local button = UI.CreateButton(slotPanel, definition.label, 108, 22)
        CreateLockedSlotVisual(button)
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
        button:SetScript("OnEnter", function(self)
            local entry = self.previewEntry
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local slotDefinition = Wardrobe.GetSlotDefinition(self.slotKey)
            GameTooltip:SetText((slotDefinition and slotDefinition.label or self.slotKey) .. " Slot", 1, 0.82, 0)
            if entry then
                GameTooltip:AddLine(entry.name or "Empty", 1, 1, 1, true)
                local stateText = entry.kind or "Preview"
                if entry.locked then stateText = stateText .. " • Locked" end
                if entry.hidden then stateText = stateText .. " • Hidden" end
                GameTooltip:AddLine(stateText, entry.hidden and 0.65 or 0.2, entry.hidden and 0.65 or 1, entry.hidden and 0.65 or 0.2)
            else
                GameTooltip:AddLine("Not active in the current preview.", 0.65, 0.65, 0.65, true)
            end
            GameTooltip:AddLine(string.format("%s cached appearances", UI.FormatNumber(#(Wardrobe.GetSlotSources(self.slotKey) or {}))), 0.65, 0.65, 0.65)
            GameTooltip:AddLine("Click to browse this slot.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        pane.slotButtons[definition.key] = button
        previous = button
    end

    local currentLookButton = UI.CreateButton(slotPanel, "Current Look", 108, 24)
    currentLookButton:SetPoint("BOTTOM", slotPanel, "BOTTOM", 0, 10)
    UI.SetTooltip(currentLookButton, "Current Character Preview", "Show every selected, equipped, hidden, and locked layer currently represented by the embedded model.")

    local modelTitle = modelPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    modelTitle:SetPoint("TOPLEFT", modelPanel, "TOPLEFT", 8, -10)
    modelTitle:SetPoint("RIGHT", modelPanel, "RIGHT", -8, 0)
    modelTitle:SetJustifyH("CENTER")
    modelTitle:SetWordWrap(false)
    modelTitle:SetText("Character Preview")

    pane.styleButtons = {}
    local previousStyleButton
    for _, mode in ipairs(ZoneStyle.modes) do
        local button = UI.CreateButton(modelPanel, mode.shortLabel, 67, 22)
        if previousStyleButton then
            button:SetPoint("LEFT", previousStyleButton, "RIGHT", 3, 0)
        else
            button:SetPoint("TOPLEFT", modelPanel, "TOPLEFT", 8, -29)
        end
        button.modeKey = mode.key
        button:SetScript("OnClick", function(self)
            ZoneStyle.SetMode(self.modeKey)
            pane:Refresh("Generation mode changed to " .. ZoneStyle.GetModeInfo(self.modeKey).label .. ".")
        end)
        UI.SetTooltip(button, mode.label, mode.description)
        pane.styleButtons[mode.key] = button
        previousStyleButton = button
    end

    local styleInfo = modelPanel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    styleInfo:SetPoint("TOPLEFT", modelPanel, "TOPLEFT", 8, -54)
    styleInfo:SetPoint("RIGHT", modelPanel, "RIGHT", -8, 0)
    styleInfo:SetHeight(40)
    styleInfo:SetJustifyH("CENTER")
    styleInfo:SetWordWrap(true)
    pane.styleInfo = styleInfo

    local model = CreateFrame("DressUpModel", nil, modelPanel)
    model:SetPoint("TOPLEFT", modelPanel, "TOPLEFT", 8, -98)
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

    UI.SetTooltip(generateButton, "Generate Outfit", "Build a promo-free weighted outfit in the selected style. Quest Chronicle starts with the major armor silhouette, favors pieces from the same Blizzard transmog set or shared motif, rejects isolated dramatic outliers, and keeps weapons within Blizzard's equipped-item rules. Locked and hidden choices are preserved.")
    UI.SetTooltip(rerollUnlocked, "Reroll Unlocked", "Replace every unlocked choice using the same promo-free, set-aware, motif-coherent rules while preserving Blizzard-safe weapon compatibility.")
    UI.SetTooltip(saveConcept, "Save Concept", "Open the Outfit Concepts manager to name and save the current selections, locks, hidden slots, and weapon configuration.")
    UI.SetTooltip(loadConcept, "Outfit Concepts", "Open the Outfit Concepts manager to inspect, load, overwrite, or delete this character's saved concepts.")
    UI.SetTooltip(clearAll, "Reset Outfit", "Clear selections, locks, and hidden-slot choices, returning the preview to currently equipped gear.")

    generateButton:SetScript("OnClick", function()
        local ok, message = Wardrobe.GenerateOutfit(false, ZoneStyle.GetMode())
        if ok then Wardrobe.ApplyPreview(model) end
        pane:Refresh(message)
    end)
    rerollUnlocked:SetScript("OnClick", function()
        local ok, message = Wardrobe.GenerateOutfit(true, ZoneStyle.GetMode())
        if ok then Wardrobe.ApplyPreview(model) end
        pane:Refresh(message)
    end)
    clearAll:SetScript("OnClick", function()
        Wardrobe.ClearAllSelections()
        Wardrobe.ApplyPreview(model)
        pane:Refresh("Outfit preview reset to currently equipped gear.")
    end)

    -- A self-contained manager replaces the fragile popup/context-menu pair.
    -- It stays inside Quest Chronicle's frame strata and exposes the complete
    -- concept lifecycle: save, overwrite by name, select, load, and delete.
    local conceptBlocker = CreateFrame("Button", nil, pane)
    conceptBlocker:SetAllPoints(pane)
    conceptBlocker:SetFrameLevel(pane:GetFrameLevel() + 40)
    local blockerShade = conceptBlocker:CreateTexture(nil, "BACKGROUND")
    blockerShade:SetAllPoints(conceptBlocker)
    blockerShade:SetColorTexture(0, 0, 0, 0.58)
    conceptBlocker:Hide()

    local conceptManager = UI.CreateInsetPanel(pane)
    conceptManager:SetSize(450, 350)
    conceptManager:SetPoint("CENTER", pane, "CENTER", 0, -4)
    conceptManager:SetFrameLevel(pane:GetFrameLevel() + 41)
    conceptManager:EnableMouse(true)
    conceptManager:Hide()
    pane.conceptManager = conceptManager

    local managerTitle = conceptManager:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    managerTitle:SetPoint("TOPLEFT", conceptManager, "TOPLEFT", 14, -13)
    managerTitle:SetText("Outfit Concepts")

    local managerClose = UI.CreateButton(conceptManager, "X", 26, 24)
    managerClose:SetPoint("TOPRIGHT", conceptManager, "TOPRIGHT", -9, -8)

    local nameLabel = conceptManager:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameLabel:SetPoint("TOPLEFT", conceptManager, "TOPLEFT", 15, -47)
    nameLabel:SetText("Concept Name")

    local conceptName = CreateFrame("EditBox", nil, conceptManager, "InputBoxTemplate")
    conceptName:SetSize(278, 26)
    conceptName:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 2, -3)
    conceptName:SetAutoFocus(false)
    conceptName:SetMaxLetters(48)
    pane.conceptName = conceptName

    local saveCurrent = UI.CreateButton(conceptManager, "Save / Update", 122, 25)
    saveCurrent:SetPoint("LEFT", conceptName, "RIGHT", 11, 0)
    UI.SetTooltip(saveCurrent, "Save Current Preview", "Saving an existing concept name overwrites it. Entering a new name creates another concept for this character.")

    local managerStatus = conceptManager:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    managerStatus:SetPoint("TOPLEFT", conceptManager, "TOPLEFT", 15, -89)
    managerStatus:SetPoint("RIGHT", conceptManager, "RIGHT", -15, 0)
    managerStatus:SetHeight(20)
    managerStatus:SetJustifyH("LEFT")
    managerStatus:SetWordWrap(false)

    conceptManager.rows = {}
    for index = 1, CONCEPT_ROWS do
        local row = CreateFrame("Button", nil, conceptManager)
        row:SetHeight(43)
        row:SetPoint("LEFT", conceptManager, "LEFT", 15, 0)
        row:SetPoint("RIGHT", conceptManager, "RIGHT", -15, 0)
        if index == 1 then
            row:SetPoint("TOP", conceptManager, "TOP", 0, -112)
        else
            row:SetPoint("TOP", conceptManager.rows[index - 1], "BOTTOM", 0, -4)
        end

        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(row)
        background:SetColorTexture(0.07, 0.07, 0.07, 0.92)
        row.background = background

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        name:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -6)
        name:SetPoint("RIGHT", row, "RIGHT", -9, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name

        local detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        detail:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 9, 6)
        detail:SetPoint("RIGHT", row, "RIGHT", -9, 0)
        detail:SetJustifyH("LEFT")
        detail:SetWordWrap(false)
        row.detail = detail

        row:SetScript("OnClick", function(self)
            if self.concept then
                conceptManager.selectedConceptID = self.concept.id
                conceptManager.pendingDeleteID = nil
                conceptName:SetText(self.concept.name or "")
                conceptManager:Refresh()
            end
        end)
        row:SetScript("OnEnter", function(self)
            if self.concept then
                self.background:SetColorTexture(0.18, 0.14, 0.06, 0.96)
            end
        end)
        row:SetScript("OnLeave", function(self)
            local selected = self.concept and self.concept.id == conceptManager.selectedConceptID
            self.background:SetColorTexture(selected and 0.20 or 0.07, selected and 0.15 or 0.07, selected and 0.05 or 0.07, 0.92)
        end)
        conceptManager.rows[index] = row
    end

    local previousConcepts = UI.CreateButton(conceptManager, "<", 28, 23)
    previousConcepts:SetPoint("BOTTOMLEFT", conceptManager, "BOTTOMLEFT", 15, 12)
    local conceptPage = conceptManager:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    conceptPage:SetPoint("LEFT", previousConcepts, "RIGHT", 6, 0)
    conceptPage:SetWidth(72)
    conceptPage:SetJustifyH("CENTER")
    local nextConcepts = UI.CreateButton(conceptManager, ">", 28, 23)
    nextConcepts:SetPoint("LEFT", conceptPage, "RIGHT", 6, 0)

    local loadSelected = UI.CreateButton(conceptManager, "Load Selected", 110, 23)
    loadSelected:SetPoint("BOTTOM", conceptManager, "BOTTOM", 36, 12)
    local deleteSelected = UI.CreateButton(conceptManager, "Delete", 96, 23)
    deleteSelected:SetPoint("LEFT", loadSelected, "RIGHT", 7, 0)
    UI.SetTooltip(loadSelected, "Load Selected Concept", "Restore the selected appearances, locks, hidden slots, and weapon configuration to the preview.")
    UI.SetTooltip(deleteSelected, "Delete Selected Concept", "Requires a second confirmation click. Deleting a concept does not change the current preview.")

    function conceptManager:Refresh(message)
        local concepts = Wardrobe.GetConcepts()
        local pageCount = math.max(1, math.ceil(#concepts / CONCEPT_ROWS))
        self.page = math.max(1, math.min(tonumber(self.page) or 1, pageCount))

        local selectedExists = false
        for _, concept in ipairs(concepts) do
            if concept.id == self.selectedConceptID then
                selectedExists = true
                break
            end
        end
        if not selectedExists then
            self.selectedConceptID = nil
            self.pendingDeleteID = nil
        end

        local startIndex = ((self.page - 1) * CONCEPT_ROWS) + 1
        for rowIndex, row in ipairs(self.rows) do
            local concept = concepts[startIndex + rowIndex - 1]
            row.concept = concept
            row:SetShown(concept ~= nil)
            if concept then
                local selected = concept.id == self.selectedConceptID
                row.name:SetText((selected and UI.gold or UI.white) .. tostring(concept.name or "Unnamed Concept") .. UI.reset)
                row.detail:SetText(ConceptDetail(concept))
                row.background:SetColorTexture(selected and 0.20 or 0.07, selected and 0.15 or 0.07, selected and 0.05 or 0.07, 0.92)
            end
        end

        local canSave = next(GetState().selections) ~= nil or next(GetState().locks) ~= nil or next(GetState().hidden) ~= nil
        saveCurrent:SetEnabled(canSave)
        loadSelected:SetEnabled(self.selectedConceptID ~= nil)
        deleteSelected:SetEnabled(self.selectedConceptID ~= nil)
        deleteSelected:SetText(self.pendingDeleteID == self.selectedConceptID and "Confirm Delete" or "Delete")
        previousConcepts:SetEnabled(self.page > 1)
        nextConcepts:SetEnabled(self.page < pageCount)
        conceptPage:SetText(string.format("%d / %d", self.page, pageCount))
        managerStatus:SetText(message or (#concepts > 0 and string.format("%d saved concept%s for this character.", #concepts, #concepts == 1 and "" or "s") or "No concepts saved yet. Name the current preview and save it."))
    end

    function conceptManager:Open(forSaving)
        local concepts = Wardrobe.GetConcepts()
        local current = Wardrobe.GetCurrentConcept()
        self.selectedConceptID = current and current.id or (not forSaving and concepts[1] and concepts[1].id or nil)
        self.pendingDeleteID = nil
        self.page = 1
        if self.selectedConceptID then
            for index, concept in ipairs(concepts) do
                if concept.id == self.selectedConceptID then
                    self.page = math.ceil(index / CONCEPT_ROWS)
                    break
                end
            end
        end
        conceptName:SetText(current and current.name or (forSaving and pane:GetSuggestedConceptName() or (concepts[1] and concepts[1].name or pane:GetSuggestedConceptName())))
        conceptBlocker:Show()
        self:Show()
        self:Refresh()
        if forSaving then
            conceptName:SetFocus()
            conceptName:HighlightText()
        else
            conceptName:ClearFocus()
        end
    end

    local function CloseConceptManager()
        conceptName:ClearFocus()
        conceptManager:Hide()
        conceptBlocker:Hide()
    end

    managerClose:SetScript("OnClick", CloseConceptManager)
    conceptManager:SetScript("OnHide", function()
        conceptBlocker:Hide()
    end)
    conceptName:SetScript("OnEscapePressed", CloseConceptManager)
    conceptName:SetScript("OnEnterPressed", function()
        saveCurrent:Click()
    end)
    previousConcepts:SetScript("OnClick", function()
        conceptManager.page = conceptManager.page - 1
        conceptManager.selectedConceptID = nil
        conceptManager.pendingDeleteID = nil
        conceptManager:Refresh()
    end)
    nextConcepts:SetScript("OnClick", function()
        conceptManager.page = conceptManager.page + 1
        conceptManager.selectedConceptID = nil
        conceptManager.pendingDeleteID = nil
        conceptManager:Refresh()
    end)
    saveCurrent:SetScript("OnClick", function()
        local ok, message, concept = pane:SaveConcept(conceptName:GetText())
        if ok and concept then
            conceptManager.selectedConceptID = concept.id
            conceptManager.pendingDeleteID = nil
            conceptManager.page = 1
            conceptName:SetText(concept.name or "")
            conceptName:ClearFocus()
        end
        conceptManager:Refresh(message)
    end)
    loadSelected:SetScript("OnClick", function()
        if conceptManager.selectedConceptID then
            local ok = pane:LoadConcept(conceptManager.selectedConceptID)
            if ok then
                CloseConceptManager()
            end
        end
    end)
    deleteSelected:SetScript("OnClick", function()
        local conceptID = conceptManager.selectedConceptID
        if not conceptID then return end
        if conceptManager.pendingDeleteID ~= conceptID then
            conceptManager.pendingDeleteID = conceptID
            conceptManager:Refresh("Click Confirm Delete to permanently remove the selected concept.")
            return
        end
        local ok, message = Wardrobe.DeleteConcept(conceptID)
        if ok then
            conceptManager.selectedConceptID = nil
            conceptManager.pendingDeleteID = nil
            pane:Refresh(message)
        elseif UIErrorsFrame then
            UIErrorsFrame:AddMessage(message or "Unable to delete outfit concept.", 1, 0.25, 0.25)
        end
        conceptManager:Refresh(message)
    end)

    saveConcept:SetScript("OnClick", function()
        conceptManager:Open(true)
    end)
    loadConcept:SetScript("OnClick", function()
        conceptManager:Open(false)
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
    statusText:SetPoint("TOPLEFT", sourcePanel, "TOPLEFT", 10, -116)
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
    local favoriteSource = UI.CreateButton(sourcePanel, "Favor in Zone", 92, 22)
    favoriteSource:SetPoint("TOPLEFT", sourcePanel, "TOPLEFT", 10, -88)
    local excludeSource = UI.CreateButton(sourcePanel, "Exclude in Zone", 100, 22)
    excludeSource:SetPoint("LEFT", favoriteSource, "RIGHT", 5, 0)
    pane.rerollSlot = rerollSlot
    pane.lockSlot = lockSlot
    pane.hideSlot = hideSlot
    pane.favoriteSource = favoriteSource
    pane.excludeSource = excludeSource

    UI.SetTooltip(rerollSlot, "Reroll Selected Slot", "Choose another cached appearance. Weapon rerolls must be valid for the currently equipped item.")
    UI.SetTooltip(lockSlot, "Lock Selected Slot", "Locked slots survive Generate Outfit and Reroll Unlocked.")
    UI.SetTooltip(hideSlot, "Toggle Slot Visibility", "Hide or show helm, cloak, shirt, or tabard while preserving its selected appearance.")
    UI.SetTooltip(favoriteSource, "Favorite for This Zone", "Strongly favor the selected visual when generating outfits in this zone. Favorites still obey era, provenance, promotion, coherence, and weapon rules.")
    UI.SetTooltip(excludeSource, "Exclude for This Zone", "Never generate the selected visual in this zone. You can still browse and preview it manually.")

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
    favoriteSource:SetScript("OnClick", function()
        local selected = Wardrobe.GetSelectedSource(GetCurrentSlot())
        local ok, message = Wardrobe.ToggleZoneFavorite(GetCurrentSlot(), selected and selected.sourceID, ZoneStyle.GetCurrentContext())
        if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "Unable to favorite this appearance.", 1, 0.25, 0.25) end
        pane:Refresh(message)
    end)
    excludeSource:SetScript("OnClick", function()
        local selected = Wardrobe.GetSelectedSource(GetCurrentSlot())
        local ok, message = Wardrobe.ToggleZoneExclusion(GetCurrentSlot(), selected and selected.sourceID, ZoneStyle.GetCurrentContext())
        if not ok and UIErrorsFrame then UIErrorsFrame:AddMessage(message or "Unable to exclude this appearance.", 1, 0.25, 0.25) end
        pane:Refresh(message)
    end)

    pane.sourceRows = {}
    for index = 1, SOURCE_ROWS do
        local row = CreateFrame("Button", nil, sourcePanel)
        row:SetHeight(SOURCE_ROW_HEIGHT)
        row:SetPoint("LEFT", sourcePanel, "LEFT", 10, 0)
        row:SetPoint("RIGHT", sourcePanel, "RIGHT", -10, 0)
        if index == 1 then
            row:SetPoint("TOP", sourcePanel, "TOP", 0, -148)
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
                ShowAppearanceTooltip(self, self.source, GetCurrentSlot())
            end
        end)
        row:SetScript("OnLeave", function(self)
            local selected = Wardrobe.GetSelectedSource(GetCurrentSlot())
            local isSelected = self.source and selected and selected.sourceID == self.source.sourceID
            local preference = self.source and Wardrobe.GetSourceZonePreference(self.source, ZoneStyle.GetCurrentContext())
            SetSourceRowBackground(self, isSelected, preference)
            GameTooltip:Hide()
        end)
        pane.sourceRows[index] = row
    end

    lookPanel = UI.CreateInsetPanel(sourcePanel)
    lookPanel:SetAllPoints(sourcePanel)
    lookPanel:SetFrameLevel(sourcePanel:GetFrameLevel() + 30)
    lookPanel:Hide()
    pane.lookPanel = lookPanel

    local lookTitle = lookPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    lookTitle:SetPoint("TOPLEFT", lookPanel, "TOPLEFT", 14, -14)
    lookTitle:SetText("Current Character Preview")
    local lookSubtitle = lookPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    lookSubtitle:SetPoint("TOPLEFT", lookTitle, "BOTTOMLEFT", 0, -4)
    lookSubtitle:SetPoint("RIGHT", lookPanel, "RIGHT", -90, 0)
    lookSubtitle:SetJustifyH("LEFT")
    lookSubtitle:SetText("Selected appearances override equipped gear. Hidden layers remain listed.")
    local closeLook = UI.CreateButton(lookPanel, "Close", 66, 22)
    closeLook:SetPoint("TOPRIGHT", lookPanel, "TOPRIGHT", -10, -10)
    closeLook:SetScript("OnClick", function() lookPanel:Hide() end)

    pane.lookRows = {}
    for index = 1, 14 do
        local row = CreateFrame("Button", nil, lookPanel)
        row:SetHeight(39)
        local column = index > 7 and 2 or 1
        local rowIndex = column == 2 and index - 7 or index
        if column == 1 then
            row:SetPoint("TOPLEFT", lookPanel, "TOPLEFT", 12, -64 - ((rowIndex - 1) * 42))
            row:SetPoint("RIGHT", lookPanel, "CENTER", -4, 0)
        else
            row:SetPoint("TOPLEFT", lookPanel, "TOP", 4, -64 - ((rowIndex - 1) * 42))
            row:SetPoint("RIGHT", lookPanel, "RIGHT", -12, 0)
        end
        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints(row)
        background:SetColorTexture(0.07, 0.07, 0.07, 0.88)
        row.background = background
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(30, 30)
        icon:SetPoint("LEFT", row, "LEFT", 5, 0)
        row.icon = icon
        local slot = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        slot:SetPoint("TOPLEFT", icon, "TOPRIGHT", 7, -1)
        slot:SetWidth(76)
        slot:SetJustifyH("LEFT")
        row.slot = slot
        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        name:SetPoint("TOPLEFT", slot, "TOPRIGHT", 3, 0)
        name:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        row.name = name
        local detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        detail:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 7, 1)
        detail:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        detail:SetJustifyH("LEFT")
        row.detail = detail
        row:SetScript("OnEnter", function(self)
            if not self.entry then return end
            self.background:SetColorTexture(0.13, 0.13, 0.13, 0.95)
            if self.entry.source then
                local previewState = self.entry.kind or "Selected"
                if self.entry.locked then previewState = previewState .. " • Locked" end
                if self.entry.hidden then previewState = previewState .. " • Hidden" end
                ShowAppearanceTooltip(self, self.entry.source, self.entry.slotKey, "Current preview: " .. previewState .. ".")
            else
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetText(self.entry.name or (self.entry.label .. " equipment"), 1, 0.82, 0)
                GameTooltip:AddLine("Currently equipped in the " .. tostring(self.entry.label) .. " slot.", 1, 1, 1, true)
                if self.entry.itemID then GameTooltip:AddLine("Item ID: " .. tostring(self.entry.itemID), 0.65, 0.65, 0.65) end
                GameTooltip:AddLine("No collected appearance is overriding this slot in the preview.", 0.65, 0.65, 0.65, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self.background:SetColorTexture(0.07, 0.07, 0.07, 0.88)
            GameTooltip:Hide()
        end)
        pane.lookRows[index] = row
    end

    function pane:RefreshCurrentLook()
        local manifest = Wardrobe.GetPreviewManifest()
        local generatedName = Wardrobe.GetGeneratedOutfitName()
        lookTitle:SetText(generatedName and ("Current Preview: " .. generatedName) or "Current Character Preview")
        for index, row in ipairs(self.lookRows) do
            local entry = manifest[index]
            row.entry = entry
            row:SetShown(entry ~= nil)
            if entry then
                row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                if row.icon.SetDesaturated then row.icon:SetDesaturated(entry.hidden == true) end
                row.slot:SetText(entry.label)
                row.name:SetText(entry.name)
                local detail = entry.kind
                if entry.locked then detail = detail .. " • Locked" end
                if entry.hidden then detail = detail .. " • Hidden" end
                row.detail:SetText(detail)
            end
        end
        return manifest
    end

    currentLookButton:SetScript("OnClick", function()
        if lookPanel:IsShown() then
            lookPanel:Hide()
        else
            pane:RefreshCurrentLook()
            lookPanel:Show()
        end
    end)

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
        local generatedName = Wardrobe.GetGeneratedOutfitName()
        if generatedName and generatedName ~= "" then return generatedName end
        return "Outfit Concept " .. tostring(#Wardrobe.GetConcepts() + 1)
    end

    function pane:SaveConcept(name)
        local ok, message, concept = Wardrobe.SaveConcept(name)
        self:Refresh(message)
        if not ok and UIErrorsFrame then
            UIErrorsFrame:AddMessage(message or "Unable to save outfit concept.", 1, 0.25, 0.25)
        end
        return ok, message, concept
    end

    function pane:LoadConcept(conceptID)
        local ok, message, concept = Wardrobe.LoadConcept(conceptID)
        if ok then
            Wardrobe.ApplyPreview(model)
        elseif UIErrorsFrame then
            UIErrorsFrame:AddMessage(message or "Unable to load outfit concept.", 1, 0.25, 0.25)
        end
        self:Refresh(message)
        return ok, message, concept
    end

    function pane:Refresh(message)
        local cache = Wardrobe.GetCache()
        local slotKey = GetCurrentSlot()
        local definition = Wardrobe.GetSlotDefinition(slotKey) or Wardrobe.slotDefinitions[1]
        local sources = Wardrobe.GetSlotSources(slotKey)
        local pageCount = math.max(1, math.ceil(#sources / SOURCE_ROWS))
        local page = math.min(GetPage(slotKey), pageCount)
        SetPage(slotKey, page)

        local styleMode = ZoneStyle.GetMode()
        local styleContext = ZoneStyle.GetCurrentContext()
        local pendingSuggestion = ZoneStyle.GetPendingSuggestion()
        local restrictionLabel = ZoneStyle.GetContextRestrictionLabel(styleContext)
        local chronicleSummary = ZoneStyle.GetChronicleSummary(styleContext)
        local favoriteCount, exclusionCount = Wardrobe.GetZonePreferenceSummary(styleContext)
        local generatedName = Wardrobe.GetGeneratedOutfitName()
        modelTitle:SetText(generatedName and ("Character Preview: " .. generatedName) or "Character Preview")
        for modeKey, button in pairs(self.styleButtons) do
            local mode = ZoneStyle.GetModeInfo(modeKey)
            local marker = modeKey == ZoneStyle.MODE_ZONE_NATIVE and pendingSuggestion and " *" or ""
            button:SetText(mode.shortLabel .. marker)
            button:SetEnabled(modeKey ~= styleMode)
        end
        styleInfo:SetText(string.format(
            "%s • %s\n%s%s\n%s • %d favored • %d excluded",
            styleContext.profileLabel or "Azeroth Adventurer",
            styleContext.provenanceLabel or styleContext.zone or "Unknown Zone",
            restrictionLabel,
            pendingSuggestion and " • Suggestion ready" or "",
            chronicleSummary,
            favoriteCount,
            exclusionCount
        ))

        local manifest = self:RefreshCurrentLook()
        local manifestBySlot = {}
        for _, entry in ipairs(manifest) do manifestBySlot[entry.slotKey] = entry end
        currentLookButton:SetText(string.format("Current Look (%d)", #manifest))
        for key, button in pairs(self.slotButtons) do
            button:SetEnabled(key ~= slotKey)
            local lockedSlot = Wardrobe.IsSlotLocked(key)
            local markers = ""
            if Wardrobe.IsSlotHidden(key) then markers = markers .. " H" end
            button:SetText(string.format("%s%s", Wardrobe.GetSlotDefinition(key).label, markers))
            local previewEntry = manifestBySlot[key]
            button.previewEntry = previewEntry
            local hasIcon = previewEntry and previewEntry.icon ~= nil
            button.previewIconBackground:SetShown(hasIcon)
            button.previewIcon:SetShown(hasIcon)
            if hasIcon then
                button.previewIcon:SetTexture(previewEntry.icon)
                if button.previewIcon.SetDesaturated then button.previewIcon:SetDesaturated(previewEntry.hidden == true) end
            end
            SetLockedSlotVisual(button, lockedSlot)
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
        local sourcePreference = selected and Wardrobe.GetSourceZonePreference(selected, styleContext)
        favoriteSource:SetEnabled(selected ~= nil)
        excludeSource:SetEnabled(selected ~= nil)
        favoriteSource:SetText(sourcePreference == "favorite" and "Unfavor" or "Favor in Zone")
        excludeSource:SetText(sourcePreference == "excluded" and "Allow in Zone" or "Exclude in Zone")
        if sourcePreference == "favorite" then
            UI.SetTooltip(favoriteSource, "Remove Zone Favorite", "Stop favoring the selected visual when generating outfits in this zone.")
        else
            UI.SetTooltip(favoriteSource, "Favorite for This Zone", "Strongly favor the selected visual when generating outfits in this zone. Favorites still obey era, provenance, promotion, coherence, and weapon rules.")
        end
        if sourcePreference == "excluded" then
            UI.SetTooltip(excludeSource, "Allow in This Zone", "Remove the zone exclusion so this visual can be generated here again when it passes the other outfit rules.")
        else
            UI.SetTooltip(excludeSource, "Exclude for This Zone", "Never generate the selected visual in this zone. You can still browse and preview it manually.")
        end

        local diagnostics = Wardrobe.GetSlotDiagnostics(slotKey)
        statusText:SetText(message or CacheSummary(cache, diagnostics, #sources))

        local canGenerate = not Wardrobe.IsScanning() and cache.totalVisuals > 0
        generateButton:SetEnabled(canGenerate)
        rerollUnlocked:SetEnabled(canGenerate)
        local concepts = Wardrobe.GetConcepts()
        saveConcept:SetEnabled(next(GetState().selections) ~= nil or next(GetState().locks) ~= nil or next(GetState().hidden) ~= nil)
        loadConcept:SetEnabled(#concepts > 0)
        loadConcept:SetText(#concepts > 0 and string.format("Concepts (%d)", #concepts) or "Load Concept")

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
                local eligible, eligibilityKind = ZoneStyle.GetEligibilitySummary(source, styleMode, styleContext)
                local sourceZonePreference = Wardrobe.GetSourceZonePreference(source, styleContext)
                local generatedMarker = sourceZonePreference == "favorite" and (" • " .. UI.gold .. "Zone favorite|r")
                    or (sourceZonePreference == "excluded" and (" • " .. UI.red .. "Zone excluded|r")
                    or (eligible and "" or (eligibilityKind == "pending" and " • Loading era" or (eligibilityKind == "promotional" and " • Promo excluded" or " • Not generated"))))
                row.detail:SetText(string.format("%s • Source %d%s%s", marker, source.sourceID or 0, valid and "" or (" • " .. tostring(reason)), generatedMarker))
                row:SetEnabled(valid)
                SetSourceRowBackground(row, isSelected, sourceZonePreference)
            end
        end

        pageText:SetText(string.format("Page %d of %d", page, pageCount))
        previousPage:SetEnabled(page > 1)
        nextPage:SetEnabled(page < pageCount)
        local concept = Wardrobe.GetCurrentConcept()
        local conceptText = concept and (" • Concept: " .. tostring(concept.name or "Unnamed")) or ""
        local generatedText = generatedName and (" • Look: " .. generatedName) or ""
        local modeInfo = ZoneStyle.GetModeInfo(styleMode)
        subtitle:SetText(string.format("%s appearances for %s • %s • %s%s%s. Preview only; no outfit is applied.", UI.FormatNumber(#sources), definition and definition.label or slotKey, modeInfo.label, styleContext.profileLabel or "Azeroth Adventurer", generatedText, conceptText))
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
    QC.RegisterCallback("WARDROBE_AUTO_REFRESH_SCHEDULED", pane, function()
        if pane:IsShown() then pane:Refresh("Collection changed • automatic refresh queued.") end
    end)
    QC.RegisterCallback("WARDROBE_AUTO_REFRESH_DEFERRED", pane, function()
        if pane:IsShown() then pane:Refresh("Automatic refresh deferred • use Rescan Collection when ready.") end
    end)
    QC.RegisterCallback("WARDROBE_APPEARANCES_RECOVERED", pane, function(recovery)
        if pane:IsShown() and recovery then
            local recovered = (recovery.previewRecovered or 0) + (recovery.conceptRecovered or 0)
            pane:Refresh(string.format("Collection scan complete • %d changed appearance source%s recovered.", recovered, recovered == 1 and "" or "s"))
        end
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
    QC.RegisterCallback("WARDROBE_ZONE_PREFERENCES_CHANGED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("ZONE_STYLE_MODE_CHANGED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("ZONE_STYLE_SUGGESTION", pane, function()
        if pane:IsShown() then pane:Refresh("A new Zone Native outfit suggestion is ready.") end
    end)
    QC.RegisterCallback("ZONE_STYLE_CONTEXT_CHANGED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("ZONE_STYLE_SUGGESTION_CONSUMED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("EVENT_RECORDED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("ACTIVE_QUESTS_UPDATED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("SETTINGS_CHANGED", pane, function(settingName)
        if pane:IsShown() and (settingName == "restrictOutfitsToZoneEra" or settingName == "highContrastOutfitStates") then
            pane:Refresh()
        end
    end)
    QC.RegisterCallback("PLAYER_READY", pane, function()
        if model.SetUnit then model:SetUnit("player") end
        Wardrobe.ApplyPreview(model)
        pane:Refresh()
    end)

    pane:SetScript("OnShow", function()
        ZoneStyle.AcknowledgeSuggestion()
        Wardrobe.ApplyPreview(model)
        pane:Refresh()
    end)

    return pane
end
