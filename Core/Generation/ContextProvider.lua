local QC = QuestChronicle
local Generation = QC.Generation
Generation.ContextProvider = Generation.ContextProvider or {}
local Provider = Generation.ContextProvider

function Provider.StepSetup(policy, job)
    return policy.runtime.StepSetup(job)
end

function Provider.BuildModeContext(policy, ...)
    local callback = policy.contextPolicy and policy.contextPolicy.BuildModeContext
    if type(callback) ~= "function" then return nil, "Mode policy has no context builder." end
    return callback(...)
end

function Provider.DescribeContext(policy, context)
    local callback = policy.contextPolicy and policy.contextPolicy.DescribeContext
    return type(callback) == "function" and callback(context) or nil
end
