local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.GENERATION_PHASE_LABELS = {
    setup = "Setup",
    validation = "Source validation",
    eraEvidence = "Era evidence",
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
}

P.GENERATION_PHASE_SHORT_LABELS = {
    validation = "Validation",
    eraEvidence = "Era",
    coherence = "Coherence",
    scoring = "Scoring",
    slotFinalization = "Slot finalize",
    progressUpdate = "Progress",
    weaponRouting = "Weapons",
    stateCommit = "Commit",
    previewApply = "Preview",
    completionNotify = "Completion",
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

local function ResolveSlowestPhase(phaseStats)
    local slowestKey, slowestMax = nil, 0
    for phaseKey, phase in pairs(phaseStats or {}) do
        local phaseMax = tonumber(phase and phase.maxMs) or 0
        if phaseMax > slowestMax then
            slowestKey, slowestMax = phaseKey, phaseMax
        end
    end
    return slowestKey, slowestMax
end

function P.BuildGenerationPerformance(job, finishedAtMs)
    local slowestKey, slowestMax = ResolveSlowestPhase(job and job.phaseStats)
    return {
        startedAtMs = job and job.startedAtMs or finishedAtMs,
        elapsedMs = math.max(0, (finishedAtMs or 0) - (job and job.startedAtMs or finishedAtMs or 0)),
        steps = job and job.steps or 0,
        maxStepMs = job and job.maxStepMs or 0,
        candidates = job and job.candidatesProcessed or 0,
        eraCandidates = job and job.eraCandidatesProcessed or 0,
        eraCacheHits = job and job.eraCacheHits or 0,
        eligibilityCacheHits = job and job.eligibilityCacheHits or 0,
        weaponYields = job and job.weaponYields or 0,
        selectedArmor = job and job.selectedArmor or 0,
        cacheDiagnostics = P.BuildGenerationCachePerformance
            and P.BuildGenerationCachePerformance(job and job.cacheCountersStarted) or nil,
        phaseStats = job and job.phaseStats or {},
        slowestPhase = slowestKey,
        slowestPhaseMs = slowestMax,
    }
end

function Wardrobe.RecordGenerationPostPhase(performance, phaseKey, elapsedMs)
    if not performance then return end
    P.RecordGenerationPhase(performance, phaseKey, elapsedMs)
    performance.maxStepMs = math.max(tonumber(performance.maxStepMs) or 0, tonumber(elapsedMs) or 0)
    local slowestKey, slowestMax = ResolveSlowestPhase(performance.phaseStats)
    performance.slowestPhase = slowestKey
    performance.slowestPhaseMs = slowestMax
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
    return string.format(
        "Prepared in %d frame%s • %.1f sec • worst %.1f ms • slowest %s %.1f ms",
        steps,
        steps == 1 and "" or "s",
        elapsedSeconds,
        maxStep,
        slowestLabel,
        slowestMs
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
    table.sort(details, function(left, right)
        if left.maxMs == right.maxMs then return left.label < right.label end
        return left.maxMs > right.maxMs
    end)
    return details
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
            "Item data: %d stable ignored • %d pending reopened • %d identity changes • %d coalesced",
            tonumber(diagnostics.itemEventsIgnoredDuringGeneration) or 0,
            tonumber(diagnostics.pendingEvidenceReopenedDuringGeneration) or 0,
            tonumber(diagnostics.metadataIdentityChangesDuringGeneration) or 0,
            tonumber(diagnostics.itemEventsCoalescedDuringGeneration) or 0
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
