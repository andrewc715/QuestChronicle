local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

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

local function LocalPendingDependsOnItem(source, itemID)
    return source and source.eraEvidenceState == "PENDING"
        and ContainsItem(source.eraEvidencePendingItemIDs, itemID)
end

local function EvidenceDependsOnChangedItem(evidence, itemID)
    if not evidence then return false end
    return evidence.method == "item" and tonumber(evidence.itemID) == tonumber(itemID)
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
    if evidence and evidence.state == "PENDING"
        and ContainsItem(evidence.pendingItemIDs, itemID)
        and loaded
    then
        P.InvalidatePersistentEraEvidence(source, "ITEM_DATA_PENDING_RESOLVED")
        P.NoteGenerationItemEvent("reopened", 1)
        return true, "PENDING_REOPENED"
    end

    if not evidence and LocalPendingDependsOnItem(source, itemID) and loaded then
        P.NoteGenerationItemEvent("reopened", 1)
        return true, "LOCAL_PENDING_REOPENED"
    end

    P.NoteGenerationItemEvent("ignored", 1)
    return false, evidence and "STABLE_OR_UNRELATED" or "NO_EVIDENCE"
end
