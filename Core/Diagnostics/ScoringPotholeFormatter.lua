local QC = QuestChronicle
local D = QC.Diagnostics
local P = D._Private

function P.AddScoringPotholePerformanceLines(lines, performance)
    local potholes = performance and performance.scoringPotholes
    if not potholes then return end
    local anchor = potholes.anchor or {}
    local bridge = potholes.supportBridge or {}
    local labels = QC.Wardrobe and QC.Wardrobe._Private and QC.Wardrobe._Private.GENERATION_PHASE_LABELS or {}
    local function N(value) return tostring(math.floor((tonumber(value) or 0) + 0.5)) end
    lines[#lines + 1] = string.format("Anchor candidate scheduling: %s substeps • %s completions • API %s metadata/%s sets/%s tracking • prepared %s metadata/%s sets/%s tracking • %s admission deferrals",
        N(anchor.substeps), N(anchor.completions), N(anchor.metadataAPICalls), N(anchor.setAPICalls), N(anchor.trackingAPICalls),
        N(anchor.preparedMetadataHits), N(anchor.preparedSetHits), N(anchor.preparedTrackingHits), N(anchor.admissionDeferrals))
    lines[#lines + 1] = string.format("Largest anchor candidate subphase: %s %.2f ms",
        labels[anchor.largestSubphase] or tostring(anchor.largestSubphase or "Not recorded"), tonumber(anchor.largestSubphaseMs) or 0)
    lines[#lines + 1] = string.format("Support bridge scheduling: %s targets • %s descriptor hits • %s fallbacks • %s candidate pairs • %s baseline pairs • %s admission deferrals",
        N(bridge.targetResolutions), N(bridge.descriptorHits), N(bridge.descriptorFallbacks), N(bridge.candidatePairs), N(bridge.baselinePairs), N(bridge.admissionDeferrals))
    lines[#lines + 1] = string.format("Largest support bridge subphase: %s %.2f ms",
        labels[bridge.largestSubphase] or tostring(bridge.largestSubphase or "Not recorded"), tonumber(bridge.largestSubphaseMs) or 0)
end
