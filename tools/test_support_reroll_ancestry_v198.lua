QuestChronicleDB = {}
time, date = os.time, os.date
UnitLevel = function() return 30 end
QuestChronicle = { version = "1.9.0.8", Wardrobe = { _Private = {}, slotDefinitions = {} }, Diagnostics = { _Private = {} } }
local QC, W, WP, D, DP = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private, QuestChronicle.Diagnostics, QuestChronicle.Diagnostics._Private
QC.GetCurrentCharacter = function() return { key = "Xyrkian-MoonGuard", name = "Xyrkian", realm = "MoonGuard", className = "WARRIOR" } end
QC.Notify = function() end
local keys = { "CHEST", "LEGS", "SHOULDER", "ONE_HAND", "OFF_HAND", "WAIST", "HANDS", "FEET", "HEAD", "BACK", "WRIST", "SHIRT", "TABARD" }
for _, key in ipairs(keys) do W.slotDefinitions[#W.slotDefinitions + 1] = { key = key, label = key } end
WP.slotByKey = {}; for _, d in ipairs(W.slotDefinitions) do WP.slotByKey[d.key] = d end
WP.SUPPORT_SLOT_ORDER = { "WAIST", "HANDS", "FEET", "HEAD", "BACK", "WRIST", "SHIRT", "TABARD" }
WP.ANCHOR_FINAL_SCORE_WINDOW = 28
function WP.IsSupportSlotKey(slotKey) for _, key in ipairs(WP.SUPPORT_SLOT_ORDER) do if key == slotKey then return true end end return false end
function W.GetSlotDefinition(key) return WP.slotByKey[key] end
function W.RerollSlot() return true, "stub" end
function WP.BuildGenerationCachePerformance() return {} end
local sources = {}
local function source(slot, id, name) local s = { slotKey = slot, sourceID = id, visualID = id, styleName = name or (slot .. id) }; sources[slot .. id] = s; return s end
local chest, legs, shoulder, main, off = source("CHEST", 1, "Chest"), source("LEGS", 2, "Legs"), source("SHOULDER", 3, "Shoulders"), source("ONE_HAND", 4, "Sword"), source("OFF_HAND", 4, "Sword")
local waistA, waistB = source("WAIST", 10, "Waist A"), source("WAIST", 11, "Waist B")
function WP.GetSourceByID(slot, id) return sources[slot .. id] end
local state = {
    selections = { CHEST = 1, LEGS = 2, SHOULDER = 3, ONE_HAND = 4, OFF_HAND = 4, WAIST = 10 },
    selectionVisuals = { CHEST = 1, LEGS = 2, SHOULDER = 3, ONE_HAND = 4, OFF_HAND = 4, WAIST = 10 },
    locks = {}, hidden = {}, styleMode = "TRAVELER", generatedName = "Ancestry Test",
}
WP.EnsurePreviewState = function() return state end

for _, file in ipairs({ "Foundation.lua", "AnchorAncestry.lua", "History.lua", "SupportComparison.lua", "SupportSnapshot.lua", "Comparison.lua", "SnapshotBuilder.lua" }) do dofile("Core/Diagnostics/" .. file) end

local skeleton = {
    chosenRank = 1, shortlistSize = 4, score = 135.7, baseSkeletonScore = 135.7,
    repeatPenalty = 0, adjustedSelectionScore = 135.7, meanPairCohesion = .550, hardClashes = 0,
    noveltyClass = "MEANINGFULLY_NEW", comparedComponents = { "Chest", "Legs", "Shoulders", "Weapon bundle" },
    changedComponents = { "Legs", "Weapon bundle" }, repeatedComponents = { "Chest", "Shoulders" }, excludedComponents = {},
    components = {
        { slotKey = "CHEST", slotLabel = "Chest", sourceID = 1, visualID = 1 },
        { slotKey = "LEGS", slotLabel = "Legs", sourceID = 2, visualID = 2 },
        { slotKey = "SHOULDER", slotLabel = "Shoulders", sourceID = 3, visualID = 3 },
        { slotKey = "ONE_HAND", slotLabel = "Main Hand", sourceID = 4, visualID = 4 },
        { slotKey = "OFF_HAND", slotLabel = "Off Hand", sourceID = 4, visualID = 4 },
    },
    scoreBreakdown = { armorBase = 50, weaponBase = 20, armorRelationships = 45, weaponRelationships = 20.7 },
}
local support = {
    profile = { activeAnchorCount = 4, meanAnchorCohesion = .65, activeAnchors = {}, centers = {}, tolerance = {}, confidence = {} },
    startingBudget = 10.75, lockedCommitment = 0, generatedSpend = .3, borrowed = 0, overrun = 0, remainingBudget = 10.45,
    configurationScore = 30, wholeOutfitCohesion = .66, controlledAccents = 0, outliers = 0, fallbackSlots = 0,
    chosenRank = 1, shortlistSize = 6, poolSizes = {}, expansions = {}, retained = {}, deduplicated = 0, budgetRejections = 0, emptySlots = 0,
    decisions = { { slotKey = "WAIST", slotLabel = "Waist", name = "Waist A", sourceID = 10, visualID = 10, mismatchSpent = .3 } }, excluded = {},
}
local anchorReport = {
    formatVersion = 1, id = "ANCHOR-1", sequence = 1, timestamp = time(), timestampText = date("%Y-%m-%d %H:%M:%S"), version = "1.9.0.8",
    lineageID = "Xyrkian-MoonGuard", generationToken = "A1", action = "GENERATE_OUTFIT", mode = "TRAVELER", result = "COMPLETED",
    performedAnchorSelection = true, anchorSourceReportID = "ANCHOR-1", anchorPhase = "SELECTED",
    character = QC.GetCurrentCharacter(), context = {}, outfit = { generatedName = "Anchor One", slots = {} }, skeleton = DP.DeepCopy(skeleton), support = DP.DeepCopy(support),
    beam = { poolSizes = {}, expansions = {}, retained = {}, weaponBundles = 4, completeSkeletons = 4, finalShortlist = 4, chosenRank = 1, weightedWindow = 28 },
    performance = { steps = 10, elapsedMs = 100, maxStepMs = 2, longestWorkerSliceMs = 2, largestInstrumentedCallMs = 1, phaseStats = {} }, cache = {}, warnings = {},
}
D.AddReport(anchorReport)

local identity = D.BeginGenerationAttempt("REROLL_SLOT", "WAIST")
assert(identity.parentCompletedReportID == "ANCHOR-1", "support parent must be latest completed report")
assert(identity.anchorSourceReportID == "ANCHOR-1", "support reroll must inherit the latest anchor source")
assert(identity.performedAnchorSelection == false, "support reroll cannot perform anchor selection")
state.selections.WAIST, state.selectionVisuals.WAIST = 11, 11
local decision = { slotKey = "WAIST", source = waistB, role = "Chest ↔ Legs bridge", profileFit = .7, neighborCohesion = .7, bridgeBonus = 0, bridgeTarget = "CHEST ↔ LEGS", bridgeBefore = .8, bridgeAfter = .7, mismatchSpent = .2, budgetState = "WITHIN", outlierState = "NORMAL", repeatPenalty = 0, score = 20, targetRerolled = true }
local supportStats = {
    profile = { activeAnchorCount = 4, meanAnchorCohesion = .65, entries = {}, descriptor = {}, tolerance = {}, confidence = {} }, activeSlots = { "WAIST" },
    startingBudget = 10.75, lockedCommitment = 0, generatedSpend = .2, borrowed = 0, overrun = 0, remainingBudget = 10.55,
    configurationScore = 20, wholeOutfitCohesion = .7, controlledAccents = 0, outliers = 0, fallbackSlots = 0,
    chosenRank = 1, shortlistSize = 6, poolSizes = { WAIST = 32 }, expansions = { WAIST = 32 }, retained = { WAIST = 6 }, decisions = { decision },
    targetSlotKey = "WAIST", previousTargetName = "Waist A", previousTargetCost = .3, replacementCost = .2, budgetBefore = .3, budgetAfter = .2, fixedContextCount = 0,
}
local supportJob = {
    action = "REROLL_SLOT", actionSlotKey = "WAIST", liveState = state, draft = state, styleMode = "TRAVELER", styleContext = {},
    diagnosticIdentity = identity, performedAnchorSelection = false, reuseAnchorSnapshot = true, anchorSourceReportID = "ANCHOR-1",
    inheritedAnchorSnapshot = anchorReport.skeleton, inheritedBeamSnapshot = anchorReport.beam, supportDiagnostics = supportStats,
}
D.RecordImmediateAttempt(supportJob, true, "Waist rerolled contextually.", { elapsedMs = 50, steps = 8, maxStepMs = 2, longestWorkerSliceMs = 2, largestInstrumentedCallPhase = "rerollCandidateScoring", largestInstrumentedCallMs = .3, phaseStats = {}, cacheDiagnostics = {} })
local supportReport = D.GetLatestReport()
assert(supportReport.anchorPhase == "REUSED", "support report must mark the anchor phase reused")
assert(supportReport.anchorSourceReportID == "ANCHOR-1", "support report lost anchor source ancestry")
assert(supportReport.skeleton.baseSkeletonScore == 135.7 and supportReport.skeleton.meanPairCohesion == .550, "support report erased immutable anchor scores")
assert(supportReport.skeleton.chosenRank == 1 and supportReport.skeleton.shortlistSize == 4, "support report erased anchor rank")
for _, warning in ipairs(supportReport.warnings or {}) do assert(warning.key ~= "REPEATED_FOUNDATION", "support reroll advanced anchor repetition warning") end

local function FullAnchor(score, token)
    local fullIdentity = D.BeginGenerationAttempt("GENERATE_OUTFIT")
    local job = {
        action = "GENERATE_OUTFIT", liveState = state, draft = state, styleMode = "TRAVELER", styleContext = {}, diagnosticIdentity = fullIdentity,
        performedAnchorSelection = true,
        anchorStats = { chosenRank = 1, shortlistSize = 4, chosenScore = score, baseSkeletonScore = score, repeatPenalty = 0, adjustedSelectionScore = score, meanPairCohesion = .55, hardClashes = 0 },
        anchorDiagnostics = { score = score, baseSkeletonScore = score, adjustedSelectionScore = score, meanPairCohesion = .55, hardClashes = 0, noveltyClass = "MEANINGFULLY_NEW", comparedComponents = {}, changedComponents = {}, repeatedComponents = {}, scoreBreakdown = skeleton.scoreBreakdown },
    }
    D.RecordImmediateAttempt(job, true, "Generated.", { elapsedMs = 100, steps = 10, maxStepMs = 2, longestWorkerSliceMs = 2, largestInstrumentedCallMs = 1, phaseStats = {}, cacheDiagnostics = {} })
    return D.GetLatestReport()
end
local second = FullAnchor(140.1, "A2")
assert(second.comparison and second.comparison.previousScore == 135.7, "next full generation compared against zero-valued support ancestry")
assert(second.previousAnchorSourceReportID == "ANCHOR-1", "full generation did not retain previous anchor source")
local third = FullAnchor(141.0, "A3")
local repeatedWarning = false
for _, warning in ipairs(third.warnings or {}) do if warning.key == "REPEATED_FOUNDATION" then repeatedWarning = true end end
assert(repeatedWarning, "anchor repetition streak must connect eligible anchor reports across support-only actions")
print("PASS v1.9.0.8 support reroll ancestry: immutable anchor scores, dual ancestry, comparison integrity, and repetition filtering verified")
