QuestChronicle = {
    ZoneStyle = { _Private = {}, MODE_TRAVELER = "TRAVELER" },
    _Core = { Print = function() end },
}
local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private

function P.Normalize(value)
    return string.lower(tostring(value or "")):gsub("[^%w]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end
function P.SourceMetadata(source)
    return P.Normalize(table.concat({ source.name or "", source.styleItemSubType or "" }, " "))
end
function P.GetSourceStyleSignals() return { families = {}, intensity = 0 } end
function P.GetSourceSetIDs(source) return source.setIDs or {} end
function ZoneStyle.GetSourceExpansionID(source) return source.expansionID end
function ZoneStyle.GetCurrentContext() return { profileKey = "outland", profileLabel = "Outland" } end
function ZoneStyle.NormalizeMode(mode) return mode end
function ZoneStyle.ScoreSource(source) return source.mockTravelerScore or 20, {} end
function time() return 123 end

assert(loadfile("Core/ZoneStyle/Traveler/StyleLexicon.lua"))()
assert(loadfile("Core/ZoneStyle/Traveler/Descriptors.lua"))()
assert(loadfile("Core/ZoneStyle/Traveler/Cohesion.lua"))()
local T = ZoneStyle.Traveler

local weightTotal = 0
for _, value in pairs(T.CONFIG.pairWeights) do weightTotal = weightTotal + value end
assert(math.abs(weightTotal - 1) < 0.0001, "pair weights must total 1.0")

local chest = T.GetDescriptor({ sourceID = 1, name = "Battleworn Steel Breastplate", styleItemSubType = "Plate", expansionID = 1 }, { key = "CHEST" })
local legs = T.GetDescriptor({ sourceID = 2, name = "Weathered Iron Legplates", styleItemSubType = "Plate", expansionID = 1 }, { key = "LEGS" })
local unknown = T.GetDescriptor({ sourceID = 3, name = "Appearance 3", expansionID = 1 }, { key = "WRIST" })
local pairScore = T.GetPairCohesion(chest, legs)
local neutralScore = T.GetPairCohesion(chest, unknown)
assert(pairScore > neutralScore, "matching weathered plate should beat unknown metadata")
assert(neutralScore > 0.35 and neutralScore < 0.75, "unknown metadata should remain neutral")

local loudDescriptor = {
    palette = { purple = 1 }, material = { cloth = 1 }, finish = { ornate = 1 }, motifs = { royal = 1 },
    confidence = { palette = 1, material = 1, finish = 1, motifs = 1, visualWeight = 1 },
    visualWeight = 1, loudness = 0.95, dominantPalette = "purple", setIDs = {}, expansionID = 4,
}
local belt = T.GetDescriptor({ sourceID = 7, name = "Weathered Brown Leather Belt", styleItemSubType = "Leather", expansionID = 1 }, { key = "WAIST" })
local entries = {
    { slotKey = "CHEST", slotLabel = "Chest", descriptor = chest, source = chest.source, travelerScore = 24 },
    { slotKey = "LEGS", slotLabel = "Legs", descriptor = legs, source = legs.source, travelerScore = 22 },
    { slotKey = "SHOULDER", slotLabel = "Shoulders", descriptor = T.GetDescriptor({ sourceID = 5, name = "Rugged Steel Pauldrons", styleItemSubType = "Plate", expansionID = 1 }, { key = "SHOULDER" }), source = {}, travelerScore = 23 },
    { slotKey = "ONE_HAND", slotLabel = "One-Hand", descriptor = T.GetDescriptor({ sourceID = 6, name = "Battleworn Iron Sword", styleItemSubType = "Sword", expansionID = 1 }, { key = "ONE_HAND", weaponRole = "ONE_HAND" }), source = {}, travelerScore = 21 },
    { slotKey = "HEAD", slotLabel = "Head", descriptor = loudDescriptor, source = { sourceID = 9, name = "Impossible Violet Crown" }, travelerScore = 10 },
    { slotKey = "WAIST", slotLabel = "Waist", descriptor = belt, source = belt.source, travelerScore = 23 },
}
local analysis = T.AnalyzeEntries(entries, {})
local bySlot = {}
for _, entry in ipairs(analysis.entries) do bySlot[entry.slotKey] = entry end
assert(bySlot.HEAD.mismatchClass == "POSTAL", "isolated loud accent should be postal")
assert(bySlot.WAIST.mismatchClass == "MILD" or bySlot.WAIST.mismatchClass == "COHESIVE", "weathered belt should retain a bridge")
assert(#analysis.entries == 6 and entries[1].source == chest.source, "analysis must not replace selections")

QC.Wardrobe = {
    slotDefinitions = {
        { key = "CHEST", label = "Chest" }, { key = "LEGS", label = "Legs" },
        { key = "SHOULDER", label = "Shoulders" }, { key = "ONE_HAND", label = "One-Hand", weaponRole = "ONE_HAND" },
    },
    GetPreviewState = function() return { styleMode = "TRAVELER", generatedName = "Harness Outfit", selections = {}, hidden = {}, locks = {} } end,
}
local mockSources = { CHEST = chest.source, LEGS = legs.source, SHOULDER = entries[3].descriptor.source, ONE_HAND = entries[4].descriptor.source }
QC.Wardrobe.GetSelectedSource = function(slotKey) return mockSources[slotKey] end
assert(loadfile("Core/ZoneStyle/Traveler/Debug.lua"))()
local current = ZoneStyle.GetTravelerCurrentAnalysis()
assert(current and #current.entries == 4, "debug analyzer should inspect current wardrobe state")

print(string.format("PASS Traveler instrumentation: pair %.3f neutral %.3f postal %s belt %s", pairScore, neutralScore, bySlot.HEAD.mismatchClass, bySlot.WAIST.mismatchClass))
