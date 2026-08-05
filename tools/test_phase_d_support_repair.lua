QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} } }
local P = QuestChronicle.Wardrobe._Private
local T = QuestChronicle.ZoneStyle.Traveler
P.SUPPORT_SLOT_ORDER = { "HEAD", "BACK" }
P.slotByKey = { HEAD = { label = "Head" }, BACK = { label = "Back" } }
P.SupportVisualIdentity = function(source) return tostring(source and source.visualID or "") end
P.GenerationNowMilliseconds = function() return 0 end
P.RecordGenerationPhase = function() end
P.CreateSupportBudget = function() return { remaining = 10 } end
P.CommitSupportBudget = function(budget) return budget end
P.ScoreSupportCandidate = function(candidate)
    return { slotKey = candidate.slotKey, candidate = candidate, allowed = true, mismatchSpent = candidate.descriptor.points or 0,
        budgetEvaluation = { allowed = true }, score = candidate.score or 0, outlierState = candidate.descriptor.phaseCOutlier or "NORMAL" }
end
T.SLOT_VISIBILITY_WEIGHTS = { CHEST = 1, HEAD = .9, BACK = .55 }
T.CONFIG = { thresholds = { loudImpact = .55 } }
T.GetTravelerDominantPalette = function(descriptor) return descriptor.paletteFamily end
T.GetTravelerProfileCohesion = function(descriptor) return descriptor.profile or 1, { finish = 1, visualWeight = 1, material = 1, motif = 1 } end
T.GetTravelerEchoSupport = function(entry) return entry.descriptor.echo or 0 end
T.ClassifyTravelerMismatch = function(entry)
    entry.visualImpact = entry.descriptor.impact or 0
    return entry.descriptor.class or "COHESIVE", entry.descriptor.points or 0, "fixture", 1, "material"
end
T.GetTravelerOutlierSeverity = function(entry) return entry.descriptor.severity or 0, {} end

dofile("Core/Wardrobe/SupportFinalValidation.lua")
dofile("Core/Wardrobe/SupportRepair.lua")

local function C(slot, id, descriptor, score)
    return { slotKey = slot, source = { sourceID = id, visualID = id, styleName = slot .. id }, descriptor = descriptor, prominence = T.SLOT_VISIBILITY_WEIGHTS[slot], score = score or 0 }
end
local badHead = C("HEAD", 1, { paletteFamily = "red", class = "POSTAL", impact = .9, severity = .9 }, 1)
local goodHead = C("HEAD", 2, { paletteFamily = "steel", class = "COHESIVE", severity = .1 }, 2)
local badBack = C("BACK", 3, { paletteFamily = "blue", class = "POSTAL", impact = .8, severity = .8 }, 1)
local goodBack = C("BACK", 4, { paletteFamily = "steel", class = "COHESIVE", severity = .1 }, 2)
local profile = { descriptor = {}, entries = { { slotKey = "CHEST", label = "Chest", source = { sourceID = 99 }, descriptor = { paletteFamily = "steel" } } }, meanAnchorCohesion = .7 }
local supportWork = { activeSlots = { "HEAD", "BACK" }, profile = profile, pools = { HEAD = { badHead, goodHead }, BACK = { badBack, goodBack } }, lockedSelections = {} }
local job = { draft = { hidden = {}, locks = {} }, phaseStats = {} }
local initial = assert(P.RebuildSupportConfiguration(job, supportWork, { HEAD = badHead, BACK = badBack }))
local work = P.CreateSupportFinalizationWork(job, supportWork, initial, 1, 1, {})
local status, guard
for index = 1, 200 do
    status = P.StepSupportFinalization(job, supportWork, work)
    if status ~= "RUNNING" then guard = index break end
end
assert(guard and status == "READY", "two-pass repair must finish")
assert(work.finalStatus == "REPAIRED", "repaired status expected")
assert(#work.repairs == 2, "exactly two repair passes expected")
assert(work.finalConfiguration.selected.HEAD == goodHead and work.finalConfiguration.selected.BACK == goodBack, "both outliers must be replaced")
assert(work.finalValidation.status == "CLEAN", "final configuration must be clean")
assert(work.repairs[1].slotKey == "HEAD", "worst outlier must be repaired first")

local impossibleWork = { activeSlots = { "HEAD", "BACK" }, profile = profile, pools = { HEAD = { badHead }, BACK = { badBack } }, lockedSelections = {} }
local impossible = assert(P.RebuildSupportConfiguration(job, impossibleWork, { HEAD = badHead, BACK = badBack }))
local failWork = P.CreateSupportFinalizationWork(job, impossibleWork, impossible, 1, 1, {})
local failStatus
for _ = 1, 200 do
    failStatus = P.StepSupportFinalization(job, impossibleWork, failWork)
    if failStatus ~= "RUNNING" then break end
end
assert(failStatus == "ALTERNATE", "unresolved support must request the next skeleton")
assert(failWork.repairPass == 2, "a third repair pass must never start")

job.draft.locks.HEAD = true
local lockedWork = { activeSlots = { "HEAD", "BACK" }, profile = profile, pools = { HEAD = { badHead }, BACK = { goodBack } }, lockedSelections = { HEAD = badHead } }
local lockedConfiguration = assert(P.RebuildSupportConfiguration(job, lockedWork, { HEAD = badHead, BACK = goodBack }))
local lockedPhaseD = P.CreateSupportFinalizationWork(job, lockedWork, lockedConfiguration, 1, 1, {})
local lockedStatus
for _ = 1, 20 do
    lockedStatus = P.StepSupportFinalization(job, lockedWork, lockedPhaseD)
    if lockedStatus ~= "RUNNING" then break end
end
assert(lockedStatus == "READY" and lockedPhaseD.finalStatus == "LOCKED_OVERRIDE", "locked-only mismatch must commit as an override")
assert(lockedPhaseD.finalConfiguration.selected.HEAD == badHead, "locked appearance must remain sovereign")

print("PASS Phase D bounded two-pass repair, alternate request, and locked override")
