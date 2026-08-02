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
    descriptor.secondaryPalette = nil
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
            local visibility = T.SLOT_VISIBILITY_WEIGHTS[other.slotKey] or 0.40
            support = support + (other.descriptor.palette[accent] or 0) * visibility
        end
    end
    return Clamp(support, 0, 1)
end

local function BridgeSupport(components)
    return math.max(components.material or 0, components.finish or 0, components.motif or 0)
end

local function ClassifyMismatch(entry, profileScore, components, echoSupport)
    local thresholds = T.CONFIG.thresholds
    local loudness = entry.descriptor.loudness or 0
    local bridgeSupport = BridgeSupport(components)
    if loudness >= thresholds.loud and profileScore < thresholds.postalCohesion and echoSupport < thresholds.echo and bridgeSupport < 0.55 then
        return "POSTAL", 3, "isolated loud accent with no palette echo or material/finish bridge", bridgeSupport
    end
    if profileScore >= thresholds.cohesive and not (loudness >= thresholds.loud and echoSupport < thresholds.echo) then
        return "COHESIVE", 0, "supports the established outfit profile", bridgeSupport
    end
    if profileScore >= thresholds.mild and loudness < thresholds.loud then
        return "MILD", 1, "weathered mismatch retains a shared visual bridge", bridgeSupport
    end
    if loudness >= thresholds.loud and (echoSupport >= thresholds.echo or bridgeSupport >= 0.65) then
        return "SUPPORTED", 2, "strong accent is echoed or narratively bridged", bridgeSupport
    end
    if profileScore >= thresholds.postalCohesion or bridgeSupport >= 0.58 then
        return "MILD", 1, "imperfect but connected to the profile", bridgeSupport
    end
    return "STRONG", 2, "weak profile fit without enough isolation to be a hard outlier", bridgeSupport
end

local function MeanAnchorCohesion(anchors)
    local total, count, hardClashes = 0, 0, 0
    for leftIndex = 1, #anchors do
        for rightIndex = leftIndex + 1, #anchors do
            local score = T.GetPairCohesion(anchors[leftIndex].descriptor, anchors[rightIndex].descriptor)
            total = total + score
            count = count + 1
            if score < 0.35 and anchors[leftIndex].descriptor.loudness >= 0.70 and anchors[rightIndex].descriptor.loudness >= 0.70 then
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
    local anchors = {}
    for _, entry in ipairs(entries or {}) do
        local weight = T.ANCHOR_SLOT_WEIGHTS[entry.slotKey]
        if weight then
            entry.profileWeight = weight
            table.insert(anchors, entry)
        end
    end
    if #anchors == 0 then
        for _, entry in ipairs(entries or {}) do
            entry.profileWeight = T.SLOT_VISIBILITY_WEIGHTS[entry.slotKey] or 0.50
            table.insert(anchors, entry)
        end
    end

    local profile = BuildProfileDescriptor(anchors)
    local meanAnchorCohesion, hardClashes = MeanAnchorCohesion(anchors)
    local travelerTotal, travelerCount = 0, 0
    local mismatchUsed, postalCount = 0, 0

    for _, entry in ipairs(entries or {}) do
        local score, components = ProfileCohesion(entry.descriptor, profile)
        local echo = EchoSupport(entry, entries)
        local classification, points, reason, bridge = ClassifyMismatch(entry, score, components, echo)
        entry.profileCohesion = score
        entry.cohesionComponents = components
        entry.echoSupport = echo
        entry.bridgeSupport = bridge
        entry.mismatchClass = classification
        entry.mismatchPoints = points
        entry.mismatchReason = reason
        if points < 3 then mismatchUsed = mismatchUsed + points else postalCount = postalCount + 1 end
        travelerTotal = travelerTotal + (entry.travelerScore or 0)
        travelerCount = travelerCount + 1
    end

    local meanTravelerRaw = travelerCount > 0 and travelerTotal / travelerCount or 0
    local meanTravelerBase = NormalizeTravelerScore(meanTravelerRaw)
    local skeletonScore = 100 * (0.55 * meanTravelerBase + 0.30 * meanAnchorCohesion + 0.10 * 0.85 + 0.05 * (hardClashes == 0 and 0.75 or 0.25)) - hardClashes * 25

    return {
        mode = ZoneStyle.MODE_TRAVELER,
        context = context,
        entries = entries,
        anchors = anchors,
        profile = profile,
        meanTravelerScore = meanTravelerRaw,
        meanTravelerBase = meanTravelerBase,
        meanAnchorCohesion = meanAnchorCohesion,
        hardClashes = hardClashes,
        mismatchBudget = T.DEFAULT_MISMATCH_BUDGET,
        mismatchUsed = mismatchUsed,
        postalCount = postalCount,
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
