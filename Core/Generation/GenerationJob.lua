local QC = QuestChronicle
local Generation = QC.Generation
Generation.GenerationJob = Generation.GenerationJob or {}
local JobEngine = Generation.GenerationJob

local function Finish(policy, job, success, message)
    return Generation.DiagnosticsEngine.Finish(policy, job, success, message)
end

local function UpdateSlice(policy, runtime, job, stepStarted)
    job.maxStepMs = math.max(job.maxStepMs, runtime.NowMilliseconds() - stepStarted)
    Generation.SchedulerEngine.Accumulate(policy, runtime, job)
end

local function ScheduleOrFail(policy, runtime, job, token, message)
    if Generation.SchedulerEngine.Schedule(policy, runtime, token) then return true end
    Finish(policy, job, false, message)
    return false
end

function JobEngine.Step(job, policy, runtime)
    if not job or runtime.GetActiveJob() ~= job then return end
    local token = job.token
    job.steps = job.steps + 1
    local stepStarted = runtime.NowMilliseconds()
    local slice = Generation.SchedulerEngine.BeginSlice(policy, runtime)
    job.currentSlice = slice

    if job.startSignature and runtime.BuildStateSignature(job.liveState) ~= job.startSignature then
        Finish(policy, job, false, "Outfit generation was cancelled because the workbench changed while Quest Chronicle was preparing the outfit.")
        return
    end

    if job.phase == "SETUP" then
        local ready, reason = Generation.ContextProvider.StepSetup(policy, job)
        if reason then Finish(policy, job, false, reason) return end
        UpdateSlice(policy, runtime, job, stepStarted)
        local message = ready
            and "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload."
            or "Quest Chronicle could not schedule cooperative generation setup. Try /reload."
        ScheduleOrFail(policy, runtime, job, token, message)
        return
    end

    if job.phase == "ANCHORS" then
        Generation.AnchorEngine.Step(policy, job, stepStarted)
        UpdateSlice(policy, runtime, job, stepStarted)
        ScheduleOrFail(policy, runtime, job, token, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
        return
    end

    if job.phase == "SUPPORT" then
        local status, reason = Generation.SupportEngine.Step(policy, job, stepStarted)
        if status == "FAILED" then
            Finish(policy, job, false, reason or "Final support validation failed; the preview was left unchanged.")
            return
        end
        UpdateSlice(policy, runtime, job, stepStarted)
        ScheduleOrFail(policy, runtime, job, token, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
        return
    end

    if job.phase == "ARMOR" then
        if Generation.CandidateEngine.StepFallbackArmor(policy, job, stepStarted, slice) then
            job.phase = job.weaponsPrepared and "COMMIT" or "WEAPONS"
        end
        UpdateSlice(policy, runtime, job, stepStarted)
        ScheduleOrFail(policy, runtime, job, token, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
        return
    end

    if job.phase == "WEAPONS" then
        local status, reason = Generation.WeaponEngine.Step(policy, job, slice)
        if status == "FAILED" then Finish(policy, job, false, reason) return end
        UpdateSlice(policy, runtime, job, stepStarted)
        ScheduleOrFail(policy, runtime, job, token, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
        return
    end

    if job.phase == "COMMIT" then
        if not Generation.SchedulerEngine.CanStartPhase(policy, job, 1.5) then
            UpdateSlice(policy, runtime, job, stepStarted)
            ScheduleOrFail(policy, runtime, job, token, "Quest Chronicle could not schedule the cooperative outfit generator. Try /reload.")
            return
        end
        local performance = Generation.CommitEngine.Commit(policy, job)
        if performance then
            performance.maxStepMs = math.max(tonumber(performance.maxStepMs) or 0, runtime.NowMilliseconds() - stepStarted)
        end
        return
    end

    Finish(policy, job, false, "Unknown shared generation phase: " .. tostring(job.phase))
end

function Generation.StepSharedGenerationJob(job, policy, runtime)
    return JobEngine.Step(job, policy, runtime)
end
