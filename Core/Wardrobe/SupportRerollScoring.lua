local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local Workers = QC._Core and QC._Core.Workers

local function NowMilliseconds()
    return P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
end

local function Record(job, phaseKey, startedAt)
    local elapsed = NowMilliseconds() - startedAt
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, phaseKey, elapsed) end
    if Workers and Workers.NoteAdaptiveCost then
        job.adaptiveCosts = job.adaptiveCosts or {}
        job.adaptiveCosts[phaseKey] = Workers.NoteAdaptiveCost(job.adaptiveCosts[phaseKey], elapsed)
    end
    return elapsed
end

local function FinishSource(job, work)
    work.candidateWork = nil
    work.sourceIndex = work.sourceIndex + 1
    job.candidatesProcessed = (job.candidatesProcessed or 0) + 1
end

function P.CreateSupportRerollPoolWork(job)
    local slotKey = job.actionSlotKey
    local currentSourceID = job.draft.selections[slotKey]
    local currentSource = currentSourceID and P.GetSourceByID(slotKey, currentSourceID)
    return {
        slotKey = slotKey,
        definition = P.slotByKey[slotKey],
        sources = Wardrobe.GetSlotSources(slotKey) or {},
        sourceIndex = 1,
        candidateWork = nil,
        byVisual = {},
        pool = {},
        poolLimit = P.SUPPORT_POOL_LIMIT,
        currentSource = currentSource,
        currentIdentity = currentSource and P.SupportVisualIdentity(currentSource) or nil,
        currentCandidate = nil,
        deduplicated = 0,
        done = false,
    }
end

local function StepValidation(job, work, candidate)
    local started = NowMilliseconds()
    candidate.valid = Wardrobe.ValidateSource(candidate.source, work.slotKey) == true
    candidate.stage = candidate.valid and "PRECHECK" or "DONE"
    Record(job, "rerollSourceValidation", started)
    if not candidate.valid then FinishSource(job, work) end
end

local function StepPrecheck(job, work, candidate)
    local style = job.styleEngine
    if not style or not style.GetSourcePreEraEligibility then
        candidate.prechecked = false
        candidate.stage = "ERA_INIT"
        return
    end
    local started = NowMilliseconds()
    local eligible = style.GetSourcePreEraEligibilityCached and style.GetSourcePreEraEligibilityCached(candidate.source, job.styleContext)
        or style.GetSourcePreEraEligibility(candidate.source, job.styleContext)
    candidate.prechecked = true
    candidate.stage = eligible and "ERA_INIT" or "DONE"
    Record(job, "rerollEligibility", started)
    if not eligible then FinishSource(job, work) end
end

local function StepEraInit(job, work, candidate)
    local style = job.styleEngine
    if style and style.CreateSourceEraEvidenceWork then
        candidate.eraWork = style.CreateSourceEraEvidenceWork(candidate.source)
        if candidate.eraWork.done then
            candidate.eraEvidence = candidate.eraWork.result
            candidate.stage = "ELIGIBILITY_INIT"
        else
            candidate.stage = "ERA_STEP"
        end
        return
    end
    if style and style.GetSourceEraEvidence then
        local started = NowMilliseconds()
        candidate.eraEvidence = style.GetSourceEraEvidence(candidate.source)
        Record(job, "rerollEraEvidence", started)
    end
    candidate.stage = "ELIGIBILITY_INIT"
end

local function StepEraWork(job, candidate)
    local started = NowMilliseconds()
    local done, evidence, processed = job.styleEngine.StepSourceEraEvidenceWork(
        candidate.eraWork,
        P.GENERATION_ERA_CANDIDATES_PER_OPERATION
    )
    job.eraCandidatesProcessed = (job.eraCandidatesProcessed or 0) + (tonumber(processed) or 0)
    local eraElapsed = Record(job, "rerollEraEvidence", started)
    if P.RecordEraSchedulingOperation then P.RecordEraSchedulingOperation(job, candidate.eraWork, eraElapsed) end
    if done then
        candidate.eraEvidence = evidence
        candidate.stage = "ELIGIBILITY_INIT"
    end
end

local function FinishEligibilityCandidate(job, work, candidate, eligible)
    candidate.eligible = eligible == true
    candidate.stage = candidate.eligible and "BUILD" or "DONE"
    if not candidate.eligible then FinishSource(job, work) end
end

local function StepEligibilityInit(job, work, candidate)
    if not job.styleEngine then candidate.stage = "BUILD" return end
    if job.styleEngine.CreateCachedSourceEligibilityWork then
        local started = NowMilliseconds()
        candidate.eligibilityWork = job.styleEngine.CreateCachedSourceEligibilityWork(
            candidate.source, job.styleMode, job.styleContext, candidate.eraEvidence, candidate.prechecked
        )
        local elapsed = Record(job, "rerollEligibility", started)
        if candidate.eligibilityWork.done then
            FinishEligibilityCandidate(job, work, candidate, candidate.eligibilityWork.eligible)
        else
            candidate.stage = "ELIGIBILITY_STEP"
        end
        return elapsed
    end
    local started = NowMilliseconds()
    local eligible = job.styleEngine.GetSourceEligibilityCached and job.styleEngine.GetSourceEligibilityCached(
        candidate.source, job.styleMode, job.styleContext, candidate.eraEvidence, candidate.prechecked
    ) or job.styleEngine.GetSourceEligibility(
        candidate.source, job.styleMode, job.styleContext, candidate.eraEvidence, candidate.prechecked
    )
    local elapsed = Record(job, "rerollEligibility", started)
    FinishEligibilityCandidate(job, work, candidate, eligible)
    return elapsed
end

local function StepEligibilityWork(job, work, candidate)
    local started = NowMilliseconds()
    local done, eligible = job.styleEngine.StepCachedSourceEligibilityWork(candidate.eligibilityWork, 4)
    local elapsed = Record(job, "rerollEligibility", started)
    if done then FinishEligibilityCandidate(job, work, candidate, eligible) end
    return elapsed
end

local function StepBuild(job, work, candidate)
    local started = NowMilliseconds()
    local built = P.BuildSupportCandidate(candidate.source, work.definition, job, job.supportRerollProfile, nil)
    Record(job, "rerollCandidatePreparation", started)
    if built then
        local identity = P.SupportVisualIdentity(built.source)
        if identity == work.currentIdentity then work.currentCandidate = built else P.AddSupportPoolCandidate(work, built) end
    end
    FinishSource(job, work)
end

function P.StepSupportRerollPool(job, work)
    if work.done then return true end
    if work.sourceIndex > #work.sources then
        local started = NowMilliseconds()
        P.FinalizeSupportPool(work)
        Record(job, "rerollCandidatePreparation", started)
        work.done = true
        return true
    end

    local candidate = work.candidateWork
    if not candidate then
        candidate = { source = work.sources[work.sourceIndex], stage = "VALIDATE" }
        work.candidateWork = candidate
    end

    if candidate.stage == "VALIDATE" then StepValidation(job, work, candidate)
    elseif candidate.stage == "PRECHECK" then StepPrecheck(job, work, candidate)
    elseif candidate.stage == "ERA_INIT" then StepEraInit(job, work, candidate)
    elseif candidate.stage == "ERA_STEP" then StepEraWork(job, candidate)
    elseif candidate.stage == "ELIGIBILITY_INIT" then StepEligibilityInit(job, work, candidate)
    elseif candidate.stage == "ELIGIBILITY_STEP" then StepEligibilityWork(job, work, candidate)
    elseif candidate.stage == "BUILD" then StepBuild(job, work, candidate)
    elseif candidate.stage == "DONE" then FinishSource(job, work) end
    return false
end

local function SortDecisions(decisions)
    table.sort(decisions, function(left, right)
        if left.score == right.score then return tostring(P.SupportVisualIdentity(left.source)) < tostring(P.SupportVisualIdentity(right.source)) end
        return left.score > right.score
    end)
end

function P.ChooseSupportRerollDecision(work)
    SortDecisions(work.decisions)
    local shortlist = {}
    local limit = math.min(P.SUPPORT_FINAL_SHORTLIST or 6, #work.decisions)
    for index = 1, limit do shortlist[index] = work.decisions[index] end
    if #shortlist == 0 then return nil, 0, 0 end
    local minimum = shortlist[#shortlist].score
    local total = 0
    for _, decision in ipairs(shortlist) do
        decision.selectionWeight = math.max(1, (decision.score - minimum + 4) ^ 2)
        total = total + decision.selectionWeight
    end
    local roll = math.random() * total
    for rank, decision in ipairs(shortlist) do
        roll = roll - decision.selectionWeight
        if roll <= 0 then return decision, rank, #shortlist end
    end
    return shortlist[#shortlist], #shortlist, #shortlist
end
