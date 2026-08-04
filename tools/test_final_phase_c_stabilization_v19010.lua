QuestChronicle = { Wardrobe = { _Private = {}, slotDefinitions = {} }, ZoneStyle = { Traveler = {} } }
local QC, W, P, Z, T = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle.Traveler
for _, key in ipairs({ "HEAD", "SHOULDER", "BACK", "CHEST", "SHIRT", "TABARD", "WRIST", "HANDS", "WAIST", "LEGS", "FEET", "ONE_HAND", "OFF_HAND" }) do
    local definition = { key = key, label = key }
    W.slotDefinitions[#W.slotDefinitions + 1] = definition
end
P.slotByKey = {}; for _, definition in ipairs(W.slotDefinitions) do P.slotByKey[definition.key] = definition end
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
local function Add(slot, id, value)
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
local chest, legs, shoulder, weapon = Add("CHEST", 1, .90), Add("LEGS", 2, .86), Add("SHOULDER", 3, .84), Add("ONE_HAND", 4, .82)
local supportOrder = { "WAIST", "HANDS", "FEET", "HEAD", "BACK", "WRIST", "SHIRT", "TABARD" }
local current = {}
for index, slot in ipairs(supportOrder) do
    current[slot] = Add(slot, 1000 + index, .35)
    local count = slot == "BACK" and 70 or (slot == "WAIST" and 50 or 30)
    for candidateIndex = 1, count do Add(slot, index * 10000 + candidateIndex, .55 + ((candidateIndex % 20) / 50)) end
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
    if P.TouchPreviewRevision then P.TouchPreviewRevision(state) end
end
function P.RefreshGeneratedOutfitName(state) state.generatedName = "Final Stabilization" return state.generatedName end
function P.CreateStyleGenerationContext() return {} end
function P.GetGenerationCacheCounterSnapshot() return {} end
function P.BuildGenerationCachePerformance() return {} end

function Z.GetTravelerDescriptor(source) return source and source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS = { CHEST = 1, LEGS = .8, SHOULDER = 1, ONE_HAND = .9, WAIST = .5, HANDS = .65, FEET = .6, HEAD = .9, BACK = .55, WRIST = .25, SHIRT = .2, TABARD = .2 }
function T.GetPairCohesion(left, right)
    local score = 1 - math.abs((left.palette.steel or 0) - (right.palette.steel or 0))
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

local state = {
    selections = { CHEST = chest.sourceID, LEGS = legs.sourceID, SHOULDER = shoulder.sourceID, ONE_HAND = weapon.sourceID },
    selectionVisuals = { CHEST = chest.visualID, LEGS = legs.visualID, SHOULDER = shoulder.visualID, ONE_HAND = weapon.visualID },
    hidden = { SHOULDER = true, TABARD = true }, locks = {}, styleMode = "TRAVELER", supportRerollRevision = 0,
}
for _, slot in ipairs(supportOrder) do state.selections[slot] = current[slot].sourceID; state.selectionVisuals[slot] = current[slot].visualID end
P.EnsurePreviewState = function() return state end
W.RerollSlot = function() return true, "anchor" end

for _, file in ipairs({
    "GenerationPerformance.lua", "SupportProfileIdentity.lua", "SupportProfile.lua", "SupportBudget.lua", "SupportRoleResolver.lua", "SupportScoring.lua", "SupportBeam.lua", "SupportWorker.lua",
    "SupportRerollLaunch.lua", "SupportRerollFoundation.lua", "SupportRerollScheduling.lua", "SupportRerollScoring.lua", "SupportRerollWorker.lua", "SupportRerollLegacy.lua", "SupportReroll.lua",
}) do dofile("Core/Wardrobe/" .. file) end
clock = 0
function P.GenerationNowMilliseconds() clock = clock + 0.04 return clock end

local hiddenMask = P.BuildActiveAnchorMask(state)
assert(P.ResolveSupportRole("HEAD", hiddenMask).role == "Chest identity support", "hidden Shoulders leaked into Head role wording")
assert(P.ResolveSupportRole("BACK", hiddenMask).role == "Chest silhouette support", "hidden Shoulders leaked into Back role wording")
state.hidden.SHOULDER = nil; state.activeAnchorMask = nil
local visibleMask = P.BuildActiveAnchorMask(state)
assert(P.ResolveSupportRole("HEAD", visibleMask).role == "Chest ↔ Shoulders identity", "visible Shoulders lost Head endpoint")
state.hidden.SHOULDER = true; state.activeAnchorMask = nil

math.randomseed(1910)
local before = state.selections.HEAD
local ok, message, asynchronous = W.RerollSlot("HEAD")
assert(ok and asynchronous, "Head reroll did not start cooperatively")
assert(state.selections.HEAD == before, "Head changed before cooperative commit")
local frames = 0
while #timerQueue > 0 do
    frames = frames + 1; assert(frames < 10000, "support reroll worker timed out")
    table.remove(timerQueue, 1)()
end
assert(completion and completion.success, "Head reroll did not complete")
assert(state.selections.HEAD ~= before, "Head reroll did not replace the target")
local performance = completion.performance
assert((performance.synchronousLaunchPreparationMs or 99) <= .5, "synthetic launch manifest exceeded 0.5 ms")
assert(not performance.phaseStats.rerollStateCapture, "legacy monolithic state capture returned")
for _, phase in ipairs({ "rerollLaunchManifest", "rerollAnchorSnapshotReuse", "rerollStateMaterialization", "rerollDiagnosticIdentity", "rerollAnchorSummary", "rerollStyleContextInit", "rerollStyleContextSeed", "rerollEligibilityContext", "rerollSupportSummaryFoundation", "rerollCacheScalarSnapshot" }) do
    assert(performance.phaseStats[phase], "missing final-stabilization phase " .. phase)
end
local selectedDecision
for _, decision in ipairs(P.lastSupportDiagnostics.decisions or {}) do if decision.slotKey == "HEAD" and decision.targetRerolled then selectedDecision = decision end end
assert(selectedDecision and selectedDecision.role == "Chest identity support", "actual Head decision retained hidden-Shoulder role wording")
assert(selectedDecision.bridgeTarget == "CHEST", "hidden Shoulder entered actual Head relationship endpoints")

completion = nil
local waistBefore = state.selections.WAIST
ok, message, asynchronous = W.RerollSlot("WAIST")
assert(ok and asynchronous, "stale-state test did not launch")
P.TouchPreviewRevision(state)
while #timerQueue > 0 do table.remove(timerQueue, 1)() end
assert(completion and not completion.success and completion.message:find("cancelled", 1, true), "revision drift did not cancel the reroll")
assert(state.selections.WAIST == waistBefore, "stale reroll committed a mixed-state target")

print(string.format("PASS v1.9.0.10 final stabilization: %d frames, launch %.2f ms, hidden-anchor roles corrected, stale commit cancelled", frames, performance.synchronousLaunchPreparationMs or 0))
