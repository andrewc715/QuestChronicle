local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local Workers = QC._Core and QC._Core.Workers

local function NowMilliseconds()
    return P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
end

function P.BeginSupportRerollSlice()
    if Workers and Workers.BeginSlice then return Workers.BeginSlice(5.5, 7.5) end
    return { startedAtMs = NowMilliseconds(), preferredMs = P.GENERATION_TIME_BUDGET_MS or 2.5 }
end

function P.NoteSupportRerollCall(slice, elapsed)
    if Workers and Workers.NoteCall then Workers.NoteCall(slice, elapsed) end
end

function P.ShouldYieldSupportRerollSlice(slice, reserveMs)
    if Workers and Workers.ShouldYield then return Workers.ShouldYield(slice, reserveMs) end
    return NowMilliseconds() - (slice.startedAtMs or 0) >= (slice.preferredMs or P.GENERATION_TIME_BUDGET_MS or 2.5)
end

local function AdaptivePhaseKey(job)
    if not job then return nil end
    if job.phase == "POOL" then
        local work = job.supportRerollPool and job.supportRerollPool.candidateWork
        local stage = work and work.stage
        if stage == "PRECHECK" or stage == "ELIGIBILITY_INIT" or stage == "ELIGIBILITY_STEP" then return "rerollEligibility" end
        if stage == "ERA_INIT" or stage == "ERA_STEP" then return "rerollEraEvidence" end
        return "rerollCandidatePreparation"
    elseif job.phase == "SCORE" then
        return "rerollCandidateScoring"
    end
end

function P.GetSupportRerollAdaptiveBatchLimit(job, slice)
    if not Workers or not Workers.GetAdaptiveBatchSize then return P.GENERATION_OPERATION_SAFETY_CAP end
    local key = AdaptivePhaseKey(job)
    if not key then return P.GENERATION_OPERATION_SAFETY_CAP end
    local state = job.adaptiveCosts and job.adaptiveCosts[key] or nil
    local remaining = Workers.Remaining and Workers.Remaining(slice) or 1
    local remainingItems = 1
    if job.phase == "POOL" and job.supportRerollPool then
        remainingItems = math.max(1, #job.supportRerollPool.sources - job.supportRerollPool.sourceIndex + 1)
    elseif job.phase == "SCORE" and job.supportRerollPool then
        remainingItems = math.max(1, #job.supportRerollPool.pool - (job.supportRerollScoreIndex or 1) + 1)
    end
    return Workers.GetAdaptiveBatchSize(state, remaining, remainingItems)
end
