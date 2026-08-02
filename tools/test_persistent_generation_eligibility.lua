local level = 70
function time() return 1000 end
function UnitClass() return "Warrior", "WARRIOR", 1 end
function UnitRace() return "Human", "Human", 1 end
function UnitLevel() return level end

QuestChronicleDB = { wardrobe = { cacheVersion = 7, bySlot = {} } }
QuestChronicle = {
    Wardrobe = {
        _Private = {},
        GetZonePreferenceKey = function() return "map:530" end,
        GetSourceZonePreference = function() return nil end,
    },
    ZoneStyle = { _Private = {} },
    GetSettings = function() return { restrictOutfitsToZoneEra = true } end,
}
local Wardrobe = QuestChronicle.Wardrobe
local WP = Wardrobe._Private
function WP.EnsureCache() return QuestChronicleDB.wardrobe end
local ZoneStyle = QuestChronicle.ZoneStyle
local P = ZoneStyle._Private
function P.GetReachableMaxPlayerLevel() return 80 end
function ZoneStyle.GetCurrentContext() return { eraMax = 2, provenanceResolved = true, provenanceKey = "outland" } end
function ZoneStyle.ResolveEra() return 2, "The Burning Crusade", "TBC" end
function ZoneStyle.ResolveProvenance() return { label = "Outland" }, "outland" end
function ZoneStyle.GetSourcePreference(source, context)
    return Wardrobe.GetSourceZonePreference(source, context)
end
local precheckCalls, eligibilityCalls = 0, 0
function ZoneStyle.GetSourcePreEraEligibility()
    precheckCalls = precheckCalls + 1
    return true, "eligible", "ok"
end
function ZoneStyle.GetSourceEligibility()
    eligibilityCalls = eligibilityCalls + 1
    return true, "eligible", "ok"
end

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationCacheStore.lua")
dofile(base .. "Core/ZoneStyle/GenerationEligibility.lua")

local source = {
    sourceID = 10, visualID = 50, itemID = 500, metadataRevision = 9,
    eraManifestVersion = 3, eraManifestSignature = "10,11",
    eraSourceIDs = { 10, 11 }, eraItemIDs = { 500, 501 },
    sourceType = 1, categoryID = 4, inventoryType = 5,
    name = "Replica Breastplate", styleName = "Replica Breastplate",
}
local evidence = { expansionID = 2, method = "set", sourceID = 10, candidateCount = 2 }
local context = ZoneStyle.PrepareGenerationEligibilityContext(ZoneStyle.GetCurrentContext())
local eligible, _, _, cached = ZoneStyle.GetSourcePreEraEligibilityCached(source, context)
assert(eligible and not cached and precheckCalls == 1, "first precheck did not populate persistent cache")
eligible, _, _, cached = ZoneStyle.GetSourceEligibilityCached(source, "TRAVELER", context, evidence, true)
assert(eligible and not cached and eligibilityCalls == 1, "first eligibility did not populate persistent cache")

-- New source table and a reset session-local metadata revision simulate the post-scan object after /reload.
source = {
    sourceID = 10, visualID = 50, itemID = 500, metadataRevision = 1,
    eraManifestVersion = 3, eraManifestSignature = "10,11",
    eraSourceIDs = { 10, 11 }, eraItemIDs = { 500, 501 },
    sourceType = 1, categoryID = 4, inventoryType = 5,
    name = "Replica Breastplate",
}
context = ZoneStyle.PrepareGenerationEligibilityContext(ZoneStyle.GetCurrentContext())
eligible, _, _, cached = ZoneStyle.GetSourcePreEraEligibilityCached(source, context)
assert(eligible and cached and precheckCalls == 1, "metadataRevision reset broke persistent precheck identity")
eligible, _, _, cached = ZoneStyle.GetSourceEligibilityCached(source, "TRAVELER", context, evidence, true)
assert(eligible and cached and eligibilityCalls == 1, "metadataRevision reset broke persistent eligibility identity")

source.categoryID = 5
source.persistentGenerationFingerprint = nil
source.generationPrecheckKey = nil
source.generationPrecheckEligible = nil
eligible, _, _, cached = ZoneStyle.GetSourcePreEraEligibilityCached(source, context)
assert(eligible and not cached and precheckCalls == 2, "stable category change reused stale persistent precheck")
source.categoryID = 4
source.persistentGenerationFingerprint = nil
source.generationPrecheckKey = nil
source.generationPrecheckEligible = nil

level = 80
context = ZoneStyle.PrepareGenerationEligibilityContext(ZoneStyle.GetCurrentContext())
eligible, _, _, cached = ZoneStyle.GetSourcePreEraEligibilityCached(source, context)
assert(eligible and not cached and precheckCalls == 3, "level change reused stale persistent precheck")
print("PASS persistent eligibility: cache keys survive metadataRevision resets and still invalidate on level changes")
