local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local Workers = QC._Core and QC._Core.Workers

local function NowMilliseconds()
    return P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
end

local PHASE_RESERVE = {
    IDENTITY = 0.25, ANCHOR_SUMMARY = 0.25, STATE = 0.5, CONTEXT_INIT = 0.75,
    CONTEXT_SEED = 0.25, CONTEXT_PREPARE = 0.75, SUMMARY = 0.25, CACHE = 0.25,
    PROFILE = 0.75, LEDGER = 0.75, FIXED = 1.0, POOL = 1.5, SCORE = 1.0,
    SELECT = 1.0, COMMIT = 1.5,
}

function P.BeginSupportRerollSlice()
    if Workers and Workers.BeginSlice then return Workers.BeginSlice(5.5, 7.5) end
    return { startedAtMs = NowMilliseconds(), preferredMs = P.GENERATION_TIME_BUDGET_MS or 2.5 }
end

function P.NoteSupportRerollCall(slice, elapsed)
    if Workers and Workers.NoteCall then return Workers.NoteCall(slice, elapsed) end
    return false
end

function P.ShouldYieldSupportRerollSlice(slice, reserveMs)
    if Workers and Workers.ShouldYield then return Workers.ShouldYield(slice, reserveMs) end
    return NowMilliseconds() - (slice.startedAtMs or 0) >= (slice.preferredMs or P.GENERATION_TIME_BUDGET_MS or 2.5)
end

function P.CanStartSupportRerollPhase(job, slice)
    if not Workers or not Workers.CanStartPhase then return true end
    return Workers.CanStartPhase(slice, PHASE_RESERVE[job and job.phase] or 0.5)
end

function P.AccumulateSupportRerollSliceDiagnostics(job, slice)
    if not job or not Workers or not Workers.ExportSliceDiagnostics then return end
    local values = Workers.ExportSliceDiagnostics(slice)
    job.schedulerDiagnostics = job.schedulerDiagnostics or {
        expensiveCallYields = 0, phaseTransitionYields = 0, preventedPhaseTransitions = 0,
        postExpensiveCallContinuations = 0, maximumSliceDebtMs = 0,
    }
    local target = job.schedulerDiagnostics
    target.expensiveCallYields = target.expensiveCallYields + (values.expensiveCalls or 0)
    target.phaseTransitionYields = target.phaseTransitionYields + (values.phaseTransitionYields or 0)
    target.preventedPhaseTransitions = target.preventedPhaseTransitions + (values.preventedTransitions or 0)
    target.postExpensiveCallContinuations = target.postExpensiveCallContinuations + (values.postExpensiveContinuations or 0)
    target.maximumSliceDebtMs = math.max(target.maximumSliceDebtMs or 0, values.sliceDebtMs or 0)
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
