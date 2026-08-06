local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone
local P = ZoneStyle._Private

local COMPONENT_WEIGHTS = {
    palette = 0.24, material = 0.18, finish = 0.14, motif = 0.14,
    culture = 0.08, magic = 0.08, provenance = 0.10, avoids = 0.04,
}
local COMPONENT_ORDER = {
    "palette", "material", "finish", "motif",
    "culture", "magic", "avoids", "provenance",
}
local CANONICAL_COMPONENTS = {
    palette = true, material = true, finish = true, motif = true,
    culture = true, magic = true, avoids = true,
}
local STATUS = Zone.AFFINITY_COMPONENT_STATUS or {
    VALUE = "VALUE", MISSING = "MISSING", NOT_APPLICABLE = "NOT_APPLICABLE",
}

local function WeightedOverlap(descriptorValues, zoneValues)
    if type(descriptorValues) ~= "table" or type(zoneValues) ~= "table" then return nil end
    local total, matched = 0, 0
    for key, value in pairs(descriptorValues) do
        value = math.max(0, tonumber(value) or 0)
        total = total + value
        matched = matched + value * math.max(0, math.min(1, tonumber(zoneValues[key]) or 0))
    end
    if total <= 0 then return nil end
    return matched / total
end

local function TextAffinity(text, values)
    if type(values) ~= "table" then return nil end
    local count, best = 0, 0
    local padded = " " .. P.Normalize(text) .. " "
    for key, weight in pairs(values) do
        count = count + 1
        local token = P.Normalize(key:gsub("_", " "))
        if token ~= "" and padded:find(" " .. token .. " ", 1, true) then best = math.max(best, tonumber(weight) or 0) end
    end
    if count == 0 then return nil end
    return best
end

local function AvoidConflict(descriptor, avoids)
    if type(avoids) ~= "table" then return nil end
    local text = descriptor and descriptor.text or ""
    local result = TextAffinity(text, avoids)
    return result and (1 - result) or nil
end

local function ProvenanceAffinity(source, snapshot)
    if not source or not snapshot or not snapshot.provenance or not snapshot.provenance.key then return nil, nil end
    local nativeExpansion = ZoneStyle.GetSourceExpansionID and ZoneStyle.GetSourceExpansionID(source) or source.expansionID
    local curated = P.GetCuratedSourceOrigin and P.GetCuratedSourceOrigin(source, nativeExpansion)
    local tracked = P.GetTrackedSourceOrigin and P.GetTrackedSourceOrigin(source)
    local origin = curated or tracked
    if origin and origin.provenanceKey then
        return origin.provenanceKey == snapshot.provenance.key and 1 or 0, origin
    end
    return nil, origin
end

local function Classification(score, confidence)
    if confidence <= 0 then return "UNKNOWN" end
    if confidence < 0.35 then return "PARTIAL_EVIDENCE" end
    if score >= 0.82 then return "STRONGLY_NATIVE" end
    if score >= 0.68 then return "LOCALLY_COHERENT" end
    if score >= 0.52 then return "SUPPORTED_LOCAL_VARIATION" end
    if score >= 0.34 then return "WEAK_LOCAL_SIGNAL" end
    return "OFF_ZONE_SIGNAL"
end

local function Contains(values, expected)
    for _, value in ipairs(type(values) == "table" and values or {}) do
        if value == expected then return true end
    end
    return false
end

local function ResolveComponentStatus(key, value, snapshot, explicitNotApplicable)
    if explicitNotApplicable then return STATUS.NOT_APPLICABLE end
    if CANONICAL_COMPONENTS[key] then
        local coverage = snapshot and snapshot.style and snapshot.style.coverage and snapshot.style.coverage[key]
        if coverage == "NOT_APPLICABLE" then return STATUS.NOT_APPLICABLE end
        if coverage ~= "KNOWN" and coverage ~= "PARTIAL" then return STATUS.MISSING end
    elseif key == "provenance" then
        local provenance = snapshot and snapshot.provenance
        if provenance and provenance.applicability == "NOT_APPLICABLE" then return STATUS.NOT_APPLICABLE end
    end
    return value == nil and STATUS.MISSING or STATUS.VALUE
end

local function BuildComponentStatuses(components, snapshot, priorStatus, priorNotApplicable)
    local statuses, missing, notApplicable = {}, {}, {}
    for _, key in ipairs(COMPONENT_ORDER) do
        local explicit = priorStatus and priorStatus[key]
        local isNotApplicable = explicit == STATUS.NOT_APPLICABLE or Contains(priorNotApplicable, key)
        local status = explicit
        if status ~= STATUS.VALUE and status ~= STATUS.MISSING and status ~= STATUS.NOT_APPLICABLE then
            status = ResolveComponentStatus(key, components and components[key], snapshot, isNotApplicable)
        end
        statuses[key] = status
        if status == STATUS.NOT_APPLICABLE then
            notApplicable[#notApplicable + 1] = key
        elseif status == STATUS.MISSING then
            missing[#missing + 1] = key
        end
    end
    return statuses, missing, notApplicable
end

local function EmptyAffinity(missing)
    return {
        format = Zone.AFFINITY_FORMAT,
        score = 0,
        confidence = 0,
        components = {},
        componentStatus = {},
        evidence = {},
        missingChannels = missing,
        notApplicableChannels = {},
        classification = "UNKNOWN",
    }
end

function Zone.NormalizeZoneAffinityPiece(piece, snapshot)
    local normalized = Zone.CopyPrimitive and Zone.CopyPrimitive(piece or {}) or {}
    normalized.components = normalized.components or {}
    local statuses, missing, notApplicable = BuildComponentStatuses(
        normalized.components, snapshot, normalized.componentStatus, normalized.notApplicableChannels
    )
    normalized.format = Zone.AFFINITY_FORMAT
    normalized.componentStatus = statuses
    normalized.missingChannels = missing
    normalized.notApplicableChannels = notApplicable
    return normalized
end

function Zone.NormalizeSelectedOutfitAffinity(affinity, snapshot)
    local normalized = Zone.CopyPrimitive and Zone.CopyPrimitive(affinity or {}) or {}
    normalized.format = Zone.AFFINITY_FORMAT
    normalized.pieces = {}
    for _, piece in ipairs(type(affinity) == "table" and affinity.pieces or {}) do
        normalized.pieces[#normalized.pieces + 1] = Zone.NormalizeZoneAffinityPiece(piece, snapshot)
    end
    return normalized
end

function Zone.GetZoneAffinity(source, definition, snapshot)
    snapshot = snapshot or (ZoneStyle.GetZoneContextSnapshot and ZoneStyle.GetZoneContextSnapshot())
    if not source or not snapshot then
        return EmptyAffinity({ "source", "snapshot" })
    end
    local descriptor = ZoneStyle.GetTravelerDescriptor and ZoneStyle.GetTravelerDescriptor(source, definition)
    if not descriptor then
        return EmptyAffinity({ "visual_descriptor" })
    end
    local style = snapshot.style or {}
    local components = {
        palette = WeightedOverlap(descriptor.palette, style.palette),
        material = WeightedOverlap(descriptor.material, style.material),
        finish = WeightedOverlap(descriptor.finish, style.finish),
        motif = WeightedOverlap(descriptor.motifs, style.motif),
        culture = TextAffinity(descriptor.text, style.culture),
        magic = TextAffinity(descriptor.text, style.magic),
        avoids = AvoidConflict(descriptor, style.avoids),
    }
    local provenance, origin = ProvenanceAffinity(source, snapshot)
    components.provenance = provenance
    local componentStatus, missing, notApplicable = BuildComponentStatuses(components, snapshot)
    for _, key in ipairs(COMPONENT_ORDER) do
        if componentStatus[key] ~= STATUS.VALUE then components[key] = nil end
    end
    local score, weightTotal, confidenceTotal = 0, 0, 0
    for key, weight in pairs(COMPONENT_WEIGHTS) do
        local value = components[key]
        if value ~= nil then
            score = score + value * weight
            weightTotal = weightTotal + weight
            local descriptorConfidence = descriptor.confidence and (descriptor.confidence[key] or descriptor.confidence.motifs or descriptor.confidence.provenance) or 0.5
            confidenceTotal = confidenceTotal + math.max(0, math.min(1, tonumber(descriptorConfidence) or 0.5)) * weight
        end
    end
    if weightTotal > 0 then score = score / weightTotal
        confidenceTotal = confidenceTotal / weightTotal end
    local zoneConfidence = math.max(0, math.min(1, tonumber(snapshot.identity and snapshot.identity.confidence) or 0))
    local confidence = confidenceTotal * zoneConfidence
    local evidence = {
        { channel = "VISUAL_DESCRIPTOR", value = descriptor.fingerprint, confidence = confidenceTotal },
        { channel = "PROFILE_DEFINITION", value = snapshot.identity.profileKey, confidence = zoneConfidence },
    }
    if origin then evidence[#evidence + 1] = { channel = "SOURCE_PROVENANCE", value = origin.provenanceKey or origin.label, confidence = provenance ~= nil and 1 or 0.5 } end
    return {
        format = Zone.AFFINITY_FORMAT,
        score = score,
        confidence = confidence,
        components = components,
        componentStatus = componentStatus,
        evidence = evidence,
        missingChannels = missing,
        notApplicableChannels = notApplicable,
        classification = Classification(score, confidence),
        descriptorFingerprint = descriptor.fingerprint,
        profileKey = snapshot.identity.profileKey,
        provenanceKey = snapshot.provenance.key,
        sourceID = source.sourceID,
        visualID = source.visualID,
        slotKey = definition and definition.key or source.slotKey,
    }
end

function Zone.BuildSelectedOutfitAffinity(state, snapshot)
    local Wardrobe = QC.Wardrobe
    local WP = Wardrobe and Wardrobe._Private
    state = state or (WP and WP.EnsurePreviewState and WP.EnsurePreviewState())
    snapshot = snapshot or (ZoneStyle.GetZoneContextSnapshot and ZoneStyle.GetZoneContextSnapshot())
    local result = { format = Zone.AFFINITY_FORMAT, pieces = {}, selected = 0, score = 0, confidence = 0, classifications = {} }
    if not state or not Wardrobe or not WP or not WP.GetSourceByID then return result end
    local totalScore, totalConfidence = 0, 0
    local seen = {}
    for _, definition in ipairs(Wardrobe.slotDefinitions or {}) do
        local slotKey = definition.key
        seen[slotKey] = true
        if not (state.hidden and state.hidden[slotKey]) then
            local sourceID = state.selections and state.selections[slotKey]
            local source = sourceID and WP.GetSourceByID(slotKey, sourceID)
            if source then
                local analysis = Zone.GetZoneAffinity(source, definition, snapshot)
                result.pieces[#result.pieces + 1] = analysis
                result.selected = result.selected + 1
                totalScore = totalScore + analysis.score
                totalConfidence = totalConfidence + analysis.confidence
                result.classifications[analysis.classification] = (result.classifications[analysis.classification] or 0) + 1
            end
        end
    end
    for _, slotKey in ipairs({ "ONE_HAND", "TWO_HAND", "RANGED", "OFF_HAND" }) do
        if not seen[slotKey] and not (state.hidden and state.hidden[slotKey]) then
            local sourceID = state.selections and state.selections[slotKey]
            local source = sourceID and WP.GetSourceByID(slotKey, sourceID)
            if source then
                local definition = Wardrobe.GetSlotDefinition and Wardrobe.GetSlotDefinition(slotKey)
                local analysis = Zone.GetZoneAffinity(source, definition, snapshot)
                result.pieces[#result.pieces + 1] = analysis
                result.selected = result.selected + 1
                totalScore = totalScore + analysis.score
                totalConfidence = totalConfidence + analysis.confidence
                result.classifications[analysis.classification] = (result.classifications[analysis.classification] or 0) + 1
            end
        end
    end
    if result.selected > 0 then result.score = totalScore / result.selected
        result.confidence = totalConfidence / result.selected end
    return result
end

function ZoneStyle.GetZoneAffinity(source, definition, snapshot)
    return Zone.CopyPrimitive(Zone.GetZoneAffinity(source, definition, snapshot))
end
