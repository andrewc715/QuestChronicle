QuestChronicle = { Wardrobe = { _Private = {}, weaponSubtypeDefinitions = {} } }
local Wardrobe, P = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
local cache = { scanCompletedAt = 100, totalVisuals = 120, characterKey = "Tester" }
P.EnsureCache = function() return cache end
Wardrobe.weaponSubtypeDefinitions.SWORD = { familyKey = "ONE_HAND" }
Wardrobe.weaponSubtypeDefinitions.AXE = { familyKey = "ONE_HAND" }
P.ResolveWeaponSubtypeCategoryID = function(definition)
    return definition == Wardrobe.weaponSubtypeDefinitions.SWORD and 7 or 8
end
local sources = {}
for index = 1, 120 do
    sources[index] = { sourceID = index, categoryID = index % 3 == 0 and 7 or 8 }
end
Wardrobe.GetSlotSources = function() return sources end
P.MaybeYieldWeaponGeneration = function() end

dofile("Core/Wardrobe/WeaponCandidateIndex.lua")

local function Run(subtypeKey)
    local start = P.BeginWeaponIndexActionSnapshot()
    P.GetIndexedWeaponSources(subtypeKey or "SWORD")
    return P.BuildWeaponIndexActionDiagnostics(start)
end

local function AssertReason(action, expectedUse, expectedReason, message)
    assert(action.use == expectedUse, message .. ": expected " .. expectedUse .. ", got " .. tostring(action.use))
    assert(action.invalidationReason == expectedReason, message .. ": expected " .. expectedReason .. ", got " .. tostring(action.invalidationReason))
end

-- Required post-reload lifecycle, including warm reuse between cold and partial builds.
local cold = Run("SWORD")
AssertReason(cold, "COLD_BUILD", "LOGIN_SESSION_RESET", "cold build lost the login lifecycle")
local warmBetween = Run("SWORD")
AssertReason(warmBetween, "WARM_REUSE", "NONE", "warm reuse repeated the login lifecycle")
assert(warmBetween.examinedThisAction == 0 and warmBetween.yieldsThisAction == 0, "warm reuse reported construction work")
local partial = Run("AXE")
AssertReason(partial, "PARTIAL_BUILD", "LOGIN_SESSION_RESET", "partial build lost the login lifecycle after an intervening warm reuse")
local finalWarm = Run("AXE")
AssertReason(finalWarm, "WARM_REUSE", "NONE", "final warm reuse did not report NONE")

-- An action that performs no weapon-index work is also NONE.
local idleStart = P.BeginWeaponIndexActionSnapshot()
local idle = P.BuildWeaponIndexActionDiagnostics(idleStart)
AssertReason(idle, "NONE", "NONE", "idle action reported a historical invalidation")

-- Merely invalidating during an action is not the same as processing the index.
local invalidationOnlyStart = P.BeginWeaponIndexActionSnapshot()
P.InvalidateWeaponCandidateIndex("COLLECTION_REVISION_CHANGED")
local invalidationOnly = P.BuildWeaponIndexActionDiagnostics(invalidationOnlyStart)
AssertReason(invalidationOnly, "NONE", "NONE", "invalidation-only action claimed to process the index")
local processedLater = Run("SWORD")
AssertReason(processedLater, "COLD_BUILD", "COLLECTION_REVISION_CHANGED", "deferred invalidation cause was not preserved until processing")

-- Every recognized lifecycle reason survives a full rebuild and does not warn as UNKNOWN.
local canonicalReasons = {
    "FORMAT_MISMATCH",
    "WARDROBE_CACHE_REPLACED",
    "COLLECTION_REVISION_CHANGED",
    "METADATA_REVISION_CHANGED",
    "CHARACTER_CAPABILITY_CHANGED",
    "APPEARANCE_COLLECTED",
    "EVIDENCE_OUTCOME_CHANGED",
    "ELIGIBILITY_OUTCOME_CHANGED",
    "LOGIN_SESSION_RESET",
    "MANUAL_DEBUG_RESET",
}
for index, reason in ipairs(canonicalReasons) do
    cache.scanCompletedAt = 200 + index
    P.InvalidateWeaponCandidateIndex(reason)
    local rebuilt = Run("SWORD")
    AssertReason(rebuilt, "COLD_BUILD", reason, "canonical full invalidation changed")
    assert(rebuilt.invalidationUnknownFallback ~= true, reason .. " was incorrectly marked UNKNOWN")
    local reused = Run("SWORD")
    AssertReason(reused, "WARM_REUSE", "NONE", reason .. " leaked into warm reuse")
end

-- Bucket-local repairs retain their specific canonical reason.
P.GetIndexedWeaponSources("AXE")
P.InvalidateWeaponCandidateIndex("ELIGIBILITY_OUTCOME_CHANGED", "SWORD")
local repaired = Run("SWORD")
AssertReason(repaired, "INCREMENTAL_REPAIR", "ELIGIBILITY_OUTCOME_CHANGED", "eligibility repair reason changed")
assert(repaired.bucketsRepaired == 1, "repair count did not increment on completed repair")

-- A later queued invalidation must not relabel work already processed by this action.
P.InvalidateWeaponCandidateIndex("EVIDENCE_OUTCOME_CHANGED")
local queuedStart = P.BeginWeaponIndexActionSnapshot()
P.GetIndexedWeaponSources("SWORD")
P.InvalidateWeaponCandidateIndex("CHARACTER_CAPABILITY_CHANGED")
local queuedAfterBuild = P.BuildWeaponIndexActionDiagnostics(queuedStart)
AssertReason(queuedAfterBuild, "COLD_BUILD", "EVIDENCE_OUTCOME_CHANGED", "later queued invalidation relabeled processed work")
local queuedNext = Run("SWORD")
AssertReason(queuedNext, "COLD_BUILD", "CHARACTER_CAPABILITY_CHANGED", "later queued invalidation was not preserved for the next build")

-- Defensive inference for identity transitions.
P.weaponCandidateIndex.format = P.WEAPON_INDEX_FORMAT + 1
local formatMismatch = Run("SWORD")
AssertReason(formatMismatch, "COLD_BUILD", "FORMAT_MISMATCH", "format mismatch was not inferred")

cache.characterKey = "OtherCharacter"
local characterChange = Run("SWORD")
AssertReason(characterChange, "COLD_BUILD", "CHARACTER_CAPABILITY_CHANGED", "character identity change was not inferred")

cache.scanCompletedAt = cache.scanCompletedAt + 100
cache.totalVisuals = cache.totalVisuals + 10
local cacheReplacement = Run("SWORD")
AssertReason(cacheReplacement, "COLD_BUILD", "WARDROBE_CACHE_REPLACED", "wardrobe identity change was not inferred")

-- Missing and unrecognized causes are the only UNKNOWN fallbacks.
P.InvalidateWeaponCandidateIndex(nil)
local missing = Run("SWORD")
AssertReason(missing, "COLD_BUILD", "UNKNOWN", "missing reason did not become UNKNOWN")
assert(missing.invalidationUnknownFallback == true, "missing reason did not set the UNKNOWN fallback flag")
AssertReason(Run("SWORD"), "WARM_REUSE", "NONE", "missing reason leaked into later warm reuse")

P.InvalidateWeaponCandidateIndex("NOT_A_CANONICAL_REASON")
local unrecognized = Run("SWORD")
AssertReason(unrecognized, "COLD_BUILD", "UNKNOWN", "unrecognized reason did not become UNKNOWN")
assert(unrecognized.invalidationUnknownFallback == true, "unrecognized reason did not set the UNKNOWN fallback flag")
AssertReason(Run("SWORD"), "WARM_REUSE", "NONE", "unrecognized reason leaked into later warm reuse")

print("PASS v1.9.0.13 weapon-index invalidation lifecycle: cold, warm, partial, idle, canonical transitions, inference, repair, and UNKNOWN isolation")
