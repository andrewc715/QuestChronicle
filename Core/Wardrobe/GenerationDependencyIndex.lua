local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.pendingEraDependenciesByItem = P.pendingEraDependenciesByItem or {}
P.pendingEraItemsByVisual = P.pendingEraItemsByVisual or {}
P.currentGenerationSourcesByVisual = P.currentGenerationSourcesByVisual or {}

local function VisualKey(sourceOrID)
    if P.GetGenerationCacheVisualKey then return P.GetGenerationCacheVisualKey(sourceOrID) end
    local visualID = type(sourceOrID) == "table" and sourceOrID.visualID or sourceOrID
    visualID = tonumber(visualID)
    return visualID and visualID > 0 and tostring(visualID) or nil
end

local function RemoveVisualFromItem(itemID, visualKey)
    local itemKey = tostring(tonumber(itemID) or "")
    local visuals = P.pendingEraDependenciesByItem[itemKey]
    if not visuals then return end
    visuals[visualKey] = nil
    if not next(visuals) then P.pendingEraDependenciesByItem[itemKey] = nil end
end

function P.RemovePersistentEraDependencies(sourceOrKey)
    local visualKey = type(sourceOrKey) == "string" and sourceOrKey or VisualKey(sourceOrKey)
    if not visualKey then return end
    for itemID in pairs(P.pendingEraItemsByVisual[visualKey] or {}) do
        RemoveVisualFromItem(itemID, visualKey)
    end
    P.pendingEraItemsByVisual[visualKey] = nil
end

function P.IndexPersistentEraDependencies(sourceOrKey, record)
    local visualKey = type(sourceOrKey) == "string" and sourceOrKey or VisualKey(sourceOrKey)
    if not visualKey then return end
    P.RemovePersistentEraDependencies(visualKey)
    local itemSet = {}
    for _, itemID in ipairs(record and record.pendingItemIDs or {}) do
        itemID = tonumber(itemID)
        if itemID and itemID > 0 then
            itemSet[itemID] = true
            local itemKey = tostring(itemID)
            local visuals = P.pendingEraDependenciesByItem[itemKey]
            if not visuals then
                visuals = {}
                P.pendingEraDependenciesByItem[itemKey] = visuals
            end
            visuals[visualKey] = true
        end
    end
    if next(itemSet) then P.pendingEraItemsByVisual[visualKey] = itemSet end
end

function P.RebuildPersistentEraDependencyIndex(store)
    P.pendingEraDependenciesByItem = {}
    P.pendingEraItemsByVisual = {}
    for visualKey, bucket in pairs(store and store.visuals or {}) do
        if bucket.evidence then P.IndexPersistentEraDependencies(visualKey, bucket.evidence) end
    end
end

function P.ResetCurrentGenerationSourceIndex()
    P.currentGenerationSourcesByVisual = {}
end

function P.RegisterCurrentGenerationSource(source)
    local visualKey = VisualKey(source)
    if visualKey and source then P.currentGenerationSourcesByVisual[visualKey] = source end
end

function P.GetPendingEraDependencySources(itemID)
    local results = {}
    local visuals = P.pendingEraDependenciesByItem[tostring(tonumber(itemID) or "")] or {}
    for visualKey in pairs(visuals) do
        local source = P.currentGenerationSourcesByVisual[visualKey]
        if source then results[#results + 1] = source end
    end
    return results
end

function P.PersistentEraEvidenceDependsOnItem(source, itemID)
    local record = P.GetPersistentGenerationCacheRecord and
        P.GetPersistentGenerationCacheRecord(source) or nil
    itemID = tonumber(itemID)
    if not record or not itemID then return false end
    for _, value in ipairs(record.pendingItemIDs or {}) do
        if tonumber(value) == itemID then return true end
    end
    return false
end
