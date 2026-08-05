local root = assert(arg[1], "root required")
QuestChronicle = { Wardrobe = { _Private = {}, slotDefinitions = {} }, ZoneStyle = { Traveler = {} } }
local QC, W, P, Z, T = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle.Traveler
for _, key in ipairs({ "HEAD", "SHOULDER", "BACK", "CHEST", "SHIRT", "TABARD", "WRIST", "HANDS", "WAIST", "LEGS", "FEET", "ONE_HAND", "OFF_HAND" }) do local d = { key = key, label = key }; W.slotDefinitions[#W.slotDefinitions + 1] = d end
P.slotByKey = {}; for _, d in ipairs(W.slotDefinitions) do P.slotByKey[d.key] = d end
P.MAIN_WEAPON_SLOT_KEYS = { "ONE_HAND" }; P.GENERATION_TIME_BUDGET_MS = .18; P.GENERATION_OPERATION_SAFETY_CAP = 2000; P.GENERATION_ERA_CANDIDATES_PER_OPERATION = 1
local clock = 0; function P.GenerationNowMilliseconds() clock = clock + .04 return clock end
local timers = {}; C_Timer = { After = function(_, cb) timers[#timers + 1] = cb end }
QC.Notify = function() end
local bySlot, byID = {}, {}
local function add(slot, id, value)
    local s = { slotKey = slot, sourceID = id, visualID = id, styleName = slot .. id, descriptor = {
        palette = { steel = value }, material = { plate = value }, finish = { military = value }, motifs = { frontier = value },
        confidence = { palette = 1, material = 1, finish = 1, motifs = 1, visualWeight = 1, provenance = 1 }, visualWeight = 2.5, loudness = .2,
        expansionID = 1, setIDs = {}, dominantPalette = "steel", dominantMaterial = "plate", dominantFinish = "military", dominantMotif = "frontier",
    } }
    bySlot[slot] = bySlot[slot] or {}; bySlot[slot][#bySlot[slot] + 1] = s; byID[slot .. id] = s; return s
end
local chest, legs, shoulder, weapon = add("CHEST", 1, .9), add("LEGS", 2, .86), add("SHOULDER", 3, .84), add("ONE_HAND", 4, .82)
local order = { "WAIST", "HANDS", "FEET", "HEAD", "BACK", "WRIST", "SHIRT", "TABARD" }
local current = {}
for i, slot in ipairs(order) do current[slot] = add(slot, 1000 + i, .35); for j = 1, (slot == "BACK" and 70 or 40) do add(slot, i * 10000 + j, .52 + ((j % 23) / 50)) end end
function W.GetSlotSources(slot) return bySlot[slot] or {} end
function W.ValidateSource() return true end
function W.GetSlotDefinition(key) return P.slotByKey[key] end
function W.IsSlotLocked(slot) return P.EnsurePreviewState().locks[slot] == true end
function W.IsScanning() return false end
function W.IsGenerating() return P.supportRerollJob ~= nil end
function P.GetSourceByID(slot, id) return byID[slot .. id] end
function P.SetSelectedSource(state, slot, source) state.selections[slot] = source and source.sourceID or nil; state.selectionVisuals[slot] = source and source.visualID or nil; if P.TouchPreviewRevision then P.TouchPreviewRevision(state) end end
function P.RefreshGeneratedOutfitName(state) state.generatedName = "Parity" return state.generatedName end
function P.CreateStyleGenerationContext() return {} end
function P.GetGenerationCacheCounterSnapshot() return {} end
function P.BuildGenerationCachePerformance() return {} end
function Z.GetTravelerDescriptor(source) return source and source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS = { CHEST = 1, LEGS = .8, SHOULDER = 1, ONE_HAND = .9, WAIST = .5, HANDS = .65, FEET = .6, HEAD = .9, BACK = .55, WRIST = .25, SHIRT = .2, TABARD = .2 }
function T.GetPairCohesion(a, b) local s = 1 - math.abs((a.palette.steel or 0) - (b.palette.steel or 0)); return s, { palette = s, material = s, finish = s, visualWeight = s, motif = s, provenance = .78 } end
Z.MODE_TRAVELER = "TRAVELER"; function Z.NormalizeMode(m) return m end; function Z.GetCurrentContext() return {} end; function Z.GetSourceCoherence() return .8, true end
function Z.ScoreSource(source) return (source.descriptor.palette.steel or 0) * 25, {} end
function Z.GetSourcePreEraEligibility() return true end; function Z.GetSourcePreEraEligibilityCached() return true end
function Z.CreateSourceEraEvidenceWork() return { done = true, result = { state = "KNOWN" } } end
function Z.GetSourceEligibility() return true end; function Z.GetSourceEligibilityCached() return true end
local state = { selections = { CHEST = 1, LEGS = 2, SHOULDER = 3, ONE_HAND = 4 }, selectionVisuals = { CHEST = 1, LEGS = 2, SHOULDER = 3, ONE_HAND = 4 }, hidden = { SHOULDER = true }, locks = {}, styleMode = "TRAVELER" }
for _, slot in ipairs(order) do state.selections[slot] = current[slot].sourceID; state.selectionVisuals[slot] = current[slot].visualID end
P.EnsurePreviewState = function() return state end; W.RerollSlot = function() return true, "anchor" end
local files = { "GenerationPerformance.lua", "SupportProfileIdentity.lua", "SupportProfile.lua", "SupportBudget.lua" }
local function exists(path) local f = io.open(path, "rb"); if f then f:close(); return true end end
if exists(root .. "/Core/Wardrobe/SupportRoleResolver.lua") then files[#files + 1] = "SupportRoleResolver.lua" end
for _, f in ipairs({ "SupportScoring.lua", "SupportBeam.lua", "SupportWorker.lua" }) do files[#files + 1] = f end
if exists(root .. "/Core/Wardrobe/SupportRerollLaunch.lua") then files[#files + 1] = "SupportRerollLaunch.lua" end
for _, f in ipairs({ "SupportRerollFoundation.lua", "SupportRerollScheduling.lua", "SupportRerollScoring.lua", "SupportRerollFinalValidation.lua", "SupportRerollStats.lua", "SupportRerollWorker.lua", "SupportRerollLegacy.lua", "SupportReroll.lua" }) do files[#files + 1] = f end
for _, f in ipairs(files) do dofile(root .. "/Core/Wardrobe/" .. f) end
clock = 0; function P.GenerationNowMilliseconds() clock = clock + .04 return clock end
math.randomseed(19010)
local outputs = {}
for _, slot in ipairs({ "WAIST", "HEAD", "BACK", "HANDS" }) do
    assert(W.RerollSlot(slot)); while #timers > 0 do table.remove(timers, 1)() end
    local stats = P.lastSupportDiagnostics
    outputs[#outputs + 1] = table.concat({ slot, tostring(state.selections[slot]), string.format("%.6f", stats.generatedSpend or 0), string.format("%.6f", stats.wholeOutfitCohesion or 0), tostring(stats.chosenRank), tostring(stats.shortlistSize) }, ":")
end
print(table.concat(outputs, "|"))
