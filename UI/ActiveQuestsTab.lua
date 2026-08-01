local QC = QuestChronicle
local UI = QC.UI

local function FormatObjective(objective)
    local finished = objective.finished and UI.green .. "✓" .. UI.reset or UI.muted .. "•" .. UI.reset
    local text = UI.SafeText(objective.text)

    if text == "" and objective.numRequired then
        text = string.format("%d / %d", objective.numFulfilled or 0, objective.numRequired or 0)
    end

    return string.format("    %s %s", finished, text)
end

local function FormatQuest(quest)
    local name = quest.questName and quest.questName ~= "" and quest.questName or ("Quest " .. tostring(quest.questID or 0))
    local stateColor = quest.questState == "READY_FOR_TURN_IN" and UI.green or UI.gold
    local lines = {
        string.format("%s%s|r %s[%d]|r", UI.white, name, UI.muted, quest.questID or 0),
        string.format("  %s%s|r", stateColor, UI.SafeText(quest.questState)),
    }

    local detailParts = {}
    if quest.questLevel and quest.questLevel > 0 then
        table.insert(detailParts, "Quest level " .. tostring(quest.questLevel))
    end
    if quest.acceptedAt then
        table.insert(detailParts, "Accepted " .. UI.FormatTimestamp(quest.acceptedAt))
        table.insert(detailParts, "Active " .. UI.FormatElapsed(time() - quest.acceptedAt))
    elseif quest.firstSeenAt then
        table.insert(detailParts, "First seen " .. UI.FormatTimestamp(quest.firstSeenAt))
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

    local syncButton = UI.CreateButton(pane, "Rescan Quest Log", 145, 24)
    syncButton:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -12, -56)

    local refreshedText = pane:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    refreshedText:SetPoint("RIGHT", syncButton, "LEFT", -12, 0)
    refreshedText:SetJustifyH("RIGHT")
    pane.refreshedText = refreshedText

    local scroller = UI.CreateScrollableText(pane, -94, 12)
    pane.scroller = scroller

    function pane:Refresh(message)
        local quests = QC.GetActiveQuests()
        local character = QC.GetCurrentCharacter()
        subtitle:SetText(string.format("%d active quests for %s.", #quests, character.name or character.key))
        refreshedText:SetText(message or (character.lastQuestSyncAt and ("Last sync: " .. date("%H:%M:%S", character.lastQuestSyncAt)) or "Not synchronized yet"))

        if #quests == 0 then
            scroller:SetText(UI.muted .. "No active quests are currently stored. Use Rescan Quest Log to refresh the snapshot." .. UI.reset)
            return
        end

        local lines = {}
        for _, quest in ipairs(quests) do
            table.insert(lines, FormatQuest(quest))
        end
        scroller:SetText(table.concat(lines, "\n\n"))
    end

    syncButton:SetScript("OnClick", function()
        local count = QC.SynchronizeQuestLog("UI_RESCAN_BUTTON")
        pane:Refresh(string.format("Rescanned: %d active quests", count or 0))
    end)

    QC.RegisterCallback("ACTIVE_QUESTS_UPDATED", pane, function()
        if pane:IsShown() then
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
