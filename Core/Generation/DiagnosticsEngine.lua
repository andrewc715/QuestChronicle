local QC = QuestChronicle
local Generation = QC.Generation
Generation.DiagnosticsEngine = Generation.DiagnosticsEngine or {}
local Engine = Generation.DiagnosticsEngine

function Engine.Finish(policy, job, success, message)
    return policy.runtime.FinishJob(job, success, message)
end

function Engine.BuildModeSections(policy, ...)
    local callback = policy.diagnosticsPolicy and policy.diagnosticsPolicy.BuildModeReportSections
    if type(callback) ~= "function" then return nil end
    return callback(...)
end
