local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.WEAPON_INDEX_FORMAT = 1
P.weaponCandidateIndex = nil
P.weaponCandidateIndexKey = nil
P.weaponCandidateIndexStats = P.weaponCandidateIndexStats or {
    builds = 0, repairs = 0, reused = 0, examined = 0, yields = 0,
}

local function CurrentIndexKey()
    local cache = P.EnsureCache()
    return table.concat({
        tostring(P.WEAPON_INDEX_FORMAT),
        tostring(cache.scanCompletedAt or 0),
        tostring(cache.totalVisuals or 0),
        tostring(cache.characterKey or ""),
    }, ":")
end

local function EnsureIndex()
    local key = CurrentIndexKey()
    local index = P.weaponCandidateIndex
    if P.weaponCandidateIndexKey ~= key or type(index) ~= "table" or index.format ~= P.WEAPON_INDEX_FORMAT then
        P.weaponCandidateIndexKey = key
        index = {
            format = P.WEAPON_INDEX_FORMAT,
            key = key,
            state = "PARTIAL",
            buckets = {},
            completedBuckets = 0,
            invalidationReason = P.weaponCandidateIndexInvalidationReason,
        }
        P.weaponCandidateIndex = index
        P.weaponCandidateIndexInvalidationReason = nil
    end
    return index
end

function P.InvalidateWeaponCandidateIndex(reason, subtypeKey)
    local index = P.weaponCandidateIndex
    if subtypeKey and index and index.buckets and index.buckets[subtypeKey] then
        index.buckets[subtypeKey] = nil
        index.completedBuckets = math.max(0, (index.completedBuckets or 1) - 1)
        index.state = "REPAIRING"
        index.repairingSubtypeKey = subtypeKey
        index.invalidationReason = reason or "BUCKET_INVALIDATED"
        P.weaponCandidateIndexStats.repairs = (P.weaponCandidateIndexStats.repairs or 0) + 1
        return
    end
    if index then index.state = "STALE" end
    P.weaponCandidateIndex = nil
    P.weaponCandidateIndexKey = nil
    P.weaponCandidateIndexInvalidationReason = reason or "UNSPECIFIED"
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
        index.lastUse = "WARM"
        return cached
    end

    local repairing = index.state == "REPAIRING" and index.repairingSubtypeKey == subtypeKey
    index.state = repairing and "REPAIRING" or "BUILDING"
    index.lastUse = repairing and "INCREMENTAL_REPAIR" or (index.completedBuckets > 0 and "PARTIAL_WARM" or "COLD_BUILD")
    local categoryID = P.ResolveWeaponSubtypeCategoryID(definition)
    local sources = Wardrobe.GetSlotSources(definition.familyKey) or {}
    cached = {}
    local chunk = 0
    for _, source in ipairs(sources) do
        P.weaponCandidateIndexStats.examined = (P.weaponCandidateIndexStats.examined or 0) + 1
        index.examined = (index.examined or 0) + 1
        if tonumber(source.categoryID) == tonumber(categoryID) then cached[#cached + 1] = source end
        chunk = chunk + 1
        if chunk >= 8 then
            chunk = 0
            YieldIndex(index, "weaponIndexBuild")
        end
    end
    index.buckets[subtypeKey] = cached
    index.completedBuckets = (index.completedBuckets or 0) + 1
    index.repairingSubtypeKey = nil
    index.state = "PARTIAL"
    P.weaponCandidateIndexStats.builds = (P.weaponCandidateIndexStats.builds or 0) + 1
    return cached
end

function P.GetWeaponCandidateIndexDiagnostics()
    local index = P.weaponCandidateIndex
    local stats = P.weaponCandidateIndexStats or {}
    local buckets = 0
    if index and index.buckets then for _ in pairs(index.buckets) do buckets = buckets + 1 end end
    return {
        format = P.WEAPON_INDEX_FORMAT,
        state = index and index.state or "STALE",
        use = index and index.lastUse or "NONE",
        buckets = buckets,
        examined = index and index.examined or 0,
        yields = index and index.yields or 0,
        builds = stats.builds or 0,
        repairs = stats.repairs or 0,
        reused = stats.reused or 0,
        invalidationReason = index and index.invalidationReason or P.weaponCandidateIndexInvalidationReason,
    }
end
