QuestChronicle = { Wardrobe = { _Private = {}, weaponSubtypeDefinitions = {} } }
local Wardrobe, P = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
P.EnsureCache = function() return { scanCompletedAt = 100, totalVisuals = 120, characterKey = "Tester" } end
Wardrobe.weaponSubtypeDefinitions.SWORD = { familyKey = "ONE_HAND" }
P.ResolveWeaponSubtypeCategoryID = function() return 7 end
local sources = {}
for index = 1, 120 do sources[index] = { sourceID = index, categoryID = index % 3 == 0 and 7 or 8 } end
Wardrobe.GetSlotSources = function() return sources end
P.MaybeYieldWeaponGeneration = function() coroutine.yield("weaponIndexBuild") end

dofile("Core/Wardrobe/WeaponCandidateIndex.lua")
local function Run(actionStart)
    local thread = coroutine.create(function() return P.GetIndexedWeaponSources("SWORD") end)
    while coroutine.status(thread) ~= "dead" do
        local ok, value = coroutine.resume(thread)
        assert(ok, value)
    end
    return P.BuildWeaponIndexActionDiagnostics(actionStart)
end
local start = P.BeginWeaponIndexActionSnapshot()
assert(start.invalidationReason == "LOGIN_SESSION_RESET", "session reset reason was not canonical")
local cold = Run(start)
assert(cold.use == "COLD_BUILD" and cold.bucketsBuilt == 1, "cold action diagnostics changed")
assert(cold.examinedThisAction == 120 and cold.yieldsThisAction > 0, "cold action-local work was not reported")
start = P.BeginWeaponIndexActionSnapshot()
local warm = Run(start)
assert(warm.use == "WARM_REUSE" and warm.bucketsReused == 1, "warm reuse was not classified")
assert(warm.examinedThisAction == 0 and warm.yieldsThisAction == 0, "warm reuse reported construction work")
P.InvalidateWeaponCandidateIndex("ELIGIBILITY_OUTCOME_CHANGED", "SWORD")
start = P.BeginWeaponIndexActionSnapshot()
local repair = Run(start)
assert(repair.use == "INCREMENTAL_REPAIR" and repair.bucketsRepaired == 1, "incremental repair was not classified")
assert(repair.invalidationReason == "ELIGIBILITY_OUTCOME_CHANGED", "repair reason was not preserved")
assert(repair.lifetimeBuckets == 1 and repair.lifetimeExamined >= 240, "lifetime totals were not separated")
print("PASS v1.9.0.12 weapon-index diagnostics: cold, warm, repair, action-local work, and canonical reasons")
