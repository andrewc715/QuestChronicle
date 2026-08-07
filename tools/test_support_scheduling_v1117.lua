local clock = 0
function debugprofilestop() return clock end
QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} }, _Core = {} }
local W, P = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
P.GENERATION_OPERATION_SAFETY_CAP = 1000
P.GENERATION_TIME_BUDGET_MS = 5.5
P.GENERATION_ERA_CANDIDATES_PER_OPERATION = 1
P.SUPPORT_SLOT_ORDER = { "WAIST" }
P.slotByKey = { WAIST = { key = "WAIST", label = "Waist" } }
W.slotDefinitions = { P.slotByKey.WAIST }

dofile("Core/Workers/SliceBudget.lua")
dofile("Core/Wardrobe/GenerationScheduling.lua")
function P.GenerationNowMilliseconds() clock = clock + 0.01 return clock end
function P.RecordGenerationPhase(job, key, elapsed)
    job.phaseStats = job.phaseStats or {}
    local row = job.phaseStats[key] or { calls = 0, totalMs = 0, maxMs = 0 }
    job.phaseStats[key] = row
    row.calls, row.totalMs, row.maxMs = row.calls + 1, row.totalMs + elapsed, math.max(row.maxMs, elapsed)
end

-- Fresh-slice admission is operation-aware and non-mutating.
local admissionJob = { currentSlice = { forceYield = false, operationCount = 1, startedAtMs = clock, preferredMs = 5.5 } }
assert(P.CanStartFreshGenerationPhase(admissionJob, 0.25) == false, "used slice must reject fresh phase")
admissionJob.currentSlice.operationCount = 0
admissionJob.currentSlice.startedAtMs = clock
assert(P.CanStartFreshGenerationPhase(admissionJob, 0.25) == true, "empty slice must admit fresh phase")

-- Load beam and worker dependencies with compact deterministic stubs.
function P.CopySupportBudget(b) local r = {}; for k,v in pairs(b or {}) do r[k]=v end; return r end
function P.CommitSupportBudget(b) return P.CopySupportBudget(b) end
function P.SupportVisualIdentity(source) return tostring(source and source.visualID or 0) end
function P.CreateSupportBudget() return { starting=10, lockedCommitment=0, generatedSpend=0, borrowed=0, overrun=0, remaining=10 } end
function P.BuildActiveAnchorMask() return {} end
function P.BuildContextualSupportProfile() return { meanAnchorCohesion=.5 } end
function P.BuildSupportCandidate(source) return { source=source, poolPriority=source.poolPriority or 1 } end
function P.AddSupportPoolCandidate() end
function P.FinalizeSupportPool() end
function W.GetSlotSources() return {} end
function W.ValidateSource() return true end
function P.GetSourceByID() return nil end
function P.SetSelectedSource() end

dofile("Core/Wardrobe/SupportBeam.lua")
dofile("Core/Wardrobe/SupportWorker.lua")

-- Fallback scanning evaluates one candidate per operation and keeps first-best ties.
local scored = 0
function P.ScoreSupportCandidate(candidate)
    scored = scored + 1
    return { candidate=candidate, slotKey="WAIST", mismatchSpent=candidate.cost, score=0,
        allowed=false, budgetEvaluation={ allowed=false } }
end
local pool = {
    { source={visualID=1}, cost=4 },
    { source={visualID=2}, cost=2 },
    { source={visualID=3}, cost=2 },
}
local beam = P.CreateSupportBeamWork({}, {}, {lockedCommitment=0}, {"WAIST"}, {WAIST=pool}, {}, {})
while P.DescribeNextSupportBeamOperation(beam) == "CANDIDATE" do P.StepSupportBeamWork(beam) end
assert(P.DescribeNextSupportBeamOperation(beam) == "FALLBACK_SCAN", "fallback operation must be explicit")
local fallbackSteps = 0
while P.DescribeNextSupportBeamOperation(beam) == "FALLBACK_SCAN" do
    P.StepSupportBeamWork(beam)
    fallbackSteps = fallbackSteps + 1
    assert(fallbackSteps < 10, "fallback scan did not complete")
end
assert(fallbackSteps == 3, "fallback must score one candidate per operation")
assert(beam.nextBeam[1].selected.WAIST.source.visualID == 2, "first lowest-mismatch candidate must win tie")
assert(scored == 6, "normal and fallback passes must each score the pool once")

-- Stage finalization defers on a used slice and starts on the next fresh slice.
local candidate = { source={visualID=9} }
local finalizeBeam = P.CreateSupportBeamWork({}, {}, {lockedCommitment=0}, {"WAIST"}, {WAIST={}}, {}, {})
finalizeBeam.beam = {}
finalizeBeam.nextBeam = { { selected={WAIST=candidate}, decisions={}, budget={}, totalScore=10, mismatchSpent=0, fallbackCount=0 } }
local job = {
    supportWork = { stage="BEAM", beamWork=finalizeBeam },
    currentSlice = { forceYield=false, operationCount=1, startedAtMs=clock, preferredMs=5.5 },
    phaseStats = {}, candidatesProcessed=0, eraCandidatesProcessed=0,
}
local beforeStage = finalizeBeam.stageIndex
local status = P.StepSupportGenerationJob(job, clock)
assert(status == "RUNNING" and finalizeBeam.stageIndex == beforeStage, "used-slice finalization must defer without mutation")
assert(job.supportBeamFreshSliceDeferrals == 1, "fresh-slice deferral must be counted")
job.currentSlice = { forceYield=false, operationCount=0, startedAtMs=clock, preferredMs=5.5 }
status = P.StepSupportGenerationJob(job, clock)
assert(status == "RUNNING" and finalizeBeam.stageIndex == beforeStage + 1, "fresh slice must execute finalization")
assert(job.supportBeamStageFinalizations == 1, "stage finalization must be counted")
assert(job.phaseStats.supportBeamStageFinalize and job.phaseStats.supportBeamExpansion, "specific and aggregate timing must be retained")

print("PASS v1.11.7 support scheduling: bounded fallback, fresh-stage admission, and split diagnostics")
