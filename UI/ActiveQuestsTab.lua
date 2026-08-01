local QC = QuestChronicle
local UI = QC.UI

local FILTERS = {
    { key = "ALL", label = "All Quests" },
    { key = "READY", label = "Ready for Turn-In" },
    { key = "ACTIVE", label = "Active" },
    { key = "FAILED", label = "Failed" },
}

local SORTS = {
    { key = "READY", label = "Ready First" },
    { key = "NAME", label = "Quest Name" },
    { key = "RECENT", label = "Recently Accepted" },
}

local function FindIndex(definitions, key)
    for index, definition in ipairs(definitions) do
        if definition.key == key then
            return index
        end
    end
    return 1
end

local function QuestMatchesFilter(quest, filter)
    if filter == "ALL" then
        return true
    elseif filter == "READY" then
        return quest.questState == "READY_FOR_TURN_IN"
    elseif filter == "FAILED" then
        return quest.questState == "FAILED" or quest.isFailed == true
    elseif filter == "ACTIVE" then
        return quest.questState ~= "READY_FOR_TURN_IN" and quest.questState ~= "FAILED" and quest.isFailed ~= true
    end
    return true
end

local function QuestSortRank(quest)
    if quest.questState == "READY_FOR_TURN_IN" then
        return 1
    elseif quest.questState == "ACTIVE" then
        return 2
    elseif quest.questState == "FAILED" or quest.isFailed then
        return 3
    end
    return 4
end

local function SortQuests(quests, sortKey)
    table.sort(quests, function(left, right)
        local leftName = UI.Lower(left.questName)
        local rightName = UI.Lower(right.questName)

        if sortKey == "READY" then
            local leftRank = QuestSortRank(left)
            local rightRank = QuestSortRank(right)
            if leftRank ~= rightRank then
                return leftRank < rightRank
            end
        elseif sortKey == "RECENT" then
            local leftTime = left.acceptedAt or left.firstSeenAt or 0
            local rightTime = right.acceptedAt or right.firstSeenAt or 0
            if leftTime ~= rightTime then
                return leftTime > rightTime
            end
        end

        if leftName == rightName then
            return (left.questID or 0) < (right.questID or 0)
        end
        return leftName < rightName
    end)
end

local function FormatObjective(objective)
    local text = UI.Trim(objective.text)
    if text == "" and objective.numRequired then
        text = string.format("%d / %d", objective.numFulfilled or 0, objective.numRequired or 0)
    end

    if objective.finished then
        return string.format("    %sComplete|r  %s", UI.green, text ~= "" and text or "Objective complete")
    end
    return string.format("    %sIn Progress|r  %s", UI.gold, text ~= "" and text or "Objective in progress")
end

local function FormatQuest(quest)
    local name = quest.questName and quest.questName ~= "" and quest.questName or ("Quest " .. tostring(quest.questID or 0))
    local settings = QC.GetSettings()
    local questID = settings.showQuestIDs ~= false and string.format(" %s[%d]|r", UI.muted, quest.questID or 0) or ""
    local stateColor = UI.GetQuestStateColor(quest.questState)
    local lines = {
        string.format("%s%s|r%s", UI.white, name, questID),
        string.format("  %s%s|r", stateColor, UI.GetQuestStateLabel(quest.questState)),
    }

    local detailParts = {}
    if quest.questLevel and quest.questLevel > 0 then
        table.insert(detailParts, "Quest level " .. tostring(quest.questLevel))
    end
    if quest.acceptedAt then
        table.insert(detailParts, "Accepted " .. UI.FormatShortTimestamp(quest.acceptedAt))
        table.insert(detailParts, "Active " .. UI.FormatElapsed(time() - quest.acceptedAt))
    elseif quest.firstSeenAt then
        table.insert(detailParts, "First seen " .. UI.FormatShortTimestamp(quest.firstSeenAt))
    end
    if #detailParts > 0 then
        table.insert(lines, "  " .. UI.muted .. table.concat(detailParts, " • ") .. UI.reset)
    end

    if #(quest.objectives or {}) == 0 then
        table.insert(lines, "    " .. UI.muted .. "No objectives reported." .. UI.reset)
    else
        for _, objective in ipairs(quest.objectives or {}) do
            table.insert(lines, FormatObjective(objective))
        end
    end

    return table.concat(lines, "\n")
end

function UI.CreateActiveQuestsTab(parent)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetAllPoints(parent)

    local _, subtitle = UI.CreatePaneTitle(
        pane,
        "Active Quests",
        "The addon's current quest-log snapshot, including objective progress and ready-for-turn-in state."
    )
    pane.subtitle = subtitle

    local filterButton = UI.CreateButton(pane, "Show: All Quests", 155, 24)
    filterButton:SetPoint("TOPLEFT", pane, "TOPLEFT", 12, -56)

    local sortButton = UI.CreateButton(pane, "Sort: Ready First", 155, 24)
    sortButton:SetPoint("LEFT", filterButton, "RIGHT", 8, 0)

    local syncButton = UI.CreateButton(pane, "Rescan Quest Log", 145, 24)
    syncButton:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -12, -56)

    local refreshedText = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    refreshedText:SetPoint("RIGHT", syncButton, "LEFT", -12, 0)
    refreshedText:SetJustifyH("RIGHT")
    pane.refreshedText = refreshedText

    local resultText = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    resultText:SetPoint("TOPLEFT", filterButton, "BOTTOMLEFT", 0, -8)
    resultText:SetPoint("RIGHT", pane, "RIGHT", -12, 0)
    resultText:SetJustifyH("LEFT")
    pane.resultText = resultText

    local scroller = UI.CreateScrollableText(pane, -116, 12)
    pane.scroller = scroller

    UI.SetTooltip(filterButton, "Active Quest Filter", "Cycle between all, ready for turn-in, active, and failed quests. Hold Shift while clicking to cycle backward.")
    UI.SetTooltip(sortButton, "Active Quest Sort", "Sort ready quests first, alphabetically by quest name, or by most recently accepted.")
    UI.SetTooltip(syncButton, "Rescan Quest Log", "Refresh Quest Chronicle's active quest snapshot from WoW's current quest log.")

    local function GetFilter()
        return QC.GetUIState().activeQuestFilter or "ALL"
    end

    local function GetSort()
        return QC.GetUIState().activeQuestSort or "READY"
    end

    function pane:Refresh(message)
        local allQuests = QC.GetActiveQuests()
        local character = QC.GetCurrentCharacter()
        local filtered = {}
        local readyCount = 0
        local failedCount = 0

        for _, quest in ipairs(allQuests) do
            if quest.questState == "READY_FOR_TURN_IN" then
                readyCount = readyCount + 1
            elseif quest.questState == "FAILED" or quest.isFailed then
                failedCount = failedCount + 1
            end
            if QuestMatchesFilter(quest, GetFilter()) then
                table.insert(filtered, quest)
            end
        end

        SortQuests(filtered, GetSort())

        local activeCount = math.max(0, #allQuests - readyCount - failedCount)
        subtitle:SetText(string.format(
            "%s tracked quests • %s ready for turn-in • %s active%s",
            UI.FormatNumber(#allQuests),
            UI.FormatNumber(readyCount),
            UI.FormatNumber(activeCount),
            failedCount > 0 and (" • " .. UI.FormatNumber(failedCount) .. " failed") or ""
        ))

        local filterIndex = FindIndex(FILTERS, GetFilter())
        local sortIndex = FindIndex(SORTS, GetSort())
        filterButton:SetText("Show: " .. FILTERS[filterIndex].label)
        sortButton:SetText("Sort: " .. SORTS[sortIndex].label)
        refreshedText:SetText(message or (character.lastQuestSyncAt and ("Last sync: " .. date("%H:%M:%S", character.lastQuestSyncAt)) or "Not synchronized yet"))
        resultText:SetText(string.format("Showing %s of %s quests", UI.FormatNumber(#filtered), UI.FormatNumber(#allQuests)))

        if #filtered == 0 then
            scroller:SetText(UI.muted .. "No active quests match the selected filter. Use Rescan Quest Log if the snapshot looks stale." .. UI.reset)
            return
        end

        local lines = {}
        for _, quest in ipairs(filtered) do
            table.insert(lines, FormatQuest(quest))
        end
        scroller:SetText(table.concat(lines, "\n\n"))
    end

    filterButton:SetScript("OnClick", function()
        local index = FindIndex(FILTERS, GetFilter())
        if IsShiftKeyDown and IsShiftKeyDown() then
            index = index - 1
            if index < 1 then index = #FILTERS end
        else
            index = index + 1
            if index > #FILTERS then index = 1 end
        end
        QC.GetUIState().activeQuestFilter = FILTERS[index].key
        pane:Refresh()
    end)

    sortButton:SetScript("OnClick", function()
        local index = FindIndex(SORTS, GetSort()) + 1
        if index > #SORTS then index = 1 end
        QC.GetUIState().activeQuestSort = SORTS[index].key
        pane:Refresh()
    end)

    syncButton:SetScript("OnClick", function()
        local count = QC.SynchronizeQuestLog("UI_RESCAN_BUTTON")
        pane:Refresh(string.format("Rescanned: %d active quests", count or 0))
    end)

    QC.RegisterCallback("ACTIVE_QUESTS_UPDATED", pane, function()
        if pane:IsShown() then
            pane:Refresh()
        end
    end)
    QC.RegisterCallback("SETTINGS_CHANGED", pane, function(settingName)
        if pane:IsShown() and settingName == "showQuestIDs" then
            pane:Refresh()
        end
    end)
    QC.RegisterCallback("PLAYER_READY", pane, function()
        pane:Refresh()
    end)

    pane:SetScript("OnShow", function()
        pane:Refresh()
    end)

    return pane
end
