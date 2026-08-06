QuestChronicle = {
    ZoneStyle = { Zone = {}, _Private = {} },
    Wardrobe = {},
}
local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone
local P = ZoneStyle._Private
P.Normalize = function(value)
    return tostring(value or ""):lower():gsub("[^%w]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end
P.GetCuratedSourceOrigin = function() return nil end
P.GetTrackedSourceOrigin = function() return nil end
Zone.AFFINITY_FORMAT = 2
Zone.AFFINITY_COMPONENT_STATUS = { VALUE = "VALUE", MISSING = "MISSING", NOT_APPLICABLE = "NOT_APPLICABLE" }
local function Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, child in pairs(value) do out[key] = Copy(child) end
    return out
end
Zone.CopyPrimitive = Copy

local descriptor = {
    fingerprint = "fixture|descriptor",
    text = "plain steel plate",
    palette = { steel = 1 }, material = { plate = 1 }, finish = nil,
    motifs = { frontier = 1 },
    confidence = { palette = 0.7, material = 0.7, motifs = 0.5, provenance = 0.5 },
}
ZoneStyle.GetTravelerDescriptor = function() return descriptor end
ZoneStyle.GetSourceExpansionID = function() return 1 end

local snapshot = {
    identity = { profileKey = "outland", confidence = 0.9 },
    provenance = { key = "netherstorm" },
    style = {
        coverage = {
            palette = "KNOWN", material = "KNOWN", finish = "KNOWN", motif = "KNOWN",
            culture = "KNOWN", magic = "KNOWN", avoids = "NOT_APPLICABLE",
        },
        palette = { steel = 0.6 }, material = { plate = 0.6 }, finish = { weathered = 1 },
        motif = { frontier = 0 }, culture = { ethereal = 1 }, magic = { nether = 1 }, avoids = {},
    },
}
local source = { sourceID = 10, visualID = 20, slotKey = "CHEST", expansionID = 1 }
local definition = { key = "CHEST" }

local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_affinity_applicability_v1112.lua$", "")
assert(loadfile(root .. "Core/ZoneStyle/Zone/Affinity.lua"))()

local result = Zone.GetZoneAffinity(source, definition, snapshot)
local expectedScore = (0.6 * 0.24 + 0.6 * 0.18 + 0 * 0.14 + 0 * 0.08 + 0 * 0.08) / (0.24 + 0.18 + 0.14 + 0.08 + 0.08)
local expectedDescriptorConfidence = (0.7 * 0.24 + 0.7 * 0.18 + 0.5 * 0.14 + 0.5 * 0.08 + 0.5 * 0.08) / (0.24 + 0.18 + 0.14 + 0.08 + 0.08)
local expectedConfidence = expectedDescriptorConfidence * 0.9
assert(math.abs(result.score - expectedScore) < 1e-12, "N/A status changed the v1 affinity score")
assert(math.abs(result.confidence - expectedConfidence) < 1e-12, "N/A status changed the v1 affinity confidence")
assert(result.componentStatus.avoids == "NOT_APPLICABLE", "avoids was not marked NOT_APPLICABLE")
assert(result.components.avoids == nil, "N/A avoids produced a numeric component")
assert(#result.notApplicableChannels == 1 and result.notApplicableChannels[1] == "avoids", "N/A list is incorrect")
for _, key in ipairs(result.missingChannels) do assert(key ~= "avoids", "N/A avoids leaked into missingChannels") end

local known = Copy(snapshot)
known.style.coverage.avoids = "KNOWN"
known.style.avoids = { fel = 0.8 }
local noConflict = Zone.GetZoneAffinity(source, definition, known)
assert(noConflict.componentStatus.avoids == "VALUE" and noConflict.components.avoids == 1, "known no-conflict avoidance is not VALUE=1")
descriptor.text = "fel steel plate"
local conflict = Zone.GetZoneAffinity(source, definition, known)
assert(math.abs(conflict.components.avoids - 0.2) < 1e-12, "known avoidance conflict changed its v1 value")
descriptor.text = "plain steel plate"
local unknown = Copy(snapshot)
unknown.style.coverage.avoids = "UNKNOWN"
local missing = Zone.GetZoneAffinity(source, definition, unknown)
assert(missing.componentStatus.avoids == "MISSING", "unknown avoids was not marked MISSING")

local legacy = {
    format = 1, components = { palette = 0.6 }, missingChannels = { "avoids", "provenance" },
    score = 0.6, confidence = 0.4, classification = "WEAK_LOCAL_SIGNAL",
}
local normalized = Zone.NormalizeZoneAffinityPiece(legacy, snapshot)
assert(normalized.format == 2, "format-1 record was not normalized to affinity format 2")
assert(normalized.componentStatus.avoids == "NOT_APPLICABLE", "format-1 avoids did not normalize to N/A")
for _, key in ipairs(normalized.missingChannels) do assert(key ~= "avoids", "format-1 N/A avoids remained missing") end
assert(normalized.score == legacy.score and normalized.confidence == legacy.confidence, "format normalization changed numeric results")
print("PASS v1.11.2 Zone affinity: VALUE, MISSING, and NOT_APPLICABLE preserve v1 arithmetic")
