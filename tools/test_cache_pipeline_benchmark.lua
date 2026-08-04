local queue = {}
local clock = 0
local function Advance(milliseconds) clock = clock + milliseconds end
function debugprofilestop() return clock end
C_Timer = { After = function(_, callback) queue[#queue + 1] = callback end }

QuestChronicle = {
    Wardrobe = { _Private = {} },
    ZoneStyle = {},
    Notify = function() end,
}
local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.ARMOR_GENERATION_ORDER = {}
P.slotByKey = {}
local sources = {}
local totalCandidates = 0
for slotIndex = 1, 10 do
    local slotKey = "SLOT_" .. slotIndex
    P.ARMOR_GENERATION_ORDER[slotIndex] = slotKey
    P.slotByKey[slotKey] = { key = slotKey, label = slotKey }
    sources[slotKey] = {}
    local count = slotIndex <= 6 and 326 or 325
    for sourceIndex = 1, count do
        totalCandidates = totalCandidates + 1
        sources[slotKey][sourceIndex] = {
            sourceID = slotIndex * 10000 + sourceIndex,
            visualID = slotIndex * 10000 + sourceIndex,
            slotKey = slotKey,
        }
    end
end
assert(totalCandidates == 3256, "benchmark source count changed")

function P.CopyPrimitiveMap(source)
    local result = {}
    for key, value in pairs(source or {}) do if type(value) ~= "table" then result[key] = value end end
    return result
end
local liveState = {
    selections = {}, selectionVisuals = {}, locks = {}, hidden = {},
    weaponFamilies = {}, weaponSubtypes = {}, linkWeaponHands = true,
    styleMode = "TRAVELER",
}
function P.EnsureCache() return { scanState = "COMPLETE", totalVisuals = totalCandidates } end
function P.EnsurePreviewState() return liveState end
function P.CreateStyleGenerationContext(_, styleEngine, base) return styleEngine.CreateGenerationContext(base) end
function P.SetSelectedSource(state, slotKey, source)
    state.selections[slotKey] = source and source.sourceID or nil
    state.selectionVisuals[slotKey] = source and source.visualID or nil
end
function P.RefreshGeneratedOutfitName() Advance(0.2) return "Cache Pipeline Benchmark" end
function P.GenerateWeapons()
    for _ = 1, 120 do
        Advance(0.4)
        P.MaybeYieldWeaponGeneration("weaponCandidate")
    end
    return true, 2
end

function Wardrobe.GetSlotSources(slotKey) return sources[slotKey] end
function Wardrobe.ValidateSource(source, slotKey) Advance(0.001) return source.slotKey == slotKey end
function Wardrobe.IsScanning() return false end

function QC.ZoneStyle.NormalizeMode(mode) return mode end
function QC.ZoneStyle.GetCurrentContext() return { profileLabel = "Outland" } end
function QC.ZoneStyle.CreateGenerationContext(base)
    local context = {}
    for key, value in pairs(base or {}) do context[key] = value end
    context.outfitProfile = { sourceCount = 0 }
    return context
end
function QC.ZoneStyle.AddSourceToGenerationContext(context) context.outfitProfile.sourceCount = context.outfitProfile.sourceCount + 1 end
function QC.ZoneStyle.ChooseWeightedSource() end
function QC.ZoneStyle.GetSourcePreEraEligibility() return true end
function QC.ZoneStyle.GetSourcePreEraEligibilityCached()
    Advance(0.001)
    P.generationJob.eligibilityCacheHits = P.generationJob.eligibilityCacheHits + 1
    return true
end
function QC.ZoneStyle.CreateSourceEraEvidenceWork(source)
    Advance(0.001)
    P.generationJob.eraCacheHits = P.generationJob.eraCacheHits + 1
    return { done = true, cached = true, result = { expansionID = 1, sourceID = source.sourceID } }
end
function QC.ZoneStyle.GetSourceEligibilityCached() Advance(0.001) return true end
function QC.ZoneStyle.GetSourceCoherence() Advance(0.001) return 0, true end
function QC.ZoneStyle.WeightForSource(source) Advance(0.002) return source.sourceID % 13 + 1, 10 end
function QC.ZoneStyle.GetModeInfo() return { label = "Traveler" } end
function QC.ZoneStyle.GetContextRestrictionLabel() return "TBC" end

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/WeaponPipeline.lua")
dofile(base .. "Core/Wardrobe/GenerationPerformance.lua")
dofile(base .. "Core/Workers/SliceBudget.lua")
dofile(base .. "Core/Workers/AdaptiveBatch.lua")
dofile(base .. "Core/Wardrobe/GenerationScheduling.lua")
dofile(base .. "Core/Wardrobe/GenerationSetupWorker.lua")
dofile(base .. "Core/Wardrobe/GenerationWorker.lua")

local ok, message = Wardrobe.StartGenerateOutfit(true, "TRAVELER")
assert(ok, message)
local safety = 0
while #queue > 0 do
    local callback = table.remove(queue, 1)
    callback()
    safety = safety + 1
    assert(safety < 100, "cache-and-pipeline benchmark exceeded frame safety limit")
end

local perf = Wardrobe.GetLastGenerationPerformance()
assert(perf.candidates == 3256, "candidate count mismatch")
assert(perf.eraCandidates == 0, "cached era evidence performed sibling checks")
assert(perf.eraCacheHits == 3256, "era cache hit count mismatch")
assert(perf.weaponYields == 120, "weapon coroutine yield count mismatch")
assert(perf.steps < 50, "warm cache pipeline regressed toward the 204-frame floor")
assert(perf.maxStepMs < 8.0, "cache pipeline exceeded the hard frame limit")
print(string.format(
    "PASS cache pipeline benchmark: %d candidates + %d weapon yields across %d frames, max %.2f ms",
    perf.candidates, perf.weaponYields, perf.steps, perf.maxStepMs
))
