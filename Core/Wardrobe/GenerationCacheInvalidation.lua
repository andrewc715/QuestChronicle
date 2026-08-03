local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local A = P._GenerationCacheStoreAccess

local function Stats()
    return P.GetGenerationCacheSessionStats and P.GetGenerationCacheSessionStats() or nil
end

local function Note(field, count)
    local stats = Stats()
    count = tonumber(count) or 1
    if stats and count > 0 then stats[field] = (tonumber(stats[field]) or 0) + count end
end

function P.NoteGenerationItemEvent(kind, count)
    local fields = {
        ignored = "itemEventsIgnored",
        coalesced = "itemEventsCoalesced",
        reopened = "pendingEvidenceReopened",
        identity = "metadataIdentityChanges",
        failed = "failedItemEventsIgnored",
        callback = "itemCallbacksReceived",
        examined = "dependencyRecordsExamined",
        stillPending = "dependenciesStillPending",
        satisfied = "dependenciesSatisfied",
        unchanged = "evidenceOutcomesUnchanged",
        changed = "evidenceOutcomesChanged",
        downstream = "downstreamRecordsInvalidated",
    }
    local field = fields[kind]
    if field then Note(field, count) end
end

local function ContainsItem(values, itemID)
    itemID = tonumber(itemID)
    if not itemID then return false end
    for _, value in ipairs(values or {}) do
        if tonumber(value) == itemID then return true end
    end
    return false
end

local function RemoveItem(values, itemID)
    local result = {}
    itemID = tonumber(itemID)
    for _, value in ipairs(values or {}) do
        value = tonumber(value)
        if value and value ~= itemID then result[#result + 1] = value end
    end
    table.sort(result)
    return #result > 0 and result or nil
end

function P.BuildStableItemMetadataFingerprint(itemID, expansionID, itemType, itemSubType,
    equipLocation, classID, subclassID)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then return nil end
    return table.concat({
        tostring(itemID), tostring(expansionID or ""), tostring(itemType or ""),
        tostring(itemSubType or ""), tostring(equipLocation or ""),
        tostring(classID or ""), tostring(subclassID or ""),
    }, "|")
end

function P.GetStableItemMetadataFingerprint(itemID)
    itemID = tonumber(itemID)
    local getter = C_Item and C_Item.GetItemInfo or GetItemInfo
    if not itemID or type(getter) ~= "function" then return nil, false end
    local ok, name, _, _, _, _, itemType, itemSubType, _, equipLocation, _, _,
        classID, subclassID, _, expansionID = pcall(getter, itemID)
    if not ok or not name then return nil, false end
    return P.BuildStableItemMetadataFingerprint(
        itemID, expansionID, itemType, itemSubType, equipLocation, classID, subclassID
    ), true
end

local function EvidenceDependsOnChangedItem(evidence, itemID)
    if not evidence then return false end
    return evidence.method == "item" and tonumber(evidence.itemID) == tonumber(itemID)
end

local function UpdateLocalDependencyState(source, record)
    if not source or not record then return end
    source.eraEvidencePendingItemIDs =
        P.CopyGenerationCacheNumericList and
        P.CopyGenerationCacheNumericList(record.pendingItemIDs) or record.pendingItemIDs
    source.eraEvidenceTrackingPending = record.trackingPending == true
    source.eraEvidencePending = record.pending == true
    source.eraEvidenceState = record.state
    source.eraEvidenceRetryAt = record.retryAt
end

local function ResolvePendingDependency(source, record, itemID)
    P.NoteGenerationItemEvent("examined", 1)
    record.pendingItemIDs = RemoveItem(record.pendingItemIDs, itemID)
    P.NoteGenerationItemEvent("satisfied", 1)

    if record.pendingItemIDs then
        record.state = "PENDING_ITEMS"
        record.pending = true
        record.retryAt = (A.CacheNow and A.CacheNow() or 0) +
            (P.GENERATION_CACHE_PENDING_RETRY_SECONDS or 600)
        P.NoteGenerationItemEvent("stillPending", 1)
        P.TouchPersistentEraEvidenceRecord(source, record)
        UpdateLocalDependencyState(source, record)
        return false, "DEPENDENCIES_REMAIN"
    end

    if record.trackingPending == true then
        record.state = "TRACKING_ONLY"
        record.pending = true
        record.retryAt = (A.CacheNow and A.CacheNow() or 0) +
            (P.GENERATION_CACHE_TRACKING_RETRY_SECONDS or 1800)
        P.NoteGenerationItemEvent("unchanged", 1)
        P.TouchPersistentEraEvidenceRecord(source, record)
        UpdateLocalDependencyState(source, record)
        return false, "TRACKING_ONLY"
    end

    record.state = "STALE"
    record.pending = true
    record.retryAt = nil
    P.TouchPersistentEraEvidenceRecord(source, record)
    UpdateLocalDependencyState(source, record)
    P.NoteGenerationItemEvent("reopened", 1)
    if P.QueuePendingEraEvidenceReevaluation then
        P.QueuePendingEraEvidenceReevaluation(source, record)
        return false, "REEVALUATION_QUEUED"
    end
    return false, "REEVALUATION_DEFERRED"
end

function P.InvalidatePersistentGenerationCacheForItemData(source, reason, itemID, eventInfo)
    eventInfo = eventInfo or {}
    itemID = tonumber(itemID)
    local evidence = P.GetPersistentGenerationCacheRecord
        and P.GetPersistentGenerationCacheRecord(source) or nil
    local identityChanged = reason == "ITEM_METADATA_IDENTITY_CHANGED"
        or eventInfo.identityChanged == true

    if identityChanged then
        if EvidenceDependsOnChangedItem(evidence, itemID) then
            P.InvalidatePersistentEraEvidence(source, "ITEM_METADATA_IDENTITY_CHANGED")
            P.NoteGenerationItemEvent("identity", 1)
            return true, "IDENTITY_CHANGED"
        end
        P.NoteGenerationItemEvent("ignored", 1)
        return false, "STABLE_EVIDENCE"
    end

    if reason ~= "ITEM_DATA_LOADED" then return false, "UNRELATED" end
    if eventInfo.success == false then
        P.NoteGenerationItemEvent("failed", 1)
        return false, "LOAD_FAILED"
    end

    local loaded = eventInfo.loaded == true
    if not loaded and eventInfo.fingerprint == nil then
        local _, isLoaded = P.GetStableItemMetadataFingerprint(itemID)
        loaded = isLoaded == true
    end
    if not loaded then
        P.NoteGenerationItemEvent("stillPending", 1)
        return false, "DATA_STILL_PENDING"
    end

    if evidence and ContainsItem(evidence.pendingItemIDs, itemID) then
        return ResolvePendingDependency(source, evidence, itemID)
    end

    P.NoteGenerationItemEvent("ignored", 1)
    return false, evidence and "STABLE_OR_UNRELATED" or "NO_EVIDENCE"
end
