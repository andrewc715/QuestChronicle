function time() return 1000 end
QuestChronicleDB = { wardrobe = { cacheVersion = 7, bySlot = {} } }
QuestChronicle = { Wardrobe = { _Private = {} } }
local Wardrobe = QuestChronicle.Wardrobe
local P = Wardrobe._Private
function P.EnsureCache() return QuestChronicleDB.wardrobe end

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationCacheStore.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheDiagnostics.lua")
dofile(base .. "Core/Wardrobe/AppearanceMetadata.lua")

local function Source(visualID)
    return {
        visualID = visualID, sourceID = visualID, itemID = visualID + 1000,
        eraManifestVersion = 3, eraManifestSignature = tostring(visualID),
        eraSourceIDs = { visualID }, eraItemIDs = { visualID + 1000 },
    }
end

local resolved = Source(10)
P.StorePersistentEraEvidence(resolved, {
    expansionID = 2, method = "set", sourceID = 10, candidateCount = 1,
}, 1, 2)
P.StorePersistentGenerationPrecheck(resolved, "pre", true, "eligible", "ok")
P.StorePersistentGenerationEligibility(resolved, "final", true, "eligible", "ok")
P.InvalidateSourceEraEvidence(resolved, "ITEM_DATA_LOADED", false)
assert(P.GetPersistentEraEvidence(resolved, 2), "stable resolved evidence was discarded by ordinary item-data load")
assert(P.GetPersistentGenerationPrecheck(resolved, "pre"), "unchanged precheck was discarded by ordinary item-data load")
assert(P.GetPersistentGenerationEligibility(resolved, "final"), "unchanged eligibility was discarded by ordinary item-data load")

local pending = Source(20)
pending.eraEvidenceRetryAt = 1030
P.StorePersistentEraEvidence(pending, { pending = true, reason = "loading" }, 1, 2)
P.StorePersistentGenerationPrecheck(pending, "pre", true, "eligible", "ok")
P.StorePersistentGenerationEligibility(pending, "final", false, "pending", "loading")
P.InvalidateSourceEraEvidence(pending, "ITEM_DATA_LOADED", false)
assert(P.GetPersistentEraEvidence(pending, 2) == nil, "item-data load did not reopen pending era evidence")
assert(P.GetPersistentGenerationEligibility(pending, "final") == nil, "dependent final eligibility survived reopened evidence")
assert(P.GetPersistentGenerationPrecheck(pending, "pre"), "era-independent precheck was unnecessarily discarded")

local scanning = Source(30)
scanning.eraEvidenceRetryAt = 1030
P.StorePersistentEraEvidence(scanning, { pending = true, reason = "loading" }, 1, 2)
P.InvalidateSourceEraEvidence(scanning, "ITEM_DATA_LOADED", true)
assert(P.GetPersistentEraEvidence(scanning, 2), "scan-time item callback discarded persistent evidence before cache transfer")
print("PASS item-data cache invalidation: strong evidence survives, pending evidence reopens, and scan-time callbacks preserve transfer state")
