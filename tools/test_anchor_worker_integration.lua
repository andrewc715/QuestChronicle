QuestChronicle = {
    Wardrobe = { _Private = {} },
    ZoneStyle = { Traveler = {} },
}
local QC = QuestChronicle
local W, P = QC.Wardrobe, QC.Wardrobe._Private
P.GENERATION_TIME_BUDGET_MS = 2.5
P.GENERATION_OPERATION_SAFETY_CAP = 2000
P.GENERATION_ERA_CANDIDATES_PER_OPERATION = 1
P.MAIN_WEAPON_SLOT_KEYS = { "ONE_HAND", "TWO_HAND", "RANGED" }
P.slotByKey = {
    CHEST = { key = "CHEST", label = "Chest" }, LEGS = { key = "LEGS", label = "Legs" }, SHOULDER = { key = "SHOULDER", label = "Shoulders" },
    ONE_HAND = { key = "ONE_HAND", label = "One-Hand", weaponRole = "ONE_HAND" }, TWO_HAND = { key = "TWO_HAND", label = "Two-Hand", weaponRole = "TWO_HAND" },
    RANGED = { key = "RANGED", label = "Ranged", weaponRole = "RANGED" }, OFF_HAND = { key = "OFF_HAND", label = "Off Hand", weaponRole = "OFF_HAND" },
}
W.GetSlotDefinition = function(key) return P.slotByKey[key] end
local bySlot = {}
local byID = {}
local function add(slot, id, group, score)
    local source = { slotKey = slot, sourceID = id, visualID = id, group = group, score = score, styleName = group .. " " .. slot }
    bySlot[slot] = bySlot[slot] or {}
    bySlot[slot][#bySlot[slot] + 1] = source
    byID[slot .. ":" .. id] = source
    return source
end
add("CHEST", 1, "A", 20); add("CHEST", 2, "B", 26)
add("LEGS", 3, "A", 20); add("LEGS", 4, "B", 26)
add("SHOULDER", 5, "A", 20); add("SHOULDER", 6, "C", 32)
local weaponA = add("ONE_HAND", 100, "A", 20)
local weaponB = add("ONE_HAND", 101, "B", 26)
W.GetSlotSources = function(slot) return bySlot[slot] or {} end
W.ValidateSource = function(source) return source ~= nil end
P.GetSourceByID = function(slot, id) return byID[slot .. ":" .. tostring(id)] end
P.CopyPrimitiveMap = function(source) local r = {} for k,v in pairs(source or {}) do r[k]=v end return r end
P.SetSelectedSource = function(state, slot, source)
    state.selections[slot] = source and source.sourceID or nil
    state.selectionVisuals[slot] = source and source.visualID or nil
end
P.GenerationNowMilliseconds = function() return 0 end
P.RecordGenerationPhase = function() end
P.CreateStyleGenerationContext = function(state, _, _, _, lockedOnly)
    local context = { outfitProfile = { sourceIDs = {}, setIDs = {}, families = {}, sourceCount = 0, themedSources = 0 }, sources = {} }
    if lockedOnly then
        for slotKey, locked in pairs(state and state.locks or {}) do
            if locked and state.selections[slotKey] and not state.hidden[slotKey] then
                local source = P.GetSourceByID(slotKey, state.selections[slotKey])
                if source then context.sources[#context.sources + 1] = source end
            end
        end
    end
    return context
end

QC.ZoneStyle.GetCurrentContext = function() return {} end
QC.ZoneStyle.PrepareGenerationEligibilityContext = function() end
QC.ZoneStyle.AddSourceToGenerationContext = function(context, source)
    context.sources = context.sources or {}
    context.sources[#context.sources + 1] = source
end
QC.ZoneStyle.GetSourcePreEraEligibilityCached = function() return true end
QC.ZoneStyle.CreateSourceEraEvidenceWork = function() return { done = true, result = { expansionID = 1 } } end
QC.ZoneStyle.GetSourceEligibilityCached = function() return true end
QC.ZoneStyle.GetSourceCoherence = function() return 0, true end
QC.ZoneStyle.ScoreSource = function(source) return source.score end
QC.ZoneStyle.GetTravelerDescriptor = function(source, definition)
    return { fingerprint = source.sourceID .. ":" .. definition.key, loudness = 0.3, group = source.group }
end
QC.ZoneStyle.Traveler.GetPairCohesion = function(left, right) return left.group == right.group and 0.95 or 0.20 end

P.CreateWeaponGenerationWork = function(state)
    return { state = state, step = 0, maxResumeMs = 0 }
end
P.StepWeaponGenerationWork = function(work)
    work.step = work.step + 1
    if work.step == 1 then return false end
    local chest = P.GetSourceByID("CHEST", work.state.selections.CHEST)
    local weapon = chest and chest.group == "A" and weaponA or weaponB
    P.SetSelectedSource(work.state, "ONE_HAND", weapon)
    work.state.lastWeaponRoute = { routeID = "TEST", mainSourceID = weapon.sourceID, offSourceID = nil }
    return true, true, 1, nil
end

math.randomseed(9)
dofile("Core/Wardrobe/AnchorSkeletonCache.lua")
dofile("Core/Wardrobe/AnchorSkeletonNovelty.lua")
dofile("Core/Wardrobe/AnchorSkeletonSearch.lua")
dofile("Core/Wardrobe/AnchorSkeletonWorker.lua")
dofile("Core/Wardrobe/AnchorSkeletonApply.lua")

local draft = {
    selections = {}, selectionVisuals = {}, locks = {}, hidden = {},
    weaponFamilies = { ONE_HAND = true }, weaponSubtypes = {}, linkWeaponHands = true,
}
local job = {
    draft = draft, reroll = false, styleEngine = QC.ZoneStyle, styleMode = "TRAVELER",
    styleContext = P.CreateStyleGenerationContext(), selectedArmor = 0, candidatesProcessed = 0,
    eraCandidatesProcessed = 0, weaponYields = 0, phaseStats = {},
}
local result
for _ = 1, 10000 do
    result = P.StepAnchorSkeletonJob(job, 0)
    if result ~= "RUNNING" then break end
end
assert(result == "READY", "anchor worker should produce a complete skeleton")
assert(P.GetSourceByID("CHEST", draft.selections.CHEST).group == "A", "worker should choose coherent chest")
assert(P.GetSourceByID("LEGS", draft.selections.LEGS).group == "A", "worker should choose coherent legs")
assert(job.anchorStats.meanPairCohesion > 0.50, "chosen skeleton should remain more coherent than neutral")
assert(P.GetSourceByID("ONE_HAND", draft.selections.ONE_HAND).group == "A", "weapon bundle should reinforce the armor skeleton")
assert(job.anchorStats and job.anchorStats.weaponBundles > 0, "worker should expose skeleton diagnostics")
assert(job.weaponYields > 0, "weapon shortlist generation should remain cooperative")
assert(job.draft.lastAnchorSkeletonSignature, "chosen skeleton signature should be retained for reroll diversity")

local currentState = {
    selections = { CHEST = 2, LEGS = 4, SHOULDER = 6, ONE_HAND = 101 },
    selectionVisuals = { CHEST = 2, LEGS = 4, SHOULDER = 6, ONE_HAND = 101 },
    locks = {}, hidden = {}, weaponFamilies = { ONE_HAND = true }, weaponSubtypes = {}, linkWeaponHands = true,
    lastAnchorSkeletonSignature = "current-b",
}
local noveltyDraft = {
    selections = P.CopyPrimitiveMap(currentState.selections), selectionVisuals = P.CopyPrimitiveMap(currentState.selectionVisuals),
    locks = {}, hidden = {}, weaponFamilies = { ONE_HAND = true }, weaponSubtypes = {}, linkWeaponHands = true,
    lastAnchorSkeletonSignature = currentState.lastAnchorSkeletonSignature,
}
local noveltyJob = {
    action = "GENERATE_OUTFIT", liveState = currentState, draft = noveltyDraft,
    currentAnchorNovelty = P.BuildAnchorNoveltyContext(currentState),
    reroll = false, styleEngine = QC.ZoneStyle, styleMode = "TRAVELER",
    styleContext = P.CreateStyleGenerationContext(), selectedArmor = 0, candidatesProcessed = 0,
    eraCandidatesProcessed = 0, weaponYields = 0, phaseStats = {},
}
math.randomseed(17)
for _ = 1, 10000 do
    result = P.StepAnchorSkeletonJob(noveltyJob, 0)
    if result ~= "RUNNING" then break end
end
assert(result == "READY", "repeated Generate Outfit should still produce a complete skeleton")
assert(noveltyJob.anchorStats.noveltyClass == "MEANINGFULLY_NEW", "Generate Outfit should select a meaningfully new skeleton when one remains inside the quality window")
assert(#(noveltyJob.anchorStats.changedComponents or {}) >= 2, "integrated novelty selection should record at least two changed logical anchors")

local lockedDraft = {
    selections = { CHEST = 2, SHOULDER = 6 }, selectionVisuals = { CHEST = 2, SHOULDER = 6 },
    locks = { CHEST = true }, hidden = { SHOULDER = true },
    weaponFamilies = { ONE_HAND = true }, weaponSubtypes = {}, linkWeaponHands = true,
}
local lockedJob = {
    draft = lockedDraft, reroll = true, styleEngine = QC.ZoneStyle, styleMode = "TRAVELER",
    styleContext = P.CreateStyleGenerationContext(), selectedArmor = 0, candidatesProcessed = 0,
    eraCandidatesProcessed = 0, weaponYields = 0, phaseStats = {},
}
for _ = 1, 10000 do
    result = P.StepAnchorSkeletonJob(lockedJob, 0)
    if result ~= "RUNNING" then break end
end
assert(result == "READY", "locked and hidden anchors should still produce a skeleton")
assert(lockedDraft.selections.CHEST == 2, "locked chest must remain fixed")
assert(lockedDraft.selections.SHOULDER == 6, "hidden shoulder selection must remain untouched")
assert(lockedJob.anchorStats.poolSizes.SHOULDER == 0, "hidden shoulders must be omitted from the beam")
local lockedChestContextCount = 0
for _, source in ipairs(lockedJob.styleContext.sources or {}) do
    if source.sourceID == 2 then lockedChestContextCount = lockedChestContextCount + 1 end
end
assert(lockedChestContextCount == 1, "locked anchor must seed the supporting context exactly once")

local missingLockedDraft = {
    selections = { CHEST = 999 }, selectionVisuals = { CHEST = 999 },
    locks = { CHEST = true }, hidden = {},
    weaponFamilies = { ONE_HAND = true }, weaponSubtypes = {}, linkWeaponHands = true,
}
local missingLockedJob = {
    draft = missingLockedDraft, reroll = true, styleEngine = QC.ZoneStyle, styleMode = "TRAVELER",
    styleContext = P.CreateStyleGenerationContext(), selectedArmor = 0, candidatesProcessed = 0,
    eraCandidatesProcessed = 0, weaponYields = 0, phaseStats = {},
}
for _ = 1, 100 do
    result = P.StepAnchorSkeletonJob(missingLockedJob, 0)
    if result ~= "RUNNING" then break end
end
assert(result == "FALLBACK", "an unavailable locked anchor must force the legacy fallback")
assert(missingLockedDraft.selections.CHEST == 999, "fallback must preserve the unavailable locked selection")

local hiddenDraft = {
    selections = {}, selectionVisuals = {}, locks = {}, hidden = { CHEST = true, LEGS = true, SHOULDER = true },
    weaponFamilies = { ONE_HAND = true }, weaponSubtypes = {}, linkWeaponHands = true,
}
local hiddenJob = {
    draft = hiddenDraft, reroll = false, styleEngine = QC.ZoneStyle, styleMode = "TRAVELER",
    styleContext = P.CreateStyleGenerationContext(), selectedArmor = 0, candidatesProcessed = 0,
    eraCandidatesProcessed = 0, weaponYields = 0, phaseStats = {},
}
for _ = 1, 100 do
    result = P.StepAnchorSkeletonJob(hiddenJob, 0)
    if result ~= "RUNNING" then break end
end
assert(result == "FALLBACK", "an outfit with no active armor anchors should use the legacy fallback")
assert(next(hiddenDraft.selections) == nil, "failed anchor search must not mutate the private draft")
print(string.format("PASS anchor worker: rank %d/%d score %.1f yields %d; locked/hidden and fallback preserved", job.anchorStats.chosenRank, job.anchorStats.shortlistSize, job.anchorStats.chosenScore, job.weaponYields))
