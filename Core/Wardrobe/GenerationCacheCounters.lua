local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

local function Stats()
    return P.GetGenerationCacheSessionStats and P.GetGenerationCacheSessionStats() or {}
end

function P.InitializeGenerationCacheCountLedger(evidence, prechecks, eligibility)
    local stats = Stats()
    stats.currentEvidence = math.max(0, tonumber(evidence) or 0)
    stats.currentPrechecks = math.max(0, tonumber(prechecks) or 0)
    stats.currentEligibility = math.max(0, tonumber(eligibility) or 0)
end

function P.AdjustGenerationCacheCountLedger(evidence, prechecks, eligibility)
    local stats = Stats()
    stats.currentEvidence = math.max(0, (tonumber(stats.currentEvidence) or 0) + (tonumber(evidence) or 0))
    stats.currentPrechecks = math.max(0, (tonumber(stats.currentPrechecks) or 0) + (tonumber(prechecks) or 0))
    stats.currentEligibility = math.max(0, (tonumber(stats.currentEligibility) or 0) + (tonumber(eligibility) or 0))
end

function P.GetGenerationCacheCountLedger()
    local stats = Stats()
    return tonumber(stats.currentEvidence) or tonumber(stats.loadedEvidence) or 0,
        tonumber(stats.currentPrechecks) or tonumber(stats.loadedPrechecks) or 0,
        tonumber(stats.currentEligibility) or tonumber(stats.loadedEligibility) or 0
end

function P.CopyGenerationCacheInvalidationReasons()
    local copy = {}
    for reason, count in pairs(Stats().invalidationReasons or {}) do copy[reason] = tonumber(count) or 0 end
    return copy
end

function P.GetGenerationCacheScalarSnapshot()
    local stats = Stats()
    local evidence, prechecks, eligibility = P.GetGenerationCacheCountLedger()
    return {
        persistentEvidence = evidence, persistentPrechecks = prechecks, persistentEligibility = eligibility,
        loadedEvidence = stats.loadedEvidence or 0, loadedPrechecks = stats.loadedPrechecks or 0,
        loadedEligibility = stats.loadedEligibility or 0, migratedEvidence = stats.migratedEvidence or 0,
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
        retainedEvidenceAfterScan = stats.retainedEvidenceAfterScan or 0,
        retainedPrechecksAfterScan = stats.retainedPrechecksAfterScan or 0,
        retainedEligibilityAfterScan = stats.retainedEligibilityAfterScan or 0,
        scanCompletedWithEvidence = stats.scanCompletedWithEvidence or 0,
        scanCompletedWithPrechecks = stats.scanCompletedWithPrechecks or 0,
        scanCompletedWithEligibility = stats.scanCompletedWithEligibility or 0,
    }
end
