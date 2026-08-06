QuestChronicle = {
    version = "1.9.0.7",
    Wardrobe = { _Private = {} },
    ZoneStyle = {}, _Core = {},
}
QuestChronicleDB = { ui = {} }
local QC, W, WP = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
QC.Notify = function() end
QC.GetCurrentCharacter = function() return { key = "Tester-Realm", name = "Tester", realm = "Realm", className = "Warrior" } end
UnitLevel = function() return 80 end
local clock = 2000
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
dofile("Core/Diagnostics/ReportEmergencyStub.lua")
dofile("Core/Diagnostics/ReportCompaction.lua")
dofile("Core/Diagnostics/History.lua")
dofile("Core/Diagnostics/Comparison.lua")
dofile("Core/Diagnostics/SnapshotBuilder.lua")
dofile("Core/Diagnostics/ReportFormatter.lua")
local D = QC.Diagnostics

local function performance()
    return {
        elapsedMs = 1200, steps = 80, maxStepMs = 7.2, longestWorkerSliceMs = 7.2,
        slowestPhase = "anchorWeaponExpansion", slowestPhaseMs = 5.4,
        largestInstrumentedCallPhase = "weaponAppearance", largestInstrumentedCallMs = 5.1,
        phaseStats = { anchorWeaponExpansion = { calls = 10, totalMs = 30, maxMs = 5.4 } },
        cacheDiagnostics = { invalidationReasons = {} },
    }
end

local function makeState(hiddenShoulder, lockedChest, chestSource)
    return {
        generatedName = "Look", styleMode = "TRAVELER",
        selections = { CHEST = chestSource or 1, LEGS = 2, SHOULDER = 3, TWO_HAND = 4, OFF_HAND = 5 },
        selectionVisuals = { CHEST = 11, LEGS = 12, SHOULDER = 13, TWO_HAND = 14, OFF_HAND = 15 },
        locks = { CHEST = lockedChest == true }, hidden = { SHOULDER = hiddenShoulder == true },
    }
end

local function makeJob(state, identity, score)
    local diagnostics = {
        score = score, baseSkeletonScore = score, repeatPenalty = 0, adjustedSelectionScore = score,
        noveltyClass = "MEANINGFULLY_NEW", comparedComponents = { "Chest", "Legs", "Weapon bundle" },
        changedComponents = { "Legs", "Weapon bundle" }, repeatedComponents = { "Chest" },
        meanPairCohesion = 0.55, hardClashes = 0, chosenRank = 1, shortlistSize = 4,
        scoreBreakdown = { armorBase = 40, weaponBase = 10, armorRelationships = 20, weaponRelationships = score - 70, hardClashPenalty = 0 },
    }
    return {
        action = "GENERATE_OUTFIT", liveState = state, draft = state, styleMode = "TRAVELER",
        styleContext = {}, anchorDiagnostics = diagnostics,
        anchorStats = {
            chosenRank = 1, shortlistSize = 4, chosenScore = score, baseSkeletonScore = score,
            repeatPenalty = 0, adjustedSelectionScore = score, noveltyClass = "MEANINGFULLY_NEW",
            comparedComponents = diagnostics.comparedComponents, changedComponents = diagnostics.changedComponents,
            repeatedComponents = diagnostics.repeatedComponents, meanPairCohesion = 0.55, hardClashes = 0,
        },
        diagnosticIdentity = identity,
    }
end

local firstIdentity = D.BeginGenerationAttempt("GENERATE_OUTFIT")
local first = D.RecordImmediateAttempt(makeJob(makeState(false, false), firstIdentity, 100), true, "first", performance())
assert(first.id == firstIdentity.reportID, "reserved report identity must be preserved")

local hiddenIdentity = D.BeginGenerationAttempt("GENERATE_OUTFIT")
assert(hiddenIdentity.parentCompletedReportID == first.id, "attempt must capture its immutable completed parent at start")
local hidden = D.RecordImmediateAttempt(makeJob(makeState(true, false), hiddenIdentity, 95), true, "hidden", performance())
assert(hidden.parentCompletedReportID == first.id, "stored ancestry must match the captured parent")
assert(hidden.comparison and hidden.comparison.previousReportID == first.id, "comparison must use explicit ancestry")
assert(table.concat(hidden.comparison.excluded, ","):find("Shoulders %(Hidden%)"), "hidden Shoulder must be excluded")
assert(not table.concat(hidden.comparison.unchanged, ","):find("Shoulders"), "hidden Shoulder must not be unchanged")
for _, warning in ipairs(hidden.warnings) do
    assert(warning.key ~= "REPEATED_FOUNDATION", "hidden Shoulders must not trigger foundation repetition")
end
local copy = D.FormatCopyReport(hidden, false, false)
assert(copy:find("Excluded: Shoulders (Hidden)", 1, true), "copied report must explain the hidden exclusion")

local lockedIdentity = D.BeginGenerationAttempt("GENERATE_OUTFIT")
local locked = D.RecordImmediateAttempt(makeJob(makeState(false, true), lockedIdentity, 90), true, "locked", performance())
assert(table.concat(locked.comparison.excluded, ","):find("Chest %(Locked%)"), "locked Chest must be excluded")

local before = D.GetHistoryCounters().duplicateInsertionsIgnored
local duplicate = QC.Diagnostics._Private.DeepCopy(locked, 10)
local same, reason = D.AddReport(duplicate)
assert(same.id == locked.id and reason, "duplicate report must resolve to the original")
assert(D.GetHistoryCounters().duplicateInsertionsIgnored == before + 1, "duplicate counter must increment")

local cancelledIdentity = D.BeginGenerationAttempt("GENERATE_OUTFIT")
local cancelled = D.RecordImmediateAttempt(makeJob(makeState(false, false), cancelledIdentity, 80), false, "cancelled", performance())
assert(cancelled.result == "CANCELLED", "cancelled attempt must be recorded")
local nextIdentity = D.BeginGenerationAttempt("GENERATE_OUTFIT")
assert(nextIdentity.parentCompletedReportID == locked.id, "cancelled report must not become the next completed parent")

print("PASS v1.9.0.7 diagnostics stabilization: hidden/locked exclusions, ancestry, cancellation skipping, and duplicate protection verified")
