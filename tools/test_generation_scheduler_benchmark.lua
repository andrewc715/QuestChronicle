local queue = {}
local clock = 0
local function Advance(milliseconds) clock = clock + milliseconds end

function debugprofilestop() return clock end
C_Timer = { After = function(_, callback) table.insert(queue, callback) end }

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
for slotIndex = 1, 10 do
    local slotKey = "SLOT_" .. tostring(slotIndex)
    P.ARMOR_GENERATION_ORDER[slotIndex] = slotKey
    P.slotByKey[slotKey] = { key = slotKey, label = slotKey }
    sources[slotKey] = {}
    for sourceIndex = 1, 600 do
        sources[slotKey][sourceIndex] = {
            sourceID = slotIndex * 10000 + sourceIndex,
            visualID = slotIndex * 10000 + sourceIndex,
            slotKey = slotKey,
        }
    end
end
local coldSourceID = sources.SLOT_1[1].sourceID

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
function P.EnsureCache() return { scanState = "COMPLETE", totalVisuals = 6000 } end
function P.EnsurePreviewState() return liveState end
function P.CreateStyleGenerationContext(_, styleEngine, base) return styleEngine.CreateGenerationContext(base) end
function P.SetSelectedSource(state, slotKey, source)
    state.selections[slotKey] = source and source.sourceID or nil
    state.selectionVisuals[slotKey] = source and source.visualID or nil
end
function P.RefreshGeneratedOutfitName() Advance(0.2) return "Scheduler Benchmark" end
function P.GenerateWeapons() Advance(1.0) return true, 0 end

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
function QC.ZoneStyle.CreateSourceEraEvidenceWork(source)
    if source.sourceID == coldSourceID then
        return { done = false, result = nil, index = 1, total = 100, sourceID = source.sourceID }
    end
    return { done = true, result = { expansionID = 1, sourceID = source.sourceID }, cached = true }
end
function QC.ZoneStyle.StepSourceEraEvidenceWork(work)
    Advance(0.4)
    work.index = work.index + 1
    if work.index > work.total then
        work.done = true
        work.result = { expansionID = 1, sourceID = work.sourceID }
        return true, work.result, 1
    end
    return false, nil, 1
end
function QC.ZoneStyle.GetSourceEligibility() Advance(0.002) return true end
function QC.ZoneStyle.GetSourceCoherence() Advance(0.001) return 0, true, nil end
function QC.ZoneStyle.WeightForSource(source) Advance(0.003) return (source.sourceID % 11) + 1, 10 end
function QC.ZoneStyle.GetModeInfo() return { label = "Traveler" } end
function QC.ZoneStyle.GetContextRestrictionLabel() return "TBC" end

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationPerformance.lua")
dofile(base .. "Core/Workers/SliceBudget.lua")
dofile(base .. "Core/Workers/AdaptiveBatch.lua")
dofile(base .. "Core/Wardrobe/GenerationScheduling.lua")
dofile(base .. "Core/Wardrobe/GenerationSetupWorker.lua")
dofile(base .. "Core/Wardrobe/GenerationWorker.lua")

local ok, message = Wardrobe.StartGenerateOutfit(false, "TRAVELER")
assert(ok, message)
local safety = 0
while #queue > 0 do
    local callback = table.remove(queue, 1)
    callback()
    safety = safety + 1
    assert(safety < 150, "adaptive scheduler exceeded benchmark safety limit")
end

local perf = Wardrobe.GetLastGenerationPerformance()
assert(perf.candidates == 6000, "benchmark candidate count mismatch")
assert(perf.eraCandidates == 100, "cooperative era sibling count mismatch")
assert(perf.steps < 80, "time-first scheduler regressed toward the old 200-frame candidate floor")
assert(perf.maxStepMs < 8.0, "cooperative era work exceeded the hard frame budget")
print(string.format(
    "PASS generation scheduler benchmark: %d candidates + %d era siblings across %d frames, max %.2f ms",
    perf.candidates,
    perf.eraCandidates,
    perf.steps,
    perf.maxStepMs
))
