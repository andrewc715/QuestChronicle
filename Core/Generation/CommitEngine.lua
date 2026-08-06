local QC = QuestChronicle
local Generation = QC.Generation
Generation.CommitEngine = Generation.CommitEngine or {}
local Engine = Generation.CommitEngine

function Engine.Commit(policy, job)
    return policy.runtime.CommitDraft(job, job.weaponCount, job.weaponNotice)
end
