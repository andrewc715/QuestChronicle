local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function CountMap(values)
    local count = 0
    for _ in pairs(values or {}) do count = count + 1 end
    return count
end

function P.BeginPersistentGenerationCacheScan()
    P.EnsurePersistentGenerationCache()
    P.generationCacheScanSeen = { evidence = {}, prechecks = {}, eligibility = {} }
end

function P.NotePersistentGenerationCacheRestore(source, evidence, precheck, eligibility)
    local seen = P.generationCacheScanSeen
    local key = P.GetGenerationCacheVisualKey(source)
    if not seen or not key then return end
    if evidence then seen.evidence[key] = true end
    if precheck then seen.prechecks[key] = true end
    if eligibility then seen.eligibility[key] = true end
end

function P.FinishPersistentGenerationCacheScan()
    P.EnsurePersistentGenerationCache()
    local stats = P.GetGenerationCacheSessionStats()
    local seen = P.generationCacheScanSeen or {}
    stats.retainedEvidenceAfterScan = CountMap(seen.evidence)
    stats.retainedPrechecksAfterScan = CountMap(seen.prechecks)
    stats.retainedEligibilityAfterScan = CountMap(seen.eligibility)
    stats.scanCompletedWithEvidence, stats.scanCompletedWithPrechecks,
        stats.scanCompletedWithEligibility = P.GetPersistentGenerationCacheCounts()
    P.generationCacheScanSeen = nil
end

function Wardrobe.GetGenerationCacheDiagnostics()
    local evidence, prechecks, eligibility = P.GetPersistentGenerationCacheCounts()
    local stats = P.GetGenerationCacheSessionStats()
    return {
        persistentEvidence = evidence,
        persistentPrechecks = prechecks,
        persistentEligibility = eligibility,
        loadedEvidence = stats.loadedEvidence,
        loadedPrechecks = stats.loadedPrechecks,
        loadedEligibility = stats.loadedEligibility,
        migratedEvidence = stats.migratedEvidence,
        addedEvidence = stats.addedEvidence,
        addedPrechecks = stats.addedPrechecks,
        addedEligibility = stats.addedEligibility,
        invalidated = stats.invalidated,
        invalidationReasons = stats.invalidationReasons,
        retainedEvidenceAfterScan = stats.retainedEvidenceAfterScan,
        retainedPrechecksAfterScan = stats.retainedPrechecksAfterScan,
        retainedEligibilityAfterScan = stats.retainedEligibilityAfterScan,
        scanCompletedWithEvidence = stats.scanCompletedWithEvidence,
        scanCompletedWithPrechecks = stats.scanCompletedWithPrechecks,
        scanCompletedWithEligibility = stats.scanCompletedWithEligibility,
    }
end

function P.GetGenerationCacheCounterSnapshot()
    local diagnostics = Wardrobe.GetGenerationCacheDiagnostics()
    return {
        addedEvidence = diagnostics.addedEvidence,
        addedPrechecks = diagnostics.addedPrechecks,
        addedEligibility = diagnostics.addedEligibility,
        invalidated = diagnostics.invalidated,
    }
end

function P.BuildGenerationCachePerformance(startCounters)
    local diagnostics = Wardrobe.GetGenerationCacheDiagnostics()
    startCounters = startCounters or {}
    diagnostics.addedDuringGeneration =
        (diagnostics.addedEvidence - (startCounters.addedEvidence or 0))
        + (diagnostics.addedPrechecks - (startCounters.addedPrechecks or 0))
        + (diagnostics.addedEligibility - (startCounters.addedEligibility or 0))
    diagnostics.invalidatedDuringGeneration = diagnostics.invalidated - (startCounters.invalidated or 0)
    return diagnostics
end
