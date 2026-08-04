local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.WEAPON_INDEX_FORMAT = 1
P.weaponCandidateIndex = nil
P.weaponCandidateIndexKey = nil
P.weaponCandidateIndexInvalidationReason = P.weaponCandidateIndexInvalidationReason or "LOGIN_SESSION_RESET"
P.weaponCandidateIndexInvalidationUnknownFallback = P.weaponCandidateIndexInvalidationUnknownFallback == true
P.weaponCandidateIndexInvalidationSequence = tonumber(P.weaponCandidateIndexInvalidationSequence) or 0
if P.weaponCandidateIndexInvalidationSequence == 0 then
    P.weaponCandidateIndexInvalidationSequence = 1
end
P.weaponCandidateIndexStats = P.weaponCandidateIndexStats or {
    builds = 0, repairs = 0, reused = 0, examined = 0, yields = 0,
    lastProcessedInvalidationReason = nil,
    lastProcessedInvalidationUnknownFallback = false,
    lastProcessedInvalidationSequence = 0,
}

local CANONICAL_REASONS = {
    NONE = true, FORMAT_MISMATCH = true, WARDROBE_CACHE_REPLACED = true,
    COLLECTION_REVISION_CHANGED = true, METADATA_REVISION_CHANGED = true,
    CHARACTER_CAPABILITY_CHANGED = true, APPEARANCE_COLLECTED = true,
    EVIDENCE_OUTCOME_CHANGED = true, ELIGIBILITY_OUTCOME_CHANGED = true,
    LOGIN_SESSION_RESET = true, MANUAL_DEBUG_RESET = true, UNKNOWN = true,
}

local function CanonicalReason(reason)
    if reason == nil or tostring(reason) == "" then return "UNKNOWN", true end
    reason = tostring(reason)
    if reason == "TEST_BUCKET_CHANGE" or reason == "BUCKET_INVALIDATED" then
        return "METADATA_REVISION_CHANGED", false
    end
    if CANONICAL_REASONS[reason] then return reason, false end
    return "UNKNOWN", true
end

local function CanonicalReasonOrNone(reason)
    if reason == nil or tostring(reason) == "" then return "NONE", false end
    return CanonicalReason(reason)
end

local function CurrentIndexIdentity()
    local cache = P.EnsureCache()
    local identity = {
        format = P.WEAPON_INDEX_FORMAT,
        scanCompletedAt = cache.scanCompletedAt or 0,
        totalVisuals = cache.totalVisuals or 0,
        characterKey = cache.characterKey or "",
    }
    identity.key = table.concat({
        tostring(identity.format), tostring(identity.scanCompletedAt),
        tostring(identity.totalVisuals), tostring(identity.characterKey),
    }, ":")
    return identity
end

local function CountBuckets(index)
    local count = 0
    for _ in pairs(index and index.buckets or {}) do count = count + 1 end
    return count
end

local function NextInvalidationSequence()
    P.weaponCandidateIndexInvalidationSequence = (tonumber(P.weaponCandidateIndexInvalidationSequence) or 0) + 1
    return P.weaponCandidateIndexInvalidationSequence
end

local function ResolveImplicitInvalidation(index, identity)
    if type(index) ~= "table" then
        local reason, unknownFallback = CanonicalReason(P.weaponCandidateIndexInvalidationReason)
        return reason, unknownFallback, tonumber(P.weaponCandidateIndexInvalidationSequence) or 0
    end
    if index.format ~= P.WEAPON_INDEX_FORMAT then
        return "FORMAT_MISMATCH", false, NextInvalidationSequence()
    end
    if tostring(index.characterKey or "") ~= tostring(identity.characterKey or "") then
        return "CHARACTER_CAPABILITY_CHANGED", false, NextInvalidationSequence()
    end
    if tonumber(index.scanCompletedAt or 0) ~= tonumber(identity.scanCompletedAt or 0)
        or tonumber(index.totalVisuals or 0) ~= tonumber(identity.totalVisuals or 0)
    then
        return "WARDROBE_CACHE_REPLACED", false, NextInvalidationSequence()
    end
    return "UNKNOWN", true, NextInvalidationSequence()
end

local function EnsureIndex()
    local identity = CurrentIndexIdentity()
    local index = P.weaponCandidateIndex
    if P.weaponCandidateIndexKey ~= identity.key or type(index) ~= "table" or index.format ~= P.WEAPON_INDEX_FORMAT then
        local reason, unknownFallback, invalidationSequence = ResolveImplicitInvalidation(index, identity)
        P.weaponCandidateIndexKey = identity.key
        index = {
            format = P.WEAPON_INDEX_FORMAT, key = identity.key, state = "PARTIAL", buckets = {},
            completedBuckets = 0, invalidationReason = reason,
            invalidationUnknownFallback = unknownFallback == true,
            invalidationSequence = invalidationSequence,
            scanCompletedAt = identity.scanCompletedAt, totalVisuals = identity.totalVisuals,
            characterKey = identity.characterKey,
            contributingReasons = { [reason] = true },
        }
        P.weaponCandidateIndex = index
        P.weaponCandidateIndexInvalidationReason = nil
        P.weaponCandidateIndexInvalidationUnknownFallback = false
    end
    return index
end

function P.InvalidateWeaponCandidateIndex(reason, subtypeKey)
    local unknownFallback
    reason, unknownFallback = CanonicalReason(reason)
    local invalidationSequence = NextInvalidationSequence()
    local index = P.weaponCandidateIndex
    if subtypeKey and index and index.buckets and index.buckets[subtypeKey] then
        index.buckets[subtypeKey] = nil
        index.completedBuckets = math.max(0, (index.completedBuckets or 1) - 1)
        index.state = "REPAIRING"
        index.repairingSubtypeKey = subtypeKey
        index.invalidationReason = reason
        index.invalidationUnknownFallback = unknownFallback == true
        index.invalidationSequence = invalidationSequence
        index.contributingReasons = index.contributingReasons or {}
        index.contributingReasons[reason] = true
        return
    end
    if index then index.state = "STALE" end
    P.weaponCandidateIndex = nil
    P.weaponCandidateIndexKey = nil
    P.weaponCandidateIndexInvalidationReason = reason
    P.weaponCandidateIndexInvalidationUnknownFallback = unknownFallback == true
end

local function YieldIndex(index, phaseKey)
    if P.MaybeYieldWeaponGeneration then
        index.yields = (index.yields or 0) + 1
        P.weaponCandidateIndexStats.yields = (P.weaponCandidateIndexStats.yields or 0) + 1
        P.MaybeYieldWeaponGeneration(phaseKey or "weaponIndexBuild")
    end
end

function P.GetIndexedWeaponSources(subtypeKey)
    local definition = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
    if not definition then return {} end
    local index = EnsureIndex()
    local cached = index.buckets[subtypeKey]
    if cached then
        P.weaponCandidateIndexStats.reused = (P.weaponCandidateIndexStats.reused or 0) + 1
        index.lastUse = "WARM_REUSE"
        return cached
    end

    local repairing = index.state == "REPAIRING" and index.repairingSubtypeKey == subtypeKey
    index.state = repairing and "REPAIRING" or "BUILDING"
    index.lastUse = repairing and "INCREMENTAL_REPAIR" or (index.completedBuckets > 0 and "PARTIAL_BUILD" or "COLD_BUILD")
    local categoryID = P.ResolveWeaponSubtypeCategoryID(definition)
    local sources = Wardrobe.GetSlotSources(definition.familyKey) or {}
    cached = {}
    local chunk = 0
    for _, source in ipairs(sources) do
        P.weaponCandidateIndexStats.examined = (P.weaponCandidateIndexStats.examined or 0) + 1
        index.examined = (index.examined or 0) + 1
        if tonumber(source.categoryID) == tonumber(categoryID) then cached[#cached + 1] = source end
        chunk = chunk + 1
        if chunk >= 8 then chunk = 0 YieldIndex(index, "weaponIndexBuild") end
    end
    index.buckets[subtypeKey] = cached
    index.completedBuckets = (index.completedBuckets or 0) + 1
    index.repairingSubtypeKey = nil
    index.state = "PARTIAL"
    if repairing then
        P.weaponCandidateIndexStats.repairs = (P.weaponCandidateIndexStats.repairs or 0) + 1
    else
        P.weaponCandidateIndexStats.builds = (P.weaponCandidateIndexStats.builds or 0) + 1
    end
    P.weaponCandidateIndexStats.lastProcessedInvalidationReason = index.invalidationReason
    P.weaponCandidateIndexStats.lastProcessedInvalidationUnknownFallback = index.invalidationUnknownFallback == true
    P.weaponCandidateIndexStats.lastProcessedInvalidationSequence = tonumber(index.invalidationSequence) or 0
    return cached
end

function P.GetWeaponCandidateIndexDiagnostics()
    local index = P.weaponCandidateIndex
    local stats = P.weaponCandidateIndexStats or {}
    local invalidationReason, unknownFallback = CanonicalReasonOrNone(
        index and index.invalidationReason or P.weaponCandidateIndexInvalidationReason
    )
    return {
        format = P.WEAPON_INDEX_FORMAT, state = index and index.state or "STALE",
        use = index and index.lastUse or "NONE", buckets = CountBuckets(index),
        examined = index and index.examined or 0, yields = index and index.yields or 0,
        builds = stats.builds or 0, repairs = stats.repairs or 0, reused = stats.reused or 0,
        invalidationReason = invalidationReason,
        invalidationUnknownFallback = index and index.invalidationUnknownFallback == true
            or P.weaponCandidateIndexInvalidationUnknownFallback == true or unknownFallback == true,
        invalidationSequence = tonumber(index and index.invalidationSequence
            or P.weaponCandidateIndexInvalidationSequence) or 0,
        lastProcessedInvalidationReason = stats.lastProcessedInvalidationReason,
        lastProcessedInvalidationUnknownFallback = stats.lastProcessedInvalidationUnknownFallback == true,
        lastProcessedInvalidationSequence = tonumber(stats.lastProcessedInvalidationSequence) or 0,
        contributingReasons = index and index.contributingReasons or nil,
    }
end

function P.BeginWeaponIndexActionSnapshot()
    local current = P.GetWeaponCandidateIndexDiagnostics()
    return {
        state = current.state, use = current.use, buckets = current.buckets,
        examined = current.examined, yields = current.yields, builds = current.builds,
        repairs = current.repairs, reused = current.reused,
        invalidationReason = current.invalidationReason,
        invalidationUnknownFallback = current.invalidationUnknownFallback == true,
        invalidationSequence = current.invalidationSequence,
    }
end

function P.BuildWeaponIndexActionDiagnostics(start)
    start = start or P.BeginWeaponIndexActionSnapshot()
    local finish = P.GetWeaponCandidateIndexDiagnostics()
    local built = math.max(0, (finish.builds or 0) - (start.builds or 0))
    local repaired = math.max(0, (finish.repairs or 0) - (start.repairs or 0))
    local reused = math.max(0, (finish.reused or 0) - (start.reused or 0))
    local processedSequence = tonumber(finish.lastProcessedInvalidationSequence) or 0
    local processedNewLifecycle = built > 0
        and processedSequence ~= (tonumber(start.invalidationSequence) or 0)
    local action = repaired > 0 and "INCREMENTAL_REPAIR"
        or (built > 0 and (((start.buckets or 0) == 0 or processedNewLifecycle)
            and "COLD_BUILD" or "PARTIAL_BUILD"))
        or (reused > 0 and "WARM_REUSE" or "NONE")
    local invalidationReason, invalidationUnknownFallback = "NONE", false
    if built > 0 or repaired > 0 then
        invalidationReason = finish.lastProcessedInvalidationReason
            or (finish.invalidationReason ~= "NONE" and finish.invalidationReason)
            or (start.invalidationReason ~= "NONE" and start.invalidationReason or "UNKNOWN")
        invalidationUnknownFallback = finish.lastProcessedInvalidationUnknownFallback == true
            or invalidationReason == "UNKNOWN"
    end
    return {
        format = finish.format, stateBefore = start.state, stateAfter = finish.state,
        use = action, bucketsBefore = start.buckets or 0, bucketsAfter = finish.buckets or 0,
        bucketsBuilt = built, bucketsRepaired = repaired, bucketsReused = reused,
        examinedThisAction = math.max(0, (finish.examined or 0) - (start.examined or 0)),
        yieldsThisAction = math.max(0, (finish.yields or 0) - (start.yields or 0)),
        invalidationReason = invalidationReason,
        invalidationUnknownFallback = invalidationUnknownFallback,
        lifetimeBuckets = finish.buckets or 0, lifetimeExamined = finish.examined or 0,
        lifetimeYields = finish.yields or 0,
    }
end
