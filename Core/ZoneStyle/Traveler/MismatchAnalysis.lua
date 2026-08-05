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
    local raw = overlap ~= nil and overlap > 0 and (0.50 + 0.50 * overlap)
        or RelationScore(leftKey, rightKey, relations, fallback)
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

local function SourceID(entry)
    return tonumber(entry and entry.source and entry.source.sourceID)
end

local function IsPrimaryWeaponSlot(slotKey)
    return slotKey == "ONE_HAND" or slotKey == "TWO_HAND" or slotKey == "RANGED"
end

function T.BuildMismatchAnalysisUnits(entries)
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
                        slotKey = entry.slotKey, slotLabel = "Weapon Pair", definition = entry.definition,
                        source = entry.source, descriptor = entry.descriptor,
                        travelerScore = Average(entry.travelerScore, offHand.travelerScore),
                        locked = entry.locked or offHand.locked, linkedHands = true,
                        isWeaponBlock = true, memberCount = 2, members = { entry, offHand },
                    }
                end
            end
            unit.members = unit.members or { entry }
            unit.memberCount = unit.memberCount or 1
            unit.slotProminence = unit.slotProminence or T.SLOT_VISIBILITY_WEIGHTS[unit.slotKey] or 0.40
            units[#units + 1] = unit
        end
    end
    return units
end

function T.GetTravelerProfileCohesion(descriptor, profile)
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

function T.GetTravelerEchoSupport(entry, entries)
    local accent = entry and entry.descriptor and entry.descriptor.dominantPalette
    if not accent then accent = Dominant(entry and entry.descriptor and entry.descriptor.palette) end
    if not accent then return 0 end
    local support = 0
    for _, other in ipairs(entries or {}) do
        if other ~= entry then
            local visibility = other.slotProminence or T.SLOT_VISIBILITY_WEIGHTS[other.slotKey] or 0.40
            support = support + ((other.descriptor and other.descriptor.palette and other.descriptor.palette[accent]) or 0) * visibility
        end
    end
    return Clamp(support, 0, 1)
end

function T.GetTravelerBridgeSupport(components)
    local bestKey, bestValue
    for _, key in ipairs({ "material", "finish", "motif" }) do
        local value = tonumber(components and components[key]) or 0
        if not bestValue or value > bestValue then bestKey, bestValue = key, value end
    end
    return bestValue or 0, bestKey
end

local function ClassificationReason(classification, entry, profileScore, components, echoSupport, bridgeSupport, bridgeKey)
    local accent = entry.descriptor.dominantPalette or Dominant(entry.descriptor.palette) or "unclassified"
    if classification == "POSTAL" then
        return string.format("high-impact %s accent has %.0f%% echo; best bridge is %s %.0f%%", accent, echoSupport * 100, tostring(bridgeKey or "style"), bridgeSupport * 100)
    elseif classification == "COHESIVE" then
        return string.format("completed-outfit profile cohesion %.0f%%", profileScore * 100)
    elseif classification == "SUPPORTED VARIATION" then
        return string.format("variation is supported by %.0f%% echo or completed-outfit cohesion", echoSupport * 100)
    elseif classification == "SUPPORTED" then
        return string.format("high-impact accent is supported by %.0f%% echo and %s bridge", echoSupport * 100, tostring(bridgeKey or "style"))
    elseif classification == "MILD" then
        return "mild completed-outfit deviation"
    end
    return string.format("strong completed-outfit mismatch; best bridge %.0f%%", bridgeSupport * 100)
end

function T.ClassifyTravelerMismatch(entry, profileScore, components, echoSupport)
    local thresholds = T.CONFIG.thresholds
    local prominence = entry.slotProminence or T.SLOT_VISIBILITY_WEIGHTS[entry.slotKey] or 0.40
    local loudness = entry.descriptor.loudness or 0
    local visualImpact = loudness * prominence
    local bridgeSupport, bridgeKey = T.GetTravelerBridgeSupport(components)
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

function T.GetTravelerOutlierSeverity(entry, profileScore, components, echoSupport, bridgeSupport)
    bridgeSupport = tonumber(bridgeSupport) or T.GetTravelerBridgeSupport(components)
    local isolation = 1 - math.max(Clamp(profileScore, 0, 1), Clamp(echoSupport, 0, 1), Clamp(bridgeSupport, 0, 1))
    local loudness = tonumber(entry and entry.visualImpact) or ((entry and entry.descriptor and entry.descriptor.loudness or 0) * (entry and entry.slotProminence or 0.40))
    local finishConflict = 1 - Clamp(components and components.finish, 0, 1)
    local weightConflict = 1 - Clamp(components and components.visualWeight, 0, 1)
    local severity = 0.45 * isolation + 0.30 * loudness + 0.15 * finishConflict + 0.10 * weightConflict
    return Clamp(severity, 0, 1), {
        isolation = Clamp(isolation, 0, 1), loudness = Clamp(loudness, 0, 1),
        finishConflict = Clamp(finishConflict, 0, 1), weightConflict = Clamp(weightConflict, 0, 1),
    }
end

function T.GetTravelerDominantPalette(descriptor)
    return descriptor and (descriptor.dominantPalette or Dominant(descriptor.palette)) or nil
end
