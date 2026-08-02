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
dofile(base .. "Core/Wardrobe/GenerationCacheInvalidation.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheDiagnostics.lua")
dofile(base .. "Core/Wardrobe/AppearanceMetadata.lua")

local stableCount, reopenCount = 1700, 40
local sources = {}
for index = 1, stableCount + reopenCount do
    local itemID = 100000 + index
    local source = {
        visualID = index, sourceID = index, itemID = itemID,
        eraManifestVersion = 3, eraManifestSignature = tostring(index),
        eraSourceIDs = { index }, eraItemIDs = { itemID },
        eraEvidenceRetryAt = 1030,
    }
    local result
    if index <= stableCount then
        result = { pending = true, trackingPending = true, reason = "tracking pending" }
    else
        result = { pending = true, pendingItemIDs = { itemID }, reason = "item loading" }
    end
    sources[#sources + 1] = source
    P.StorePersistentEraEvidence(source, result, 1, 2)
    P.itemMetadataWatch[itemID] = setmetatable({ [source] = true }, { __mode = "k" })
    Wardrobe.QueueItemMetadataUpdate(itemID, true, "ITEM_DATA_LOAD_RESULT")
end
assert(timerCallback, "large item-data batch was not scheduled")
timerCallback()

local evidence = select(1, P.GetPersistentGenerationCacheCounts())
local stats = P.GetGenerationCacheSessionStats()
assert(evidence == stableCount, "stable tracking-pending evidence was lost from the batch")
assert(stats.pendingEvidenceReopened == reopenCount, "relevant item-pending records did not reopen exactly once")
assert(stats.itemEventsIgnored == stableCount, "stable item-data events were not ignored exactly")
assert(stats.invalidated == reopenCount, "batch invalidated more than the relevant pending evidence")
print(string.format(
    "PASS item-data invalidation benchmark: %d stable events ignored, %d relevant pending records reopened, %d total invalidations",
    stableCount, reopenCount, stats.invalidated
))
