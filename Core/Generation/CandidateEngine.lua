local QC = QuestChronicle
local Generation = QC.Generation
Generation.CandidateEngine = Generation.CandidateEngine or {}
local Engine = Generation.CandidateEngine

function Engine.StepFallbackArmor(policy, job, stepStarted, slice)
    return policy.runtime.ProcessArmor(job, stepStarted, slice)
end
