local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.GENERATION_PHASE_LABELS = {
    setup = "Setup (legacy)",
    generationActionIdentity = "Generation action identity",
    generationStateSnapshot = "Generation state snapshot",
    generationModeContext = "Generation mode context",
    generationContextSeed = "Generation context seed",
    generationEligibilityContext = "Generation eligibility context",
    generationNoveltyReference = "Generation novelty reference",
    generationCacheScalarSnapshot = "Generation cache scalar snapshot",
    generationWeaponIndexSnapshot = "Generation weapon-index snapshot",
    validation = "Source validation",
    eraEvidence = "Era evidence",
    eraCandidateBuild = "Era candidate build", eraCurated = "Era curated evidence",
    eraSetList = "Era set list", eraSetEntry = "Era set entry", eraTracking = "Era tracking evidence",
    eraEncounterList = "Era encounter list", eraEncounterEntry = "Era encounter entry",
    eraEncounterResolve = "Era encounter resolve", eraItemMetadata = "Era item metadata",
    eraCandidateFinalize = "Era candidate finalization", eraAggregateFinalize = "Era aggregate finalization",
    eligibility = "Eligibility",
    coherence = "Outfit coherence",
    scoring = "Candidate scoring",
    slotSetup = "Slot setup",
    slotFinalization = "Slot finalization",
    progressUpdate = "Progress update",
    weaponRouting = "Weapon routing",
    stateCommit = "State commit",
    previewApply = "Preview application",
    uiRefresh = "UI refresh",
    completionNotify = "Completion callback",
    anchorCandidateScoring = "Anchor candidate scoring",
    anchorBeamSearch = "Anchor beam search",
    anchorWeaponExpansion = "Anchor weapon expansion",
    anchorSelection = "Anchor selection",
    supportProfile = "Support profile", supportLockedCommitments = "Locked support commitments",
    supportValidation = "Support validation", supportEraEvidence = "Support era evidence",
    supportEligibility = "Support eligibility", supportCandidateScoring = "Support candidate scoring",
    supportBeamExpansion = "Support beam expansion", supportBeamCandidate = "Support beam candidate",
    supportBeamFallback = "Support beam fallback", supportBeamStageFinalize = "Support beam stage finalization",
    supportSelection = "Support selection",
    supportFinalValidation = "Support final validation", supportRepairTargeting = "Support repair targeting",
    supportRepairCandidateEvaluation = "Support repair candidate evaluation",
    supportRepairPass1 = "Support repair pass 1", supportRepairRevalidation = "Support repair revalidation",
    supportRepairPass2 = "Support repair pass 2", supportAlternateSkeleton = "Alternate skeleton preparation",
    rerollFinalValidation = "Reroll final validation", rerollFinalAlternative = "Reroll final alternative",
    rerollSlot = "Reroll slot",
    rerollLaunchManifest = "Reroll launch manifest", rerollStateCapture = "Reroll state capture (legacy)",
    rerollAnchorSnapshotReuse = "Reroll anchor snapshot reuse",
    rerollStateMaterialization = "Reroll state materialization",
    rerollDiagnosticIdentity = "Reroll diagnostic identity",
    rerollAnchorSummary = "Reroll anchor summary",
    rerollStyleContextInit = "Reroll style-context initialization",
    rerollStyleContextSeed = "Reroll style-context seed",
    rerollEligibilityContext = "Reroll eligibility context",
    rerollSupportSummaryFoundation = "Reroll support summary foundation",
    rerollCacheSummaryFoundation = "Reroll cache summary foundation (legacy)",
    rerollCacheScalarSnapshot = "Reroll cache scalar snapshot",
    rerollProfileReuse = "Reroll profile reuse",
    rerollFixedContextCommitments = "Reroll fixed-context commitments", rerollLedgerReconstruction = "Reroll ledger reconstruction",
    rerollCandidatePreparation = "Reroll candidate preparation", rerollSourceValidation = "Reroll source validation",
    rerollEraEvidence = "Reroll era evidence", rerollEligibility = "Reroll eligibility",
    rerollCandidateScoring = "Reroll candidate scoring", rerollNeighborScoring = "Reroll neighbor scoring",
    rerollBridgeScoring = "Reroll bridge scoring", rerollBudgetEvaluation = "Reroll budget evaluation",
    rerollShortlistSelection = "Reroll shortlist selection", rerollStateCommit = "Reroll state commit",
    weaponContext = "Weapon context", weaponCapabilities = "Weapon capabilities", weaponRoute = "Weapon route",
    weaponCapabilitiesBuild = "Weapon capabilities build", weaponCapabilitiesReuse = "Weapon capabilities reuse",
    weaponContextMutableState = "Weapon context mutable state",
    weaponStyleEligibilityStep = "Weapon style eligibility step", weaponStyleCoherence = "Weapon style coherence",
    weaponStyleScoring = "Weapon style scoring",
    weaponCandidateBuild = "Weapon candidate build", weaponCandidateValidate = "Weapon candidate validation",
    weaponValidation = "Weapon source validation", weaponPermission = "Weapon permission",
    weaponAppearance = "Weapon appearance lookup", weaponSourceInfo = "Weapon source metadata",
    weaponIndexBuild = "Weapon index build", weaponIndexRepair = "Weapon index repair",
    weaponIndexLookup = "Weapon index lookup",
    weaponLinkedValidate = "Linked-weapon validation", weaponRouteFilter = "Weapon route filtering",
    weaponCompanionRoute = "Weapon companion route", weaponBundleCohesion = "Weapon bundle cohesion",
}

P.GENERATION_PHASE_SHORT_LABELS = {
    validation = "Validation",
    eraEvidence = "Era",
    eraCandidateBuild = "Era build", eraCurated = "Era curated", eraSetList = "Era sets",
    eraSetEntry = "Era set entry", eraTracking = "Era tracking", eraEncounterList = "Era encounters",
    eraEncounterEntry = "Era encounter entry", eraEncounterResolve = "Era encounter resolve",
    eraItemMetadata = "Era item", eraCandidateFinalize = "Era finalize", eraAggregateFinalize = "Era aggregate",
    coherence = "Coherence",
    scoring = "Scoring",
    slotFinalization = "Slot finalize",
    progressUpdate = "Progress",
    weaponRouting = "Weapons",
    stateCommit = "Commit",
    previewApply = "Preview",
    completionNotify = "Completion",
    anchorCandidateScoring = "Anchor candidates",
    anchorBeamSearch = "Anchor beam",
    anchorWeaponExpansion = "Anchor weapons",
    anchorSelection = "Anchor selection",
    supportProfile = "Support profile", supportLockedCommitments = "Locked support commitments",
    supportValidation = "Support validation", supportEraEvidence = "Support era evidence",
    supportEligibility = "Support eligibility", supportCandidateScoring = "Support candidate scoring",
    supportBeamExpansion = "Support beam expansion", supportBeamCandidate = "Support beam candidate",
    supportBeamFallback = "Support beam fallback", supportBeamStageFinalize = "Support beam stage finalization",
    supportSelection = "Support selection",
    supportFinalValidation = "Support final validation", supportRepairTargeting = "Support repair targeting",
    supportRepairCandidateEvaluation = "Support repair candidate evaluation",
    supportRepairPass1 = "Support repair pass 1", supportRepairRevalidation = "Support repair revalidation",
    supportRepairPass2 = "Support repair pass 2", supportAlternateSkeleton = "Alternate skeleton preparation",
    rerollFinalValidation = "Reroll final validation", rerollFinalAlternative = "Reroll final alternative",
    rerollSlot = "Reroll slot",
    rerollLaunchManifest = "Reroll launch", rerollStateCapture = "Reroll capture (legacy)",
    rerollAnchorSnapshotReuse = "Reroll anchor snapshot", rerollStateMaterialization = "Reroll state",
    rerollDiagnosticIdentity = "Reroll diagnostic identity", rerollAnchorSummary = "Reroll anchor summary",
    rerollStyleContextInit = "Reroll context init", rerollStyleContextSeed = "Reroll context seed",
    rerollEligibilityContext = "Reroll eligibility context",
    rerollSupportSummaryFoundation = "Reroll support summary", rerollCacheSummaryFoundation = "Reroll cache summary (legacy)",
    rerollCacheScalarSnapshot = "Reroll cache snapshot",
    rerollProfileReuse = "Reroll profile",
    rerollFixedContextCommitments = "Reroll fixed context", rerollLedgerReconstruction = "Reroll ledger",
    rerollCandidatePreparation = "Reroll candidates", rerollSourceValidation = "Reroll validation",
    rerollEraEvidence = "Reroll era", rerollEligibility = "Reroll eligibility",
    rerollCandidateScoring = "Reroll scoring", rerollNeighborScoring = "Reroll neighbors",
    rerollBridgeScoring = "Reroll bridge", rerollBudgetEvaluation = "Reroll budget",
    rerollShortlistSelection = "Reroll shortlist", rerollStateCommit = "Reroll commit",
}

function P.GenerationNowMilliseconds()
    if type(debugprofilestop) == "function" then
        return debugprofilestop()
    end
    if type(GetTimePreciseSec) == "function" then
        return GetTimePreciseSec() * 1000
    end
    if type(GetTime) == "function" then
        return GetTime() * 1000
    end
    return 0
end

function P.RecordGenerationPhase(target, phaseKey, elapsedMs)
    if not target or not phaseKey then return end
    elapsedMs = math.max(0, tonumber(elapsedMs) or 0)
    target.phaseStats = target.phaseStats or {}
    local phase = target.phaseStats[phaseKey]
    if not phase then
        phase = { calls = 0, totalMs = 0, maxMs = 0 }
        target.phaseStats[phaseKey] = phase
    end
    phase.calls = phase.calls + 1
    phase.totalMs = phase.totalMs + elapsedMs
    phase.maxMs = math.max(phase.maxMs, elapsedMs)
end

local function ResolveSlowestPhase(phaseStats, allowed)
    local slowestKey, slowestMax = nil, 0
    for phaseKey, phase in pairs(phaseStats or {}) do
        local accepted = not allowed or allowed(phaseKey)
        local phaseMax = accepted and (tonumber(phase and phase.maxMs) or 0) or 0
        local specificSupportTie = phaseMax == slowestMax and slowestKey == "supportBeamExpansion"
            and (phaseKey == "supportBeamCandidate" or phaseKey == "supportBeamFallback" or phaseKey == "supportBeamStageFinalize")
        if phaseMax > slowestMax or specificSupportTie then slowestKey, slowestMax = phaseKey, phaseMax end
    end
    return slowestKey, slowestMax
end

local ERA_OPERATION_PHASE = {
    BUILD = "eraCandidateBuild", CURATED = "eraCurated", SET_LIST = "eraSetList",
    SET_ENTRY = "eraSetEntry", TRACKING = "eraTracking", ENCOUNTER_LIST = "eraEncounterList",
    ENCOUNTER_DROP = "eraEncounterEntry", ENCOUNTER_TIER = "eraEncounterEntry",
    ENCOUNTER_RESOLVE = "eraEncounterResolve", EARLY_DECISION = "eraCandidateFinalize",
    ITEM_METADATA = "eraItemMetadata", FINALIZE = "eraCandidateFinalize",
    AGGREGATE_FINALIZE = "eraAggregateFinalize",
}

local ERA_SUBPHASES = {
    "eraCandidateBuild", "eraCurated", "eraSetList", "eraSetEntry", "eraTracking",
    "eraEncounterList", "eraEncounterEntry", "eraEncounterResolve", "eraItemMetadata",
    "eraCandidateFinalize", "eraAggregateFinalize",
}

local function ResolveLargestEraSubphase(phaseStats)
    local key, value = nil, 0
    for _, phaseKey in ipairs(ERA_SUBPHASES) do
        local current = tonumber(phaseStats and phaseStats[phaseKey] and phaseStats[phaseKey].maxMs) or 0
        if current > value then key, value = phaseKey, current end
    end
    return key, value
end

function P.RecordEraSchedulingOperation(job, eraWork, elapsedMs)
    if not job or not eraWork then return end
    local diag = eraWork.lastStepDiagnostics or {}
    if diag.deferred then return end
    local operation = diag.operation
    if not operation then return end
    job.eraOperations = (tonumber(job.eraOperations) or 0) + 1
    if diag.siblingCompleted then job.eraSiblingCompletions = (tonumber(job.eraSiblingCompletions) or 0) + 1 end
    if diag.fragmentCacheHit then job.eraFragmentCacheHits = (tonumber(job.eraFragmentCacheHits) or 0) + 1 end
    if diag.fragmentCacheBuilt then job.eraFragmentCacheBuilds = (tonumber(job.eraFragmentCacheBuilds) or 0) + 1 end
    if diag.pendingCandidate then job.eraPendingCandidateCompletions = (tonumber(job.eraPendingCandidateCompletions) or 0) + 1 end
    if operation == "SET_LIST" then job.eraSetListCalls = (tonumber(job.eraSetListCalls) or 0) + 1
    elseif operation == "SET_ENTRY" then job.eraSetEntryCalls = (tonumber(job.eraSetEntryCalls) or 0) + 1
    elseif operation == "TRACKING" then job.eraTrackingCalls = (tonumber(job.eraTrackingCalls) or 0) + 1
    elseif operation == "ENCOUNTER_LIST" then job.eraEncounterListCalls = (tonumber(job.eraEncounterListCalls) or 0) + 1
    elseif operation == "ENCOUNTER_DROP" or operation == "ENCOUNTER_TIER" then job.eraEncounterEntryOperations = (tonumber(job.eraEncounterEntryOperations) or 0) + 1
    elseif operation == "ITEM_METADATA" then job.eraItemMetadataCalls = (tonumber(job.eraItemMetadataCalls) or 0) + 1
    elseif operation == "AGGREGATE_FINALIZE" then job.eraAggregateFinalizations = (tonumber(job.eraAggregateFinalizations) or 0) + 1 end
    local phaseKey = ERA_OPERATION_PHASE[operation]
    if phaseKey then P.RecordGenerationPhase(job, phaseKey, elapsedMs) end
end

local SUPPORT_SUBPHASES = {
    "supportEligibility", "supportBeamCandidate", "supportBeamFallback", "supportBeamStageFinalize",
}

local function ResolveLargestSupportSubphase(phaseStats)
    local key, value = nil, 0
    for _, phaseKey in ipairs(SUPPORT_SUBPHASES) do
        local current = tonumber(phaseStats and phaseStats[phaseKey] and phaseStats[phaseKey].maxMs) or 0
        if current > value then key, value = phaseKey, current end
    end
    return key, value
end

local function IsCooperativeRerollPhase(phaseKey)
    return phaseKey ~= "rerollLaunchManifest" and phaseKey ~= "rerollStateCapture"
        and phaseKey ~= "previewApply" and phaseKey ~= "uiRefresh" and phaseKey ~= "completionNotify"
end

local function ApplyTimingDomains(performance)
    if not performance or not performance.supportRerollTiming then return end
    local phases = performance.phaseStats or {}
    local launch = phases.rerollLaunchManifest or phases.rerollStateCapture
    local launchMs = tonumber(launch and launch.maxMs) or tonumber(performance.synchronousLaunchPreparationMs)
        or tonumber(performance.preWorkerPreparationMs) or 0
    performance.synchronousLaunchPreparationMs = launchMs
    performance.preWorkerPreparationMs = launchMs
    local key, value = ResolveSlowestPhase(performance.phaseStats, IsCooperativeRerollPhase)
    performance.largestCooperativeCallPhase = key
    performance.largestCooperativeCallMs = value
end

function P.BuildGenerationPerformance(job, finishedAtMs)
    local slowestKey, slowestMax = ResolveSlowestPhase(job and job.phaseStats)
    local supportSlowestKey, supportSlowestMax = ResolveLargestSupportSubphase(job and job.phaseStats)
    local eraSlowestKey, eraSlowestMax = ResolveLargestEraSubphase(job and job.phaseStats)
    local weaponYieldMs = job and math.max(job.weaponWork and job.weaponWork.maxResumeMs or 0, job.anchorWeaponSlowYieldMs or 0) or 0
    local weaponYieldPhase = job and ((job.weaponWork and job.weaponWork.slowestYieldPhase) or job.anchorWeaponSlowYieldPhase) or nil
    local largestKey, largestMax = slowestKey, slowestMax
    if weaponYieldPhase and (weaponYieldMs > largestMax or (slowestKey == "anchorWeaponExpansion" and weaponYieldMs >= largestMax * 0.75)) then
        largestKey, largestMax = weaponYieldPhase, weaponYieldMs
    end
    local result = {
        startedAtMs = job and job.startedAtMs or finishedAtMs,
        elapsedMs = math.max(0, (finishedAtMs or 0) - (job and job.startedAtMs or finishedAtMs or 0)),
        steps = job and job.steps or 0,
        maxStepMs = job and job.maxStepMs or 0,
        longestWorkerSliceMs = job and job.maxStepMs or 0,
        candidates = job and job.candidatesProcessed or 0,
        eraCandidates = job and job.eraCandidatesProcessed or 0,
        eraCacheHits = job and job.eraCacheHits or 0,
        eligibilityCacheHits = job and job.eligibilityCacheHits or 0,
        weaponYields = job and job.weaponYields or 0,
        weaponSlowYieldPhase = weaponYieldPhase,
        weaponSlowYieldMs = weaponYieldMs,
        selectedArmor = job and job.selectedArmor or 0,
        anchorStats = job and job.anchorStats or nil,
        anchorFallbackReason = job and job.anchorFallbackReason or nil,
        supportStats = job and job.supportStats or nil,
        supportFallbackReason = job and job.supportFallbackReason or nil,
        weaponIndex = P.BuildWeaponIndexActionDiagnostics
            and P.BuildWeaponIndexActionDiagnostics(job and job.weaponIndexActionStarted) or
            (P.GetWeaponCandidateIndexDiagnostics and P.GetWeaponCandidateIndexDiagnostics() or nil),
        cacheDiagnostics = P.BuildGenerationCachePerformance
            and P.BuildGenerationCachePerformance(job and job.cacheCountersStarted) or nil,
        phaseStats = job and job.phaseStats or {},
        slowestPhase = slowestKey,
        slowestPhaseMs = slowestMax,
        largestInstrumentedCallPhase = largestKey,
        largestInstrumentedCallMs = largestMax,
        supportRerollTiming = job and job.supportReroll == true or false,
        synchronousLaunchPreparationMs = job and (job.synchronousLaunchPreparationMs or job.preWorkerPreparationMs) or 0,
        preWorkerPreparationMs = job and (job.synchronousLaunchPreparationMs or job.preWorkerPreparationMs) or 0,
        schedulerDiagnostics = job and job.schedulerDiagnostics or nil,
        eraScheduling = job and {
            operations = tonumber(job.eraOperations) or 0,
            siblingCompletions = tonumber(job.eraSiblingCompletions) or 0,
            freshSliceDeferrals = tonumber(job.eraFreshSliceDeferrals) or 0,
            fragmentCacheHits = tonumber(job.eraFragmentCacheHits) or 0,
            fragmentCacheBuilds = tonumber(job.eraFragmentCacheBuilds) or 0,
            pendingCandidateCompletions = tonumber(job.eraPendingCandidateCompletions) or 0,
            setListCalls = tonumber(job.eraSetListCalls) or 0, setEntryCalls = tonumber(job.eraSetEntryCalls) or 0,
            trackingCalls = tonumber(job.eraTrackingCalls) or 0, encounterListCalls = tonumber(job.eraEncounterListCalls) or 0,
            encounterEntryOperations = tonumber(job.eraEncounterEntryOperations) or 0,
            itemMetadataCalls = tonumber(job.eraItemMetadataCalls) or 0,
            aggregateFinalizations = tonumber(job.eraAggregateFinalizations) or 0,
            largestSubphase = eraSlowestKey, largestSubphaseMs = eraSlowestMax,
        } or nil,
        supportScheduling = job and {
            eligibilitySteps = tonumber(job.supportEligibilitySteps) or 0,
            eligibilityYields = tonumber(job.supportEligibilityYields) or 0,
            eligibilityCacheCompletions = tonumber(job.supportEligibilityCacheCompletions) or 0,
            eligibilityComputedCompletions = tonumber(job.supportEligibilityComputedCompletions) or 0,
            eligibilityMarkerBatch = tonumber(job.supportEligibilityMarkerBatch) or P.SUPPORT_ELIGIBILITY_MARKER_BATCH or 4,
            beamCandidateSteps = tonumber(job.supportBeamCandidateSteps) or 0,
            beamFallbackSteps = tonumber(job.supportBeamFallbackSteps) or 0,
            beamFallbackYields = tonumber(job.supportBeamFallbackYields) or 0,
            beamStageFinalizations = tonumber(job.supportBeamStageFinalizations) or 0,
            beamFreshSliceDeferrals = tonumber(job.supportBeamFreshSliceDeferrals) or 0,
            beamStageFinalizeMaxMs = tonumber(job.supportBeamStageFinalizeMaxMs) or 0,
            largestSubphase = supportSlowestKey,
            largestSubphaseMs = supportSlowestMax,
        } or nil,
        weaponCapabilities = job and {
            status = job.weaponCapabilitySnapshotStatus,
            generation = job.weaponCapabilityGeneration,
            buildsThisAction = tonumber(job.weaponCapabilityBuildsThisAction) or 0,
            reusesThisAction = tonumber(job.weaponCapabilityReusesThisAction) or 0,
            staleAtCommit = job.weaponCapabilityStaleAtCommit == true,
            currentGeneration = job.weaponCapabilityCurrentGeneration,
            invalidationReason = job.weaponCapabilityInvalidationReason,
            eligibilitySteps = tonumber(job.weaponStyleEligibilitySteps) or 0,
            eligibilityYields = tonumber(job.weaponStyleEligibilityYields) or 0,
            coherenceCalls = tonumber(job.weaponStyleCoherenceCalls) or 0,
            scoringCalls = tonumber(job.weaponStyleScoringCalls) or 0,
        } or nil,
    }
    ApplyTimingDomains(result)
    return result
end

function Wardrobe.RecordGenerationPostPhase(performance, phaseKey, elapsedMs)
    if not performance then return end
    P.RecordGenerationPhase(performance, phaseKey, elapsedMs)
    if not performance.supportRerollTiming then
        performance.maxStepMs = math.max(tonumber(performance.maxStepMs) or 0, tonumber(elapsedMs) or 0)
        performance.longestWorkerSliceMs = performance.maxStepMs
    end
    local slowestKey, slowestMax = ResolveSlowestPhase(performance.phaseStats)
    performance.slowestPhase = slowestKey
    performance.slowestPhaseMs = slowestMax
    local weaponYieldMs = tonumber(performance.weaponSlowYieldMs) or 0
    local weaponYieldPhase = performance.weaponSlowYieldPhase
    if weaponYieldPhase and (weaponYieldMs > slowestMax or (slowestKey == "anchorWeaponExpansion" and weaponYieldMs >= slowestMax * 0.75)) then
        performance.largestInstrumentedCallPhase = weaponYieldPhase
        performance.largestInstrumentedCallMs = weaponYieldMs
    else
        performance.largestInstrumentedCallPhase = slowestKey
        performance.largestInstrumentedCallMs = slowestMax
    end
    ApplyTimingDomains(performance)
    if performance.startedAtMs then
        performance.elapsedMs = math.max(tonumber(performance.elapsedMs) or 0, P.GenerationNowMilliseconds() - performance.startedAtMs)
    end
end

function Wardrobe.FormatGenerationPerformance(performance)
    if not performance then return "" end
    local steps = tonumber(performance.steps) or 0
    local elapsedSeconds = (tonumber(performance.elapsedMs) or 0) / 1000
    local maxStep = tonumber(performance.maxStepMs) or 0
    local slowestLabel = P.GENERATION_PHASE_SHORT_LABELS[performance.slowestPhase]
        or P.GENERATION_PHASE_LABELS[performance.slowestPhase]
        or tostring(performance.slowestPhase or "Unknown")
    local slowestMs = tonumber(performance.slowestPhaseMs) or 0
    if performance.supportRerollTiming then
        local cooperativeLabel = P.GENERATION_PHASE_SHORT_LABELS[performance.largestCooperativeCallPhase]
            or P.GENERATION_PHASE_LABELS[performance.largestCooperativeCallPhase]
            or tostring(performance.largestCooperativeCallPhase or "Unknown")
        return string.format(
            "Prepared in %d frame%s • %.1f sec • synchronous launch %.1f ms • cooperative slice %.1f ms • largest cooperative call %s %.1f ms",
            steps, steps == 1 and "" or "s", elapsedSeconds, tonumber(performance.synchronousLaunchPreparationMs) or 0,
            maxStep, cooperativeLabel, tonumber(performance.largestCooperativeCallMs) or 0
        )
    end
    return string.format(
        "Prepared in %d frame%s • %.1f sec • worker slice %.1f ms • largest call %s %.1f ms",
        steps, steps == 1 and "" or "s", elapsedSeconds, maxStep, slowestLabel, slowestMs
    )
end

function Wardrobe.GetGenerationPerformanceDetails(performance)
    performance = performance or P.lastGenerationPerformance
    if not performance then return {} end
    local details = {}
    for phaseKey, phase in pairs(performance.phaseStats or {}) do
        table.insert(details, {
            key = phaseKey,
            label = P.GENERATION_PHASE_LABELS[phaseKey] or phaseKey,
            calls = tonumber(phase.calls) or 0,
            totalMs = tonumber(phase.totalMs) or 0,
            maxMs = tonumber(phase.maxMs) or 0,
        })
    end
    if (tonumber(performance.weaponSlowYieldMs) or 0) > 8 then
        table.insert(details, {
            key = "weaponYieldOverrun",
            label = "Weapon yield: " .. tostring(performance.weaponSlowYieldPhase or "unknown"),
            calls = 1,
            totalMs = tonumber(performance.weaponSlowYieldMs) or 0,
            maxMs = tonumber(performance.weaponSlowYieldMs) or 0,
        })
    end
    table.sort(details, function(left, right)
        if left.maxMs == right.maxMs then return left.label < right.label end
        return left.maxMs > right.maxMs
    end)
    return details
end


function Wardrobe.GetAnchorSkeletonPerformanceLines(performance)
    local stats = performance and performance.anchorStats
    if not stats then
        return performance and performance.anchorFallbackReason and { "Anchor fallback: " .. tostring(performance.anchorFallbackReason) } or {}
    end
    local pools, expansions, retained = stats.poolSizes or {}, stats.expansions or {}, stats.retained or {}
    return {
        string.format("Anchor pools: %d chest • %d legs • %d shoulders", pools.CHEST or 0, pools.LEGS or 0, pools.SHOULDER or 0),
        string.format("Beam expansions: %d chest • %d legs • %d shoulders", expansions.CHEST or 0, expansions.LEGS or 0, expansions.SHOULDER or 0),
        string.format("Beam retained: %d chest • %d legs • %d shoulders • %d weapon bundles", retained.CHEST or 0, retained.LEGS or 0, retained.SHOULDER or 0, stats.weaponBundles or 0),
        string.format("Chosen skeleton: rank %d/%d • base %.1f • adjusted %.1f • cohesion %.3f • hard clashes %d", stats.chosenRank or 0, stats.shortlistSize or 0, stats.baseSkeletonScore or stats.chosenScore or 0, stats.adjustedSelectionScore or stats.chosenScore or 0, stats.meanPairCohesion or 0, stats.hardClashes or 0),
        stats.noveltyClass and string.format("Novelty: %s • repeat penalty %.1f", P.GetAnchorNoveltyClassLabel and P.GetAnchorNoveltyClassLabel(stats.noveltyClass) or tostring(stats.noveltyClass), stats.repeatPenalty or 0) or "Novelty: not applicable",
        string.format("Pair cache: %d hits • %d misses", stats.pairCacheHits or 0, stats.pairCacheMisses or 0),
    }
end

function Wardrobe.GetGenerationCachePerformanceLines(performance)
    local diagnostics = performance and performance.cacheDiagnostics
    if not diagnostics then return {} end
    local lines = {
        string.format(
            "Persistent cache: %d evidence • %d prechecks • %d eligibility",
            tonumber(diagnostics.persistentEvidence) or 0,
            tonumber(diagnostics.persistentPrechecks) or 0,
            tonumber(diagnostics.persistentEligibility) or 0
        ),
        string.format(
            "Loaded: %d evidence • %d prechecks • %d eligibility • %d migrated",
            tonumber(diagnostics.loadedEvidence) or 0,
            tonumber(diagnostics.loadedPrechecks) or 0,
            tonumber(diagnostics.loadedEligibility) or 0,
            tonumber(diagnostics.migratedEvidence) or 0
        ),
        string.format(
            "After scan: %d evidence retained • this generation: %d added • %d invalidated",
            tonumber(diagnostics.retainedEvidenceAfterScan) or 0,
            tonumber(diagnostics.addedDuringGeneration) or 0,
            tonumber(diagnostics.invalidatedDuringGeneration) or 0
        ),
        string.format(
            "Item callbacks: %d received • %d coalesced • %d dependencies examined",
            tonumber(diagnostics.itemCallbacksReceivedDuringGeneration) or 0,
            tonumber(diagnostics.itemEventsCoalescedDuringGeneration) or 0,
            tonumber(diagnostics.dependencyRecordsExaminedDuringGeneration) or 0
        ),
        string.format(
            "Dependencies: %d still pending • %d satisfied • %d outcomes unchanged • %d changed",
            tonumber(diagnostics.dependenciesStillPendingDuringGeneration) or 0,
            tonumber(diagnostics.dependenciesSatisfiedDuringGeneration) or 0,
            tonumber(diagnostics.evidenceOutcomesUnchangedDuringGeneration) or 0,
            tonumber(diagnostics.evidenceOutcomesChangedDuringGeneration) or 0
        ),
        string.format(
            "Cache churn: %d pending records created • %d downstream invalidated • %d identity changes",
            tonumber(diagnostics.pendingRecordsCreatedDuringGeneration) or 0,
            tonumber(diagnostics.downstreamRecordsInvalidatedDuringGeneration) or 0,
            tonumber(diagnostics.metadataIdentityChangesDuringGeneration) or 0
        ),
    }
    local reasons = {}
    for reason, count in pairs(diagnostics.invalidationReasons or {}) do
        reasons[#reasons + 1] = { reason = reason, count = tonumber(count) or 0 }
    end
    table.sort(reasons, function(left, right)
        if left.count == right.count then return left.reason < right.reason end
        return left.count > right.count
    end)
    for _, entry in ipairs(reasons) do
        lines[#lines + 1] = string.format("Invalidated %s: %d", entry.reason, entry.count)
    end
    return lines
end
