local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local T = QC.ZoneStyle and QC.ZoneStyle.Traveler

local supportSlotKeys = {}
for _, slotKey in ipairs(P.SUPPORT_SLOT_ORDER or {}) do supportSlotKeys[slotKey] = true end

local function Pair(leftDescriptor, rightDescriptor)
    if not leftDescriptor or not rightDescriptor then return nil end
    return T and T.GetPairCohesion and T.GetPairCohesion(leftDescriptor, rightDescriptor) or 0.5
end

local function DescriptorForSource(source, slotKey)
    if not source then return nil end
    return QC.ZoneStyle and QC.ZoneStyle.GetTravelerDescriptor
        and QC.ZoneStyle.GetTravelerDescriptor(source, P.slotByKey[slotKey]) or nil
end

local function SameSource(left, right)
    if not left or not right then return false end
    local leftSource, rightSource = tonumber(left.sourceID), tonumber(right.sourceID)
    if leftSource and rightSource and leftSource == rightSource then return true end
    local leftVisual, rightVisual = tonumber(left.visualID), tonumber(right.visualID)
    return leftVisual and rightVisual and leftVisual == rightVisual
end

local function ProfileDescriptor(profile, source, actualKey)
    for _, entry in ipairs(profile and profile.entries or {}) do
        if entry.descriptor and SameSource(entry.source, source) then
            if actualKey == nil or entry.slotKey == actualKey or SameSource(entry.source, source) then
                return entry.descriptor
            end
        end
    end
    return nil
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

local function ResolveNodeReference(work, slotKey)
    work.descriptorCache = work.descriptorCache or {}
    local cached = work.descriptorCache[slotKey]
    if cached then return cached end
    local state, node, profile = work.job.draft, work.node, work.profile
    local source, descriptor, actualKey
    local mask = profile and profile.activeAnchorMask
    if slotKey == "WEAPON" or slotKey == "CHEST" or slotKey == "LEGS" or slotKey == "SHOULDER" then
        if not P.IsAnchorActive(mask, slotKey) then
            cached = { source = false, descriptor = false, actualKey = slotKey }
        else
            source, actualKey = P.GetActiveAnchorSource(mask, state, slotKey)
            descriptor = ProfileDescriptor(profile, source, actualKey)
            cached = { source = source or false, descriptor = descriptor or false, actualKey = actualKey or slotKey }
        end
    elseif state and state.hidden and state.hidden[slotKey] then
        cached = { source = false, descriptor = false, actualKey = slotKey }
    else
        local selected = node and node.selected and node.selected[slotKey]
        if selected then
            cached = { source = selected.source or false, descriptor = selected.descriptor or false, actualKey = slotKey }
        elseif supportSlotKeys[slotKey] and not (state and state.locks and state.locks[slotKey]) then
            cached = { source = false, descriptor = false, actualKey = slotKey }
        else
            source, actualKey = SelectedSource(state, slotKey)
            cached = { source = source or false, descriptor = false, actualKey = actualKey or slotKey }
        end
    end
    work.descriptorCache[slotKey] = cached
    return cached
end

local function MaterializeReferenceDescriptor(work, slotKey)
    local ref = ResolveNodeReference(work, slotKey)
    if not ref or not ref.source or ref.source == false then return nil end
    if ref.descriptor and ref.descriptor ~= false then return ref.descriptor end
    ref.descriptor = DescriptorForSource(ref.source, ref.actualKey) or false
    work.descriptorFallbacks = (work.descriptorFallbacks or 0) + 1
    return ref.descriptor ~= false and ref.descriptor or nil
end

local function OutlierPenalty(candidate)
    if candidate.outlierState == "OUTLIER" then return 28 end
    if candidate.outlierState == "LOUD_ACCENT" then return 10 end
    return 0
end

function P.CreateSupportCandidateWork(candidate, node, job, profile, remainingSlots, locked)
    return {
        candidate = candidate, node = node, job = job, profile = profile,
        remainingSlots = remainingSlots or {}, locked = locked == true,
        stage = "INIT", done = false, decision = nil,
        descriptorCache = {}, neighborIndex = 1, neighborTotal = 0, neighborCount = 0,
        bridgeTargetIndex = 1, bridgePairIndex = 1, bridgeDescriptors = {}, bridgeLabels = {},
        bridgeCandidateTotal = 0, descriptorFallbacks = 0,
    }
end

function P.DescribeSupportCandidateWorkOperation(work)
    if not work or work.done then return "COMPLETE" end
    local stage = work.stage or "INIT"
    if stage == "NEIGHBOR_TARGET_RESOLVE" then return "NEIGHBOR_TARGET" end
    if stage == "NEIGHBOR_DESCRIPTOR_RESOLVE" then return "NEIGHBOR_DESCRIPTOR" end
    if stage == "NEIGHBOR_PAIR" then return "NEIGHBOR_PAIR" end
    if stage == "NEIGHBOR_FINALIZE" then return "NEIGHBOR_FINALIZE" end
    if stage == "BRIDGE_TARGET_RESOLVE" then return "BRIDGE_TARGET" end
    if stage == "BRIDGE_DESCRIPTOR_RESOLVE" then return "BRIDGE_DESCRIPTOR" end
    if stage == "BRIDGE_PAIR_CANDIDATE" then return "BRIDGE_PAIR" end
    if stage == "BRIDGE_AFTER_FINALIZE" then return "BRIDGE_AFTER" end
    if stage == "BRIDGE_BASELINE_PAIR" then return "BRIDGE_BASELINE" end
    if stage == "BRIDGE_FINALIZE" then return "BRIDGE_FINALIZE" end
    if stage == "BUDGET" then return "BUDGET" end
    return "FINALIZE"
end

function P.StepSupportCandidateWork(work)
    if not work then return true, nil end
    if work.done then return true, work.decision end
    work.lastBridgeDescriptorHit = false
    local candidate = work.candidate
    if work.stage == "INIT" then
        work.neighbors = P.SUPPORT_NEIGHBORS[candidate.slotKey] or {}
        work.neighborIndex = 1
        work.stage = #work.neighbors > 0 and "NEIGHBOR_TARGET_RESOLVE" or "NEIGHBOR_FINALIZE"
    elseif work.stage == "NEIGHBOR_TARGET_RESOLVE" then
        local key = work.neighbors[work.neighborIndex]
        if key == nil then
            work.stage = "NEIGHBOR_FINALIZE"
        else
            local ref = ResolveNodeReference(work, key)
            work.currentNeighborKey = key
            if ref and ref.descriptor and ref.descriptor ~= false then
                work.currentNeighborDescriptor = ref.descriptor
                work.stage = "NEIGHBOR_PAIR"
            elseif ref and ref.source and ref.source ~= false then
                work.stage = "NEIGHBOR_DESCRIPTOR_RESOLVE"
            else
                work.currentNeighborDescriptor = nil
                work.stage = "NEIGHBOR_PAIR"
            end
        end
    elseif work.stage == "NEIGHBOR_DESCRIPTOR_RESOLVE" then
        work.currentNeighborDescriptor = MaterializeReferenceDescriptor(work, work.currentNeighborKey)
        work.stage = "NEIGHBOR_PAIR"
    elseif work.stage == "NEIGHBOR_PAIR" then
        local score = Pair(candidate.descriptor, work.currentNeighborDescriptor)
        if score then
            work.neighborTotal = work.neighborTotal + score
            work.neighborCount = work.neighborCount + 1
        end
        work.currentNeighborDescriptor, work.currentNeighborKey = nil, nil
        work.neighborIndex = work.neighborIndex + 1
        work.stage = work.neighborIndex <= #work.neighbors and "NEIGHBOR_TARGET_RESOLVE" or "NEIGHBOR_FINALIZE"
    elseif work.stage == "NEIGHBOR_FINALIZE" then
        work.neighbor = work.neighborCount > 0 and work.neighborTotal / work.neighborCount or candidate.profileFit
        local resolved = P.ResolveSupportRole and P.ResolveSupportRole(candidate.slotKey, work.profile and work.profile.activeAnchorMask) or nil
        work.resolvedRole = resolved
        work.bridgeTargets = resolved and resolved.bridgeTargets or P.SUPPORT_BRIDGES[candidate.slotKey] or {}
        work.bridgeTargetIndex = 1
        work.stage = #work.bridgeTargets > 0 and "BRIDGE_TARGET_RESOLVE" or "BRIDGE_FINALIZE"
    elseif work.stage == "BRIDGE_TARGET_RESOLVE" then
        local key = work.bridgeTargets[work.bridgeTargetIndex]
        if key == nil then
            work.bridgePairIndex = 1
            work.stage = #work.bridgeDescriptors > 0 and "BRIDGE_PAIR_CANDIDATE" or "BRIDGE_FINALIZE"
        else
            local ref = ResolveNodeReference(work, key)
            work.currentBridgeKey = key
            if ref and ref.descriptor and ref.descriptor ~= false then
                work.lastBridgeDescriptorHit = true
                work.bridgeDescriptors[#work.bridgeDescriptors + 1] = ref.descriptor
                work.bridgeLabels[#work.bridgeLabels + 1] = key
                work.bridgeTargetIndex = work.bridgeTargetIndex + 1
                work.stage = work.bridgeTargetIndex <= #work.bridgeTargets and "BRIDGE_TARGET_RESOLVE"
                    or (#work.bridgeDescriptors > 0 and "BRIDGE_PAIR_CANDIDATE" or "BRIDGE_FINALIZE")
            elseif ref and ref.source and ref.source ~= false then
                work.stage = "BRIDGE_DESCRIPTOR_RESOLVE"
            else
                work.bridgeTargetIndex = work.bridgeTargetIndex + 1
                work.stage = work.bridgeTargetIndex <= #work.bridgeTargets and "BRIDGE_TARGET_RESOLVE"
                    or (#work.bridgeDescriptors > 0 and "BRIDGE_PAIR_CANDIDATE" or "BRIDGE_FINALIZE")
            end
        end
    elseif work.stage == "BRIDGE_DESCRIPTOR_RESOLVE" then
        local descriptor = MaterializeReferenceDescriptor(work, work.currentBridgeKey)
        if descriptor then
            work.bridgeDescriptors[#work.bridgeDescriptors + 1] = descriptor
            work.bridgeLabels[#work.bridgeLabels + 1] = work.currentBridgeKey
        end
        work.currentBridgeKey = nil
        work.bridgeTargetIndex = work.bridgeTargetIndex + 1
        work.stage = work.bridgeTargetIndex <= #work.bridgeTargets and "BRIDGE_TARGET_RESOLVE"
            or (#work.bridgeDescriptors > 0 and "BRIDGE_PAIR_CANDIDATE" or "BRIDGE_FINALIZE")
    elseif work.stage == "BRIDGE_PAIR_CANDIDATE" then
        local descriptor = work.bridgeDescriptors[work.bridgePairIndex]
        if descriptor then
            work.bridgeCandidateTotal = work.bridgeCandidateTotal + (Pair(candidate.descriptor, descriptor) or 0.5)
        end
        work.bridgePairIndex = work.bridgePairIndex + 1
        if work.bridgePairIndex > #work.bridgeDescriptors then work.stage = "BRIDGE_AFTER_FINALIZE" end
    elseif work.stage == "BRIDGE_AFTER_FINALIZE" then
        local count = #work.bridgeDescriptors
        work.bridgeAfter = count > 0 and work.bridgeCandidateTotal / count or nil
        if count > 1 then
            work.stage = "BRIDGE_BASELINE_PAIR"
        else
            work.bridgeBefore = 0.5
            work.stage = "BRIDGE_FINALIZE"
        end
    elseif work.stage == "BRIDGE_BASELINE_PAIR" then
        work.bridgeBefore = Pair(work.bridgeDescriptors[1], work.bridgeDescriptors[2]) or 0.5
        work.stage = "BRIDGE_FINALIZE"
    elseif work.stage == "BRIDGE_FINALIZE" then
        if #work.bridgeDescriptors == 0 then
            work.bridge, work.bridgeTarget, work.bridgeBefore, work.bridgeAfter = 0, nil, nil, nil
        else
            work.bridge = math.max(0, (work.bridgeAfter or 0) - (work.bridgeBefore or 0.5))
            work.bridgeTarget = table.concat(work.bridgeLabels, " ↔ ")
        end
        work.stage = "BUDGET"
    elseif work.stage == "BUDGET" then
        work.budget = P.EvaluateSupportBudget(work.node.budget, candidate.slotKey, candidate.mismatchCost, work.remainingSlots, work.locked)
        work.stage = "SCORE"
    elseif work.stage == "SCORE" then
        local bridge = work.bridge or 0
        local accentBonus = candidate.outlierState == "ACCENT" and bridge >= 0.08 and 3 or 0
        local score = candidate.baseScore + candidate.profileFit * 35 + work.neighbor * 18 + bridge * 24 + accentBonus
            - candidate.mismatchCost * 6 - candidate.repeatPenalty - OutlierPenalty(candidate) - work.budget.pressurePenalty
        work.decision = {
            slotKey = candidate.slotKey, source = candidate.source, candidate = candidate,
            role = work.resolvedRole and work.resolvedRole.role or P.SUPPORT_SLOT_ROLES[candidate.slotKey], profileFit = candidate.profileFit,
            neighborCohesion = work.neighbor, bridgeBonus = bridge * 24, bridgeTarget = work.bridgeTarget,
            bridgeBefore = work.bridgeBefore, bridgeAfter = work.bridgeAfter,
            bridgeImprovement = work.bridgeAfter and work.bridgeBefore and (work.bridgeAfter - work.bridgeBefore) > 0.005 or false,
            mismatchSpent = work.budget.cost,
            budgetState = work.budget.state, outlierState = candidate.outlierState,
            repeatPenalty = candidate.repeatPenalty, fallback = candidate.forceFallback == true, score = score,
            budgetEvaluation = work.budget, allowed = work.budget.allowed and candidate.outlierState ~= "OUTLIER",
        }
        work.done, work.stage = true, "COMPLETE"
        return true, work.decision
    else
        work.done, work.stage = true, "COMPLETE"
    end
    return work.done, work.decision
end
