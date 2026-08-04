QuestChronicle = { Wardrobe = { _Private = {}, slotDefinitions = {} }, ZoneStyle = { Traveler = {} } }
local QC, W, P, Z, T = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle.Traveler
local slots = { "HEAD", "SHOULDER", "BACK", "CHEST", "SHIRT", "TABARD", "WRIST", "HANDS", "WAIST", "LEGS", "FEET", "ONE_HAND", "OFF_HAND" }
for _, key in ipairs(slots) do local d = { key = key, label = key }; W.slotDefinitions[#W.slotDefinitions + 1] = d end
P.slotByKey = {}; for _, d in ipairs(W.slotDefinitions) do P.slotByKey[d.key] = d end
P.MAIN_WEAPON_SLOT_KEYS = { "ONE_HAND" }
P.GENERATION_TIME_BUDGET_MS = 0.18
P.GENERATION_OPERATION_SAFETY_CAP = 2000
P.GENERATION_ERA_CANDIDATES_PER_OPERATION = 1

local clock = 0
function P.GenerationNowMilliseconds() clock = clock + 0.04 return clock end
local timerQueue = {}
C_Timer = { After = function(_, callback) timerQueue[#timerQueue + 1] = callback end }
local completion
QC.Notify = function(eventName, success, message, performance)
    if eventName == "WARDROBE_GENERATION_COMPLETE" then completion = { success = success, message = message, performance = performance } end
end

local bySlot, byID = {}, {}
local function add(slot, id, value)
    local source = {
        slotKey = slot, sourceID = id, visualID = id, styleName = slot .. id,
        descriptor = {
            palette = { steel = value }, material = { plate = value }, finish = { military = value }, motifs = { frontier = value },
            confidence = { palette = 1, material = 1, finish = 1, motifs = 1, visualWeight = 1, provenance = 1 },
            visualWeight = 2.5, loudness = 0.2, expansionID = 1, setIDs = {},
            dominantPalette = "steel", dominantMaterial = "plate", dominantFinish = "military", dominantMotif = "frontier",
        },
    }
    bySlot[slot] = bySlot[slot] or {}; bySlot[slot][#bySlot[slot] + 1] = source; byID[slot .. id] = source
    return source
end
local chest, legs, shoulder, weapon = add("CHEST", 1, .90), add("LEGS", 2, .86), add("SHOULDER", 3, .84), add("ONE_HAND", 4, .82)
local supportOrder = { "WAIST", "HANDS", "FEET", "HEAD", "BACK", "WRIST", "SHIRT", "TABARD" }
local current = {}
for index, slot in ipairs(supportOrder) do
    current[slot] = add(slot, 1000 + index, .35)
    local count = slot == "WAIST" and 50 or 3
    for candidateIndex = 1, count do add(slot, index * 10000 + candidateIndex, .55 + ((candidateIndex % 20) / 50)) end
end

function W.GetSlotSources(slot) return bySlot[slot] or {} end
function W.ValidateSource() return true end
function W.GetSlotDefinition(key) return P.slotByKey[key] end
function W.IsSlotLocked(slot) return P.EnsurePreviewState().locks[slot] == true end
function W.IsScanning() return false end
function W.IsGenerating() return P.supportRerollJob ~= nil end
function P.GetSourceByID(slot, id) return byID[slot .. id] end
function P.SetSelectedSource(state, slot, source)
    state.selections[slot] = source and source.sourceID or nil
    state.selectionVisuals[slot] = source and source.visualID or nil
end
function P.RefreshGeneratedOutfitName(state) state.generatedName = "Cooperative Reroll" return state.generatedName end
function P.CreateStyleGenerationContext() return {} end
function P.GetGenerationCacheCounterSnapshot() return {} end
function P.BuildGenerationCachePerformance() return {} end

function Z.GetTravelerDescriptor(source) return source and source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS = { CHEST = 1, LEGS = .8, SHOULDER = 1, ONE_HAND = .9, WAIST = .5, HANDS = .65, FEET = .6, HEAD = .9, BACK = .55, WRIST = .25, SHIRT = .2, TABARD = .2 }
function T.GetPairCohesion(left, right)
    local a, b = left.palette.steel or 0, right.palette.steel or 0
    local score = 1 - math.abs(a - b)
    return score, { palette = score, material = score, finish = score, visualWeight = score, motif = score, provenance = .78 }
end
Z.MODE_TRAVELER = "TRAVELER"
function Z.NormalizeMode(mode) return mode end
function Z.GetCurrentContext() return {} end
function Z.GetSourceCoherence() return .8, true end
function Z.ScoreSource(source) return (source.descriptor.palette.steel or 0) * 25, {} end
function Z.GetSourcePreEraEligibility() return true end
function Z.GetSourcePreEraEligibilityCached() return true end
function Z.CreateSourceEraEvidenceWork() return { done = true, result = { state = "KNOWN" } } end
function Z.GetSourceEligibility() return true end
function Z.GetSourceEligibilityCached() return true end

local state = { selections = { CHEST = chest.sourceID, LEGS = legs.sourceID, SHOULDER = shoulder.sourceID, ONE_HAND = weapon.sourceID }, selectionVisuals = {}, hidden = {}, locks = {}, styleMode = "TRAVELER" }
for _, slot in ipairs(supportOrder) do state.selections[slot] = current[slot].sourceID; state.selectionVisuals[slot] = current[slot].visualID end
P.EnsurePreviewState = function() return state end
W.RerollSlot = function() return true, "anchor" end

math.randomseed(198)
for _, file in ipairs({
    "GenerationPerformance.lua", "SupportProfileIdentity.lua", "SupportProfile.lua", "SupportBudget.lua", "SupportRoleResolver.lua", "SupportScoring.lua", "SupportBeam.lua", "SupportWorker.lua",
    "SupportRerollLaunch.lua", "SupportRerollFoundation.lua", "SupportRerollScheduling.lua", "SupportRerollScoring.lua", "SupportRerollWorker.lua", "SupportRerollLegacy.lua", "SupportReroll.lua",
}) do dofile("Core/Wardrobe/" .. file) end
clock = 0
function P.GenerationNowMilliseconds() clock = clock + 0.04 return clock end

local before = {}; for slot, id in pairs(state.selections) do before[slot] = id end
local ok, message, asynchronous = W.RerollSlot("WAIST")
assert(ok and asynchronous, "support reroll must start asynchronously")
assert(state.selections.WAIST == before.WAIST, "target changed before cooperative worker completed")
local frames = 0
while #timerQueue > 0 do
    frames = frames + 1; assert(frames < 10000, "support reroll worker timed out")
    local callback = table.remove(timerQueue, 1); callback()
end
assert(completion and completion.success, "support reroll did not complete successfully")
assert(state.selections.WAIST ~= before.WAIST, "target appearance did not change")
for slot, id in pairs(before) do if slot ~= "WAIST" then assert(state.selections[slot] == id, "unrelated slot changed: " .. slot) end end
local stats = P.lastSupportDiagnostics
assert(stats.poolSizes.WAIST == 32, "prepared pool must be capped at 32")
assert(stats.shortlistSize <= 6, "final shortlist must be capped at 6")
assert(completion.performance.steps > 1, "reroll must span cooperative frames")
assert((completion.performance.maxStepMs or 0) < 8, "synthetic worker slice exceeded 8 ms")
assert(not completion.performance.phaseStats.rerollSlot, "monolithic rerollSlot phase must not return")
assert(not completion.performance.phaseStats.rerollStateCapture, "legacy synchronous state-capture phase must not return")
for _, phase in ipairs({ "rerollLaunchManifest", "rerollAnchorSnapshotReuse", "rerollStateMaterialization", "rerollDiagnosticIdentity", "rerollAnchorSummary", "rerollStyleContextInit", "rerollStyleContextSeed", "rerollEligibilityContext", "rerollSupportSummaryFoundation", "rerollCacheScalarSnapshot", "rerollProfileReuse", "rerollLedgerReconstruction", "rerollFixedContextCommitments", "rerollCandidatePreparation", "rerollSourceValidation", "rerollEligibility", "rerollCandidateScoring", "rerollNeighborScoring", "rerollBridgeScoring", "rerollBudgetEvaluation", "rerollShortlistSelection", "rerollStateCommit" }) do
    assert(completion.performance.phaseStats[phase], "missing cooperative reroll phase " .. phase)
end
print(string.format("PASS v1.9.0.8 support reroll worker: %d frames, pool %d, shortlist %d, max %.2f ms", frames, stats.poolSizes.WAIST, stats.shortlistSize, completion.performance.maxStepMs or 0))
