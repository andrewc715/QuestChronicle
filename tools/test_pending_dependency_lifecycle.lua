function time() return 1000 end
QuestChronicleDB = { wardrobe = { cacheVersion = 7, bySlot = {} } }
QuestChronicle = { Wardrobe = { _Private = {}, scanning = false } }
local Wardrobe = QuestChronicle.Wardrobe
local P = Wardrobe._Private
function P.EnsureCache() return QuestChronicleDB.wardrobe end

C_Item = {
    GetItemInfo = function(itemID)
        return "Item " .. tostring(itemID), "item:" .. tostring(itemID), 2, 10, 1,
            "Armor", "Plate", 1, "INVTYPE_CHEST", 134400, 1, 4, 4, 1, 2
    end,
}

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationCacheStore.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheAccess.lua")
dofile(base .. "Core/Wardrobe/GenerationDependencyIndex.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheInvalidation.lua")

local function Source(id, items)
    return {
        visualID = id, sourceID = id, itemID = items[1],
        eraManifestVersion = 3, eraManifestSignature = tostring(id),
        eraSourceIDs = { id }, eraItemIDs = items,
        eraEvidenceRetryAt = 1600,
    }
end

local multiple = Source(10, { 1010, 1011 })
P.StorePersistentEraEvidence(multiple, {
    pending = true, pendingItemIDs = { 1010, 1011 }, reason = "loading",
}, 1, 2)
local queued = 0
P.QueuePendingEraEvidenceReevaluation = function() queued = queued + 1 return true end

P.InvalidatePersistentGenerationCacheForItemData(multiple, "ITEM_DATA_LOADED", 1010, {
    success = true, loaded = true,
})
local evidence, record = P.GetPersistentEraEvidence(multiple, 2)
assert(evidence and record.state == "PENDING_ITEMS", "first dependency did not remain pending")
assert(#record.pendingItemIDs == 1 and record.pendingItemIDs[1] == 1011,
    "first dependency did not preserve the unresolved item")
assert(queued == 0, "partial dependency resolution queued a premature reevaluation")

P.InvalidatePersistentGenerationCacheForItemData(multiple, "ITEM_DATA_LOADED", 1011, {
    success = true, loaded = true,
})
evidence, record = P.GetPersistentEraEvidence(multiple, 2)
assert(evidence and record.state == "STALE" and not record.pendingItemIDs,
    "fully satisfied dependencies were not retained for comparison")
assert(queued == 1, "fully satisfied dependencies did not queue exactly once")

local tracking = Source(20, { 2020 })
P.StorePersistentEraEvidence(tracking, {
    pending = true, pendingItemIDs = { 2020 }, trackingPending = true,
    reason = "tracking pending",
}, 1, 2)
P.StorePersistentGenerationEligibility(tracking, "final", false, "pending", "loading")
P.InvalidatePersistentGenerationCacheForItemData(tracking, "ITEM_DATA_LOADED", 2020, {
    success = true, loaded = true,
})
local trackingEvidence, trackingRecord = P.GetPersistentEraEvidence(tracking, 2)
assert(trackingEvidence and trackingRecord.state == "TRACKING_ONLY",
    "tracking dependency did not become tracking-only")
assert(P.GetPersistentGenerationEligibility(tracking, "final"),
    "tracking-only transition invalidated unchanged eligibility")
assert(queued == 1, "tracking-only transition queued unnecessary reevaluation")

local stats = P.GetGenerationCacheSessionStats()
assert(stats.dependencyRecordsExamined == 3, "dependency examination count was incorrect")
assert(stats.dependenciesSatisfied == 3, "dependency satisfaction count was incorrect")
assert(stats.dependenciesStillPending == 1, "remaining dependency count was incorrect")
assert(stats.evidenceOutcomesUnchanged == 1, "tracking-only unchanged outcome was not counted")
assert(stats.invalidated == 0, "dependency bookkeeping invalidated cache records")
print("PASS pending dependency lifecycle: partial dependencies remain indexed, tracking-only outcomes stay cached, and no premature invalidation occurs")
