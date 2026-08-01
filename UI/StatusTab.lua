local QC = QuestChronicle
local UI = QC.UI

local SETTING_ROWS = {
    { key = "enabled", label = "Enable all recording", tooltip = "Master switch for Quest Chronicle event recording." },
    { key = "chatNotifications", label = "Show chat notifications", tooltip = "Print a short message when important Chronicle events are recorded." },
    { key = "lifecycleTracking", label = "Record quest lifecycle", tooltip = "Record acceptance, active-state discovery, and state-change events." },
    { key = "objectiveTracking", label = "Record objective progress", tooltip = "Record meaningful changes to quest objective text and progress." },
    { key = "removalTracking", label = "Record abandonments and removals", tooltip = "Record confirmed abandonment and uncertain quest-log removal events separately." },
}

local function CreateCheckBox(parent, definition, previous)
    local checkBox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkBox:SetSize(24, 24)
    if previous then
        checkBox:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -3)
    else
        checkBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -258)
    end

    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", checkBox, "RIGHT", 2, 0)
    label:SetText(definition.label)
    checkBox.label = label
    checkBox.definition = definition

    UI.SetTooltip(checkBox, definition.label, definition.tooltip)
    return checkBox
end

function UI.CreateStatusTab(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent)

    UI.CreatePaneTitle(
        pane,
        "Status & Maintenance",
        "Recorder health, Courier snapshot readiness, manual synchronization, and tracking controls."
    )

    local statusText = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    statusText:SetPoint("TOPLEFT", pane, "TOPLEFT", 16, -72)
    statusText:SetPoint("RIGHT", pane, "RIGHT", -16, 0)
    statusText:SetJustifyH("LEFT")
    statusText:SetJustifyV("TOP")
    statusText:SetSpacing(4)
    pane.statusText = statusText

    local divider = pane:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.35, 0.30, 0.20, 0.65)
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", pane, "TOPLEFT", 16, -240)
    divider:SetPoint("RIGHT", pane, "RIGHT", -16, 0)

    local settingsHeader = pane:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    settingsHeader:SetPoint("TOPLEFT", pane, "TOPLEFT", 16, -248)
    settingsHeader:SetText("Recording Controls")

    pane.checkBoxes = {}
    local previous
    for _, definition in ipairs(SETTING_ROWS) do
        local checkBox = CreateCheckBox(pane, definition, previous)
        checkBox:SetScript("OnClick", function(self)
            QC.SetSetting(self.definition.key, self:GetChecked() == true)
            pane:Refresh()
        end)
        table.insert(pane.checkBoxes, checkBox)
        previous = checkBox
    end

    local syncButton = UI.CreateButton(pane, "Rescan Quest Log", 145, 26)
    syncButton:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 16, 48)

    local exportButton = UI.CreateButton(pane, "Refresh Courier Export", 170, 26)
    exportButton:SetPoint("LEFT", syncButton, "RIGHT", 8, 0)

    local settingsButton = UI.CreateButton(pane, "Open WoW Settings", 145, 26)
    settingsButton:SetPoint("LEFT", exportButton, "RIGHT", 8, 0)

    local resetWindowButton = UI.CreateButton(pane, "Reset Window", 115, 26)
    resetWindowButton:SetPoint("LEFT", settingsButton, "RIGHT", 8, 0)

    UI.SetTooltip(syncButton, "Rescan Quest Log", "Refresh the active quest snapshot from WoW's current quest log.")
    UI.SetTooltip(exportButton, "Refresh Courier Export", "Rebuild the in-memory Courier JSON snapshot. Use /reload, logout, or exit to write SavedVariables to disk.")
    UI.SetTooltip(settingsButton, "Open WoW Settings", "Open Quest Chronicle's native AddOns settings category.")
    UI.SetTooltip(resetWindowButton, "Reset Window", "Return Quest Chronicle to its default size and center-screen position.")

    local notice = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    notice:SetPoint("BOTTOMLEFT", pane, "BOTTOMLEFT", 16, 16)
    notice:SetPoint("RIGHT", pane, "RIGHT", -16, 0)
    notice:SetJustifyH("LEFT")
    notice:SetText(UI.muted .. "WoW writes SavedVariables to disk on /reload, logout, or exit. Refreshing the Courier export updates the in-memory snapshot." .. UI.reset)

    local feedback = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    feedback:SetPoint("BOTTOMLEFT", syncButton, "TOPLEFT", 0, 8)
    feedback:SetPoint("RIGHT", pane, "RIGHT", -16, 0)
    feedback:SetJustifyH("LEFT")
    pane.feedback = feedback

    function pane:Refresh()
        local status = QC.GetStatus()
        local settings = QC.GetSettings()
        local character = QC.GetCurrentCharacter()
        local recording = settings.enabled and (UI.green .. "Enabled" .. UI.reset) or (UI.red .. "Disabled" .. UI.reset)
        local lastEvent = status.lastEventAt and UI.FormatTimestamp(status.lastEventAt) or "No events recorded"
        local lastSync = status.lastQuestSyncAt and UI.FormatTimestamp(status.lastQuestSyncAt) or "Not synchronized"
        local courier = status.courierSnapshotSize > 0
            and (UI.green .. "Ready|r • " .. UI.FormatBytes(status.courierSnapshotSize))
            or (UI.red .. "Not generated|r")
        local wardrobeCache = QC.Wardrobe and QC.Wardrobe.GetCache and QC.Wardrobe.GetCache()
        local wardrobeState = "Unavailable"
        if wardrobeCache then
            if wardrobeCache.loginRefreshPending then
                wardrobeState = "Login refresh pending"
            elseif wardrobeCache.dirty then
                wardrobeState = "Collection may be stale"
            elseif wardrobeCache.scanState == "COMPLETE" or wardrobeCache.scanState == "COMPLETE_WITH_WARNINGS" then
                wardrobeState = "Current"
            elseif wardrobeCache.scanState == "FAILED" then
                wardrobeState = "Last scan failed"
            else
                wardrobeState = "Collection scan required"
            end
        end
        local wardrobe = wardrobeCache and string.format("%s • %s visuals", wardrobeState, UI.FormatNumber(wardrobeCache.totalVisuals or 0)) or wardrobeState

        statusText:SetText(table.concat({
            string.format("%s%s - %s|r", UI.gold, character.name or "Unknown", character.realm or "Unknown Realm"),
            string.format("Quest Chronicle %s%s|r  •  Schema %d  •  Courier format %d", UI.blue, tostring(QC.version or "Unknown"), QC.schemaVersion or 0, QC.courierFormatVersion or 0),
            string.format("Recording: %s", recording),
            string.format("Events: %s  •  Active quests: %s  •  RP notes: %s", UI.FormatNumber(status.eventCount), UI.FormatNumber(status.activeQuestCount), UI.FormatNumber(status.noteCount)),
            string.format("Accepted: %s  •  Turned in: %s  •  Objectives: %s  •  State changes: %s", UI.FormatNumber(status.acceptedCount), UI.FormatNumber(status.completedCount), UI.FormatNumber(status.objectiveUpdateCount), UI.FormatNumber(status.stateChangeCount)),
            string.format("Abandoned: %s  •  Removed: %s", UI.FormatNumber(status.abandonedCount), UI.FormatNumber(status.removedCount)),
            "Last event: " .. lastEvent,
            "Last quest sync: " .. lastSync,
            "Courier snapshot: " .. courier,
            "Wardrobe: " .. wardrobe,
        }, "\n"))

        for _, checkBox in ipairs(self.checkBoxes) do
            checkBox:SetChecked(settings[checkBox.definition.key] == true)
        end
    end

    syncButton:SetScript("OnClick", function()
        local count = QC.SynchronizeQuestLog("UI_STATUS_RESCAN")
        feedback:SetText(UI.green .. string.format("Quest log synchronized: %d active quests.", count or 0) .. UI.reset)
        pane:Refresh()
    end)

    exportButton:SetScript("OnClick", function()
        local snapshot = QC.RefreshCourierSnapshot(true)
        feedback:SetText(UI.green .. "Courier snapshot refreshed: " .. UI.FormatBytes(#snapshot) .. "." .. UI.reset)
        pane:Refresh()
    end)

    settingsButton:SetScript("OnClick", function()
        if QC.OpenSettings then
            QC.OpenSettings()
        end
    end)

    resetWindowButton:SetScript("OnClick", function()
        if QC.ResetWindowPosition then
            QC.ResetWindowPosition()
            feedback:SetText(UI.green .. "Window size and position reset." .. UI.reset)
        end
    end)

    QC.RegisterCallback("EVENT_RECORDED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("ACTIVE_QUESTS_UPDATED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("COURIER_EXPORT_REFRESHED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("SETTINGS_CHANGED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("WARDROBE_CACHE_DIRTY", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("WARDROBE_SCAN_COMPLETE", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("WARDROBE_LOGIN_REFRESH_SCHEDULED", pane, function()
        if pane:IsShown() then pane:Refresh() end
    end)
    QC.RegisterCallback("PLAYER_READY", pane, function()
        pane:Refresh()
    end)

    pane:SetScript("OnShow", function()
        feedback:SetText("")
        pane:Refresh()
    end)

    return pane
end
