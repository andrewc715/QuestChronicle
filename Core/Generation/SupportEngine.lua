local QC = QuestChronicle
local Generation = QC.Generation
Generation.SupportEngine = Generation.SupportEngine or {}
local Engine = Generation.SupportEngine

function Engine.Step(policy, job, stepStarted)
    local status, reason = Generation.ValidationEngine.Step(policy, job, stepStarted)
    if status == "READY" then
        job.phase = "COMMIT"
    elseif status == "ALTERNATE" then
        local runtime = policy.runtime
        local started = runtime.NowMilliseconds()
        local ok, alternateReason = Generation.RepairEngine.ApplyAlternateSkeleton(policy, job)
        runtime.RecordPhase(job, "supportAlternateSkeleton", started)
        if not ok then return "FAILED", alternateReason or reason or "No alternate anchor skeleton could resolve the final support outliers." end
        job.phaseDAlternateNoRepair = true
        job.supportWork = nil
        job.phase = "SUPPORT"
    elseif status == "FAILED" then
        return "FAILED", reason or "Final support validation failed; the preview was left unchanged."
    elseif status == "FALLBACK" then
        job.supportFallbackReason = reason
        job.phase = "ARMOR"
        job.armorOrder = policy.runtime.GetSupportingArmorOrder()
        job.armorIndex, job.armorWork = 1, nil
    end
    return status, reason
end

function Engine.ScoreCandidate(policy, ...)
    local callback = policy.supportPolicy and policy.supportPolicy.ScoreSupportCandidate
    if type(callback) ~= "function" then return nil, "Mode policy has no support-candidate scorer." end
    return callback(...)
end
