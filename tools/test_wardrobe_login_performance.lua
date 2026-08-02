QuestChronicle = { Wardrobe = { _Private = {} } }
local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local getItemInfoCalls = 0
local requestCalls = 0
C_Item = {
    GetItemInfo = function(itemID)
        getItemInfoCalls = getItemInfoCalls + 1
        return "Item " .. tostring(itemID), "item:" .. tostring(itemID), 2, 1, 1, 1,
            "Armor", "Plate", 1, "INVTYPE_CHEST", 1, 0, 4, 4, 1, 1
    end,
    RequestLoadItemDataByID = function()
        requestCalls = requestCalls + 1
    end,
}
C_TransmogCollection = {
    GetAllAppearanceSources = function(visualID) return { visualID } end,
    GetSourceItemID = function(sourceID) return sourceID + 10000 end,
}
function P.SafeCall(func, ...)
    if type(func) ~= "function" then return nil end
    local ok, a, b, c, d, e, f = pcall(func, ...)
    if ok then return a, b, c, d, e, f end
end
function time() return 123 end
assert(loadfile("Core/Wardrobe/AppearanceMetadata.lua"))()

local cache = { bySlot = { CHEST = {} } }
P.BeginAppearanceMetadataRefresh()
for index = 1, 250 do
    local source = {
        sourceID = index,
        visualID = index,
        itemID = index + 10000,
        slotKey = "CHEST",
        eraManifestVersion = P.ERA_MANIFEST_VERSION,
        eraSourceIDs = { index },
        eraItemIDs = { index + 10000, index + 20000, index + 30000 },
    }
    table.insert(cache.bySlot.CHEST, source)
    P.TrackAppearanceMetadata(source, false)
end
P.FinalizeAppearanceMetadataRefresh(cache, true)
assert(getItemInfoCalls == 250, "scan hydration should query only each representative item once")
assert(requestCalls == 0, "loaded representative items must not trigger sibling request storms")

getItemInfoCalls = 0
requestCalls = 0
P.RestoreAppearanceMetadataWatchIndex(cache)
assert(getItemInfoCalls == 0 and requestCalls == 0, "watch restoration must not hydrate or request item data")

-- Cooperative slot worker: a large slot must be spread across multiple steps.
local clock = 0
function GetTime()
    clock = clock + 0.00005
    return clock
end
local appearances = {}
for index = 1, 103 do
    table.insert(appearances, { visualID = index, isCollected = true, isHideVisual = false })
end
C_TransmogCollection.GetCategoryCollectedCount = function() return #appearances end
function P.GetTransmogLocation() return {} end
function P.ResolveCategoryIDs() return { 1 } end
function P.GetCategoryAppearancesRobust() return appearances, "mock" end
function P.GetKnownSources(appearance)
    return { { sourceID = appearance.visualID, itemID = appearance.visualID + 50000 } }
end
function P.NormalizeSource(source, appearance, slotKey, categoryID)
    source.visualID = appearance.visualID
    source.slotKey = slotKey
    source.categoryID = categoryID
    source.name = "Source " .. tostring(source.sourceID)
    return source
end
function Wardrobe.ValidateSource() return true end
function P.BetterSource(candidate, current) return current == nil or candidate.sourceID < current.sourceID end
function P.AttachEraSourceManifest() end
function P.TrackAppearanceMetadata() end
assert(loadfile("Core/Wardrobe/CollectionScanWorker.lua"))()

local worker = P.CreateSlotScanWorker({ key = "CHEST", slotName = "CHESTSLOT" })
local steps = 0
local done, results, diagnostics
repeat
    steps = steps + 1
    done, results, diagnostics = P.StepSlotScanWorker(worker, 18, 0.003)
until done
assert(steps > 1, "large slots must yield across multiple timer steps")
assert(#results == #appearances, "cooperative worker must preserve every appearance")
assert(diagnostics.compatibleVisuals == #appearances, "cooperative diagnostics must match the synchronous result")

print(string.format(
    "PASS wardrobe login performance: representative queries=%d sibling requests=%d worker steps=%d visuals=%d",
    250, requestCalls, steps, #results
))
