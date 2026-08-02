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
assert(T.INSTRUMENTATION_VERSION == 2, "calibrated instrumentation version should be 2")

local function Descriptor(id, name, subtype, slotKey, score, expansionID)
    local source = {
        sourceID = id,
        name = name,
        styleItemSubType = subtype,
        expansionID = expansionID or 1,
        mockTravelerScore = score or 20,
    }
    return source, T.GetDescriptor(source, { key = slotKey, weaponRole = slotKey == "ONE_HAND" and "ONE_HAND" or nil })
end

local chestSource, chest = Descriptor(1, "Battleworn Steel Breastplate", "Plate", "CHEST", 24)
local legsSource, legs = Descriptor(2, "Weathered Iron Legplates", "Plate", "LEGS", 22)
local shoulderSource, shoulders = Descriptor(5, "Rugged Steel Pauldrons", "Plate", "SHOULDER", 23)
local swordSource, sword = Descriptor(6, "Battleworn Iron Sword", "Sword", "ONE_HAND", 21)
local unknownSource, unknown = Descriptor(3, "Appearance 3", nil, "WRIST", 15)
local pairScore = T.GetPairCohesion(chest, legs)
local neutralScore = T.GetPairCohesion(chest, unknown)
assert(pairScore > neutralScore, "matching weathered plate should beat unknown metadata")
assert(neutralScore > 0.35 and neutralScore < 0.75, "unknown metadata should remain neutral")

local loudDescriptor = {
    palette = { purple = 1 }, material = { cloth = 1 }, finish = { ornate = 1 }, motifs = { royal = 1 },
    confidence = { palette = 1, material = 1, finish = 1, motifs = 1, visualWeight = 1 },
    visualWeight = 1, loudness = 0.95, dominantPalette = "purple", setIDs = {}, expansionID = 4,
}
local beltSource, belt = Descriptor(7, "Weathered Brown Leather Belt", "Leather", "WAIST", 23)
local entries = {
    { slotKey = "CHEST", slotLabel = "Chest", descriptor = chest, source = chestSource, travelerScore = 24 },
    { slotKey = "LEGS", slotLabel = "Legs", descriptor = legs, source = legsSource, travelerScore = 22 },
    { slotKey = "SHOULDER", slotLabel = "Shoulders", descriptor = shoulders, source = shoulderSource, travelerScore = 23 },
    { slotKey = "ONE_HAND", slotLabel = "Main Hand", descriptor = sword, source = swordSource, travelerScore = 21, linkedHands = true },
    { slotKey = "OFF_HAND", slotLabel = "Off Hand", descriptor = sword, source = swordSource, travelerScore = 21, linkedHands = true },
    { slotKey = "HEAD", slotLabel = "Head", descriptor = loudDescriptor, source = { sourceID = 9, name = "Impossible Violet Crown" }, travelerScore = 10 },
    { slotKey = "WAIST", slotLabel = "Waist", descriptor = belt, source = beltSource, travelerScore = 23 },
}
local analysis = T.AnalyzeEntries(entries, {})
local bySlot = {}
for _, entry in ipairs(analysis.entries) do bySlot[entry.slotKey] = entry end
assert(bySlot.HEAD.mismatchClass == "POSTAL", "isolated loud accent should remain postal")
assert(bySlot.WAIST.mismatchClass == "MILD" or bySlot.WAIST.mismatchClass == "SUPPORTED VARIATION", "weathered belt should retain a bridge")
assert(analysis.selectedAppearanceCount == 7, "all physical selections must remain counted")
assert(analysis.analysisBlockCount == 6, "linked matching weapons should collapse into one analysis block")
assert(bySlot.ONE_HAND and bySlot.ONE_HAND.isWeaponBlock and bySlot.ONE_HAND.memberCount == 2, "linked weapons should form a weapon block")
assert(not bySlot.OFF_HAND, "linked off-hand should not be charged as a second block")
assert(bySlot.ONE_HAND.mismatchPoints <= 0.90, "linked weapon pair must not be charged twice")

local echoedHandsDescriptor = {
    palette = { gold = 1 }, material = { plate = 1 }, finish = { military = 1 }, motifs = { crusader = 1 },
    confidence = { palette = 1, material = 1, finish = 1, motifs = 1, visualWeight = 1 },
    visualWeight = 2.5, loudness = 0.34, dominantPalette = "gold", setIDs = {}, expansionID = 1,
}
local echoedEntries = {
    { slotKey = "CHEST", slotLabel = "Chest", descriptor = echoedHandsDescriptor, source = { sourceID = 20, name = "Golden Plate Chest" }, travelerScore = 20 },
    { slotKey = "SHOULDER", slotLabel = "Shoulders", descriptor = echoedHandsDescriptor, source = { sourceID = 21, name = "Golden Plate Shoulders" }, travelerScore = 20 },
    { slotKey = "LEGS", slotLabel = "Legs", descriptor = echoedHandsDescriptor, source = { sourceID = 22, name = "Golden Plate Legs" }, travelerScore = 20 },
    { slotKey = "HANDS", slotLabel = "Hands", descriptor = echoedHandsDescriptor, source = { sourceID = 23, name = "Golden Plate Gloves" }, travelerScore = 20 },
}
local echoedAnalysis = T.AnalyzeEntries(echoedEntries, {})
local echoedHands
for _, entry in ipairs(echoedAnalysis.entries) do if entry.slotKey == "HANDS" then echoedHands = entry end end
assert(echoedHands and echoedHands.echoSupport >= 0.65, "repeated accent should receive strong echo")
assert(echoedHands.mismatchPoints == 0, "strongly echoed variation should be free")
assert(echoedHands.visualImpact < echoedHands.intrinsicLoudness, "slot prominence must reduce outfit impact")

local sameOddDescriptor = {
    palette = { purple = 1 }, material = { cloth = 1 }, finish = { ornate = 1 }, motifs = { royal = 1 },
    confidence = { palette = 1, material = 1, finish = 1, motifs = 1, visualWeight = 1 },
    visualWeight = 2, loudness = 0.60, dominantPalette = "purple", setIDs = {}, expansionID = 1,
}
local prominenceEntries = {
    { slotKey = "CHEST", slotLabel = "Chest", descriptor = chest, source = chestSource, travelerScore = 20 },
    { slotKey = "LEGS", slotLabel = "Legs", descriptor = legs, source = legsSource, travelerScore = 20 },
    { slotKey = "SHOULDER", slotLabel = "Shoulders", descriptor = shoulders, source = shoulderSource, travelerScore = 20 },
    { slotKey = "HEAD", slotLabel = "Head", descriptor = sameOddDescriptor, source = { sourceID = 30, name = "Purple Head" }, travelerScore = 20 },
    { slotKey = "WRIST", slotLabel = "Wrists", descriptor = sameOddDescriptor, source = { sourceID = 31, name = "Purple Wrists" }, travelerScore = 20 },
}
local prominenceAnalysis = T.AnalyzeEntries(prominenceEntries, {})
local head, wrists
for _, entry in ipairs(prominenceAnalysis.entries) do
    if entry.slotKey == "HEAD" then head = entry elseif entry.slotKey == "WRIST" then wrists = entry end
end
assert(head.visualImpact > wrists.visualImpact, "the same intrinsic loudness must have more impact on a prominent slot")
assert(head.mismatchPoints >= wrists.mismatchPoints, "minor slots must never cost more than prominent slots for the same style")

QC.Wardrobe = {
    slotDefinitions = {
        { key = "CHEST", label = "Chest" }, { key = "LEGS", label = "Legs" },
        { key = "SHOULDER", label = "Shoulders" }, { key = "ONE_HAND", label = "Main Hand", weaponRole = "ONE_HAND" },
        { key = "OFF_HAND", label = "Off Hand", weaponRole = "OFF_HAND" },
    },
    GetPreviewState = function()
        return { styleMode = "TRAVELER", generatedName = "Harness Outfit", selections = {}, hidden = {}, locks = {}, linkWeaponHands = true }
    end,
}
local mockSources = { CHEST = chestSource, LEGS = legsSource, SHOULDER = shoulderSource, ONE_HAND = swordSource, OFF_HAND = swordSource }
QC.Wardrobe.GetSelectedSource = function(slotKey) return mockSources[slotKey] end
assert(loadfile("Core/ZoneStyle/Traveler/Debug.lua"))()
local current = ZoneStyle.GetTravelerCurrentAnalysis()
assert(current and current.selectedAppearanceCount == 5, "debug analyzer should preserve physical selection count")
assert(current.analysisBlockCount == 4, "debug analyzer should collapse the linked weapon pair")

print(string.format(
    "PASS Traveler calibration: pair %.3f neutral %.3f postal %s belt %s linkedBlocks %d mismatch %.2f",
    pairScore, neutralScore, bySlot.HEAD.mismatchClass, bySlot.WAIST.mismatchClass,
    analysis.analysisBlockCount, analysis.mismatchUsed
))
