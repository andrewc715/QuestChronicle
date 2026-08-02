local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.ERA_MANIFEST_VERSION = 2
P.eraItemRequests = P.eraItemRequests or {}

local function AddUnique(list, seen, value)
    value = tonumber(value)
    if value and value > 0 and not seen[value] then
        seen[value] = true
        table.insert(list, value)
    end
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

function P.RequestEraManifestItems(sourceIDs)
    if not C_Item or type(C_Item.RequestLoadItemDataByID) ~= "function" then return end
    for _, sourceID in ipairs(sourceIDs or {}) do
        local itemID
        if C_TransmogCollection and type(C_TransmogCollection.GetSourceItemID) == "function" then
            itemID = P.SafeCall(C_TransmogCollection.GetSourceItemID, sourceID)
        end
        itemID = tonumber(itemID)
        if itemID and itemID > 0 and not P.eraItemRequests[itemID] then
            P.eraItemRequests[itemID] = true
            P.SafeCall(C_Item.RequestLoadItemDataByID, itemID)
        end
    end
end

function P.AttachEraSourceManifest(source)
    if not source then return end
    source.eraManifestVersion = P.ERA_MANIFEST_VERSION
    source.eraSourceIDs = P.BuildEraSourceManifest(source)

    -- Evidence is derived from this exact source manifest. A scan or schema
    -- migration must invalidate any conclusion produced from an older list.
    source.eraEvidenceVersion = nil
    source.eraEvidenceVisualID = nil
    source.eraEvidenceExpansionID = nil
    source.eraEvidenceMethod = nil
    source.eraEvidenceLabel = nil
    source.eraEvidenceSourceID = nil
    source.eraEvidenceItemID = nil
    source.eraEvidenceCandidateCount = nil

    P.RequestEraManifestItems(source.eraSourceIDs)
end
