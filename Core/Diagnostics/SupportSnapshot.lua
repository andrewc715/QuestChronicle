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
    }
end
