local QC = QuestChronicle
local P = QC._Core
function P.SyncQuestLog(sourceEvent, suppressLifecycleEvents)
    if not P.currentCharacter then
        return
    end

    local character = P.EnsureCharacter()
    local previousMap = character.activeQuests or {}
    local currentMap = P.EnumerateActiveQuests(previousMap)
    local now = time()

    for key, current in pairs(currentMap) do
        local previous = previousMap[key]

        if previous then
            current.acceptedAt = previous.acceptedAt
            current.acceptedAtText = previous.acceptedAtText
            current.firstSeenAt = previous.firstSeenAt or current.firstSeenAt
            current.firstSeenAtText = previous.firstSeenAtText or current.firstSeenAtText

            if not suppressLifecycleEvents and previous.fingerprint ~= current.fingerprint then
                P.RecordObjectiveChanges(previous, current, sourceEvent)
                P.RecordStateChange(previous, current, sourceEvent)
            end
        elseif not suppressLifecycleEvents and not P.IsRecent(P.recentAcceptances, current.questID) then
            if QuestChronicleDB.settings.lifecycleTracking then
                local payload = P.QuestPayload(current)
                payload.sourceEvent = sourceEvent
                payload.changeReason = current.isTask or current.isWorldQuest
                    and "BECAME_ACTIVE_WITHOUT_ACCEPT_EVENT"
                    or "DISCOVERED_BY_QUEST_LOG_DIFF"

                if current.isTask or current.isWorldQuest then
                    P.AddEvent("QUEST_BECAME_ACTIVE", payload)
                else
                    current.acceptedAt = now
                    current.acceptedAtText = P.TimestampText(now)
                    payload.acceptedAt = now
                    payload.acceptedAtText = current.acceptedAtText
                    P.AddEvent("QUEST_ACCEPTED", payload)
                    P.recentAcceptances[current.questID] = GetTime()
                end
            end
        end
    end

    if not suppressLifecycleEvents then
        for key, previous in pairs(previousMap) do
            if not currentMap[key] then
                P.QueueQuestRemoval(previous.questID, previous, sourceEvent)
            end
        end
    end

    character.activeQuests = currentMap
    character.lastQuestSyncAt = now
    character.lastQuestSyncAtText = P.TimestampText(now)

    if QC.Notify then
        QC.Notify("ACTIVE_QUESTS_UPDATED", sourceEvent)
    end
end

function P.ScheduleQuestSync(sourceEvent, delay)
    P.questSyncToken = P.questSyncToken + 1
    local token = P.questSyncToken

    C_Timer.After(delay or P.OBJECTIVE_SYNC_DELAY, function()
        if token ~= P.questSyncToken then
            return
        end
        P.SyncQuestLog(sourceEvent or "QUEST_LOG_UPDATE", false)
    end)
end

function P.RecordQuestAccepted(questID, sourceEvent)
    if not questID or P.IsRecent(P.recentAcceptances, questID) then
        return
    end

    P.recentAcceptances[questID] = GetTime()

    C_Timer.After(0.20, function()
        local character = P.EnsureCharacter()
        local key = tostring(questID)
        local previous = character.activeQuests[key]
        local snapshot = P.CaptureQuestState(questID, nil, previous)

        if not snapshot then
            return
        end

        local now = time()
        snapshot.acceptedAt = previous and previous.acceptedAt or now
        snapshot.acceptedAtText = P.TimestampText(snapshot.acceptedAt)
        snapshot.firstSeenAt = previous and previous.firstSeenAt or now
        snapshot.firstSeenAtText = P.TimestampText(snapshot.firstSeenAt)
        snapshot.fingerprint = P.QuestFingerprint(snapshot)
        character.activeQuests[key] = snapshot

        local event
        if QuestChronicleDB.settings.lifecycleTracking then
            local payload = P.QuestPayload(snapshot)
            payload.sourceEvent = sourceEvent or "QUEST_ACCEPTED"
            payload.changeReason = "ACCEPTED"
            event = P.AddEvent("QUEST_ACCEPTED", payload)

            if event and snapshot.questName == "" then
                P.RequestQuestTitle(questID, event.eventID)
            end

            if event and QuestChronicleDB.settings.chatNotifications then
                local questName = snapshot.questName ~= "" and snapshot.questName or ("Quest " .. tostring(questID))
                P.Print(string.format("Recorded acceptance: %s [%d]", questName, questID))
            end
        end

        P.ScheduleQuestSync("QUEST_ACCEPTED", 0.25)
    end)
end

function P.RecordQuestTurnIn(questID, xpReward, moneyReward)
    if not questID then
        return
    end

    P.recentTurnIns[questID] = GetTime()
    local character = P.EnsureCharacter()
    local activeQuest = character.activeQuests[tostring(questID)]
    local questName = P.GetQuestTitle(questID) or (activeQuest and activeQuest.questName) or ""
    local payload = {
        questID = questID,
        questName = questName,
        xpReward = xpReward or 0,
        moneyReward = moneyReward or 0,
        questState = "TURNED_IN",
        previousQuestState = activeQuest and activeQuest.questState or nil,
        changeReason = "COMPLETED_AND_TURNED_IN",
        sourceEvent = "QUEST_TURNED_IN",
    }

    if activeQuest then
        local activePayload = P.QuestPayload(activeQuest)
        for key, value in pairs(activePayload) do
            if payload[key] == nil then
                payload[key] = value
            end
        end

        payload.questState = "TURNED_IN"
        payload.previousQuestState = activeQuest.questState
        if activeQuest.acceptedAt then
            payload.elapsedSeconds = math.max(0, time() - activeQuest.acceptedAt)
        end
    end

    local event = P.AddEvent("QUEST_TURNED_IN", payload)
    if not event then
        return
    end

    if not questName or questName == "" then
        P.RequestQuestTitle(questID, event.eventID)
        questName = "Quest " .. tostring(questID)
    end

    if QuestChronicleDB.settings.chatNotifications then
        P.Print(string.format("Recorded completion: %s [%d]", questName, questID))
    end

    P.ScheduleQuestSync("QUEST_TURNED_IN", 0.25)
end

function P.RecordNote(text)
    text = text and text:match("^%s*(.-)%s*$") or ""
    if text == "" then
        P.Print("Usage: /qc note <your roleplay note>")
        return
    end

    local event = P.AddEvent("RP_NOTE", {
        note = text,
    })

    if event then
        P.Print("Recorded RP note #" .. tostring(event.sequence) .. ".")
    end

    return event
end

function P.CountEvents(character, eventType)
    local count = 0
    for _, event in ipairs(character.events or {}) do
        if not eventType or event.eventType == eventType then
            count = count + 1
        end
    end
    return count
end

function P.CountActiveQuests(character)
    local count = 0
    for _ in pairs(character.activeQuests or {}) do
        count = count + 1
    end
    return count
end

function P.PrintStatus()
    local character = P.currentCharacter or P.EnsureCharacter()
    local enabled = QuestChronicleDB.settings.enabled and "enabled" or "disabled"
    local chat = QuestChronicleDB.settings.chatNotifications and "on" or "off"
    local lifecycle = QuestChronicleDB.settings.lifecycleTracking and "on" or "off"
    local objectives = QuestChronicleDB.settings.objectiveTracking and "on" or "off"
    local removals = QuestChronicleDB.settings.removalTracking and "on" or "off"

    P.Print(string.format(
        "%s | %d events | %d active quests | %d accepted | %d completed | %d abandoned | recording %s",
        character.key,
        P.CountEvents(character),
        P.CountActiveQuests(character),
        P.CountEvents(character, "QUEST_ACCEPTED"),
        P.CountEvents(character, "QUEST_TURNED_IN"),
        P.CountEvents(character, "QUEST_ABANDONED"),
        enabled
    ))
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "  Chat notices %s | lifecycle %s | objectives %s | removals %s",
        chat,
        lifecycle,
        objectives,
        removals
    ))
end

P.QUEST_STATE_LABELS = {
    ACTIVE = "Active",
    READY_FOR_TURN_IN = "Ready for Turn-In",
    FAILED = "Failed",
    COMPLETE = "Complete",
    TURNED_IN = "Turned In",
    REMOVED = "Removed",
}

function P.FriendlyQuestState(value)
    value = P.SafeText(value)
    if P.QUEST_STATE_LABELS[value] then
        return P.QUEST_STATE_LABELS[value]
    end
    if value == "" then
        return "Unknown"
    end
    value = value:gsub("_", " "):lower()
    return (value:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest
    end))
end

function P.EventSummary(event)
    local questName = event.questName and event.questName ~= "" and event.questName
        or (event.questID and ("Quest " .. tostring(event.questID)) or "")

    if event.eventType == "QUEST_TURNED_IN" then
        return string.format("TURNED IN %s [%d]", questName, event.questID or 0)
    elseif event.eventType == "QUEST_ACCEPTED" then
        return string.format("ACCEPTED %s [%d]", questName, event.questID or 0)
    elseif event.eventType == "QUEST_ABANDONED" then
        return string.format("ABANDONED %s [%d]", questName, event.questID or 0)
    elseif event.eventType == "QUEST_REMOVED" then
        return string.format("REMOVED %s [%d] (%s)", questName, event.questID or 0, P.SafeText(event.removalReason))
    elseif event.eventType == "QUEST_BECAME_ACTIVE" then
        return string.format("ACTIVE %s [%d]", questName, event.questID or 0)
    elseif event.eventType == "QUEST_STATE_CHANGED" then
        return string.format("STATE %s: %s -> %s", questName, P.FriendlyQuestState(event.previousQuestState), P.FriendlyQuestState(event.questState))
    elseif event.eventType == "QUEST_OBJECTIVE_UPDATED" then
        return string.format(
            "OBJECTIVE %s #%d: %s",
            questName,
            event.objectiveIndex or 0,
            event.objectiveText ~= "" and P.SafeText(event.objectiveText) or P.SafeText(event.changeReason)
        )
    elseif event.eventType == "RP_NOTE" then
        return "NOTE " .. P.SafeText(event.note)
    end

    return P.SafeText(event.eventType)
end

function P.PrintRecent(count)
    local character = P.currentCharacter or P.EnsureCharacter()
    count = tonumber(count) or 5
    count = math.max(1, math.min(count, 30))

    local events = character.events or {}
    if #events == 0 then
        P.Print("No events recorded yet.")
        return
    end

    P.Print("Most recent events:")
    local first = math.max(1, #events - count + 1)
    for index = first, #events do
        local event = events[index]
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "  |cffd9b36c#%d|r %s",
            event.sequence,
            P.EventSummary(event)
        ))
    end
end

function P.PrintActive(count)
    local character = P.currentCharacter or P.EnsureCharacter()
    count = tonumber(count) or 25
    count = math.max(1, math.min(count, 50))

    local quests = {}
    for _, quest in pairs(character.activeQuests or {}) do
        table.insert(quests, quest)
    end
    table.sort(quests, function(left, right)
        return P.SafeText(left.questName) < P.SafeText(right.questName)
    end)

    P.Print(string.format("Active quests: %d", #quests))
    for index = 1, math.min(#quests, count) do
        local quest = quests[index]
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "  |cffd9b36c%s|r [%d] - %s - %d objectives",
            quest.questName ~= "" and quest.questName or ("Quest " .. tostring(quest.questID)),
            quest.questID,
            P.FriendlyQuestState(quest.questState),
            quest.objectiveCount or 0
        ))
    end
end

function P.SetTrackingSetting(settingName, value, label)
    if value == "on" then
        QuestChronicleDB.settings[settingName] = true
        P.Print(label .. " enabled.")
    elseif value == "off" then
        QuestChronicleDB.settings[settingName] = false
        P.Print(label .. " disabled.")
    else
        P.Print("Usage: /qc " .. label:lower() .. " on|off")
    end
end

function P.PrintHelp()
    P.Print("Commands:")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc|r or |cffd9b36c/qc show|r - open the Quest Chronicle window")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc help|r - show command help")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc status|r - show recorder and lifecycle status")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc recent [1-30]|r - show recent events")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc active [1-50]|r - show the current active quest snapshot")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc sync|r - rescan the active quest log now")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc note <text>|r - record an RP observation")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc export|r - refresh the courier export snapshot")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc on|off|r - enable or disable all event recording")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc chat on|off|r - toggle chat notices")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc lifecycle on|off|r - toggle acceptance and state events")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc objectives on|off|r - toggle objective progress events")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc removals on|off|r - toggle abandonment and removal events")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc minimap show|hide|toggle|reset|r - manage the minimap button")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc weapon debug|r - print weapon slot, option, and selection diagnostics")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc traveler debug|r - explain Traveler cohesion, mismatch budget, and outliers")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc skeleton debug|r - print the latest anchor beam and chosen skeleton")
    DEFAULT_CHAT_FRAME:AddMessage("  |cffd9b36c/qc debug|r - open the Diagnostics Workbench")
end

function P.HandleSlashCommand(message)
    local command, rest = message:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    rest = rest or ""

    if command == "" or command == "show" or command == "window" then
        if QC.ToggleWindow then
            QC.ToggleWindow()
        else
            P.PrintHelp()
        end
    elseif command == "help" then
        P.PrintHelp()
    elseif command == "status" then
        P.PrintStatus()
    elseif command == "debug" then
        if QC.ShowWindow then QC.ShowWindow("debug") else P.Print("The Debug Workbench is not available yet.") end
    elseif command == "recent" then
        P.PrintRecent(rest)
    elseif command == "active" then
        P.PrintActive(rest)
    elseif command == "sync" then
        P.SyncQuestLog("MANUAL_SYNC", false)
        local export = P.RefreshCourierExport()
        P.Print("Quest log synchronized; courier snapshot is " .. tostring(#export) .. " bytes.")
    elseif command == "note" then
        P.RecordNote(rest)
    elseif command == "export" then
        P.SyncQuestLog("MANUAL_EXPORT", false)
        local export = P.RefreshCourierExport()
        P.Print("Courier snapshot refreshed (" .. tostring(#export) .. " bytes). Run /reload to write it to disk now.")
    elseif command == "on" then
        QuestChronicleDB.settings.enabled = true
        P.Print("Recording enabled.")
    elseif command == "off" then
        QuestChronicleDB.settings.enabled = false
        P.Print("Recording disabled.")
    elseif command == "chat" then
        local value = string.lower(rest)
        if value == "on" then
            QuestChronicleDB.settings.chatNotifications = true
            P.Print("Chat notices enabled.")
        elseif value == "off" then
            QuestChronicleDB.settings.chatNotifications = false
            P.Print("Chat notices disabled.")
        else
            P.Print("Usage: /qc chat on|off")
        end
    elseif command == "lifecycle" then
        P.SetTrackingSetting("lifecycleTracking", string.lower(rest), "Lifecycle")
    elseif command == "objectives" then
        P.SetTrackingSetting("objectiveTracking", string.lower(rest), "Objectives")
    elseif command == "removals" then
        P.SetTrackingSetting("removalTracking", string.lower(rest), "Removals")
    elseif command == "traveler" then
        local subcommand = string.lower(rest:match("^(%S*)") or "")
        if subcommand == "debug" and QC.ZoneStyle and QC.ZoneStyle.PrintTravelerDiagnostics then
            QC.ZoneStyle.PrintTravelerDiagnostics()
        else
            P.Print("Usage: /qc traveler debug")
        end
    elseif command == "weapon" then
        local subcommand = string.lower(rest:match("^(%S*)") or "")
        if subcommand == "debug" and QC.Wardrobe and QC.Wardrobe.PrintWeaponRuleDiagnostics then
            QC.Wardrobe.PrintWeaponRuleDiagnostics()
        else
            P.Print("Usage: /qc weapon debug")
        end
    elseif command == "skeleton" then
        local subcommand = string.lower(rest:match("^(%S*)") or "")
        if subcommand == "debug" and QC.Wardrobe and QC.Wardrobe.PrintAnchorSkeletonDiagnostics then
            QC.Wardrobe.PrintAnchorSkeletonDiagnostics()
        else
            P.Print("Usage: /qc skeleton debug")
        end
    elseif command == "minimap" then
        local value = string.lower(rest or "")
        if value == "show" or value == "on" then
            if QC.SetMinimapButtonVisible then QC.SetMinimapButtonVisible(true) end
            P.Print("Minimap button shown.")
        elseif value == "hide" or value == "off" then
            if QC.SetMinimapButtonVisible then QC.SetMinimapButtonVisible(false) end
            P.Print("Minimap button hidden. Use /qc minimap show to restore it.")
        elseif value == "reset" then
            if QC.ResetMinimapButtonPosition then QC.ResetMinimapButtonPosition() end
        elseif value == "toggle" or value == "" then
            local visible = QuestChronicleDB.settings.showMinimapButton ~= false
            if QC.SetMinimapButtonVisible then QC.SetMinimapButtonVisible(not visible) end
            P.Print("Minimap button " .. (visible and "hidden." or "shown."))
        else
            P.Print("Usage: /qc minimap show|hide|toggle|reset")
        end
    else
        P.PrintHelp()
    end
end

-- Public API used by the v0.4.1 UI modules. The recorder remains local so
-- future UI work cannot accidentally replace its event handlers.
function QC.GetDatabase()
    P.EnsureDatabase()
    return QuestChronicleDB
end

function QC.GetCurrentCharacter()
    return P.currentCharacter or P.EnsureCharacter()
end

function QC.GetSettings()
    P.EnsureDatabase()
    return QuestChronicleDB.settings
end

function QC.GetUIState()
    P.EnsureDatabase()
    return QuestChronicleDB.ui
end
