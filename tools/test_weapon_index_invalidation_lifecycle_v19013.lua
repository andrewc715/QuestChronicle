QuestChronicle = { Wardrobe = { _Private = {}, weaponSubtypeDefinitions = {} } }
local Wardrobe, P = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
local cache = { scanCompletedAt = 100, totalVisuals = 90, characterKey = "Tester" }
P.EnsureCache = function() return cache end
Wardrobe.weaponSubtypeDefinitions.SWORD = { familyKey = "ONE_HAND" }
P.ResolveWeaponSubtypeCategoryID = function() return 7 end
local sources = {}
for index = 1, 90 do sources[index] = { sourceID = index, categoryID = 7 } end
Wardrobe.GetSlotSources = function() return sources end

dofile("Core/Wardrobe/WeaponCandidateIndex.lua")

local function Build()
    local start = P.BeginWeaponIndexActionSnapshot()
    P.GetIndexedWeaponSources("SWORD")
    return P.BuildWeaponIndexActionDiagnostics(start)
end

local cold = Build()
assert(cold.use == "COLD_BUILD", "initial index use was not cold")
assert(cold.invalidationReason == "LOGIN_SESSION_RESET", "reload did not report LOGIN_SESSION_RESET")
local warm = Build()
assert(warm.use == "WARM_REUSE" and warm.invalidationReason == "NONE", "warm reuse did not report NONE")

cache.scanCompletedAt = 200
cache.totalVisuals = 100
P.InvalidateWeaponCandidateIndex("WARDROBE_CACHE_REPLACED")
local replaced = Build()
assert(replaced.use == "COLD_BUILD", "cache replacement did not rebuild")
assert(replaced.invalidationReason == "WARDROBE_CACHE_REPLACED", "cache replacement reason was not canonical")

cache.characterKey = "Other"
P.InvalidateWeaponCandidateIndex("CHARACTER_CAPABILITY_CHANGED")
local capability = Build()
assert(capability.invalidationReason == "CHARACTER_CAPABILITY_CHANGED", "character transition reason was not canonical")

P.InvalidateWeaponCandidateIndex(nil)
local unknown = Build()
assert(unknown.invalidationReason == "UNKNOWN", "missing reason did not fall back to UNKNOWN")
assert(unknown.invalidationUnknownFallback == true, "UNKNOWN fallback was not marked for warning")
local recoveredWarm = Build()
assert(recoveredWarm.invalidationReason == "NONE", "UNKNOWN leaked into later warm reuse")

cache.scanCompletedAt = 300
cache.totalVisuals = 110
P.GetIndexedWeaponSources("SWORD")
local inferred = P.GetWeaponCandidateIndexDiagnostics()
assert(inferred.invalidationReason == "WARDROBE_CACHE_REPLACED", "implicit cache identity transition was not inferred")

print("PASS v1.9.0.13 weapon-index invalidation lifecycle: session reset, none, cache replacement, capability change, implicit inference, and genuine unknown fallback")
