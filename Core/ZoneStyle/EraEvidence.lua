local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private

P.ERA_EVIDENCE_VERSION = 2
P.ERA_MANIFEST_VERSION = 3

-- Exact corrections remain intentionally small and reviewable. They protect
-- known legacy item records whose sparse expansion field is incorrect while
-- the broader resolver uses sets, source tracking, encounters, and all visual
-- siblings for the rest of the collection.
P.curatedEraItemIDs = {
    [89561] = 4, -- Green Belt of Quiet Understanding
    [89565] = 4, -- Biting Yellow Belt
}

local evidenceRanks = {
    curated = 100,
    set = 90,
    tracking = 80,
    encounter = 70,
    item = 40,
}

local function Evidence(expansionID, method, label, sourceID, itemID, rank)
    expansionID = tonumber(expansionID)
    if expansionID == nil then return nil end
    return {
        expansionID = expansionID,
        method = method,
        label = label,
        sourceID = tonumber(sourceID),
        itemID = tonumber(itemID),
        rank = rank or evidenceRanks[method] or 0,
    }
end

local function PreferStronger(current, candidate)
    if not candidate then return current end
    if not current then return candidate end
    if candidate.rank ~= current.rank then
        return candidate.rank > current.rank and candidate or current
    end
    if candidate.expansionID ~= current.expansionID then
        -- Conflicting evidence for one source fails toward the later era.
        return candidate.expansionID > current.expansionID and candidate or current
    end
    return current
end

function P.ResolveEraFromText(text)
    text = P.Normalize(text)
    if text == "" then return nil end

    for expansionID = 11, 0, -1 do
        local info = ZoneStyle.expansions[expansionID]
        if info and P.TextMatchesAny(text, { info.label, info.shortLabel }) then
            return expansionID
        end
    end
    for _, rule in ipairs(P.eraRules or {}) do
        if P.TextMatchesAny(text, rule.match) then
            return rule.maxExpansionID
        end
    end
    return nil
end

local function AddSourceID(list, seen, value)
    value = tonumber(value)
    if value and value > 0 and not seen[value] then
        seen[value] = true
        table.insert(list, value)
    end
end

function P.GetAppearanceEraSourceIDs(source)
    local sourceIDs, seen = {}, {}
    AddSourceID(sourceIDs, seen, source and source.sourceID)

    if source and source.eraManifestVersion == P.ERA_MANIFEST_VERSION and type(source.eraSourceIDs) == "table" then
        for _, sourceID in ipairs(source.eraSourceIDs) do AddSourceID(sourceIDs, seen, sourceID) end
    elseif source and source.visualID and C_TransmogCollection and type(C_TransmogCollection.GetAllAppearanceSources) == "function" then
        for _, sourceID in ipairs(P.SafeCall(C_TransmogCollection.GetAllAppearanceSources, source.visualID) or {}) do
            AddSourceID(sourceIDs, seen, sourceID)
        end
    end
    table.sort(sourceIDs)
    return sourceIDs
end

function P.BuildEraCandidate(source, sourceID)
    local info
    if source and tonumber(source.sourceID) == tonumber(sourceID) then
        info = source
    elseif C_TransmogCollection and type(C_TransmogCollection.GetSourceInfo) == "function" then
        info = P.SafeCall(C_TransmogCollection.GetSourceInfo, sourceID)
    end

    local itemID = info and info.itemID
    if not itemID and C_TransmogCollection and type(C_TransmogCollection.GetSourceItemID) == "function" then
        itemID = P.SafeCall(C_TransmogCollection.GetSourceItemID, sourceID)
    end
    return {
        sourceID = tonumber(sourceID),
        visualID = source and source.visualID,
        itemID = tonumber(itemID),
        sourceType = info and info.sourceType or (source and source.sourceType),
        name = info and info.name or (source and source.name),
    }
end

local function GetCuratedEvidence(candidate)
    local expansionID = P.curatedEraItemIDs[tonumber(candidate.itemID)]
    if expansionID ~= nil then
        local info = ZoneStyle.expansions[expansionID]
        return Evidence(expansionID, "curated", "curated correction: " .. tostring(info and info.label or expansionID), candidate.sourceID, candidate.itemID)
    end
    local origin = P.GetCuratedSourceOrigin(candidate)
    if origin and origin.expansionID ~= nil then
        return Evidence(origin.expansionID, "curated", tostring(origin.label or "curated source"), candidate.sourceID, candidate.itemID)
    end
end

local function GetSetEvidence(candidate)
    if not C_TransmogSets or type(C_TransmogSets.GetSetsContainingSourceID) ~= "function" or type(C_TransmogSets.GetSetInfo) ~= "function" then
        return nil
    end
    local best
    for _, setID in ipairs(P.SafeCall(C_TransmogSets.GetSetsContainingSourceID, candidate.sourceID) or {}) do
        local info = P.SafeCall(C_TransmogSets.GetSetInfo, setID)
        if type(info) == "table" and info.expansionID ~= nil then
            local label = string.format("set %s", tostring(info.name or setID))
            best = PreferStronger(best, Evidence(info.expansionID, "set", label, candidate.sourceID, candidate.itemID))
        end
    end
    return best
end

local function GetTrackingEvidence(candidate)
    local trackingAvailable = C_ContentTracking and type(C_ContentTracking.GetBestMapForTrackable) == "function" and P.GetAppearanceTrackingType() ~= nil
    if not trackingAvailable then return nil, false end

    local origin = P.GetTrackedSourceOrigin(candidate)
    if origin then
        local expansionID = origin.expansionID or P.ResolveEraFromText(table.concat({ origin.label or "", origin.mapName or "" }, " "))
        if expansionID ~= nil then
            return Evidence(expansionID, "tracking", "WoW tracking: " .. tostring(origin.label or origin.mapName or "tracked source"), candidate.sourceID, candidate.itemID), false
        end
    end

    -- false means Blizzard gave a stable Failure. nil means DataPending and is
    -- retried rather than allowing weak item metadata to pass prematurely.
    return nil, P.trackedOriginCache[candidate.sourceID] == nil
end

local function GetEncounterEvidence(candidate)
    if not C_TransmogCollection or type(C_TransmogCollection.GetAppearanceSourceDrops) ~= "function" then return nil end
    local parts = {}
    for _, drop in ipairs(P.SafeCall(C_TransmogCollection.GetAppearanceSourceDrops, candidate.sourceID) or {}) do
        table.insert(parts, drop.instance or "")
        table.insert(parts, drop.encounter or "")
        for _, tier in ipairs(drop.tiers or {}) do table.insert(parts, tier) end
    end
    local text = table.concat(parts, " ")
    local expansionID = P.ResolveEraFromText(text)
    if expansionID ~= nil then
        return Evidence(expansionID, "encounter", "encounter journal", candidate.sourceID, candidate.itemID)
    end
end

local function GetItemEvidence(candidate)
    if not candidate.itemID then return nil, false end
    local getter = C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getter) ~= "function" then return nil, false end

    -- C_Item.GetItemInfo returns expansionID as its fifteenth result after
    -- the item name. Keep the tuple explicit so future API changes are easier
    -- to audit than a row of anonymous placeholders.
    local ok, name, link, quality, itemLevel, requiredLevel, itemType, itemSubType,
        stackCount, equipLocation, icon, sellPrice, classID, subclassID, bindType,
        expansionID = pcall(getter, candidate.itemID)
    if ok and name and expansionID ~= nil then
        local info = ZoneStyle.expansions[tonumber(expansionID)]
        return Evidence(expansionID, "item", "item metadata: " .. tostring(info and info.label or expansionID), candidate.sourceID, candidate.itemID), false
    end
    if C_Item and type(C_Item.RequestLoadItemDataByID) == "function" then
        P.SafeCall(C_Item.RequestLoadItemDataByID, candidate.itemID)
        return nil, true
    end
    return nil, false
end

function P.ResolveEraCandidate(candidate)
    local best = GetCuratedEvidence(candidate)
    best = PreferStronger(best, GetSetEvidence(candidate))

    local tracking, trackingPending = GetTrackingEvidence(candidate)
    best = PreferStronger(best, tracking)
    best = PreferStronger(best, GetEncounterEvidence(candidate))

    if best and best.rank >= evidenceRanks.encounter then return best, false end

    local item, itemPending = GetItemEvidence(candidate)
    if trackingPending then return nil, true end
    return PreferStronger(best, item), itemPending
end

local function EraNow()
    if type(time) == "function" then return time() end
    if type(GetTimePreciseSec) == "function" then return GetTimePreciseSec() end
    if type(GetTime) == "function" then return GetTime() end
    return 0
end

local function ManifestSignature(source)
    if not source then return "" end
    if source.eraManifestSignature then return source.eraManifestSignature end
    local parts = {}
    for _, sourceID in ipairs(source.eraSourceIDs or {}) do parts[#parts + 1] = tostring(sourceID) end
    return table.concat(parts, ",")
end

local function CacheEraResult(source, result, candidateCount)
    if not source or not result then return result end
    source.eraEvidenceVersion = P.ERA_EVIDENCE_VERSION
    source.eraEvidenceVisualID = source.visualID
    source.eraEvidenceManifestVersion = source.eraManifestVersion
    source.eraEvidenceManifestSignature = ManifestSignature(source)
    source.eraEvidenceMetadataRevision = tonumber(source.metadataRevision) or 0
    source.eraEvidenceCandidateCount = candidateCount
    source.eraEvidenceExpansionID = result.expansionID
    source.eraEvidenceMethod = result.method
    source.eraEvidenceLabel = result.label
    source.eraEvidenceSourceID = result.sourceID
    source.eraEvidenceItemID = result.itemID
    source.eraEvidenceReason = result.reason
    source.eraEvidencePending = result.pending == true
    source.eraEvidenceUnknown = result.unknown == true
    source.eraEvidenceState = result.expansionID ~= nil and "RESOLVED"
        or (result.pending and "PENDING" or "UNKNOWN")
    source.eraEvidenceRetryAt = result.pending and (EraNow() + 30) or nil
    return result
end

local function ReadCachedEvidence(source)
    if not source
        or source.eraEvidenceVersion ~= P.ERA_EVIDENCE_VERSION
        or source.eraEvidenceVisualID ~= source.visualID
        or source.eraEvidenceManifestVersion ~= source.eraManifestVersion
        or source.eraEvidenceManifestSignature ~= ManifestSignature(source)
        or (tonumber(source.eraEvidenceMetadataRevision) or 0) ~= (tonumber(source.metadataRevision) or 0)
        or source.eraEvidenceState == nil
    then
        return nil
    end
    if source.eraEvidenceState == "PENDING"
        and tonumber(source.eraEvidenceRetryAt)
        and EraNow() >= tonumber(source.eraEvidenceRetryAt)
    then
        return nil
    end
    return {
        expansionID = source.eraEvidenceExpansionID,
        method = source.eraEvidenceMethod,
        label = source.eraEvidenceLabel,
        sourceID = source.eraEvidenceSourceID,
        itemID = source.eraEvidenceItemID,
        candidateCount = source.eraEvidenceCandidateCount,
        reason = source.eraEvidenceReason,
        pending = source.eraEvidencePending == true,
        unknown = source.eraEvidenceUnknown == true,
        cached = true,
    }
end

local function FinalizeEraWork(work)
    local earliest = work.earliest
    local pending = work.pending == true
    local candidateCount = #work.sourceIDs
    local result
    if earliest then
        -- A pending sibling may still reveal stronger set/tracking/encounter
        -- evidence. Do not freeze a weak item-only answer while Blizzard is
        -- still loading the rest of the visual family.
        if pending and (earliest.rank or 0) < evidenceRanks.encounter then
            result = {
                pending = true,
                candidateCount = candidateCount,
                provisionalExpansionID = earliest.expansionID,
                reason = "WoW is still loading stronger source-era evidence.",
            }
        else
            earliest.candidateCount = candidateCount
            earliest.partial = pending
            result = earliest
        end
    else
        result = {
            pending = pending,
            unknown = not pending,
            candidateCount = candidateCount,
            reason = pending and "WoW is still loading source-era evidence." or "WoW did not expose enough evidence to establish this appearance's era.",
        }
    end
    CacheEraResult(work.source, result, candidateCount)
    work.done = true
    work.result = result
    return result
end

function ZoneStyle.CreateSourceEraEvidenceWork(source)
    if not source then
        return {
            source = source,
            sourceIDs = {},
            sourceIndex = 1,
            done = true,
            result = { pending = true, reason = "No appearance source was provided." },
        }
    end
    local cached = ReadCachedEvidence(source)
    if cached then
        local wardrobePrivate = QC.Wardrobe and QC.Wardrobe._Private
        if wardrobePrivate and wardrobePrivate.generationJob then
            wardrobePrivate.generationJob.eraCacheHits = (wardrobePrivate.generationJob.eraCacheHits or 0) + 1
        end
        return {
            source = source,
            sourceIDs = {},
            sourceIndex = 1,
            done = true,
            result = cached,
            cached = true,
        }
    end
    return {
        source = source,
        sourceIDs = P.GetAppearanceEraSourceIDs(source),
        sourceIndex = 1,
        earliest = nil,
        pending = false,
        done = false,
    }
end

function ZoneStyle.StepSourceEraEvidenceWork(work, maxCandidates)
    if not work then return true, { pending = true, reason = "No era-evidence work was provided." }, 0 end
    if work.done then return true, work.result, 0 end

    maxCandidates = math.max(1, tonumber(maxCandidates) or 1)
    local processed = 0
    while work.sourceIndex <= #work.sourceIDs and processed < maxCandidates do
        local sourceID = work.sourceIDs[work.sourceIndex]
        local evidence, candidatePending = P.ResolveEraCandidate(P.BuildEraCandidate(work.source, sourceID))
        work.pending = work.pending or candidatePending
        if evidence and (not work.earliest
            or evidence.expansionID < work.earliest.expansionID
            or (evidence.expansionID == work.earliest.expansionID and evidence.rank > work.earliest.rank))
        then
            work.earliest = evidence
        end
        work.sourceIndex = work.sourceIndex + 1
        processed = processed + 1
        local wardrobePrivate = QC.Wardrobe and QC.Wardrobe._Private
        if wardrobePrivate and wardrobePrivate.MaybeYieldWeaponGeneration then
            wardrobePrivate.MaybeYieldWeaponGeneration("eraEvidence")
        end
    end

    if work.sourceIndex > #work.sourceIDs then
        return true, FinalizeEraWork(work), processed
    end
    return false, nil, processed
end

function ZoneStyle.GetSourceEraEvidence(source)
    local work = ZoneStyle.CreateSourceEraEvidenceWork(source)
    while not work.done do
        ZoneStyle.StepSourceEraEvidenceWork(work, 1000000)
    end
    return work.result
end

function ZoneStyle.GetSourceExpansionID(source)
    local evidence = ZoneStyle.GetSourceEraEvidence(source)
    return evidence and evidence.expansionID or nil
end

function ZoneStyle.FormatEraEvidence(evidence)
    if not evidence or evidence.expansionID == nil then return "unverified era" end
    local info = ZoneStyle.expansions[evidence.expansionID]
    local era = info and info.label or ("Expansion " .. tostring(evidence.expansionID))
    local method = evidence.label or evidence.method or "WoW metadata"
    return string.format("%s via %s", era, method)
end
