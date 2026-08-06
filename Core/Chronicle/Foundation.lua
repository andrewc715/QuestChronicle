QuestChronicle = QuestChronicle or {}
local QC = QuestChronicle
QC._Core = QC._Core or {}
local P = QC._Core
P.ADDON_NAME = ...

P.frame = CreateFrame("Frame")
P.currentCharacter = nil
P.currentSession = nil
P.pendingQuestTitles = {}
P.pendingQuestRemovals = {}
P.recentTurnIns = {}
P.recentAcceptances = {}
P.confirmedAbandons = {}
P.abandonCandidateQuestID = nil
P.questSyncToken = 0

P.SCHEMA_VERSION = 2
P.COURIER_FORMAT_VERSION = 1
P.ADDON_VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(P.ADDON_NAME, "Version")) or "1.11.6"
P.PREFIX = "|cffd9b36cQuest Chronicle:|r "
P.OBJECTIVE_SYNC_DELAY = 0.35
P.REMOVAL_CLASSIFY_DELAY = 0.45
P.RECENT_EVENT_WINDOW = 8

QC.addonName = P.ADDON_NAME
QC.version = P.ADDON_VERSION
QC.schemaVersion = P.SCHEMA_VERSION
QC.courierFormatVersion = P.COURIER_FORMAT_VERSION

function P.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(P.PREFIX .. tostring(message))
end

function P.SafeText(value)
    if value == nil then
        return ""
    end

    local ok, text = pcall(tostring, value)
    if ok then
        return text
    end

    return ""
end

function P.TimestampText(timestamp)
    return date("%Y-%m-%dT%H:%M:%S", timestamp)
end

function P.ShallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

function P.CloneObjectives(objectives)
    local copy = {}
    for index, objective in ipairs(objectives or {}) do
        copy[index] = P.ShallowCopy(objective)
    end
    return copy
end

function P.JsonEscape(value)
    local text = P.SafeText(value)
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

function P.JsonString(value)
    return '"' .. P.JsonEscape(value) .. '"'
end

function P.IsArray(value)
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

function P.JsonEncode(value, seen)
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
        return P.JsonString(value)
    elseif valueType ~= "table" then
        return P.JsonString(P.SafeText(value))
    end

    seen = seen or {}
    if seen[value] then
        return "null"
    end
    seen[value] = true

    local parts = {}
    if P.IsArray(value) then
        for index = 1, #value do
            parts[index] = P.JsonEncode(value[index], seen)
        end
        seen[value] = nil
        return "[" .. table.concat(parts, ",") .. "]"
    end

    local keys = {}
    for key in pairs(value) do
        table.insert(keys, P.SafeText(key))
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
        table.insert(parts, P.JsonString(key) .. ":" .. P.JsonEncode(originalValue, seen))
    end

    seen[value] = nil
    return "{" .. table.concat(parts, ",") .. "}"
end

P.EVENT_EXPORT_FIELDS = {
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

P.SESSION_EXPORT_FIELDS = {
    "id", "startedAt", "startedAtText", "startLevel", "startZone",
    "startSubZone", "startMapID", "endedAt", "endedAtText", "endLevel",
    "endZone", "endSubZone", "endMapID",
}

P.CHARACTER_EXPORT_FIELDS = {
    "key", "name", "realm", "className", "classID", "raceName",
    "raceID", "faction", "createdAt", "createdAtText", "lastEventAt",
    "lastEventAtText", "lastQuestSyncAt", "lastQuestSyncAtText",
}

P.ACTIVE_QUEST_EXPORT_FIELDS = {
    "questID", "questName", "questState", "questLevel", "difficultyLevel",
    "isComplete", "isFailed", "isTask", "isWorldQuest", "isHidden",
    "isAutoComplete", "acceptedAt", "acceptedAtText", "firstSeenAt",
    "firstSeenAtText", "lastSeenAt", "lastSeenAtText", "updatedAt",
    "updatedAtText", "objectiveCount",
}

P.OBJECTIVE_EXPORT_FIELDS = {
    "index", "text", "type", "objectiveType", "finished",
    "numFulfilled", "numRequired",
}

function P.CopyKnownFields(source, fields)
    local result = {}
    for _, key in ipairs(fields) do
        if source and source[key] ~= nil then
            result[key] = source[key]
        end
    end
    return result
end

function P.ExportObjectives(objectives)
    local result = {}
    for index, objective in ipairs(objectives or {}) do
        result[index] = P.CopyKnownFields(objective, P.OBJECTIVE_EXPORT_FIELDS)
    end
    return result
end

function P.ExportEvent(event)
    local result = P.CopyKnownFields(event, P.EVENT_EXPORT_FIELDS)
    if event and event.objectives then
        result.objectives = P.ExportObjectives(event.objectives)
    end
    return result
end

function P.ExportActiveQuest(quest)
    local result = P.CopyKnownFields(quest, P.ACTIVE_QUEST_EXPORT_FIELDS)
    result.objectives = P.ExportObjectives(quest and quest.objectives)
    return result
end

function P.BuildCourierExport()
    local now = time()
    local export = {
        formatVersion = P.COURIER_FORMAT_VERSION,
        schemaVersion = P.SCHEMA_VERSION,
        addonVersion = P.ADDON_VERSION,
        generatedAt = now,
        generatedAtText = P.TimestampText(now),
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
            local characterExport = P.CopyKnownFields(character, P.CHARACTER_EXPORT_FIELDS)
            characterExport.events = {}
            characterExport.sessions = {}
            characterExport.activeQuests = {}

            for index, event in ipairs(character.events or {}) do
                characterExport.events[index] = P.ExportEvent(event)
            end

            for index, session in ipairs(character.sessions or {}) do
                characterExport.sessions[index] = P.CopyKnownFields(session, P.SESSION_EXPORT_FIELDS)
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
                table.insert(characterExport.activeQuests, P.ExportActiveQuest(quest))
            end

            characterExport.activeQuestCount = #characterExport.activeQuests
            table.insert(export.characters, characterExport)
        end
    end

    return P.JsonEncode(export)
end

function P.RefreshCourierExport()
    QuestChronicleCourierExport = P.BuildCourierExport()
    if QC.Notify then
        QC.Notify("COURIER_EXPORT_REFRESHED", #QuestChronicleCourierExport)
    end
    return QuestChronicleCourierExport
end

function P.GetCharacterIdentity()
    local name, realm = UnitFullName("player")
    name = name or UnitName("player") or "Unknown"
    realm = realm or GetRealmName() or "Unknown Realm"

    return name, realm, realm .. " - " .. name
end

function P.GetLocation()
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

function P.EnsureDatabase()
    QuestChronicleDB = QuestChronicleDB or {}
    QuestChronicleDB.schemaVersion = P.SCHEMA_VERSION
    QuestChronicleDB.addonVersion = P.ADDON_VERSION
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
    QuestChronicleDB.settings.autoRefreshWardrobe = nil
    QuestChronicleDB.settings.recoverMissingAppearances = QuestChronicleDB.settings.recoverMissingAppearances ~= false
    QuestChronicleDB.settings.announceWardrobeUpdates = QuestChronicleDB.settings.announceWardrobeUpdates ~= false
    QuestChronicleDB.settings.highContrastOutfitStates = QuestChronicleDB.settings.highContrastOutfitStates == true
    QuestChronicleDB.settings.showMinimapButton = QuestChronicleDB.settings.showMinimapButton ~= false
    QuestChronicleDB.characters = QuestChronicleDB.characters or {}
    QuestChronicleDB.ui = QuestChronicleDB.ui or {}
    QuestChronicleDB.ui.lastTab = QuestChronicleDB.ui.lastTab or "chronicle"
    QuestChronicleDB.ui.noteDrafts = QuestChronicleDB.ui.noteDrafts or {}
    QuestChronicleDB.ui.chronicleFilter = QuestChronicleDB.ui.chronicleFilter or "ALL"
    QuestChronicleDB.ui.chronicleNewestFirst = QuestChronicleDB.ui.chronicleNewestFirst ~= false
    QuestChronicleDB.ui.chronicleSearch = QuestChronicleDB.ui.chronicleSearch or ""
    QuestChronicleDB.ui.activeQuestFilter = QuestChronicleDB.ui.activeQuestFilter or "ALL"
    QuestChronicleDB.ui.activeQuestSort = QuestChronicleDB.ui.activeQuestSort or "READY"
    QuestChronicleDB.ui.debugRawIDs = QuestChronicleDB.ui.debugRawIDs == true
    QuestChronicleDB.ui.debugVerbose = QuestChronicleDB.ui.debugVerbose == true
    QuestChronicleDB.ui.window = QuestChronicleDB.ui.window or {}
end

function P.EnsureCharacter()
    P.EnsureDatabase()

    local name, realm, key = P.GetCharacterIdentity()
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
            createdAtText = P.TimestampText(now),
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

    P.currentCharacter = character
    return character
end

function P.StartSession()
    local character = P.EnsureCharacter()
    local now = time()
    local location = P.GetLocation()

    P.currentSession = {
        id = string.format("%s:%d:%d", character.key, now, #character.sessions + 1),
        startedAt = now,
        startedAtText = P.TimestampText(now),
        startLevel = UnitLevel("player") or 0,
        startZone = location.zone,
        startSubZone = location.subZone,
        startMapID = location.mapID,
    }

    table.insert(character.sessions, P.currentSession)
end

function P.EndSession()
    if not P.currentSession then
        return
    end

    local now = time()
    local location = P.GetLocation()
    P.currentSession.endedAt = now
    P.currentSession.endedAtText = P.TimestampText(now)
    P.currentSession.endLevel = UnitLevel("player") or 0
    P.currentSession.endZone = location.zone
    P.currentSession.endSubZone = location.subZone
    P.currentSession.endMapID = location.mapID
end
