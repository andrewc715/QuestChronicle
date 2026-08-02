QuestChronicle = { Wardrobe = { _Private = {} } }
local P = QuestChronicle.Wardrobe._Private

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/WeaponPipeline.lua")

local stages = {}
function P.GenerateWeapons()
    stages[#stages + 1] = "setup"
    P.MaybeYieldWeaponGeneration("candidate")
    stages[#stages + 1] = "candidate"
    P.MaybeYieldWeaponGeneration("validation")
    stages[#stages + 1] = "commit"
    return true, 2, "linked"
end

local work = P.CreateWeaponGenerationWork({}, false, "TRAVELER", {})
local done, _, _, _, phase = P.StepWeaponGenerationWork(work)
assert(not done and phase == "candidate", "weapon pipeline did not yield after setup")
done, _, _, _, phase = P.StepWeaponGenerationWork(work)
assert(not done and phase == "validation", "weapon pipeline did not yield after candidate work")
local ok, count, notice
done, ok, count, notice = P.StepWeaponGenerationWork(work)
assert(done and ok and count == 2 and notice == "linked", "weapon pipeline did not preserve generator return values")
assert(table.concat(stages, ",") == "setup,candidate,commit", "weapon coroutine changed execution order")

print("PASS weapon pipeline: synchronous route logic resumes cooperatively without changing results")
