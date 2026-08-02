local queue = {}
local clock = 0

function debugprofilestop()
    clock = clock + 0.20
    return clock
end

C_Timer = {
    After = function(_, callback) table.insert(queue, callback) end,
}

local notifications = {}
QuestChronicle = {
    Wardrobe = { _Private = {} },
    ZoneStyle = {},
    Notify = function(event, ...)
        table.insert(notifications, { event = event, args = { ... } })
    end,
}

local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.ARMOR_GENERATION_ORDER = { "CHEST", "LEGS", "BACK" }
P.slotByKey = {
    CHEST = { key = "CHEST", label = "Chest" },
    LEGS = { key = "LEGS", label = "Legs" },
    BACK = { key = "BACK", label = "Back" },
}

function P.CopyPrimitiveMap(source)
    local result = {}
    for key, value in pairs(source or {}) do
        if type(value) ~= "table" then result[key] = value end
    end
    return result
end

local liveState = {
    selections = { CHEST = 999 },
    selectionVisuals = { CHEST = 999 },
    locks = {}, hidden = {},
    weaponFamilies = { ONE_HAND = true },
    weaponSubtypes = { ONE_HAND_SWORD = true },
    linkWeaponHands = true,
    styleMode = "TRAVELER",
}

local cache = { scanState = "COMPLETE", totalVisuals = 360 }
local sources = {}
for _, slotKey in ipairs(P.ARMOR_GENERATION_ORDER) do
    sources[slotKey] = {}
    for index = 1, 120 do
        table.insert(sources[slotKey], {
            sourceID = (slotKey == "CHEST" and 1000 or slotKey == "LEGS" and 2000 or 3000) + index,
            visualID = index,
            itemID = index,
            slotKey = slotKey,
            sourceIsCollected = true,
            isCollected = true,
        })
    end
end

function P.EnsureCache() return cache end
function P.EnsurePreviewState() return liveState end
function P.CreateStyleGenerationContext(_, styleEngine, base)
    return styleEngine.CreateGenerationContext(base)
end
function P.SetSelectedSource(state, slotKey, source)
    state.selections[slotKey] = source and source.sourceID or nil
    state.selectionVisuals[slotKey] = source and source.visualID or nil
end
function P.RefreshGeneratedOutfitName(state)
    state.generatedName = "Cooperative Test"
    return state.generatedName
end
function P.GenerateWeapons(state)
    state.selections.ONE_HAND = 5001
    state.selections.OFF_HAND = 5001
    state.selectionVisuals.ONE_HAND = 51
    state.selectionVisuals.OFF_HAND = 51
    state.lastWeaponRoute = { routeKind = "ONE_HAND_PAIR" }
    return true, 2
end

function Wardrobe.GetSlotSources(slotKey) return sources[slotKey] or {} end
function Wardrobe.ValidateSource(source, slotKey) return source.slotKey == slotKey end
function Wardrobe.IsScanning() return false end

QC.ZoneStyle.MODE_ZONE_NATIVE = "ZONE_NATIVE"
function QC.ZoneStyle.NormalizeMode(mode) return mode end
function QC.ZoneStyle.GetCurrentContext() return { profileLabel = "Outland" } end
function QC.ZoneStyle.CreateGenerationContext(base)
    local context = {}
    for key, value in pairs(base or {}) do context[key] = value end
    context.outfitProfile = { count = 0 }
    return context
end
function QC.ZoneStyle.AddSourceToGenerationContext(context)
    context.outfitProfile.count = context.outfitProfile.count + 1
end
function QC.ZoneStyle.ChooseWeightedSource() end
function QC.ZoneStyle.GetSourceEligibility() return true end
function QC.ZoneStyle.GetSourceCoherence() return 0, true end
function QC.ZoneStyle.WeightForSource(source) return source.sourceID % 17 + 1, source.sourceID % 17 end
function QC.ZoneStyle.GetModeInfo() return { label = "Traveler" } end
function QC.ZoneStyle.GetContextRestrictionLabel() return "TBC" end
function QC.ZoneStyle.ConsumeSuggestion() end

local root = (... and (...):match("^(.*)[/\\]") or "")
dofile((root ~= "" and root .. "/../" or "") .. "Core/Wardrobe/GenerationWorker.lua")

local ok, message = Wardrobe.StartGenerateOutfit(false, "TRAVELER")
assert(ok == true, message)
assert(Wardrobe.IsGenerating() == true, "generation job did not start")
assert(liveState.selections.CHEST == 999, "live state changed before cooperative job ran")
assert(#queue == 1, "first worker step was not scheduled")

queue[1]()
table.remove(queue, 1)
assert(liveState.selections.CHEST == 999, "live state was partially committed")
assert(Wardrobe.IsGenerating() == true, "job finished in one blocking step")

local safety = 0
while #queue > 0 do
    local callback = table.remove(queue, 1)
    callback()
    safety = safety + 1
    assert(safety < 200, "generation worker did not terminate")
end

assert(Wardrobe.IsGenerating() == false, "generation job did not finish")
assert(liveState.selections.CHEST ~= 999, "armor selections were not committed")
assert(liveState.selections.LEGS ~= nil and liveState.selections.BACK ~= nil, "armor slots missing")
assert(liveState.selections.ONE_HAND == 5001 and liveState.selections.OFF_HAND == 5001, "weapon bundle missing")
assert(liveState.generatedName == "Cooperative Test", "generated name missing")

local perf = Wardrobe.GetLastGenerationPerformance()
assert(perf and perf.steps > 3, "generation was not spread across frames")
assert(perf.candidates == 360, "candidate count mismatch")
assert(perf.selectedArmor == 3, "selected armor count mismatch")

local sawStart, sawProgress, sawComplete = false, false, false
for _, notification in ipairs(notifications) do
    sawStart = sawStart or notification.event == "WARDROBE_GENERATION_STARTED"
    sawProgress = sawProgress or notification.event == "WARDROBE_GENERATION_PROGRESS"
    sawComplete = sawComplete or notification.event == "WARDROBE_GENERATION_COMPLETE"
end
assert(sawStart and sawProgress and sawComplete, "generation callbacks incomplete")

print(string.format(
    "PASS cooperative generation: %d candidates across %d frames, max step %.2f ms",
    perf.candidates,
    perf.steps,
    perf.maxStepMs
))
