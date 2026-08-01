local QC = QuestChronicle
local UI = QC.UI

local SETTING_ROWS = {
    { key = "enabled", label = "Enable all recording", tooltip = "Master switch for Quest Chronicle event recording." },
    { key = "chatNotifications", label = "Show chat notifications", tooltip = "Print a short message when important Chronicle events are recorded." },
    { key = "lifecycleTracking", label = "Record quest lifecycle", tooltip = "Record acceptance, active-state, and state-change events." },
    { key = "objectiveTracking", label = "Record objective progress", tooltip = "Record meaningful changes to quest objective text and progress." },
    { key = "removalTracking", label = "Record abandonments and removals", tooltip = "Record confirmed abandonment and uncertain quest-log removal events separately." },
}

local function CreateCheckBox(parent, definition, previous)
    local checkBox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkBox:SetSize(24, 24)
    if previous then
        checkBox:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -3)
    else
        checkBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -236)
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
    divider:SetPoint("TOPLEFT", pane, "TOPLEFT", 16, -218)
    divider:SetPoint("RIGHT", pane, "RIGHT", -16, 0)

    local settingsHeader = pane:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    settingsHeader:SetPoint("TOPLEFT", pane, "TOPLEFT", 16, -226)
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
    exportButton:SetPoint("LEFT", syncButton, "RIGHT", 10, 0)

    local settingsButton = UI.CreateButton(pane, "Open WoW Settings", 155, 26)
    settingsButton:SetPoint("LEFT", exportButton, "RIGHT", 10, 0)

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
        local recording = settings.enabled and (UI.green .. "Enabled" .. UI.reset) or (UI.red .. "Disabled" .. UI.reset)
        local lastEvent = status.lastEventAt and UI.FormatTimestamp(status.lastEventAt) or "No events recorded"
        local lastSync = status.lastQuestSyncAt and UI.FormatTimestamp(status.lastQuestSyncAt) or "Not synchronized"

        statusText:SetText(table.concat({
            UI.gold .. status.characterKey .. UI.reset,
            string.format("Recording: %s", recording),
            string.format("Events: %d  •  Active quests: %d  •  RP notes: %d", status.eventCount, status.activeQuestCount, status.noteCount),
            string.format("Accepted: %d  •  Turned in: %d  •  Abandoned: %d  •  Removed: %d", status.acceptedCount, status.completedCount, status.abandonedCount, status.removedCount),
            "Last event: " .. lastEvent,
            "Last quest sync: " .. lastSync,
            "Courier snapshot: " .. UI.FormatBytes(status.courierSnapshotSize),
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
    QC.RegisterCallback("PLAYER_READY", pane, function()
        pane:Refresh()
    end)

    pane:SetScript("OnShow", function()
        feedback:SetText("")
        pane:Refresh()
    end)

    return pane
end
