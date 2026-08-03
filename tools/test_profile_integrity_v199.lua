QuestChronicle = { Wardrobe = { _Private = {}, slotDefinitions = {} }, ZoneStyle = { Traveler = {} } }
local QC, W, P, Z, T = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle.Traveler
for _, key in ipairs({ "CHEST", "LEGS", "SHOULDER", "ONE_HAND", "OFF_HAND", "HEAD" }) do
    local definition = { key = key, label = key }
    W.slotDefinitions[#W.slotDefinitions + 1] = definition
end
P.slotByKey = {}; for _, definition in ipairs(W.slotDefinitions) do P.slotByKey[definition.key] = definition end
P.MAIN_WEAPON_SLOT_KEYS = { "ONE_HAND" }

local sources = {}
local function Add(slotKey, id, value)
    local source = {
        slotKey = slotKey, sourceID = id, visualID = id, styleName = slotKey .. id,
        descriptor = {
            palette = { steel = value }, material = { plate = value }, finish = { military = value }, motifs = { frontier = value },
            confidence = { palette = 1, material = 1, finish = 1, motifs = 1, visualWeight = 1, provenance = 1 },
            visualWeight = 2.5, loudness = 0.2, expansionID = 1, setIDs = {},
            dominantPalette = "steel", dominantMaterial = "plate", dominantFinish = "military", dominantMotif = "frontier",
        },
    }
    sources[slotKey .. id] = source
    return source
end
local chest, legs, shoulder, weapon, head = Add("CHEST", 1, .90), Add("LEGS", 2, .86), Add("SHOULDER", 3, .84), Add("ONE_HAND", 4, .82), Add("HEAD", 5, .80)
function P.GetSourceByID(slotKey, sourceID) return sources[slotKey .. sourceID] end
function P.FindSourceByVisualID(slotKey, visualID) return sources[slotKey .. visualID] end
function Z.GetTravelerDescriptor(source) return source and source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS = { CHEST = 1, LEGS = .8, SHOULDER = 1, ONE_HAND = .9, HEAD = .9 }
function T.GetPairCohesion(left, right)
    local a, b = left.palette.steel or 0, right.palette.steel or 0
    local score = 1 - math.abs(a - b)
    return score, { palette = score, material = score, finish = score, visualWeight = score, motif = score, provenance = .78 }
end

dofile("Core/Wardrobe/SupportProfileIdentity.lua")
dofile("Core/Wardrobe/SupportProfile.lua")
dofile("Core/Wardrobe/SupportBudget.lua")
dofile("Core/Wardrobe/SupportScoring.lua")
dofile("Core/Wardrobe/GenerationPerformance.lua")

local state = {
    selections = { CHEST = chest.sourceID, LEGS = legs.sourceID, SHOULDER = shoulder.sourceID, ONE_HAND = weapon.sourceID },
    selectionVisuals = { CHEST = chest.visualID, LEGS = legs.visualID, SHOULDER = shoulder.visualID, ONE_HAND = weapon.visualID },
    hidden = { SHOULDER = true }, locks = {},
}
local skeleton = { components = {
    { slotKey = "CHEST", sourceID = 1, visualID = 1 },
    { slotKey = "LEGS", sourceID = 2, visualID = 2 },
    { slotKey = "SHOULDER", sourceID = 3, visualID = 3, hidden = true },
    { slotKey = "ONE_HAND", sourceID = 4, visualID = 4 },
} }
local mask = P.BuildActiveAnchorMask(state, skeleton)
local profile = P.BuildContextualSupportProfile(state, { activeAnchorMask = mask, profileSourceReportID = "ANCHOR-1" })
assert(profile.activeAnchorCount == 3, "hidden Shoulder must not enter the initial profile")
assert(profile.activeAnchorMask.SHOULDER.state == "HIDDEN", "canonical mask lost hidden Shoulder state")
local snapshot = P.ExportContextualSupportProfile(profile)
local profileID = snapshot.profileID

-- Simulate the v1.9.0.8 drift: the mutable hidden map forgets Shoulders while
-- the canonical lineage mask remains correct.
state.activeAnchorMask = P.CopySupportProfileValue(mask)
state.activeAnchorMask.SHOULDER.state = "ACTIVE" -- stale mutable state must lose to the explicit anchor snapshot
state.contextualSupportProfile = P.CopySupportProfileValue(snapshot)
state.hidden.SHOULDER = nil
local reused, resolution = P.ResolveContextualSupportProfile(snapshot, state, skeleton, "ANCHOR-1")
assert(resolution.reused and not resolution.repaired, "healthy immutable profile should be reused")
assert(reused.profileID == profileID, "profile identity drifted across support-only work")
assert(reused.activeAnchorCount == 3 and reused.activeAnchorMask.SHOULDER.state == "HIDDEN", "hidden Shoulder returned to reused profile")

local job = { draft = state, styleEngine = { GetSourceCoherence = function() return .8, true end, ScoreSource = function() return 10, {} end }, styleMode = "TRAVELER", styleContext = {} }
local candidate = P.BuildSupportCandidate(head, P.slotByKey.HEAD, job, reused)
local decision = P.ScoreSupportCandidate(candidate, { selected = {}, budget = P.CreateSupportBudget(state, { "HEAD" }) }, job, reused, {}, false)
assert(decision.bridgeTarget == "CHEST", "Head scoring must omit hidden Shoulders from relationship endpoints")
assert(not tostring(decision.bridgeTarget):find("SHOULDER", 1, true), "hidden Shoulder earned a bridge endpoint")

local repaired, repair = P.ResolveContextualSupportProfile({ version = 1 }, state, skeleton, "ANCHOR-1")
assert(repair.repaired and repair.migrated, "legacy profile should be repaired once")
assert(repaired.activeAnchorCount == 3 and repaired.activeAnchorMask.SHOULDER.state == "HIDDEN", "legacy repair used a noncanonical mask")

local perf = P.BuildGenerationPerformance({
    supportReroll = true, startedAtMs = 0, steps = 11, maxStepMs = 2.9, preWorkerPreparationMs = 7.1,
    phaseStats = {
        rerollStateCapture = { calls = 1, totalMs = 7.1, maxMs = 7.1 },
        rerollCandidatePreparation = { calls = 32, totalMs = 12, maxMs = 2.7 },
        rerollCandidateScoring = { calls = 32, totalMs = 4, maxMs = .3 },
    },
}, 200)
assert(perf.preWorkerPreparationMs == 7.1, "pre-worker timing was not preserved")
assert(perf.longestWorkerSliceMs == 2.9, "cooperative worker slice changed")
assert(perf.largestCooperativeCallPhase == "rerollCandidatePreparation" and perf.largestCooperativeCallMs == 2.7, "cooperative timing domain selected the wrong call")
print(string.format("PASS v1.9.0.9 profile integrity: %s reused with %d anchors, hidden Shoulder excluded, pre-worker %.1f ms / cooperative %.1f ms", profileID, reused.activeAnchorCount, perf.preWorkerPreparationMs, perf.longestWorkerSliceMs))
