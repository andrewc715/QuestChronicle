QuestChronicle = {
    version = "1.9.0.7",
    Wardrobe = { _Private = {} },
    ZoneStyle = {}, _Core = {},
}
QuestChronicleDB = { ui = {} }
local QC, W, WP = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
QC.Notify = function() end
QC.GetCurrentCharacter = function() return { name = "Tester", realm = "Realm", className = "Warrior" } end
UnitLevel = function() return 80 end
local clock = 1000
time = function() clock = clock + 1 return clock end
date = function(_, value) return tostring(value) end

local definitions = {
    { key = "CHEST", label = "Chest" }, { key = "LEGS", label = "Legs" },
    { key = "SHOULDER", label = "Shoulders" }, { key = "TWO_HAND", label = "Two-Hand" },
    { key = "OFF_HAND", label = "Off Hand" },
}
W.slotDefinitions = definitions
local byKey = {}
for _, definition in ipairs(definitions) do byKey[definition.key] = definition end
W.GetSlotDefinition = function(key) return byKey[key] end
local sources = {
    CHEST = { sourceID = 1, visualID = 11, styleName = "Chest A" },
    LEGS = { sourceID = 2, visualID = 12, styleName = "Legs A" },
    SHOULDER = { sourceID = 3, visualID = 13, styleName = "Shoulders A" },
    TWO_HAND = { sourceID = 4, visualID = 14, styleName = "Greatsword A", styleItemSubType = "Two-Handed Sword" },
    OFF_HAND = { sourceID = 5, visualID = 15, styleName = "Greatsword B", styleItemSubType = "Two-Handed Sword" },
}
WP.GetSourceByID = function(slotKey, sourceID)
    local source = sources[slotKey]
    return source and source.sourceID == sourceID and source or nil
end
WP.BuildGenerationCachePerformance = function() return { invalidationReasons = {} } end
W.RerollSlot = function() return true, "ok" end

dofile("Core/Diagnostics/Foundation.lua")
dofile("Core/Diagnostics/History.lua")
dofile("Core/Diagnostics/Comparison.lua")
dofile("Core/Diagnostics/SnapshotBuilder.lua")
dofile("Core/Diagnostics/ReportFormatter.lua")
local D = QC.Diagnostics

local state = {
    generatedName = "First", styleMode = "TRAVELER",
    selections = { CHEST = 1, LEGS = 2, SHOULDER = 3, TWO_HAND = 4, OFF_HAND = 5 },
    selectionVisuals = { CHEST = 11, LEGS = 12, SHOULDER = 13, TWO_HAND = 14, OFF_HAND = 15 },
    locks = {}, hidden = {},
}
local function job(score, penalty, adjusted, novelty)
    local diagnostics = {
        sources = { CHEST = sources.CHEST, LEGS = sources.LEGS, SHOULDER = sources.SHOULDER },
        mainSource = sources.TWO_HAND, offSource = sources.OFF_HAND,
        score = score, baseSkeletonScore = score, repeatPenalty = penalty,
        adjustedSelectionScore = adjusted, noveltyClass = novelty,
        comparedComponents = { "Chest", "Legs", "Shoulders", "Weapon bundle" },
        changedComponents = novelty == "MEANINGFULLY_NEW" and { "Legs", "Weapon bundle" } or {},
        repeatedComponents = novelty == "MEANINGFULLY_NEW" and { "Chest", "Shoulders" } or {},
        meanPairCohesion = 0.538, hardClashes = 0, chosenRank = 1, shortlistSize = 4,
        scoreBreakdown = { armorBase = 55, weaponBase = 12, armorRelationships = 49, weaponRelationships = score - 116, hardClashPenalty = 0, repeatPenalty = penalty },
    }
    return {
        action = "GENERATE_OUTFIT", liveState = state, draft = state, styleMode = "TRAVELER",
        styleContext = {}, anchorDiagnostics = diagnostics,
        anchorStats = {
            chosenRank = 1, shortlistSize = 4, chosenScore = score, baseSkeletonScore = score,
            repeatPenalty = penalty, adjustedSelectionScore = adjusted, noveltyClass = novelty,
            comparedComponents = diagnostics.comparedComponents, changedComponents = diagnostics.changedComponents,
            repeatedComponents = diagnostics.repeatedComponents, meanPairCohesion = 0.538, hardClashes = 0,
        },
    }
end
local performance = {
    elapsedMs = 1500, steps = 100, maxStepMs = 8.3, longestWorkerSliceMs = 8.3,
    slowestPhase = "anchorWeaponExpansion", slowestPhaseMs = 5.7,
    largestInstrumentedCallPhase = "anchorWeaponExpansion", largestInstrumentedCallMs = 5.7,
    phaseStats = { anchorWeaponExpansion = { calls = 10, totalMs = 20, maxMs = 5.7 } },
    cacheDiagnostics = { invalidationReasons = {} },
}
local first = D.RecordImmediateAttempt(job(133.93, -18, 115.93, "MEANINGFULLY_NEW"), true, "first", performance)
state.generatedName = "Second"
local second = D.RecordImmediateAttempt(job(120.10, -6, 114.10, "PARTIAL_CHANGE"), true, "second", performance)
assert(second.comparison.previousScore == 133.93, "previous comparison must use the immutable stored base score")
assert(second.comparison.previousAdjustedScore == 115.93, "previous adjusted score must not be recalculated")
local report = D.FormatCopyReport(second, false, false)
assert(report:find("Base skeleton score: 133.9 → 120.1", 1, true), "compact score comparison should round from the stored values")
assert(report:find("Adjusted selection score: 115.9 → 114.1", 1, true), "adjusted score comparison should remain internally consistent")
assert(report:find("Main Hand:", 1, true) and report:find("Two-Handed Sword", 1, true), "physical slot labels should retain subtype metadata")
assert(report:find("Longest worker slice: 8.3 ms", 1, true), "worker-slice timing should be explicit")
assert(report:find("Largest instrumented call: Anchor weapon expansion 5.7 ms", 1, true), "instrumented-call timing should be explicit")

local old = {
    formatVersion = 1, id = "old", timestamp = 1, timestampText = "old", version = "1.9.0.3",
    action = "GENERATE_OUTFIT", result = "COMPLETED", mode = "TRAVELER",
    character = {}, context = {}, outfit = {}, skeleton = { components = {}, score = 100 },
    beam = {}, performance = {}, cache = {}, warnings = {},
}
local oldText = D.FormatCopyReport(old, false, false)
assert(oldText:find("Novelty data: Not recorded by this version", 1, true), "v1.9.0.3 reports should remain readable without invented novelty data")

print("PASS v1.9.0.7 diagnostics: immutable scores, physical hand labels, timing terminology, and legacy reports verified")
