local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.SUPPORT_POOL_LIMIT = 32
P.SUPPORT_BEAM_WIDTH = 24
P.SUPPORT_FINAL_SHORTLIST = 6
P.SUPPORT_FINAL_SCORE_WINDOW = 20

local function CopyMap(source)
    local result = {}
    for key, value in pairs(source or {}) do result[key] = value end
    return result
end

local function CopyArray(source)
    local result = {}
    for index, value in ipairs(source or {}) do result[index] = value end
    return result
end

local function InsertSortedLimited(values, entry, limit, field)
    values[#values + 1] = entry
    table.sort(values, function(left, right)
        local leftValue, rightValue = tonumber(left[field]) or 0, tonumber(right[field]) or 0
        if leftValue == rightValue then return tostring(left.diversityKey or "") < tostring(right.diversityKey or "") end
        return leftValue > rightValue
    end)
    if #values > limit then table.remove(values) end
end

function P.AddSupportPoolCandidate(work, candidate)
    if not candidate then return end
    local identity = P.SupportVisualIdentity(candidate.source)
    local existing = work.byVisual[identity]
    if existing then work.deduplicated = (work.deduplicated or 0) + 1 end
    if existing and existing.poolPriority >= candidate.poolPriority then return end
    work.byVisual[identity] = candidate
end

function P.FinalizeSupportPool(work)
    local candidates = {}
    for _, candidate in pairs(work.byVisual or {}) do InsertSortedLimited(candidates, candidate, work.poolLimit or P.SUPPORT_POOL_LIMIT, "poolPriority") end
    work.pool = candidates
    return candidates
end

local function NodeSignature(node, throughIndex, slotOrder)
    local parts = {}
    for index = 1, throughIndex do
        local slotKey = slotOrder[index]
        local candidate = node.selected[slotKey]
        parts[#parts + 1] = slotKey .. "=" .. P.SupportVisualIdentity(candidate and candidate.source)
    end
    return table.concat(parts, "|")
end

local function NewRoot(lockedSelections, lockedDecisions, budget)
    return {
        selected = CopyMap(lockedSelections), decisions = CopyArray(lockedDecisions), budget = P.CopySupportBudget(budget),
        totalScore = 0, mismatchSpent = budget.lockedCommitment or 0, fallbackCount = 0,
    }
end

local function ExtendNode(node, decision)
    local child = {
        selected = CopyMap(node.selected), decisions = CopyArray(node.decisions),
        budget = P.CommitSupportBudget(node.budget, decision.budgetEvaluation, decision.locked),
        totalScore = (node.totalScore or 0) + (decision.score or 0),
        mismatchSpent = (node.mismatchSpent or 0) + (decision.mismatchSpent or 0),
        fallbackCount = (node.fallbackCount or 0) + (decision.fallback and 1 or 0),
    }
    child.selected[decision.slotKey] = decision.candidate
    child.decisions[#child.decisions + 1] = decision
    return child
end

local function RemainingSlots(work, stageIndex)
    local result = {}
    for index = stageIndex + 1, #work.slotOrder do result[#result + 1] = work.slotOrder[index] end
    return result
end

local function FinishStage(work)
    local retained, seen = {}, {}
    table.sort(work.nextBeam, function(left, right) return (left.totalScore or 0) > (right.totalScore or 0) end)
    for _, node in ipairs(work.nextBeam) do
        local signature = NodeSignature(node, work.stageIndex, work.slotOrder)
        if not seen[signature] then
            seen[signature] = true
            retained[#retained + 1] = node
            if #retained >= P.SUPPORT_BEAM_WIDTH then break end
        else
            work.deduplicated = work.deduplicated + 1
        end
    end
    work.beam = retained
    work.retained[work.slotOrder[work.stageIndex]] = #retained
    work.stageIndex = work.stageIndex + 1
    work.nodeIndex, work.candidateIndex, work.nextBeam = 1, 1, {}
end

local function BeginFallback(work, node, pool, remaining)
    work.fallbackWork = {
        node = node, pool = pool or {}, remaining = remaining or {}, candidateIndex = 1,
        bestDecision = nil, candidateWork = nil,
    }
end

local function FinishFallback(work, fallback)
    local bestDecision = fallback.bestDecision
    if bestDecision then
        bestDecision.allowed = true
        bestDecision.fallback = true
        bestDecision.budgetState = "OVER"
        bestDecision.budgetEvaluation.allowed = true
        work.nextBeam[#work.nextBeam + 1] = ExtendNode(fallback.node, bestDecision)
        work.fallbacks = work.fallbacks + 1
    else
        work.nextBeam[#work.nextBeam + 1] = fallback.node
        work.emptySlots = work.emptySlots + 1
    end
    work.fallbackWork = nil
    work.nodeIndex = work.nodeIndex + 1
    work.candidateIndex = 1
end

local function StepCandidateDecision(holder, candidate, node, work, remaining, locked)
    if P.CreateSupportCandidateWork and P.StepSupportCandidateWork then
        if not holder.candidateWork then
            holder.candidateWork = P.CreateSupportCandidateWork(candidate, node, work.job, work.profile, remaining, locked)
        end
        local subphase = P.DescribeSupportCandidateWorkOperation and P.DescribeSupportCandidateWorkOperation(holder.candidateWork) or "FINALIZE"
        local fallbackBefore = tonumber(holder.candidateWork.descriptorFallbacks) or 0
        local done, decision = P.StepSupportCandidateWork(holder.candidateWork)
        work.lastCandidateDescriptorFallbacks = math.max(0, (tonumber(holder.candidateWork.descriptorFallbacks) or 0) - fallbackBefore)
        work.lastCandidateBridgeDescriptorHit = holder.candidateWork.lastBridgeDescriptorHit == true
        work.lastCandidateSubphase = subphase
        work.lastCandidateCompleted = done == true
        if not done then return nil, false end
        holder.candidateWork = nil
        return decision, true
    end
    work.lastCandidateSubphase = "FINALIZE"
    work.lastCandidateCompleted = true
    return P.ScoreSupportCandidate(candidate, node, work.job, work.profile, remaining, locked), true
end

local function StepFallback(work)
    local fallback = work.fallbackWork
    if not fallback then return true end
    local candidate = fallback.pool[fallback.candidateIndex]
    if candidate then
        local decision, complete = StepCandidateDecision(fallback, candidate, fallback.node, work, fallback.remaining, false)
        if not complete then return false end
        if not fallback.bestDecision or decision.mismatchSpent < fallback.bestDecision.mismatchSpent then
            fallback.bestDecision = decision
        end
        fallback.candidateIndex = fallback.candidateIndex + 1
        if fallback.candidateIndex > #fallback.pool then FinishFallback(work, fallback) return true end
        return false
    end
    FinishFallback(work, fallback)
    return true
end

function P.CreateSupportBeamWork(job, profile, budget, slotOrder, pools, lockedSelections, lockedDecisions)
    return {
        job = job, profile = profile, slotOrder = slotOrder or {}, pools = pools or {},
        beam = { NewRoot(lockedSelections or {}, lockedDecisions or {}, budget) },
        stageIndex = 1, nodeIndex = 1, candidateIndex = 1, nextBeam = {}, candidateWork = nil,
        expansions = {}, retained = {}, rejections = 0, deduplicated = 0, fallbacks = 0, emptySlots = 0,
    }
end

function P.DescribeNextSupportBeamOperation(work)
    if not work or work.stageIndex > #(work.slotOrder or {}) then return "COMPLETE" end
    if work.fallbackWork then return "FALLBACK_SCAN" end
    local node = work.beam and work.beam[work.nodeIndex]
    if not node then return #(work.nextBeam or {}) == 0 and "COMPLETE" or "STAGE_FINALIZE" end
    local slotKey = work.slotOrder[work.stageIndex]
    local pool = work.pools[slotKey] or {}
    if work.candidateWork or pool[work.candidateIndex] then return "CANDIDATE" end
    if #pool == 0 or #(work.nextBeam or {}) == (work.nodeStartCount or 0) then return "FALLBACK_SCAN" end
    return "CANDIDATE"
end

function P.DescribeNextSupportBeamCandidateSubphase(work)
    if not work then return nil end
    local candidateWork = work.fallbackWork and work.fallbackWork.candidateWork or work.candidateWork
    return candidateWork and P.DescribeSupportCandidateWorkOperation and P.DescribeSupportCandidateWorkOperation(candidateWork) or nil
end

function P.StepSupportBeamWork(work)
    work.lastCandidateSubphase, work.lastCandidateCompleted, work.lastCandidateDescriptorFallbacks, work.lastCandidateBridgeDescriptorHit = nil, false, 0, false
    if work.stageIndex > #work.slotOrder then return true end
    if work.fallbackWork then StepFallback(work) return false end
    local slotKey = work.slotOrder[work.stageIndex]
    local pool = work.pools[slotKey] or {}
    local node = work.beam[work.nodeIndex]
    if not node then
        if #work.nextBeam == 0 then return true end
        FinishStage(work)
        return work.stageIndex > #work.slotOrder
    end
    if work.candidateIndex == 1 and not work.candidateWork then work.nodeStartCount = #work.nextBeam end
    local candidate = pool[work.candidateIndex]
    if candidate then
        local decision, complete = StepCandidateDecision(work, candidate, node, work, RemainingSlots(work, work.stageIndex), false)
        if not complete then return false end
        work.expansions[slotKey] = (work.expansions[slotKey] or 0) + 1
        if decision.allowed then work.nextBeam[#work.nextBeam + 1] = ExtendNode(node, decision)
        else work.rejections = work.rejections + 1 end
        work.candidateIndex = work.candidateIndex + 1
        return false
    end
    if #pool == 0 or #work.nextBeam == (work.nodeStartCount or 0) then
        BeginFallback(work, node, pool, RemainingSlots(work, work.stageIndex))
        StepFallback(work)
        return false
    end
    work.nodeIndex = work.nodeIndex + 1
    work.candidateIndex = 1
    return false
end

local function WeightedChoice(finalists)
    if #finalists == 0 then return nil, 0, 0 end
    table.sort(finalists, function(left, right) return (left.totalScore or 0) > (right.totalScore or 0) end)
    local best = finalists[1].totalScore or 0
    local shortlist = {}
    for _, node in ipairs(finalists) do
        if #shortlist >= P.SUPPORT_FINAL_SHORTLIST or (node.totalScore or 0) < best - P.SUPPORT_FINAL_SCORE_WINDOW then break end
        shortlist[#shortlist + 1] = node
    end
    local minimum = shortlist[#shortlist] and shortlist[#shortlist].totalScore or best
    local totalWeight = 0
    for _, node in ipairs(shortlist) do node.selectionWeight = math.max(1, (node.totalScore - minimum + 4) ^ 2) totalWeight = totalWeight + node.selectionWeight end
    local roll = math.random() * totalWeight
    for rank, node in ipairs(shortlist) do
        roll = roll - node.selectionWeight
        if roll <= 0 then return node, rank, #shortlist end
    end
    return shortlist[#shortlist], #shortlist, #shortlist
end

function P.ChooseSupportConfiguration(work)
    return WeightedChoice(work.beam or {})
end
