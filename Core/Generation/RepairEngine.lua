local QC = QuestChronicle
local Generation = QC.Generation
Generation.RepairEngine = Generation.RepairEngine or {}
local Engine = Generation.RepairEngine

function Engine.ApplyAlternateSkeleton(policy, job)
    return policy.runtime.ApplyNextAnchor(job)
end

function Engine.RankTargets(policy, ...)
    local callback = policy.validationPolicy and policy.validationPolicy.RankRepairTargets
    if type(callback) ~= "function" then return nil, "Mode policy has no repair-target ranker." end
    return callback(...)
end
