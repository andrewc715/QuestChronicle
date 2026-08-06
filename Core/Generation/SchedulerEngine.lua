local QC = QuestChronicle
local Generation = QC.Generation
Generation.SchedulerEngine = Generation.SchedulerEngine or {}
local Engine = Generation.SchedulerEngine

function Engine.BeginSlice(policy, runtime)
    return runtime.BeginWorkerSlice()
end

function Engine.ShouldYield(policy, runtime, slice, reserveMs)
    return runtime.WorkerShouldYield(slice, reserveMs)
end

function Engine.CanStartPhase(policy, job, reserveMs)
    local runtime = policy.runtime
    if type(runtime.CanStartPhase) ~= "function" then return true end
    return runtime.CanStartPhase(job, reserveMs)
end

function Engine.RecordPhase(policy, runtime, job, phaseKey, startedAt)
    return runtime.RecordPhase(job, phaseKey, startedAt)
end

function Engine.Accumulate(policy, runtime, job)
    if type(runtime.AccumulateSliceDiagnostics) == "function" then runtime.AccumulateSliceDiagnostics(job) end
end

function Engine.Schedule(policy, runtime, token)
    return runtime.ScheduleNextStep(token)
end
