local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private
local T = QC.ZoneStyle and QC.ZoneStyle.Traveler

P.SUPPORT_SLOT_ORDER = { "WAIST", "HANDS", "FEET", "HEAD", "BACK", "WRIST", "SHIRT", "TABARD" }
P.SUPPORT_PROFILE_WEIGHTS = { CHEST = 0.34, LEGS = 0.24, SHOULDER = 0.18, WEAPON = 0.24 }
P.SUPPORT_DESCRIPTOR_WEIGHTS = { palette = 0.40, material = 0.22, finish = 0.14, visualWeight = 0.10, motif = 0.09, provenance = 0.05 }

local function Clamp(value, low, high)
    value = tonumber(value) or 0
    if value < low then return low end
    if value > high then return high end
    return value
end

local function AddMap(target, source, weight)
    for key, value in pairs(source or {}) do target[key] = (target[key] or 0) + (tonumber(value) or 0) * weight end
end

local function Normalize(values)
    local total = 0
    for _, value in pairs(values or {}) do total = total + math.max(0, tonumber(value) or 0) end
    if total > 0 then for key, value in pairs(values) do values[key] = math.max(0, value) / total end end
    return values
end

local function Dominant(values)
    local key, best
    for candidate, value in pairs(values or {}) do if not best or value > best then key, best = candidate, value end end
    return key, best or 0
end

local function AddEntry(entries, source, slotKey, weight, label)
    if not source or weight <= 0 then return end
    local definition = P.slotByKey[slotKey]
    local descriptor = QC.ZoneStyle and QC.ZoneStyle.GetTravelerDescriptor and QC.ZoneStyle.GetTravelerDescriptor(source, definition)
    if descriptor then
        entries[#entries + 1] = {
            source = source, sourceID = source.sourceID, visualID = source.visualID,
            slotKey = slotKey, label = label or slotKey, weight = weight, descriptor = descriptor,
        }
    end
end

local function Redistribute(entries)
    local total = 0
    for _, entry in ipairs(entries) do total = total + entry.weight end
    if total <= 0 then return end
    for _, entry in ipairs(entries) do entry.weight = entry.weight / total end
end

local function BuildEntries(state, mask)
    local entries, logicalCount = {}, 0
    for _, slotKey in ipairs({ "CHEST", "LEGS", "SHOULDER" }) do
        if P.IsAnchorActive(mask, slotKey) then
            local source = P.GetActiveAnchorSource(mask, state, slotKey)
            if source then
                AddEntry(entries, source, slotKey, P.SUPPORT_PROFILE_WEIGHTS[slotKey], slotKey == "SHOULDER" and "Shoulders" or (slotKey == "CHEST" and "Chest" or "Legs"))
                logicalCount = logicalCount + 1
            end
        end
    end
    local mainSource, mainSlot, offSource = P.GetActiveAnchorSource(mask, state, "WEAPON")
    if mainSource or offSource then logicalCount = logicalCount + 1 end
    if mainSource and offSource and tostring(mainSource.visualID or mainSource.sourceID) ~= tostring(offSource.visualID or offSource.sourceID) then
        AddEntry(entries, mainSource, mainSlot, P.SUPPORT_PROFILE_WEIGHTS.WEAPON * 0.5, "Main Hand")
        AddEntry(entries, offSource, "OFF_HAND", P.SUPPORT_PROFILE_WEIGHTS.WEAPON * 0.5, "Off Hand")
    else
        AddEntry(entries, mainSource or offSource, mainSlot or "OFF_HAND", P.SUPPORT_PROFILE_WEIGHTS.WEAPON, "Weapon bundle")
    end
    Redistribute(entries)
    return entries, mainSlot, logicalCount
end

local function BuildDescriptor(entries)
    local descriptor = { palette = {}, material = {}, finish = {}, motifs = {}, confidence = {}, setIDs = {}, visualWeight = 0 }
    local expansionWeights, setCounts = {}, {}
    for _, entry in ipairs(entries) do
        local source, weight = entry.descriptor, entry.weight
        AddMap(descriptor.palette, source.palette, weight)
        AddMap(descriptor.material, source.material, weight)
        AddMap(descriptor.finish, source.finish, weight)
        AddMap(descriptor.motifs, source.motifs, weight)
        descriptor.visualWeight = descriptor.visualWeight + (tonumber(source.visualWeight) or 2.5) * weight
        for _, field in ipairs({ "palette", "material", "finish", "motifs", "visualWeight", "provenance" }) do
            descriptor.confidence[field] = (descriptor.confidence[field] or 0) + (tonumber(source.confidence and source.confidence[field]) or 0) * weight
        end
        if source.expansionID ~= nil then expansionWeights[source.expansionID] = (expansionWeights[source.expansionID] or 0) + weight end
        for _, setID in ipairs(source.setIDs or {}) do setCounts[setID] = (setCounts[setID] or 0) + 1 end
    end
    Normalize(descriptor.palette); Normalize(descriptor.material); Normalize(descriptor.finish); Normalize(descriptor.motifs)
    descriptor.dominantPalette, descriptor.dominantPaletteStrength = Dominant(descriptor.palette)
    descriptor.dominantMaterial, descriptor.dominantMaterialStrength = Dominant(descriptor.material)
    descriptor.dominantFinish, descriptor.dominantFinishStrength = Dominant(descriptor.finish)
    descriptor.dominantMotif, descriptor.dominantMotifStrength = Dominant(descriptor.motifs)
    descriptor.expansionID = Dominant(expansionWeights)
    for setID, count in pairs(setCounts) do if count >= 2 then descriptor.setIDs[#descriptor.setIDs + 1] = setID end end
    table.sort(descriptor.setIDs)
    return descriptor
end

local function RelationshipSummary(entries)
    local total, count, strongest, weakest = 0, 0, nil, nil
    local componentTotals = { palette = 0, material = 0, finish = 0, visualWeight = 0, motif = 0, provenance = 0 }
    for leftIndex = 1, #entries do
        for rightIndex = leftIndex + 1, #entries do
            local left, right = entries[leftIndex], entries[rightIndex]
            local score, components = 0.5, nil
            if T and T.GetPairCohesion then score, components = T.GetPairCohesion(left.descriptor, right.descriptor) end
            total, count = total + score, count + 1
            local relationship = { left = left.label, right = right.label, score = score }
            if not strongest or score > strongest.score then strongest = relationship end
            if not weakest or score < weakest.score then weakest = relationship end
            for key in pairs(componentTotals) do componentTotals[key] = componentTotals[key] + (components and components[key] or 0.5) end
        end
    end
    local mean = count > 0 and total / count or 0.5
    for key, value in pairs(componentTotals) do componentTotals[key] = count > 0 and value / count or 0.5 end
    local tolerance = {}
    for key, value in pairs(componentTotals) do tolerance[key] = Clamp(1 - value, 0.05, 0.65) end
    return mean, strongest, weakest, componentTotals, tolerance
end

function P.BuildContextualSupportProfile(state, options)
    options = options or {}
    local mask = options.activeAnchorMask or P.BuildActiveAnchorMask(state or {}, options.anchorSnapshot)
    local entries, mainSlot, logicalCount = BuildEntries(state or {}, mask)
    local descriptor = BuildDescriptor(entries)
    local mean, strongest, weakest, components, tolerance = RelationshipSummary(entries)
    local sourceReportID = options.profileSourceReportID
    local profileID = options.profileID or P.CreateContextualSupportProfileID(sourceReportID, mask)
    return {
        version = 2,
        profileID = profileID,
        profileSourceReportID = sourceReportID,
        activeAnchorMask = mask,
        activeAnchorMaskSignature = P.ActiveAnchorMaskSignature(mask),
        entries = entries,
        descriptor = descriptor,
        mainWeaponSlot = mainSlot,
        activeAnchorCount = logicalCount,
        meanAnchorCohesion = mean,
        strongestRelationship = strongest,
        weakestRelationship = weakest,
        cohesionComponents = components,
        tolerance = tolerance,
        confidence = descriptor.confidence,
    }
end

function P.GetSupportProfileFit(source, definition, profile)
    if not source or not profile or not profile.descriptor then return 0.5, {} end
    local descriptor = QC.ZoneStyle and QC.ZoneStyle.GetTravelerDescriptor and QC.ZoneStyle.GetTravelerDescriptor(source, definition)
    if not descriptor then return 0.5, {} end
    local score, components = 0.5, {}
    if T and T.GetPairCohesion then score, components = T.GetPairCohesion(descriptor, profile.descriptor) end
    return Clamp(score, 0, 1), components or {}, descriptor
end

function P.GetSupportProfileDistance(components, profile)
    local total, totalWeight = 0, 0
    for key, weight in pairs(P.SUPPORT_DESCRIPTOR_WEIGHTS or {}) do
        local cohesion = Clamp(components and components[key] or 0.5, 0, 1)
        local tolerance = Clamp(profile and profile.tolerance and profile.tolerance[key] or 0.15, 0, 0.85)
        local confidenceKey = key == "motif" and "motifs" or key
        local confidence = Clamp(profile and profile.confidence and profile.confidence[confidenceKey] or 0.5, 0, 1)
        local excess = math.max(0, (1 - cohesion) - tolerance)
        local normalized = excess / math.max(0.15, 1 - tolerance)
        total = total + normalized * weight * (0.5 + confidence * 0.5)
        totalWeight = totalWeight + weight
    end
    return Clamp(totalWeight > 0 and total / totalWeight or 0.5, 0, 1)
end
