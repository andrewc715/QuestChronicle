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
        variable = "QUEST_CHRONICLE_REMEMBER_WINDOW",
        key = "rememberWindowPosition",
        label = "Remember window position",
        default = true,
        tooltip = "Restore the Quest Chronicle window where you last placed it.",
    },
    {
        variable = "QUEST_CHRONICLE_LOCK_WINDOW",
        key = "lockWindow",
        label = "Lock window position",
        default = false,
        tooltip = "Prevent the Quest Chronicle window from being dragged.",
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
