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
    ZoneStyle = {
        MODE_ZONE_NATIVE = "ZONE_NATIVE", MODE_TRAVELER = "TRAVELER",
        MODE_CLASS_FANTASY = "CLASS_FANTASY", MODE_CHRONICLE_ECHO = "CHRONICLE_ECHO",
        Traveler = {},
    },
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
dofile(base .. "Core/Workers/SliceBudget.lua")
dofile(base .. "Core/Workers/AdaptiveBatch.lua")
dofile(base .. "Core/Wardrobe/GenerationScheduling.lua")
dofile(base .. "Core/Wardrobe/GenerationSetupWorker.lua")
dofile(base .. "Core/Wardrobe/GenerationWorker.lua")
local generationFiles = {
    "Core/Generation/ModePolicy.lua", "Core/Generation/ModeRegistry.lua",
    "Core/Generation/GenerationLifecycle.lua", "Core/Generation/SchedulerEngine.lua",
    "Core/Generation/ContextProvider.lua", "Core/Generation/AnchorEngine.lua",
    "Core/Generation/ValidationEngine.lua", "Core/Generation/RepairEngine.lua",
    "Core/Generation/SupportEngine.lua", "Core/Generation/CandidateEngine.lua",
    "Core/Generation/WeaponEngine.lua", "Core/Generation/CommitEngine.lua",
    "Core/Generation/DiagnosticsEngine.lua", "Core/Generation/RerollEngine.lua",
    "Core/Generation/VisualLanguage.lua", "Core/Generation/GenerationJob.lua",
    "Core/Generation/Modes/Traveler/Context.lua", "Core/Generation/Modes/Traveler/AnchorPolicy.lua",
    "Core/Generation/Modes/Traveler/SupportPolicy.lua", "Core/Generation/Modes/Traveler/ValidationPolicy.lua",
    "Core/Generation/Modes/Traveler/Diagnostics.lua", "Core/Generation/Modes/Traveler/Policy.lua",
    "Core/Generation/Modes/ZoneLegacyAdapter.lua", "Core/Generation/Modes/ClassLegacyAdapter.lua",
    "Core/Generation/Modes/EchoLegacyAdapter.lua", "Core/Generation/GenerationAPI.lua",
}
for _, file in ipairs(generationFiles) do dofile(base .. file) end
P.GENERATION_TIME_BUDGET_MS = 1000
math.randomseed(seed)

local ok, message = QC.Generation.GenerateCurrentMode({ modeID = "TRAVELER" })
assert(ok, message)
while #queue > 0 do
    local callback = table.remove(queue, 1)
    callback()
end

assert(liveState.selections.CHEST == expectedChest, "adaptive worker changed Chest weighted selection")
assert(liveState.selections.LEGS == expectedLegs, "adaptive worker changed Legs weighted selection")
local capabilities = assert(QC.Generation.GetModeCapabilities("TRAVELER"))
assert(capabilities.sharedFramework == true, "Traveler did not use the shared framework")
assert(QC.Generation.GetActiveAction() == nil, "shared action did not complete atomically")
print(string.format("PASS v1.10.0 shared Traveler selection parity: Chest %d, Legs %d", expectedChest, expectedLegs))
