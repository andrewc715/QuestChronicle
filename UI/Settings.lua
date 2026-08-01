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
    {
        variable = "QUEST_CHRONICLE_SHOW_MINIMAP_BUTTON",
        key = "showMinimapButton",
        label = "Show minimap button",
        default = true,
        tooltip = "Show a draggable Quest Chronicle button on the minimap. Minimap button organizers may collect it into their button bag.",
    },
    {
        variable = "QUEST_CHRONICLE_ZONE_ERA_RESTRICTION",
        key = "restrictOutfitsToZoneEra",
        label = "Restrict generated outfits to the zone's expansion",
        default = true,
        tooltip = "Prevent generated outfits from using appearances introduced after the current zone's expansion. Manual preview remains unrestricted.",
    },
    {
        variable = "QUEST_CHRONICLE_AUTO_REFRESH_WARDROBE",
        key = "autoRefreshWardrobe",
        label = "Refresh the wardrobe after collection changes",
        default = true,
        tooltip = "Quietly rescan after appearances are learned or removed. Refresh waits until combat and Blizzard's Wardrobe windows are closed.",
    },
    {
        variable = "QUEST_CHRONICLE_RECOVER_APPEARANCES",
        key = "recoverMissingAppearances",
        label = "Recover changed appearance sources",
        default = true,
        tooltip = "Keep previews and saved concepts intact when Blizzard changes which collected source represents the same visual appearance.",
    },
    {
        variable = "QUEST_CHRONICLE_ANNOUNCE_WARDROBE",
        key = "announceWardrobeUpdates",
        label = "Announce wardrobe maintenance in chat",
        default = true,
        tooltip = "Print concise messages when an automatic refresh completes, is deferred, or recovers saved appearances.",
    },
    {
        variable = "QUEST_CHRONICLE_HIGH_CONTRAST_OUTFITS",
        key = "highContrastOutfitStates",
        label = "High-contrast outfit states",
        default = false,
        tooltip = "Use stronger row backgrounds for selected, favored, and excluded appearances while retaining written state labels.",
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
