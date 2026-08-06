QuestChronicle = {
    Wardrobe = { _Private = {} },
    Generation = {},
}
local QC = QuestChronicle
local P = QC.Wardrobe._Private
P.ANCHOR_SLOT_ORDER = { "CHEST", "LEGS", "SHOULDER" }
P.ANCHOR_BEAM_WIDTH, P.ANCHOR_FINAL_SHORTLIST, P.ANCHOR_FINAL_SCORE_WINDOW = 32, 6, 28
P.BuildAnchorCandidate = function(source) return { source = source, baseScore = 10 } end
P.ScoreAnchorRelationship = function() return 2, 0.75, { palette = 1 }, false end
P.ScoreWeaponBundleForAnchor = function() return { score = 33 } end
P.BuildAnchorNoveltyContext = function() return { available = true } end
P.EvaluateAnchorNovelty = function() return { class = "MEANINGFULLY_NEW", adjustedScore = 10 } end
local zonePolicy = {
    GetAnchorSlots = function() return { "CHEST", "LEGS", "SHOULDER", "WEAPON_BUNDLE" } end,
    GetAnchorSearchConfiguration = function() return { beamWidth = 24, finalShortlist = 4, scoreWindow = 20 } end,
    EvaluateAnchorCandidate = function(source) return { source = source, baseScore = 18, policy = true } end,
    ScoreAnchorPair = function() return 5, 0.8, { palette = 0.9 }, false, { visualBonus = 2, zonePairBonus = 3 } end,
    ScoreAnchorSkeleton = function() return { score = 55 } end,
    BuildNoveltyReference = function() return { available = true, policy = true } end,
    ClassifyNovelty = function() return { class = "PARTIAL_CHANGE", adjustedScore = 9 } end,
}
QC.Generation.GetGenerationMode = function(modeID)
    if modeID == "ZONE_NATIVE" then return { capabilities = { zoneAnchorPolicy = true }, anchorPolicy = zonePolicy } end
    return { capabilities = { zoneAnchorPolicy = false } }
end
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_anchor_policy_bridge_v1113.lua$", "")
assert(loadfile(root .. "Core/Wardrobe/AnchorPolicyBridge.lua"))()

local job = { requestedStyleMode = "ZONE_NATIVE", styleMode = "ZONE_NATIVE" }
P.AttachGenerationModePolicy(job)
assert(P.ValidateAttachedAnchorPolicy(job) == true, "Zone policy validation failed")
assert(#P.GetAnchorSlotsForJob(job) == 3, "logical weapon pseudo-slot leaked into armor slots")
local config = P.GetAnchorSearchConfigurationForJob(job)
assert(config.beamWidth == 24 and config.finalShortlist == 4 and config.scoreWindow == 20, "policy search configuration was ignored")
assert(P.EvaluateAnchorCandidateForJob(job, { sourceID = 1 }, {}, {}, false).policy == true, "candidate callback was not authoritative")
local bonus, pairScore, _, hardClash, details = P.ScoreAnchorRelationshipForJob(job, {}, {})
assert(bonus == 5 and pairScore == 0.8 and hardClash == false and details.zonePairBonus == 3, "pair callback lost multiple return values")
assert(P.ScoreAnchorSkeletonForJob(job, {}, {}, {}).score == 55, "skeleton callback was not authoritative")
assert(P.BuildAnchorNoveltyReferenceForJob(job, {}).policy == true, "novelty reference callback was not used")
assert(P.ClassifyAnchorNoveltyForOptions({}, {}, { job = job }).class == "PARTIAL_CHANGE", "novelty callback was not used")

local legacy = { requestedStyleMode = "CLASS_FANTASY", styleMode = "CLASS_FANTASY" }
P.AttachGenerationModePolicy(legacy)
assert(P.EvaluateAnchorCandidateForJob(legacy, { sourceID = 2 }, {}, {}, false).baseScore == 10, "legacy compatibility helper changed")
local legacyBonus, legacyPair = P.ScoreAnchorRelationshipForJob(legacy, {}, {})
assert(legacyBonus == 2 and legacyPair == 0.75, "legacy pair callback changed")

print("PASS v1.11.3 anchor-policy bridge: Zone authority and Class/Echo compatibility helpers")
