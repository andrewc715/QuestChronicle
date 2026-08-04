QuestChronicle = { Wardrobe = { _Private = {} } }
local Wardrobe, P = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
local stats = {
    loadedEvidence = 10, loadedPrechecks = 20, loadedEligibility = 30,
    migratedEvidence = 2, addedEvidence = 3, addedPrechecks = 4, addedEligibility = 5,
    invalidated = 6, invalidationReasons = { TEST_REASON = 6 },
    itemCallbacksReceived = 7, dependencyRecordsExamined = 8,
}
P.GetGenerationCacheSessionStats = function() return stats end
P.GetPersistentGenerationCacheCounts = function() error("scalar snapshot performed a full cache recount") end

dofile("Core/Wardrobe/GenerationCacheCounters.lua")
dofile("Core/Wardrobe/GenerationCacheDiagnostics.lua")
P.InitializeGenerationCacheCountLedger(100, 200, 300)
P.AdjustGenerationCacheCountLedger(1, -2, 3)
local snapshot = Wardrobe.GetGenerationCacheDiagnostics()
assert(snapshot.persistentEvidence == 101, "evidence ledger mismatch")
assert(snapshot.persistentPrechecks == 198, "precheck ledger mismatch")
assert(snapshot.persistentEligibility == 303, "eligibility ledger mismatch")
assert(snapshot.loadedEvidence == 10 and snapshot.migratedEvidence == 2, "loaded scalar diagnostics changed")
assert(snapshot.invalidationReasons.TEST_REASON == 6, "invalidation reason snapshot changed")
snapshot.invalidationReasons.TEST_REASON = 999
assert(stats.invalidationReasons.TEST_REASON == 6, "cache scalar snapshot was not immutable")
local start = P.GetGenerationCacheCounterSnapshot()
stats.addedEvidence = 5
stats.invalidated = 8
local perf = P.BuildGenerationCachePerformance(start)
assert(perf.addedDuringGeneration == 2, "generation cache addition delta changed")
assert(perf.invalidatedDuringGeneration == 2, "generation cache invalidation delta changed")
print("PASS v1.9.0.12 cache diagnostics: constant-time scalar ledger, immutable reasons, and exact deltas")
