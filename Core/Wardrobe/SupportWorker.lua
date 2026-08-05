local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function NowMilliseconds()
    return P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
end

local function RecordPhase(job, phaseKey, startedAt)
    local elapsed = math.max(0, NowMilliseconds() - startedAt)
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, phaseKey, elapsed) end
    if P.NoteGenerationWorkerCall then P.NoteGenerationWorkerCall(job, elapsed) end
    return elapsed
end

local function ActiveSupportSlots(state)
    local active = {}
    for _, slotKey in ipairs(P.SUPPORT_SLOT_ORDER or {}) do
        local hasSources = #(Wardrobe.GetSlotSources(slotKey) or {}) > 0
        local selected = state.selections and state.selections[slotKey]
        if P.slotByKey[slotKey] and not (state.hidden and state.hidden[slotKey]) and (hasSources or selected) then active[#active + 1] = slotKey end
    end
    return active
end

local function CreatePoolWork(job, slotKey)
    local definition = P.slotByKey[slotKey]
    local currentSourceID = job.liveState and job.liveState.selections and job.liveState.selections[slotKey]
    local currentSource = currentSourceID and P.GetSourceByID(slotKey, currentSourceID)
    return {
        slotKey = slotKey, definition = definition, sources = Wardrobe.GetSlotSources(slotKey), sourceIndex = 1,
        candidateWork = nil, byVisual = {}, pool = {}, poolLimit = P.SUPPORT_POOL_LIMIT,
        currentSourceID = job.reroll and nil or (currentSource and P.SupportVisualIdentity(currentSource) or nil),
        excludeVisualID = job.reroll and currentSource and P.SupportVisualIdentity(currentSource) or nil,
        fallback = nil, deduplicated = 0, done = false,
    }
end

local function ContinueCandidate(job, work)
    local candidateWork = work.candidateWork
    if not candidateWork then
        local source = work.sources[work.sourceIndex]
        candidateWork = { source = source }
        work.candidateWork = candidateWork
        local started = NowMilliseconds()
        candidateWork.valid = Wardrobe.ValidateSource(source, work.slotKey) == true
        RecordPhase(job, "supportValidation", started)
        if not candidateWork.valid then return true end
        if job.styleEngine and job.styleEngine.GetSourcePreEraEligibility then
            started = NowMilliseconds()
            local eligible = job.styleEngine.GetSourcePreEraEligibilityCached and job.styleEngine.GetSourcePreEraEligibilityCached(source, job.styleContext)
                or job.styleEngine.GetSourcePreEraEligibility(source, job.styleContext)
            RecordPhase(job, "supportEligibility", started)
            if not eligible then return true end
            candidateWork.prechecked = true
        end
        if job.styleEngine then
            started = NowMilliseconds()
            if job.styleEngine.CreateSourceEraEvidenceWork then
                candidateWork.eraWork = job.styleEngine.CreateSourceEraEvidenceWork(source)
                if candidateWork.eraWork.done then candidateWork.eraEvidence = candidateWork.eraWork.result end
            elseif job.styleEngine.GetSourceEraEvidence then candidateWork.eraEvidence = job.styleEngine.GetSourceEraEvidence(source) end
            RecordPhase(job, "supportEraEvidence", started)
        end
    end
    if candidateWork.eraWork and not candidateWork.eraWork.done then
        local started = NowMilliseconds()
        local done, evidence, processed = job.styleEngine.StepSourceEraEvidenceWork(candidateWork.eraWork, P.GENERATION_ERA_CANDIDATES_PER_OPERATION)
        job.eraCandidatesProcessed = job.eraCandidatesProcessed + (tonumber(processed) or 0)
        RecordPhase(job, "supportEraEvidence", started)
        if not done then return false end
        candidateWork.eraEvidence = evidence
    end
    if job.styleEngine then
        local started = NowMilliseconds()
        local eligible = job.styleEngine.GetSourceEligibilityCached and job.styleEngine.GetSourceEligibilityCached(candidateWork.source, job.styleMode, job.styleContext, candidateWork.eraEvidence, candidateWork.prechecked)
            or job.styleEngine.GetSourceEligibility(candidateWork.source, job.styleMode, job.styleContext, candidateWork.eraEvidence, candidateWork.prechecked)
        RecordPhase(job, "supportEligibility", started)
        if not eligible then return true end
    end
    local started = NowMilliseconds()
    local candidate = P.BuildSupportCandidate(candidateWork.source, work.definition, job, job.supportWork.profile, work.currentSourceID)
    RecordPhase(job, "supportCandidateScoring", started)
    if candidate then
        if work.excludeVisualID and P.SupportVisualIdentity(candidate.source) == work.excludeVisualID then work.fallback = candidate
        else P.AddSupportPoolCandidate(work, candidate) end
    end
    return true
end

local function StepPool(job, work)
    if work.done then return true end
    if work.sourceIndex > #work.sources then
        P.FinalizeSupportPool(work)
        if #work.pool == 0 and work.fallback then work.fallback.forceFallback = true work.pool = { work.fallback } end
        work.done = true
        return true
    end
    local complete = ContinueCandidate(job, work)
    if complete then work.candidateWork = nil work.sourceIndex = work.sourceIndex + 1 job.candidatesProcessed = job.candidatesProcessed + 1 end
    return false
end

local function LockedDecision(job, profile, budget, slotKey)
    local sourceID = job.draft.selections[slotKey]
    local source = sourceID and P.GetSourceByID(slotKey, sourceID)
    if not source then return nil, budget end
    local candidate = P.BuildSupportCandidate(source, P.slotByKey[slotKey], job, profile, nil, true)
    if not candidate then return nil, budget end
    local node = { selected = {}, budget = budget }
    local decision = P.ScoreSupportCandidate(candidate, node, job, profile, {}, true)
    decision.locked, decision.allowed, decision.fallback = true, true, false
    decision.budgetEvaluation.allowed = true
    return decision, P.CommitSupportBudget(budget, decision.budgetEvaluation, true)
end

local function BuildLocked(job, work)
    local selections, decisions, unlocked = {}, {}, {}
    local budget = P.CreateSupportBudget(job.draft, work.activeSlots)
    for _, slotKey in ipairs(work.activeSlots) do
        if job.draft.locks[slotKey] then
            local decision
            decision, budget = LockedDecision(job, work.profile, budget, slotKey)
            if decision then selections[slotKey] = decision.candidate decisions[#decisions + 1] = decision end
        else unlocked[#unlocked + 1] = slotKey end
    end
    work.lockedSelections, work.lockedDecisions, work.unlockedSlots, work.budget = selections, decisions, unlocked, budget
end

local function ApplySelection(job, work, selected, chosenRank, shortlistSize)
    if not selected then return false, "No complete contextual support configuration was available." end
    local decisionsBySlot = {}
    for _, decision in ipairs(selected.decisions or {}) do decisionsBySlot[decision.slotKey] = decision end
    for _, slotKey in ipairs(work.activeSlots) do
        if not job.draft.locks[slotKey] then
            local candidate = selected.selected[slotKey]
            if candidate then P.SetSelectedSource(job.draft, slotKey, candidate.source) job.selectedArmor = job.selectedArmor + 1
            elseif not job.reroll then P.SetSelectedSource(job.draft, slotKey, nil) end
        elseif job.draft.selections[slotKey] then job.selectedArmor = job.selectedArmor + 1 end
    end
    if job.styleEngine and job.styleEngine.AddSourceToGenerationContext then
        for _, slotKey in ipairs(work.activeSlots) do
            if not job.draft.hidden[slotKey] then
                local sourceID = job.draft.selections[slotKey]
                if sourceID then job.styleEngine.AddSourceToGenerationContext(job.styleContext, P.GetSourceByID(slotKey, sourceID)) end
            end
        end
    end
    local profile = work.profile
    local phaseD = selected.phaseD or (work.phaseDWork and { status = work.phaseDWork.finalStatus, repairPasses = #(work.phaseDWork.repairs or {}), repairs = work.phaseDWork.repairs, initialValidation = work.phaseDWork.initialValidation, finalValidation = work.phaseDWork.finalValidation, alternateSkeleton = work.phaseDWork.options and work.phaseDWork.options.alternate == true })
    local cohesionTotal, count, outliers, accents, fallbacks = 0, 0, 0, 0, 0
    for _, decision in ipairs(selected.decisions or {}) do
        cohesionTotal, count = cohesionTotal + ((decision.profileFit + decision.neighborCohesion) * 0.5), count + 1
        if decision.outlierState == "OUTLIER" then outliers = outliers + 1 elseif decision.outlierState == "ACCENT" or decision.outlierState == "LOUD_ACCENT" then accents = accents + 1 end
        if decision.fallback then fallbacks = fallbacks + 1 end
    end
    local finalValidation = phaseD and phaseD.finalValidation
    if finalValidation then outliers = tonumber(finalValidation.repairableOutliers) or 0 end
    job.supportStats = {
        profile = profile, startingBudget = selected.budget.starting, lockedCommitment = selected.budget.lockedCommitment,
        generatedSpend = selected.budget.generatedSpend, borrowed = selected.budget.borrowed, overrun = selected.budget.overrun,
        remainingBudget = selected.budget.remaining, configurationScore = selected.totalScore,
        wholeOutfitCohesion = count > 0 and cohesionTotal / count or profile.meanAnchorCohesion,
        controlledAccents = accents, outliers = outliers, fallbackSlots = fallbacks,
        chosenRank = chosenRank, shortlistSize = shortlistSize, poolSizes = work.poolSizes,
        expansions = work.beamWork.expansions, retained = work.beamWork.retained,
        deduplicated = (work.poolDeduplicated or 0) + (work.beamWork.deduplicated or 0), budgetRejections = work.beamWork.rejections,
        emptySlots = work.beamWork.emptySlots or 0, decisions = selected.decisions, activeSlots = work.activeSlots,
        finalValidationStatus = phaseD and phaseD.status or "CLEAN", repairPasses = phaseD and phaseD.repairPasses or 0,
        repairs = phaseD and phaseD.repairs or {}, phaseDInitial = phaseD and phaseD.initialValidation or nil,
        phaseDFinal = finalValidation, alternateSkeleton = phaseD and phaseD.alternateSkeleton == true or false,
    }
    job.supportDiagnostics = job.supportStats
    P.lastSupportDiagnostics = job.supportStats
    return true
end

function P.CreateSupportGenerationWork(job)
    return { stage = "PROFILE", activeSlots = ActiveSupportSlots(job.draft), poolIndex = 1, pools = {}, poolSizes = {} }
end

function P.StepSupportGenerationJob(job, stepStarted)
    local work = job.supportWork
    if not work then work = P.CreateSupportGenerationWork(job) job.supportWork = work end
    local operations = 0
    while operations < P.GENERATION_OPERATION_SAFETY_CAP do
        if P.ShouldYieldGenerationWorker and P.ShouldYieldGenerationWorker(job, 0.5) then return "RUNNING" end
        if work.stage == "PROFILE" then
            local started = NowMilliseconds()
            work.activeAnchorMask = P.BuildActiveAnchorMask(job.draft)
            work.profile = P.BuildContextualSupportProfile(job.draft, {
                activeAnchorMask = work.activeAnchorMask,
                profileSourceReportID = job.diagnosticIdentity and job.diagnosticIdentity.reportID,
            })
            job.activeAnchorMask = work.activeAnchorMask
            RecordPhase(job, "supportProfile", started)
            work.stage = "LOCKED"
            return "RUNNING"
        elseif work.stage == "LOCKED" then
            if P.CanStartGenerationPhase and not P.CanStartGenerationPhase(job, 1.0) then return "RUNNING" end
            local started = NowMilliseconds()
            BuildLocked(job, work)
            RecordPhase(job, "supportLockedCommitments", started)
            work.stage = "POOLS"
            return "RUNNING"
        elseif work.stage == "POOLS" then
            if work.poolIndex > #work.unlockedSlots then
                work.beamWork = P.CreateSupportBeamWork(job, work.profile, work.budget, work.unlockedSlots, work.pools, work.lockedSelections, work.lockedDecisions)
                work.stage = "BEAM"
                return "RUNNING"
            else
                local slotKey = work.unlockedSlots[work.poolIndex]
                if not work.poolWork then work.poolWork = CreatePoolWork(job, slotKey) end
                if StepPool(job, work.poolWork) then
                    work.pools[slotKey] = work.poolWork.pool
                    work.poolSizes[slotKey] = #work.poolWork.pool
                    work.poolDeduplicated = (work.poolDeduplicated or 0) + (work.poolWork.deduplicated or 0)
                    work.poolIndex, work.poolWork = work.poolIndex + 1, nil
                end
            end
        elseif work.stage == "BEAM" then
            if P.CanStartGenerationPhase and not P.CanStartGenerationPhase(job, 1.0) then return "RUNNING" end
            local started = NowMilliseconds()
            local done = P.StepSupportBeamWork(work.beamWork)
            RecordPhase(job, "supportBeamExpansion", started)
            if done then work.stage = "SELECT" return "RUNNING" end
        elseif work.stage == "SELECT" then
            if P.CanStartGenerationPhase and not P.CanStartGenerationPhase(job, 1.5) then return "RUNNING" end
            local started = NowMilliseconds()
            work.selected, work.chosenRank, work.shortlistSize = P.ChooseSupportConfiguration(work.beamWork)
            RecordPhase(job, "supportSelection", started)
            if not work.selected then return "FALLBACK", "No complete contextual support configuration was available." end
            if not P.CreateSupportFinalizationWork or not P.StepSupportFinalization then
                local ok, reason = ApplySelection(job, work, work.selected, work.chosenRank, work.shortlistSize)
                if not ok then return "FAILED", reason end
                return "READY"
            end
            work.phaseDWork = P.CreateSupportFinalizationWork(job, work, work.selected, work.chosenRank, work.shortlistSize, {
                noRepair = job.phaseDAlternateNoRepair == true,
                alternate = job.phaseDAlternateNoRepair == true,
            })
            work.stage = "FINAL"
            return "RUNNING"
        elseif work.stage == "FINAL" then
            local status, reason = P.StepSupportFinalization(job, work, work.phaseDWork)
            if status == "READY" then
                local ok, applyReason = ApplySelection(job, work, work.phaseDWork.finalConfiguration, work.chosenRank, work.shortlistSize)
                if not ok then return "FAILED", applyReason end
                return "READY"
            elseif status == "ALTERNATE" then
                return "ALTERNATE", "Two support repair passes were exhausted."
            elseif status == "FAILED" then
                return "FAILED", reason
            end
            return "RUNNING"
        end
        operations = operations + 1
        if P.ShouldYieldGenerationWorker and P.ShouldYieldGenerationWorker(job, 0.5) then return "RUNNING" end
        if NowMilliseconds() - stepStarted >= P.GENERATION_TIME_BUDGET_MS then return "RUNNING" end
    end
    return "RUNNING"
end
