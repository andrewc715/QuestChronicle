local ADDON_NAME = ...

QuestChronicle = QuestChronicle or {}
local QC = QuestChronicle

local frame = CreateFrame("Frame")
local currentCharacter
local currentSession
local pendingQuestTitles = {}
local pendingQuestRemovals = {}
local recentTurnIns = {}
local recentAcceptances = {}
local confirmedAbandons = {}
local abandonCandidateQuestID
local questSyncToken = 0

local SCHEMA_VERSION = 2
local COURIER_FORMAT_VERSION = 1
local ADDON_VERSION = "1.0.1"
local PREFIX = "|cffd9b36cQuest Chronicle:|r "
local OBJECTIVE_SYNC_DELAY = 0.35
local REMOVAL_CLASSIFY_DELAY = 0.45
local RECENT_EVENT_WINDOW = 8

QC.addonName = ADDON_NAME
QC.version = ADDON_VERSION
QC.schemaVersion = SCHEMA_VERSION
QC.courierFormatVersion = COURIER_FORMAT_VERSION

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(message))
end

local function SafeText(value)
    if value == nil then
        return ""
    end

    local ok, text = pcall(tostring, value)
    if ok then
        return text
    end

    return ""
end

local function TimestampText(timestamp)
    return date("%Y-%m-%dT%H:%M:%S", timestamp)
end

local function ShallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function CloneObjectives(objectives)
    local copy = {}
    for index, objective in ipairs(objectives or {}) do
        copy[index] = ShallowCopy(objective)
    end
    return copy
end

local function JsonEscape(value)
    local text = SafeText(value)
    text = text:gsub("\\", "\\\\")
    text = text:gsub('"', '\\"')
    text = text:gsub("\b", "\\b")
    text = text:gsub("\f", "\\f")
    text = text:gsub("\n", "\\n")
    text = text:gsub("\r", "\\r")
    text = text:gsub("\t", "\\t")
    text = text:gsub("[%z\1-\31]", function(char)
        return string.format("\\u%04x", string.byte(char))
    end)
    return text
end

local function JsonString(value)
    return '"' .. JsonEscape(value) .. '"'
end

local function IsArray(value)
    local count = 0
    local highest = 0

    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false
        end

        count = count + 1
        if key > highest then
            highest = key
        end
    end

    return highest == count
end

local function JsonEncode(value, seen)
    local valueType = type(value)

    if value == nil then
        return "null"
    elseif valueType == "boolean" then
        return value and "true" or "false"
    elseif valueType == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return "null"
        end
        return tostring(value)
    elseif valueType == "string" then
        return JsonString(value)
    elseif valueType ~= "table" then
        return JsonString(SafeText(value))
    end

    seen = seen or {}
    if seen[value] then
        return "null"
    end
    seen[value] = true

    local parts = {}
    if IsArray(value) then
        for index = 1, #value do
            parts[index] = JsonEncode(value[index], seen)
        end
        seen[value] = nil
        return "[" .. table.concat(parts, ",") .. "]"
    end

    local keys = {}
    for key in pairs(value) do
        table.insert(keys, SafeText(key))
    end
    table.sort(keys)

    for _, key in ipairs(keys) do
        local originalValue = value[key]
        if originalValue == nil then
            local numericKey = tonumber(key)
            if numericKey then
                originalValue = value[numericKey]
            end
        end
        table.insert(parts, JsonString(key) .. ":" .. JsonEncode(originalValue, seen))
    end

    seen[value] = nil
    return "{" .. table.concat(parts, ",") .. "}"
end

local EVENT_EXPORT_FIELDS = {
    "schemaVersion", "eventID", "sequence", "eventType",
    "characterKey", "character", "realm", "sessionID",
    "timestamp", "timestampText", "level", "zone", "subZone",
    "mapID", "x", "y", "questID", "questName", "xpReward",
    "moneyReward", "note", "questState", "previousQuestState",
    "changeReason", "removalReason", "removalConfidence", "sourceEvent",
    "questLevel", "difficultyLevel", "isComplete", "isFailed", "isTask",
    "isWorldQuest", "isHidden", "isAutoComplete", "acceptedAt",
    "acceptedAtText", "elapsedSeconds", "objectiveCount", "objectiveIndex",
    "objectiveText", "objectiveType", "objectiveTypeID", "objectiveFinished",
    "numFulfilled", "numRequired", "previousObjectiveText",
    "previousObjectiveFinished", "previousNumFulfilled", "previousNumRequired",
}

local SESSION_EXPORT_FIELDS = {
    "id", "startedAt", "startedAtText", "startLevel", "startZone",
    "startSubZone", "startMapID", "endedAt", "endedAtText", "endLevel",
    "endZone", "endSubZone", "endMapID",
}

local CHARACTER_EXPORT_FIELDS = {
    "key", "name", "realm", "className", "classID", "raceName",
    "raceID", "faction", "createdAt", "createdAtText", "lastEventAt",
    "lastEventAtText", "lastQuestSyncAt", "lastQuestSyncAtText",
}

local ACTIVE_QUEST_EXPORT_FIELDS = {
    "questID", "questName", "questState", "questLevel", "difficultyLevel",
    "isComplete", "isFailed", "isTask", "isWorldQuest", "isHidden",
    "isAutoComplete", "acceptedAt", "acceptedAtText", "firstSeenAt",
    "firstSeenAtText", "lastSeenAt", "lastSeenAtText", "updatedAt",
    "updatedAtText", "objectiveCount",
}

local OBJECTIVE_EXPORT_FIELDS = {
    "index", "text", "type", "objectiveType", "finished",
    "numFulfilled", "numRequired",
}

local function CopyKnownFields(source, fields)
    local result = {}
    for _, key in ipairs(fields) do
        if source and source[key] ~= nil then
            result[key] = source[key]
        end
    end
    return result
end

local function ExportObjectives(objectives)
    local result = {}
    for index, objective in ipairs(objectives or {}) do
        result[index] = CopyKnownFields(objective, OBJECTIVE_EXPORT_FIELDS)
    end
    return result
end

local function ExportEvent(event)
    local result = CopyKnownFields(event, EVENT_EXPORT_FIELDS)
    if event and event.objectives then
        result.objectives = ExportObjectives(event.objectives)
    end
    return result
end

local function ExportActiveQuest(quest)
    local result = CopyKnownFields(quest, ACTIVE_QUEST_EXPORT_FIELDS)
    result.objectives = ExportObjectives(quest and quest.objectives)
    return result
end

local function BuildCourierExport()
    local now = time()
    local export = {
        formatVersion = COURIER_FORMAT_VERSION,
        schemaVersion = SCHEMA_VERSION,
        addonVersion = ADDON_VERSION,
        generatedAt = now,
        generatedAtText = TimestampText(now),
        characters = {},
    }

    if QuestChronicleDB and QuestChronicleDB.characters then
        local characterKeys = {}
        for key in pairs(QuestChronicleDB.characters) do
            table.insert(characterKeys, key)
        end
        table.sort(characterKeys)

        for _, key in ipairs(characterKeys) do
            local character = QuestChronicleDB.characters[key]
            local characterExport = CopyKnownFields(character, CHARACTER_EXPORT_FIELDS)
            characterExport.events = {}
            characterExport.sessions = {}
            characterExport.activeQuests = {}

            for index, event in ipairs(character.events or {}) do
                characterExport.events[index] = ExportEvent(event)
            end

            for index, session in ipairs(character.sessions or {}) do
                characterExport.sessions[index] = CopyKnownFields(session, SESSION_EXPORT_FIELDS)
            end

            local activeQuestIDs = {}
            for questID in pairs(character.activeQuests or {}) do
                table.insert(activeQuestIDs, tonumber(questID) or questID)
            end
            table.sort(activeQuestIDs, function(left, right)
                return tonumber(left) < tonumber(right)
            end)

            for _, questID in ipairs(activeQuestIDs) do
                local quest = character.activeQuests[tostring(questID)] or character.activeQuests[questID]
                table.insert(characterExport.activeQuests, ExportActiveQuest(quest))
            end

            characterExport.activeQuestCount = #characterExport.activeQuests
            table.insert(export.characters, characterExport)
        end
    end

    return JsonEncode(export)
end

local function RefreshCourierExport()
    QuestChronicleCourierExport = BuildCourierExport()
    if QC.Notify then
        QC.Notify("COURIER_EXPORT_REFRESHED", #QuestChronicleCourierExport)
    end
    return QuestChronicleCourierExport
end

local function GetCharacterIdentity()
    local name, realm = UnitFullName("player")
    name = name or UnitName("player") or "Unknown"
    realm = realm or GetRealmName() or "Unknown Realm"

    return name, realm, realm .. " - " .. name
end

local function GetLocation()
    local zone = GetZoneText() or ""
    local subZone = GetSubZoneText() or ""
    local mapID
    local x
    local y

    if C_Map and C_Map.GetBestMapForUnit then
        mapID = C_Map.GetBestMapForUnit("player")
        if mapID and C_Map.GetPlayerMapPosition then
            local position = C_Map.GetPlayerMapPosition(mapID, "player")
            if position and position.GetXY then
                x, y = position:GetXY()
            end
        end
    end

    return {
        zone = zone,
        subZone = subZone,
        mapID = mapID,
        x = x,
        y = y,
    }
end

local function EnsureDatabase()
    QuestChronicleDB = QuestChronicleDB or {}
    QuestChronicleDB.schemaVersion = SCHEMA_VERSION
    QuestChronicleDB.addonVersion = ADDON_VERSION
    QuestChronicleDB.settings = QuestChronicleDB.settings or {}
    QuestChronicleDB.settings.enabled = QuestChronicleDB.settings.enabled ~= false
    QuestChronicleDB.settings.chatNotifications = QuestChronicleDB.settings.chatNotifications ~= false
    QuestChronicleDB.settings.lifecycleTracking = QuestChronicleDB.settings.lifecycleTracking ~= false
    QuestChronicleDB.settings.objectiveTracking = QuestChronicleDB.settings.objectiveTracking ~= false
    QuestChronicleDB.settings.removalTracking = QuestChronicleDB.settings.removalTracking ~= false
    QuestChronicleDB.settings.rememberWindowPosition = QuestChronicleDB.settings.rememberWindowPosition ~= false
    QuestChronicleDB.settings.lockWindow = QuestChronicleDB.settings.lockWindow == true
    QuestChronicleDB.settings.showQuestIDs = QuestChronicleDB.settings.showQuestIDs ~= false
    QuestChronicleDB.settings.showDateSeparators = QuestChronicleDB.settings.showDateSeparators ~= false
    QuestChronicleDB.settings.confirmClearDraft = QuestChronicleDB.settings.confirmClearDraft ~= false
    QuestChronicleDB.settings.restrictOutfitsToZoneEra = QuestChronicleDB.settings.restrictOutfitsToZoneEra ~= false
    QuestChronicleDB.settings.autoRefreshWardrobe = QuestChronicleDB.settings.autoRefreshWardrobe ~= false
    QuestChronicleDB.settings.recoverMissingAppearances = QuestChronicleDB.settings.recoverMissingAppearances ~= false
    QuestChronicleDB.settings.announceWardrobeUpdates = QuestChronicleDB.settings.announceWardrobeUpdates ~= false
    QuestChronicleDB.settings.highContrastOutfitStates = QuestChronicleDB.settings.highContrastOutfitStates == true
    QuestChronicleDB.characters = QuestChronicleDB.characters or {}
    QuestChronicleDB.ui = QuestChronicleDB.ui or {}
    QuestChronicleDB.ui.lastTab = QuestChronicleDB.ui.lastTab or "chronicle"
    QuestChronicleDB.ui.noteDrafts = QuestChronicleDB.ui.noteDrafts or {}
    QuestChronicleDB.ui.chronicleFilter = QuestChronicleDB.ui.chronicleFilter or "ALL"
    QuestChronicleDB.ui.chronicleNewestFirst = QuestChronicleDB.ui.chronicleNewestFirst ~= false
    QuestChronicleDB.ui.chronicleSearch = QuestChronicleDB.ui.chronicleSearch or ""
    QuestChronicleDB.ui.activeQuestFilter = QuestChronicleDB.ui.activeQuestFilter or "ALL"
    QuestChronicleDB.ui.activeQuestSort = QuestChronicleDB.ui.activeQuestSort or "READY"
    QuestChronicleDB.ui.window = QuestChronicleDB.ui.window or {}
end

local function EnsureCharacter()
    EnsureDatabase()

    local name, realm, key = GetCharacterIdentity()
    local _, className, classID = UnitClass("player")
    local raceName, _, raceID = UnitRace("player")

    local character = QuestChronicleDB.characters[key]
    if not character then
        local now = time()
        character = {
            key = key,
            name = name,
            realm = realm,
            className = className or "",
            classID = classID,
            raceName = raceName or "",
            raceID = raceID,
            faction = UnitFactionGroup("player") or "",
            createdAt = now,
            createdAtText = TimestampText(now),
            nextSequence = 1,
            events = {},
            sessions = {},
            activeQuests = {},
        }
        QuestChronicleDB.characters[key] = character
    end

    character.name = name
    character.realm = realm
    character.className = className or character.className or ""
    character.classID = classID or character.classID
    character.raceName = raceName or character.raceName or ""
    character.raceID = raceID or character.raceID
    character.faction = UnitFactionGroup("player") or character.faction or ""
    character.nextSequence = character.nextSequence or (#character.events + 1)
    character.events = character.events or {}
    character.sessions = character.sessions or {}
    character.activeQuests = character.activeQuests or {}

    currentCharacter = character
    return character
end

local function StartSession()
    local character = EnsureCharacter()
    local now = time()
    local location = GetLocation()

    currentSession = {
        id = string.format("%s:%d:%d", character.key, now, #character.sessions + 1),
        startedAt = now,
        startedAtText = TimestampText(now),
        startLevel = UnitLevel("player") or 0,
        startZone = location.zone,
        startSubZone = location.subZone,
        startMapID = location.mapID,
    }

    table.insert(character.sessions, currentSession)
end

local function EndSession()
    if not currentSession then
        return
    end

    local now = time()
    local location = GetLocation()
    currentSession.endedAt = now
    currentSession.endedAtText = TimestampText(now)
    currentSession.endLevel = UnitLevel("player") or 0
    currentSession.endZone = location.zone
    currentSession.endSubZone = location.subZone
    currentSession.endMapID = location.mapID
end

local function AddEvent(eventType, payload)
    if not QuestChronicleDB or not QuestChronicleDB.settings.enabled then
        return nil
    end

    local character = currentCharacter or EnsureCharacter()
    local now = time()
    local location = GetLocation()
    local sequence = character.nextSequence or (#character.events + 1)

    local event = {
        schemaVersion = SCHEMA_VERSION,
        eventID = string.format("%s:%d:%d", character.key, now, sequence),
        sequence = sequence,
        eventType = eventType,
        characterKey = character.key,
        character = character.name,
        realm = character.realm,
        sessionID = currentSession and currentSession.id or nil,
        timestamp = now,
        timestampText = TimestampText(now),
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

local function GetQuestTitle(questID)
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

local function RequestQuestTitle(questID, eventID)
    pendingQuestTitles[questID] = pendingQuestTitles[questID] or {}
    if eventID then
        table.insert(pendingQuestTitles[questID], eventID)
    end

    if C_QuestLog and C_QuestLog.RequestLoadQuestByID then
        pcall(C_QuestLog.RequestLoadQuestByID, questID)
    end
end

local function UpdatePendingQuestTitles(questID)
    local pending = pendingQuestTitles[questID]
    if not pending then
        return
    end

    local title = GetQuestTitle(questID)
    if not title then
        return
    end

    local character = currentCharacter or EnsureCharacter()
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

    pendingQuestTitles[questID] = nil
    if QC.Notify then
        QC.Notify("DATA_UPDATED", "QUEST_TITLE", questID)
    end
end

local function SafeQuestBoolean(functionName, questID)
    if not C_QuestLog or not C_QuestLog[functionName] then
        return false
    end

    local ok, value = pcall(C_QuestLog[functionName], questID)
    return ok and value == true
end

local function NormalizeObjectives(questID)
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
            text = SafeText(objective.text),
            type = SafeText(objective.type),
            objectiveType = objective.objectiveType,
            finished = objective.finished == true,
            numFulfilled = type(objective.numFulfilled) == "number" and objective.numFulfilled or 0,
            numRequired = type(objective.numRequired) == "number" and objective.numRequired or 0,
        }
    end

    return normalized
end

local function ObjectiveFingerprint(objective)
    if not objective then
        return "<missing>"
    end

    return table.concat({
        SafeText(objective.text),
        SafeText(objective.type),
        SafeText(objective.objectiveType),
        objective.finished and "1" or "0",
        SafeText(objective.numFulfilled),
        SafeText(objective.numRequired),
    }, "\031")
end

local function QuestFingerprint(quest)
    local parts = {
        SafeText(quest.questName),
        SafeText(quest.questState),
        SafeText(quest.questLevel),
        SafeText(quest.difficultyLevel),
        quest.isComplete and "1" or "0",
        quest.isFailed and "1" or "0",
        quest.isTask and "1" or "0",
        quest.isWorldQuest and "1" or "0",
        quest.isHidden and "1" or "0",
        quest.isAutoComplete and "1" or "0",
    }

    for _, objective in ipairs(quest.objectives or {}) do
        table.insert(parts, ObjectiveFingerprint(objective))
    end

    return table.concat(parts, "\030")
end

local function GetQuestLogInfo(questID)
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

local function CaptureQuestState(questID, info, previous)
    if not questID then
        return nil
    end

    info = info or GetQuestLogInfo(questID) or {}
    local now = time()
    local isComplete = SafeQuestBoolean("IsComplete", questID)
    local isFailed = SafeQuestBoolean("IsFailed", questID)
    local isWorldQuest = SafeQuestBoolean("IsWorldQuest", questID)
    local questState = "ACTIVE"

    if isFailed then
        questState = "FAILED"
    elseif isComplete then
        questState = "READY_FOR_TURN_IN"
    end

    local questName = info.title or GetQuestTitle(questID) or ""
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
        acceptedAtText = acceptedAt and TimestampText(acceptedAt) or nil,
        firstSeenAt = firstSeenAt,
        firstSeenAtText = TimestampText(firstSeenAt),
        lastSeenAt = now,
        lastSeenAtText = TimestampText(now),
        updatedAt = now,
        updatedAtText = TimestampText(now),
        objectives = NormalizeObjectives(questID),
    }

    snapshot.objectiveCount = #snapshot.objectives
    snapshot.fingerprint = QuestFingerprint(snapshot)
    return snapshot
end

local function EnumerateActiveQuests(previousMap)
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
            result[key] = CaptureQuestState(info.questID, info, previousMap and previousMap[key])
        end
    end

    return result
end

local function QuestPayload(quest)
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
        objectives = CloneObjectives(quest.objectives),
    }
end

local function IsRecent(lookup, questID)
    local recordedAt = lookup[questID]
    return recordedAt and (GetTime() - recordedAt) <= RECENT_EVENT_WINDOW
end

local function IsQuestCurrentlyActive(questID)
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

local function RecordObjectiveChanges(previous, current, sourceEvent)
    if not QuestChronicleDB.settings.objectiveTracking then
        return
    end

    local maxObjectives = math.max(#(previous.objectives or {}), #(current.objectives or {}))
    for index = 1, maxObjectives do
        local oldObjective = previous.objectives and previous.objectives[index]
        local newObjective = current.objectives and current.objectives[index]

        if ObjectiveFingerprint(oldObjective) ~= ObjectiveFingerprint(newObjective) then
            local payload = QuestPayload(current)
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
            AddEvent("QUEST_OBJECTIVE_UPDATED", payload)
        end
    end
end

local function RecordStateChange(previous, current, sourceEvent)
    if not QuestChronicleDB.settings.lifecycleTracking then
        return
    end

    if previous.questState ~= current.questState then
        local payload = QuestPayload(current)
        payload.previousQuestState = previous.questState
        payload.sourceEvent = sourceEvent
        payload.changeReason = "QUEST_STATE_CHANGED"
        AddEvent("QUEST_STATE_CHANGED", payload)
    end
end

local function ClassifyQuestRemoval(questID)
    local pending = pendingQuestRemovals[questID]
    if not pending then
        return
    end

    pendingQuestRemovals[questID] = nil

    if IsQuestCurrentlyActive(questID) then
        return
    end

    if IsRecent(recentTurnIns, questID) then
        return
    end

    if not QuestChronicleDB.settings.removalTracking then
        return
    end

    local previous = pending.snapshot
    local payload = QuestPayload(previous)
    payload.sourceEvent = pending.sourceEvent
    payload.previousQuestState = previous.questState

    if IsRecent(confirmedAbandons, questID) then
        payload.removalReason = "PLAYER_CONFIRMED_ABANDON"
        payload.removalConfidence = "CONFIRMED"
        payload.changeReason = "ABANDONED"
        AddEvent("QUEST_ABANDONED", payload)

        if QuestChronicleDB.settings.chatNotifications then
            local questName = previous.questName ~= "" and previous.questName or ("Quest " .. tostring(questID))
            Print(string.format("Recorded abandonment: %s [%d]", questName, questID))
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
        AddEvent("QUEST_REMOVED", payload)
    end
end

local function QueueQuestRemoval(questID, snapshot, sourceEvent)
    if not questID or not snapshot or pendingQuestRemovals[questID] then
        return
    end

    pendingQuestRemovals[questID] = {
        snapshot = snapshot,
        sourceEvent = sourceEvent or "QUEST_LOG_DIFF",
        queuedAt = GetTime(),
    }

    C_Timer.After(REMOVAL_CLASSIFY_DELAY, function()
        ClassifyQuestRemoval(questID)
    end)
end

local function SyncQuestLog(sourceEvent, suppressLifecycleEvents)
    if not currentCharacter then
        return
    end

    local character = EnsureCharacter()
    local previousMap = character.activeQuests or {}
    local currentMap = EnumerateActiveQuests(previousMap)
    local now = time()

    for key, current in pairs(currentMap) do
        local previous = previousMap[key]

        if previous then
            current.acceptedAt = previous.acceptedAt
            current.acceptedAtText = previous.acceptedAtText
            current.firstSeenAt = previous.firstSeenAt or current.firstSeenAt
            current.firstSeenAtText = previous.firstSeenAtText or current.firstSeenAtText

            if not suppressLifecycleEvents and previous.fingerprint ~= current.fingerprint then
                RecordObjectiveChanges(previous, current, sourceEvent)
                RecordStateChange(previous, current, sourceEvent)
            end
        elseif not suppressLifecycleEvents and not IsRecent(recentAcceptances, current.questID) then
            if QuestChronicleDB.settings.lifecycleTracking then
                local payload = QuestPayload(current)
                payload.sourceEvent = sourceEvent
                payload.changeReason = current.isTask or current.isWorldQuest
                    and "BECAME_ACTIVE_WITHOUT_ACCEPT_EVENT"
                    or "DISCOVERED_BY_QUEST_LOG_DIFF"

                if current.isTask or current.isWorldQuest then
                    AddEvent("QUEST_BECAME_ACTIVE", payload)
                else
                    current.acceptedAt = now
                    current.acceptedAtText = TimestampText(now)
                    payload.acceptedAt = now
                    payload.acceptedAtText = current.acceptedAtText
                    AddEvent("QUEST_ACCEPTED", payload)
                    recentAcceptances[current.questID] = GetTime()
                end
            end
        end
    end

    if not suppressLifecycleEvents then
        for key, previous in pairs(previousMap) do
            if not currentMap[key] then
                QueueQuestRemoval(previous.questID, previous, sourceEvent)
            end
        end
    end

    character.activeQuests = currentMap
    character.lastQuestSyncAt = now
    character.lastQuestSyncAtText = TimestampText(now)

    if QC.Notify then
        QC.Notify("ACTIVE_QUESTS_UPDATED", sourceEvent)
    end
end

local function ScheduleQuestSync(sourceEvent, delay)
    questSyncToken = questSyncToken + 1
    local token = questSyncToken

    C_Timer.After(delay or OBJECTIVE_SYNC_DELAY, function()
        if token ~= questSyncToken then
            return
        end
        SyncQuestLog(sourceEvent or "QUEST_LOG_UPDATE", false)
    end)
end

local function RecordQuestAccepted(questID, sourceEvent)
    if not questID or IsRecent(recentAcceptances, questID) then
        return
    end

    recentAcceptances[questID] = GetTime()

    C_Timer.After(0.20, function()
        local character = EnsureCharacter()
        local key = tostring(questID)
        local previous = character.activeQuests[key]
        local snapshot = CaptureQuestState(questID, nil, previous)

        if not snapshot then
            return
        end

        local now = time()
        snapshot.acceptedAt = previous and previous.acceptedAt or now
        snapshot.acceptedAtText = TimestampText(snapshot.acceptedAt)
        snapshot.firstSeenAt = previous and previous.firstSeenAt or now
        snapshot.firstSeenAtText = TimestampText(snapshot.firstSeenAt)
        snapshot.fingerprint = QuestFingerprint(snapshot)
        character.activeQuests[key] = snapshot

        local event
        if QuestChronicleDB.settings.lifecycleTracking then
            local payload = QuestPayload(snapshot)
            payload.sourceEvent = sourceEvent or "QUEST_ACCEPTED"
            payload.changeReason = "ACCEPTED"
            event = AddEvent("QUEST_ACCEPTED", payload)

            if event and snapshot.questName == "" then
                RequestQuestTitle(questID, event.eventID)
            end

            if event and QuestChronicleDB.settings.chatNotifications then
                local questName = snapshot.questName ~= "" and snapshot.questName or ("Quest " .. tostring(questID))
                Print(string.format("Recorded acceptance: %s [%d]", questName, questID))
            end
        end

        ScheduleQuestSync("QUEST_ACCEPTED", 0.25)
    end)
end

local function RecordQuestTurnIn(questID, xpReward, moneyReward)
    if not questID then
        return
    end

    recentTurnIns[questID] = GetTime()
    local character = EnsureCharacter()
    local activeQuest = character.activeQuests[tostring(questID)]
    local questName = GetQuestTitle(questID) or (activeQuest and activeQuest.questName) or ""
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
        local activePayload = QuestPayload(activeQuest)
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

    local event = AddEvent("QUEST_TURNED_IN", payload)
    if not event then
        return
    end

    if not questName or questName == "" then
        RequestQuestTitle(questID, event.eventID)
        questName = "Quest " .. tostring(questID)
    end

    if QuestChronicleDB.settings.chatNotifications then
        Print(string.format("Recorded completion: %s [%d]", questName, questID))
    end

    ScheduleQuestSync("QUEST_TURNED_IN", 0.25)
end

local function RecordNote(text)
    text = text and text:match("^%s*(.-)%s*$") or ""
    if text == "" then
        Print("Usage: /qc note <your roleplay note>")
        return
    end

    local event = AddEvent("RP_NOTE", {
        note = text,
    })

    if event then
        Print("Recorded RP note #" .. tostring(event.sequence) .. ".")
    end

    return event
end

local function CountEvents(character, eventType)
    local count = 0
    for _, event in ipairs(character.events or {}) do
        if not eventType or event.eventType == eventType then
            count = count + 1
        end
    end
    return count
end

local function CountActiveQuests(character)
    local count = 0
    for _ in pairs(character.activeQuests or {}) do
        count = count + 1
    end
    return count
end

local function PrintStatus()
    local character = currentCharacter or EnsureCharacter()
    local enabled = QuestChronicleDB.settings.enabled and "enabled" or "disabled"
    local chat = QuestChronicleDB.settings.chatNotifications and "on" or "off"
    local lifecycle = QuestChronicleDB.settings.lifecycleTracking and "on" or "off"
    local objectives = QuestChronicleDB.settings.objectiveTracking and "on" or "off"
    local removals = QuestChronicleDB.settings.removalTracking and "on" or "off"

    Print(string.format(
        "%s | %d events | %d active quests | %d accepted | %d completed | %d abandoned | recording %s",
        character.key,
        CountEvents(character),
        CountActiveQuests(character),
        CountEvents(character, "QUEST_ACCEPTED"),
        CountEvents(character, "QUEST_TURNED_IN"),
        CountEvents(character, "QUEST_ABANDONED"),
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

local QUEST_STATE_LABELS = {
    ACTIVE = "Active",
    READY_FOR_TURN_IN = "Ready for Turn-In",
    FAILED = "Failed",
    COMPLETE = "Complete",
    TURNED_IN = "Turned In",
    REMOVED = "Removed",
}

local function FriendlyQuestState(value)
    value = SafeText(value)
    if QUEST_STATE_LABELS[value] then
        return QUEST_STATE_LABELS[value]
    end
    if value == "" then
        return "Unknown"
    end
    value = value:gsub("_", " "):lower()
    return (value:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest
    end))
end

local function EventSummary(event)
    local questName = event.questName and event.questName ~= "" and event.questName
        or (event.questID and ("Quest " .. tostring(event.questID)) or "")

    if event.eventType == "QUEST_TURNED_IN" then
        return string.format("TURNED IN %s [%d]", questName, event.questID or 0)
    elseif event.eventType == "QUEST_ACCEPTED" then
        return string.format("ACCEPTED %s [%d]", questName, event.questID or 0)
    elseif event.eventType == "QUEST_ABANDONED" then
        return string.format("ABANDONED %s [%d]", questName, event.questID or 0)
    elseif event.eventType == "QUEST_REMOVED" then
        return string.format("REMOVED %s [%d] (%s)", questName, event.questID or 0, SafeText(event.removalReason))
    elseif event.eventType == "QUEST_BECAME_ACTIVE" then
        return string.format("ACTIVE %s [%d]", questName, event.questID or 0)
    elseif event.eventType == "QUEST_STATE_CHANGED" then
        return string.format("STATE %s: %s -> %s", questName, FriendlyQuestState(event.previousQuestState), FriendlyQuestState(event.questState))
    elseif event.eventType == "QUEST_OBJECTIVE_UPDATED" then
        return string.format(
            "OBJECTIVE %s #%d: %s",
            questName,
            event.objectiveIndex or 0,
            event.objectiveText ~= "" and SafeText(event.objectiveText) or SafeText(event.changeReason)
        )
    elseif event.eventType == "RP_NOTE" then
        return "NOTE " .. SafeText(event.note)
    end

    return SafeText(event.eventType)
end

local function PrintRecent(count)
    local character = currentCharacter or EnsureCharacter()
    count = tonumber(count) or 5
    count = math.max(1, math.min(count, 30))

    local events = character.events or {}
    if #events == 0 then
        Print("No events recorded yet.")
        return
    end

    Print("Most recent events:")
    local first = math.max(1, #events - count + 1)
    for index = first, #events do
        local event = events[index]
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "  |cffd9b36c#%d|r %s",
            event.sequence,
            EventSummary(event)
        ))
    end
end

local function PrintActive(count)
    local character = currentCharacter or EnsureCharacter()
    count = tonumber(count) or 25
    count = math.max(1, math.min(count, 50))

    local quests = {}
    for _, quest in pairs(character.activeQuests or {}) do
        table.insert(quests, quest)
    end
    table.sort(quests, function(left, right)
        return SafeText(left.questName) < SafeText(right.questName)
    end)

    Print(string.format("Active quests: %d", #quests))
    for index = 1, math.min(#quests, count) do
        local quest = quests[index]
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "  |cffd9b36c%s|r [%d] - %s - %d objectives",
            quest.questName ~= "" and quest.questName or ("Quest " .. tostring(quest.questID)),
            quest.questID,
            FriendlyQuestState(quest.questState),
            quest.objectiveCount or 0
        ))
    end
end

local function SetTrackingSetting(settingName, value, label)
    if value == "on" then
        QuestChronicleDB.settings[settingName] = true
        Print(label .. " enabled.")
    elseif value == "off" then
        QuestChronicleDB.settings[settingName] = false
        Print(label .. " disabled.")
    else
        Print("Usage: /qc " .. label:lower() .. " on|off")
    end
end

local function PrintHelp()
    Print("Commands:")
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
end

local function HandleSlashCommand(message)
    local command, rest = message:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    rest = rest or ""

    if command == "" or command == "show" or command == "window" then
        if QC.ToggleWindow then
            QC.ToggleWindow()
        else
            PrintHelp()
        end
    elseif command == "help" then
        PrintHelp()
    elseif command == "status" then
        PrintStatus()
    elseif command == "recent" then
        PrintRecent(rest)
    elseif command == "active" then
        PrintActive(rest)
    elseif command == "sync" then
        SyncQuestLog("MANUAL_SYNC", false)
        local export = RefreshCourierExport()
        Print("Quest log synchronized; courier snapshot is " .. tostring(#export) .. " bytes.")
    elseif command == "note" then
        RecordNote(rest)
    elseif command == "export" then
        SyncQuestLog("MANUAL_EXPORT", false)
        local export = RefreshCourierExport()
        Print("Courier snapshot refreshed (" .. tostring(#export) .. " bytes). Run /reload to write it to disk now.")
    elseif command == "on" then
        QuestChronicleDB.settings.enabled = true
        Print("Recording enabled.")
    elseif command == "off" then
        QuestChronicleDB.settings.enabled = false
        Print("Recording disabled.")
    elseif command == "chat" then
        local value = string.lower(rest)
        if value == "on" then
            QuestChronicleDB.settings.chatNotifications = true
            Print("Chat notices enabled.")
        elseif value == "off" then
            QuestChronicleDB.settings.chatNotifications = false
            Print("Chat notices disabled.")
        else
            Print("Usage: /qc chat on|off")
        end
    elseif command == "lifecycle" then
        SetTrackingSetting("lifecycleTracking", string.lower(rest), "Lifecycle")
    elseif command == "objectives" then
        SetTrackingSetting("objectiveTracking", string.lower(rest), "Objectives")
    elseif command == "removals" then
        SetTrackingSetting("removalTracking", string.lower(rest), "Removals")
    else
        PrintHelp()
    end
end

-- Public API used by the v0.4.1 UI modules. The recorder remains local so
-- future UI work cannot accidentally replace its event handlers.
function QC.GetDatabase()
    EnsureDatabase()
    return QuestChronicleDB
end

function QC.GetCurrentCharacter()
    return currentCharacter or EnsureCharacter()
end

function QC.GetSettings()
    EnsureDatabase()
    return QuestChronicleDB.settings
end

function QC.GetUIState()
    EnsureDatabase()
    return QuestChronicleDB.ui
end

function QC.SetSetting(settingName, value)
    EnsureDatabase()
    QuestChronicleDB.settings[settingName] = value
    if QC.Notify then
        QC.Notify("SETTINGS_CHANGED", settingName, value)
    end
end

function QC.GetEvents()
    local character = QC.GetCurrentCharacter()
    return character.events or {}
end

function QC.GetActiveQuests()
    local character = QC.GetCurrentCharacter()
    local quests = {}
    for _, quest in pairs(character.activeQuests or {}) do
        table.insert(quests, quest)
    end
    table.sort(quests, function(left, right)
        local leftName = SafeText(left.questName):lower()
        local rightName = SafeText(right.questName):lower()
        if leftName == rightName then
            return (left.questID or 0) < (right.questID or 0)
        end
        return leftName < rightName
    end)
    return quests
end

function QC.RecordNote(text)
    return RecordNote(text)
end

function QC.SynchronizeQuestLog(sourceEvent)
    SyncQuestLog(sourceEvent or "UI_MANUAL_SYNC", false)
    RefreshCourierExport()
    return CountActiveQuests(QC.GetCurrentCharacter())
end

function QC.RefreshCourierSnapshot(syncFirst)
    if syncFirst then
        SyncQuestLog("UI_MANUAL_EXPORT", false)
    end
    return RefreshCourierExport()
end

function QC.GetCourierSnapshotSize()
    return type(QuestChronicleCourierExport) == "string" and #QuestChronicleCourierExport or 0
end

function QC.GetStatus()
    local character = QC.GetCurrentCharacter()
    return {
        characterKey = character.key,
        eventCount = CountEvents(character),
        activeQuestCount = CountActiveQuests(character),
        acceptedCount = CountEvents(character, "QUEST_ACCEPTED"),
        completedCount = CountEvents(character, "QUEST_TURNED_IN"),
        abandonedCount = CountEvents(character, "QUEST_ABANDONED"),
        removedCount = CountEvents(character, "QUEST_REMOVED"),
        noteCount = CountEvents(character, "RP_NOTE"),
        objectiveUpdateCount = CountEvents(character, "QUEST_OBJECTIVE_UPDATED"),
        stateChangeCount = CountEvents(character, "QUEST_STATE_CHANGED"),
        lastEventAt = character.lastEventAt,
        lastEventAtText = character.lastEventAtText,
        lastQuestSyncAt = character.lastQuestSyncAt,
        lastQuestSyncAtText = character.lastQuestSyncAtText,
        courierSnapshotSize = QC.GetCourierSnapshotSize(),
    }
end

QC.GetLocation = GetLocation
QC.TimestampText = TimestampText
QC.EventSummary = EventSummary
QC.CountEvents = CountEvents
QC.CountActiveQuests = CountActiveQuests
QC.Print = Print

local function InstallAbandonHooks()
    if not hooksecurefunc or not C_QuestLog then
        return
    end

    if C_QuestLog.SetAbandonQuest and C_QuestLog.GetAbandonQuest then
        hooksecurefunc(C_QuestLog, "SetAbandonQuest", function()
            local ok, questID = pcall(C_QuestLog.GetAbandonQuest)
            if ok and questID then
                abandonCandidateQuestID = questID
            end
        end)
    end

    if C_QuestLog.AbandonQuest then
        hooksecurefunc(C_QuestLog, "AbandonQuest", function()
            local questID = abandonCandidateQuestID
            if C_QuestLog.GetAbandonQuest then
                local ok, currentQuestID = pcall(C_QuestLog.GetAbandonQuest)
                if ok and currentQuestID then
                    questID = currentQuestID
                end
            end

            if questID then
                confirmedAbandons[questID] = GetTime()
            end
        end)
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("QUEST_REMOVED")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_LOG_CRITERIA_UPDATE")
frame:RegisterEvent("QUEST_WATCH_UPDATE")
frame:RegisterEvent("TASK_PROGRESS_UPDATE")
frame:RegisterEvent("QUEST_DATA_LOAD_RESULT")

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= ADDON_NAME then
            return
        end

        EnsureDatabase()
        QuestChronicleCourierExport = QuestChronicleCourierExport or ""
        SLASH_QUESTCHRONICLE1 = "/questchronicle"
        SLASH_QUESTCHRONICLE2 = "/qc"
        SlashCmdList.QUESTCHRONICLE = HandleSlashCommand
        InstallAbandonHooks()

        if QC.RegisterSettings then
            QC.RegisterSettings()
        end

    elseif event == "PLAYER_LOGIN" then
        EnsureCharacter()
        StartSession()
        SyncQuestLog("PLAYER_LOGIN_BASELINE", true)
        RefreshCourierExport()
        if QC.InitializeUI then
            QC.InitializeUI()
        end
        if QC.Notify then
            QC.Notify("PLAYER_READY")
        end
        Print("v" .. ADDON_VERSION .. " loaded. Type /qc to open the Chronicle.")

    elseif event == "PLAYER_LOGOUT" then
        SyncQuestLog("PLAYER_LOGOUT", false)
        EndSession()
        RefreshCourierExport()

    elseif event == "QUEST_ACCEPTED" then
        local questID = ...
        RecordQuestAccepted(questID, "QUEST_ACCEPTED")

    elseif event == "QUEST_TURNED_IN" then
        local questID, xpReward, moneyReward = ...
        RecordQuestTurnIn(questID, xpReward, moneyReward)

    elseif event == "QUEST_REMOVED" then
        local questID = ...
        local character = currentCharacter or EnsureCharacter()
        local previous = character.activeQuests[tostring(questID)]
        if previous then
            QueueQuestRemoval(questID, previous, "QUEST_REMOVED")
        end
        ScheduleQuestSync("QUEST_REMOVED", 0.20)

    elseif event == "QUEST_LOG_UPDATE" then
        ScheduleQuestSync("QUEST_LOG_UPDATE", OBJECTIVE_SYNC_DELAY)

    elseif event == "QUEST_LOG_CRITERIA_UPDATE" then
        ScheduleQuestSync("QUEST_LOG_CRITERIA_UPDATE", 0.20)

    elseif event == "QUEST_WATCH_UPDATE" then
        ScheduleQuestSync("QUEST_WATCH_UPDATE", OBJECTIVE_SYNC_DELAY)

    elseif event == "TASK_PROGRESS_UPDATE" then
        ScheduleQuestSync("TASK_PROGRESS_UPDATE", 0.20)

    elseif event == "QUEST_DATA_LOAD_RESULT" then
        local questID, success = ...
        if success then
            UpdatePendingQuestTitles(questID)
            ScheduleQuestSync("QUEST_DATA_LOAD_RESULT", 0.10)
        end
    end
end)
