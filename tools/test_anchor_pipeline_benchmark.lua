local clock = 0
local function Advance(milliseconds) clock = clock + milliseconds end

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
    CHEST = { key = "CHEST", label = "Chest" },
    LEGS = { key = "LEGS", label = "Legs" },
    SHOULDER = { key = "SHOULDER", label = "Shoulders" },
    ONE_HAND = { key = "ONE_HAND", label = "One-Hand", weaponRole = "ONE_HAND" },
    TWO_HAND = { key = "TWO_HAND", label = "Two-Hand", weaponRole = "TWO_HAND" },
    RANGED = { key = "RANGED", label = "Ranged", weaponRole = "RANGED" },
    OFF_HAND = { key = "OFF_HAND", label = "Off Hand", weaponRole = "OFF_HAND" },
}

local sources, byID = {}, {}
local function AddSource(slotKey, sourceID, family, score)
    local source = {
        slotKey = slotKey,
        sourceID = sourceID,
        visualID = sourceID,
        family = family,
        score = score,
        styleName = family .. " " .. slotKey,
    }
    sources[slotKey] = sources[slotKey] or {}
    sources[slotKey][#sources[slotKey] + 1] = source
    byID[slotKey .. ":" .. sourceID] = source
    return source
end
for index = 1, 48 do AddSource("CHEST", 1000 + index, "F" .. ((index - 1) % 8 + 1), 28 - index * 0.05) end
for index = 1, 32 do AddSource("LEGS", 2000 + index, "F" .. ((index - 1) % 8 + 1), 27 - index * 0.05) end
for index = 1, 32 do AddSource("SHOULDER", 3000 + index, "F" .. ((index - 1) % 8 + 1), 26 - index * 0.05) end
local weapons = {}
for index = 1, 8 do weapons[index] = AddSource("ONE_HAND", 4000 + index, "F" .. index, 25) end

function P.GenerationNowMilliseconds() return clock end
function P.RecordGenerationPhase() end
function P.CopyPrimitiveMap(source)
    local result = {}
    for key, value in pairs(source or {}) do result[key] = value end
    return result
end
function P.SetSelectedSource(state, slotKey, source)
    state.selections[slotKey] = source and source.sourceID or nil
    state.selectionVisuals[slotKey] = source and source.visualID or nil
end
function P.GetSourceByID(slotKey, sourceID) return byID[slotKey .. ":" .. tostring(sourceID)] end
function P.CreateStyleGenerationContext(_, _, base)
    return { base = base, outfitProfile = { sourceIDs = {}, setIDs = {}, families = {}, sourceCount = 0, themedSources = 0 } }
end

function W.GetSlotSources(slotKey) return sources[slotKey] or {} end
function W.ValidateSource(source, slotKey) Advance(0.006) return source and source.slotKey == slotKey end

function QC.ZoneStyle.GetCurrentContext() return { profileLabel = "Benchmark" } end
function QC.ZoneStyle.PrepareGenerationEligibilityContext() Advance(0.01) end
function QC.ZoneStyle.AddSourceToGenerationContext(context) context.outfitProfile.sourceCount = context.outfitProfile.sourceCount + 1 end
function QC.ZoneStyle.GetSourcePreEraEligibilityCached() Advance(0.004) return true end
function QC.ZoneStyle.CreateSourceEraEvidenceWork(source) Advance(0.004) return { done = true, result = { expansionID = 1, sourceID = source.sourceID } } end
function QC.ZoneStyle.GetSourceEligibilityCached() Advance(0.004) return true end
function QC.ZoneStyle.GetSourceCoherence() Advance(0.003) return 0, true end
function QC.ZoneStyle.ScoreSource(source) Advance(0.004) return source.score end
function QC.ZoneStyle.GetTravelerDescriptor(source, definition)
    Advance(0.002)
    return {
        fingerprint = source.family .. ":" .. definition.key,
        loudness = 0.35,
        group = source.family,
        dominantMaterial = source.family,
        dominantMotif = "BENCH",
        dominantPalette = source.family,
    }
end
function QC.ZoneStyle.Traveler.GetPairCohesion(left, right)
    Advance(0.010)
    return left.group == right.group and 0.94 or 0.46
end

function P.CreateWeaponGenerationWork(state)
    return { state = state, step = 0, maxResumeMs = 0 }
end
function P.StepWeaponGenerationWork(work)
    Advance(0.35)
    work.step = work.step + 1
    if work.step <= 20 then return false end
    local chest = P.GetSourceByID("CHEST", work.state.selections.CHEST)
    local familyIndex = tonumber(chest and chest.family:match("(%d+)$")) or 1
    local weapon = weapons[familyIndex]
    P.SetSelectedSource(work.state, "ONE_HAND", weapon)
    work.state.lastWeaponRoute = { routeID = "BENCH", mainSourceID = weapon.sourceID }
    return true, true, 1, nil
end

math.randomseed(1902)
dofile("Core/Wardrobe/AnchorSkeletonCache.lua")
dofile("Core/Wardrobe/AnchorSkeletonSearch.lua")
dofile("Core/Wardrobe/AnchorSkeletonWorker.lua")

local job = {
    draft = {
        selections = {}, selectionVisuals = {}, locks = {}, hidden = {},
        weaponFamilies = { ONE_HAND = true }, weaponSubtypes = {}, linkWeaponHands = true,
    },
    reroll = false,
    styleEngine = QC.ZoneStyle,
    styleMode = "TRAVELER",
    styleContext = P.CreateStyleGenerationContext(),
    selectedArmor = 0,
    candidatesProcessed = 0,
    eraCandidatesProcessed = 0,
    weaponYields = 0,
    phaseStats = {},
}

local frames, maximumStep, status = 0, 0, "RUNNING"
while status == "RUNNING" do
    local frameStarted = clock
    status = P.StepAnchorSkeletonJob(job, frameStarted)
    local elapsed = clock - frameStarted
    if elapsed > maximumStep then maximumStep = elapsed end
    frames = frames + 1
    assert(frames < 100, "anchor pipeline exceeded benchmark frame safety limit")
end

assert(status == "READY", "anchor pipeline failed to produce a skeleton")
assert(job.candidatesProcessed == 112, "anchor candidate count mismatch")
assert(job.weaponYields == 80, "cooperative weapon yield count mismatch")
assert(job.anchorStats.expansions.CHEST == 48, "chest seed count mismatch")
assert(job.anchorStats.expansions.LEGS == 1024, "leg expansion count mismatch")
assert(job.anchorStats.expansions.SHOULDER == 1024, "shoulder expansion count mismatch")
assert(job.anchorStats.weaponBundles == 4, "weapon bundle shortlist count mismatch")
assert(frames < 50, "anchor beam regressed beyond the synthetic frame target")
assert(maximumStep < 3.2, "anchor beam exceeded the expected frame-budget overshoot")
print(string.format(
    "PASS anchor pipeline benchmark: 112 candidates + 2096 beam expansions + %d weapon yields across %d frames, max %.2f ms",
    job.weaponYields,
    frames,
    maximumStep
))
