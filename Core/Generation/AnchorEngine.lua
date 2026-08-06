local QC = QuestChronicle
local Generation = QC.Generation
Generation.AnchorEngine = Generation.AnchorEngine or {}
local Engine = Generation.AnchorEngine

function Engine.Step(policy, job, stepStarted)
    return policy.runtime.StepAnchor(job, stepStarted)
end

function Engine.EvaluateCandidate(policy, ...)
    local callback = policy.anchorPolicy and policy.anchorPolicy.EvaluateAnchorCandidate
    if type(callback) ~= "function" then return nil, "Mode policy has no anchor-candidate evaluator." end
    return callback(...)
end

function Engine.ScorePair(policy, ...)
    local callback = policy.anchorPolicy and policy.anchorPolicy.ScoreAnchorPair
    if type(callback) ~= "function" then return nil, "Mode policy has no anchor-pair scorer." end
    return callback(...)
end
