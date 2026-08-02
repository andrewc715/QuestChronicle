local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.ERA_MANIFEST_VERSION = 3
P.previousGenerationCachesByVisual = nil
P.eraItemRequests = P.eraItemRequests or {}
P.itemMetadataWatch = P.itemMetadataWatch or {}
P.pendingItemMetadata = P.pendingItemMetadata or {}
P.itemMetadataBatchScheduled = false
P.metadataRefreshActive = false

local function AddUnique(list, seen, value)
    value = tonumber(value)
    if value and value > 0 and not seen[value] then
        seen[value] = true
        table.insert(list, value)
    end
end

local function IsGenericName(value)
    return value == nil or tostring(value):match("^Appearance %d+$") ~= nil
end

local function ClearSourceGenerationFields(source)
    if not source then return end
    source.eraEvidenceVersion = nil
    source.eraEvidenceVisualID = nil
    source.eraEvidenceManifestVersion = nil
    source.eraEvidenceManifestSignature = nil
    source.eraEvidenceMetadataRevision = nil
    source.eraEvidenceState = nil
    source.eraEvidenceExpansionID = nil
    source.eraEvidenceMethod = nil
    source.eraEvidenceLabel = nil
    source.eraEvidenceSourceID = nil
    source.eraEvidenceItemID = nil
    source.eraEvidenceCandidateCount = nil
    source.eraEvidenceReason = nil
    source.eraEvidencePending = nil
    source.eraEvidenceUnknown = nil
    source.eraEvidenceRetryAt = nil
    source.persistentEraFingerprint = nil
    source.persistentGenerationFingerprint = nil
    source.generationEligibilityKey = nil
    source.generationEligibilityEligible = nil
    source.generationEligibilityKind = nil
    source.generationEligibilityReason = nil
    source.generationPrecheckKey = nil
    source.generationPrecheckEligible = nil
    source.generationPrecheckKind = nil
    source.generationPrecheckReason = nil
end

function P.InvalidateSourceEraEvidence(source, reason, preservePersistent)
    if not source then return end
    ClearSourceGenerationFields(source)
    if not preservePersistent then
        if (reason == "ITEM_DATA_LOADED" or reason == "ITEM_METADATA_CHANGED")
            and P.InvalidatePersistentGenerationCacheForItemData
        then
            P.InvalidatePersistentGenerationCacheForItemData(source, reason)
        elseif P.InvalidatePersistentGenerationCache then
            P.InvalidatePersistentGenerationCache(source, reason or "SOURCE_METADATA_CHANGED")
        end
    end
end


function P.GetEraManifestSignature(sourceIDs)
    local parts = {}
    for _, sourceID in ipairs(sourceIDs or {}) do
        parts[#parts + 1] = tostring(sourceID)
    end
    return table.concat(parts, ",")
end

local generationCacheFields = {
    "eraEvidenceVersion", "eraEvidenceVisualID", "eraEvidenceManifestVersion",
    "eraEvidenceManifestSignature", "eraEvidenceMetadataRevision", "eraEvidenceState",
    "eraEvidenceExpansionID", "eraEvidenceMethod", "eraEvidenceLabel",
    "eraEvidenceSourceID", "eraEvidenceItemID", "eraEvidenceCandidateCount",
    "eraEvidenceReason", "eraEvidencePending", "eraEvidenceUnknown", "eraEvidenceRetryAt",
    "generationEligibilityKey", "generationEligibilityEligible", "generationEligibilityKind",
    "generationEligibilityReason", "generationPrecheckKey", "generationPrecheckEligible",
    "generationPrecheckKind", "generationPrecheckReason",
}

function P.CaptureAppearanceGenerationCaches(cache)
    local snapshots = {}
    for _, sources in pairs(cache and cache.bySlot or {}) do
        for _, source in ipairs(sources or {}) do
            local visualID = tonumber(source.visualID)
            if visualID and (source.eraEvidenceVersion or source.generationPrecheckKey or source.generationEligibilityKey) then
                local snapshot = { manifestSignature = source.eraManifestSignature
                    or P.GetEraManifestSignature(source.eraSourceIDs) }
                for _, field in ipairs(generationCacheFields) do snapshot[field] = source[field] end
                snapshot.eraEvidenceManifestSignature = snapshot.eraEvidenceManifestSignature or snapshot.manifestSignature
                if not snapshot.eraEvidenceState and snapshot.eraEvidenceExpansionID ~= nil then
                    snapshot.eraEvidenceState = "RESOLVED"
                end
                snapshots[visualID] = snapshot
            end
        end
    end
    P.previousGenerationCachesByVisual = snapshots
end

function P.DiscardAppearanceGenerationCaches()
    P.previousGenerationCachesByVisual = nil
end

function P.RestoreAppearanceGenerationCache(source)
    local restored = false
    local snapshot = source and P.previousGenerationCachesByVisual
        and P.previousGenerationCachesByVisual[tonumber(source.visualID)]
    if snapshot then
        local signature = source.eraManifestSignature or P.GetEraManifestSignature(source.eraSourceIDs)
        if snapshot.manifestSignature == signature then
            for _, field in ipairs(generationCacheFields) do source[field] = snapshot[field] end
            source.eraEvidenceMetadataRevision = tonumber(source.metadataRevision) or 0
            restored = true
        end
    end
    if P.RestorePersistentGenerationFields then
        local zonePrivate = QC.ZoneStyle and QC.ZoneStyle._Private
        local evidenceVersion = zonePrivate and zonePrivate.ERA_EVIDENCE_VERSION or 2
        restored = P.RestorePersistentGenerationFields(source, evidenceVersion) or restored
    end
    return restored
end

function P.BuildEraSourceManifest(source)
    local sourceIDs, seen = {}, {}
    if not source then return sourceIDs end

    AddUnique(sourceIDs, seen, source.sourceID)
    if C_TransmogCollection and type(C_TransmogCollection.GetAllAppearanceSources) == "function" and source.visualID then
        for _, sourceID in ipairs(P.SafeCall(C_TransmogCollection.GetAllAppearanceSources, source.visualID) or {}) do
            AddUnique(sourceIDs, seen, sourceID)
        end
    end
    table.sort(sourceIDs)
    return sourceIDs
end

function P.BuildEraItemManifest(sourceIDs)
    local itemIDs, seen = {}, {}
    for _, sourceID in ipairs(sourceIDs or {}) do
        local itemID
        if C_TransmogCollection and type(C_TransmogCollection.GetSourceItemID) == "function" then
            itemID = P.SafeCall(C_TransmogCollection.GetSourceItemID, sourceID)
        end
        AddUnique(itemIDs, seen, itemID)
    end
    table.sort(itemIDs)
    return itemIDs
end

function P.RequestAppearanceItemData(itemID)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 or P.eraItemRequests[itemID] then return end
    if not C_Item or type(C_Item.RequestLoadItemDataByID) ~= "function" then return end
    P.eraItemRequests[itemID] = true
    P.SafeCall(C_Item.RequestLoadItemDataByID, itemID)
end

function P.RequestEraManifestItems(itemIDs)
    for _, itemID in ipairs(itemIDs or {}) do
        P.RequestAppearanceItemData(itemID)
    end
end

function P.EnsureEraSourceManifest(source, invalidate)
    if not source then return end
    local current = source.eraManifestVersion == P.ERA_MANIFEST_VERSION
        and type(source.eraSourceIDs) == "table"
        and type(source.eraItemIDs) == "table"
    if current then return end

    source.eraManifestVersion = P.ERA_MANIFEST_VERSION
    source.eraSourceIDs = P.BuildEraSourceManifest(source)
    source.eraManifestSignature = P.GetEraManifestSignature(source.eraSourceIDs)
    source.eraItemIDs = P.BuildEraItemManifest(source.eraSourceIDs)
    if invalidate ~= false then
        P.InvalidateSourceEraEvidence(source, "ERA_MANIFEST_REBUILT", P.metadataRefreshActive == true)
    end
end

function P.AttachEraSourceManifest(source, requestItems)
    if not source then return end
    source.eraManifestVersion = nil
    P.EnsureEraSourceManifest(source, true)
    if requestItems ~= false then
        P.RequestEraManifestItems(source.eraItemIDs)
    end
end

local function SetIfChanged(source, key, value)
    if value ~= nil and source[key] ~= value then
        source[key] = value
        return true
    end
    return false
end

function P.HydrateSourceItemMetadata(source)
    if not source or not source.itemID then return false, false end
    local itemID = tonumber(source.itemID)
    local getter = C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getter) ~= "function" then return false, false end

    local ok, name, link, quality, itemLevel, requiredLevel, itemType, itemSubType,
        stackCount, equipLocation, icon, sellPrice, classID, subclassID, bindType,
        expansionID = pcall(getter, itemID)
    if not ok or not name then
        source.metadataPending = true
        P.RequestAppearanceItemData(itemID)
        return false, false
    end

    local changed = false
    if IsGenericName(source.name) then changed = SetIfChanged(source, "name", name) or changed end
    changed = SetIfChanged(source, "styleName", name) or changed
    changed = SetIfChanged(source, "styleItemLink", link) or changed
    changed = SetIfChanged(source, "quality", quality) or changed
    changed = SetIfChanged(source, "styleItemType", itemType) or changed
    changed = SetIfChanged(source, "styleItemSubType", itemSubType) or changed
    changed = SetIfChanged(source, "styleEquipLocation", equipLocation) or changed
    changed = SetIfChanged(source, "icon", icon) or changed

    local numericExpansion = expansionID ~= nil and tonumber(expansionID) or nil
    if source.expansionID ~= numericExpansion then
        source.expansionID = numericExpansion
        changed = true
    end
    if source.itemMetadataItemID ~= itemID or source.itemMetadataVerified ~= true then changed = true end
    source.itemMetadataItemID = itemID
    source.itemMetadataVerified = true
    source.metadataPending = nil
    if changed then
        source.metadataRevision = (tonumber(source.metadataRevision) or 0) + 1
        P.InvalidateSourceEraEvidence(source, "ITEM_METADATA_CHANGED", P.metadataRefreshActive == true)
    end
    return true, changed
end

local function WatchItem(itemID, source)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 or not source then return end
    local watchers = P.itemMetadataWatch[itemID]
    if not watchers then
        watchers = setmetatable({}, { __mode = "k" })
        P.itemMetadataWatch[itemID] = watchers
    end
    watchers[source] = true
end

function P.TrackAppearanceMetadata(source, requestManifestItems)
    if not source then return false end
    P.EnsureEraSourceManifest(source, true)
    if source.itemID then WatchItem(source.itemID, source) end
    for _, itemID in ipairs(source.eraItemIDs or {}) do
        WatchItem(itemID, source)
    end

    local loaded, changed = P.HydrateSourceItemMetadata(source)
    if requestManifestItems ~= false then
        for _, itemID in ipairs(source.eraItemIDs or {}) do
            if not loaded or tonumber(itemID) ~= tonumber(source.itemID) then
                P.RequestAppearanceItemData(itemID)
            end
        end
    end
    return changed == true
end

function P.BeginAppearanceMetadataRefresh()
    if P.EnsurePersistentGenerationCache then P.EnsurePersistentGenerationCache() end
    if P.BeginPersistentGenerationCacheScan then P.BeginPersistentGenerationCacheScan() end
    P.CaptureAppearanceGenerationCaches(P.EnsureCache and P.EnsureCache() or nil)
    -- A collection scan reconstructs the watch index as it discovers sources.
    -- Clear it once here instead of rebuilding and hydrating the entire old
    -- cache before the scan, then doing the same work again afterward.
    P.itemMetadataWatch = {}
    P.eraItemRequests = {}
    P.pendingItemMetadata = {}
    P.itemMetadataBatchScheduled = false
    P.metadataRefreshActive = true
end

function P.RestoreAppearanceMetadataWatchIndex(cache)
    P.itemMetadataWatch = {}
    for _, sources in pairs(cache and cache.bySlot or {}) do
        for _, source in ipairs(sources or {}) do
            if source.itemID then WatchItem(source.itemID, source) end
            for _, itemID in ipairs(source.eraItemIDs or {}) do
                WatchItem(itemID, source)
            end
        end
    end
    P.metadataRefreshActive = false
end

local function SortSlotSources(sources)
    table.sort(sources or {}, function(left, right)
        local leftName = string.lower(left.styleName or left.name or "")
        local rightName = string.lower(right.styleName or right.name or "")
        if leftName == rightName then return (left.sourceID or 0) < (right.sourceID or 0) end
        return leftName < rightName
    end)
end

function P.RebuildAppearanceMetadataIndex(cache, sortSources, notify, requestManifestItems)
    P.itemMetadataWatch = {}
    P.eraItemRequests = {}
    local changedSourceIDs = {}
    local changedCount = 0
    for _, sources in pairs(cache and cache.bySlot or {}) do
        for _, source in ipairs(sources or {}) do
            if P.TrackAppearanceMetadata(source, requestManifestItems == true) then
                changedSourceIDs[source.sourceID] = true
                changedCount = changedCount + 1
            end
        end
        if sortSources then SortSlotSources(sources) end
    end
    if notify and changedCount > 0 and QC.Notify then
        QC.Notify("WARDROBE_SOURCE_METADATA_UPDATED", {
            sourceIDs = changedSourceIDs,
            reason = "INDEX_REBUILD",
            changedCount = changedCount,
        })
    end
    P.metadataRefreshActive = false
    return changedCount
end

function P.FinalizeAppearanceMetadataRefresh(cache, sortSources)
    if P.FinishPersistentGenerationCacheScan then P.FinishPersistentGenerationCacheScan() end
    P.DiscardAppearanceGenerationCaches()
    if sortSources then
        for _, sources in pairs(cache and cache.bySlot or {}) do
            SortSlotSources(sources)
        end
    end
    P.metadataRefreshActive = false
end

local function ProcessItemMetadataBatch()
    P.itemMetadataBatchScheduled = false
    local pending = P.pendingItemMetadata
    P.pendingItemMetadata = {}
    local changedSourceIDs, changedItemIDs = {}, {}
    local changedCount = 0

    for itemID in pairs(pending) do
        itemID = tonumber(itemID)
        P.eraItemRequests[itemID] = nil
        changedItemIDs[itemID] = true
        for source in pairs(P.itemMetadataWatch[itemID] or {}) do
            local sourceChanged = false
            if tonumber(source.itemID) == itemID then
                local _, changed = P.HydrateSourceItemMetadata(source)
                sourceChanged = changed == true
            end
            P.InvalidateSourceEraEvidence(
                source, "ITEM_DATA_LOADED", P.metadataRefreshActive == true or Wardrobe.scanning == true
            )
            if source.sourceID and not changedSourceIDs[source.sourceID] then
                changedSourceIDs[source.sourceID] = true
                changedCount = changedCount + 1
            end
            if sourceChanged then source.metadataUpdatedAt = time and time() or 0 end
        end
    end

    if changedCount > 0 and QC.Notify then
        QC.Notify("WARDROBE_SOURCE_METADATA_UPDATED", {
            sourceIDs = changedSourceIDs,
            itemIDs = changedItemIDs,
            reason = "ITEM_DATA_LOADED",
            changedCount = changedCount,
        })
    end
end

function Wardrobe.QueueItemMetadataUpdate(itemID, success, eventName)
    itemID = tonumber(itemID)
    if not itemID or itemID <= 0 then return end
    P.eraItemRequests[itemID] = nil
    P.pendingItemMetadata[itemID] = {
        success = success,
        eventName = eventName,
    }
    if P.itemMetadataBatchScheduled then return end
    P.itemMetadataBatchScheduled = true
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0.05, ProcessItemMetadataBatch)
    else
        ProcessItemMetadataBatch()
    end
end

function Wardrobe.RebuildAppearanceMetadataIndex(sortSources, notify)
    return P.RebuildAppearanceMetadataIndex(P.EnsureCache(), sortSources == true, notify == true, false)
end
