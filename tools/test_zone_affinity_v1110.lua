QuestChronicle = {
    ZoneStyle = { _Private = {} },
    GetSettings = function() return {} end,
}
local Z = QuestChronicle.ZoneStyle
local P = Z._Private
P.Normalize = function(value)
    local text = string.lower(tostring(value or "")):gsub("[’']", ""):gsub("[^%w]+", " ")
    return text:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
end
Z.Zone = {}
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_affinity_v1110.lua$", "")
local function Load(path) assert(loadfile(root .. path))() end
Load("Core/ZoneStyle/Zone/Foundation.lua")
Load("Core/ZoneStyle/Zone/CanonicalStyles.lua")
Z.GetTravelerDescriptor = function(source)
    return {
        fingerprint = "D-" .. tostring(source.sourceID), text = P.Normalize(source.text),
        palette = source.palette or {}, material = source.material or {}, finish = source.finish or {}, motifs = source.motifs or {},
        confidence = { palette = 0.9, material = 0.9, finish = 0.9, motifs = 0.8, provenance = 0.8 },
    }
end
Z.GetSourceExpansionID = function(source) return source.expansionID end
P.GetCuratedSourceOrigin = function(source) return source.origin end
P.GetTrackedSourceOrigin = function() return nil end
Load("Core/ZoneStyle/Zone/Affinity.lua")

local snapshot = {
    identity = { profileKey = "outland", confidence = 0.9 },
    provenance = { key = "netherstorm" },
    style = {
        palette = { purple = 0.8, green = 0.7, steel = 0.6 },
        material = { crystal = 0.9, plate = 0.6 },
        finish = { weathered = 0.9, magical = 0.8 },
        motif = { outland = 1.0, fel = 0.7, frontier = 0.7 },
        culture = { draenei = 0.9, ethereal = 0.8 }, magic = { nether = 1.0, fel = 0.8 }, avoids = {},
    },
}
local native = {
    sourceID = 1, visualID = 101, text = "Nether crystal draenei outland weathered",
    palette = { purple = 0.7, steel = 0.3 }, material = { crystal = 1.0 }, finish = { weathered = 1.0 }, motifs = { outland = 1.0 },
    origin = { provenanceKey = "netherstorm", label = "Netherstorm" }, expansionID = 1,
}
local foreign = {
    sourceID = 2, visualID = 102, text = "Stormwind lion polished royal plate",
    palette = { blue = 0.7, gold = 0.3 }, material = { plate = 1.0 }, finish = { polished = 1.0 }, motifs = { alliance = 1.0 },
    origin = { provenanceKey = "stormwind", label = "Stormwind" }, expansionID = 0,
}
local randomCalls = 0
local originalRandom = math.random
math.random = function(...) randomCalls = randomCalls + 1 return originalRandom(...) end
local a = Z.Zone.GetZoneAffinity(native, { key = "CHEST" }, snapshot)
local b = Z.Zone.GetZoneAffinity(foreign, { key = "CHEST" }, snapshot)
math.random = originalRandom
assert(randomCalls == 0, "Zone affinity consumed random values")
assert(a.score > b.score, "native evidence did not outrank foreign evidence")
assert(a.components.provenance == 1 and b.components.provenance == 0, "provenance affinity mismatch")
assert(a.classification ~= "UNKNOWN" and a.confidence > 0, "native classification missing")
local partial = Z.Zone.GetZoneAffinity({ sourceID = 3, text = "unknown", palette = {}, material = {}, finish = {}, motifs = {} }, nil, snapshot)
assert(#partial.missingChannels > 0, "missing channels were not preserved")
print(string.format("PASS v1.11.0 Zone affinity: native %.3f > foreign %.3f, deterministic and selection-neutral", a.score, b.score))
