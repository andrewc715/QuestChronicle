function time() return 1000 end
QuestChronicleDB = { wardrobe = { cacheVersion = 7, bySlot = {} } }
QuestChronicle = {
    Wardrobe = { _Private = {}, scanning = false },
    ZoneStyle = { _Private = {}, expansions = { [2] = { label = "Wrath" } } },
}
local Wardrobe = QuestChronicle.Wardrobe
local WP = Wardrobe._Private
local ZoneStyle = QuestChronicle.ZoneStyle
local ZP = ZoneStyle._Private
function WP.EnsureCache() return QuestChronicleDB.wardrobe end
function ZP.Normalize(value) return string.lower(tostring(value or "")) end
function ZP.TextMatchesAny() return false end
function ZP.SafeCall(callback, ...) return callback(...) end
function ZP.GetCuratedSourceOrigin() return nil end
function ZP.GetTrackedSourceOrigin() return nil end
function ZP.GetAppearanceTrackingType() return nil end
ZP.trackedOriginCache = {}

local callbacks = {}
C_Timer = { After = function(_, callback) callbacks[#callbacks + 1] = callback end }
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
dofile("Core/ZoneStyle/EraExecution.lua")
dofile(base .. "Core/ZoneStyle/EraEvidence.lua")
dofile(base .. "Core/Wardrobe/PendingEvidenceResolver.lua")

local source = {
    visualID = 50, sourceID = 50, itemID = 5050,
    name = "Appearance 50", metadataRevision = 0,
    eraManifestVersion = 3, eraManifestSignature = "50",
    eraSourceIDs = { 50 }, eraItemIDs = { 5050 },
    eraEvidenceRetryAt = 1600,
}
WP.StorePersistentEraEvidence(source, {
    pending = true, pendingItemIDs = { 5050 }, reason = "loading",
    candidateCount = 1,
}, 1, ZP.ERA_EVIDENCE_VERSION)
WP.StorePersistentGenerationPrecheck(source, "pre", true, "eligible", "ok")
WP.StorePersistentGenerationEligibility(source, "final", false, "pending", "loading")

local cleared = WP.InvalidatePersistentGenerationCacheForItemData(
    source, "ITEM_DATA_LOADED", 5050, { success = true, loaded = true }
)
assert(cleared == false, "dependency resolution cleared evidence before comparison")
assert(#callbacks == 1, "reevaluation worker was not scheduled")
while #callbacks > 0 do
    local callback = table.remove(callbacks, 1)
    callback()
end

local evidence, record = WP.GetPersistentEraEvidence(source, ZP.ERA_EVIDENCE_VERSION)
assert(evidence and evidence.expansionID == 2 and record.state == "RESOLVED",
    "reevaluation did not replace pending evidence with resolved evidence")
assert(WP.GetPersistentGenerationPrecheck(source, "pre"),
    "era-independent precheck was lost after changed evidence")
assert(WP.GetPersistentGenerationEligibility(source, "final") == nil,
    "changed evidence did not invalidate dependent eligibility")

local stats = WP.GetGenerationCacheSessionStats()
assert(stats.evidenceOutcomesChanged == 1, "changed outcome was not counted")
assert(stats.downstreamRecordsInvalidated == 1,
    "only the dependent eligibility record should have been invalidated")
assert(stats.invalidated == 1, "changed outcome invalidation count was incorrect")
print("PASS pending dependency outcome: resolved item evidence is compared cooperatively and invalidates only dependent eligibility when the outcome changes")
