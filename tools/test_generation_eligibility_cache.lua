local level = 70
local preference
function UnitClass() return "Warrior", "WARRIOR", 1 end
function UnitRace() return "Human", "Human", 1 end
function UnitLevel() return level end

QuestChronicle = {
    Wardrobe = {
        _Private = {},
        GetZonePreferenceKey = function() return "map:530" end,
        GetSourceZonePreference = function() return preference end,
    },
    ZoneStyle = { _Private = {} },
    GetSettings = function() return { restrictOutfitsToZoneEra = true } end,
}
local ZoneStyle = QuestChronicle.ZoneStyle
local P = ZoneStyle._Private
function P.GetReachableMaxPlayerLevel() return 80 end
function ZoneStyle.GetCurrentContext() return { eraMax = 2, provenanceResolved = true, provenanceKey = "outland" } end
function ZoneStyle.ResolveEra() return 2, "The Burning Crusade", "TBC" end
function ZoneStyle.ResolveProvenance() return { label = "Outland" }, "outland" end
function ZoneStyle.GetSourcePreference(source, context)
    return QuestChronicle.Wardrobe.GetSourceZonePreference(source, context)
end
local precheckCalls, eligibilityCalls = 0, 0
function ZoneStyle.GetSourcePreEraEligibility()
    precheckCalls = precheckCalls + 1
    return preference ~= "excluded", preference == "excluded" and "excluded" or "eligible"
end
function ZoneStyle.GetSourceEligibility(_, _, _, evidence)
    eligibilityCalls = eligibilityCalls + 1
    return evidence and evidence.expansionID ~= nil, "eligible", "ok"
end
function ZoneStyle.GetSourceEraEvidence() return { expansionID = 2, sourceID = 10, candidateCount = 2 } end

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile("Core/ZoneStyle/EraExecution.lua")
dofile(base .. "Core/ZoneStyle/GenerationEligibility.lua")

local source = { sourceID = 10, visualID = 50, itemID = 500, metadataRevision = 1 }
local context = ZoneStyle.PrepareGenerationEligibilityContext(ZoneStyle.GetCurrentContext())
local eligible, _, _, cached = ZoneStyle.GetSourcePreEraEligibilityCached(source, context)
assert(eligible and not cached and precheckCalls == 1, "first precheck did not compute")
eligible, _, _, cached = ZoneStyle.GetSourcePreEraEligibilityCached(source, context)
assert(eligible and cached and precheckCalls == 1, "warm precheck did not reuse cache")

local evidence = ZoneStyle.GetSourceEraEvidence(source)
eligible, _, _, cached = ZoneStyle.GetSourceEligibilityCached(source, "TRAVELER", context, evidence, true)
assert(eligible and not cached and eligibilityCalls == 1, "first final eligibility did not compute")
eligible, _, _, cached = ZoneStyle.GetSourceEligibilityCached(source, "TRAVELER", context, evidence, true)
assert(eligible and cached and eligibilityCalls == 1, "warm final eligibility did not reuse cache")

source.sourceID = 11
eligible, _, _, cached = ZoneStyle.GetSourceEligibilityCached(source, "TRAVELER", context, evidence, true)
assert(eligible and not cached and eligibilityCalls == 2, "changed representative source reused stale eligibility")

preference = "excluded"
eligible, _, _, cached = ZoneStyle.GetSourcePreEraEligibilityCached(source, context)
assert(not eligible and not cached and precheckCalls == 2, "changed zone preference reused stale precheck")

preference = nil
level = 80
local leveledContext = ZoneStyle.PrepareGenerationEligibilityContext(ZoneStyle.GetCurrentContext())
eligible, _, _, cached = ZoneStyle.GetSourcePreEraEligibilityCached(source, leveledContext)
assert(eligible and not cached and precheckCalls == 3, "changed player level reused stale progression result")

print("PASS generation eligibility cache: warm hits reuse results and source, preference, and level changes invalidate")
