local QC = QuestChronicle
local D = QC.Diagnostics
local DP = D._Private
local Wardrobe = QC.Wardrobe
local WP = Wardrobe and Wardrobe._Private

local function Copy(value)
    return DP.DeepCopy(value, 8) or {}
end

local function SourceSnapshot(decision)
    local source = decision and decision.source
    return {
        slotKey = decision and decision.slotKey,
        slotLabel = decision and decision.slotKey and (Wardrobe.GetSlotDefinition(decision.slotKey) and Wardrobe.GetSlotDefinition(decision.slotKey).label or decision.slotKey),
        name = source and (source.styleName or source.name or source.itemName) or "None",
        sourceID = source and tonumber(source.sourceID) or nil,
        visualID = source and tonumber(source.visualID) or nil,
        itemID = source and tonumber(source.itemID) or nil,
        role = decision and decision.role,
        profileFit = decision and tonumber(decision.profileFit) or 0,
        neighborCohesion = decision and tonumber(decision.neighborCohesion) or 0,
        bridgeBonus = decision and tonumber(decision.bridgeBonus) or 0,
        bridgeTarget = decision and decision.bridgeTarget,
        bridgeBefore = decision and tonumber(decision.bridgeBefore) or nil,
        bridgeAfter = decision and tonumber(decision.bridgeAfter) or nil,
        mismatchSpent = decision and tonumber(decision.mismatchSpent) or 0,
        budgetState = decision and decision.budgetState,
        outlierState = decision and decision.outlierState,
        repeatPenalty = decision and tonumber(decision.repeatPenalty) or 0,
        locked = decision and decision.locked == true or false,
        fixed = decision and decision.fixed == true or false,
        contextFixed = decision and decision.contextFixed == true or false,
        targetRerolled = decision and decision.targetRerolled == true or false,
        noAlternative = decision and decision.noAlternative == true or false,
        bridgeImprovement = decision and decision.bridgeImprovement == true or false,
        fallback = decision and decision.fallback == true or false,
        score = decision and tonumber(decision.score) or 0,
        finalMismatchClass = decision and decision.finalMismatchClass or nil,
        echoSupport = decision and tonumber(decision.echoSupport) or nil,
        outlierSeverity = decision and tonumber(decision.outlierSeverity) or nil,
        repairPass = decision and tonumber(decision.repairPass) or nil,
        repaired = decision and decision.repaired == true or false,
        replacedVisualID = decision and decision.replacedVisualID or nil,
        protectedByLock = decision and decision.protectedByLock == true or false,
    }
end


local function ValidationSnapshot(validation)
    if not validation then return nil end
    return {
        status = validation.status,
        mismatchBudget = tonumber(validation.mismatchBudget) or 0,
        mismatchUsed = tonumber(validation.mismatchUsed) or 0,
        mismatchOverflow = tonumber(validation.mismatchOverflow) or 0,
        severityThreshold = tonumber(validation.severityThreshold) or 0,
        maximumSeverity = tonumber(validation.maximumSeverity) or 0,
        paletteLimit = tonumber(validation.paletteLimit) or 0,
        paletteFamilies = tonumber(validation.paletteFamilies) or 0,
        paletteOverflow = tonumber(validation.paletteOverflow) or 0,
        repairableOutliers = tonumber(validation.repairableOutliers) or 0,
        protectedOutliers = tonumber(validation.protectedOutliers) or 0,
        repairableZeroEcho = tonumber(validation.repairableZeroEcho) or 0,
        protectedZeroEcho = tonumber(validation.protectedZeroEcho) or 0,
        repairableSevere = tonumber(validation.repairableSevere) or 0,
        protectedSevere = tonumber(validation.protectedSevere) or 0,
        protectedLockedViolations = tonumber(validation.protectedLockedViolations) or 0,
        weightedSeverity = tonumber(validation.weightedSeverity) or 0,
        wholeOutfitCohesion = tonumber(validation.wholeOutfitCohesion) or 0,
    }
end

local function RepairSnapshot(repair)
    return {
        pass = tonumber(repair and repair.pass) or 0,
        slotKey = repair and repair.slotKey,
        previousName = repair and repair.previousName,
        previousVisualID = repair and repair.previousVisualID,
        replacementName = repair and repair.replacementName,
        replacementVisualID = repair and repair.replacementVisualID,
        trigger = repair and repair.trigger,
        mismatchBefore = tonumber(repair and repair.mismatchBefore) or 0,
        mismatchAfter = tonumber(repair and repair.mismatchAfter) or 0,
        severityBefore = tonumber(repair and repair.severityBefore) or 0,
        severityAfter = tonumber(repair and repair.severityAfter) or 0,
        paletteBefore = tonumber(repair and repair.paletteBefore) or 0,
        paletteAfter = tonumber(repair and repair.paletteAfter) or 0,
        zeroEchoBefore = tonumber(repair and repair.zeroEchoBefore) or 0,
        zeroEchoAfter = tonumber(repair and repair.zeroEchoAfter) or 0,
        cohesionBefore = tonumber(repair and repair.cohesionBefore) or 0,
        cohesionAfter = tonumber(repair and repair.cohesionAfter) or 0,
        scoreDelta = tonumber(repair and repair.scoreDelta) or 0,
    }
end

local function ProfileSnapshot(profile)
    if not profile then return nil end
    if WP and WP.ExportContextualSupportProfile then return WP.ExportContextualSupportProfile(profile) end
    return Copy(profile)
end

local function ExcludedSlots(state, stats)
    local excluded, active = {}, {}
    for _, slotKey in ipairs(stats and stats.activeSlots or {}) do active[slotKey] = true end
    for _, slotKey in ipairs(WP and WP.SUPPORT_SLOT_ORDER or {}) do
        local definition = Wardrobe.GetSlotDefinition(slotKey)
        local label = definition and definition.label or slotKey
        if state.hidden and state.hidden[slotKey] then excluded[#excluded + 1] = label .. " (Hidden)"
        elseif state.locks and state.locks[slotKey] then excluded[#excluded + 1] = label .. " (Locked)"
        elseif not active[slotKey] then excluded[#excluded + 1] = label .. " (Unavailable)" end
    end
    return excluded
end

function DP.BuildSupportSnapshot(state, job)
    local stats = job and job.supportDiagnostics
    if not stats and job and job.action == "REROLL_SLOT" then stats = WP and WP.lastSupportDiagnostics end
    if not stats then return nil end
    local decisions = {}
    for _, decision in ipairs(stats.decisions or {}) do decisions[#decisions + 1] = SourceSnapshot(decision) end
    return {
        version = 1,
        profile = ProfileSnapshot(stats.profile),
        startingBudget = tonumber(stats.startingBudget) or 0,
        lockedCommitment = tonumber(stats.lockedCommitment) or 0,
        generatedSpend = tonumber(stats.generatedSpend) or 0,
        borrowed = tonumber(stats.borrowed) or 0,
        overrun = tonumber(stats.overrun) or 0,
        remainingBudget = tonumber(stats.remainingBudget) or 0,
        configurationScore = tonumber(stats.configurationScore) or 0,
        wholeOutfitCohesion = tonumber(stats.wholeOutfitCohesion) or 0,
        controlledAccents = tonumber(stats.controlledAccents) or 0,
        outliers = tonumber(stats.outliers) or 0,
        fallbackSlots = tonumber(stats.fallbackSlots) or 0,
        chosenRank = tonumber(stats.chosenRank) or 0,
        shortlistSize = tonumber(stats.shortlistSize) or 0,
        poolSizes = Copy(stats.poolSizes), expansions = Copy(stats.expansions), retained = Copy(stats.retained),
        deduplicated = tonumber(stats.deduplicated) or 0,
        budgetRejections = tonumber(stats.budgetRejections) or 0,
        emptySlots = tonumber(stats.emptySlots) or 0,
        decisions = decisions,
        excluded = ExcludedSlots(state or {}, stats),
        targetSlotKey = stats.targetSlotKey,
        previousTargetName = stats.previousTargetName,
        previousTargetSourceID = stats.previousTargetSourceID,
        previousTargetVisualID = stats.previousTargetVisualID,
        previousTargetCost = tonumber(stats.previousTargetCost) or 0,
        replacementCost = tonumber(stats.replacementCost) or 0,
        budgetBefore = tonumber(stats.budgetBefore) or 0,
        budgetAfter = tonumber(stats.budgetAfter) or 0,
        fixedContextCount = tonumber(stats.fixedContextCount) or 0,
        noAlternative = stats.noAlternative == true,
        profileID = stats.profileID or (stats.profile and stats.profile.profileID),
        profileSourceReportID = stats.profileSourceReportID or (stats.profile and stats.profile.profileSourceReportID),
        profileReused = stats.profileReused == true,
        profileRepaired = stats.profileRepaired == true,
        profileMigrated = stats.profileMigrated == true,
        profileRepairReason = stats.profileRepairReason,
        profileBasisConsistent = stats.profileBasisConsistent ~= false,
        fixedContextCost = tonumber(stats.fixedContextCost) or 0,
        profileAdjustment = tonumber(stats.profileAdjustment) or 0,
        expectedBudgetAfter = tonumber(stats.expectedBudgetAfter) or tonumber(stats.budgetAfter) or 0,
        budgetReconciled = stats.budgetReconciled ~= false,
        finalValidationStatus = stats.finalValidationStatus or "CLEAN",
        repairPasses = tonumber(stats.repairPasses) or 0,
        repairs = (function()
            local result = {}
            for _, repair in ipairs(stats.repairs or {}) do result[#result + 1] = RepairSnapshot(repair) end
            return result
        end)(),
        phaseDInitial = ValidationSnapshot(stats.phaseDInitial),
        phaseDFinal = ValidationSnapshot(stats.phaseDFinal),
        alternateSkeleton = stats.alternateSkeleton == true,
    }
end
