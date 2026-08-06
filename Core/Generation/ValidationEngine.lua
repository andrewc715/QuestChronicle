local QC = QuestChronicle
local Generation = QC.Generation
Generation.ValidationEngine = Generation.ValidationEngine or {}
local Engine = Generation.ValidationEngine

function Engine.Step(policy, job, stepStarted)
    return policy.runtime.StepSupport(job, stepStarted)
end

function Engine.Analyze(policy, ...)
    local callback = policy.validationPolicy and policy.validationPolicy.AnalyzeCompletedConfiguration
    if type(callback) ~= "function" then return nil, "Mode policy has no completed-configuration analyzer." end
    return callback(...)
end

function Engine.Compare(policy, ...)
    local callback = policy.validationPolicy and policy.validationPolicy.CompareValidationObjectives
    if type(callback) ~= "function" then return nil, "Mode policy has no validation comparator." end
    return callback(...)
end
