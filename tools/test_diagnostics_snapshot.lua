QuestChronicle = {
    version = "1.9.0.7",
    Wardrobe = { _Private = {} },
    ZoneStyle = {},
    _Core = {},
}
local QC = QuestChronicle
local W, WP = QC.Wardrobe, QC.Wardrobe._Private
QuestChronicleDB = { ui = {} }
QC.Notify = function() end
QC.GetUIState = function() return QuestChronicleDB.ui end
QC.GetCurrentCharacter = function() return { key = "Tester-Realm", name = "Tester", realm = "Realm", className = "Warrior", classID = 1, raceName = "Human" } end
UnitLevel = function() return 80 end
time = function() return 123456 end
date = function(_, value) return "2026-08-02 20:34:00" end

local definitions = {
    { key = "CHEST", label = "Chest" }, { key = "LEGS", label = "Legs" },
    { key = "SHOULDER", label = "Shoulders" }, { key = "ONE_HAND", label = "One-Hand", weaponRole = true },
    { key = "OFF_HAND", label = "Off Hand", weaponRole = true },
}
W.slotDefinitions = definitions
local byKey = {}
for _, definition in ipairs(definitions) do byKey[definition.key] = definition end
W.GetSlotDefinition = function(key) return byKey[key] end
local sources = {
    CHEST = { sourceID = 1, visualID = 11, itemID = 101, styleName = "Rugged Plate Vest", categoryID = 1 },
    LEGS = { sourceID = 2, visualID = 12, itemID = 102, styleName = "Redsteel Legguards", categoryID = 2 },
    SHOULDER = { sourceID = 3, visualID = 13, itemID = 103, styleName = "Expedition Shoulders", categoryID = 3 },
    ONE_HAND = { sourceID = 4, visualID = 14, itemID = 104, styleName = "Ice-Pitted Blade", styleItemSubType = "One-Handed Sword", categoryID = 4 },
    OFF_HAND = { sourceID = 4, visualID = 14, itemID = 104, styleName = "Ice-Pitted Blade", styleItemSubType = "One-Handed Sword", categoryID = 4 },
}
WP.GetSourceByID = function(slot, id)
    local source = sources[slot]
    return source and source.sourceID == id and source or nil
end
WP.EnsurePreviewState = function() return _G.testState end
WP.BuildGenerationCachePerformance = function()
    return { persistentEvidence = 3200, persistentPrechecks = 3500, persistentEligibility = 3200, invalidationReasons = {} }
end
W.RerollSlot = function(slotKey)
    testState.generatedName = "Rerolled Look"
    return true, slotKey .. " rerolled."
end

dofile("Core/Diagnostics/Foundation.lua")
dofile("Core/Diagnostics/History.lua")
dofile("Core/Diagnostics/Comparison.lua")
dofile("Core/Diagnostics/SnapshotBuilder.lua")
dofile("Core/Diagnostics/ReportFormatter.lua")
local D = QC.Diagnostics

testState = {
    generatedName = "Anchor Look",
    styleMode = "TRAVELER",
    selections = { CHEST = 1, LEGS = 2, SHOULDER = 3, ONE_HAND = 4, OFF_HAND = 4 },
    selectionVisuals = { CHEST = 11, LEGS = 12, SHOULDER = 13, ONE_HAND = 14, OFF_HAND = 14 },
    locks = { CHEST = true }, hidden = {},
}
local anchorDiagnostics = {
    sources = { CHEST = sources.CHEST, LEGS = sources.LEGS, SHOULDER = sources.SHOULDER },
    mainSource = sources.ONE_HAND, offSource = sources.OFF_HAND,
    score = 148.6, meanPairCohesion = 0.614, hardClashes = 0,
    chosenRank = 1, shortlistSize = 4, signature = "sig",
    baseSkeletonScore = 148.6, repeatPenalty = -18, adjustedSelectionScore = 130.6,
    noveltyClass = "MEANINGFULLY_NEW", comparedComponents = { "Chest", "Legs", "Shoulders", "Weapon bundle" },
    changedComponents = { "Legs", "Weapon bundle" }, repeatedComponents = { "Chest", "Shoulders" },
    candidates = {
        CHEST = { source = sources.CHEST, baseScore = 30, scoreReasons = { "Travel: rugged" } },
        LEGS = { source = sources.LEGS, baseScore = 28 }, SHOULDER = { source = sources.SHOULDER, baseScore = 32 },
        ONE_HAND = { source = sources.ONE_HAND, baseScore = 20 }, OFF_HAND = { source = sources.OFF_HAND, baseScore = 20 },
    },
    scoreBreakdown = { armorBase = 90, weaponBase = 40, armorRelationships = 10, weaponRelationships = 8.6, hardClashPenalty = 0, repeatPenalty = 0 },
    cohesionComponents = { palette = 0.7, material = 0.8, finish = 0.5, visualWeight = 0.6, motif = 0.55, provenance = 0.4 },
    strongestBridge = { label = "Chest ↔ Shoulders", score = 0.82 },
    weakestRelationship = { label = "Legs ↔ Weapons", score = 0.41 },
}
local job = {
    action = "GENERATE_OUTFIT", liveState = testState, draft = testState,
    styleMode = "TRAVELER", styleContext = { profileLabel = "Outland Traveler", zone = "Hellfire Peninsula", eraLabel = "The Burning Crusade" },
    anchorDiagnostics = anchorDiagnostics,
    anchorStats = { poolSizes = { CHEST = 47, LEGS = 32, SHOULDER = 32 }, expansions = { CHEST = 47, LEGS = 1024, SHOULDER = 1024 }, retained = { CHEST = 32, LEGS = 32, SHOULDER = 32 }, weaponBundles = 4, chosenRank = 1, shortlistSize = 4, chosenScore = 148.6, baseSkeletonScore = 148.6, repeatPenalty = -18, adjustedSelectionScore = 130.6, noveltyClass = "MEANINGFULLY_NEW", comparedComponents = { "Chest", "Legs", "Shoulders", "Weapon bundle" }, changedComponents = { "Legs", "Weapon bundle" }, repeatedComponents = { "Chest", "Shoulders" }, meanPairCohesion = 0.614, hardClashes = 0, pairCacheHits = 1120, pairCacheMisses = 1964 },
}
local performance = {
    elapsedMs = 3000, steps = 203, maxStepMs = 21.9, candidates = 3256, eraCandidates = 141,
    eraCacheHits = 3992, eligibilityCacheHits = 8072, weaponYields = 2214, selectedArmor = 10,
    slowestPhase = "anchorWeaponExpansion", slowestPhaseMs = 19.6,
    phaseStats = { anchorWeaponExpansion = { calls = 2218, totalMs = 200.7, maxMs = 19.6 }, uiRefresh = { calls = 1, totalMs = 1.8, maxMs = 1.8 } },
    cacheDiagnostics = { persistentEvidence = 3460, persistentPrechecks = 3831, persistentEligibility = 6915, invalidationReasons = { PENDING_RETRY_EXPIRED = 210 } },
}
local report = D.RecordImmediateAttempt(job, true, "Generated Anchor Look.", performance)
assert(report and report.action == "GENERATE_OUTFIT", "generation snapshot should be recorded")
assert(report.skeleton.components[1].name == "Rugged Plate Vest", "snapshot should capture the selected chest")
assert(report.skeleton.score == 148.6 and report.beam.expansions.LEGS == 1024, "beam and score metrics should be preserved")
assert(#report.warnings >= 1 and report.warnings[1].key == "SEVERE_WORKER_SLICE", "severe worker slice should be flagged")
assert(report.skeleton.baseSkeletonScore == 148.6 and report.skeleton.adjustedSelectionScore == 130.6, "base and adjusted scores should remain distinct")

sources.CHEST.styleName = "Changed Later"
assert(report.skeleton.components[1].name == "Rugged Plate Vest", "snapshot must remain immutable after source hydration")
local copy = D.FormatCopyReport(report, true, true)
assert(copy:find("Anchor Skeleton", 1, true) and copy:find("source 1", 1, true), "copy report should include sections and raw IDs")
assert(copy:find("Main Hand:", 1, true) and not copy:find("One-Hand:", 1, true), "weapon report should use physical Main Hand terminology")
assert(copy:find("Longest worker slice", 1, true) and copy:find("Largest instrumented call", 1, true), "worker slices and instrumented calls should be named separately")
local display = D.FormatDisplayReport(report, false, false)
assert(not display:find("source 1", 1, true), "display report should hide raw IDs by default")
assert((report.approximateBytes or 0) < D.MAX_REPORT_BYTES, "snapshot should remain under the persistence limit")

local ok = W.RerollSlot("CHEST")
assert(ok == true, "wrapped reroll slot should preserve original result")
local latest = D.GetLatestReport()
assert(latest.action == "REROLL_SLOT" and latest.actionSlotKey == "CHEST", "reroll slot should create a correctly labeled report")
print(string.format("PASS diagnostics snapshot: %d-byte immutable report, beam/scoring/performance captured, reroll wrapper preserved", report.approximateBytes or 0))
