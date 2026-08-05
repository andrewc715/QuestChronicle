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

local function CopyArray(source)
    local result = {}
    for index, value in ipairs(source or {}) do result[index] = value end
    return result
end

local function RemainingSlots(activeSlots, index, state)
    local result = {}
    for nextIndex = index + 1, #(activeSlots or {}) do
        local slotKey = activeSlots[nextIndex]
        if not (state.locks and state.locks[slotKey]) then result[#result + 1] = slotKey end
    end
    return result
end

local function ExtendNode(node, decision)
    node.selected[decision.slotKey] = decision.candidate
    node.decisions[#node.decisions + 1] = decision
    node.budget = P.CommitSupportBudget(node.budget, decision.budgetEvaluation, decision.locked)
    node.totalScore = (node.totalScore or 0) + (decision.score or 0)
    node.mismatchSpent = (node.mismatchSpent or 0) + (decision.mismatchSpent or 0)
    node.fallbackCount = (node.fallbackCount or 0) + (decision.fallback and 1 or 0)
end

function P.RebuildSupportConfiguration(job, work, candidateMap)
    local state = job.draft
    local node = {
        selected = {}, decisions = {}, budget = P.CreateSupportBudget(state, work.activeSlots),
        totalScore = 0, mismatchSpent = 0, fallbackCount = 0, emptySlots = 0,
    }
    for index, slotKey in ipairs(work.activeSlots or {}) do
        local locked = state.locks and state.locks[slotKey] == true
        local candidate = locked and work.lockedSelections and work.lockedSelections[slotKey] or candidateMap[slotKey]
        if not candidate then return nil, "No legal candidate remained for " .. tostring(slotKey) .. "." end
        local decision = P.ScoreSupportCandidate(candidate, node, job, work.profile, RemainingSlots(work.activeSlots, index, state), locked)
        if locked then
            decision.locked, decision.allowed, decision.fallback = true, true, false
            decision.budgetEvaluation.allowed = true
        elseif not decision.allowed then
            return nil, "The replacement violated the Phase C support budget."
        end
        ExtendNode(node, decision)
    end
    return node
end

local function SourceName(source)
    return source and (source.styleName or source.name or source.itemName or tostring(source.sourceID)) or "None"
end

local function BuildRepairRecord(work, pass, target, oldCandidate, newCandidate, before, after)
    return {
        pass = pass, slotKey = target.slotKey,
        previousName = SourceName(oldCandidate and oldCandidate.source),
        previousVisualID = oldCandidate and (oldCandidate.source.visualID or oldCandidate.source.sourceID),
        replacementName = SourceName(newCandidate and newCandidate.source),
        replacementVisualID = newCandidate and (newCandidate.source.visualID or newCandidate.source.sourceID),
        trigger = target.explicitOutlier and "final outlier"
            or target.zeroEchoLoudAccent and "zero-echo loud accent"
            or target.severe and "outlier severity"
            or (before.paletteOverflow or 0) > 0 and "palette-family overflow"
            or "final mismatch budget",
        mismatchBefore = before.mismatchUsed, mismatchAfter = after.mismatchUsed,
        severityBefore = target.outlierSeverity,
        severityAfter = after.analysisBySlot[target.slotKey] and after.analysisBySlot[target.slotKey].outlierSeverity or 0,
        paletteBefore = before.paletteFamilies, paletteAfter = after.paletteFamilies,
        zeroEchoBefore = before.repairableZeroEcho, zeroEchoAfter = after.repairableZeroEcho,
        cohesionBefore = before.wholeOutfitCohesion, cohesionAfter = after.wholeOutfitCohesion,
        scoreDelta = (tonumber(work.bestConfiguration and work.bestConfiguration.totalScore) or 0)
            - (tonumber(work.currentConfiguration and work.currentConfiguration.totalScore) or 0),
    }
end

local function FinalStatus(work, validation)
    if work.options and work.options.alternate then return "ALTERNATE_SKELETON" end
    if validation.status == "LOCKED_OVERRIDE" then return "LOCKED_OVERRIDE" end
    if #(work.repairs or {}) > 0 then return "REPAIRED" end
    return "CLEAN"
end

local function FinishReady(work)
    work.finalConfiguration = work.currentConfiguration
    work.finalValidation = work.currentValidation
    work.finalStatus = FinalStatus(work, work.currentValidation)
    P.AttachSupportFinalAnalysis(work.finalConfiguration, work.finalValidation, work.repairs)
    work.finalConfiguration.phaseD = {
        status = work.finalStatus,
        repairPasses = #(work.repairs or {}), repairs = CopyArray(work.repairs),
        initialValidation = work.initialValidation, finalValidation = work.finalValidation,
        alternateSkeleton = work.options and work.options.alternate == true or false,
    }
    return "READY"
end

function P.CreateSupportFinalizationWork(job, supportWork, selected, rank, shortlist, options)
    return {
        stage = "VALIDATE", options = options or {},
        currentConfiguration = selected, chosenRank = rank, shortlistSize = shortlist,
        currentValidation = nil, initialValidation = nil,
        repairPass = 0, repairs = {}, exhaustedSlots = {}, rejectedVisuals = {},
        candidateIndex = 1, bestConfiguration = nil, bestValidation = nil,
    }
end

local function StartTarget(work)
    local target = P.SelectSupportRepairTarget(work.currentValidation, work.exhaustedSlots)
    if not target then return false end
    work.target = target
    work.pool = work.supportWork.pools[target.slotKey] or {}
    work.candidateIndex = 1
    work.bestConfiguration, work.bestValidation = nil, nil
    return true
end

local function EvaluateCandidate(job, work)
    local candidate = work.pool[work.candidateIndex]
    if not candidate then return true end
    work.candidateIndex = work.candidateIndex + 1
    local current = work.currentConfiguration.selected[work.target.slotKey]
    local currentIdentity = P.SupportVisualIdentity(current and current.source)
    local candidateIdentity = P.SupportVisualIdentity(candidate.source)
    local rejected = work.rejectedVisuals[work.target.slotKey] or {}
    if candidateIdentity == currentIdentity or rejected[candidateIdentity] then return false end
    local map = P.CopySupportCandidateMap(work.currentConfiguration.selected)
    map[work.target.slotKey] = candidate
    local configuration = P.RebuildSupportConfiguration(job, work.supportWork, map)
    if not configuration then return false end
    local validation = P.ValidateSupportConfiguration(job, work.supportWork, configuration)
    if P.IsSupportValidationImprovement(validation, work.currentValidation)
        and (not work.bestValidation or P.CompareSupportValidation(validation, work.bestValidation) < 0)
    then
        work.bestConfiguration, work.bestValidation = configuration, validation
    end
    return false
end

function P.StepSupportFinalization(job, supportWork, work)
    work.supportWork = supportWork
    if work.stage == "VALIDATE" then
        local started = NowMilliseconds()
        work.currentValidation = P.ValidateSupportConfiguration(job, supportWork, work.currentConfiguration)
        if not work.initialValidation then work.initialValidation = work.currentValidation end
        RecordPhase(job, "supportFinalValidation", started)
        if not work.currentValidation.internalValid then
            work.failureReason = work.currentValidation.failureReason or "Final support validation failed."
            return "FAILED", work.failureReason
        end
        if work.currentValidation.status == "CLEAN" or work.currentValidation.status == "LOCKED_OVERRIDE" then
            return FinishReady(work)
        end
        if work.options.noRepair then
            work.failureReason = "The alternate anchor skeleton still failed final support validation."
            return "FAILED", work.failureReason
        end
        if work.repairPass >= P.SUPPORT_FINAL_REPAIR_LIMIT then return "ALTERNATE" end
        work.stage = "TARGET"
        return "RUNNING"
    elseif work.stage == "TARGET" then
        local started = NowMilliseconds()
        local found = StartTarget(work)
        RecordPhase(job, "supportRepairTargeting", started)
        if not found then return "ALTERNATE" end
        work.stage = "CANDIDATES"
        return "RUNNING"
    elseif work.stage == "CANDIDATES" then
        local started = NowMilliseconds()
        local done = EvaluateCandidate(job, work)
        RecordPhase(job, "supportRepairCandidateEvaluation", started)
        if done then work.stage = "APPLY" end
        return "RUNNING"
    elseif work.stage == "APPLY" then
        local phaseKey = work.repairPass == 0 and "supportRepairPass1" or "supportRepairPass2"
        local started = NowMilliseconds()
        work.repairPass = work.repairPass + 1
        local oldCandidate = work.currentConfiguration.selected[work.target.slotKey]
        work.exhaustedSlots[work.target.slotKey] = true
        if work.bestConfiguration and work.bestValidation then
            local oldIdentity = P.SupportVisualIdentity(oldCandidate and oldCandidate.source)
            work.rejectedVisuals[work.target.slotKey] = work.rejectedVisuals[work.target.slotKey] or {}
            work.rejectedVisuals[work.target.slotKey][oldIdentity] = true
            local repair = BuildRepairRecord(work, work.repairPass, work.target, oldCandidate,
                work.bestConfiguration.selected[work.target.slotKey], work.currentValidation, work.bestValidation)
            work.repairs[#work.repairs + 1] = repair
            work.currentConfiguration, work.currentValidation = work.bestConfiguration, work.bestValidation
        end
        RecordPhase(job, phaseKey, started)
        work.stage = "REVALIDATE"
        return "RUNNING"
    elseif work.stage == "REVALIDATE" then
        local started = NowMilliseconds()
        work.currentValidation = P.ValidateSupportConfiguration(job, supportWork, work.currentConfiguration)
        RecordPhase(job, "supportRepairRevalidation", started)
        if work.currentValidation.status == "CLEAN" or work.currentValidation.status == "LOCKED_OVERRIDE" then
            return FinishReady(work)
        end
        if work.repairPass >= P.SUPPORT_FINAL_REPAIR_LIMIT then return "ALTERNATE" end
        work.stage = "TARGET"
        return "RUNNING"
    end
    return "FAILED", "The support repair worker entered an unknown stage."
end
