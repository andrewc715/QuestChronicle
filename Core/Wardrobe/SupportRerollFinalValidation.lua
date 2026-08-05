local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function CopyArray(source)
    local result = {}
    for index, value in ipairs(source or {}) do result[index] = value end
    return result
end

local function CopyMap(source)
    local result = {}
    for key, value in pairs(source or {}) do result[key] = value end
    return result
end

function P.BuildSupportRerollPhaseDConfiguration(job, chosen)
    local root = job.supportRerollRoot
    local configuration = {
        selected = CopyMap(root.selected), decisions = CopyArray(root.decisions),
        budget = P.CopySupportBudget(root.budget), totalScore = root.totalScore or 0,
        mismatchSpent = (root.budget.lockedCommitment or 0) + (root.budget.generatedSpend or 0),
        fallbackCount = 0, emptySlots = chosen and 0 or 1,
    }
    for _, decision in ipairs(configuration.decisions) do
        if decision.fallback then configuration.fallbackCount = configuration.fallbackCount + 1 end
    end
    if chosen then
        configuration.selected[job.actionSlotKey] = chosen.candidate
        configuration.decisions[#configuration.decisions + 1] = chosen
        configuration.budget = P.CommitSupportBudget(configuration.budget, chosen.budgetEvaluation, false)
        configuration.totalScore = configuration.totalScore + (chosen.score or 0)
        configuration.mismatchSpent = configuration.mismatchSpent + (chosen.mismatchSpent or 0)
        if chosen.fallback then configuration.fallbackCount = configuration.fallbackCount + 1 end
    end
    return configuration
end

function P.ApplySupportRerollFinalValidation(job, chosen, configuration, validation, repairs, status)
    P.AttachSupportFinalAnalysis(configuration, validation, repairs)
    job.supportRerollChosen = chosen
    job.supportRerollPhaseD = {
        status = status or (validation.status == "LOCKED_OVERRIDE" and "LOCKED_OVERRIDE" or (#(repairs or {}) > 0 and "REPAIRED" or "CLEAN")),
        repairPasses = #(repairs or {}), repairs = repairs or {},
        initialValidation = job.supportRerollInitialValidation or validation,
        finalValidation = validation,
    }
end

function P.BuildSupportRerollRepairRecord(job, original, replacement, before, after)
    local oldSource, newSource = original and original.source, replacement and replacement.source
    return {
        pass = 1, slotKey = job.actionSlotKey,
        previousName = oldSource and (oldSource.styleName or oldSource.name or oldSource.itemName) or "None",
        previousVisualID = oldSource and (oldSource.visualID or oldSource.sourceID),
        replacementName = newSource and (newSource.styleName or newSource.name or newSource.itemName) or "None",
        replacementVisualID = newSource and (newSource.visualID or newSource.sourceID),
        trigger = "target replacement failed final validation",
        mismatchBefore = before.mismatchUsed, mismatchAfter = after.mismatchUsed,
        severityBefore = before.analysisBySlot[job.actionSlotKey] and before.analysisBySlot[job.actionSlotKey].outlierSeverity or 0,
        severityAfter = after.analysisBySlot[job.actionSlotKey] and after.analysisBySlot[job.actionSlotKey].outlierSeverity or 0,
        paletteBefore = before.paletteFamilies, paletteAfter = after.paletteFamilies,
        zeroEchoBefore = before.repairableZeroEcho, zeroEchoAfter = after.repairableZeroEcho,
        cohesionBefore = before.wholeOutfitCohesion, cohesionAfter = after.wholeOutfitCohesion,
        scoreDelta = (replacement and replacement.score or 0) - (original and original.score or 0),
    }
end
