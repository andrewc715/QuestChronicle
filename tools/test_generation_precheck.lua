local queue = {}
function debugprofilestop() return 0 end
C_Timer = { After = function(_, callback) table.insert(queue, callback) end }
QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = {}, Notify = function() end }
local QC, Wardrobe = QuestChronicle, QuestChronicle.Wardrobe
local P = Wardrobe._Private

P.ARMOR_GENERATION_ORDER = { "CHEST" }
P.slotByKey = { CHEST = { key = "CHEST", label = "Chest" } }
function P.CopyPrimitiveMap(source)
    local result = {}
    for key, value in pairs(source or {}) do if type(value) ~= "table" then result[key] = value end end
    return result
end
local liveState = {
    selections = {}, selectionVisuals = {}, locks = {}, hidden = {},
    weaponFamilies = {}, weaponSubtypes = {}, styleMode = "TRAVELER",
}
function P.EnsureCache() return { scanState = "COMPLETE", totalVisuals = 2 } end
function P.EnsurePreviewState() return liveState end
function P.CreateStyleGenerationContext(_, styleEngine, base) return styleEngine.CreateGenerationContext(base) end
function P.SetSelectedSource(state, slotKey, source)
    state.selections[slotKey] = source and source.sourceID or nil
    state.selectionVisuals[slotKey] = source and source.visualID or nil
end
function P.RefreshGeneratedOutfitName() return "Precheck Test" end
function P.GenerateWeapons() return true, 0 end

local excluded = { sourceID = 1, visualID = 1, slotKey = "CHEST", excluded = true }
local eligible = { sourceID = 2, visualID = 2, slotKey = "CHEST" }
function Wardrobe.GetSlotSources() return { excluded, eligible } end
function Wardrobe.ValidateSource() return true end
function Wardrobe.IsScanning() return false end

local eraCalls = 0
function QC.ZoneStyle.NormalizeMode(mode) return mode end
function QC.ZoneStyle.GetCurrentContext() return {} end
function QC.ZoneStyle.CreateGenerationContext() return { outfitProfile = {} } end
function QC.ZoneStyle.AddSourceToGenerationContext() end
function QC.ZoneStyle.ChooseWeightedSource() end
function QC.ZoneStyle.GetSourcePreEraEligibility(source) return source.excluded ~= true end
function QC.ZoneStyle.CreateSourceEraEvidenceWork(source)
    eraCalls = eraCalls + 1
    return { done = true, result = { expansionID = 1, sourceID = source.sourceID } }
end
function QC.ZoneStyle.StepSourceEraEvidenceWork(work) return true, work.result, 0 end
function QC.ZoneStyle.GetSourceEligibility() return true end
function QC.ZoneStyle.GetSourceCoherence() return 0, true end
function QC.ZoneStyle.WeightForSource() return 1, 1 end
function QC.ZoneStyle.GetModeInfo() return { label = "Traveler" } end
function QC.ZoneStyle.GetContextRestrictionLabel() return nil end

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/GenerationPerformance.lua")
dofile(base .. "Core/Wardrobe/GenerationWorker.lua")
P.GENERATION_TIME_BUDGET_MS = 1000

local ok, message = Wardrobe.StartGenerateOutfit(false, "TRAVELER")
assert(ok, message)
while #queue > 0 do table.remove(queue, 1)() end
assert(eraCalls == 1, "pre-era rejection still created expensive era work")
assert(liveState.selections.CHEST == 2, "eligible source was not selected after precheck")
print("PASS generation precheck: excluded source skipped era evidence")
