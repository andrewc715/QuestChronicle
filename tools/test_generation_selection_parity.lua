local queue = {}
local clock = 0

function debugprofilestop()
    clock = clock + 0.01
    return clock
end

C_Timer = {
    After = function(_, callback) table.insert(queue, callback) end,
}

QuestChronicle = {
    Wardrobe = { _Private = {} },
    ZoneStyle = {},
    Notify = function() end,
}

local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.ARMOR_GENERATION_ORDER = { "CHEST", "LEGS" }
P.slotByKey = {
    CHEST = { key = "CHEST", label = "Chest" },
    LEGS = { key = "LEGS", label = "Legs" },
}

function P.CopyPrimitiveMap(source)
    local result = {}
    for key, value in pairs(source or {}) do
        if type(value) ~= "table" then result[key] = value end
    end
    return result
end

local liveState = {
    selections = {}, selectionVisuals = {}, locks = {}, hidden = {},
    weaponFamilies = {}, weaponSubtypes = {}, linkWeaponHands = true,
    styleMode = "TRAVELER",
}
local cache = { scanState = "COMPLETE", totalVisuals = 20 }
local sources = { CHEST = {}, LEGS = {} }
for index = 1, 10 do
    sources.CHEST[index] = { sourceID = 100 + index, visualID = 100 + index, slotKey = "CHEST" }
    sources.LEGS[index] = { sourceID = 200 + index, visualID = 200 + index, slotKey = "LEGS" }
end

function P.EnsureCache() return cache end
function P.EnsurePreviewState() return liveState end
function P.CreateStyleGenerationContext(_, styleEngine, base) return styleEngine.CreateGenerationContext(base) end
function P.SetSelectedSource(state, slotKey, source)
    state.selections[slotKey] = source and source.sourceID or nil
    state.selectionVisuals[slotKey] = source and source.visualID or nil
end
function P.RefreshGeneratedOutfitName() return "Parity Test" end
function P.GenerateWeapons() return true, 0 end

function Wardrobe.GetSlotSources(slotKey) return sources[slotKey] or {} end
function Wardrobe.ValidateSource(source, slotKey) return source.slotKey == slotKey end
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
    return { done = true, result = { expansionID = 1, sourceID = source.sourceID } }
end
function QC.ZoneStyle.StepSourceEraEvidenceWork(work) return true, work.result, 0 end
function QC.ZoneStyle.GetSourceEligibility() return true end
function QC.ZoneStyle.GetSourceCoherence() return 0, true, nil end
function QC.ZoneStyle.WeightForSource(source) return (source.sourceID % 9) + 1, source.sourceID % 9 end
function QC.ZoneStyle.GetModeInfo() return { label = "Traveler" } end
function QC.ZoneStyle.GetContextRestrictionLabel() return "TBC" end

local function ExpectedSource(slotSources)
    local total = 0
    for _, source in ipairs(slotSources) do total = total + ((source.sourceID % 9) + 1) end
    local roll = math.random() * total
    for _, source in ipairs(slotSources) do
        roll = roll - ((source.sourceID % 9) + 1)
        if roll <= 0 then return source.sourceID end
    end
    return slotSources[#slotSources].sourceID
end

local seed = 9917
math.randomseed(seed)
local expectedChest = ExpectedSource(sources.CHEST)
local expectedLegs = ExpectedSource(sources.LEGS)

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationPerformance.lua")
dofile(base .. "Core/Wardrobe/GenerationWorker.lua")
P.GENERATION_TIME_BUDGET_MS = 1000
math.randomseed(seed)

local ok, message = Wardrobe.StartGenerateOutfit(false, "TRAVELER")
assert(ok, message)
while #queue > 0 do
    local callback = table.remove(queue, 1)
    callback()
end

assert(liveState.selections.CHEST == expectedChest, "adaptive worker changed Chest weighted selection")
assert(liveState.selections.LEGS == expectedLegs, "adaptive worker changed Legs weighted selection")
print(string.format("PASS generation selection parity: Chest %d, Legs %d", expectedChest, expectedLegs))
