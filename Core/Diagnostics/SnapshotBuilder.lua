local QC = QuestChronicle
local D = QC.Diagnostics
local DP = D._Private
local Wardrobe = QC.Wardrobe
local WP = Wardrobe and Wardrobe._Private

local ANCHOR_KEYS = { "CHEST", "LEGS", "SHOULDER" }
local WEAPON_KEYS = { "ONE_HAND", "TWO_HAND", "RANGED", "OFF_HAND" }

local function CopyTable(value)
    return DP.DeepCopy(value, 10) or {}
end

local function SlotLabel(slotKey)
    if slotKey == "ONE_HAND" or slotKey == "TWO_HAND" or slotKey == "RANGED" then return "Main Hand" end
    if slotKey == "OFF_HAND" then return "Off Hand" end
    local definition = Wardrobe and Wardrobe.GetSlotDefinition and Wardrobe.GetSlotDefinition(slotKey)
    return definition and definition.label or tostring(slotKey or "Unknown")
end

local function SourceFor(state, slotKey)
    local sourceID = state and state.selections and state.selections[slotKey]
    if not sourceID or not WP or not WP.GetSourceByID then return nil end
    return WP.GetSourceByID(slotKey, sourceID)
end

local function SourceSnapshot(source, slotKey, state, candidate)
    local sourceID = source and source.sourceID or (state and state.selections and state.selections[slotKey])
    local visualID = source and source.visualID or (state and state.selectionVisuals and state.selectionVisuals[slotKey])
    return {
        slotKey = slotKey,
        slotLabel = SlotLabel(slotKey),
        name = source and (source.styleName or source.name or source.itemName) or (sourceID and ("Appearance " .. tostring(sourceID)) or "None"),
        sourceID = tonumber(sourceID),
        visualID = tonumber(visualID),
        itemID = source and tonumber(source.itemID) or nil,
        categoryID = source and tonumber(source.categoryID) or nil,
        quality = source and tonumber(source.quality) or nil,
        itemSubtype = source and source.styleItemSubType or nil,
        weaponFamily = source and source.styleWeaponFamily or nil,
        locked = state and state.locks and state.locks[slotKey] == true or false,
        hidden = state and state.hidden and state.hidden[slotKey] == true or false,
        baseScore = candidate and tonumber(candidate.baseScore) or nil,
        scoreReasons = candidate and CopyTable(candidate.scoreReasons) or nil,
    }
end

local function BuildOutfit(state)
    local outfit = { slots = {}, generatedName = state and state.generatedName or nil }
    local seen = {}
    for _, definition in ipairs(Wardrobe and Wardrobe.slotDefinitions or {}) do
        local slotKey = definition.key
        seen[slotKey] = true
        outfit.slots[#outfit.slots + 1] = SourceSnapshot(SourceFor(state, slotKey), slotKey, state)
    end
    for _, slotKey in ipairs(WEAPON_KEYS) do
        if not seen[slotKey] then
            outfit.slots[#outfit.slots + 1] = SourceSnapshot(SourceFor(state, slotKey), slotKey, state)
        end
    end
    return outfit
end

local function FindCandidate(anchorDiagnostics, slotKey)
    local candidates = anchorDiagnostics and anchorDiagnostics.candidates
    return candidates and candidates[slotKey] or nil
end

local function BuildSkeleton(state, job)
    if job and job.reuseAnchorSnapshot and type(job.inheritedAnchorSnapshot) == "table" then
        local inherited = CopyTable(job.inheritedAnchorSnapshot)
        inherited.reusedFromParent = true
        return inherited
    end
    local sourceDiagnostics = job and job.anchorDiagnostics
    local stats = job and job.anchorStats
    local skeleton = {
        fallbackReason = job and job.anchorFallbackReason or (sourceDiagnostics and sourceDiagnostics.fallbackReason),
        chosenRank = stats and stats.chosenRank or sourceDiagnostics and sourceDiagnostics.chosenRank,
        shortlistSize = stats and stats.shortlistSize or sourceDiagnostics and sourceDiagnostics.shortlistSize,
        score = stats and stats.chosenScore or sourceDiagnostics and sourceDiagnostics.score,
        baseSkeletonScore = stats and stats.baseSkeletonScore or sourceDiagnostics and sourceDiagnostics.baseSkeletonScore
            or stats and stats.chosenScore or sourceDiagnostics and sourceDiagnostics.score,
        repeatPenalty = stats and stats.repeatPenalty or sourceDiagnostics and sourceDiagnostics.repeatPenalty or 0,
        adjustedSelectionScore = stats and stats.adjustedSelectionScore or sourceDiagnostics and sourceDiagnostics.adjustedSelectionScore
            or stats and stats.chosenScore or sourceDiagnostics and sourceDiagnostics.score,
        noveltyClass = stats and stats.noveltyClass or sourceDiagnostics and sourceDiagnostics.noveltyClass,
        comparedComponents = CopyTable(stats and stats.comparedComponents or sourceDiagnostics and sourceDiagnostics.comparedComponents),
        changedComponents = CopyTable(stats and stats.changedComponents or sourceDiagnostics and sourceDiagnostics.changedComponents),
        repeatedComponents = CopyTable(stats and stats.repeatedComponents or sourceDiagnostics and sourceDiagnostics.repeatedComponents),
        excludedComponents = {},
        exactRepeatAccepted = stats and stats.exactRepeatAccepted == true or sourceDiagnostics and sourceDiagnostics.exactRepeatAccepted == true,
        exactRepeatReason = stats and stats.exactRepeatReason or sourceDiagnostics and sourceDiagnostics.exactRepeatReason,
        meanPairCohesion = stats and stats.meanPairCohesion or sourceDiagnostics and sourceDiagnostics.meanPairCohesion,
        hardClashes = stats and stats.hardClashes or sourceDiagnostics and sourceDiagnostics.hardClashes,
        signature = sourceDiagnostics and sourceDiagnostics.signature or state and state.lastAnchorSkeletonSignature,
        components = {},
        scoreBreakdown = CopyTable(sourceDiagnostics and sourceDiagnostics.scoreBreakdown),
        cohesionComponents = CopyTable(sourceDiagnostics and sourceDiagnostics.cohesionComponents),
        strongestBridge = CopyTable(sourceDiagnostics and sourceDiagnostics.strongestBridge),
        weakestRelationship = CopyTable(sourceDiagnostics and sourceDiagnostics.weakestRelationship),
    }
    for _, slotKey in ipairs(ANCHOR_KEYS) do
        skeleton.components[#skeleton.components + 1] = SourceSnapshot(
            SourceFor(state, slotKey), slotKey, state, FindCandidate(sourceDiagnostics, slotKey)
        )
    end
    for _, slotKey in ipairs(WEAPON_KEYS) do
        local source = SourceFor(state, slotKey)
        if source or (state and state.locks and state.locks[slotKey]) or (state and state.hidden and state.hidden[slotKey]) then
            skeleton.components[#skeleton.components + 1] = SourceSnapshot(source, slotKey, state, FindCandidate(sourceDiagnostics, slotKey))
        end
    end
    for _, component in ipairs(skeleton.components) do
        if component.hidden then skeleton.excludedComponents[#skeleton.excludedComponents + 1] = component.slotLabel .. " (Hidden)"
        elseif component.locked then skeleton.excludedComponents[#skeleton.excludedComponents + 1] = component.slotLabel .. " (Locked)" end
    end
    return skeleton
end

local function BuildBeam(job)
    if job and job.reuseAnchorSnapshot and type(job.inheritedBeamSnapshot) == "table" then return CopyTable(job.inheritedBeamSnapshot) end
    local stats = job and job.anchorStats or {}
    local work = job and job.anchorWork or {}
    return {
        poolSizes = CopyTable(stats.poolSizes or work.poolSizes),
        expansions = CopyTable(stats.expansions or (work.beamWork and work.beamWork.expansions)),
        retained = CopyTable(stats.retained or (work.beamWork and work.beamWork.retained)),
        weaponBundles = tonumber(stats.weaponBundles) or tonumber(work.finalists and #work.finalists) or 0,
        pairCacheHits = tonumber(stats.pairCacheHits) or 0,
        pairCacheMisses = tonumber(stats.pairCacheMisses) or 0,
        completeSkeletons = tonumber(stats.weaponBundles) or 0,
        finalShortlist = tonumber(stats.shortlistSize) or 0,
        chosenRank = tonumber(stats.chosenRank) or 0,
        fallbackReason = job and job.anchorFallbackReason or nil,
        deduplicated = tonumber(stats.deduplicated) or 0,
        hardConstraintRejections = tonumber(stats.hardConstraintRejections) or 0,
        hardClashRejections = tonumber(stats.hardClashRejections) or 0,
        weightedWindow = tonumber(WP and WP.ANCHOR_FINAL_SCORE_WINDOW) or 0,
    }
end

local function BuildCharacter()
    local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter() or {}
    return {
        key = character.key,
        name = character.name,
        realm = character.realm,
        className = character.className,
        classID = character.classID,
        raceName = character.raceName,
        level = type(UnitLevel) == "function" and UnitLevel("player") or nil,
    }
end

local function BuildContext(job)
    local context = job and job.styleContext or {}
    return {
        mode = job and job.styleMode or nil,
        profileKey = context.profileKey,
        profileLabel = context.profileLabel,
        provenanceLabel = context.provenanceLabel,
        zone = context.zone,
        subZone = context.subZone,
        mapID = context.mapID,
        eraMax = context.eraMax,
        eraLabel = context.eraLabel,
        eraShortLabel = context.eraShortLabel,
    }
end

local function ResolveResult(success, message, fallbackReason, resultOverride)
    if resultOverride then return tostring(resultOverride) end
    if success and fallbackReason then return "FALLBACK" end
    if success then return "COMPLETED" end
    local lower = string.lower(tostring(message or ""))
    if lower:find("cancel", 1, true) then return "CANCELLED" end
    return "FAILED"
end

local function BuildGenerationSeed(job, success, message)
    local state = job and (job.liveState or job.draft) or (WP and WP.EnsurePreviewState and WP.EnsurePreviewState()) or {}
    local action = job and job.action
    if not action then action = job and job.reroll and "REROLL_UNLOCKED" or "GENERATE_OUTFIT" end
    local timestamp = type(time) == "function" and time() or 0
    local identity = job and job.diagnosticIdentity
    if not identity and D.BeginGenerationAttempt then identity = D.BeginGenerationAttempt(action) end
    identity = identity or {}
    local performedAnchorSelection = identity.performedAnchorSelection == true
    if job and job.performedAnchorSelection ~= nil then performedAnchorSelection = job.performedAnchorSelection == true end
    return {
        formatVersion = D.FORMAT_VERSION,
        id = identity.reportID, sequence = identity.sequence, startedAt = identity.startedAt,
        lineageID = identity.lineageID, generationToken = identity.generationToken,
        parentCompletedReportID = identity.parentCompletedReportID,
        performedAnchorSelection = performedAnchorSelection,
        previousAnchorSourceReportID = identity.anchorSourceReportID,
        anchorSourceReportID = performedAnchorSelection and identity.reportID
            or (job and job.anchorSourceReportID) or identity.anchorSourceReportID,
        anchorPhase = job and job.reuseAnchorSnapshot and "REUSED" or "SELECTED",
        timestamp = timestamp,
        timestampText = type(date) == "function" and date("%Y-%m-%d %H:%M:%S", timestamp) or tostring(timestamp),
        version = QC.version,
        action = action,
        actionSlotKey = job and job.actionSlotKey or nil,
        mode = job and job.styleMode or state.styleMode,
        result = ResolveResult(success, message, job and (job.anchorFallbackReason or job.supportFallbackReason), job and job.resultOverride),
        success = success == true,
        message = tostring(message or ""),
        character = BuildCharacter(),
        context = BuildContext(job),
        outfit = BuildOutfit(state),
        skeleton = BuildSkeleton(state, job),
        support = DP.BuildSupportSnapshot and DP.BuildSupportSnapshot(state, job) or nil,
        supportFallbackReason = job and job.supportFallbackReason or nil,
        beam = BuildBeam(job),
        cache = {},
        performance = {},
        warnings = {},
    }
end

local function PerformanceSnapshot(performance)
    performance = performance or {}
    local result = {
        elapsedMs = tonumber(performance.elapsedMs) or 0,
        steps = tonumber(performance.steps) or 0,
        maxStepMs = tonumber(performance.maxStepMs) or 0,
        longestWorkerSliceMs = tonumber(performance.longestWorkerSliceMs) or tonumber(performance.maxStepMs) or 0,
        candidates = tonumber(performance.candidates) or 0,
        eraCandidates = tonumber(performance.eraCandidates) or 0,
        eraCacheHits = tonumber(performance.eraCacheHits) or 0,
        eligibilityCacheHits = tonumber(performance.eligibilityCacheHits) or 0,
        weaponYields = tonumber(performance.weaponYields) or 0,
        selectedArmor = tonumber(performance.selectedArmor) or 0,
        slowestPhase = performance.slowestPhase,
        slowestPhaseMs = tonumber(performance.slowestPhaseMs) or 0,
        largestInstrumentedCallPhase = performance.largestInstrumentedCallPhase or performance.slowestPhase,
        largestInstrumentedCallMs = tonumber(performance.largestInstrumentedCallMs) or tonumber(performance.slowestPhaseMs) or 0,
        supportRerollTiming = performance.supportRerollTiming == true,
        synchronousLaunchPreparationMs = tonumber(performance.synchronousLaunchPreparationMs or performance.preWorkerPreparationMs) or 0,
        preWorkerPreparationMs = tonumber(performance.synchronousLaunchPreparationMs or performance.preWorkerPreparationMs) or 0,
        largestCooperativeCallPhase = performance.largestCooperativeCallPhase,
        largestCooperativeCallMs = tonumber(performance.largestCooperativeCallMs) or 0,
        weaponSlowYieldPhase = performance.weaponSlowYieldPhase,
        weaponSlowYieldMs = tonumber(performance.weaponSlowYieldMs) or 0,
        weaponIndex = CopyTable(performance.weaponIndex),
        phaseStats = CopyTable(performance.phaseStats),
    }
    return result
end

local function FinalizeSeed(seed, performance)
    seed.performance = PerformanceSnapshot(performance)
    seed.cache = CopyTable(performance and performance.cacheDiagnostics)
    if DP.AttachWarningsAndComparison then DP.AttachWarningsAndComparison(seed) end
    local report, message = D.AddReport(seed)
    if DP.latestEligiblePendingReport and DP.latestEligiblePendingReport.id == seed.id then DP.latestEligiblePendingReport = nil end
    return report, message
end

local function ScheduleAfterUI(callback)
    if not C_Timer or type(C_Timer.After) ~= "function" then callback() return end
    C_Timer.After(0, function()
        C_Timer.After(0, function()
            C_Timer.After(0, callback)
        end)
    end)
end

function D.QueueGenerationAttempt(job, success, message, performance)
    local seed = BuildGenerationSeed(job, success, message)
    if seed.result == "COMPLETED" or seed.result == "FALLBACK" then DP.latestEligiblePendingReport = seed end
    DP.pendingReportToken = DP.pendingReportToken + 1
    local token = DP.pendingReportToken
    ScheduleAfterUI(function()
        if token <= DP.pendingReportToken then FinalizeSeed(seed, performance) end
    end)
    return seed
end

function D.RecordImmediateAttempt(job, success, message, performance)
    return FinalizeSeed(BuildGenerationSeed(job, success, message), performance)
end

function D.RecordRerollSlotAttempt(slotKey, success, message, elapsedMs, state, styleMode)
    local performance = {
        elapsedMs = tonumber(elapsedMs) or 0,
        steps = 1,
        maxStepMs = tonumber(elapsedMs) or 0,
        slowestPhase = "rerollSlot",
        slowestPhaseMs = tonumber(elapsedMs) or 0,
        phaseStats = { rerollSlot = { calls = 1, totalMs = tonumber(elapsedMs) or 0, maxMs = tonumber(elapsedMs) or 0 } },
        cacheDiagnostics = WP and WP.BuildGenerationCachePerformance and WP.BuildGenerationCachePerformance(nil) or nil,
    }
    local job = {
        action = "REROLL_SLOT",
        actionSlotKey = slotKey,
        liveState = state,
        draft = state,
        styleMode = styleMode,
        styleContext = QC.ZoneStyle and QC.ZoneStyle.GetCurrentContext and QC.ZoneStyle.GetCurrentContext() or nil,
    }
    return D.RecordImmediateAttempt(job, success, message, performance)
end

function D.InstallRerollSlotWrapper()
    if DP.rerollSlotWrapped or not Wardrobe or type(Wardrobe.RerollSlot) ~= "function" then return false end
    local original = Wardrobe.RerollSlot
    Wardrobe.RerollSlot = function(slotKey)
        if WP and WP.IsSupportSlotKey and WP.IsSupportSlotKey(slotKey) then return original(slotKey) end
        local identity = D.BeginGenerationAttempt and D.BeginGenerationAttempt("REROLL_SLOT", slotKey) or nil
        local started = DP.NowMilliseconds()
        local ok, message, asynchronous = original(slotKey)
        if asynchronous then return ok, message, asynchronous end
        local elapsed = math.max(0, DP.NowMilliseconds() - started)
        local state = WP and WP.EnsurePreviewState and WP.EnsurePreviewState() or nil
        local mode = state and state.styleMode or nil
        local job = {
            action = "REROLL_SLOT", actionSlotKey = slotKey, liveState = state, draft = state,
            styleMode = mode, diagnosticIdentity = identity, performedAnchorSelection = true,
        }
        local performance = {
            elapsedMs = elapsed, steps = 1, maxStepMs = elapsed, longestWorkerSliceMs = elapsed,
            slowestPhase = "rerollSlot", slowestPhaseMs = elapsed,
            phaseStats = { rerollSlot = { calls = 1, totalMs = elapsed, maxMs = elapsed } },
            cacheDiagnostics = WP and WP.BuildGenerationCachePerformance and WP.BuildGenerationCachePerformance(nil) or nil,
        }
        D.RecordImmediateAttempt(job, ok == true, message, performance)
        return ok, message, false
    end
    DP.rerollSlotWrapped = true
    return true
end

D.InstallRerollSlotWrapper()
