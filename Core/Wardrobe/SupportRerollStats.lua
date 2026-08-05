local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

function P.BuildSupportRerollStats(job, chosen, chosenRank, shortlistSize)
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
    -- Rebuild the current target on the same live profile and ledger basis used
    -- for every fixed contextual slot. Parent-report totals are ancestry only;
    -- mixing them with a freshly reconstructed ledger can create false failures
    -- after locks, Phase D repairs, report compaction, or other preview changes.
    local sourceID = job.draft.selections and job.draft.selections[job.actionSlotKey]
    local previousTargetSource = sourceID and P.GetSourceByID(job.actionSlotKey, sourceID) or nil
    local previousTarget
    if previousTargetSource then
        local candidate = P.BuildSupportCandidate(
            previousTargetSource, P.slotByKey[job.actionSlotKey], job,
            job.supportRerollProfile, nil, true
        )
        if candidate then
            local evaluation = P.EvaluateSupportBudget(
                root.budget, job.actionSlotKey, candidate.mismatchCost, {}, false
            )
            previousTarget = {
                name = previousTargetSource.styleName or previousTargetSource.name or previousTargetSource.itemName,
                sourceID = previousTargetSource.sourceID,
                visualID = previousTargetSource.visualID,
                mismatchSpent = evaluation.cost,
            }
        end
    end
    local removedCost = previousTarget and previousTarget.mismatchSpent or 0
    local fixedSpend = (root.budget.lockedCommitment or 0) + (root.budget.generatedSpend or 0)
    local previousSpend = fixedSpend + removedCost
    local replacementCost = chosen and chosen.mismatchSpent or 0
    local actualAfter = finalBudget.lockedCommitment + finalBudget.generatedSpend
    local expectedAfter = fixedSpend + replacementCost
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
        finalValidationStatus = job.supportRerollPhaseD and job.supportRerollPhaseD.status or "CLEAN",
        repairPasses = job.supportRerollPhaseD and job.supportRerollPhaseD.repairPasses or 0,
        repairs = job.supportRerollPhaseD and job.supportRerollPhaseD.repairs or {},
        phaseDInitial = job.supportRerollPhaseD and job.supportRerollPhaseD.initialValidation or nil,
        phaseDFinal = job.supportRerollPhaseD and job.supportRerollPhaseD.finalValidation or nil,
        alternateSkeleton = false,
    }
end

