function time() return 1000 end
QuestChronicleDB = { wardrobe = { cacheVersion = 7, bySlot = {} } }
local notifications = 0
QuestChronicle = {
    Wardrobe = { _Private = {}, scanning = false },
    Notify = function() notifications = notifications + 1 end,
}
local Wardrobe = QuestChronicle.Wardrobe
local P = Wardrobe._Private
function P.EnsureCache() return QuestChronicleDB.wardrobe end

local timerCallback
C_Timer = { After = function(_, callback) timerCallback = callback end }
C_Item = {
    GetItemInfo = function(itemID)
        return "Loaded Item", "item:" .. tostring(itemID), 2, 10, 1,
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

local source = {
    visualID = 10, sourceID = 10, itemID = 1010,
    name = "Appearance 10", eraManifestVersion = 3,
    eraManifestSignature = "10", eraSourceIDs = { 10 }, eraItemIDs = { 1010 },
    eraEvidenceState = "PENDING", eraEvidencePending = true,
    eraEvidencePendingItemIDs = { 1010 }, eraEvidenceRetryAt = 1030,
}
P.StorePersistentEraEvidence(source, {
    pending = true, reason = "item loading", pendingItemIDs = { 1010 },
}, 1, 2)
P.RegisterCurrentGenerationSource(source)
P.itemMetadataWatch[1010] = setmetatable({ [source] = true }, { __mode = "k" })
local queued = 0
P.QueuePendingEraEvidenceReevaluation = function() queued = queued + 1 return true end

Wardrobe.QueueItemMetadataUpdate(1010, true, "GET_ITEM_INFO_RECEIVED")
Wardrobe.QueueItemMetadataUpdate(1010, true, "ITEM_DATA_LOAD_RESULT")
assert(timerCallback, "item-data batch was not scheduled")
timerCallback()
local evidence, record = P.GetPersistentEraEvidence(source, 2)
assert(evidence and record.state == "STALE", "loaded dependency was not retained for outcome comparison")
local stats = P.GetGenerationCacheSessionStats()
assert(stats.pendingEvidenceReopened == 1 and queued == 1,
    "duplicate item events queued evidence more than once")
assert(stats.dependenciesSatisfied == 1, "resolved item dependency was not counted")
assert(stats.itemEventsCoalesced >= 1, "duplicate item events were not coalesced")
assert(notifications == 1, "representative metadata hydration did not produce one targeted notification")

Wardrobe.QueueItemMetadataUpdate(1010, true, "ITEM_DATA_LOAD_RESULT")
assert(timerCallback, "second item-data batch was not scheduled")
timerCallback()
stats = P.GetGenerationCacheSessionStats()
assert(stats.pendingEvidenceReopened == 1 and queued == 1,
    "stable repeat event queued already-satisfied evidence")
assert(stats.itemCallbacksReceived == 3,
    "stable repeat callback was not counted without reopening evidence")
assert(notifications == 1, "stable repeat event caused an unnecessary UI notification")
print("PASS item-data batch precision: duplicate callbacks coalesce, exact dependencies queue once, and stable repeats cause no cache churn")
