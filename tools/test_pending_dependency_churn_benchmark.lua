function time() return 1000 end
QuestChronicleDB = { wardrobe = { cacheVersion = 7, bySlot = {} } }
QuestChronicle = { Wardrobe = { _Private = {}, scanning = false } }
local Wardrobe = QuestChronicle.Wardrobe
local P = Wardrobe._Private
function P.EnsureCache() return QuestChronicleDB.wardrobe end

local timerCallback
C_Timer = { After = function(_, callback) timerCallback = callback end }
C_Item = {
    GetItemInfo = function(itemID)
        return "Loaded " .. tostring(itemID), "item:" .. tostring(itemID), 2, 10, 1,
            "Armor", "Plate", 1, "INVTYPE_CHEST", 134400, 1, 4, 4, 1, 2
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

local count = 850
for index = 1, count do
    local itemID = 200000 + index
    local source = {
        visualID = index, sourceID = index, itemID = itemID,
        eraManifestVersion = 3, eraManifestSignature = tostring(index),
        eraSourceIDs = { index }, eraItemIDs = { itemID },
        eraEvidenceRetryAt = 1600,
    }
    P.StorePersistentEraEvidence(source, {
        pending = true, pendingItemIDs = { itemID }, trackingPending = true,
        reason = "item and tracking pending",
    }, 1, 2)
    P.RegisterCurrentGenerationSource(source)
    Wardrobe.QueueItemMetadataUpdate(itemID, true, "GET_ITEM_INFO_RECEIVED")
    Wardrobe.QueueItemMetadataUpdate(itemID, true, "ITEM_DATA_LOAD_RESULT")
end
assert(timerCallback, "callback storm did not schedule a batch")
timerCallback()

local evidence = select(1, P.GetPersistentGenerationCacheCounts())
local stats = P.GetGenerationCacheSessionStats()
assert(evidence == count, "tracking-pending callback storm discarded evidence")
assert(stats.itemCallbacksReceived == count * 2, "callback count did not include both events")
assert(stats.itemEventsCoalesced == count, "duplicate item events did not coalesce")
assert(stats.dependencyRecordsExamined == count, "exact dependency records were not isolated")
assert(stats.dependenciesSatisfied == count, "loaded dependencies were not satisfied")
assert(stats.evidenceOutcomesUnchanged == count,
    "tracking-only fail-closed outcomes were not preserved")
assert(stats.pendingEvidenceReopened == 0,
    "tracking-only outcomes queued unnecessary evidence recomputation")
assert(stats.invalidated == 0 and stats.downstreamRecordsInvalidated == 0,
    "tracking-only callback storm caused cache churn")
print(string.format(
    "PASS live churn benchmark: %d callback pairs became tracking-only with 0 reevaluations and 0 invalidations",
    count
))
