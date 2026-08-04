local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local A = P._GenerationCacheStoreAccess
local CacheNow, CountMap, GetBucket = A.CacheNow, A.CountMap, A.GetBucket
local NoteInvalidation, PruneEntryMap, Stats = A.NoteInvalidation, A.PruneEntryMap, A.Stats
local InvalidateEvidence = A.InvalidateEvidence
local VisualKey = A.VisualKey

local function TrimBucketMap(bucket, field, maxEntries, reason)
    local values = bucket[field]
    local before = CountMap(values)
    if before <= maxEntries then return end
    PruneEntryMap(values, maxEntries, CacheNow(), reason)
    local removed = before - CountMap(values)
    if removed > 0 and P.AdjustGenerationCacheCountLedger then
        P.AdjustGenerationCacheCountLedger(0, field == "prechecks" and -removed or 0, field == "eligibility" and -removed or 0)
    end
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
    if added then
        Stats().addedPrechecks = Stats().addedPrechecks + 1
        if P.AdjustGenerationCacheCountLedger then P.AdjustGenerationCacheCountLedger(0, 1, 0) end
    end
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
        if P.AdjustGenerationCacheCountLedger then P.AdjustGenerationCacheCountLedger(0, -1, 0) end
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
    if added then
        Stats().addedEligibility = Stats().addedEligibility + 1
        if P.AdjustGenerationCacheCountLedger then P.AdjustGenerationCacheCountLedger(0, 0, 1) end
    end
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
        if P.AdjustGenerationCacheCountLedger then P.AdjustGenerationCacheCountLedger(0, 0, -1) end
        NoteInvalidation("ELIGIBILITY_IDENTITY_CHANGED", 1)
        return nil
    end
    record.updatedAt = CacheNow()
    return record
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

function P.InvalidatePersistentGenerationEligibilityForSource(source, reason)
    local store, bucket = GetBucket(source, false)
    if not bucket then return 0 end
    local removed = CountMap(bucket.eligibility)
    bucket.eligibility = nil
    if removed > 0 then
        if P.AdjustGenerationCacheCountLedger then P.AdjustGenerationCacheCountLedger(0, 0, -removed) end
        NoteInvalidation(reason or "EVIDENCE_OUTCOME_CHANGED", removed)
        Stats().downstreamRecordsInvalidated =
            Stats().downstreamRecordsInvalidated + removed
    end
    store.updatedAt = CacheNow()
    return removed
end

function P.GetPersistentGenerationCacheRecordByVisual(visualID)
    local store = P.EnsurePersistentGenerationCache()
    local key = VisualKey(visualID)
    local bucket = key and store.visuals[key] or nil
    return bucket and bucket.evidence or nil, bucket, store, key
end

function P.TouchPersistentEraEvidenceRecord(source, record)
    local store, bucket, key = GetBucket(source, false)
    if not bucket or bucket.evidence ~= record then return false end
    record.updatedAt = CacheNow()
    record.lastUsedAt = record.updatedAt
    bucket.updatedAt = record.updatedAt
    store.updatedAt = record.updatedAt
    if P.IndexPersistentEraDependencies then P.IndexPersistentEraDependencies(key, record) end
    return true
end

