local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone

Zone.ANCHOR_POLICY_FORMAT = Zone.ANCHOR_POLICY_FORMAT or 1
Zone.ANCHOR_POLICY_ID = Zone.ANCHOR_POLICY_ID or "ZONE_ANCHOR_POLICY_V1"
Zone.ANCHOR_POLICY_AUTHORITY = Zone.ANCHOR_POLICY_AUTHORITY or "ACTIVE"

Zone.ANCHOR_POLICY_CONSTANTS = {
    neutralAffinity = 0.35,
    affinityScale = 20.00,
    maximumBonus = 8.00,
    maximumPenalty = -6.00,
    confidenceFull = 0.65,
    maximumPairBonus = 4.00,
    pairScale = 6.00,
    slotMultipliers = {
        CHEST = 1.00,
        LEGS = 0.90,
        SHOULDER = 1.00,
        ONE_HAND = 1.10,
        TWO_HAND = 1.10,
        RANGED = 1.10,
        OFF_HAND = 1.10,
        WEAPON_BUNDLE = 1.10,
    },
}

local function Clamp(value, low, high)
    value = tonumber(value) or 0
    if value < low then return low end
    if value > high then return high end
    return value
end

local function Round(value, places)
    local scale = 10 ^ (places or 3)
    return math.floor((tonumber(value) or 0) * scale + 0.5) / scale
end

local function SlotMultiplier(slotKey)
    return Zone.ANCHOR_POLICY_CONSTANTS.slotMultipliers[slotKey] or 1
end

function Zone.ComputeAnchorEvidenceAdjustment(affinity, slotKey)
    affinity = type(affinity) == "table" and affinity or {}
    local classification = tostring(affinity.classification or "UNKNOWN")
    local confidence = Clamp(affinity.confidence, 0, 1)
    if classification == "UNKNOWN" or confidence <= 0 then
        return 0, {
            rawAdjustment = 0,
            boundedAdjustment = 0,
            confidenceFactor = 0,
            slotMultiplier = SlotMultiplier(slotKey),
            neutral = true,
        }
    end
    local constants = Zone.ANCHOR_POLICY_CONSTANTS
    local raw = ((tonumber(affinity.score) or 0) - constants.neutralAffinity) * constants.affinityScale
    local bounded = Clamp(raw, constants.maximumPenalty, constants.maximumBonus)
    local confidenceFactor = Clamp(confidence / constants.confidenceFull, 0, 1)
    local multiplier = SlotMultiplier(slotKey)
    local final = bounded * confidenceFactor * multiplier
    return final, {
        rawAdjustment = raw,
        boundedAdjustment = bounded,
        confidenceFactor = confidenceFactor,
        slotMultiplier = multiplier,
        neutral = false,
    }
end

function Zone.ApplyAnchorEvidence(candidate, affinity, definition, fixed)
    if not candidate then return nil end
    affinity = type(affinity) == "table" and affinity or {}
    local slotKey = definition and definition.key or candidate.slotKey
    local legacy = tonumber(candidate.baseScore) or 0
    local adjustment, calculation = Zone.ComputeAnchorEvidenceAdjustment(affinity, slotKey)
    local finalScore = legacy + adjustment
    candidate.legacyBaseScore = legacy
    candidate.baseScore = finalScore
    candidate.weight = math.max(1, finalScore + 4) ^ 2
    if candidate.poolRandomValue then
        candidate.poolPriority = math.log(math.max(0.000001, candidate.poolRandomValue)) / candidate.weight
    end
    candidate.anchorPolicy = {
        policyID = Zone.ANCHOR_POLICY_ID,
        policyFormat = Zone.ANCHOR_POLICY_FORMAT,
        authority = Zone.ANCHOR_POLICY_AUTHORITY,
        legacyRelevance = legacy,
        zoneAffinity = tonumber(affinity.score) or 0,
        zoneConfidence = tonumber(affinity.confidence) or 0,
        zoneClassification = affinity.classification or "UNKNOWN",
        zoneAdjustment = adjustment,
        slotMultiplier = calculation.slotMultiplier,
        rawAdjustment = calculation.rawAdjustment,
        boundedAdjustment = calculation.boundedAdjustment,
        confidenceFactor = calculation.confidenceFactor,
        finalRelevance = finalScore,
        favorite = false,
        locked = fixed == true,
        reasons = {},
    }
    local details = candidate.anchorPolicy
    if calculation.neutral then
        details.reasons[#details.reasons + 1] = "Unknown or zero-confidence Zone evidence was neutral."
    elseif adjustment > 0 then
        details.reasons[#details.reasons + 1] = string.format("%s local evidence added %.2f.", tostring(details.zoneClassification), adjustment)
    elseif adjustment < 0 then
        details.reasons[#details.reasons + 1] = string.format("%s evidence applied a bounded %.2f adjustment.", tostring(details.zoneClassification), adjustment)
    else
        details.reasons[#details.reasons + 1] = "Zone evidence was centered at the neutral preference point."
    end
    candidate.scoreReasons = candidate.scoreReasons or {}
    if #candidate.scoreReasons < 4 then
        candidate.scoreReasons[#candidate.scoreReasons + 1] = string.format(
            "Zone: %s %+.2f",
            tostring(details.zoneClassification), adjustment
        )
    end
    return candidate
end

local function CandidateSupport(candidate)
    local details = candidate and candidate.anchorPolicy
    if not details then return 0 end
    local classification = tostring(details.zoneClassification or "UNKNOWN")
    local score = tonumber(details.zoneAffinity) or 0
    local confidence = tonumber(details.zoneConfidence) or 0
    if classification == "UNKNOWN" or classification == "PARTIAL_EVIDENCE" then return 0 end
    if score < Zone.ANCHOR_POLICY_CONSTANTS.neutralAffinity or confidence <= 0 then return 0 end
    return Clamp(score, 0, 1) * Clamp(confidence, 0, 1)
end

function Zone.ComputeAnchorPairSupport(left, right)
    local leftSupport = CandidateSupport(left)
    local rightSupport = CandidateSupport(right)
    local shared = math.min(leftSupport, rightSupport)
    local bonus = Clamp(
        shared * Zone.ANCHOR_POLICY_CONSTANTS.pairScale,
        0,
        Zone.ANCHOR_POLICY_CONSTANTS.maximumPairBonus
    )
    return bonus, {
        leftSupport = leftSupport,
        rightSupport = rightSupport,
        sharedLocalSupport = shared,
        zonePairBonus = bonus,
    }
end

function Zone.BuildSelectedAnchorPolicySummary(selected, poolSummaries, job)
    local rows = {}
    local function AddCandidate(slotKey, candidate)
        local details = candidate and candidate.anchorPolicy
        if not details then return end
        rows[#rows + 1] = {
            slotKey = slotKey,
            sourceID = candidate.source and candidate.source.sourceID,
            visualID = candidate.source and candidate.source.visualID,
            name = candidate.source and (candidate.source.styleName or candidate.source.name or candidate.source.itemName),
            legacyRelevance = details.legacyRelevance,
            affinity = details.zoneAffinity,
            confidence = details.zoneConfidence,
            classification = details.zoneClassification,
            adjustment = details.zoneAdjustment,
            finalRelevance = details.finalRelevance,
            favorite = details.favorite == true,
            locked = candidate.locked == true or details.locked == true,
        }
    end
    for slotKey, candidate in pairs(selected and selected.armorNode and selected.armorNode.sourceBySlot or {}) do
        AddCandidate(slotKey, candidate)
    end
    local logicalSeen = {}
    local logicalWeapons = {}
    for _, candidate in ipairs(selected and selected.weaponCandidates or {}) do
        local visualKey = tostring(candidate.source and (candidate.source.visualID or candidate.source.sourceID) or "")
        if visualKey ~= "" and not logicalSeen[visualKey] then
            logicalSeen[visualKey] = true
            AddCandidate(candidate.slotKey or "WEAPON", candidate)
            logicalWeapons[#logicalWeapons + 1] = {
                slotKey = candidate.slotKey,
                sourceID = candidate.source and candidate.source.sourceID,
                visualID = candidate.source and candidate.source.visualID,
                name = candidate.source and (candidate.source.styleName or candidate.source.name or candidate.source.itemName),
                affinity = candidate.anchorPolicy and candidate.anchorPolicy.zoneAffinity or 0,
                confidence = candidate.anchorPolicy and candidate.anchorPolicy.zoneConfidence or 0,
                adjustment = candidate.anchorPolicy and candidate.anchorPolicy.zoneAdjustment or 0,
            }
        end
    end
    table.sort(rows, function(a, b) return tostring(a.slotKey) < tostring(b.slotKey) end)
    return {
        policyID = Zone.ANCHOR_POLICY_ID,
        policyFormat = Zone.ANCHOR_POLICY_FORMAT,
        authority = Zone.ANCHOR_POLICY_AUTHORITY,
        supportPolicy = "LEGACY",
        snapshotFingerprint = job and job.modeContextFingerprint or nil,
        contextStaleAtCommit = job and job.zoneContextStaleAtCommit == true or false,
        currentFingerprint = job and job.zoneContextCurrentFingerprint or nil,
        fallback = job and job.zoneAnchorPolicyFallback or nil,
        fallbackReason = job and job.zoneAnchorPolicyFallbackReason or nil,
        selected = rows,
        pools = poolSummaries or {},
        armorPairSupport = selected and selected.armorNode and tonumber(selected.armorNode.zonePairSupportBonus) or 0,
        weaponPairSupport = selected and tonumber(selected.zonePairSupportBonus) or 0,
        visualArmorRelationshipBonus = selected and selected.armorNode and tonumber(selected.armorNode.visualRelationshipBonus) or 0,
        visualWeaponRelationshipBonus = selected and tonumber(selected.visualRelationshipBonus) or 0,
        logicalWeapons = logicalWeapons,
        linkedVisualDeduplicated = selected and selected.linkedVisualDeduplicated == true or false,
        routeFamily = selected and selected.draft and selected.draft.lastWeaponRoute and selected.draft.lastWeaponRoute.routeFamily or nil,
    }
end

function Zone.GetAnchorPolicyStatus()
    return {
        policyID = Zone.ANCHOR_POLICY_ID,
        policyFormat = Zone.ANCHOR_POLICY_FORMAT,
        authority = Zone.ANCHOR_POLICY_AUTHORITY,
        supportPolicy = "LEGACY",
        constants = {
            neutralAffinity = Round(Zone.ANCHOR_POLICY_CONSTANTS.neutralAffinity),
            affinityScale = Round(Zone.ANCHOR_POLICY_CONSTANTS.affinityScale),
            maximumBonus = Round(Zone.ANCHOR_POLICY_CONSTANTS.maximumBonus),
            maximumPenalty = Round(Zone.ANCHOR_POLICY_CONSTANTS.maximumPenalty),
            confidenceFull = Round(Zone.ANCHOR_POLICY_CONSTANTS.confidenceFull),
            maximumPairBonus = Round(Zone.ANCHOR_POLICY_CONSTANTS.maximumPairBonus),
        },
    }
end
