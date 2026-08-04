local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private


local function GetScalarSnapshot()
    if P.GetGenerationCacheScalarSnapshot then return P.GetGenerationCacheScalarSnapshot() end
    local stats = P.GetGenerationCacheSessionStats and P.GetGenerationCacheSessionStats() or {}
    local evidence = tonumber(stats.currentEvidence)
    local prechecks = tonumber(stats.currentPrechecks)
    local eligibility = tonumber(stats.currentEligibility)
    if evidence == nil or prechecks == nil or eligibility == nil then
        local countEvidence, countPrechecks, countEligibility = 0, 0, 0
        if P.GetPersistentGenerationCacheCounts then
            countEvidence, countPrechecks, countEligibility = P.GetPersistentGenerationCacheCounts()
        end
        evidence = evidence or tonumber(stats.loadedEvidence) or countEvidence or 0
        prechecks = prechecks or tonumber(stats.loadedPrechecks) or countPrechecks or 0
        eligibility = eligibility or tonumber(stats.loadedEligibility) or countEligibility or 0
    end
    return {
        persistentEvidence = evidence or 0, persistentPrechecks = prechecks or 0,
        persistentEligibility = eligibility or 0, loadedEvidence = stats.loadedEvidence or 0,
        loadedPrechecks = stats.loadedPrechecks or 0, loadedEligibility = stats.loadedEligibility or 0,
        migratedEvidence = stats.migratedEvidence or 0, addedEvidence = stats.addedEvidence or 0,
        addedPrechecks = stats.addedPrechecks or 0, addedEligibility = stats.addedEligibility or 0,
        invalidated = stats.invalidated or 0, itemEventsIgnored = stats.itemEventsIgnored or 0,
        itemEventsCoalesced = stats.itemEventsCoalesced or 0, pendingEvidenceReopened = stats.pendingEvidenceReopened or 0,
        metadataIdentityChanges = stats.metadataIdentityChanges or 0, failedItemEventsIgnored = stats.failedItemEventsIgnored or 0,
        itemCallbacksReceived = stats.itemCallbacksReceived or 0, dependencyRecordsExamined = stats.dependencyRecordsExamined or 0,
        dependenciesStillPending = stats.dependenciesStillPending or 0, dependenciesSatisfied = stats.dependenciesSatisfied or 0,
        evidenceOutcomesUnchanged = stats.evidenceOutcomesUnchanged or 0, evidenceOutcomesChanged = stats.evidenceOutcomesChanged or 0,
        downstreamRecordsInvalidated = stats.downstreamRecordsInvalidated or 0, pendingRecordsCreated = stats.pendingRecordsCreated or 0,
        retainedEvidenceAfterScan = stats.retainedEvidenceAfterScan or 0, retainedPrechecksAfterScan = stats.retainedPrechecksAfterScan or 0,
        retainedEligibilityAfterScan = stats.retainedEligibilityAfterScan or 0, scanCompletedWithEvidence = stats.scanCompletedWithEvidence or 0,
        scanCompletedWithPrechecks = stats.scanCompletedWithPrechecks or 0, scanCompletedWithEligibility = stats.scanCompletedWithEligibility or 0,
    }
end
local function CopyReasons(values)
    local copy = {}
    for reason, count in pairs(values or {}) do copy[reason] = tonumber(count) or 0 end
    return copy
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

local function CountMap(values)
    local count = 0
    for _ in pairs(values or {}) do count = count + 1 end
    return count
end

function P.FinishPersistentGenerationCacheScan()
    P.EnsurePersistentGenerationCache()
    local stats = P.GetGenerationCacheSessionStats()
    local seen = P.generationCacheScanSeen or {}
    stats.retainedEvidenceAfterScan = CountMap(seen.evidence)
    stats.retainedPrechecksAfterScan = CountMap(seen.prechecks)
    stats.retainedEligibilityAfterScan = CountMap(seen.eligibility)
    stats.scanCompletedWithEvidence, stats.scanCompletedWithPrechecks,
        stats.scanCompletedWithEligibility = P.GetGenerationCacheCountLedger()
    P.generationCacheScanSeen = nil
end

function Wardrobe.GetGenerationCacheDiagnostics()
    local diagnostics = GetScalarSnapshot()
    diagnostics.invalidationReasons = P.CopyGenerationCacheInvalidationReasons
        and P.CopyGenerationCacheInvalidationReasons() or {}
    return diagnostics
end

function P.GetGenerationCacheCounterSnapshot()
    local stats = P.GetGenerationCacheSessionStats()
    return {
        addedEvidence = stats.addedEvidence or 0, addedPrechecks = stats.addedPrechecks or 0,
        addedEligibility = stats.addedEligibility or 0, invalidated = stats.invalidated or 0,
        itemEventsIgnored = stats.itemEventsIgnored or 0, itemEventsCoalesced = stats.itemEventsCoalesced or 0,
        pendingEvidenceReopened = stats.pendingEvidenceReopened or 0,
        metadataIdentityChanges = stats.metadataIdentityChanges or 0,
        failedItemEventsIgnored = stats.failedItemEventsIgnored or 0,
        itemCallbacksReceived = stats.itemCallbacksReceived or 0,
        dependencyRecordsExamined = stats.dependencyRecordsExamined or 0,
        dependenciesStillPending = stats.dependenciesStillPending or 0,
        dependenciesSatisfied = stats.dependenciesSatisfied or 0,
        evidenceOutcomesUnchanged = stats.evidenceOutcomesUnchanged or 0,
        evidenceOutcomesChanged = stats.evidenceOutcomesChanged or 0,
        downstreamRecordsInvalidated = stats.downstreamRecordsInvalidated or 0,
        pendingRecordsCreated = stats.pendingRecordsCreated or 0,
    }
end

function P.BuildGenerationCachePerformance(startCounters)
    local diagnostics = GetScalarSnapshot()
    diagnostics.invalidationReasons = P.CopyGenerationCacheInvalidationReasons
        and P.CopyGenerationCacheInvalidationReasons() or CopyReasons(diagnostics.invalidationReasons)
    startCounters = startCounters or {}
    diagnostics.addedDuringGeneration =
        (diagnostics.addedEvidence - (startCounters.addedEvidence or 0))
        + (diagnostics.addedPrechecks - (startCounters.addedPrechecks or 0))
        + (diagnostics.addedEligibility - (startCounters.addedEligibility or 0))
    diagnostics.invalidatedDuringGeneration = diagnostics.invalidated - (startCounters.invalidated or 0)
    local fields = {
        "itemEventsIgnored", "itemEventsCoalesced", "pendingEvidenceReopened", "metadataIdentityChanges",
        "failedItemEventsIgnored", "itemCallbacksReceived", "dependencyRecordsExamined",
        "dependenciesStillPending", "dependenciesSatisfied", "evidenceOutcomesUnchanged",
        "evidenceOutcomesChanged", "downstreamRecordsInvalidated", "pendingRecordsCreated",
    }
    for _, field in ipairs(fields) do
        diagnostics[field .. "DuringGeneration"] = (diagnostics[field] or 0) - (startCounters[field] or 0)
    end
    return diagnostics
end
