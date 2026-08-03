local now = 1000
function time() return now end

QuestChronicleDB = {
    wardrobe = {
        cacheVersion = 7,
        bySlot = {},
    },
}
QuestChronicle = { Wardrobe = { _Private = {} } }
local Wardrobe = QuestChronicle.Wardrobe
local P = Wardrobe._Private
function P.EnsureCache() return QuestChronicleDB.wardrobe end

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationCacheStore.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheAccess.lua")
dofile(base .. "Core/Wardrobe/GenerationDependencyIndex.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheDiagnostics.lua")

local source = {
    visualID = 50,
    sourceID = 10,
    itemID = 500,
    eraManifestVersion = 3,
    eraManifestSignature = "10,11",
    eraSourceIDs = { 10, 11 },
    eraItemIDs = { 500, 501 },
    eraEvidenceRetryAt = nil,
}
local evidence = {
    expansionID = 2,
    method = "set",
    label = "set Test",
    sourceID = 10,
    itemID = 500,
    candidateCount = 2,
}
P.StorePersistentEraEvidence(source, evidence, 2, 2)
local precheckKey = "context|source|none"
local eligibilityKey = "context|TRAVELER|source|none|evidence"
P.StorePersistentGenerationPrecheck(source, precheckKey, true, "eligible", "ok")
P.StorePersistentGenerationEligibility(source, eligibilityKey, true, "eligible", "ok")

local warm = P.GetPersistentEraEvidence(source, 2)
assert(warm and warm.expansionID == 2, "warm persistent era evidence was not returned")
assert(P.GetPersistentGenerationPrecheck(source, precheckKey).eligible, "warm precheck was not returned")
assert(P.GetPersistentGenerationEligibility(source, eligibilityKey).eligible, "warm eligibility was not returned")

-- Simulate /reload: runtime session state disappears while SavedVariables remain.
P.generationCacheSessionInitialized = nil
P.generationCacheSessionStats = nil
P.generationCacheScanSeen = nil
local rebuilt = {
    visualID = 50,
    sourceID = 10,
    itemID = 500,
    eraManifestVersion = 3,
    eraManifestSignature = "10,11",
    eraSourceIDs = { 10, 11 },
    eraItemIDs = { 500, 501 },
}
local restored = P.GetPersistentEraEvidence(rebuilt, 2)
assert(restored and restored.expansionID == 2 and restored.persistent, "era evidence did not survive simulated reload")
assert(P.GetPersistentGenerationPrecheck(rebuilt, precheckKey), "precheck did not survive simulated reload")
assert(P.GetPersistentGenerationEligibility(rebuilt, eligibilityKey), "eligibility did not survive simulated reload")
local diagnostics = Wardrobe.GetGenerationCacheDiagnostics()
assert(diagnostics.loadedEvidence == 1, "reload diagnostics did not count loaded evidence")
assert(diagnostics.loadedPrechecks == 1 and diagnostics.loadedEligibility == 1,
    "reload diagnostics did not count loaded eligibility records")

P.BeginPersistentGenerationCacheScan()
P.NotePersistentGenerationCacheRestore(rebuilt, true, false, false)
P.FinishPersistentGenerationCacheScan()
diagnostics = Wardrobe.GetGenerationCacheDiagnostics()
assert(diagnostics.retainedEvidenceAfterScan == 1, "scan diagnostics did not retain restored evidence")

local changed = {
    visualID = 50,
    sourceID = 10,
    itemID = 500,
    eraManifestVersion = 3,
    eraManifestSignature = "10,12",
    eraSourceIDs = { 10, 12 },
    eraItemIDs = { 500, 502 },
}
assert(P.GetPersistentEraEvidence(changed, 2) == nil, "changed manifest reused stale persistent evidence")
diagnostics = Wardrobe.GetGenerationCacheDiagnostics()
assert(diagnostics.invalidated >= 2, "identity invalidation did not remove evidence and dependent eligibility")
assert((diagnostics.invalidationReasons.EVIDENCE_IDENTITY_CHANGED or 0) >= 2,
    "identity invalidation reason was not recorded")

local pending = {
    visualID = 60,
    sourceID = 20,
    itemID = 600,
    eraManifestVersion = 3,
    eraManifestSignature = "20",
    eraSourceIDs = { 20 },
    eraItemIDs = { 600 },
    eraEvidenceRetryAt = now + 30,
}
P.StorePersistentEraEvidence(pending, { pending = true, reason = "loading" }, 1, 2)
assert(P.GetPersistentEraEvidence(pending, 2), "pending evidence did not cache before retry")
now = now + 31
assert(P.GetPersistentEraEvidence(pending, 2) == nil, "expired pending evidence did not reopen")

print("PASS persistent generation cache: evidence and eligibility survive reload, scans retain records, and invalidations are explained")
