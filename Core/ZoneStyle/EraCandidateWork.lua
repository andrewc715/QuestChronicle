local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private

local ranks = P.eraEvidenceRanks or {
    curated = 100, set = 90, tracking = 80, encounter = 70, item = 40,
}

P.eraCandidateFragmentCache = P.eraCandidateFragmentCache or {}
P.eraCandidateFragmentByItem = P.eraCandidateFragmentByItem or {}
P.eraCandidateFragmentBySource = P.eraCandidateFragmentBySource or {}

local function Evidence(expansionID, method, label, sourceID, itemID, rank)
    if P.CreateEraEvidence then return P.CreateEraEvidence(expansionID, method, label, sourceID, itemID, rank) end
    expansionID = tonumber(expansionID)
    if expansionID == nil then return nil end
    return {
        expansionID = expansionID, method = method, label = label,
        sourceID = tonumber(sourceID), itemID = tonumber(itemID),
        rank = rank or ranks[method] or 0,
    }
end

local function Prefer(current, candidate)
    if P.PreferEraEvidence then return P.PreferEraEvidence(current, candidate) end
    if not candidate then return current end
    if not current then return candidate end
    if candidate.rank ~= current.rank then return candidate.rank > current.rank and candidate or current end
    if candidate.expansionID ~= current.expansionID then
        return candidate.expansionID > current.expansionID and candidate or current
    end
    return current
end

local function CopyEvidence(value)
    if type(value) ~= "table" then return nil end
    return {
        expansionID = value.expansionID, method = value.method, label = value.label,
        sourceID = value.sourceID, itemID = value.itemID, rank = value.rank,
    }
end

local function FragmentKey(candidate)
    if not candidate or not tonumber(candidate.sourceID) then return nil end
    return table.concat({
        tostring(tonumber(candidate.sourceID) or ""),
        tostring(tonumber(candidate.itemID) or ""),
        tostring(tonumber(candidate.sourceType) or tostring(candidate.sourceType or "")),
    }, ":")
end

local function IndexFragment(key, candidate)
    local itemID, sourceID = tonumber(candidate and candidate.itemID), tonumber(candidate and candidate.sourceID)
    if itemID then
        P.eraCandidateFragmentByItem[itemID] = P.eraCandidateFragmentByItem[itemID] or {}
        P.eraCandidateFragmentByItem[itemID][key] = true
    end
    if sourceID then
        P.eraCandidateFragmentBySource[sourceID] = P.eraCandidateFragmentBySource[sourceID] or {}
        P.eraCandidateFragmentBySource[sourceID][key] = true
    end
end

local function RemoveFragmentKey(key)
    local fragment = P.eraCandidateFragmentCache[key]
    if not fragment then return end
    P.eraCandidateFragmentCache[key] = nil
    local itemID, sourceID = tonumber(fragment.itemID), tonumber(fragment.sourceID)
    if itemID and P.eraCandidateFragmentByItem[itemID] then
        P.eraCandidateFragmentByItem[itemID][key] = nil
        if not next(P.eraCandidateFragmentByItem[itemID]) then P.eraCandidateFragmentByItem[itemID] = nil end
    end
    if sourceID and P.eraCandidateFragmentBySource[sourceID] then
        P.eraCandidateFragmentBySource[sourceID][key] = nil
        if not next(P.eraCandidateFragmentBySource[sourceID]) then P.eraCandidateFragmentBySource[sourceID] = nil end
    end
end

function P.ClearEraCandidateFragmentCache()
    P.eraCandidateFragmentCache = {}
    P.eraCandidateFragmentByItem = {}
    P.eraCandidateFragmentBySource = {}
end

function P.InvalidateEraCandidateFragmentsForItem(itemID)
    itemID = tonumber(itemID)
    local keys = itemID and P.eraCandidateFragmentByItem[itemID]
    if not keys then return 0 end
    local list = {}
    for key in pairs(keys) do list[#list + 1] = key end
    for _, key in ipairs(list) do RemoveFragmentKey(key) end
    return #list
end

function P.InvalidateEraCandidateFragmentsForSourceID(sourceID)
    sourceID = tonumber(sourceID)
    local keys = sourceID and P.eraCandidateFragmentBySource[sourceID]
    if not keys then return 0 end
    local list = {}
    for key in pairs(keys) do list[#list + 1] = key end
    for _, key in ipairs(list) do RemoveFragmentKey(key) end
    return #list
end

function P.InvalidateTrackedSourceOrigin(sourceID)
    sourceID = tonumber(sourceID)
    if not sourceID then return false end
    if P.trackedOriginCache then P.trackedOriginCache[sourceID] = nil end
    P.InvalidateEraCandidateFragmentsForSourceID(sourceID)
    return true
end

local function ReadFragment(candidate)
    local key = FragmentKey(candidate)
    local fragment = key and P.eraCandidateFragmentCache[key]
    if not fragment then return nil end
    return {
        evidence = fragment.hasEvidence and CopyEvidence(fragment.evidence) or nil,
        candidatePending = false, pendingItemID = nil, trackingPending = false,
        key = key,
    }
end

local function StoreFragment(work)
    if not work or work.candidatePending or work.trackingPending or work.itemPending then return false end
    local key = FragmentKey(work.candidate)
    if not key then return false end
    local fragment = {
        hasEvidence = work.resultEvidence ~= nil,
        evidence = CopyEvidence(work.resultEvidence),
        sourceID = tonumber(work.candidate.sourceID),
        itemID = tonumber(work.candidate.itemID),
        sourceType = work.candidate.sourceType,
    }
    P.eraCandidateFragmentCache[key] = fragment
    IndexFragment(key, work.candidate)
    work.fragmentKey = key
    return true
end

local function GetCurated(work)
    local candidate = work.candidate
    local expansionID = P.curatedEraItemIDs and P.curatedEraItemIDs[tonumber(candidate.itemID)]
    if expansionID ~= nil then
        local info = ZoneStyle.expansions[expansionID]
        return Evidence(expansionID, "curated", "curated correction: " .. tostring(info and info.label or expansionID), candidate.sourceID, candidate.itemID)
    end
    local origin = P.GetCuratedSourceOrigin and P.GetCuratedSourceOrigin(candidate)
    if origin and origin.expansionID ~= nil then
        return Evidence(origin.expansionID, "curated", tostring(origin.label or "curated source"), candidate.sourceID, candidate.itemID)
    end
end

local function StepSetList(work)
    work.lastInvokedAPI = false
    if not C_TransmogSets or type(C_TransmogSets.GetSetsContainingSourceID) ~= "function" or type(C_TransmogSets.GetSetInfo) ~= "function" then
        work.setIDs, work.stage = {}, "TRACKING"
        return
    end
    work.lastInvokedAPI = true
    work.setIDs = P.SafeCall(C_TransmogSets.GetSetsContainingSourceID, work.candidate.sourceID) or {}
    work.setIndex = 1
    work.stage = #work.setIDs > 0 and "SET_ENTRY" or "TRACKING"
end

local function StepSetEntry(work)
    work.lastInvokedAPI = false
    local setID = work.setIDs and work.setIDs[work.setIndex]
    if setID == nil then work.stage = "TRACKING" return end
    work.lastInvokedAPI = true
    local info = P.SafeCall(C_TransmogSets.GetSetInfo, setID)
    if type(info) == "table" and info.expansionID ~= nil then
        local label = string.format("set %s", tostring(info.name or setID))
        work.best = Prefer(work.best, Evidence(info.expansionID, "set", label, work.candidate.sourceID, work.candidate.itemID))
    end
    work.setIndex = work.setIndex + 1
    if work.setIndex > #work.setIDs then work.stage = "TRACKING" end
end

local function StepTracking(work)
    work.lastInvokedAPI = false
    local candidate = work.candidate
    local trackingAvailable = C_ContentTracking and type(C_ContentTracking.GetBestMapForTrackable) == "function"
        and P.GetAppearanceTrackingType and P.GetAppearanceTrackingType() ~= nil
    if not trackingAvailable then work.stage = "ENCOUNTER_LIST" return end
    if P.trackedOriginCache and P.trackedOriginCache[candidate.sourceID] == nil then work.lastInvokedAPI = true end
    local origin = P.GetTrackedSourceOrigin and P.GetTrackedSourceOrigin(candidate)
    if origin then
        local expansionID = origin.expansionID or (P.ResolveEraFromText and P.ResolveEraFromText(table.concat({ origin.label or "", origin.mapName or "" }, " ")))
        if expansionID ~= nil then
            work.best = Prefer(work.best, Evidence(expansionID, "tracking", "WoW tracking: " .. tostring(origin.label or origin.mapName or "tracked source"), candidate.sourceID, candidate.itemID))
        end
        work.trackingPending = false
    else
        work.trackingPending = P.trackedOriginCache and P.trackedOriginCache[candidate.sourceID] == nil or false
    end
    work.stage = "ENCOUNTER_LIST"
end

local function StepEncounterList(work)
    work.lastInvokedAPI = false
    if not C_TransmogCollection or type(C_TransmogCollection.GetAppearanceSourceDrops) ~= "function" then
        work.drops, work.stage = {}, "ENCOUNTER_RESOLVE"
        return
    end
    work.lastInvokedAPI = true
    work.drops = P.SafeCall(C_TransmogCollection.GetAppearanceSourceDrops, work.candidate.sourceID) or {}
    work.dropIndex, work.tierIndex, work.encounterParts = 1, nil, {}
    work.stage = #work.drops > 0 and "ENCOUNTER_DROP" or "ENCOUNTER_RESOLVE"
end

local function StepEncounterDrop(work)
    local drop = work.drops and work.drops[work.dropIndex]
    if not drop then work.stage = "ENCOUNTER_RESOLVE" return end
    work.encounterParts[#work.encounterParts + 1] = drop.instance or ""
    work.encounterParts[#work.encounterParts + 1] = drop.encounter or ""
    work.tierIndex = 1
    if type(drop.tiers) == "table" and #drop.tiers > 0 then
        work.stage = "ENCOUNTER_TIER"
    else
        work.dropIndex = work.dropIndex + 1
        work.stage = work.dropIndex <= #work.drops and "ENCOUNTER_DROP" or "ENCOUNTER_RESOLVE"
    end
end

local function StepEncounterTier(work)
    local drop = work.drops and work.drops[work.dropIndex]
    local tier = drop and drop.tiers and drop.tiers[work.tierIndex]
    if tier ~= nil then work.encounterParts[#work.encounterParts + 1] = tier end
    work.tierIndex = (work.tierIndex or 1) + 1
    if not drop or not drop.tiers or work.tierIndex > #drop.tiers then
        work.dropIndex = work.dropIndex + 1
        work.tierIndex = nil
        work.stage = work.dropIndex <= #(work.drops or {}) and "ENCOUNTER_DROP" or "ENCOUNTER_RESOLVE"
    end
end

local function StepEncounterResolve(work)
    local expansionID = P.ResolveEraFromText and P.ResolveEraFromText(table.concat(work.encounterParts or {}, " "))
    if expansionID ~= nil then
        work.best = Prefer(work.best, Evidence(expansionID, "encounter", "encounter journal", work.candidate.sourceID, work.candidate.itemID))
    end
    work.stage = "EARLY_DECISION"
end

local function StepItemMetadata(work)
    work.lastInvokedAPI = false
    local candidate = work.candidate
    if not candidate.itemID then work.itemPending = false work.stage = "FINALIZE" return end
    local getter = C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getter) ~= "function" then work.itemPending = false work.stage = "FINALIZE" return end
    work.lastInvokedAPI = true
    local ok, name, link, quality, itemLevel, requiredLevel, itemType, itemSubType,
        stackCount, equipLocation, icon, sellPrice, classID, subclassID, bindType,
        expansionID = pcall(getter, candidate.itemID)
    if ok and name and expansionID ~= nil then
        local info = ZoneStyle.expansions[tonumber(expansionID)]
        work.itemEvidence = Evidence(expansionID, "item", "item metadata: " .. tostring(info and info.label or expansionID), candidate.sourceID, candidate.itemID)
        work.itemPending = false
    elseif C_Item and type(C_Item.RequestLoadItemDataByID) == "function" then
        P.SafeCall(C_Item.RequestLoadItemDataByID, candidate.itemID)
        work.itemPending, work.pendingItemID = true, candidate.itemID
    else
        work.itemPending = false
    end
    work.stage = "FINALIZE"
end

function P.CreateEraCandidateResolutionWork(source, sourceID, options)
    options = type(options) == "table" and options or {}
    return {
        source = source, sourceID = tonumber(sourceID), candidate = options.candidate,
        stage = options.candidate and "CURATED" or "BUILD", best = nil,
        setIDs = nil, setIndex = 1, drops = nil, dropIndex = 1, tierIndex = nil,
        encounterParts = {}, trackingPending = false, itemPending = false,
        pendingItemID = nil, done = false, resultEvidence = nil,
        candidatePending = false, fragmentCacheHit = false, fragmentCacheBuilt = false,
        skipFragmentCache = options.skipFragmentCache == true,
    }
end

local function LocalAdmission(operation)
    return { operation = operation, admission = P.ERA_ADMISSION_LOCAL or "LOCAL", reserveMs = 0, willInvokeAPI = false }
end

function P.DescribeNextEraCandidateAdmission(work)
    if not work or work.done then
        return { operation = "COMPLETE", admission = P.ERA_ADMISSION_COMPLETE or "COMPLETE", reserveMs = 0, willInvokeAPI = false }
    end
    local stage = work.stage or "BUILD"
    local candidate = work.candidate
    if stage == "SET_LIST" then
        local ready = candidate and tonumber(candidate.sourceID) and C_TransmogSets
            and type(C_TransmogSets.GetSetsContainingSourceID) == "function"
            and type(C_TransmogSets.GetSetInfo) == "function"
        if ready then return { operation=stage, admission=P.ERA_ADMISSION_API_HEADROOM or "API_HEADROOM", reserveMs=P.ERA_API_RESERVE_MS or 3.0, willInvokeAPI=true } end
    elseif stage == "SET_ENTRY" then
        local setID = work.setIDs and work.setIDs[work.setIndex]
        if setID ~= nil and C_TransmogSets and type(C_TransmogSets.GetSetInfo) == "function" then
            return { operation=stage, admission=P.ERA_ADMISSION_API_HEADROOM or "API_HEADROOM", reserveMs=P.ERA_API_RESERVE_MS or 3.0, willInvokeAPI=true }
        end
    elseif stage == "TRACKING" then
        local sourceID = candidate and tonumber(candidate.sourceID)
        if sourceID and P.trackedOriginCache and P.trackedOriginCache[sourceID] ~= nil then return LocalAdmission(stage) end
        local ready = sourceID and C_ContentTracking and type(C_ContentTracking.GetBestMapForTrackable) == "function"
            and P.GetAppearanceTrackingType and P.GetAppearanceTrackingType() ~= nil
        if ready then return { operation=stage, admission=P.ERA_ADMISSION_API_HEADROOM or "API_HEADROOM", reserveMs=P.ERA_API_RESERVE_MS or 3.0, willInvokeAPI=true } end
    elseif stage == "ENCOUNTER_LIST" then
        if candidate and tonumber(candidate.sourceID) and C_TransmogCollection
            and type(C_TransmogCollection.GetAppearanceSourceDrops) == "function"
        then
            return { operation=stage, admission=P.ERA_ADMISSION_API_HEADROOM or "API_HEADROOM", reserveMs=P.ERA_API_RESERVE_MS or 3.0, willInvokeAPI=true }
        end
    elseif stage == "ITEM_METADATA" then
        local getter = C_Item and C_Item.GetItemInfo or GetItemInfo
        if candidate and tonumber(candidate.itemID) and type(getter) == "function" then
            return { operation=stage, admission=P.ERA_ADMISSION_API_HEADROOM or "API_HEADROOM", reserveMs=P.ERA_API_RESERVE_MS or 3.0, willInvokeAPI=true }
        end
    end
    return LocalAdmission(stage)
end

function P.DescribeNextEraCandidateOperation(work)
    local descriptor = P.DescribeNextEraCandidateAdmission(work)
    -- Compatibility: the second return remains true for an API-sensitive stage,
    -- even though production admission is now headroom-based rather than fresh-only.
    return descriptor.operation, descriptor.admission ~= (P.ERA_ADMISSION_LOCAL or "LOCAL")
        and descriptor.admission ~= (P.ERA_ADMISSION_COMPLETE or "COMPLETE")
end

function P.StepEraCandidateResolutionWork(work)
    if not work then return true, nil, true, nil, false end
    if work.done then return true, work.resultEvidence, work.candidatePending, work.pendingItemID, work.trackingPending end
    work.lastInvokedAPI = false
    local stage = work.stage
    if stage == "BUILD" then
        work.candidate = P.BuildEraCandidate(work.source, work.sourceID)
        if not work.skipFragmentCache then
            local fragment = ReadFragment(work.candidate)
            if fragment then
                work.fragmentCacheHit = true
                work.resultEvidence, work.candidatePending = fragment.evidence, false
                work.pendingItemID, work.trackingPending, work.done = nil, false, true
                return true, work.resultEvidence, false, nil, false
            end
        end
        work.stage = "CURATED"
    elseif stage == "CURATED" then
        work.best = Prefer(work.best, GetCurated(work))
        work.stage = "SET_LIST"
    elseif stage == "SET_LIST" then StepSetList(work)
    elseif stage == "SET_ENTRY" then StepSetEntry(work)
    elseif stage == "TRACKING" then StepTracking(work)
    elseif stage == "ENCOUNTER_LIST" then StepEncounterList(work)
    elseif stage == "ENCOUNTER_DROP" then StepEncounterDrop(work)
    elseif stage == "ENCOUNTER_TIER" then StepEncounterTier(work)
    elseif stage == "ENCOUNTER_RESOLVE" then StepEncounterResolve(work)
    elseif stage == "EARLY_DECISION" then
        if work.best and work.best.rank >= ranks.encounter then
            work.resultEvidence, work.candidatePending = work.best, false
            work.pendingItemID, work.trackingPending, work.stage = nil, false, "FINALIZE"
        else
            work.stage = "ITEM_METADATA"
        end
    elseif stage == "ITEM_METADATA" then StepItemMetadata(work)
    elseif stage == "FINALIZE" then
        if work.resultEvidence == nil then
            if work.trackingPending then
                work.resultEvidence, work.candidatePending = nil, true
            else
                work.resultEvidence = Prefer(work.best, work.itemEvidence)
                work.candidatePending = work.itemPending == true
            end
        end
        work.done = true
        work.fragmentCacheBuilt = StoreFragment(work)
        return true, work.resultEvidence, work.candidatePending, work.pendingItemID, work.trackingPending
    else
        work.done, work.candidatePending = true, true
    end
    return work.done, work.resultEvidence, work.candidatePending, work.pendingItemID, work.trackingPending
end

-- Runtime compatibility wrapper. Existing focused harnesses that load only
-- EraEvidence.lua keep the v1.11.7 reference resolver; the addon loads this
-- module immediately afterward and receives this state-machine-backed wrapper.
P.ResolveEraCandidateReference = P.ResolveEraCandidate
function P.ResolveEraCandidate(candidate)
    local work = P.CreateEraCandidateResolutionWork(nil, candidate and candidate.sourceID, {
        candidate = candidate, skipFragmentCache = true,
    })
    while not work.done do P.StepEraCandidateResolutionWork(work) end
    return work.resultEvidence, work.candidatePending, work.pendingItemID, work.trackingPending
end
