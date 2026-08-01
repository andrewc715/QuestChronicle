local QC = QuestChronicle
QC.UI = QC.UI or {}
local UI = QC.UI

UI.callbacks = UI.callbacks or {}
UI.gold = "|cffd9b36c"
UI.muted = "|cff9d9d9d"
UI.green = "|cff4cff72"
UI.red = "|cffff6868"
UI.blue = "|cff67b7ff"
UI.orange = "|cffff9f45"
UI.white = "|cffffffff"
UI.reset = "|r"

function QC.RegisterCallback(eventName, owner, callback)
    if type(eventName) ~= "string" or type(callback) ~= "function" then
        return
    end

    UI.callbacks[eventName] = UI.callbacks[eventName] or {}
    UI.callbacks[eventName][owner or callback] = callback
end

function QC.UnregisterCallbacks(owner)
    for _, callbacks in pairs(UI.callbacks) do
        callbacks[owner] = nil
    end
end

function QC.Notify(eventName, ...)
    local callbacks = UI.callbacks[eventName]
    if not callbacks then
        return
    end

    for _, callback in pairs(callbacks) do
        local ok, errorMessage = pcall(callback, ...)
        if not ok and QC.Print then
            QC.Print("UI callback failed: " .. tostring(errorMessage))
        end
    end
end

function UI.SafeText(value)
    if value == nil then
        return ""
    end
    local ok, text = pcall(tostring, value)
    return ok and text or ""
end

function UI.Trim(value)
    return UI.SafeText(value):match("^%s*(.-)%s*$") or ""
end

function UI.Lower(value)
    return string.lower(UI.SafeText(value))
end

function UI.FormatNumber(value)
    local text = tostring(math.floor(tonumber(value) or 0))
    local sign, digits = text:match("^([%-]?)(%d+)$")
    if not digits then
        return text
    end

    local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if formatted:sub(1, 1) == "," then
        formatted = formatted:sub(2)
    end
    return (sign or "") .. formatted
end

function UI.FormatBytes(value)
    value = tonumber(value) or 0
    if value >= 1024 * 1024 then
        return string.format("%.2f MB", value / (1024 * 1024))
    elseif value >= 1024 then
        return string.format("%.1f KB", value / 1024)
    end
    return string.format("%d bytes", value)
end

function UI.FormatTimestamp(timestamp)
    if not timestamp then
        return "Unknown"
    end
    return date("%Y-%m-%d %H:%M:%S", timestamp)
end

function UI.FormatShortTimestamp(timestamp)
    if not timestamp then
        return "Unknown"
    end

    local today = date("%Y%m%d", time())
    local day = date("%Y%m%d", timestamp)
    if day == today then
        return "Today at " .. date("%H:%M", timestamp)
    end
    return date("%b %d, %Y at %H:%M", timestamp)
end

function UI.FormatDayHeading(timestamp)
    if not timestamp then
        return "Unknown Date"
    end
    local label = date("%A, %B %d, %Y", timestamp)
    if date("%Y%m%d", timestamp) == date("%Y%m%d", time()) then
        label = "Today • " .. label
    end
    return label
end

function UI.GetDayKey(timestamp)
    return timestamp and date("%Y%m%d", timestamp) or "unknown"
end

function UI.FormatElapsed(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    if days > 0 then
        return string.format("%dd %dh", days, hours)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    end
    return string.format("%dm", minutes)
end

UI.questStateLabels = {
    ACTIVE = "Active",
    READY_FOR_TURN_IN = "Ready for Turn-In",
    FAILED = "Failed",
    COMPLETE = "Complete",
    TURNED_IN = "Turned In",
    REMOVED = "Removed",
}

UI.questStateColors = {
    ACTIVE = UI.gold,
    READY_FOR_TURN_IN = UI.green,
    FAILED = UI.red,
    COMPLETE = UI.green,
    TURNED_IN = UI.green,
    REMOVED = UI.muted,
}

function UI.FriendlyIdentifier(value)
    value = UI.SafeText(value)
    if value == "" then
        return "Unknown"
    end
    value = value:gsub("_", " "):lower()
    return (value:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest
    end))
end

function UI.GetQuestStateLabel(state)
    return UI.questStateLabels[state] or UI.FriendlyIdentifier(state)
end

function UI.GetQuestStateColor(state)
    return UI.questStateColors[state] or UI.white
end

UI.removalReasonLabels = {
    PLAYER_CONFIRMED_ABANDON = "Player-confirmed abandonment",
    DYNAMIC_OR_WORLD_QUEST_REMOVED = "Dynamic or world quest ended",
    FAILED_OR_SCRIPTED_REMOVAL = "Failed or removed by a game script",
    UNKNOWN_REMOVAL = "Unknown quest-log removal",
}

function UI.GetRemovalReasonLabel(reason)
    return UI.removalReasonLabels[reason] or UI.FriendlyIdentifier(reason)
end

UI.eventLabels = {
    QUEST_ACCEPTED = "Quest Accepted",
    QUEST_BECAME_ACTIVE = "Became Active",
    QUEST_OBJECTIVE_UPDATED = "Objective Progress",
    QUEST_STATE_CHANGED = "State Changed",
    QUEST_ABANDONED = "Quest Abandoned",
    QUEST_REMOVED = "Quest Removed",
    QUEST_TURNED_IN = "Quest Turned In",
    RP_NOTE = "RP Note",
}

UI.eventColors = {
    QUEST_ACCEPTED = "|cffffd100",
    QUEST_BECAME_ACTIVE = "|cff67b7ff",
    QUEST_OBJECTIVE_UPDATED = "|cffffffff",
    QUEST_STATE_CHANGED = "|cff9be36d",
    QUEST_ABANDONED = "|cffff6868",
    QUEST_REMOVED = "|cff9d9d9d",
    QUEST_TURNED_IN = "|cff4cff72",
    RP_NOTE = "|cffd9b36c",
}

function UI.GetQuestName(event)
    if event.questName and event.questName ~= "" then
        return event.questName
    elseif event.questID then
        return "Quest " .. tostring(event.questID)
    end
    return ""
end

function UI.GetQuestDisplayName(event)
    local name = UI.GetQuestName(event)
    local settings = QC.GetSettings and QC.GetSettings() or {}
    if settings.showQuestIDs ~= false and event.questID then
        return string.format("%s %s[%d]|r", name, UI.muted, event.questID)
    end
    return name
end

function UI.GetEventDetail(event)
    local eventType = event.eventType
    local questName = UI.GetQuestDisplayName(event)

    if eventType == "QUEST_OBJECTIVE_UPDATED" then
        local text = event.objectiveText and event.objectiveText ~= "" and event.objectiveText or event.changeReason
        return string.format("%s\nObjective %d: %s", questName, event.objectiveIndex or 0, UI.SafeText(text))
    elseif eventType == "QUEST_STATE_CHANGED" then
        return string.format(
            "%s\n%s%s|r → %s%s|r",
            questName,
            UI.GetQuestStateColor(event.previousQuestState),
            UI.GetQuestStateLabel(event.previousQuestState),
            UI.GetQuestStateColor(event.questState),
            UI.GetQuestStateLabel(event.questState)
        )
    elseif eventType == "QUEST_ABANDONED" then
        return questName .. "\nDeliberately abandoned by the player."
    elseif eventType == "QUEST_REMOVED" then
        return string.format("%s\nRemoved from the quest log: %s.", questName, UI.GetRemovalReasonLabel(event.removalReason))
    elseif eventType == "QUEST_TURNED_IN" then
        local rewardParts = {}
        if (event.xpReward or 0) > 0 then
            table.insert(rewardParts, UI.FormatNumber(event.xpReward) .. " XP")
        end
        if (event.moneyReward or 0) > 0 then
            table.insert(rewardParts, GetMoneyString and GetMoneyString(event.moneyReward) or (tostring(event.moneyReward) .. " copper"))
        end
        local rewardText = #rewardParts > 0 and ("\nRewards: " .. table.concat(rewardParts, ", ")) or ""
        return questName .. rewardText
    elseif eventType == "QUEST_ACCEPTED" then
        return questName
    elseif eventType == "QUEST_BECAME_ACTIVE" then
        return questName .. "\nDiscovered in the active quest log."
    elseif eventType == "RP_NOTE" then
        return UI.SafeText(event.note)
    elseif questName ~= "" then
        return questName
    end

    return UI.SafeText(event.changeReason)
end

function UI.FormatEvent(event)
    local color = UI.eventColors[event.eventType] or UI.white
    local label = UI.eventLabels[event.eventType] or UI.FriendlyIdentifier(event.eventType)
    local sequence = event.sequence or 0
    local clock = event.timestamp and date("%H:%M:%S", event.timestamp) or "--:--:--"
    local locationParts = {}

    if event.zone and event.zone ~= "" then
        table.insert(locationParts, event.zone)
    end
    if event.subZone and event.subZone ~= "" and event.subZone ~= event.zone then
        table.insert(locationParts, event.subZone)
    end
    if event.level and event.level > 0 then
        table.insert(locationParts, "Level " .. tostring(event.level))
    end

    local header = string.format("%s#%d  %s  %s|r", color, sequence, clock, label)
    local detail = UI.GetEventDetail(event)
    local location = #locationParts > 0 and ("\n" .. UI.muted .. table.concat(locationParts, " • ") .. UI.reset) or ""
    return header .. "\n" .. detail .. location
end

function UI.FormatDaySeparator(timestamp)
    return UI.gold .. "-----  " .. UI.FormatDayHeading(timestamp) .. "  -----" .. UI.reset
end

function UI.EventMatchesFilter(event, filter)
    if filter == "ALL" then
        return true
    elseif filter == "LIFECYCLE" then
        return event.eventType ~= "QUEST_OBJECTIVE_UPDATED" and event.eventType ~= "RP_NOTE"
    elseif filter == "OBJECTIVES" then
        return event.eventType == "QUEST_OBJECTIVE_UPDATED" or event.eventType == "QUEST_STATE_CHANGED"
    elseif filter == "NOTES" then
        return event.eventType == "RP_NOTE"
    elseif filter == "REMOVALS" then
        return event.eventType == "QUEST_ABANDONED" or event.eventType == "QUEST_REMOVED"
    end
    return true
end

function UI.EventMatchesSearch(event, searchText)
    searchText = UI.Lower(UI.Trim(searchText))
    if searchText == "" then
        return true
    end

    local haystack = table.concat({
        UI.SafeText(event.eventType),
        UI.eventLabels[event.eventType] or "",
        UI.SafeText(event.questName),
        UI.SafeText(event.questID),
        UI.SafeText(event.objectiveText),
        UI.SafeText(event.note),
        UI.SafeText(event.zone),
        UI.SafeText(event.subZone),
        UI.SafeText(event.changeReason),
        UI.GetQuestStateLabel(event.previousQuestState),
        UI.GetQuestStateLabel(event.questState),
        UI.GetRemovalReasonLabel(event.removalReason),
    }, " "):lower()

    return haystack:find(searchText, 1, true) ~= nil
end

function UI.CreateInsetPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)

    local background = panel:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(panel)
    background:SetColorTexture(0.025, 0.025, 0.025, 0.78)
    panel.background = background

    local function CreateEdge(point1, point2, width, height)
        local edge = panel:CreateTexture(nil, "BORDER")
        edge:SetColorTexture(0.34, 0.29, 0.19, 0.85)
        edge:SetPoint(point1, panel, point1, 0, 0)
        edge:SetPoint(point2, panel, point2, 0, 0)
        if width then edge:SetWidth(width) end
        if height then edge:SetHeight(height) end
        return edge
    end

    panel.topEdge = CreateEdge("TOPLEFT", "TOPRIGHT", nil, 1)
    panel.bottomEdge = CreateEdge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
    panel.leftEdge = CreateEdge("TOPLEFT", "BOTTOMLEFT", 1, nil)
    panel.rightEdge = CreateEdge("TOPRIGHT", "BOTTOMRIGHT", 1, nil)

    return panel
end

function UI.CreateButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 110, height or 24)
    button:SetText(text or "Button")
    return button
end

function UI.CreateScrollableText(parent, topOffset, bottomOffset)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, topOffset or -12)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, bottomOffset or 12)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local text = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, -4)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetSpacing(3)

    local function Resize()
        local width = math.max(50, scrollFrame:GetWidth() - 12)
        scrollChild:SetWidth(width)
        text:SetWidth(width - 8)
        local height = math.max(scrollFrame:GetHeight(), (text:GetStringHeight() or 0) + 16)
        scrollChild:SetHeight(height)
        scrollFrame:UpdateScrollChildRect()
    end

    scrollFrame:SetScript("OnSizeChanged", Resize)

    local object = {
        frame = scrollFrame,
        child = scrollChild,
        text = text,
    }

    function object:SetText(value, resetScroll)
        text:SetText(value or "")
        if C_Timer and C_Timer.After then
            C_Timer.After(0, Resize)
        else
            Resize()
        end
        if resetScroll ~= false then
            scrollFrame:SetVerticalScroll(0)
        end
    end

    function object:Resize()
        Resize()
    end

    return object
end

function UI.CreatePaneTitle(parent, title, subtitle)
    local titleText = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -12)
    titleText:SetText(title)

    local subtitleText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitleText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -4)
    subtitleText:SetPoint("RIGHT", parent, "RIGHT", -12, 0)
    subtitleText:SetJustifyH("LEFT")
    subtitleText:SetText(subtitle or "")

    return titleText, subtitleText
end

function UI.SetTooltip(frame, title, body, anchor)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, anchor or "ANCHOR_RIGHT")
        GameTooltip:SetText(title or "Quest Chronicle")
        if body and body ~= "" then
            GameTooltip:AddLine(body, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
