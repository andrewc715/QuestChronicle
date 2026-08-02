local QC = QuestChronicle
local P = QC._Core
function P.AddEvent(eventType, payload)
    if not QuestChronicleDB or not QuestChronicleDB.settings.enabled then
        return nil
    end

    local character = P.currentCharacter or P.EnsureCharacter()
    local now = time()
    local location = P.GetLocation()
    local sequence = character.nextSequence or (#character.events + 1)

    local event = {
        schemaVersion = P.SCHEMA_VERSION,
        eventID = string.format("%s:%d:%d", character.key, now, sequence),
        sequence = sequence,
        eventType = eventType,
        characterKey = character.key,
        character = character.name,
        realm = character.realm,
        sessionID = P.currentSession and P.currentSession.id or nil,
        timestamp = now,
        timestampText = P.TimestampText(now),
        level = UnitLevel("player") or 0,
        zone = location.zone,
        subZone = location.subZone,
        mapID = location.mapID,
        x = location.x,
        y = location.y,
    }

    if payload then
        for key, value in pairs(payload) do
            event[key] = value
        end
    end

    table.insert(character.events, event)
    character.nextSequence = sequence + 1
    character.lastEventAt = now
    character.lastEventAtText = event.timestampText

    if QC.Notify then
        QC.Notify("EVENT_RECORDED", event)
    end

    return event
end

function P.GetQuestTitle(questID)
    if not questID then
        return nil
    end

    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local ok, title = pcall(C_QuestLog.GetTitleForQuestID, questID)
        if ok and title and title ~= "" then
            return title
        end
    end

    return nil
end

function P.RequestQuestTitle(questID, eventID)
    P.pendingQuestTitles[questID] = P.pendingQuestTitles[questID] or {}
    if eventID then
        table.insert(P.pendingQuestTitles[questID], eventID)
    end

    if C_QuestLog and C_QuestLog.RequestLoadQuestByID then
        pcall(C_QuestLog.RequestLoadQuestByID, questID)
    end
end

function P.UpdatePendingQuestTitles(questID)
    local pending = P.pendingQuestTitles[questID]
    if not pending then
        return
    end

    local title = P.GetQuestTitle(questID)
    if not title then
        return
    end

    local character = P.currentCharacter or P.EnsureCharacter()
    local eventLookup = {}
    for _, eventID in ipairs(pending) do
        eventLookup[eventID] = true
    end

    for _, event in ipairs(character.events) do
        if eventLookup[event.eventID] then
            event.questName = title
        end
    end

    local activeQuest = character.activeQuests[tostring(questID)]
    if activeQuest then
        activeQuest.questName = title
    end

    P.pendingQuestTitles[questID] = nil
    if QC.Notify then
        QC.Notify("DATA_UPDATED", "QUEST_TITLE", questID)
    end
end

function P.SafeQuestBoolean(functionName, questID)
    if not C_QuestLog or not C_QuestLog[functionName] then
        return false
    end

    local ok, value = pcall(C_QuestLog[functionName], questID)
    return ok and value == true
end

function P.NormalizeObjectives(questID)
    local normalized = {}
    if not C_QuestLog or not C_QuestLog.GetQuestObjectives then
        return normalized
    end

    local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
    if not ok or type(objectives) ~= "table" then
        return normalized
    end

    for index, objective in ipairs(objectives) do
        normalized[index] = {
            index = index,
            text = P.SafeText(objective.text),
            type = P.SafeText(objective.type),
            objectiveType = objective.objectiveType,
            finished = objective.finished == true,
            numFulfilled = type(objective.numFulfilled) == "number" and objective.numFulfilled or 0,
            numRequired = type(objective.numRequired) == "number" and objective.numRequired or 0,
        }
    end

    return normalized
end

function P.ObjectiveFingerprint(objective)
    if not objective then
        return "<missing>"
    end

    return table.concat({
        P.SafeText(objective.text),
        P.SafeText(objective.type),
        P.SafeText(objective.objectiveType),
        objective.finished and "1" or "0",
        P.SafeText(objective.numFulfilled),
        P.SafeText(objective.numRequired),
    }, "\031")
end

function P.QuestFingerprint(quest)
    local parts = {
        P.SafeText(quest.questName),
        P.SafeText(quest.questState),
        P.SafeText(quest.questLevel),
        P.SafeText(quest.difficultyLevel),
        quest.isComplete and "1" or "0",
        quest.isFailed and "1" or "0",
        quest.isTask and "1" or "0",
        quest.isWorldQuest and "1" or "0",
        quest.isHidden and "1" or "0",
        quest.isAutoComplete and "1" or "0",
    }

    for _, objective in ipairs(quest.objectives or {}) do
        table.insert(parts, P.ObjectiveFingerprint(objective))
    end

    return table.concat(parts, "\030")
end

function P.GetQuestLogInfo(questID)
    if not C_QuestLog or not C_QuestLog.GetLogIndexForQuestID or not C_QuestLog.GetInfo then
        return nil
    end

    local okIndex, questLogIndex = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
    if not okIndex or not questLogIndex then
        return nil
    end

    local okInfo, info = pcall(C_QuestLog.GetInfo, questLogIndex)
    if not okInfo then
        return nil
    end

    return info
end

function P.CaptureQuestState(questID, info, previous)
    if not questID then
        return nil
    end

    info = info or P.GetQuestLogInfo(questID) or {}
    local now = time()
    local isComplete = P.SafeQuestBoolean("IsComplete", questID)
    local isFailed = P.SafeQuestBoolean("IsFailed", questID)
    local isWorldQuest = P.SafeQuestBoolean("IsWorldQuest", questID)
    local questState = "ACTIVE"

    if isFailed then
        questState = "FAILED"
    elseif isComplete then
        questState = "READY_FOR_TURN_IN"
    end

    local questName = info.title or P.GetQuestTitle(questID) or ""
    local firstSeenAt = previous and previous.firstSeenAt or now
    local acceptedAt = previous and previous.acceptedAt or nil

    local snapshot = {
        questID = questID,
        questName = questName,
        questState = questState,
        questLevel = info.level,
        difficultyLevel = info.difficultyLevel,
        isComplete = isComplete,
        isFailed = isFailed,
        isTask = info.isTask == true,
        isWorldQuest = isWorldQuest,
        isHidden = info.isHidden == true,
        isAutoComplete = info.isAutoComplete == true,
        acceptedAt = acceptedAt,
        acceptedAtText = acceptedAt and P.TimestampText(acceptedAt) or nil,
        firstSeenAt = firstSeenAt,
        firstSeenAtText = P.TimestampText(firstSeenAt),
        lastSeenAt = now,
        lastSeenAtText = P.TimestampText(now),
        updatedAt = now,
        updatedAtText = P.TimestampText(now),
        objectives = P.NormalizeObjectives(questID),
    }

    snapshot.objectiveCount = #snapshot.objectives
    snapshot.fingerprint = P.QuestFingerprint(snapshot)
    return snapshot
end

function P.EnumerateActiveQuests(previousMap)
    local result = {}
    if not C_QuestLog or not C_QuestLog.GetNumQuestLogEntries or not C_QuestLog.GetInfo then
        return result
    end

    local okCount, numShownEntries = pcall(C_QuestLog.GetNumQuestLogEntries)
    if not okCount or type(numShownEntries) ~= "number" then
        return result
    end

    for questLogIndex = 1, numShownEntries do
        local okInfo, info = pcall(C_QuestLog.GetInfo, questLogIndex)
        if okInfo and info and not info.isHeader and info.questID and info.questID > 0 then
            local key = tostring(info.questID)
            result[key] = P.CaptureQuestState(info.questID, info, previousMap and previousMap[key])
        end
    end

    return result
end

function P.QuestPayload(quest)
    return {
        questID = quest.questID,
        questName = quest.questName,
        questState = quest.questState,
        questLevel = quest.questLevel,
        difficultyLevel = quest.difficultyLevel,
        isComplete = quest.isComplete,
        isFailed = quest.isFailed,
        isTask = quest.isTask,
        isWorldQuest = quest.isWorldQuest,
        isHidden = quest.isHidden,
        isAutoComplete = quest.isAutoComplete,
        acceptedAt = quest.acceptedAt,
        acceptedAtText = quest.acceptedAtText,
        objectiveCount = quest.objectiveCount,
        objectives = P.CloneObjectives(quest.objectives),
    }
end

function P.IsRecent(lookup, questID)
    local recordedAt = lookup[questID]
    return recordedAt and (GetTime() - recordedAt) <= P.RECENT_EVENT_WINDOW
end

function P.IsQuestCurrentlyActive(questID)
    if C_QuestLog and C_QuestLog.IsOnQuest then
        local ok, isOnQuest = pcall(C_QuestLog.IsOnQuest, questID)
        if ok then
            return isOnQuest == true
        end
    end

    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
        return ok and index ~= nil
    end

    return false
end

function P.RecordObjectiveChanges(previous, current, sourceEvent)
    if not QuestChronicleDB.settings.objectiveTracking then
        return
    end

    local maxObjectives = math.max(#(previous.objectives or {}), #(current.objectives or {}))
    for index = 1, maxObjectives do
        local oldObjective = previous.objectives and previous.objectives[index]
        local newObjective = current.objectives and current.objectives[index]

        if P.ObjectiveFingerprint(oldObjective) ~= P.ObjectiveFingerprint(newObjective) then
            local payload = P.QuestPayload(current)
            payload.sourceEvent = sourceEvent
            payload.changeReason = oldObjective and newObjective and "PROGRESS_CHANGED"
                or (newObjective and "OBJECTIVE_ADDED" or "OBJECTIVE_REMOVED")
            payload.objectiveIndex = index

            if newObjective then
                payload.objectiveText = newObjective.text
                payload.objectiveType = newObjective.type
                payload.objectiveTypeID = newObjective.objectiveType
                payload.objectiveFinished = newObjective.finished
                payload.numFulfilled = newObjective.numFulfilled
                payload.numRequired = newObjective.numRequired
            end

            if oldObjective then
                payload.previousObjectiveText = oldObjective.text
                payload.previousObjectiveFinished = oldObjective.finished
                payload.previousNumFulfilled = oldObjective.numFulfilled
                payload.previousNumRequired = oldObjective.numRequired
            end

            payload.objectives = nil
            P.AddEvent("QUEST_OBJECTIVE_UPDATED", payload)
        end
    end
end

function P.RecordStateChange(previous, current, sourceEvent)
    if not QuestChronicleDB.settings.lifecycleTracking then
        return
    end

    if previous.questState ~= current.questState then
        local payload = P.QuestPayload(current)
        payload.previousQuestState = previous.questState
        payload.sourceEvent = sourceEvent
        payload.changeReason = "QUEST_STATE_CHANGED"
        P.AddEvent("QUEST_STATE_CHANGED", payload)
    end
end

function P.ClassifyQuestRemoval(questID)
    local pending = P.pendingQuestRemovals[questID]
    if not pending then
        return
    end

    P.pendingQuestRemovals[questID] = nil

    if P.IsQuestCurrentlyActive(questID) then
        return
    end

    if P.IsRecent(P.recentTurnIns, questID) then
        return
    end

    if not QuestChronicleDB.settings.removalTracking then
        return
    end

    local previous = pending.snapshot
    local payload = P.QuestPayload(previous)
    payload.sourceEvent = pending.sourceEvent
    payload.previousQuestState = previous.questState

    if P.IsRecent(P.confirmedAbandons, questID) then
        payload.removalReason = "PLAYER_CONFIRMED_ABANDON"
        payload.removalConfidence = "CONFIRMED"
        payload.changeReason = "ABANDONED"
        P.AddEvent("QUEST_ABANDONED", payload)

        if QuestChronicleDB.settings.chatNotifications then
            local questName = previous.questName ~= "" and previous.questName or ("Quest " .. tostring(questID))
            P.Print(string.format("Recorded abandonment: %s [%d]", questName, questID))
        end
    else
        if previous.isTask or previous.isWorldQuest then
            payload.removalReason = "DYNAMIC_OR_WORLD_QUEST_REMOVED"
        elseif previous.isFailed then
            payload.removalReason = "FAILED_OR_SCRIPTED_REMOVAL"
        else
            payload.removalReason = "UNKNOWN_REMOVAL"
        end

        payload.removalConfidence = "UNCONFIRMED"
        payload.changeReason = "REMOVED_FROM_LOG"
        P.AddEvent("QUEST_REMOVED", payload)
    end
end

function P.QueueQuestRemoval(questID, snapshot, sourceEvent)
    if not questID or not snapshot or P.pendingQuestRemovals[questID] then
        return
    end

    P.pendingQuestRemovals[questID] = {
        snapshot = snapshot,
        sourceEvent = sourceEvent or "QUEST_LOG_DIFF",
        queuedAt = GetTime(),
    }

    C_Timer.After(P.REMOVAL_CLASSIFY_DELAY, function()
        P.ClassifyQuestRemoval(questID)
    end)
end
