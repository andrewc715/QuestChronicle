local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function NowMilliseconds()
    return P.GenerationNowMilliseconds and P.GenerationNowMilliseconds() or 0
end

local function Record(job, phaseKey, startedAt)
    local elapsed = NowMilliseconds() - startedAt
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, phaseKey, elapsed) end
    return elapsed
end

local function Notify(eventName, ...)
    if QC.Notify then QC.Notify(eventName, ...) end
end

local function Schedule(token)
    if not C_Timer or type(C_Timer.After) ~= "function" then return false end
    C_Timer.After(0, function()
        if P.supportRerollJob and P.supportRerollJob.token == token then P.StepSupportRerollJob(token) end
    end)
    return true
end

local Finish

local function CountSelectedArmor(state)
    local count = 0
    for _, definition in ipairs(Wardrobe.slotDefinitions or {}) do
        if not definition.weaponRole and state and state.selections and state.selections[definition.key]
            and not (state.hidden and state.hidden[definition.key]) then count = count + 1 end
    end
    return count
end

local function ManifestValid(job)
    local valid = P.ValidateSupportRerollManifest(job and job.manifest, job and job.liveState)
    if not valid then
        Finish(job, false, "The support-slot reroll was cancelled because the workbench changed while Quest Chronicle was preparing it.", "CANCELLED")
        return false
    end
    return true
end

local function MaterializeIdentity(job)
    local started = NowMilliseconds()
    local identity = QC.Diagnostics and QC.Diagnostics.BeginGenerationAttempt
        and QC.Diagnostics.BeginGenerationAttempt("REROLL_SLOT", job.actionSlotKey) or nil
    local parentReport, anchorReport = P.GetSupportRerollParentReports(identity)
    job.diagnosticIdentity = identity
    job.anchorSourceReportID = identity and identity.anchorSourceReportID
    job.parentReport = parentReport
    job.anchorReport = anchorReport
    job.pinnedReportIDs = {}
    if QC.Diagnostics and QC.Diagnostics.PinReport then
        for _, report in ipairs({ parentReport, anchorReport }) do
            local reportID = report and report.id
            if reportID and not job.pinnedReportIDs[reportID] then
                QC.Diagnostics.PinReport(reportID)
                job.pinnedReportIDs[reportID] = true
            end
        end
    end
    Record(job, "rerollDiagnosticIdentity", started)
end

local function MaterializeAnchorSummary(job)
    local started = NowMilliseconds()
    local anchorReport, parentReport = job.anchorReport, job.parentReport
    job.inheritedAnchorSnapshot = anchorReport and anchorReport.skeleton or nil
    job.inheritedBeamSnapshot = anchorReport and anchorReport.beam or nil
    job.previousTargetDecision = parentReport and parentReport.support
        and P.GetSupportDecisionBySlot(parentReport.support, job.actionSlotKey) or nil
    local elapsed = Record(job, "rerollAnchorSummary", started)
    if P.RecordGenerationPhase then P.RecordGenerationPhase(job, "rerollAnchorSnapshotReuse", elapsed) end
end

local function MaterializeState(job)
    local started = NowMilliseconds()
    local draft = P.CopySupportRerollState(job.liveState)
    draft.styleMode = job.styleMode
    job.draft = draft
    job.startSignature = P.SupportRerollStateSignature(job.liveState)
    job.inheritedSupportProfileSnapshot = job.parentReport and job.parentReport.support
        and job.parentReport.support.profile or draft.contextualSupportProfile
    Record(job, "rerollStateMaterialization", started)
end

local function InitializeStyleContext(job)
    local started = NowMilliseconds()
    local style = QC.ZoneStyle
    job.styleEngine = style
    local baseContext = style and style.GetCurrentContext and style.GetCurrentContext() or nil
    job.styleContext = style and style.CreateGenerationContext and style.CreateGenerationContext(baseContext) or baseContext
    job.styleSeedIndex = 1
    Record(job, "rerollStyleContextInit", started)
end

local function SeedStyleContext(job)
    local definition = Wardrobe.slotDefinitions and Wardrobe.slotDefinitions[job.styleSeedIndex]
    if not definition then return true end
    local started = NowMilliseconds()
    local slotKey = definition.key
    local shouldSeed = slotKey ~= job.actionSlotKey
        and job.draft.selections[slotKey] ~= nil
        and job.draft.hidden[slotKey] ~= true
    if shouldSeed and job.styleEngine and job.styleEngine.AddSourceToGenerationContext then
        job.styleEngine.AddSourceToGenerationContext(job.styleContext, P.GetSourceByID(slotKey, job.draft.selections[slotKey]))
    end
    job.styleSeedIndex = job.styleSeedIndex + 1
    Record(job, "rerollStyleContextSeed", started)
    return job.styleSeedIndex > #(Wardrobe.slotDefinitions or {})
end

local function PrepareStyleContext(job)
    local started = NowMilliseconds()
    if job.styleEngine and job.styleEngine.PrepareGenerationEligibilityContext then
        job.styleEngine.PrepareGenerationEligibilityContext(job.styleContext)
    end
    Record(job, "rerollEligibilityContext", started)
end

local function MaterializeSupportSummary(job)
    local started = NowMilliseconds()
    job.supportRerollActiveSlots = P.GetActiveSupportSlots(job.draft)
    job.selectedArmor = CountSelectedArmor(job.draft)
    Record(job, "rerollSupportSummaryFoundation", started)
end

local function MaterializeCacheSummary(job)
    local started = NowMilliseconds()
    job.cacheCountersStarted = P.GetGenerationCacheCounterSnapshot and P.GetGenerationCacheCounterSnapshot() or nil
    Record(job, "rerollCacheSummaryFoundation", started)
end

local function ReleasePinnedReports(job)
    if not job or not job.pinnedReportIDs or not QC.Diagnostics or not QC.Diagnostics.ReleaseReport then return end
    for reportID in pairs(job.pinnedReportIDs) do QC.Diagnostics.ReleaseReport(reportID) end
    job.pinnedReportIDs = nil
end

Finish = function(job, success, message, resultOverride)
    if not job or P.supportRerollJob ~= job then return end
    local finishedAt = NowMilliseconds()
    if job.currentStepStartedMs then job.maxStepMs = math.max(job.maxStepMs or 0, finishedAt - job.currentStepStartedMs) end
    local performance = P.BuildGenerationPerformance and P.BuildGenerationPerformance(job, finishedAt) or {
        elapsedMs = math.max(0, finishedAt - (job.startedAtMs or finishedAt)),
        steps = job.steps or 0, maxStepMs = job.maxStepMs or 0, phaseStats = job.phaseStats or {},
    }
    P.lastGenerationPerformance = performance
    P.supportRerollJob = nil
    job.resultOverride = resultOverride
    Notify("WARDROBE_GENERATION_COMPLETE", success == true, message, performance)
    if QC.Diagnostics and QC.Diagnostics.QueueGenerationAttempt then QC.Diagnostics.QueueGenerationAttempt(job, success == true, message, performance) end
    ReleasePinnedReports(job)
    return performance
end

local function BuildFixedDecision(job, slotKey)
    local sourceID = job.draft.selections[slotKey]
    local source = sourceID and P.GetSourceByID(slotKey, sourceID)
    if not source then return nil end
    local candidate = P.BuildSupportCandidate(source, P.slotByKey[slotKey], job, job.supportRerollProfile, nil, true)
    if not candidate then return nil end
    local decision = P.ScoreSupportCandidate(candidate, job.supportRerollRoot, job, job.supportRerollProfile, {}, true)
    decision.allowed = true
    decision.fixed = true
    decision.contextFixed = job.draft.locks[slotKey] ~= true
    decision.locked = job.draft.locks[slotKey] == true
    decision.budgetEvaluation.allowed = true
    return decision
end

local function CommitFixedDecision(job, decision)
    local node = job.supportRerollRoot
    node.selected[decision.slotKey] = decision.candidate
    node.decisions[#node.decisions + 1] = decision
    node.budget = P.CommitSupportBudget(node.budget, decision.budgetEvaluation, decision.locked)
    node.totalScore = (node.totalScore or 0) + (decision.score or 0)
end

local function ScorePoolDecision(job, candidate)
    local started = NowMilliseconds()
    local decision = P.ScoreSupportCandidate(candidate, job.supportRerollRoot, job, job.supportRerollProfile, {}, false)
    Record(job, "rerollCandidateScoring", started)
    return decision
end

local function CurrentDecision(job)
    local candidate = job.supportRerollPool and job.supportRerollPool.currentCandidate
    if not candidate and job.supportRerollPool and job.supportRerollPool.currentSource then
        candidate = P.BuildSupportCandidate(job.supportRerollPool.currentSource, P.slotByKey[job.actionSlotKey], job, job.supportRerollProfile, nil, true)
    end
    if not candidate then return nil end
    local decision = ScorePoolDecision(job, candidate)
    decision.fallback = true
    decision.noAlternative = true
    decision.allowed = true
    decision.budgetEvaluation.allowed = true
    return decision
end

local function BuildStats(job, chosen, chosenRank, shortlistSize)
    local root = job.supportRerollRoot
    local finalBudget = chosen and P.CommitSupportBudget(root.budget, chosen.budgetEvaluation, false) or root.budget
    local decisions = {}
    for _, decision in ipairs(root.decisions or {}) do decisions[#decisions + 1] = decision end
    if chosen then
        chosen.targetRerolled = not chosen.noAlternative
        decisions[#decisions + 1] = chosen
    end
    local total, scoreTotal, count, accents, outliers, fallbacks, fixedContextCount = 0, 0, 0, 0, 0, 0, 0
    for _, decision in ipairs(decisions) do
        total = total + ((decision.profileFit or 0) + (decision.neighborCohesion or 0)) * 0.5
        scoreTotal = scoreTotal + (decision.score or 0)
        count = count + 1
        if decision.outlierState == "OUTLIER" then outliers = outliers + 1
        elseif decision.outlierState == "ACCENT" or decision.outlierState == "LOUD_ACCENT" then accents = accents + 1 end
        if decision.fallback then fallbacks = fallbacks + 1 end
        if decision.contextFixed then fixedContextCount = fixedContextCount + 1 end
    end
    local previousTarget = job.previousTargetDecision
    local previousTargetSource
    if not previousTarget then
        local sourceID = job.draft.selections and job.draft.selections[job.actionSlotKey]
        previousTargetSource = sourceID and P.GetSourceByID(job.actionSlotKey, sourceID) or nil
        local candidate = previousTargetSource and P.BuildSupportCandidate(previousTargetSource, P.slotByKey[job.actionSlotKey], job, job.supportRerollProfile, nil, true) or nil
        if candidate then
            local evaluation = P.EvaluateSupportBudget(root.budget, job.actionSlotKey, candidate.mismatchCost, {}, false)
            previousTarget = {
                name = previousTargetSource.styleName or previousTargetSource.name or previousTargetSource.itemName,
                sourceID = previousTargetSource.sourceID, visualID = previousTargetSource.visualID,
                mismatchSpent = evaluation.cost,
            }
        end
    end
    local parentSpend = job.parentReport and job.parentReport.support
        and ((job.parentReport.support.lockedCommitment or 0) + (job.parentReport.support.generatedSpend or 0))
    local removedCost = previousTarget and previousTarget.mismatchSpent or 0
    local fixedSpend = (root.budget.lockedCommitment or 0) + (root.budget.generatedSpend or 0)
    local previousSpend = parentSpend or (fixedSpend + removedCost)
    local replacementCost = chosen and chosen.mismatchSpent or 0
    local actualAfter = finalBudget.lockedCommitment + finalBudget.generatedSpend
    local expectedAfter = previousSpend - removedCost + replacementCost
    local adjustment = actualAfter - expectedAfter
    if math.abs(adjustment) < 0.0005 then adjustment = 0 end
    local repaired = job.profileResolution and job.profileResolution.repaired == true
    local reconciled = repaired or adjustment == 0
    return {
        profile = job.supportRerollProfile,
        profileID = job.supportRerollProfile and job.supportRerollProfile.profileID,
        profileSourceReportID = job.supportRerollProfile and job.supportRerollProfile.profileSourceReportID,
        profileReused = job.profileResolution and job.profileResolution.reused == true,
        profileRepaired = repaired,
        profileMigrated = job.profileResolution and job.profileResolution.migrated == true,
        profileRepairReason = job.profileResolution and job.profileResolution.repairReason,
        profileBasisConsistent = true,
        startingBudget = finalBudget.starting, lockedCommitment = finalBudget.lockedCommitment,
        generatedSpend = finalBudget.generatedSpend, borrowed = finalBudget.borrowed,
        overrun = finalBudget.overrun, remainingBudget = finalBudget.remaining,
        configurationScore = scoreTotal,
        wholeOutfitCohesion = count > 0 and total / count or job.supportRerollProfile.meanAnchorCohesion,
        controlledAccents = accents, outliers = outliers, fallbackSlots = fallbacks,
        chosenRank = chosenRank or 0, shortlistSize = shortlistSize or 0,
        poolSizes = { [job.actionSlotKey] = #(job.supportRerollPool.pool or {}) },
        expansions = { [job.actionSlotKey] = job.supportRerollScoreIndex - 1 },
        retained = { [job.actionSlotKey] = shortlistSize or 0 },
        deduplicated = job.supportRerollPool.deduplicated or 0,
        budgetRejections = job.supportRerollBudgetRejections or 0,
        emptySlots = chosen and 0 or 1, decisions = decisions,
        activeSlots = job.supportRerollActiveSlots,
        targetSlotKey = job.actionSlotKey,
        previousTargetName = previousTarget and previousTarget.name,
        previousTargetSourceID = previousTarget and previousTarget.sourceID,
        previousTargetVisualID = previousTarget and previousTarget.visualID,
        previousTargetCost = removedCost,
        replacementCost = replacementCost,
        budgetBefore = previousSpend,
        fixedContextCost = (finalBudget.lockedCommitment + finalBudget.generatedSpend) - replacementCost,
        profileAdjustment = adjustment,
        expectedBudgetAfter = expectedAfter,
        budgetAfter = actualAfter,
        budgetReconciled = reconciled,
        fixedContextCount = fixedContextCount,
        noAlternative = not chosen or chosen.noAlternative == true,
    }
end

local function Commit(job)
    if not P.ValidateSupportRerollManifest(job.manifest, job.liveState)
        or P.SupportRerollStateSignature(job.liveState) ~= job.startSignature then
        return Finish(job, false, "The support-slot reroll was cancelled because the workbench changed while Quest Chronicle was preparing it.", "CANCELLED")
    end
    local chosen = job.supportRerollChosen
    local stats = BuildStats(job, chosen, job.supportRerollChosenRank, job.supportRerollShortlistSize)
    job.supportDiagnostics, job.supportStats = stats, stats
    P.lastSupportDiagnostics = stats
    if not stats.budgetReconciled then
        return Finish(job, false, "The contextual mismatch ledger could not be reconciled on one profile basis; the preview was left unchanged.", "FAILED")
    end
    if not chosen or chosen.noAlternative then
        job.liveState.activeAnchorMask = P.CopySupportProfileValue(job.supportRerollProfile.activeAnchorMask)
        job.liveState.contextualSupportProfile = P.ExportContextualSupportProfile(job.supportRerollProfile)
        return Finish(job, false, "No legal contextual alternative was available for " .. tostring(job.slotLabel or job.actionSlotKey) .. ".", "NO_ALTERNATIVE")
    end
    local started = NowMilliseconds()
    P.SetSelectedSource(job.draft, job.actionSlotKey, chosen.source)
    local generatedName = P.RefreshGeneratedOutfitName(job.draft, job.styleEngine, job.styleMode, job.styleContext)
    job.liveState.selections[job.actionSlotKey] = job.draft.selections[job.actionSlotKey]
    job.liveState.selectionVisuals[job.actionSlotKey] = job.draft.selectionVisuals[job.actionSlotKey]
    job.liveState.activeAnchorMask = P.CopySupportProfileValue(job.supportRerollProfile.activeAnchorMask)
    job.liveState.contextualSupportProfile = P.ExportContextualSupportProfile(job.supportRerollProfile)
    job.liveState.generatedName = generatedName
    job.liveState.selectedConceptID = nil
    if P.TouchPreviewRevision then P.TouchPreviewRevision(job.liveState) end
    Record(job, "rerollStateCommit", started)
    local message = string.format("%s rerolled contextually; the current look is now %s.", tostring(job.slotLabel or job.actionSlotKey), tostring(generatedName or "the updated outfit"))
    return Finish(job, true, message)
end

function P.StepSupportRerollJob(token)
    local job = P.supportRerollJob
    if not job or job.token ~= token then return end
    job.steps = (job.steps or 0) + 1
    local stepStarted = NowMilliseconds()
    local slice = P.BeginSupportRerollSlice()
    job.currentStepStartedMs = stepStarted
    if not ManifestValid(job) then return end
    if job.startSignature and P.SupportRerollStateSignature(job.liveState) ~= job.startSignature then
        Finish(job, false, "The support-slot reroll was cancelled because the workbench changed while Quest Chronicle was preparing it.", "CANCELLED")
        return
    end

    local operations = 0
    local batchPhase, batchOperations, batchLimit = nil, 0, P.GENERATION_OPERATION_SAFETY_CAP
    while operations < P.GENERATION_OPERATION_SAFETY_CAP do
        if P.ShouldYieldSupportRerollSlice(slice, 0.25) then break end
        if batchPhase ~= job.phase then
            batchPhase, batchOperations = job.phase, 0
            batchLimit = P.GetSupportRerollAdaptiveBatchLimit(job, slice)
        elseif batchOperations >= batchLimit then
            break
        end
        local operationStarted = NowMilliseconds()

        if job.phase == "IDENTITY" then
            MaterializeIdentity(job)
            job.phase = "ANCHOR_SUMMARY"
        elseif job.phase == "ANCHOR_SUMMARY" then
            MaterializeAnchorSummary(job)
            job.phase = "STATE"
        elseif job.phase == "STATE" then
            MaterializeState(job)
            job.phase = "CONTEXT_INIT"
        elseif job.phase == "CONTEXT_INIT" then
            InitializeStyleContext(job)
            job.phase = "CONTEXT_SEED"
        elseif job.phase == "CONTEXT_SEED" then
            if SeedStyleContext(job) then job.phase = "CONTEXT_PREPARE" end
        elseif job.phase == "CONTEXT_PREPARE" then
            PrepareStyleContext(job)
            job.phase = "SUMMARY"
        elseif job.phase == "SUMMARY" then
            MaterializeSupportSummary(job)
            job.phase = "CACHE"
        elseif job.phase == "CACHE" then
            MaterializeCacheSummary(job)
            job.phase = "PROFILE"
        elseif job.phase == "PROFILE" then
            local started = NowMilliseconds()
            job.supportRerollProfile, job.profileResolution = P.ResolveContextualSupportProfile(
                job.inheritedSupportProfileSnapshot, job.draft, job.inheritedAnchorSnapshot, job.anchorSourceReportID
            )
            job.activeAnchorMask = job.profileResolution.activeAnchorMask
            Record(job, "rerollProfileReuse", started)
            job.phase = "LEDGER"
        elseif job.phase == "LEDGER" then
            local started = NowMilliseconds()
            local budget = P.CreateSupportBudget(job.draft, job.supportRerollActiveSlots)
            job.supportRerollRoot = { selected = {}, decisions = {}, budget = budget, totalScore = 0 }
            job.supportRerollFixedIndex = 1
            Record(job, "rerollLedgerReconstruction", started)
            job.phase = "FIXED"
        elseif job.phase == "FIXED" then
            if job.supportRerollFixedIndex > #job.supportRerollActiveSlots then
                job.supportRerollPool = P.CreateSupportRerollPoolWork(job)
                job.phase = "POOL"
            else
                local slotKey = job.supportRerollActiveSlots[job.supportRerollFixedIndex]
                if slotKey ~= job.actionSlotKey then
                    local started = NowMilliseconds()
                    local decision = BuildFixedDecision(job, slotKey)
                    if decision then CommitFixedDecision(job, decision) end
                    Record(job, "rerollFixedContextCommitments", started)
                end
                job.supportRerollFixedIndex = job.supportRerollFixedIndex + 1
            end
        elseif job.phase == "POOL" then
            if P.StepSupportRerollPool(job, job.supportRerollPool) then
                job.supportRerollScoreIndex = 1
                job.supportRerollScoreWork = { decisions = {}, overBudget = nil }
                job.phase = "SCORE"
            end
        elseif job.phase == "SCORE" then
            local pool = job.supportRerollPool.pool or {}
            if job.supportRerollScoreIndex > #pool then
                job.phase = "SELECT"
            else
                local decision = ScorePoolDecision(job, pool[job.supportRerollScoreIndex])
                if decision.allowed then
                    job.supportRerollScoreWork.decisions[#job.supportRerollScoreWork.decisions + 1] = decision
                else
                    job.supportRerollBudgetRejections = (job.supportRerollBudgetRejections or 0) + 1
                    local old = job.supportRerollScoreWork.overBudget
                    if not old or decision.mismatchSpent < old.mismatchSpent
                        or (decision.mismatchSpent == old.mismatchSpent and decision.score > old.score)
                    then
                        job.supportRerollScoreWork.overBudget = decision
                    end
                end
                job.supportRerollScoreIndex = job.supportRerollScoreIndex + 1
            end
        elseif job.phase == "SELECT" then
            local started = NowMilliseconds()
            local work = job.supportRerollScoreWork
            work.decisions = work.decisions or {}
            local chosen, rank, shortlist = P.ChooseSupportRerollDecision(work)
            if not chosen and work.overBudget then
                chosen, rank, shortlist = work.overBudget, 1, 1
                chosen.fallback, chosen.allowed, chosen.budgetState = true, true, "OVER"
                chosen.budgetEvaluation.allowed = true
            end
            if not chosen then chosen, rank, shortlist = CurrentDecision(job), 1, 1 end
            job.supportRerollChosen, job.supportRerollChosenRank, job.supportRerollShortlistSize = chosen, rank, shortlist
            Record(job, "rerollShortlistSelection", started)
            job.phase = "COMMIT"
        elseif job.phase == "COMMIT" then
            Commit(job)
            return
        else
            Finish(job, false, "The cooperative support-slot reroll entered an unknown phase.", "FAILED")
            return
        end

        operations = operations + 1
        batchOperations = batchOperations + 1
        local operationElapsed = math.max(0, NowMilliseconds() - operationStarted)
        P.NoteSupportRerollCall(slice, operationElapsed)
        if P.ShouldYieldSupportRerollSlice(slice, 0.25) then break end
    end

    job.maxStepMs = math.max(job.maxStepMs or 0, NowMilliseconds() - stepStarted)
    if not Schedule(token) then
        Finish(job, false, "Quest Chronicle could not schedule the cooperative support-slot reroll. Try /reload.", "FAILED")
    end
end

function P.CancelSupportReroll(reason)
    local job = P.supportRerollJob
    if not job then return false end
    P.supportRerollToken = P.supportRerollToken + 1
    Finish(job, false, reason or "The support-slot reroll was cancelled.", "CANCELLED")
    return true
end
