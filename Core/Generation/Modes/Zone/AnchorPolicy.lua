local QC = QuestChronicle
local Generation = QC.Generation
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle and ZoneStyle.Zone
local P = QC.Wardrobe and QC.Wardrobe._Private

local function SnapshotFor(job)
    return job and job.modeContext or nil
end

local function EvaluateCandidate(source, definition, styleMode, styleContext, fixed, job)
    local candidate = P.BuildAnchorCandidate(source, definition, styleMode, styleContext, fixed)
    if not candidate then return nil end
    if job and job.zoneAnchorPolicyFallback then
        candidate.anchorPolicy = {
            policyID = Zone.ANCHOR_POLICY_ID,
            policyFormat = Zone.ANCHOR_POLICY_FORMAT,
            authority = "FALLBACK",
            legacyRelevance = candidate.baseScore,
            zoneAffinity = 0,
            zoneConfidence = 0,
            zoneClassification = "UNKNOWN",
            zoneAdjustment = 0,
            slotMultiplier = 1,
            finalRelevance = candidate.baseScore,
            locked = fixed == true,
            reasons = { "Zone context was unavailable; the legacy score remained authoritative." },
        }
        return candidate
    end
    local snapshot = SnapshotFor(job)
    local affinity = Generation.ZoneAffinityPolicy and Generation.ZoneAffinityPolicy.AnalyzeAppearance
        and Generation.ZoneAffinityPolicy.AnalyzeAppearance(source, definition, snapshot) or nil
    candidate = Zone.ApplyAnchorEvidence(candidate, affinity, definition, fixed)
    if candidate and candidate.anchorPolicy and ZoneStyle.GetSourcePreference then
        candidate.anchorPolicy.favorite = ZoneStyle.GetSourcePreference(source, styleContext) == "favorite"
    end
    return candidate
end

local function ScorePair(left, right, job)
    local visualBonus, pairScore, components, hardClash = P.ScoreAnchorRelationship(left, right)
    if job and job.zoneAnchorPolicyFallback then
        return visualBonus, pairScore, components, hardClash, {
            visualBonus = visualBonus,
            zonePairBonus = 0,
            fallback = true,
        }
    end
    local zoneBonus, support = Zone.ComputeAnchorPairSupport(left, right)
    return visualBonus + zoneBonus, pairScore, components, hardClash, {
        visualBonus = visualBonus,
        zonePairBonus = zoneBonus,
        localSupport = support,
    }
end

Generation.ZoneAnchorPolicy = {
    policyID = Zone.ANCHOR_POLICY_ID,
    policyFormat = Zone.ANCHOR_POLICY_FORMAT,
    authority = Zone.ANCHOR_POLICY_AUTHORITY,
    GetAnchorSlots = function()
        return { "CHEST", "LEGS", "SHOULDER", "WEAPON_BUNDLE" }
    end,
    GetAnchorSearchConfiguration = function()
        return {
            beamWidth = P.ANCHOR_BEAM_WIDTH,
            finalShortlist = P.ANCHOR_FINAL_SHORTLIST,
            scoreWindow = P.ANCHOR_FINAL_SCORE_WINDOW,
        }
    end,
    EvaluateAnchorCandidate = EvaluateCandidate,
    ScoreAnchorPair = ScorePair,
    ScoreAnchorSkeleton = function(node, draft, styleMode, styleContext, job)
        return P.ScoreWeaponBundleForAnchor(node, draft, styleMode, styleContext, job)
    end,
    BuildNoveltyReference = function(state)
        return P.BuildAnchorNoveltyContext and P.BuildAnchorNoveltyContext(state) or nil
    end,
    ClassifyNovelty = function(entry, context)
        return P.EvaluateAnchorNovelty and P.EvaluateAnchorNovelty(entry, context) or nil
    end,
}
