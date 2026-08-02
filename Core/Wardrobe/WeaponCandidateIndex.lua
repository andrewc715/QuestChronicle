local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.weaponCandidateIndex = nil
P.weaponCandidateIndexKey = nil

local function CurrentIndexKey()
    local cache = P.EnsureCache()
    return table.concat({
        tostring(cache.scanCompletedAt or 0),
        tostring(cache.totalVisuals or 0),
        tostring(cache.characterKey or ""),
    }, ":")
end

function P.InvalidateWeaponCandidateIndex()
    P.weaponCandidateIndex = nil
    P.weaponCandidateIndexKey = nil
end

function P.GetIndexedWeaponSources(subtypeKey)
    local definition = Wardrobe.weaponSubtypeDefinitions[subtypeKey]
    if not definition then return {} end
    local key = CurrentIndexKey()
    if P.weaponCandidateIndexKey ~= key then
        P.weaponCandidateIndexKey = key
        P.weaponCandidateIndex = {}
    end
    local cached = P.weaponCandidateIndex[subtypeKey]
    if cached then return cached end

    local categoryID = P.ResolveWeaponSubtypeCategoryID(definition)
    cached = {}
    for _, source in ipairs(Wardrobe.GetSlotSources(definition.familyKey)) do
        if tonumber(source.categoryID) == tonumber(categoryID) then
            cached[#cached + 1] = source
        end
    end
    P.weaponCandidateIndex[subtypeKey] = cached
    return cached
end
