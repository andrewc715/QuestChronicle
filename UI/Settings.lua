local QC = QuestChronicle

local SETTINGS = {
    {
        variable = "QUEST_CHRONICLE_ENABLED",
        key = "enabled",
        label = "Enable all recording",
        default = true,
        tooltip = "Master switch for Quest Chronicle event recording.",
    },
    {
        variable = "QUEST_CHRONICLE_CHAT_NOTIFICATIONS",
        key = "chatNotifications",
        label = "Show chat notifications",
        default = true,
        tooltip = "Print short chat notices when important events are recorded.",
    },
    {
        variable = "QUEST_CHRONICLE_LIFECYCLE_TRACKING",
        key = "lifecycleTracking",
        label = "Record quest lifecycle",
        default = true,
        tooltip = "Record acceptance, active-state discovery, and state changes.",
    },
    {
        variable = "QUEST_CHRONICLE_OBJECTIVE_TRACKING",
        key = "objectiveTracking",
        label = "Record objective progress",
        default = true,
        tooltip = "Record meaningful objective progress and completion changes.",
    },
    {
        variable = "QUEST_CHRONICLE_REMOVAL_TRACKING",
        key = "removalTracking",
        label = "Record abandonments and removals",
        default = true,
        tooltip = "Keep confirmed player abandonment separate from uncertain automatic removal.",
    },
    {
        variable = "QUEST_CHRONICLE_SHOW_QUEST_IDS",
        key = "showQuestIDs",
        label = "Show quest IDs in the UI",
        default = true,
        tooltip = "Display numeric quest IDs beside quest names in Chronicle and Active Quest views.",
    },
    {
        variable = "QUEST_CHRONICLE_DATE_SEPARATORS",
        key = "showDateSeparators",
        label = "Group Chronicle events by date",
        default = true,
        tooltip = "Insert date headings between Chronicle events recorded on different days.",
    },
    {
        variable = "QUEST_CHRONICLE_CONFIRM_CLEAR_DRAFT",
        key = "confirmClearDraft",
        label = "Confirm before clearing note drafts",
        default = true,
        tooltip = "Ask for confirmation before erasing an unfinished RP note.",
    },
    {
        variable = "QUEST_CHRONICLE_REMEMBER_WINDOW",
        key = "rememberWindowPosition",
        label = "Remember window position and size",
        default = true,
        tooltip = "Restore the Quest Chronicle window where you last placed and sized it.",
    },
    {
        variable = "QUEST_CHRONICLE_LOCK_WINDOW",
        key = "lockWindow",
        label = "Lock window position and size",
        default = false,
        tooltip = "Prevent the Quest Chronicle window from being dragged or resized.",
    },
}

function QC.RegisterSettings()
    if QC.settingsRegistered or not Settings or not Settings.RegisterVerticalLayoutCategory then
        return
    end

    local settingsTable = QC.GetSettings()
    local category = Settings.RegisterVerticalLayoutCategory("Quest Chronicle")

    for _, definition in ipairs(SETTINGS) do
        local settingDefinition = definition
        local setting = Settings.RegisterAddOnSetting(
            category,
            settingDefinition.variable,
            settingDefinition.key,
            settingsTable,
            Settings.VarType.Boolean,
            settingDefinition.label,
            settingDefinition.default
        )

        setting:SetValueChangedCallback(function(_, value)
            QC.SetSetting(settingDefinition.key, value)
        end)
        Settings.CreateCheckbox(category, setting, settingDefinition.tooltip)
    end

    Settings.RegisterAddOnCategory(category)
    QC.settingsCategory = category
    QC.settingsRegistered = true
end

function QC.OpenSettings()
    if QC.settingsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(QC.settingsCategory:GetID())
    elseif QC.Print then
        QC.Print("The modern WoW Settings panel is not available.")
    end
end
