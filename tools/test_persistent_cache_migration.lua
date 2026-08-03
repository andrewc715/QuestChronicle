function time() return 1000 end
QuestChronicleDB = {
    wardrobe = {
        cacheVersion = 7,
        bySlot = {
            CHEST = {
                {
                    visualID = 50,
                    sourceID = 10,
                    itemID = 500,
                    metadataRevision = 7,
                    eraManifestVersion = 3,
                    eraManifestSignature = "10,11",
                    eraSourceIDs = { 10, 11 },
                    eraItemIDs = { 500, 501 },
                    eraEvidenceVersion = 2,
                    eraEvidenceVisualID = 50,
                    eraEvidenceManifestVersion = 3,
                    eraEvidenceManifestSignature = "10,11",
                    eraEvidenceMetadataRevision = 7,
                    eraEvidenceState = "RESOLVED",
                    eraEvidenceExpansionID = 2,
                    eraEvidenceMethod = "set",
                    eraEvidenceLabel = "set Legacy",
                    eraEvidenceSourceID = 10,
                    eraEvidenceItemID = 500,
                    eraEvidenceCandidateCount = 2,
                },
            },
        },
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

P.EnsurePersistentGenerationCache()
local diagnostics = Wardrobe.GetGenerationCacheDiagnostics()
assert(diagnostics.loadedEvidence == 0, "fresh a8 store unexpectedly loaded records")
assert(diagnostics.migratedEvidence == 1, "a7 source evidence was not migrated")
local rebuilt = {
    visualID = 50,
    sourceID = 10,
    itemID = 500,
    metadataRevision = 1,
    eraManifestVersion = 3,
    eraManifestSignature = "10,11",
    eraSourceIDs = { 10, 11 },
    eraItemIDs = { 500, 501 },
}
local evidence = P.GetPersistentEraEvidence(rebuilt, 2)
assert(evidence and evidence.expansionID == 2, "migrated a7 evidence was not reusable after rebuild")
print("PASS persistent cache migration: legacy source evidence enters the dedicated SavedVariables store")
