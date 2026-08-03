local QC = QuestChronicle
QC.Diagnostics = QC.Diagnostics or {}
local D = QC.Diagnostics
D._Private = D._Private or {}
local P = D._Private

D.FORMAT_VERSION = 1
D.MAX_REPORTS = 10
D.MAX_REPORT_BYTES = 20480
D.MAX_HISTORY_BYTES = 204800

P.pendingReportToken = P.pendingReportToken or 0
P.rerollSlotWrapped = P.rerollSlotWrapped == true

function P.SafeString(value)
    if value == nil then return "" end
    local ok, text = pcall(tostring, value)
    return ok and text or ""
end

function P.SafeNumber(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return fallback or 0
    end
    return value
end

function P.CopyPrimitiveMap(source)
    local result = {}
    for key, value in pairs(type(source) == "table" and source or {}) do
        local valueType = type(value)
        if valueType == "string" or valueType == "number" or valueType == "boolean" then
            result[key] = value
        end
    end
    return result
end

function P.DeepCopy(value, depth, seen)
    local valueType = type(value)
    if valueType ~= "table" then
        if valueType == "string" or valueType == "number" or valueType == "boolean" or value == nil then
            return value
        end
        return nil
    end
    depth = tonumber(depth) or 8
    if depth <= 0 then return nil end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local result = {}
    local count = 0
    for key, child in pairs(value) do
        count = count + 1
        if count > 512 then break end
        local keyType = type(key)
        if keyType == "string" or keyType == "number" then
            local copied = P.DeepCopy(child, depth - 1, seen)
            if copied ~= nil then result[key] = copied end
        end
    end
    seen[value] = nil
    return result
end

local function NewStore()
    return {
        formatVersion = D.FORMAT_VERSION,
        nextSequence = 1,
        reports = {},
        counters = { reportsRecorded = 0, duplicateInsertionsIgnored = 0, malformedReportsDiscarded = 0 },
    }
end

function P.EnsureStore()
    QuestChronicleDB = QuestChronicleDB or {}
    local store = QuestChronicleDB.debug
    if type(store) ~= "table" or tonumber(store.formatVersion) ~= D.FORMAT_VERSION then
        store = NewStore()
        QuestChronicleDB.debug = store
    end
    store.reports = type(store.reports) == "table" and store.reports or {}
    store.nextSequence = math.max(1, math.floor(tonumber(store.nextSequence) or 1))
    store.counters = type(store.counters) == "table" and store.counters or {}
    store.counters.reportsRecorded = math.max(0, math.floor(tonumber(store.counters.reportsRecorded) or 0))
    store.counters.duplicateInsertionsIgnored = math.max(0, math.floor(tonumber(store.counters.duplicateInsertionsIgnored) or 0))
    store.counters.malformedReportsDiscarded = math.max(0, math.floor(tonumber(store.counters.malformedReportsDiscarded) or 0))
    return store
end

function P.GetUIState()
    QuestChronicleDB = QuestChronicleDB or {}
    QuestChronicleDB.ui = QuestChronicleDB.ui or {}
    return QuestChronicleDB.ui
end

function P.NowMilliseconds()
    if QC.Wardrobe and QC.Wardrobe._Private and QC.Wardrobe._Private.GenerationNowMilliseconds then
        return QC.Wardrobe._Private.GenerationNowMilliseconds()
    end
    if type(debugprofilestop) == "function" then return debugprofilestop() end
    if type(GetTimePreciseSec) == "function" then return GetTimePreciseSec() * 1000 end
    if type(GetTime) == "function" then return GetTime() * 1000 end
    return 0
end

function P.Notify(eventName, ...)
    if QC.Notify then QC.Notify(eventName, ...) end
end
