local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
ZoneStyle.Zone = ZoneStyle.Zone or {}
local Zone = ZoneStyle.Zone
local P = ZoneStyle._Private

Zone.CONTEXT_FORMAT = 1
Zone.PROFILE_REGISTRY_VERSION = 1
Zone.PROVENANCE_REGISTRY_VERSION = 1
Zone.STARTING_ZONE_REGISTRY_VERSION = 1
Zone.ERA_RULE_VERSION = 1
Zone.AFFINITY_FORMAT = 1
Zone.FOUNDATION_ID = "CONTEXT_EVIDENCE_V1"

Zone.RESOLUTION_CONFIDENCE = {
    EXACT_MAP = 1.00,
    EXACT_SUBZONE = 0.95,
    EXACT_ZONE = 0.90,
    EXACT_MAP_NAME = 0.90,
    MAP_TRAIL = 0.80,
    PARENT_PROFILE = 0.70,
    REGION_FALLBACK = 0.55,
    AZEROTH_FALLBACK = 0.25,
    UNRESOLVED = 0.00,
}

local function Copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do result[Copy(key, seen)] = Copy(child, seen) end
    return result
end

local function PrimitiveCopy(value, seen)
    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then return value end
    if valueType ~= "table" then return nil end
    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true
    local result = {}
    for key, child in pairs(value) do
        local keyType = type(key)
        if keyType == "string" or keyType == "number" then
            local copied = PrimitiveCopy(child, seen)
            if copied ~= nil then result[key] = copied end
        end
    end
    seen[value] = nil
    return result
end

local function SortedKeys(values)
    local keys = {}
    for key in pairs(values or {}) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

local function StableEncode(value)
    local valueType = type(value)
    if valueType == "nil" then return "nil" end
    if valueType == "boolean" or valueType == "number" then return tostring(value) end
    if valueType == "string" then return string.format("%q", value) end
    if valueType ~= "table" then return "<" .. valueType .. ">" end
    local parts = { "{" }
    for _, key in ipairs(SortedKeys(value)) do
        parts[#parts + 1] = StableEncode(key) .. "=" .. StableEncode(value[key]) .. ";"
    end
    parts[#parts + 1] = "}"
    return table.concat(parts)
end

function Zone.Copy(value) return Copy(value) end
function Zone.CopyPrimitive(value) return PrimitiveCopy(value) end
function Zone.StableEncode(value) return StableEncode(value) end

function Zone.Fingerprint(value)
    local text = StableEncode(value)
    local hash = 2166136261
    for index = 1, #text do
        hash = (hash * 16777619 + text:byte(index)) % 4294967296
    end
    return string.format("ZCTX-%08x", hash)
end

function Zone.NormalizeWeights(values)
    local result, total = {}, 0
    for key, value in pairs(type(values) == "table" and values or {}) do
        value = tonumber(value) or 0
        if type(key) == "string" and key ~= "" and value > 0 then result[key] = value
            total = total + value end
    end
    if total > 0 then for key, value in pairs(result) do result[key] = value / total end end
    return result
end

function Zone.ValidateKey(key, label)
    if type(key) ~= "string" or key == "" or not key:match("^[%w_]+$") then
        return false, tostring(label or "Registry") .. " has an invalid key: " .. tostring(key)
    end
    return true
end

function Zone.ValidateAliasList(values, label)
    if type(values) ~= "table" then return false, tostring(label) .. " aliases must be a table." end
    for index, value in ipairs(values) do
        if type(value) ~= "string" or P.Normalize(value) == "" then
            return false, string.format("%s alias %d is empty or invalid.", tostring(label), index)
        end
    end
    return true
end

function Zone.GetFoundationStatus()
    return {
        foundation = Zone.FOUNDATION_ID,
        contextFormat = Zone.CONTEXT_FORMAT,
        profileRegistryVersion = Zone.PROFILE_REGISTRY_VERSION,
        provenanceRegistryVersion = Zone.PROVENANCE_REGISTRY_VERSION,
        startingZoneRegistryVersion = Zone.STARTING_ZONE_REGISTRY_VERSION,
        eraRuleVersion = Zone.ERA_RULE_VERSION,
        affinityFormat = Zone.AFFINITY_FORMAT,
    }
end

function ZoneStyle.GetZoneFoundationStatus()
    return Zone.CopyPrimitive(Zone.GetFoundationStatus())
end
