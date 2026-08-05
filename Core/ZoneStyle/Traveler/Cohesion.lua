local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local T = ZoneStyle.Traveler

local function Clamp(value, low, high)
    value = tonumber(value) or 0
    if value < low then return low end
    if value > high then return high end
    return value
end

local function Average(left, right)
    return ((tonumber(left) or 0) + (tonumber(right) or 0)) * 0.5
end

local function Round(value, places)
    local scale = 10 ^ (places or 0)
    return math.floor((tonumber(value) or 0) * scale + 0.5) / scale
end

local function FormatPercent(value)
    return string.format("%.0f%%", Clamp(value, 0, 1) * 100)
end

local function MapTotal(values)
    local total = 0
    for _, value in pairs(values or {}) do total = total + math.max(0, tonumber(value) or 0) end
    return total
end

local function MapOverlap(left, right)
    local leftTotal, rightTotal = MapTotal(left), MapTotal(right)
    if leftTotal <= 0 or rightTotal <= 0 then return nil end
    local overlap = 0
    for key, value in pairs(left or {}) do overlap = overlap + math.min(value, right[key] or 0) end
    return Clamp(overlap / math.min(leftTotal, rightTotal), 0, 1)
end

local function Dominant(values)
    local bestKey, bestValue
    for key, value in pairs(values or {}) do
        if not bestValue or value > bestValue then bestKey, bestValue = key, value end
    end
    return bestKey, bestValue or 0
end

local function RelationScore(leftKey, rightKey, relations, fallback)
    if not leftKey or not rightKey then return 0.50 end
    if leftKey == rightKey then return 1.00 end
    local left = relations and relations[leftKey]
    local right = relations and relations[rightKey]
    return (left and left[rightKey]) or (right and right[leftKey]) or fallback or 0.35
end

local function AdjustForConfidence(raw, leftConfidence, rightConfidence)
    local confidence = Clamp(Average(leftConfidence, rightConfidence), 0, 1)
    return 0.50 + confidence * (Clamp(raw, 0, 1) - 0.50)
end

local function VectorCompatibility(left, right, family, relations, fallback)
    local leftMap = left and left[family] or {}
    local rightMap = right and right[family] or {}
    local overlap = MapOverlap(leftMap, rightMap)
    local leftKey = Dominant(leftMap)
    local rightKey = Dominant(rightMap)
    local raw = overlap ~= nil and overlap > 0 and (0.50 + 0.50 * overlap) or RelationScore(leftKey, rightKey, relations, fallback)
    return AdjustForConfidence(raw, left and left.confidence and left.confidence[family], right and right.confidence and right.confidence[family])
end

local function WeightCompatibility(left, right)
    if not left or not right then return 0.50 end
    local difference = math.abs((left.visualWeight or 2.5) - (right.visualWeight or 2.5))
    local raw
    if difference <= 0.35 then raw = 1.00
    elseif difference <= 1.00 then raw = 0.75
    elseif difference <= 2.00 then raw = 0.40
    else raw = 0.10 end
    return AdjustForConfidence(raw, left.confidence and left.confidence.visualWeight, right.confidence and right.confidence.visualWeight)
end

local function ProvenanceCompatibility(left, right)
    if not left or not right then return 0.50 end
    for _, leftSet in ipairs(left.setIDs or {}) do
        for _, rightSet in ipairs(right.setIDs or {}) do
            if leftSet == rightSet then return 1.00 end
        end
    end
    if left.expansionID ~= nil and right.expansionID ~= nil then
        return left.expansionID == right.expansionID and 0.78 or 0.44
    end
    return 0.50
end

function T.GetPairCohesion(left, right)
    local components = {
        palette = VectorCompatibility(left, right, "palette", T.PALETTE_RELATIONS, 0.32),
        material = VectorCompatibility(left, right, "material", T.MATERIAL_RELATIONS, 0.38),
        finish = VectorCompatibility(left, right, "finish", T.FINISH_RELATIONS, 0.38),
        visualWeight = WeightCompatibility(left, right),
        motif = VectorCompatibility(left, right, "motifs", nil, 0.42),
        provenance = ProvenanceCompatibility(left, right),
    }
    local score = 0
    for key, weight in pairs(T.CONFIG.pairWeights) do score = score + weight * (components[key] or 0.50) end
    return Clamp(score, 0, 1), components
end

local function SourceID(entry)
    return tonumber(entry and entry.source and entry.source.sourceID)
end

local function IsPrimaryWeaponSlot(slotKey)
    return slotKey == "ONE_HAND" or slotKey == "TWO_HAND" or slotKey == "RANGED"
end

local function BuildAnalysisUnits(entries)
    local units, consumed = {}, {}
    local offHandIndex
    for index, entry in ipairs(entries or {}) do
        if entry.slotKey == "OFF_HAND" then offHandIndex = index end
    end

    for index, entry in ipairs(entries or {}) do
        if not consumed[index] then
            local unit = entry
            if IsPrimaryWeaponSlot(entry.slotKey) and entry.linkedHands and offHandIndex and not consumed[offHandIndex] then
                local offHand = entries[offHandIndex]
                if SourceID(entry) and SourceID(entry) == SourceID(offHand) then
                    consumed[offHandIndex] = true
                    unit = {
                        slotKey = entry.slotKey,
                        slotLabel = "Weapon Pair",
                        definition = entry.definition,
                        source = entry.source,
                        descriptor = entry.descriptor,
                        travelerScore = Average(entry.travelerScore, offHand.travelerScore),
                        locked = entry.locked or offHand.locked,
                        linkedHands = true,
                        isWeaponBlock = true,
                        memberCount = 2,
                        members = { entry, offHand },
                    }
                end
            end
            unit.members = unit.members or { entry }
            unit.memberCount = unit.memberCount or 1
            unit.slotProminence = T.SLOT_VISIBILITY_WEIGHTS[unit.slotKey] or 0.40
            table.insert(units, unit)
        end
    end
    return units
end

local function AggregateMap(entries, field)
    local values, totalWeight = {}, 0
    for _, entry in ipairs(entries or {}) do
        local weight = tonumber(entry.profileWeight) or 1
        local descriptor = entry.descriptor
        for key, value in pairs(descriptor and descriptor[field] or {}) do
            values[key] = (values[key] or 0) + value * weight
        end
        totalWeight = totalWeight + weight
    end
    if totalWeight > 0 then
        local total = MapTotal(values)
        if total > 0 then for key, value in pairs(values) do values[key] = value / total end end
    end
    return values
end

local function AggregateConfidence(entries, field)
    local total, weightTotal = 0, 0
    for _, entry in ipairs(entries or {}) do
        local weight = tonumber(entry.profileWeight) or 1
        total = total + (entry.descriptor.confidence[field] or 0) * weight
        weightTotal = weightTotal + weight
    end
    return weightTotal > 0 and total / weightTotal or 0
end

local function BuildProfileDescriptor(anchors)
    local descriptor = {
        palette = AggregateMap(anchors, "palette"),
        material = AggregateMap(anchors, "material"),
        finish = AggregateMap(anchors, "finish"),
        motifs = AggregateMap(anchors, "motifs"),
        confidence = {
            palette = AggregateConfidence(anchors, "palette"),
            material = AggregateConfidence(anchors, "material"),
            finish = AggregateConfidence(anchors, "finish"),
            motifs = AggregateConfidence(anchors, "motifs"),
            visualWeight = AggregateConfidence(anchors, "visualWeight"),
        },
        visualWeight = 0,
    }
    local totalWeight = 0
    for _, entry in ipairs(anchors or {}) do
        local weight = tonumber(entry.profileWeight) or 1
        descriptor.visualWeight = descriptor.visualWeight + (entry.descriptor.visualWeight or 2.5) * weight
        totalWeight = totalWeight + weight
    end
    descriptor.visualWeight = totalWeight > 0 and descriptor.visualWeight / totalWeight or 2.5
    descriptor.dominantPalette, descriptor.dominantPaletteStrength = Dominant(descriptor.palette)
    local secondValue = -1
    for key, value in pairs(descriptor.palette) do
        if key ~= descriptor.dominantPalette and value > secondValue then descriptor.secondaryPalette, secondValue = key, value end
    end
    descriptor.dominantMaterial = Dominant(descriptor.material)
    descriptor.dominantFinish = Dominant(descriptor.finish)
    descriptor.dominantMotif = Dominant(descriptor.motifs)
    return descriptor
end

local function ProfileCohesion(descriptor, profile)
    local components = {
        palette = VectorCompatibility(descriptor, profile, "palette", T.PALETTE_RELATIONS, 0.32),
        material = VectorCompatibility(descriptor, profile, "material", T.MATERIAL_RELATIONS, 0.38),
        finish = VectorCompatibility(descriptor, profile, "finish", T.FINISH_RELATIONS, 0.38),
        visualWeight = WeightCompatibility(descriptor, profile),
        motif = VectorCompatibility(descriptor, profile, "motifs", nil, 0.42),
    }
    local score = 0
    for key, weight in pairs(T.CONFIG.profileWeights) do score = score + weight * (components[key] or 0.50) end
    return Clamp(score, 0, 1), components
end

local function EchoSupport(entry, entries)
    local accent = entry.descriptor.dominantPalette
    if not accent then return 0 end
    local support = 0
    for _, other in ipairs(entries or {}) do
        if other ~= entry then
            local visibility = other.slotProminence or T.SLOT_VISIBILITY_WEIGHTS[other.slotKey] or 0.40
            support = support + (other.descriptor.palette[accent] or 0) * visibility
        end
    end
    return Clamp(support, 0, 1)
end

local COMPONENT_LABELS = {
    palette = "palette",
    material = "material",
    finish = "finish",
    visualWeight = "visual weight",
    motif = "motif",
}

local function ComponentExtremes(components)
    local strongestKey, strongestValue, weakestKey, weakestValue
    for key, value in pairs(components or {}) do
        if COMPONENT_LABELS[key] then
            if not strongestValue or value > strongestValue then strongestKey, strongestValue = key, value end
            if not weakestValue or value < weakestValue then weakestKey, weakestValue = key, value end
        end
    end
    return strongestKey, strongestValue or 0.50, weakestKey, weakestValue or 0.50
end

local function BridgeSupport(components)
    local bestKey, bestValue
    for _, key in ipairs({ "material", "finish", "motif" }) do
        local value = components[key] or 0
        if not bestValue or value > bestValue then bestKey, bestValue = key, value end
    end
    return bestValue or 0, bestKey
end

local function ClassificationReason(classification, entry, profileScore, components, echoSupport, bridgeSupport, bridgeKey)
    local strongestKey, strongestValue, weakestKey, weakestValue = ComponentExtremes(components)
    local accent = entry.descriptor.dominantPalette or "unclassified"
    if classification == "POSTAL" then
        return string.format(
            "high-impact %s accent (%s) has %s echo; best bridge is %s %s",
            accent, FormatPercent(entry.visualImpact), FormatPercent(echoSupport),
            COMPONENT_LABELS[bridgeKey] or "style", FormatPercent(bridgeSupport)
        )
    end
    if classification == "COHESIVE" then
        return string.format(
            "profile fit is led by %s %s; weakest fit is %s %s",
            COMPONENT_LABELS[strongestKey] or "style", FormatPercent(strongestValue),
            COMPONENT_LABELS[weakestKey] or "style", FormatPercent(weakestValue)
        )
    end
    if classification == "SUPPORTED VARIATION" then
        if echoSupport >= T.CONFIG.thresholds.echo then
            return string.format("%s accent is echoed at %s; visual impact is only %s", accent, FormatPercent(echoSupport), FormatPercent(entry.visualImpact))
        end
        return string.format("overall profile cohesion %s absorbs the variation; strongest bridge is %s %s", FormatPercent(profileScore), COMPONENT_LABELS[strongestKey] or "style", FormatPercent(strongestValue))
    end
    if classification == "SUPPORTED" then
        return string.format("high-impact %s accent (%s) is supported by %s echo and %s %s", accent, FormatPercent(entry.visualImpact), FormatPercent(echoSupport), COMPONENT_LABELS[bridgeKey] or "style", FormatPercent(bridgeSupport))
    end
    if classification == "MILD" then
        return string.format("mild %s deviation (%s); %s %s provides the bridge", COMPONENT_LABELS[weakestKey] or "style", FormatPercent(weakestValue), COMPONENT_LABELS[strongestKey] or "style", FormatPercent(strongestValue))
    end
    return string.format("weak %s fit (%s); best bridge is %s %s", COMPONENT_LABELS[weakestKey] or "style", FormatPercent(weakestValue), COMPONENT_LABELS[bridgeKey] or "style", FormatPercent(bridgeSupport))
end

local function ClassifyMismatch(entry, profileScore, components, echoSupport)
    local thresholds = T.CONFIG.thresholds
    local prominence = entry.slotProminence or T.SLOT_VISIBILITY_WEIGHTS[entry.slotKey] or 0.40
    local loudness = entry.descriptor.loudness or 0
    local visualImpact = loudness * prominence
    local bridgeSupport, bridgeKey = BridgeSupport(components)
    local highImpact = visualImpact >= thresholds.loudImpact
    entry.intrinsicLoudness = loudness
    entry.visualImpact = visualImpact

    local classification, cost
    if highImpact and profileScore < thresholds.postalCohesion and echoSupport < thresholds.echo and bridgeSupport < thresholds.postalBridge then
        classification, cost = "POSTAL", 0
    elseif profileScore >= thresholds.cohesive then
        classification, cost = "COHESIVE", 0
    elseif highImpact and profileScore < thresholds.supportedCohesion and (echoSupport >= thresholds.echo or bridgeSupport >= thresholds.strongBridge) then
        classification, cost = "SUPPORTED", prominence
    elseif profileScore >= thresholds.supportedCohesion or echoSupport >= thresholds.echo then
        classification, cost = "SUPPORTED VARIATION", 0
    elseif profileScore >= thresholds.mild or bridgeSupport >= thresholds.mildBridge then
        classification, cost = "MILD", 0.5 * prominence
    elseif prominence <= 0.30 and profileScore >= thresholds.postalCohesion and not highImpact then
        classification, cost = "MILD", 0.5 * prominence
    else
        classification, cost = "STRONG", prominence
    end

    return classification, Round(cost, 2), ClassificationReason(classification, entry, profileScore, components, echoSupport, bridgeSupport, bridgeKey), bridgeSupport, bridgeKey
end

local function MeanAnchorCohesion(anchors)
    local total, count, hardClashes = 0, 0, 0
    for leftIndex = 1, #anchors do
        for rightIndex = leftIndex + 1, #anchors do
            local left, right = anchors[leftIndex], anchors[rightIndex]
            local score = T.GetPairCohesion(left.descriptor, right.descriptor)
            total = total + score
            count = count + 1
            local leftImpact = (left.descriptor.loudness or 0) * (left.slotProminence or 0.40)
            local rightImpact = (right.descriptor.loudness or 0) * (right.slotProminence or 0.40)
            if score < 0.35 and leftImpact >= T.CONFIG.thresholds.loudImpact and rightImpact >= T.CONFIG.thresholds.loudImpact then
                hardClashes = hardClashes + 1
            end
        end
    end
    return count > 0 and total / count or 0.50, hardClashes
end

local function NormalizeTravelerScore(score)
    return Clamp((tonumber(score) or 0) / 35, 0, 1)
end

function T.AnalyzeEntries(entries, context)
    local selectedAppearanceCount = #(entries or {})
    local units = T.BuildMismatchAnalysisUnits and T.BuildMismatchAnalysisUnits(entries or {}) or BuildAnalysisUnits(entries or {})
    local anchors = {}
    for _, entry in ipairs(units) do
        local weight = T.ANCHOR_SLOT_WEIGHTS[entry.slotKey]
        if weight then
            entry.profileWeight = weight
            table.insert(anchors, entry)
        end
    end
    if #anchors == 0 then
        for _, entry in ipairs(units) do
            entry.profileWeight = entry.slotProminence or 0.50
            table.insert(anchors, entry)
        end
    end

    local profile = BuildProfileDescriptor(anchors)
    local meanAnchorCohesion, hardClashes = MeanAnchorCohesion(anchors)
    local travelerTotal, travelerCount = 0, 0
    local mismatchUsed, postalCount, supportedVariationCount = 0, 0, 0

    for _, entry in ipairs(units) do
        local score, components
        if T.GetTravelerProfileCohesion then score, components = T.GetTravelerProfileCohesion(entry.descriptor, profile)
        else score, components = ProfileCohesion(entry.descriptor, profile) end
        local echo
        if T.GetTravelerEchoSupport then echo = T.GetTravelerEchoSupport(entry, units)
        else echo = EchoSupport(entry, units) end
        local classification, points, reason, bridge, bridgeKey
        if T.ClassifyTravelerMismatch then
            classification, points, reason, bridge, bridgeKey = T.ClassifyTravelerMismatch(entry, score, components, echo)
        else
            classification, points, reason, bridge, bridgeKey = ClassifyMismatch(entry, score, components, echo)
        end
        entry.profileCohesion = score
        entry.cohesionComponents = components
        entry.echoSupport = echo
        entry.bridgeSupport = bridge
        entry.bridgeType = bridgeKey
        entry.mismatchClass = classification
        entry.mismatchPoints = points
        entry.mismatchReason = reason
        if classification == "POSTAL" then postalCount = postalCount + 1
        else mismatchUsed = mismatchUsed + points end
        if classification == "SUPPORTED VARIATION" then supportedVariationCount = supportedVariationCount + 1 end
        travelerTotal = travelerTotal + (entry.travelerScore or 0)
        travelerCount = travelerCount + 1
    end

    local meanTravelerRaw = travelerCount > 0 and travelerTotal / travelerCount or 0
    local meanTravelerBase = NormalizeTravelerScore(meanTravelerRaw)
    local skeletonScore = 100 * (0.55 * meanTravelerBase + 0.30 * meanAnchorCohesion + 0.10 * 0.85 + 0.05 * (hardClashes == 0 and 0.75 or 0.25)) - hardClashes * 25

    return {
        mode = ZoneStyle.MODE_TRAVELER,
        context = context,
        entries = units,
        selectedAppearanceCount = selectedAppearanceCount,
        analysisBlockCount = #units,
        anchors = anchors,
        profile = profile,
        meanTravelerScore = meanTravelerRaw,
        meanTravelerBase = meanTravelerBase,
        meanAnchorCohesion = meanAnchorCohesion,
        hardClashes = hardClashes,
        mismatchBudget = T.DEFAULT_MISMATCH_BUDGET,
        mismatchUsed = Round(mismatchUsed, 2),
        postalCount = postalCount,
        supportedVariationCount = supportedVariationCount,
        skeletonScore = skeletonScore,
        instrumentationVersion = T.INSTRUMENTATION_VERSION,
        analyzedAt = time and time() or 0,
    }
end

function ZoneStyle.GetTravelerPairCohesion(leftSource, rightSource, leftDefinition, rightDefinition)
    local left = T.GetDescriptor(leftSource, leftDefinition)
    local right = T.GetDescriptor(rightSource, rightDefinition)
    return T.GetPairCohesion(left, right)
end
