local QC = QuestChronicle
local Generation = QC.Generation
Generation.WeaponEngine = Generation.WeaponEngine or {}
local Engine = Generation.WeaponEngine

function Engine.Step(policy, job, slice)
    local runtime = policy.runtime
    if not job.weaponWork and runtime.CreateWeaponWork then
        job.weaponWork = runtime.CreateWeaponWork(job.draft, job.reroll, job.styleMode, job.styleContext)
    end
    local operations = 0
    while operations < runtime.GetOperationSafetyCap() do
        local started = runtime.NowMilliseconds()
        local done, ok, countOrMessage, notice
        if job.weaponWork and runtime.StepWeaponWork then
            done, ok, countOrMessage, notice = runtime.StepWeaponWork(job.weaponWork)
        else
            done = true
            ok, countOrMessage, notice = runtime.GenerateWeapons(job.draft, job.reroll, job.styleMode, job.styleContext)
        end
        runtime.RecordPhase(job, "weaponRouting", started)
        operations = operations + 1
        if done then
            if not ok then return "FAILED", countOrMessage end
            job.weaponCount = countOrMessage
            job.weaponNotice = notice
            job.phase = "COMMIT"
            return "READY"
        end
        job.weaponYields = job.weaponYields + 1
        if runtime.WorkerShouldYield(slice, 0.15) then return "PENDING" end
    end
    return "PENDING"
end
