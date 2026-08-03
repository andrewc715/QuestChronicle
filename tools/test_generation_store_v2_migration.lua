function time() return 1000 end
QuestChronicleDB = {
    wardrobe = {
        cacheVersion = 7,
        bySlot = {},
        generationCache = {
            version = 1,
            visuals = {
                ["77"] = {
                    evidence = {
                        evidenceVersion = 2,
                        visualID = 77,
                        manifestVersion = 3,
                        manifestSignature = "77",
                        fingerprint = "77|3|77|7070",
                        state = "PENDING",
                        pending = true,
                        pendingItemIDs = { 7070 },
                        trackingPending = true,
                        candidateCount = 1,
                        retryAt = 1600,
                        updatedAt = 900,
                    },
                    prechecks = {
                        pre = {
                            eligible = true, sourceIdentity = "77:77:7070:3:77",
                            fingerprint = "77|3|77|7070|0|0|0", updatedAt = 900,
                        },
                    },
                },
            },
        },
    },
}
QuestChronicle = { Wardrobe = { _Private = {} } }
local P = QuestChronicle.Wardrobe._Private
function P.EnsureCache() return QuestChronicleDB.wardrobe end

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationCacheStore.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheAccess.lua")
dofile(base .. "Core/Wardrobe/GenerationDependencyIndex.lua")

local store = P.EnsurePersistentGenerationCache()
assert(store.version == 2, "generation cache v1 was not upgraded in place")
assert(store.visuals["77"] and store.visuals["77"].evidence,
    "generation cache v1 evidence was purged during migration")
assert(store.visuals["77"].evidence.state == "PENDING_ITEMS",
    "legacy pending state was not normalized")
local sources = P.GetPendingEraDependencySources(7070)
assert(#sources == 0, "dependency index unexpectedly invented a runtime source")
assert(P.pendingEraDependenciesByItem["7070"]
    and P.pendingEraDependenciesByItem["7070"]["77"],
    "migrated dependency was not indexed")
print("PASS generation cache v2 migration: v1 records upgrade in place and pending dependencies rebuild without a cache purge")
