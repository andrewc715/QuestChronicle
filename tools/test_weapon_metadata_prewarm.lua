QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = {} }
local QC, W, P = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
P.SafeCall = function(fn, ...) if type(fn) == "function" then return fn(...) end end
P.GetTransmogLocation = function() return "LOCATION" end
P.GetCurrentClassID = function() return 1 end
P.slotByKey = { TWO_HAND = { key = "TWO_HAND", slotName = "MAINHANDSLOT" } }
W.weaponSubtypeDefinitions = {}
W.WEAPON_SUBTYPE_ORDER = {}
W.WEAPON_FAMILY_ORDER = {}
W.ValidateSource = function() return true end
P.IsWeaponCategoryPermitted = function() return true, { method = "PHYSICAL_TOPOLOGY_SINGLE_ROUTE" } end
P.MaybeYieldWeaponGeneration = function() end

local categoryCalls, sourceInfoCalls = 0, 0
P.GetCategoryAppearancesRobust = function()
    categoryCalls = categoryCalls + 1
    return { { visualID = 101, isCollected = true, canDisplayOnPlayer = true, isUsable = true } }
end
C_TransmogCollection = {
    GetAppearanceInfoBySource = function()
        sourceInfoCalls = sourceInfoCalls + 1
        return { sourceIsCollected = true, appearanceIsCollected = true, appearanceIsUsable = true, canDisplayOnPlayer = true, isAnySourceValidForPlayer = true }
    end,
}

dofile("Core/Wardrobe/WeaponFilters.lua")
local definition = P.slotByKey.TWO_HAND
P.StoreWeaponGenerationAppearanceIndex(definition, 9, { { visualID = 101, isCollected = true, canDisplayOnPlayer = true, isUsable = true } })
P.StoreWeaponSourceInfo(55, C_TransmogCollection.GetAppearanceInfoBySource(55))
sourceInfoCalls = 0

dofile("Core/Wardrobe/WeaponSelection.lua")
local source = { sourceID = 55, visualID = 101, categoryID = 9, slotKey = "TWO_HAND", sourceIsCollected = true, isCollected = true, appearanceIsCollected = true, itemID = 500 }
local contextA = { validation = {}, appearancesByCategory = {}, locationsBySlot = {}, activeRoute = { id = "R1" }, capabilities = { main = {} } }
local contextB = { validation = {}, appearancesByCategory = {}, locationsBySlot = {}, activeRoute = { id = "R1" }, capabilities = { main = {} } }
local okA = P.ValidateGeneratedWeaponSource(source, "TWO_HAND", "item:100", contextA)
local okB = P.ValidateGeneratedWeaponSource(source, "TWO_HAND", "item:100", contextB)
assert(okA and okB, "prewarmed source should validate")
assert(categoryCalls == 0, "generation must reuse the scan-prewarmed category index")
assert(sourceInfoCalls == 0, "generation must reuse the scan-prewarmed source metadata")
assert(next(P.weaponValidationSessionCache) ~= nil, "validation result must be reusable across armor finalists")

P.ClearWeaponGenerationMetadataCaches()
assert(next(P.weaponGenerationAppearanceIndex) == nil and next(P.weaponSourceInfoCache) == nil and next(P.weaponValidationSessionCache) == nil, "collection invalidation must clear generation metadata caches")
print("PASS weapon metadata prewarm: category, source, and validation results are reused across anchor finalists")
