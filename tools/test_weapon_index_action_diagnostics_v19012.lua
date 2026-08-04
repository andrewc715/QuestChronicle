QuestChronicle = { Wardrobe = { _Private = {}, weaponSubtypeDefinitions = {} } }
local Wardrobe, P = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
P.EnsureCache = function() return { scanCompletedAt = 100, totalVisuals = 120, characterKey = "Tester" } end
Wardrobe.weaponSubtypeDefinitions.SWORD = { familyKey = "ONE_HAND" }
Wardrobe.weaponSubtypeDefinitions.AXE = { familyKey = "ONE_HAND" }
P.ResolveWeaponSubtypeCategoryID = function(definition)
    return definition == Wardrobe.weaponSubtypeDefinitions.SWORD and 7 or 8
end
local sources = {}
for index = 1, 120 do sources[index] = { sourceID = index, categoryID = index % 3 == 0 and 7 or 8 } end
Wardrobe.GetSlotSources = function() return sources end
P.MaybeYieldWeaponGeneration = function() coroutine.yield("weaponIndexBuild") end

dofile("Core/Wardrobe/WeaponCandidateIndex.lua")
local function Run(actionStart, subtypeKey)
    local thread = coroutine.create(function() return P.GetIndexedWeaponSources(subtypeKey or "SWORD") end)
    while coroutine.status(thread) ~= "dead" do
        local ok, value = coroutine.resume(thread)
        assert(ok, value)
    end
    return P.BuildWeaponIndexActionDiagnostics(actionStart)
end
local start = P.BeginWeaponIndexActionSnapshot()
assert(start.invalidationReason == "LOGIN_SESSION_RESET", "session reset reason was not canonical")
local cold = Run(start, "SWORD")
assert(cold.use == "COLD_BUILD" and cold.bucketsBuilt == 1, "cold action diagnostics changed")
assert(cold.examinedThisAction == 120 and cold.yieldsThisAction > 0, "cold action-local work was not reported")
assert(cold.invalidationReason == "LOGIN_SESSION_RESET", "cold build lost the session reset reason")
start = P.BeginWeaponIndexActionSnapshot()
local partial = Run(start, "AXE")
assert(partial.use == "PARTIAL_BUILD" and partial.bucketsBuilt == 1, "partial build was not classified")
assert(partial.invalidationReason == "LOGIN_SESSION_RESET", "partial build lost the session reset reason")
start = P.BeginWeaponIndexActionSnapshot()
local warm = Run(start, "SWORD")
assert(warm.use == "WARM_REUSE" and warm.bucketsReused == 1, "warm reuse was not classified")
assert(warm.examinedThisAction == 0 and warm.yieldsThisAction == 0, "warm reuse reported construction work")
assert(warm.invalidationReason == "NONE", "warm reuse repeated an old invalidation reason")
P.InvalidateWeaponCandidateIndex("ELIGIBILITY_OUTCOME_CHANGED", "SWORD")
start = P.BeginWeaponIndexActionSnapshot()
local repair = Run(start, "SWORD")
assert(repair.use == "INCREMENTAL_REPAIR" and repair.bucketsRepaired == 1, "incremental repair was not classified")
assert(repair.invalidationReason == "ELIGIBILITY_OUTCOME_CHANGED", "repair reason was not preserved")
assert(repair.lifetimeBuckets == 2 and repair.lifetimeExamined >= 360, "lifetime totals were not separated")
print("PASS v1.9.0.13 weapon-index diagnostics: cold, partial, warm, repair, action-local work, and canonical reasons")
