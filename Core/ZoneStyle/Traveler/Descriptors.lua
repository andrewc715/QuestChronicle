local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private
local T = ZoneStyle.Traveler

T.descriptorCache = setmetatable({}, { __mode = "k" })

local function Clamp(value, low, high)
    value = tonumber(value) or 0
    if value < low then return low end
    if value > high then return high end
    return value
end

local function AddEvidence(evidence, text)
    if not text or text == "" then return end
    for _, existing in ipairs(evidence) do
        if existing == text then return end
    end
    table.insert(evidence, text)
end

local function AddWeighted(target, key, value)
    value = tonumber(value) or 0
    if key and value > 0 then target[key] = (target[key] or 0) + value end
end

local function NormalizeMap(values)
    local total = 0
    for _, value in pairs(values or {}) do total = total + math.max(0, tonumber(value) or 0) end
    if total <= 0 then return values or {} end
    for key, value in pairs(values) do values[key] = math.max(0, value) / total end
    return values
end

local function CopyMap(values)
    local copy = {}
    for key, value in pairs(values or {}) do copy[key] = value end
    return copy
end

local function ApplyLexicon(text, lexicon, target, evidence, evidenceLabel)
    local hits = 0
    local padded = " " .. tostring(text or "") .. " "
    for family, keywords in pairs(lexicon or {}) do
        local familyScore = 0
        for token, value in pairs(keywords) do
            local normalizedToken = P.Normalize(token)
            if normalizedToken ~= "" and padded:find(" " .. normalizedToken .. " ", 1, true) then
                familyScore = familyScore + value
                hits = hits + 1
            end
        end
        AddWeighted(target, family, familyScore)
    end
    if hits > 0 then AddEvidence(evidence, evidenceLabel) end
    return hits
end

local function Dominant(values)
    local bestKey, bestValue
    for key, value in pairs(values or {}) do
        if not bestValue or value > bestValue then bestKey, bestValue = key, value end
    end
    return bestKey, bestValue or 0
end

local function SlotBaseWeight(definition)
    local key = definition and definition.key
    if key == "SHOULDER" or key == "CHEST" then return 3.3 end
    if key == "HEAD" or key == "LEGS" then return 2.8 end
    if definition and definition.weaponRole then return 3.0 end
    if key == "BACK" or key == "HANDS" or key == "FEET" then return 2.2 end
    if key == "WAIST" or key == "WRIST" then return 1.7 end
    return 1.4
end

local function InferMaterialFromSubtype(source, material, evidence)
    local subtype = P.Normalize(source and source.styleItemSubType)
    if subtype == "" then return 0 end
    local matched
    if subtype:find("plate", 1, true) then matched = "plate"
    elseif subtype:find("mail", 1, true) then matched = "mail"
    elseif subtype:find("leather", 1, true) then matched = "leather"
    elseif subtype:find("cloth", 1, true) then matched = "cloth"
    elseif subtype:find("shield", 1, true) then matched = "plate"
    end
    if matched then
        AddWeighted(material, matched, 8)
        AddEvidence(evidence, "item subtype")
        return 1
    end
    return 0
end

local function ComputeLoudness(text, descriptor, prepared)
    local padded = " " .. tostring(text or "") .. " "
    local loudness = 0.08
    for token, value in pairs(T.LEXICON.loudness or {}) do
        local normalizedToken = P.Normalize(token)
        if normalizedToken ~= "" and padded:find(" " .. normalizedToken .. " ", 1, true) then
            loudness = loudness + value
        end
    end
    local styleSignals = prepared and prepared.styleSignals or (P.GetSourceStyleSignals and P.GetSourceStyleSignals(descriptor.source))
    local intensity = styleSignals and tonumber(styleSignals.intensity) or 0
    loudness = loudness + math.min(0.30, intensity * 0.035)
    if descriptor.definition and descriptor.definition.key == "SHOULDER" then loudness = loudness + 0.08 end
    if descriptor.definition and descriptor.definition.key == "HEAD" then loudness = loudness + 0.05 end
    return Clamp(loudness, 0, 1)
end

local function DescriptorFingerprint(source, definition, text)
    return table.concat({
        tostring(source and source.visualID or ""),
        tostring(source and source.sourceID or ""),
        tostring(source and source.itemID or ""),
        tostring(source and source.styleName or source and source.name or ""),
        tostring(source and source.styleItemSubType or ""),
        tostring(definition and definition.key or source and source.slotKey or ""),
        tostring(text or ""),
        tostring(T.INSTRUMENTATION_VERSION or 0),
        tostring(T.CURATED_TUNING_VERSION or 0),
    }, "|")
end

function T.BuildDescriptor(source, definition, prepared)
    if not source then return nil end
    definition = definition or (QC.Wardrobe and QC.Wardrobe.GetSlotDefinition and QC.Wardrobe.GetSlotDefinition(source.slotKey))
    local text = prepared and prepared.metadataText or P.SourceMetadata(source)
    local expansionID
    if prepared and prepared.expansionIDKnown then
        expansionID = prepared.expansionID
    else
        expansionID = ZoneStyle.GetSourceExpansionID and ZoneStyle.GetSourceExpansionID(source) or source.expansionID
    end
    local fingerprint = DescriptorFingerprint(source, definition, text)
    local cached = T.descriptorCache[source]
    if cached and cached.fingerprint == fingerprint then return cached end

    local descriptor = {
        source = source,
        definition = definition,
        visualID = tonumber(source.visualID),
        sourceID = tonumber(source.sourceID),
        itemID = tonumber(source.itemID),
        slotKey = definition and definition.key or source.slotKey,
        name = source.styleName or source.name or ("Appearance " .. tostring(source.sourceID or 0)),
        text = text,
        fingerprint = fingerprint,
        palette = {},
        material = {},
        finish = {},
        motifs = {},
        evidence = {},
        confidence = {},
        setIDs = prepared and prepared.setIDsKnown and (prepared.setIDs or {}) or (P.GetSourceSetIDs and P.GetSourceSetIDs(source) or {}),
        expansionID = expansionID,
    }

    local paletteHits = ApplyLexicon(text, T.LEXICON.palette, descriptor.palette, descriptor.evidence, "name palette lexicon")
    local materialHits = ApplyLexicon(text, T.LEXICON.material, descriptor.material, descriptor.evidence, "name material lexicon")
    materialHits = materialHits + InferMaterialFromSubtype(source, descriptor.material, descriptor.evidence)
    local finishHits = ApplyLexicon(text, T.LEXICON.finish, descriptor.finish, descriptor.evidence, "name finish lexicon")
    local motifHits = ApplyLexicon(text, T.LEXICON.motif, descriptor.motifs, descriptor.evidence, "name motif lexicon")
    if T.ApplyCuratedDescriptorOverride then T.ApplyCuratedDescriptorOverride(descriptor) end

    NormalizeMap(descriptor.palette)
    NormalizeMap(descriptor.material)
    NormalizeMap(descriptor.finish)
    NormalizeMap(descriptor.motifs)
    descriptor.echoPalette = T.BuildTravelerEchoPalette and T.BuildTravelerEchoPalette(descriptor) or CopyMap(descriptor.palette)

    descriptor.dominantPalette, descriptor.dominantPaletteStrength = Dominant(descriptor.palette)
    descriptor.dominantMaterial, descriptor.dominantMaterialStrength = Dominant(descriptor.material)
    descriptor.dominantFinish, descriptor.dominantFinishStrength = Dominant(descriptor.finish)
    descriptor.dominantMotif, descriptor.dominantMotifStrength = Dominant(descriptor.motifs)

    descriptor.confidence.palette = descriptor.curatedFields and descriptor.curatedFields.palette
        and (T.CURATED_CONFIDENCE or 0.95) or (paletteHits > 0 and 0.70 or 0.00)
    descriptor.confidence.material = materialHits > 0 and (source.styleItemSubType and 0.90 or 0.68) or 0.00
    descriptor.confidence.finish = descriptor.curatedFields and descriptor.curatedFields.finish
        and (T.CURATED_CONFIDENCE or 0.95) or (finishHits > 0 and 0.66 or 0.00)
    descriptor.confidence.motifs = motifHits > 0 and 0.58 or 0.00
    descriptor.confidence.provenance = descriptor.expansionID ~= nil and 0.75 or (#descriptor.setIDs > 0 and 0.65 or 0.00)

    local visualWeight = SlotBaseWeight(definition)
    if descriptor.dominantMaterial == "plate" or descriptor.dominantMaterial == "scale" then visualWeight = visualWeight + 0.35 end
    if descriptor.dominantMaterial == "cloth" then visualWeight = visualWeight - 0.35 end
    if text:find("lightweight", 1, true) or text:find("slender", 1, true) then visualWeight = visualWeight - 0.50 end
    if text:find("heavy", 1, true) or text:find("colossal", 1, true) or text:find("massive", 1, true) then visualWeight = visualWeight + 0.55 end
    descriptor.visualWeight = Clamp(visualWeight, 1, 4)
    descriptor.confidence.visualWeight = definition and 0.72 or 0.40
    descriptor.loudness = ComputeLoudness(text, descriptor, prepared)

    T.descriptorCache[source] = descriptor
    return descriptor
end

function T.InvalidateDescriptor(source)
    if source then T.descriptorCache[source] = nil end
end

function T.GetDescriptor(source, definition, prepared)
    return T.BuildDescriptor(source, definition, prepared)
end

function ZoneStyle.GetTravelerDescriptor(source, definition, prepared)
    return T.GetDescriptor(source, definition, prepared)
end
