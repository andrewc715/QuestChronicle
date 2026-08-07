local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local ANCHOR_PHASES = {
    "anchorCandidateEra", "anchorCandidateMetadata", "anchorCandidateSetIDs", "anchorCandidateStyleSignals",
    "anchorCandidateCoherence", "anchorCandidateLegacyScore", "anchorCandidateDescriptor", "anchorCandidateRandom",
    "anchorCandidateTracking", "anchorCandidateAffinity", "anchorCandidatePolicy", "anchorCandidateFinalize",
    "anchorWeaponCandidateScoring", "anchorWeaponRelationship",
}

local SUPPORT_BRIDGE_PHASES = {
    "supportCandidateBridgeTarget", "supportCandidateBridgeDescriptor", "supportCandidateBridgePair",
    "supportCandidateBridgeAfter", "supportCandidateBridgeBaseline", "supportCandidateBridgeFinalize",
}

local LABELS = {
    anchorCandidateEra = "Anchor candidate era", anchorCandidateMetadata = "Anchor candidate metadata",
    anchorCandidateSetIDs = "Anchor candidate set IDs", anchorCandidateStyleSignals = "Anchor candidate style signals",
    anchorCandidateCoherence = "Anchor candidate coherence", anchorCandidateLegacyScore = "Anchor candidate legacy score",
    anchorCandidateDescriptor = "Anchor candidate descriptor", anchorCandidateRandom = "Anchor candidate random boundary",
    anchorCandidateTracking = "Anchor candidate tracking", anchorCandidateAffinity = "Anchor candidate Zone affinity",
    anchorCandidatePolicy = "Anchor candidate Zone policy", anchorCandidateFinalize = "Anchor candidate finalize",
    anchorWeaponCandidateScoring = "Anchor weapon candidate scoring", anchorWeaponRelationship = "Anchor weapon relationship",
    supportCandidateNeighborTarget = "Support neighbor target", supportCandidateNeighborDescriptor = "Support neighbor descriptor",
    supportCandidateNeighborPair = "Support neighbor pair", supportCandidateNeighborFinalize = "Support neighbor finalize",
    supportCandidateBridgeTarget = "Support bridge target", supportCandidateBridgeDescriptor = "Support bridge descriptor",
    supportCandidateBridgePair = "Support bridge pair", supportCandidateBridgeAfter = "Support bridge after",
    supportCandidateBridgeBaseline = "Support bridge baseline", supportCandidateBridgeFinalize = "Support bridge finalize",
}

for key, label in pairs(LABELS) do
    P.GENERATION_PHASE_LABELS[key] = label
    P.GENERATION_PHASE_SHORT_LABELS[key] = label
end

local function Largest(phaseStats, keys)
    local bestKey, bestMs = nil, 0
    for _, key in ipairs(keys) do
        local current = tonumber(phaseStats and phaseStats[key] and phaseStats[key].maxMs) or 0
        if current > bestMs then bestKey, bestMs = key, current end
    end
    return bestKey, bestMs
end

function P.BuildScoringPotholeDiagnostics(job, phaseStats)
    if not job then return nil end
    local anchorKey, anchorMs = Largest(phaseStats, ANCHOR_PHASES)
    local bridgeKey, bridgeMs = Largest(phaseStats, SUPPORT_BRIDGE_PHASES)
    return {
        anchor = {
            substeps = tonumber(job.anchorCandidateSubsteps) or 0, completions = tonumber(job.anchorCandidateCompletions) or 0,
            apiOperations = tonumber(job.anchorCandidateAPIOperations) or 0, admissionDeferrals = tonumber(job.anchorCandidateAdmissionDeferrals) or 0,
            metadataAPICalls = tonumber(job.anchorCandidateMetadataAPICalls) or 0, setAPICalls = tonumber(job.anchorCandidateSetAPICalls) or 0,
            trackingAPICalls = tonumber(job.anchorCandidateTrackingAPICalls) or 0, preparedMetadataHits = tonumber(job.anchorCandidatePreparedMetadataHits) or 0,
            preparedSetHits = tonumber(job.anchorCandidatePreparedSetHits) or 0, preparedTrackingHits = tonumber(job.anchorCandidatePreparedTrackingHits) or 0,
            largestSubphase = anchorKey, largestSubphaseMs = anchorMs,
        },
        supportBridge = {
            targetResolutions = tonumber(job.supportBridgeTargetResolutions) or 0, descriptorHits = tonumber(job.supportBridgeDescriptorHits) or 0,
            descriptorFallbacks = tonumber(job.supportBridgeDescriptorFallbacks) or 0, candidatePairs = tonumber(job.supportBridgeCandidatePairs) or 0,
            baselinePairs = tonumber(job.supportBridgeBaselinePairs) or 0, admissionDeferrals = tonumber(job.supportBridgeAdmissionDeferrals) or 0,
            descriptorDeferrals = tonumber(job.supportBridgeDescriptorDeferrals) or 0, largestSubphase = bridgeKey, largestSubphaseMs = bridgeMs,
        },
    }
end
