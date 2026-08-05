local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local T = ZoneStyle.Traveler

T.CURATED_TUNING_VERSION = 1
T.CURATED_CONFIDENCE = 0.95

-- Phase E corrections are exact visual-identity facts confirmed from standardized
-- TransmogDB model renders and in-game close inspection. They replace descriptor
-- fields only; they never exempt an appearance from scoring or Phase D repair.
T.CURATED_DESCRIPTOR_OVERRIDES = {
    visual = {
        [912] = {
            reviewedSourceIDs = { 888 },
            finish = { plain = 1.00 },
            label = "Gray Woolen Shirt reviewed plain-cloth finish",
        },
        [1208] = {
            reviewedSourceIDs = { 1254 },
            finish = { plain = 1.00 },
            label = "Stylish Black Shirt reviewed plain-cloth finish",
        },
        [1051] = {
            reviewedSourceIDs = { 1057 },
            palette = { dark = 0.45, neutral = 0.35, purple = 0.20 },
            finish = { primal = 0.75, weathered = 0.25 },
            label = "Hide of Lupos reviewed dark violet-gray fur",
        },
        [1139] = {
            reviewedSourceIDs = { 1159 },
            palette = { blue = 0.45, steel = 0.35, dark = 0.20 },
            finish = { weathered = 0.60, plain = 0.40 },
            label = "Rugged Plate Vest reviewed blue-steel rugged finish",
        },
        [5237] = {
            reviewedSourceIDs = { 14444 },
            palette = { green = 0.70, steel = 0.30 },
            finish = { military = 0.80, polished = 0.20 },
            label = "Expedition Defender's Shoulders reviewed green military finish",
        },
        [12877] = {
            reviewedSourceIDs = { 25917 },
            palette = { dark = 0.70, blue = 0.20, steel = 0.10 },
            finish = { plain = 0.75, polished = 0.25 },
            label = "Orcish Scout Boots reviewed dark navy finish",
        },
    },
    item = {},
    source = {},
}

local function CopyMap(values)
    local copy = {}
    for key, value in pairs(values or {}) do copy[key] = value end
    return copy
end

local function AddUnique(values, value)
    if not value or value == "" then return end
    for _, existing in ipairs(values) do if existing == value then return end end
    values[#values + 1] = value
end

local function ValidFamily(field, family)
    if field == "palette" then return T.LEXICON and T.LEXICON.palette and T.LEXICON.palette[family] ~= nil end
    if field == "finish" then return T.LEXICON and T.LEXICON.finish and T.LEXICON.finish[family] ~= nil end
    return false
end

local function NormalizeCuratedMap(field, values)
    if type(values) ~= "table" then return nil end
    local result, total = {}, 0
    for family, rawValue in pairs(values) do
        local value = tonumber(rawValue) or 0
        if ValidFamily(field, family) and value > 0 then
            result[family] = value
            total = total + value
        end
    end
    if total <= 0 then return nil end
    for family, value in pairs(result) do result[family] = value / total end
    return result
end

local function LayerFor(kind, identity)
    identity = tonumber(identity)
    if not identity or identity <= 0 then return nil end
    local group = T.CURATED_DESCRIPTOR_OVERRIDES and T.CURATED_DESCRIPTOR_OVERRIDES[kind]
    return group and group[identity] or nil
end

local function ApplyLayer(resolved, layer, kind, identity)
    if type(layer) ~= "table" then return end
    for _, field in ipairs({ "palette", "finish", "echoAdd" }) do
        if layer[field] ~= nil then resolved[field] = CopyMap(layer[field]) end
    end
    if layer.label then resolved.label = layer.label end
    resolved.keyType = kind
    resolved.key = tonumber(identity)
    resolved.matched[#resolved.matched + 1] = { keyType = kind, key = tonumber(identity), label = layer.label }
end

function T.ResolveCuratedDescriptorOverride(source)
    if type(source) ~= "table" then return nil end
    local resolved = { matched = {} }
    -- Broad appearance truth first, then increasingly specific refinements.
    ApplyLayer(resolved, LayerFor("visual", source.visualID), "visualID", source.visualID)
    ApplyLayer(resolved, LayerFor("item", source.itemID), "itemID", source.itemID)
    ApplyLayer(resolved, LayerFor("source", source.sourceID), "sourceID", source.sourceID)
    if #resolved.matched == 0 then return nil end
    resolved.palette = NormalizeCuratedMap("palette", resolved.palette)
    resolved.finish = NormalizeCuratedMap("finish", resolved.finish)
    resolved.echoAdd = NormalizeCuratedMap("palette", resolved.echoAdd)
    return resolved
end

function T.GetCuratedDescriptorMetadata(source)
    local resolved = T.ResolveCuratedDescriptorOverride(source)
    if not resolved then return nil end
    local fields = {}
    if resolved.palette then fields[#fields + 1] = "palette" end
    if resolved.finish then fields[#fields + 1] = "finish" end
    if resolved.echoAdd then fields[#fields + 1] = "echo" end
    return {
        fields = fields,
        keyType = resolved.keyType,
        key = resolved.key,
        label = resolved.label,
        version = T.CURATED_TUNING_VERSION,
    }
end

function T.ApplyCuratedDescriptorOverride(descriptor)
    local resolved = descriptor and T.ResolveCuratedDescriptorOverride(descriptor.source)
    if not resolved then return nil end
    descriptor.curatedFields = {}
    descriptor.curatedKeyType = resolved.keyType
    descriptor.curatedKey = resolved.key
    descriptor.curatedLabel = resolved.label
    descriptor.curatedTuningVersion = T.CURATED_TUNING_VERSION
    descriptor.curatedEchoAdd = resolved.echoAdd and CopyMap(resolved.echoAdd) or nil
    if resolved.palette then
        descriptor.palette = CopyMap(resolved.palette)
        descriptor.curatedFields.palette = true
    end
    if resolved.finish then
        descriptor.finish = CopyMap(resolved.finish)
        descriptor.curatedFields.finish = true
    end
    if resolved.echoAdd then descriptor.curatedFields.echo = true end
    descriptor.evidence = descriptor.evidence or {}
    AddUnique(descriptor.evidence, "curated Traveler override")
    return resolved
end

function T.BuildTravelerEchoPalette(descriptor)
    local echo = CopyMap(descriptor and descriptor.palette)
    for family, value in pairs(descriptor and descriptor.curatedEchoAdd or {}) do
        echo[family] = (echo[family] or 0) + value
    end
    local total = 0
    for _, value in pairs(echo) do total = total + math.max(0, tonumber(value) or 0) end
    if total > 0 then for family, value in pairs(echo) do echo[family] = math.max(0, value) / total end end
    return echo
end

function T.GetCuratedFieldsLabel(value)
    local fields = value and value.curatedFields or value and value.fields
    if type(fields) ~= "table" then return nil end
    local parts = {}
    if fields.palette == true then parts[#parts + 1] = "palette" end
    if fields.finish == true then parts[#parts + 1] = "finish" end
    if fields.echo == true then parts[#parts + 1] = "echo" end
    if #parts == 0 then
        for _, field in ipairs(fields) do parts[#parts + 1] = tostring(field) end
    end
    return #parts > 0 and table.concat(parts, ", ") or nil
end
