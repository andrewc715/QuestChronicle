function time() return 1000 end
QuestChronicleDB = { wardrobe = { cacheVersion = 7, bySlot = {} } }
QuestChronicle = { Wardrobe = { _Private = {} } }
local Wardrobe = QuestChronicle.Wardrobe
local P = Wardrobe._Private
function P.EnsureCache() return QuestChronicleDB.wardrobe end

local loadedExpansion = {}
C_Item = {
    GetItemInfo = function(itemID)
        local expansionID = loadedExpansion[tonumber(itemID)]
        if expansionID == nil then return nil end
        return "Item " .. tostring(itemID), "item:" .. tostring(itemID), 2, 10, 1,
            "Armor", "Plate", 1, "INVTYPE_CHEST", 134400, 1, 4, 4, 1, expansionID
    end,
    RequestLoadItemDataByID = function() end,
}

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationCacheStore.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheAccess.lua")
dofile(base .. "Core/Wardrobe/GenerationDependencyIndex.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheInvalidation.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheDiagnostics.lua")
dofile(base .. "Core/Wardrobe/AppearanceMetadata.lua")

local function Source(visualID)
    return {
        visualID = visualID, sourceID = visualID, itemID = visualID + 1000,
        eraManifestVersion = 3, eraManifestSignature = tostring(visualID),
        eraSourceIDs = { visualID }, eraItemIDs = { visualID + 1000 },
    }
end

local queued = 0
P.QueuePendingEraEvidenceReevaluation = function() queued = queued + 1 return true end

local resolved = Source(10)
loadedExpansion[resolved.itemID] = 2
P.StorePersistentEraEvidence(resolved, {
    expansionID = 2, method = "set", sourceID = 10, candidateCount = 1,
}, 1, 2)
P.StorePersistentGenerationPrecheck(resolved, "pre", true, "eligible", "ok")
P.StorePersistentGenerationEligibility(resolved, "final", true, "eligible", "ok")
P.InvalidateSourceEraEvidence(resolved, "ITEM_DATA_LOADED", false, resolved.itemID, {
    success = true, loaded = true,
})
assert(P.GetPersistentEraEvidence(resolved, 2), "stable resolved evidence was discarded by ordinary item-data load")
assert(P.GetPersistentGenerationPrecheck(resolved, "pre"), "unchanged precheck was discarded by ordinary item-data load")
assert(P.GetPersistentGenerationEligibility(resolved, "final"), "unchanged eligibility was discarded by ordinary item-data load")

local pending = Source(20)
loadedExpansion[pending.itemID] = 2
pending.eraEvidenceRetryAt = 1030
P.StorePersistentEraEvidence(pending, {
    pending = true, reason = "item loading", pendingItemIDs = { pending.itemID },
}, 1, 2)
P.StorePersistentGenerationPrecheck(pending, "pre", true, "eligible", "ok")
P.StorePersistentGenerationEligibility(pending, "final", false, "pending", "loading")
P.InvalidateSourceEraEvidence(pending, "ITEM_DATA_LOADED", false, pending.itemID, {
    success = true, loaded = true,
})
local pendingEvidence, pendingRecord = P.GetPersistentEraEvidence(pending, 2)
assert(pendingEvidence and pendingRecord.state == "STALE",
    "relevant item dependency was discarded before outcome comparison")
assert(P.GetPersistentGenerationEligibility(pending, "final"),
    "eligibility was invalidated before evidence outcome changed")
assert(P.GetPersistentGenerationPrecheck(pending, "pre"),
    "era-independent precheck was unnecessarily discarded")
assert(queued == 1, "resolved dependency did not queue one reevaluation")

local tracking = Source(30)
loadedExpansion[tracking.itemID] = 2
tracking.eraEvidenceRetryAt = 1030
P.StorePersistentEraEvidence(tracking, {
    pending = true, reason = "tracking pending", trackingPending = true,
}, 1, 2)
P.InvalidateSourceEraEvidence(tracking, "ITEM_DATA_LOADED", false, tracking.itemID, {
    success = true, loaded = true,
})
assert(P.GetPersistentEraEvidence(tracking, 2), "tracking-only pending evidence was reopened by unrelated item data")

local unrelated = Source(40)
loadedExpansion[unrelated.itemID] = 2
unrelated.eraEvidenceRetryAt = 1030
P.StorePersistentEraEvidence(unrelated, {
    pending = true, reason = "other item loading", pendingItemIDs = { 999999 },
}, 1, 2)
P.InvalidateSourceEraEvidence(unrelated, "ITEM_DATA_LOADED", false, unrelated.itemID, {
    success = true, loaded = true,
})
assert(P.GetPersistentEraEvidence(unrelated, 2), "unrelated item data reopened pending evidence")

local changed = Source(50)
changed.itemMetadataVerified = true
changed.itemMetadataItemID = changed.itemID
changed.itemMetadataFingerprint = P.BuildStableItemMetadataFingerprint(
    changed.itemID, 1, "Armor", "Plate", "INVTYPE_CHEST", 4, 4
)
loadedExpansion[changed.itemID] = 2
P.StorePersistentEraEvidence(changed, {
    expansionID = 1, method = "item", sourceID = changed.sourceID,
    itemID = changed.itemID, candidateCount = 1,
}, 1, 2)
local loaded, presentationChanged, identityChanged = P.HydrateSourceItemMetadata(changed)
assert(loaded and presentationChanged and identityChanged, "genuine item metadata identity change was not detected")
assert(P.GetPersistentEraEvidence(changed, 2) == nil, "item-derived evidence survived a genuine metadata identity change")

local scanning = Source(60)
loadedExpansion[scanning.itemID] = 2
scanning.eraEvidenceRetryAt = 1030
P.StorePersistentEraEvidence(scanning, {
    pending = true, reason = "loading", pendingItemIDs = { scanning.itemID },
}, 1, 2)
P.InvalidateSourceEraEvidence(scanning, "ITEM_DATA_LOADED", true, scanning.itemID, {
    success = true, loaded = true,
})
assert(P.GetPersistentEraEvidence(scanning, 2), "scan-time item callback discarded persistent evidence before cache transfer")

local stats = P.GetGenerationCacheSessionStats()
assert(stats.pendingEvidenceReopened == 2, "pending reevaluation diagnostic was not precise")
assert(stats.dependenciesSatisfied == 2, "dependency satisfaction diagnostic was not precise")
assert(stats.metadataIdentityChanges == 1, "identity-change diagnostic was not precise")
assert(stats.itemEventsIgnored >= 3, "stable item-data events were not counted as ignored")
print("PASS item-data dependency precision: stable events are ignored, pending records survive until outcome comparison, and genuine identity changes invalidate")
