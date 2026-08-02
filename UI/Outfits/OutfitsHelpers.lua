local QC = QuestChronicle
local UI = QC.UI
local Wardrobe = QC.Wardrobe
local ZoneStyle = QC.ZoneStyle
UI._Outfits = UI._Outfits or {}
local P = UI._Outfits


P.SOURCE_ROWS = 7
P.SOURCE_ROW_HEIGHT = 37
P.SOURCE_ROW_SPACING = 2
P.CONCEPT_ROWS = 4
P.CUSTOM_SET_ROWS = 5

function P.GetState()
    return Wardrobe.GetPreviewState()
end

function P.GetCurrentSlot()
    return P.GetState().selectedSlot or "HEAD"
end

function P.GetDisplayedSources(slotKey)
    if Wardrobe.GetFilteredSlotSources then
        return Wardrobe.GetFilteredSlotSources(slotKey)
    end
    return Wardrobe.GetSlotSources(slotKey)
end

function P.GetPage(slotKey)
    return math.max(1, tonumber(P.GetState().pages[slotKey]) or 1)
end

function P.SetPage(slotKey, value)
    P.GetState().pages[slotKey] = math.max(1, tonumber(value) or 1)
end

function P.SourceLabel(source)
    local qualityColor = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[source.quality or 1]
    local color = qualityColor and qualityColor.hex or UI.white
    return string.format("%s%s|r", color, source.name or ("Appearance " .. tostring(source.sourceID or 0)))
end

function P.ShowAppearanceTooltip(owner, source, slotKey, leadText)
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

function P.CountMap(values)
    local count = 0
    for _, value in pairs(values or {}) do
        if value ~= nil and value ~= false then
            count = count + 1
        end
    end
    return count
end

function P.ConceptDetail(concept)
    local updated = concept.updatedAt and UI.FormatShortTimestamp(concept.updatedAt) or "Unknown time"
    local mode = concept.styleMode and ZoneStyle and ZoneStyle.GetModeInfo(concept.styleMode)
    local _, nativeStatus = Wardrobe.GetConceptCustomSetStatus(concept)
    return string.format(
        "%d appearances • %d locked • %d hidden • %s • Weapons: %s • %s • %s",
        P.CountMap(concept.selections),
        P.CountMap(concept.locks),
        P.CountMap(concept.hidden),
        mode and mode.label or "Current mode",
        Wardrobe.GetWeaponConceptSummary(concept.weaponFamilies, concept.weaponSubtypes, concept.linkWeaponHands),
        nativeStatus,
        updated
    )
end

function P.CreateLockedSlotVisual(button)
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

function P.SetLockedSlotVisual(button, locked)
    button.lockIcon:SetShown(locked)
    for _, edge in ipairs(button.lockEdges or {}) do
        edge:SetShown(locked)
    end
end

function P.CacheSummary(cache, diagnostics, sourceCount)
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
    local maintenance = ""
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

function P.BuildDiagnosticsTooltip(cache, diagnostics, sourceCount, selected)
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
    if cache.loginRefreshPending then
        table.insert(lines, "Login refresh: waiting for a quiet moment")
    elseif cache.lastLoginRefreshAt then
        table.insert(lines, "Last login refresh: " .. UI.FormatShortTimestamp(cache.lastLoginRefreshAt))
    end
    if cache.dirty then
        table.insert(lines, "Collection state: may be stale; use Scan Collection to refresh it")
    end
    if cache.lastRecovery then
        local recovered = (cache.lastRecovery.previewRecovered or 0) + (cache.lastRecovery.conceptRecovered or 0)
        table.insert(lines, string.format("Last recovery: %d rebound • %d still unavailable", recovered, cache.lastRecovery.missing or 0))
    end

    table.insert(lines, "")
    table.insert(lines, "These counts are not expected to match exactly. Multiple item sources can share one visual, and unusable appearances are excluded from the preview cache.")
    return table.concat(lines, "\n")
end

function P.SetSourceRowBackground(row, selected, preference)
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

