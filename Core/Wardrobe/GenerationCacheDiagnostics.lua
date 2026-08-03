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
        itemEventsIgnored = stats.itemEventsIgnored,
        itemEventsCoalesced = stats.itemEventsCoalesced,
        pendingEvidenceReopened = stats.pendingEvidenceReopened,
        metadataIdentityChanges = stats.metadataIdentityChanges,
        failedItemEventsIgnored = stats.failedItemEventsIgnored,
        itemCallbacksReceived = stats.itemCallbacksReceived,
        dependencyRecordsExamined = stats.dependencyRecordsExamined,
        dependenciesStillPending = stats.dependenciesStillPending,
        dependenciesSatisfied = stats.dependenciesSatisfied,
        evidenceOutcomesUnchanged = stats.evidenceOutcomesUnchanged,
        evidenceOutcomesChanged = stats.evidenceOutcomesChanged,
        downstreamRecordsInvalidated = stats.downstreamRecordsInvalidated,
        pendingRecordsCreated = stats.pendingRecordsCreated,
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
        itemEventsIgnored = diagnostics.itemEventsIgnored,
        itemEventsCoalesced = diagnostics.itemEventsCoalesced,
        pendingEvidenceReopened = diagnostics.pendingEvidenceReopened,
        metadataIdentityChanges = diagnostics.metadataIdentityChanges,
        failedItemEventsIgnored = diagnostics.failedItemEventsIgnored,
        itemCallbacksReceived = diagnostics.itemCallbacksReceived,
        dependencyRecordsExamined = diagnostics.dependencyRecordsExamined,
        dependenciesStillPending = diagnostics.dependenciesStillPending,
        dependenciesSatisfied = diagnostics.dependenciesSatisfied,
        evidenceOutcomesUnchanged = diagnostics.evidenceOutcomesUnchanged,
        evidenceOutcomesChanged = diagnostics.evidenceOutcomesChanged,
        downstreamRecordsInvalidated = diagnostics.downstreamRecordsInvalidated,
        pendingRecordsCreated = diagnostics.pendingRecordsCreated,
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
    diagnostics.itemEventsIgnoredDuringGeneration = diagnostics.itemEventsIgnored - (startCounters.itemEventsIgnored or 0)
    diagnostics.itemEventsCoalescedDuringGeneration = diagnostics.itemEventsCoalesced - (startCounters.itemEventsCoalesced or 0)
    diagnostics.pendingEvidenceReopenedDuringGeneration = diagnostics.pendingEvidenceReopened - (startCounters.pendingEvidenceReopened or 0)
    diagnostics.metadataIdentityChangesDuringGeneration = diagnostics.metadataIdentityChanges - (startCounters.metadataIdentityChanges or 0)
    diagnostics.failedItemEventsIgnoredDuringGeneration = diagnostics.failedItemEventsIgnored - (startCounters.failedItemEventsIgnored or 0)
    diagnostics.itemCallbacksReceivedDuringGeneration = diagnostics.itemCallbacksReceived - (startCounters.itemCallbacksReceived or 0)
    diagnostics.dependencyRecordsExaminedDuringGeneration = diagnostics.dependencyRecordsExamined - (startCounters.dependencyRecordsExamined or 0)
    diagnostics.dependenciesStillPendingDuringGeneration = diagnostics.dependenciesStillPending - (startCounters.dependenciesStillPending or 0)
    diagnostics.dependenciesSatisfiedDuringGeneration = diagnostics.dependenciesSatisfied - (startCounters.dependenciesSatisfied or 0)
    diagnostics.evidenceOutcomesUnchangedDuringGeneration = diagnostics.evidenceOutcomesUnchanged - (startCounters.evidenceOutcomesUnchanged or 0)
    diagnostics.evidenceOutcomesChangedDuringGeneration = diagnostics.evidenceOutcomesChanged - (startCounters.evidenceOutcomesChanged or 0)
    diagnostics.downstreamRecordsInvalidatedDuringGeneration = diagnostics.downstreamRecordsInvalidated - (startCounters.downstreamRecordsInvalidated or 0)
    diagnostics.pendingRecordsCreatedDuringGeneration = diagnostics.pendingRecordsCreated - (startCounters.pendingRecordsCreated or 0)
    return diagnostics
end
