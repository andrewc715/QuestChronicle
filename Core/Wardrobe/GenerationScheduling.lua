local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local Workers = QC._Core and QC._Core.Workers

function P.BeginGenerationWorkerSlice()
    if Workers and Workers.BeginSlice then return Workers.BeginSlice(5.5, 7.5) end
    local now = P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
    return { startedAtMs = now, preferredMs = P.GENERATION_TIME_BUDGET_MS or 5.5 }
end

function P.NoteGenerationWorkerCall(job, elapsedMs)
    if not job or not job.currentSlice or not Workers or not Workers.NoteCall then return false end
    return Workers.NoteCall(job.currentSlice, elapsedMs)
end

function P.ShouldYieldGenerationWorker(job, reserveMs)
    if not job or not job.currentSlice then return false end
    if Workers and Workers.ShouldYield then return Workers.ShouldYield(job.currentSlice, reserveMs or 0.25) end
    local now = P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
    return now - (job.currentSlice.startedAtMs or 0) >= (job.currentSlice.preferredMs or 5.5)
end

function P.CanStartGenerationPhase(job, reserveMs)
    if not job or not job.currentSlice or not Workers or not Workers.CanStartPhase then return true end
    return Workers.CanStartPhase(job.currentSlice, reserveMs or 1.0)
end

function P.AccumulateGenerationSliceDiagnostics(job)
    if not job or not job.currentSlice or not Workers or not Workers.ExportSliceDiagnostics then return end
    local values = Workers.ExportSliceDiagnostics(job.currentSlice)
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
