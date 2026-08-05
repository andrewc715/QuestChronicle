QuestChronicle = {
    version = "1.9.0.9",
    Wardrobe = { _Private = {}, slotDefinitions = {} },
    Diagnostics = nil,
    _Core = {},
}
QuestChronicleDB = { ui = {} }
local QC, W, WP = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
QC.Notify = function() end
for _, slotKey in ipairs({ "WAIST", "HANDS", "FEET", "HEAD", "BACK", "WRIST", "SHIRT", "TABARD" }) do
    W.slotDefinitions[#W.slotDefinitions + 1] = { key = slotKey, label = slotKey }
end
function W.GetSlotDefinition(slotKey)
    for _, definition in ipairs(W.slotDefinitions) do if definition.key == slotKey then return definition end end
end
WP.SUPPORT_SLOT_ORDER = { "WAIST", "HANDS", "FEET", "HEAD", "BACK", "WRIST", "SHIRT", "TABARD" }

dofile("Core/Wardrobe/SupportProfileIdentity.lua")
dofile("Core/Diagnostics/Foundation.lua")
dofile("Core/Diagnostics/History.lua")
dofile("Core/Diagnostics/SupportSnapshot.lua")
local D, DP = QC.Diagnostics, QC.Diagnostics._Private

local function Distribution(prefix, count)
    local result = {}
    for index = 1, count do result[prefix .. index] = (count - index + 1) / 100 end
    return result
end

local function Descriptor(index)
    return {
        palette = Distribution("palette", 8), material = Distribution("material", 7),
        finish = Distribution("finish", 7), motifs = Distribution("motif", 12),
        confidence = { palette = 0.91, material = 0.87, finish = 0.82, motifs = 0.79, visualWeight = 0.88, provenance = 0.76 },
        setIDs = { 10000 + index, 11000 + index, 12000 + index, 13000 + index },
        visualWeight = 3.75, expansionID = index,
        dominantPalette = "palette1", dominantMaterial = "material1",
        dominantFinish = "finish1", dominantMotif = "motif1",
        dominantPaletteStrength = 0.41, dominantMaterialStrength = 0.44,
        dominantFinishStrength = 0.39, dominantMotifStrength = 0.35,
    }
end

local mask = {
    version = 1,
    CHEST = { logicalKey = "CHEST", slotKey = "CHEST", state = "ACTIVE", sourceID = 101, visualID = 201 },
    LEGS = { logicalKey = "LEGS", slotKey = "LEGS", state = "LOCKED", sourceID = 102, visualID = 202 },
    SHOULDER = { logicalKey = "SHOULDER", slotKey = "SHOULDER", state = "ACTIVE", sourceID = 103, visualID = 203 },
    WEAPON = { logicalKey = "WEAPON", state = "ACTIVE", mainSlotKey = "ONE_HAND", mainSourceID = 104, mainVisualID = 204, offSourceID = 105, offVisualID = 205 },
}
local profile = {
    version = 2, profileID = "QCPROFILE-MAXIMUM-DETAIL", profileSourceReportID = "QCDBG-PROFILE-SOURCE",
    activeAnchorMask = mask, activeAnchorMaskSignature = WP.ActiveAnchorMaskSignature(mask),
    activeAnchorCount = 4, meanAnchorCohesion = 0.684,
    strongestRelationship = { left = "Chest", right = "Shoulders", score = 0.881 },
    weakestRelationship = { left = "Chest", right = "Weapon bundle", score = 0.411 },
    cohesionComponents = { palette = 0.72, material = 0.76, finish = 0.61, visualWeight = 0.74, motif = 0.53, provenance = 0.67 },
    tolerance = { palette = 0.28, material = 0.24, finish = 0.39, visualWeight = 0.26, motif = 0.47, provenance = 0.33 },
    confidence = { palette = 0.84, material = 0.79, finish = 0.71, visualWeight = 0.88, motifs = 0.68, provenance = 0.75 },
    descriptor = Descriptor(9), mainWeaponSlot = "ONE_HAND", entries = {},
}
for index, values in ipairs({
    { "CHEST", "Chest", 0.34, 101, 201 }, { "LEGS", "Legs", 0.24, 102, 202 },
    { "SHOULDER", "Shoulders", 0.18, 103, 203 }, { "ONE_HAND", "Main Hand", 0.12, 104, 204 },
    { "OFF_HAND", "Off Hand", 0.12, 105, 205 },
}) do
    profile.entries[#profile.entries + 1] = {
        slotKey = values[1], label = values[2], weight = values[3],
        source = { sourceID = values[4], visualID = values[5] }, descriptor = Descriptor(index),
    }
end

local decisions = {}
for index, slotKey in ipairs(WP.SUPPORT_SLOT_ORDER) do
    decisions[#decisions + 1] = {
        slotKey = slotKey,
        source = { sourceID = 2000 + index, visualID = 3000 + index, itemID = 4000 + index, styleName = string.rep(slotKey .. " Contextual Appearance ", 3) },
        role = "Contextual bridge, continuity, silhouette, motif, and controlled-accent role",
        profileFit = 0.812, neighborCohesion = 0.784, bridgeBonus = 5.25,
        bridgeTarget = "Chest ↔ Legs", bridgeBefore = 0.51, bridgeAfter = 0.73,
        mismatchSpent = 0.74, budgetState = "WITHIN", outlierState = "NORMAL",
        repeatPenalty = 0, score = 42.5, finalMismatchClass = "SUPPORTED VARIATION",
        echoSupport = 0.72, outlierSeverity = 0.41, repaired = index <= 2, repairPass = index <= 2 and index or nil,
        replacedVisualID = index <= 2 and 9000 + index or nil, protectedByLock = false,
    }
end
local stats = {
    activeSlots = WP.SUPPORT_SLOT_ORDER, profile = profile,
    startingBudget = 10.75, lockedCommitment = 1.25, generatedSpend = 5.92,
    borrowed = 0.20, overrun = 0, remainingBudget = 3.58,
    configurationScore = 318.5, wholeOutfitCohesion = 0.79,
    controlledAccents = 1, outliers = 0, fallbackSlots = 0, emptySlots = 0,
    chosenRank = 2, shortlistSize = 6, poolSizes = {}, expansions = {}, retained = {},
    deduplicated = 12, budgetRejections = 4, decisions = decisions,
    targetSlotKey = "HEAD", previousTargetName = string.rep("Previous Head Appearance ", 3),
    previousTargetSourceID = 9991, previousTargetVisualID = 9992,
    previousTargetCost = 0.31, replacementCost = 0.27, budgetBefore = 5.96, budgetAfter = 5.92,
    fixedContextCount = 7, profileID = profile.profileID, profileSourceReportID = profile.profileSourceReportID,
    profileReused = true, profileRepaired = false, profileMigrated = false,
    profileBasisConsistent = true, fixedContextCost = 5.65, profileAdjustment = 0,
    expectedBudgetAfter = 5.92, budgetReconciled = true,
    finalValidationStatus = "REPAIRED", repairPasses = 2, alternateSkeleton = false,
    phaseDInitial = { status = "REPAIR_REQUIRED", mismatchBudget = 2, mismatchUsed = 2.84, maximumSeverity = 0.81, severityThreshold = 0.72, paletteFamilies = 4, paletteLimit = 3, repairableZeroEcho = 1, repairableOutliers = 2, protectedLockedViolations = 0 },
    phaseDFinal = { status = "CLEAN", mismatchBudget = 2, mismatchUsed = 1.74, maximumSeverity = 0.54, severityThreshold = 0.72, paletteFamilies = 3, paletteLimit = 3, repairableZeroEcho = 0, repairableOutliers = 0, protectedLockedViolations = 0 },
    repairs = {
        { pass = 1, slotKey = "BACK", previousName = string.rep("Loud Postal Cape ", 3), replacementName = string.rep("Weathered Chain Cloak ", 3), trigger = "zero-echo loud accent", mismatchBefore = 2.84, mismatchAfter = 2.10, severityBefore = 0.81, severityAfter = 0.43, paletteBefore = 4, paletteAfter = 3, cohesionBefore = 0.61, cohesionAfter = 0.65 },
        { pass = 2, slotKey = "HEAD", previousName = string.rep("Ornate Postal Crown ", 3), replacementName = string.rep("Frontier Plate Helm ", 3), trigger = "outlier severity", mismatchBefore = 2.10, mismatchAfter = 1.74, severityBefore = 0.76, severityAfter = 0.54, paletteBefore = 3, paletteAfter = 3, cohesionBefore = 0.65, cohesionAfter = 0.68 },
    },
}
for _, slotKey in ipairs(WP.SUPPORT_SLOT_ORDER) do
    stats.poolSizes[slotKey], stats.expansions[slotKey], stats.retained[slotKey] = 32, 768, 24
end
local snapshot = DP.BuildSupportSnapshot({ hidden = {}, locks = {} }, { action = "REROLL_SLOT", supportDiagnostics = stats })
assert(snapshot and snapshot.profile and snapshot.profile.version == 2, "full profile snapshot was not captured")
assert(#snapshot.profile.entries == 5 and #snapshot.decisions == 8, "maximum-detail snapshot is incomplete")

local report = D.AddReport({
    formatVersion = 1, id = "QCDBG-MAXIMUM-SUPPORT-SNAPSHOT", sequence = 1,
    timestamp = 1785770000, timestampText = "2026-08-03 12:00:00", version = "1.9.0.9",
    action = "REROLL_SLOT", actionSlotKey = "HEAD", result = "COMPLETED",
    generationToken = "QCGEN-MAXIMUM-SUPPORT-SNAPSHOT", lineageID = "Tester-Realm",
    character = { key = "Tester-Realm", name = "Tester", realm = "Realm", className = "WARRIOR" },
    skeleton = { components = {}, baseSkeletonScore = 145.2, adjustedSelectionScore = 130.2, meanPairCohesion = 0.68 },
    support = snapshot, performance = { phaseStats = {} }, cache = { invalidationReasons = {} }, warnings = {},
})
assert(report, "maximum-detail support snapshot should be accepted")
assert((report.approximateBytes or 0) < D.MAX_REPORT_BYTES,
    string.format("maximum-detail persisted Phase C snapshot exceeds 20 KB: %d", report.approximateBytes or 0))
assert(snapshot.finalValidationStatus == "REPAIRED" and #snapshot.repairs == 2, "Phase D snapshot fields were not retained")
print(string.format("PASS Phase D persisted support snapshot size: %d bytes, %d profile entries, %d decisions, %d repairs", report.approximateBytes or 0, #snapshot.profile.entries, #snapshot.decisions, #snapshot.repairs))
