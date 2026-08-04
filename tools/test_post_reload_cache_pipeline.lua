local queue = {}
local clock = 0
local function Advance(milliseconds) clock = clock + milliseconds end
function debugprofilestop() return clock end
function time() return 1000 end
function UnitClass() return "Warrior", "WARRIOR", 1 end
function UnitRace() return "Human", "Human", 1 end
function UnitLevel() return 70 end
C_Timer = { After = function(_, callback) queue[#queue + 1] = callback end }

QuestChronicleDB = { wardrobe = { cacheVersion = 7, bySlot = {}, scanState = "COMPLETE" } }
QuestChronicle = {
    Wardrobe = { _Private = {} },
    ZoneStyle = { _Private = {}, expansions = {} },
    GetSettings = function() return { restrictOutfitsToZoneEra = true } end,
    Notify = function() end,
}
local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local WP = Wardrobe._Private
local ZoneStyle = QC.ZoneStyle
local ZP = ZoneStyle._Private
function WP.EnsureCache() return QuestChronicleDB.wardrobe end
function WP.CopyPrimitiveMap(source)
    local result = {}
    for key, value in pairs(source or {}) do if type(value) ~= "table" then result[key] = value end end
    return result
end
function WP.GetReachableMaxPlayerLevel() return 80 end
function WP.SafeCall(callback, ...) return callback(...) end
function WP.CopySourceForSlot(source) return source end
function WP.CreateStyleGenerationContext(_, styleEngine, base) return styleEngine.CreateGenerationContext(base) end

function ZP.Normalize(value) return string.lower(tostring(value or "")) end
function ZP.TextMatchesAny() return false end
function ZP.SafeCall(callback, ...) return callback(...) end
function ZP.GetCuratedSourceOrigin() return nil end
function ZP.GetTrackedSourceOrigin() return nil end
function ZP.GetAppearanceTrackingType() return nil end
function ZP.GetReachableMaxPlayerLevel() return 80 end
ZP.trackedOriginCache = {}

function Wardrobe.GetZonePreferenceKey() return "map:530" end
function Wardrobe.GetSourceZonePreference() return nil end
function Wardrobe.IsScanning() return false end
function Wardrobe.ValidateSource(source, slotKey) Advance(0.001) return source.slotKey == slotKey end

function ZoneStyle.GetCurrentContext() return { eraMax = 2, provenanceResolved = true, provenanceKey = "outland", profileLabel = "Outland" } end
function ZoneStyle.ResolveEra() return 2, "The Burning Crusade", "TBC" end
function ZoneStyle.ResolveProvenance() return { label = "Outland" }, "outland" end
function ZoneStyle.GetSourcePreference(source, context) return Wardrobe.GetSourceZonePreference(source, context) end
local precheckCalls, eligibilityCalls = 0, 0
function ZoneStyle.GetSourcePreEraEligibility()
    precheckCalls = precheckCalls + 1
    Advance(0.001)
    return true, "eligible", "ok"
end
function ZoneStyle.GetSourceEligibility()
    eligibilityCalls = eligibilityCalls + 1
    Advance(0.001)
    return true, "eligible", "ok"
end
function ZoneStyle.NormalizeMode(mode) return mode end
function ZoneStyle.CreateGenerationContext(base)
    local context = {}
    for key, value in pairs(base or {}) do context[key] = value end
    context.outfitProfile = { sourceCount = 0 }
    return ZoneStyle.PrepareGenerationEligibilityContext(context)
end
function ZoneStyle.AddSourceToGenerationContext(context) context.outfitProfile.sourceCount = context.outfitProfile.sourceCount + 1 end
function ZoneStyle.ChooseWeightedSource() end
function ZoneStyle.GetSourceCoherence() Advance(0.001) return 0, true end
function ZoneStyle.WeightForSource(source) Advance(0.002) return source.sourceID % 13 + 1, 10 end
function ZoneStyle.GetModeInfo() return { label = "Traveler" } end
function ZoneStyle.GetContextRestrictionLabel() return "TBC" end

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationCacheStore.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheCounters.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheAccess.lua")
dofile(base .. "Core/Wardrobe/GenerationDependencyIndex.lua")
dofile(base .. "Core/Wardrobe/GenerationCacheDiagnostics.lua")
dofile(base .. "Core/ZoneStyle/EraEvidence.lua")
dofile(base .. "Core/ZoneStyle/GenerationEligibility.lua")

WP.ARMOR_GENERATION_ORDER = {}
WP.slotByKey = {}
local warmSources = {}
local totalCandidates = 0
for slotIndex = 1, 10 do
    local slotKey = "SLOT_" .. slotIndex
    WP.ARMOR_GENERATION_ORDER[slotIndex] = slotKey
    WP.slotByKey[slotKey] = { key = slotKey, label = slotKey }
    warmSources[slotKey] = {}
    local count = slotIndex <= 6 and 326 or 325
    for sourceIndex = 1, count do
        totalCandidates = totalCandidates + 1
        local sourceID = slotIndex * 10000 + sourceIndex
        warmSources[slotKey][sourceIndex] = {
            sourceID = sourceID, visualID = sourceID, itemID = sourceID + 100000,
            metadataRevision = 9, slotKey = slotKey,
            eraManifestVersion = 3, eraManifestSignature = tostring(sourceID),
            eraSourceIDs = { sourceID }, eraItemIDs = { sourceID + 100000 },
        }
    end
end
assert(totalCandidates == 3256, "benchmark source count changed")

local warmContext = ZoneStyle.PrepareGenerationEligibilityContext(ZoneStyle.GetCurrentContext())
for _, slotKey in ipairs(WP.ARMOR_GENERATION_ORDER) do
    for _, source in ipairs(warmSources[slotKey]) do
        local evidence = { expansionID = 2, method = "set", sourceID = source.sourceID, candidateCount = 1 }
        WP.StorePersistentEraEvidence(source, evidence, 1, ZP.ERA_EVIDENCE_VERSION)
        ZoneStyle.GetSourcePreEraEligibilityCached(source, warmContext)
        ZoneStyle.GetSourceEligibilityCached(source, "TRAVELER", warmContext, evidence, true)
    end
end
assert(precheckCalls == totalCandidates and eligibilityCalls == totalCandidates, "warm seed did not populate every eligibility record")

-- Rebuild every source table and reset runtime session state as /reload + automatic scan would.
WP.generationCacheSessionInitialized = nil
WP.generationCacheSessionStats = nil
local sources = {}
for _, slotKey in ipairs(WP.ARMOR_GENERATION_ORDER) do
    sources[slotKey] = {}
    for index, old in ipairs(warmSources[slotKey]) do
        sources[slotKey][index] = {
            sourceID = old.sourceID, visualID = old.visualID, itemID = old.itemID,
            metadataRevision = 1, slotKey = slotKey,
            eraManifestVersion = 3, eraManifestSignature = old.eraManifestSignature,
            eraSourceIDs = { old.sourceID }, eraItemIDs = { old.itemID },
        }
    end
end
QuestChronicleDB.wardrobe.bySlot = sources
function Wardrobe.GetSlotSources(slotKey) return sources[slotKey] end

local liveState = {
    selections = {}, selectionVisuals = {}, locks = {}, hidden = {},
    weaponFamilies = {}, weaponSubtypes = {}, linkWeaponHands = true,
    styleMode = "TRAVELER",
}
function WP.EnsurePreviewState() return liveState end
function WP.SetSelectedSource(state, slotKey, source)
    state.selections[slotKey] = source and source.sourceID or nil
    state.selectionVisuals[slotKey] = source and source.visualID or nil
end
function WP.RefreshGeneratedOutfitName() Advance(0.2) return "Post Reload Benchmark" end
function WP.GenerateWeapons()
    for _ = 1, 120 do Advance(0.4); WP.MaybeYieldWeaponGeneration("weaponCandidate") end
    return true, 2
end

dofile(base .. "Core/Wardrobe/WeaponPipeline.lua")
dofile(base .. "Core/Wardrobe/GenerationPerformance.lua")
dofile(base .. "Core/Workers/SliceBudget.lua")
dofile(base .. "Core/Workers/AdaptiveBatch.lua")
dofile(base .. "Core/Wardrobe/GenerationScheduling.lua")
dofile(base .. "Core/Wardrobe/GenerationSetupWorker.lua")
dofile(base .. "Core/Wardrobe/GenerationWorker.lua")

local precheckBaseline, eligibilityBaseline = precheckCalls, eligibilityCalls
local ok, message = Wardrobe.StartGenerateOutfit(true, "TRAVELER")
assert(ok, message)
local safety = 0
while #queue > 0 do
    local callback = table.remove(queue, 1)
    callback()
    safety = safety + 1
    assert(safety < 100, "post-reload persistent benchmark exceeded frame safety limit")
end
local perf = Wardrobe.GetLastGenerationPerformance()
assert(precheckCalls == precheckBaseline, "post-reload generation recomputed persistent prechecks")
assert(eligibilityCalls == eligibilityBaseline, "post-reload generation recomputed persistent eligibility")
assert(perf.eraCandidates == 0, "post-reload generation repeated era sibling checks")
assert(perf.eraCacheHits == totalCandidates, "post-reload era cache hit count mismatch")
assert(perf.eligibilityCacheHits >= totalCandidates * 2, "post-reload eligibility cache hits were incomplete")
assert(perf.steps < 50, "post-reload persistent pipeline regressed toward the Retail frame floor")
assert(perf.maxStepMs < 8.0, "post-reload persistent pipeline exceeded the hard frame budget")
print(string.format(
    "PASS post-reload cache pipeline: %d persistent candidates across %d frames, max %.2f ms",
    perf.candidates, perf.steps, perf.maxStepMs
))
