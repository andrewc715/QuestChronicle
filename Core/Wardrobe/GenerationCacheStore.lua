local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
P.GENERATION_CACHE_STORE_VERSION = 1
P.GENERATION_CACHE_UNKNOWN_TTL_SECONDS = 6 * 60 * 60
P.GENERATION_CACHE_ENTRY_TTL_SECONDS = 30 * 24 * 60 * 60
P.GENERATION_CACHE_PRECHECKS_PER_VISUAL = 3
P.GENERATION_CACHE_ELIGIBILITY_PER_VISUAL = 4
local function CacheNow()
    if type(time) == "function" then return time() end
    if type(GetTimePreciseSec) == "function" then return GetTimePreciseSec() end
    if type(GetTime) == "function" then return GetTime() end
    return 0
end
local function CountMap(values)
    local count = 0
    for _ in pairs(values or {}) do count = count + 1 end
    return count
end
local function CopyNumericList(values)
    local copy, seen = {}, {}
    for _, value in ipairs(values or {}) do
        value = tonumber(value)
        if value and value > 0 and not seen[value] then
            seen[value] = true
            copy[#copy + 1] = value
        end
    end
    table.sort(copy)
    return #copy > 0 and copy or nil
end
local function VisualKey(sourceOrID)
    local visualID = type(sourceOrID) == "table" and sourceOrID.visualID or sourceOrID
    visualID = tonumber(visualID)
    return visualID and visualID > 0 and tostring(visualID) or nil
end
local function ManifestSignature(source)
    if not source then return "" end
    if source.eraManifestSignature then return tostring(source.eraManifestSignature) end
    if P.GetEraManifestSignature then return P.GetEraManifestSignature(source.eraSourceIDs) end
    local parts = {}
    for _, sourceID in ipairs(source.eraSourceIDs or {}) do parts[#parts + 1] = tostring(sourceID) end
    return table.concat(parts, ",")
end
local function ItemManifestSignature(source)
    local parts = {}
    for _, itemID in ipairs(source and source.eraItemIDs or {}) do parts[#parts + 1] = tostring(itemID) end
    return table.concat(parts, ",")
end
function P.GetPersistentEraFingerprint(source)
    if source and source.persistentEraFingerprint then return source.persistentEraFingerprint end
    local fingerprint = table.concat({
        tostring(source and source.visualID or 0),
        tostring(source and source.eraManifestVersion or 0),
        ManifestSignature(source),
        ItemManifestSignature(source),
    }, "|")
    if source then source.persistentEraFingerprint = fingerprint end
    return fingerprint
end

function P.GetPersistentGenerationFingerprint(source)
    if source and source.persistentGenerationFingerprint then
        return source.persistentGenerationFingerprint
    end
    local fingerprint = table.concat({
        P.GetPersistentEraFingerprint(source),
        tostring(source and source.sourceType or 0),
        tostring(source and source.categoryID or 0),
        tostring(source and source.inventoryType or 0),
    }, "|")
    if source then source.persistentGenerationFingerprint = fingerprint end
    return fingerprint
end
function P.GetStableGenerationSourceIdentity(source)
    return table.concat({
        tostring(source and source.visualID or 0),
        tostring(source and source.sourceID or 0),
        tostring(source and source.itemID or 0),
        tostring(source and source.eraManifestVersion or 0),
        ManifestSignature(source),
    }, ":")
end
local function NewStore()
    return {
        version = P.GENERATION_CACHE_STORE_VERSION,
        visuals = {},
        createdAt = CacheNow(),
        updatedAt = CacheNow(),
    }
end
local function EnsureStoreRaw()
    local cache = P.EnsureCache()
    local store = cache.generationCache
    if type(store) ~= "table" or store.version ~= P.GENERATION_CACHE_STORE_VERSION then
        store = NewStore()
        cache.generationCache = store
    end
    store.visuals = store.visuals or {}
    return store, cache
end
local function CountStore(store)
    local evidence, prechecks, eligibility = 0, 0, 0
    for _, bucket in pairs(store and store.visuals or {}) do
        if bucket.evidence then evidence = evidence + 1 end
        prechecks = prechecks + CountMap(bucket.prechecks)
        eligibility = eligibility + CountMap(bucket.eligibility)
    end
    return evidence, prechecks, eligibility
end
local function Stats()
    if not P.generationCacheSessionStats then
        P.generationCacheSessionStats = {
            loadedEvidence = 0,
            loadedPrechecks = 0,
            loadedEligibility = 0,
            migratedEvidence = 0,
            addedEvidence = 0,
            addedPrechecks = 0,
            addedEligibility = 0,
            invalidated = 0,
            invalidationReasons = {},
            itemEventsIgnored = 0,
            itemEventsCoalesced = 0,
            pendingEvidenceReopened = 0,
            metadataIdentityChanges = 0,
            failedItemEventsIgnored = 0,
            retainedEvidenceAfterScan = 0,
            retainedPrechecksAfterScan = 0,
            retainedEligibilityAfterScan = 0,
            scanCompletedWithEvidence = 0,
            scanCompletedWithPrechecks = 0,
            scanCompletedWithEligibility = 0,
        }
    end
    return P.generationCacheSessionStats
end
local function NoteInvalidation(reason, count)
    count = tonumber(count) or 0
    if count <= 0 then return end
    local stats = Stats()
    stats.invalidated = stats.invalidated + count
    reason = tostring(reason or "UNKNOWN")
    stats.invalidationReasons[reason] = (stats.invalidationReasons[reason] or 0) + count
end
local function RemoveBucketIfEmpty(store, key, bucket)
    if bucket and not bucket.evidence and CountMap(bucket.prechecks) == 0 and CountMap(bucket.eligibility) == 0 then
        store.visuals[key] = nil
    end
end

local function InvalidateEvidence(store, key, bucket, reason)
    if not bucket then return end
    local removed = bucket.evidence and 1 or 0
    removed = removed + CountMap(bucket.eligibility)
    bucket.evidence = nil
    bucket.eligibility = nil
    NoteInvalidation(reason, removed)
    RemoveBucketIfEmpty(store, key, bucket)
end

local function PruneEntryMap(values, maxEntries, now, reason)
    if type(values) ~= "table" then return 0 end
    local removed = 0
    local ordered = {}
    for key, record in pairs(values) do
        if not record.updatedAt or now - tonumber(record.updatedAt or 0) > P.GENERATION_CACHE_ENTRY_TTL_SECONDS then
            values[key] = nil
            removed = removed + 1
        else
            ordered[#ordered + 1] = { key = key, updatedAt = tonumber(record.updatedAt) or 0 }
        end
    end
    if #ordered > maxEntries then
        table.sort(ordered, function(left, right) return left.updatedAt < right.updatedAt end)
        for index = 1, #ordered - maxEntries do
            values[ordered[index].key] = nil
            removed = removed + 1
        end
    end
    if removed > 0 then NoteInvalidation(reason, removed) end
    return removed
end

local function PruneStore(store)
    local now = CacheNow()
    for key, bucket in pairs(store.visuals or {}) do
        local evidence = bucket.evidence
        if evidence then
            local expiredPending = evidence.state == "PENDING"
                and tonumber(evidence.retryAt)
                and now >= tonumber(evidence.retryAt)
            local expiredUnknown = evidence.state == "UNKNOWN"
                and tonumber(evidence.expiresAt)
                and now >= tonumber(evidence.expiresAt)
            if expiredPending or expiredUnknown then
                InvalidateEvidence(store, key, bucket, expiredPending and "PENDING_RETRY_EXPIRED" or "UNKNOWN_TTL_EXPIRED")
                bucket = store.visuals[key]
            end
        end
        if bucket then
            PruneEntryMap(bucket.prechecks, P.GENERATION_CACHE_PRECHECKS_PER_VISUAL, now, "PRECHECK_TTL_OR_LRU")
            PruneEntryMap(bucket.eligibility, P.GENERATION_CACHE_ELIGIBILITY_PER_VISUAL, now, "ELIGIBILITY_TTL_OR_LRU")
            RemoveBucketIfEmpty(store, key, bucket)
        end
    end
end

local function PutEvidenceRaw(store, source, result, candidateCount, evidenceVersion, migrated)
    local key = VisualKey(source)
    if not key or not result then return false end
    local bucket = store.visuals[key] or {}
    store.visuals[key] = bucket
    local now = CacheNow()
    local state = result.expansionID ~= nil and "RESOLVED" or (result.pending and "PENDING" or "UNKNOWN")
    local record = {
        evidenceVersion = tonumber(evidenceVersion) or tonumber(source.eraEvidenceVersion) or 0,
        visualID = tonumber(source.visualID),
        manifestVersion = tonumber(source.eraManifestVersion) or 0,
        manifestSignature = ManifestSignature(source),
        fingerprint = P.GetPersistentEraFingerprint(source),
        state = state,
        expansionID = result.expansionID,
        method = result.method,
        label = result.label,
        sourceID = result.sourceID,
        itemID = result.itemID,
        candidateCount = candidateCount or result.candidateCount,
        reason = result.reason,
        pending = result.pending == true,
        unknown = result.unknown == true,
        pendingItemIDs = CopyNumericList(result.pendingItemIDs),
        trackingPending = result.trackingPending == true,
        retryAt = result.pending and (tonumber(source.eraEvidenceRetryAt) or (now + 30)) or nil,
        expiresAt = state == "UNKNOWN" and (now + P.GENERATION_CACHE_UNKNOWN_TTL_SECONDS) or nil,
        updatedAt = now,
        lastUsedAt = now,
    }
    local added = bucket.evidence == nil
    bucket.evidence = record
    bucket.updatedAt = now
    store.updatedAt = now
    if migrated then
        if added then Stats().migratedEvidence = Stats().migratedEvidence + 1 end
    elseif added then
        Stats().addedEvidence = Stats().addedEvidence + 1
    end
    return true
end

local function MigrateLegacySourceFields(cache, store)
    local seen = {}
    for _, sources in pairs(cache and cache.bySlot or {}) do
        for _, source in ipairs(sources or {}) do
            local key = VisualKey(source)
            if key and not seen[key] and (source.eraEvidenceState
                or source.eraEvidenceExpansionID ~= nil
                or source.eraEvidencePending == true
                or source.eraEvidenceUnknown == true) then
                seen[key] = true
                PutEvidenceRaw(store, source, {
                    expansionID = source.eraEvidenceExpansionID,
                    method = source.eraEvidenceMethod,
                    label = source.eraEvidenceLabel,
                    sourceID = source.eraEvidenceSourceID,
                    itemID = source.eraEvidenceItemID,
                    candidateCount = source.eraEvidenceCandidateCount,
                    reason = source.eraEvidenceReason,
                    pending = source.eraEvidencePending == true,
                    unknown = source.eraEvidenceUnknown == true,
                    pendingItemIDs = source.eraEvidencePendingItemIDs,
                    trackingPending = source.eraEvidenceTrackingPending == true,
                }, source.eraEvidenceCandidateCount, source.eraEvidenceVersion, true)
            end
        end
    end
end

function P.EnsurePersistentGenerationCache()
    local store, cache = EnsureStoreRaw()
    if not P.generationCacheSessionInitialized then
        P.generationCacheSessionInitialized = true
        PruneStore(store)
        local evidence, prechecks, eligibility = CountStore(store)
        local stats = Stats()
        stats.loadedEvidence = evidence
        stats.loadedPrechecks = prechecks
        stats.loadedEligibility = eligibility
        MigrateLegacySourceFields(cache, store)
    end
    return store
end

local function GetBucket(source, create)
    local store = P.EnsurePersistentGenerationCache()
    local key = VisualKey(source)
    if not key then return store, nil, nil end
    local bucket = store.visuals[key]
    if not bucket and create then
        bucket = {}
        store.visuals[key] = bucket
    end
    return store, bucket, key
end

function P.StorePersistentEraEvidence(source, result, candidateCount, evidenceVersion)
    local store = P.EnsurePersistentGenerationCache()
    return PutEvidenceRaw(store, source, result, candidateCount, evidenceVersion, false)
end

function P.GetPersistentEraEvidence(source, evidenceVersion)
    local store, bucket, key = GetBucket(source, false)
    local record = bucket and bucket.evidence
    if not record then return nil end
    if record.evidenceVersion ~= tonumber(evidenceVersion)
        or record.visualID ~= tonumber(source.visualID)
        or record.manifestVersion ~= (tonumber(source.eraManifestVersion) or 0)
        or record.manifestSignature ~= ManifestSignature(source)
        or record.fingerprint ~= P.GetPersistentEraFingerprint(source)
    then
        InvalidateEvidence(store, key, bucket, "EVIDENCE_IDENTITY_CHANGED")
        return nil
    end
    local now = CacheNow()
    if record.state == "PENDING" and tonumber(record.retryAt) and now >= tonumber(record.retryAt) then
        InvalidateEvidence(store, key, bucket, "PENDING_RETRY_EXPIRED")
        return nil
    end
    if record.state == "UNKNOWN" and tonumber(record.expiresAt) and now >= tonumber(record.expiresAt) then
        InvalidateEvidence(store, key, bucket, "UNKNOWN_TTL_EXPIRED")
        return nil
    end
    record.lastUsedAt = now
    bucket.updatedAt = now
    return {
        expansionID = record.expansionID,
        method = record.method,
        label = record.label,
        sourceID = record.sourceID,
        itemID = record.itemID,
        candidateCount = record.candidateCount,
        reason = record.reason,
        pending = record.pending == true,
        unknown = record.unknown == true,
        pendingItemIDs = CopyNumericList(record.pendingItemIDs),
        trackingPending = record.trackingPending == true,
        cached = true,
        persistent = true,
    }, record
end

local function TrimBucketMap(bucket, field, maxEntries, reason)
    local values = bucket[field]
    if CountMap(values) <= maxEntries then return end
    PruneEntryMap(values, maxEntries, CacheNow(), reason)
end

function P.StorePersistentGenerationPrecheck(source, key, eligible, kind, reason)
    local store, bucket = GetBucket(source, true)
    if not bucket or not key then return end
    bucket.prechecks = bucket.prechecks or {}
    local added = bucket.prechecks[key] == nil
    bucket.prechecks[key] = {
        eligible = eligible == true,
        kind = kind,
        reason = reason,
        sourceIdentity = P.GetStableGenerationSourceIdentity(source),
        fingerprint = P.GetPersistentGenerationFingerprint(source),
        updatedAt = CacheNow(),
    }
    bucket.updatedAt = CacheNow()
    store.updatedAt = CacheNow()
    if added then Stats().addedPrechecks = Stats().addedPrechecks + 1 end
    TrimBucketMap(bucket, "prechecks", P.GENERATION_CACHE_PRECHECKS_PER_VISUAL, "PRECHECK_LRU")
end

function P.GetPersistentGenerationPrecheck(source, key)
    local _, bucket = GetBucket(source, false)
    local record = bucket and bucket.prechecks and bucket.prechecks[key]
    if not record then return nil end
    if record.sourceIdentity ~= P.GetStableGenerationSourceIdentity(source)
        or record.fingerprint ~= P.GetPersistentGenerationFingerprint(source)
    then
        bucket.prechecks[key] = nil
        NoteInvalidation("PRECHECK_IDENTITY_CHANGED", 1)
        return nil
    end
    record.updatedAt = CacheNow()
    return record
end

function P.StorePersistentGenerationEligibility(source, key, eligible, kind, reason)
    local store, bucket = GetBucket(source, true)
    if not bucket or not key then return end
    bucket.eligibility = bucket.eligibility or {}
    local added = bucket.eligibility[key] == nil
    bucket.eligibility[key] = {
        eligible = eligible == true,
        kind = kind,
        reason = reason,
        sourceIdentity = P.GetStableGenerationSourceIdentity(source),
        fingerprint = P.GetPersistentGenerationFingerprint(source),
        updatedAt = CacheNow(),
    }
    bucket.updatedAt = CacheNow()
    store.updatedAt = CacheNow()
    if added then Stats().addedEligibility = Stats().addedEligibility + 1 end
    TrimBucketMap(bucket, "eligibility", P.GENERATION_CACHE_ELIGIBILITY_PER_VISUAL, "ELIGIBILITY_LRU")
end

function P.GetPersistentGenerationEligibility(source, key)
    local _, bucket = GetBucket(source, false)
    local record = bucket and bucket.eligibility and bucket.eligibility[key]
    if not record then return nil end
    if record.sourceIdentity ~= P.GetStableGenerationSourceIdentity(source)
        or record.fingerprint ~= P.GetPersistentGenerationFingerprint(source)
    then
        bucket.eligibility[key] = nil
        NoteInvalidation("ELIGIBILITY_IDENTITY_CHANGED", 1)
        return nil
    end
    record.updatedAt = CacheNow()
    return record
end

function P.InvalidatePersistentGenerationCache(source, reason)
    local store, bucket, key = GetBucket(source, false)
    if not bucket then return end
    local removed = (bucket.evidence and 1 or 0) + CountMap(bucket.prechecks) + CountMap(bucket.eligibility)
    store.visuals[key] = nil
    NoteInvalidation(reason or "SOURCE_INVALIDATED", removed)
end

function P.GetPersistentGenerationCacheRecord(source)
    local store, bucket, key = GetBucket(source, false)
    return bucket and bucket.evidence or nil, bucket, store, key
end

function P.InvalidatePersistentEraEvidence(source, reason)
    local store, bucket, key = GetBucket(source, false)
    if not bucket or not bucket.evidence then return 0 end
    local removed = 1 + CountMap(bucket.eligibility)
    InvalidateEvidence(store, key, bucket, reason or "ERA_EVIDENCE_INVALIDATED")
    return removed
end

function P.RestorePersistentGenerationFields(source, evidenceVersion)
    local evidence = P.GetPersistentEraEvidence(source, evidenceVersion)
    local evidenceRestored = evidence ~= nil
    if evidence then
        source.eraEvidenceVersion = evidenceVersion
        source.eraEvidenceVisualID = source.visualID
        source.eraEvidenceManifestVersion = source.eraManifestVersion
        source.eraEvidenceManifestSignature = ManifestSignature(source)
        source.eraEvidenceMetadataRevision = tonumber(source.metadataRevision) or 0
        source.eraEvidenceCandidateCount = evidence.candidateCount
        source.eraEvidenceExpansionID = evidence.expansionID
        source.eraEvidenceMethod = evidence.method
        source.eraEvidenceLabel = evidence.label
        source.eraEvidenceSourceID = evidence.sourceID
        source.eraEvidenceItemID = evidence.itemID
        source.eraEvidenceReason = evidence.reason
        source.eraEvidencePending = evidence.pending == true
        source.eraEvidenceUnknown = evidence.unknown == true
        source.eraEvidencePendingItemIDs = CopyNumericList(evidence.pendingItemIDs)
        source.eraEvidenceTrackingPending = evidence.trackingPending == true
        source.eraEvidenceState = evidence.expansionID ~= nil and "RESOLVED"
            or (evidence.pending and "PENDING" or "UNKNOWN")
    end
    if P.NotePersistentGenerationCacheRestore then
        P.NotePersistentGenerationCacheRestore(source, evidenceRestored, false, false)
    end
    return evidenceRestored
end

function P.GetPersistentGenerationCacheCounts()
    return CountStore(P.EnsurePersistentGenerationCache())
end

function P.GetGenerationCacheSessionStats()
    return Stats()
end

function P.GetGenerationCacheVisualKey(source)
    return VisualKey(source)
end
