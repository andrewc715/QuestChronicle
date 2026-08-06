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


local function ZoneAnchorPolicyStub()
    return {
        GetAnchorSlots = function() return { "CHEST", "LEGS", "SHOULDER", "WEAPON_BUNDLE" } end,
        GetAnchorSearchConfiguration = function() return {} end,
        EvaluateAnchorCandidate = function() return nil end,
        ScoreAnchorPair = function() return 0, 0.5, nil, false end,
        ScoreAnchorSkeleton = function() return nil end,
        BuildNoveltyReference = function() return nil end,
        ClassifyNovelty = function() return nil end,
    }
end

QuestChronicle.Generation = QuestChronicle.Generation or {}
QuestChronicle.Generation.ZoneAnchorPolicy = ZoneAnchorPolicyStub()

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationPerformance.lua")
dofile(base .. "Core/Workers/SliceBudget.lua")
dofile(base .. "Core/Workers/AdaptiveBatch.lua")
dofile(base .. "Core/Wardrobe/GenerationScheduling.lua")
dofile(base .. "Core/Wardrobe/GenerationSetupWorker.lua")
dofile(base .. "Core/Wardrobe/GenerationJobFactory.lua")
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

local function DrainQueue()
    while #queue > 0 do
        local callback = table.remove(queue, 1)
        callback()
    end
end

local function ResetState()
    liveState.selections = {}
    liveState.selectionVisuals = {}
    liveState.generatedName = nil
    liveState.lastWeaponRoute = nil
    liveState.lastAnchorSkeletonSignature = nil
    liveState.activeAnchorMask = nil
    liveState.contextualSupportProfile = nil
    P.generationJob = nil
    P.supportRerollJob = nil
end

local function SnapshotPerformance(performance)
    local phases = {}
    for key, phase in pairs(performance.phaseStats or {}) do
        phases[key] = { calls = phase.calls, maxMs = phase.maxMs, totalMs = phase.totalMs }
    end
    return {
        steps = performance.steps, candidates = performance.candidates,
        selectedArmor = performance.selectedArmor, weaponYields = performance.weaponYields,
        schedulerDiagnostics = performance.schedulerDiagnostics, phaseStats = phases,
    }
end

ResetState()
math.randomseed(seed)
local ok, message = Wardrobe.StartGenerateOutfit(false, "TRAVELER")
assert(ok, message)
DrainQueue()
local legacySelections = { CHEST = liveState.selections.CHEST, LEGS = liveState.selections.LEGS }
local legacyPerformance = SnapshotPerformance(P.lastGenerationPerformance)

ResetState()
math.randomseed(seed)
ok, message = QC.Generation.GenerateCurrentMode({ modeID = "TRAVELER" })
assert(ok, message)
DrainQueue()
local sharedPerformance = SnapshotPerformance(P.lastGenerationPerformance)

assert(liveState.selections.CHEST == legacySelections.CHEST, "shared Chest selection differs from legacy orchestration")
assert(liveState.selections.LEGS == legacySelections.LEGS, "shared Legs selection differs from legacy orchestration")
assert(liveState.selections.CHEST == expectedChest and liveState.selections.LEGS == expectedLegs, "weighted selection changed")
assert(sharedPerformance.steps == legacyPerformance.steps, "shared scheduler step count changed")
assert(sharedPerformance.candidates == legacyPerformance.candidates, "shared candidate count changed")
assert(sharedPerformance.selectedArmor == legacyPerformance.selectedArmor, "shared armor count changed")
assert(sharedPerformance.weaponYields == legacyPerformance.weaponYields, "shared weapon yield count changed")
for key, phase in pairs(legacyPerformance.phaseStats) do
    local shared = sharedPerformance.phaseStats[key]
    assert(shared and shared.calls == phase.calls, "shared phase call count changed for " .. tostring(key))
end
assert(QC.Generation.GetActiveAction() == nil, "shared action did not complete")
print(string.format("PASS v1.10.0 shared-vs-legacy orchestration parity: Chest %d, Legs %d, %d steps", liveState.selections.CHEST, liveState.selections.LEGS, sharedPerformance.steps))
