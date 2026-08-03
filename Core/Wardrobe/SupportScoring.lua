local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local T = QC.ZoneStyle and QC.ZoneStyle.Traveler

P.SUPPORT_SLOT_ROLES = P.SUPPORT_SLOT_ROLES or {
    WAIST = "Chest ↔ Legs bridge", HANDS = "Chest ↔ Weapon bridge", FEET = "Lower silhouette continuity",
    HEAD = "Chest ↔ Shoulders identity", BACK = "Silhouette and motif completion", WRIST = "Hands ↔ Chest continuity",
    SHIRT = "Chest ↔ Waist underlayer", TABARD = "Chest ↔ Legs overlay",
}
P.SUPPORT_NEIGHBORS = {
    WAIST = { "CHEST", "LEGS", "SHIRT", "TABARD" }, HANDS = { "CHEST", "WEAPON", "WRIST" },
    FEET = { "LEGS" }, HEAD = { "CHEST", "SHOULDER", "BACK" }, BACK = { "CHEST", "SHOULDER", "HEAD" },
    WRIST = { "HANDS", "CHEST" }, SHIRT = { "CHEST", "WAIST" }, TABARD = { "CHEST", "LEGS" },
}

local supportSlotKeys = {}
for _, slotKey in ipairs(P.SUPPORT_SLOT_ORDER or {}) do supportSlotKeys[slotKey] = true end

P.SUPPORT_BRIDGES = P.SUPPORT_BRIDGES or {
    WAIST = { "CHEST", "LEGS" }, HANDS = { "CHEST", "WEAPON" }, FEET = { "LEGS" },
    HEAD = { "CHEST", "SHOULDER" }, BACK = { "CHEST", "SHOULDER" }, WRIST = { "HANDS", "CHEST" },
    SHIRT = { "CHEST", "WAIST" }, TABARD = { "CHEST", "LEGS" },
}

local function Clamp(value, low, high)
    value = tonumber(value) or 0
    if value < low then return low end
    if value > high then return high end
    return value
end

local function VisualIdentity(source)
    return tostring(source and (source.visualID or source.sourceID or source.itemID) or "")
end

local function SelectedSource(state, slotKey)
    if slotKey == "WEAPON" then
        for _, key in ipairs(P.MAIN_WEAPON_SLOT_KEYS or {}) do
            local sourceID = state.selections and state.selections[key]
            if sourceID then return P.GetSourceByID(key, sourceID), key end
        end
        local sourceID = state.selections and state.selections.OFF_HAND
        return sourceID and P.GetSourceByID("OFF_HAND", sourceID) or nil, "OFF_HAND"
    end
    local sourceID = state.selections and state.selections[slotKey]
    return sourceID and P.GetSourceByID(slotKey, sourceID) or nil, slotKey
end

local function Pair(leftDescriptor, rightDescriptor)
    if not leftDescriptor or not rightDescriptor then return nil end
    return T and T.GetPairCohesion and T.GetPairCohesion(leftDescriptor, rightDescriptor) or 0.5
end

local function DescriptorForSource(source, slotKey)
    if not source then return nil end
    return QC.ZoneStyle and QC.ZoneStyle.GetTravelerDescriptor and QC.ZoneStyle.GetTravelerDescriptor(source, P.slotByKey[slotKey]) or nil
end

local function NodeSource(node, state, slotKey, profile)
    local mask = profile and profile.activeAnchorMask
    if slotKey == "WEAPON" or slotKey == "CHEST" or slotKey == "LEGS" or slotKey == "SHOULDER" then
        if not P.IsAnchorActive(mask, slotKey) then return nil end
        local source, actualKey = P.GetActiveAnchorSource(mask, state, slotKey)
        return source, DescriptorForSource(source, actualKey)
    end
    if state and state.hidden and state.hidden[slotKey] then return nil end
    local candidate = node and node.selected and node.selected[slotKey]
    if candidate then return candidate.source, candidate.descriptor end
    if supportSlotKeys[slotKey] and not (state and state.locks and state.locks[slotKey]) then return nil end
    local source, actualKey = SelectedSource(state, slotKey)
    return source, DescriptorForSource(source, actualKey)
end

local function NeighborScore(candidate, node, state, slotKey, profile)
    local total, count = 0, 0
    for _, neighborKey in ipairs(P.SUPPORT_NEIGHBORS[slotKey] or {}) do
        local _, descriptor = NodeSource(node, state, neighborKey, profile)
        local score = Pair(candidate.descriptor, descriptor)
        if score then total, count = total + score, count + 1 end
    end
    return count > 0 and total / count or candidate.profileFit
end

local function BridgeScore(candidate, node, state, slotKey, profile)
    local resolved = P.ResolveSupportRole and P.ResolveSupportRole(slotKey, profile and profile.activeAnchorMask) or nil
    local targets = resolved and resolved.bridgeTargets or P.SUPPORT_BRIDGES[slotKey] or {}
    local descriptors, labels = {}, {}
    for _, targetKey in ipairs(targets) do
        local _, descriptor = NodeSource(node, state, targetKey, profile)
        if descriptor then descriptors[#descriptors + 1] = descriptor labels[#labels + 1] = targetKey end
    end
    if #descriptors == 0 then return 0, nil, nil, nil end
    local candidateTotal = 0
    for _, descriptor in ipairs(descriptors) do candidateTotal = candidateTotal + (Pair(candidate.descriptor, descriptor) or 0.5) end
    local after = candidateTotal / #descriptors
    local before = #descriptors > 1 and (Pair(descriptors[1], descriptors[2]) or 0.5) or 0.5
    return math.max(0, after - before), table.concat(labels, " ↔ "), before, after, resolved and resolved.role
end

local function OutlierState(profileFit, visualImpact)
    if visualImpact >= 0.55 and profileFit < 0.45 then return "OUTLIER" end
    if visualImpact >= 0.45 and profileFit < 0.58 then return "LOUD_ACCENT" end
    if visualImpact >= 0.32 and profileFit < 0.66 then return "ACCENT" end
    return "NORMAL"
end

function P.BuildSupportCandidate(source, definition, job, profile, currentSourceID, allowIncoherent)
    if not source or not definition then return nil end
    local style = job.styleEngine
    local coherenceScore, coherent, coherenceReason = 0.5, true, nil
    if style and style.GetSourceCoherence then coherenceScore, coherent, coherenceReason = style.GetSourceCoherence(source, job.styleContext) end
    if coherent == false and not allowIncoherent then return nil end
    local baseScore, reasons = 10, {}
    if style and style.ScoreSource then baseScore, reasons = style.ScoreSource(source, definition, job.styleMode, job.styleContext, coherenceScore, coherent, coherenceReason) end
    local profileFit, components, descriptor = P.GetSupportProfileFit(source, definition, profile)
    local profileDistance = P.GetSupportProfileDistance and P.GetSupportProfileDistance(components, profile) or (1 - profileFit)
    local prominence = T and T.SLOT_VISIBILITY_WEIGHTS and T.SLOT_VISIBILITY_WEIGHTS[definition.key] or 0.4
    local visualImpact = (descriptor and descriptor.loudness or 0.1) * prominence
    local allowance = P.GetSupportSlotAllowance(definition.key)
    local mismatchCost = profileDistance * (allowance * 1.4 + prominence * 0.8)
    local repeatPenalty = currentSourceID and VisualIdentity(source) == tostring(currentSourceID) and prominence * 5 or 0
    local outlierState = OutlierState(profileFit, visualImpact)
    local outlierPenalty = outlierState == "OUTLIER" and 28 or (outlierState == "LOUD_ACCENT" and 10 or 0)
    local preliminaryScore = (tonumber(baseScore) or 0) + profileFit * 42 - mismatchCost * 6 - repeatPenalty - outlierPenalty
    local randomValue = math.max(0.000001, math.random())
    return {
        source = source, definition = definition, slotKey = definition.key, descriptor = descriptor,
        baseScore = tonumber(baseScore) or 0, scoreReasons = reasons, profileFit = profileFit,
        profileComponents = components, profileDistance = profileDistance, prominence = prominence, visualImpact = visualImpact,
        mismatchCost = mismatchCost, repeatPenalty = repeatPenalty, outlierState = outlierState,
        preliminaryScore = preliminaryScore, poolPriority = preliminaryScore + math.log(randomValue) * 2,
        diversityKey = table.concat({ descriptor and descriptor.dominantMaterial or "?", descriptor and descriptor.dominantMotif or "?", descriptor and descriptor.dominantPalette or "?", VisualIdentity(source) }, ":"),
    }
end

function P.ScoreSupportCandidate(candidate, node, job, profile, remainingSlots, locked)
    local now = P.GenerationNowMilliseconds
    local record = P.RecordGenerationPhase
    local started = job and job.supportReroll and now and now() or nil
    local neighbor = NeighborScore(candidate, node, job.draft, candidate.slotKey, profile)
    if started and record then record(job, "rerollNeighborScoring", now() - started) end
    started = job and job.supportReroll and now and now() or nil
    local bridge, bridgeTarget, bridgeBefore, bridgeAfter, resolvedRole = BridgeScore(candidate, node, job.draft, candidate.slotKey, profile)
    if started and record then record(job, "rerollBridgeScoring", now() - started) end
    local accentBonus = candidate.outlierState == "ACCENT" and bridge >= 0.08 and 3 or 0
    local outlierPenalty = candidate.outlierState == "OUTLIER" and 28 or (candidate.outlierState == "LOUD_ACCENT" and 10 or 0)
    started = job and job.supportReroll and now and now() or nil
    local budget = P.EvaluateSupportBudget(node.budget, candidate.slotKey, candidate.mismatchCost, remainingSlots, locked)
    if started and record then record(job, "rerollBudgetEvaluation", now() - started) end
    local score = candidate.baseScore + candidate.profileFit * 35 + neighbor * 18 + bridge * 24 + accentBonus
        - candidate.mismatchCost * 6 - candidate.repeatPenalty - outlierPenalty - budget.pressurePenalty
    return {
        slotKey = candidate.slotKey, source = candidate.source, candidate = candidate,
        role = resolvedRole or P.SUPPORT_SLOT_ROLES[candidate.slotKey], profileFit = candidate.profileFit,
        neighborCohesion = neighbor, bridgeBonus = bridge * 24, bridgeTarget = bridgeTarget,
        bridgeBefore = bridgeBefore, bridgeAfter = bridgeAfter,
        bridgeImprovement = bridgeAfter and bridgeBefore and (bridgeAfter - bridgeBefore) > 0.005 or false,
        mismatchSpent = budget.cost,
        budgetState = budget.state, outlierState = candidate.outlierState,
        repeatPenalty = candidate.repeatPenalty, fallback = candidate.forceFallback == true, score = score,
        budgetEvaluation = budget, allowed = budget.allowed and candidate.outlierState ~= "OUTLIER",
    }
end

function P.SupportVisualIdentity(source)
    return VisualIdentity(source)
end
