local QC = QuestChronicle
local Wardrobe = QC.Wardrobe
local P = Wardrobe._Private

P.ANCHOR_SLOT_ORDER = { "CHEST", "LEGS", "SHOULDER" }
P.SUPPORTING_ARMOR_GENERATION_ORDER = { "WAIST", "HEAD", "HANDS", "FEET", "WRIST", "BACK", "SHIRT", "TABARD" }
P.ANCHOR_POOL_LIMITS = { CHEST = 48, LEGS = 32, SHOULDER = 32 }
P.ANCHOR_BEAM_WIDTH = 32
P.ANCHOR_WEAPON_EXPANSION_LIMIT = 4
P.ANCHOR_FINAL_SHORTLIST = 6
P.ANCHOR_FINAL_SCORE_WINDOW = 28
P.ANCHOR_PAIR_CACHE_LIMIT = 4096
P.ANCHOR_SCORING_VERSION = 1

P.anchorPairCache = P.anchorPairCache or {
    values = {},
    order = {},
    size = 0,
    hits = 0,
    misses = 0,
}

local function Clamp(value, low, high)
    value = tonumber(value) or 0
    if value < low then return low end
    if value > high then return high end
    return value
end

local function SourceIdentity(source)
    return tostring(source and (source.visualID or source.sourceID or source.itemID) or "")
end

local function DescriptorFingerprint(source, definition)
    local style = QC.ZoneStyle
    local descriptor = style and style.GetTravelerDescriptor and style.GetTravelerDescriptor(source, definition)
    return descriptor and descriptor.fingerprint or table.concat({
        SourceIdentity(source),
        tostring(definition and definition.key or source and source.slotKey or ""),
        tostring(P.ANCHOR_SCORING_VERSION),
    }, ":"), descriptor
end

local function PairKey(leftSource, rightSource, leftDefinition, rightDefinition)
    local leftKey, leftDescriptor = DescriptorFingerprint(leftSource, leftDefinition)
    local rightKey, rightDescriptor = DescriptorFingerprint(rightSource, rightDefinition)
    if leftKey > rightKey then
        leftKey, rightKey = rightKey, leftKey
        leftDescriptor, rightDescriptor = rightDescriptor, leftDescriptor
    end
    return table.concat({
        tostring(P.ANCHOR_SCORING_VERSION),
        leftKey,
        rightKey,
    }, "|"), leftDescriptor, rightDescriptor
end

local function TrimPairCache(cache)
    local limit = tonumber(P.ANCHOR_PAIR_CACHE_LIMIT) or 4096
    if cache.size <= limit then return end
    local removeCount = math.max(1, math.floor(limit * 0.25))
    for _ = 1, removeCount do
        local key = table.remove(cache.order, 1)
        if key and cache.values[key] then
            cache.values[key] = nil
            cache.size = cache.size - 1
        end
    end
end

function P.GetAnchorPairCohesion(leftSource, rightSource, leftDefinition, rightDefinition)
    if not leftSource or not rightSource then return 0.50, nil end
    local cache = P.anchorPairCache
    local key, leftDescriptor, rightDescriptor = PairKey(leftSource, rightSource, leftDefinition, rightDefinition)
    local cached = cache.values[key]
    if cached then
        cache.hits = cache.hits + 1
        return cached.score, cached.components
    end

    local score, components = 0.50, nil
    local traveler = QC.ZoneStyle and QC.ZoneStyle.Traveler
    if traveler and traveler.GetPairCohesion and leftDescriptor and rightDescriptor then
        score, components = traveler.GetPairCohesion(leftDescriptor, rightDescriptor)
    elseif QC.ZoneStyle and QC.ZoneStyle.GetTravelerPairCohesion then
        score, components = QC.ZoneStyle.GetTravelerPairCohesion(leftSource, rightSource, leftDefinition, rightDefinition)
    end
    score = Clamp(score, 0, 1)
    cache.values[key] = { score = score, components = components }
    cache.order[#cache.order + 1] = key
    cache.size = cache.size + 1
    cache.misses = cache.misses + 1
    TrimPairCache(cache)
    return score, components
end

function P.GetAnchorPairCacheSnapshot()
    local cache = P.anchorPairCache
    return {
        hits = tonumber(cache.hits) or 0,
        misses = tonumber(cache.misses) or 0,
        size = tonumber(cache.size) or 0,
    }
end

function P.BuildAnchorCandidate(source, definition, styleMode, styleContext, fixed)
    if not source or not definition then return nil end
    local style = QC.ZoneStyle
    local coherenceScore, coherent, coherenceReason = 0, true, nil
    if style and style.GetSourceCoherence then
        coherenceScore, coherent, coherenceReason = style.GetSourceCoherence(source, styleContext)
        if coherent == false and not fixed then return nil end
        if fixed then coherent = true end
    end

    local score, scoreReasons = 10, {}
    if style and style.ScoreSource then
        score, scoreReasons = style.ScoreSource(source, definition, styleMode, styleContext, coherenceScore, coherent, coherenceReason)
    end
    local descriptor = style and style.GetTravelerDescriptor and style.GetTravelerDescriptor(source, definition)
    local weight = math.max(1, (tonumber(score) or 0) + 4) ^ 2
    local randomValue = math.max(0.000001, math.random())
    return {
        source = source,
        definition = definition,
        slotKey = definition.key,
        baseScore = tonumber(score) or 0,
        scoreReasons = scoreReasons,
        weight = weight,
        poolRandomValue = randomValue,
        poolPriority = math.log(randomValue) / weight,
        descriptor = descriptor,
        diversityKey = descriptor and ((descriptor.setIDs and descriptor.setIDs[1] and ("SET:" .. tostring(descriptor.setIDs[1])))
            or table.concat({ descriptor.dominantMaterial or "?", descriptor.dominantMotif or "?", descriptor.dominantPalette or "?" }, ":"))
            or ("VISUAL:" .. SourceIdentity(source)),
        coherenceScore = coherenceScore,
        coherenceReason = coherenceReason,
    }
end

function P.ScoreAnchorRelationship(left, right)
    local pairScore, components = P.GetAnchorPairCohesion(
        left.source,
        right.source,
        left.definition,
        right.definition
    )
    local leftLoudness = left.descriptor and left.descriptor.loudness or 0.25
    local rightLoudness = right.descriptor and right.descriptor.loudness or 0.25
    local loudnessBalance = 1 - math.abs(leftLoudness - rightLoudness)
    local pairBonus = (pairScore - 0.50) * 44 + Clamp(loudnessBalance, 0, 1) * 4
    local hardClash = pairScore < 0.30 and leftLoudness >= 0.60 and rightLoudness >= 0.60
    if hardClash then pairBonus = pairBonus - 28 end
    return pairBonus, pairScore, components, hardClash
end

function P.AnchorSkeletonSignature(sourceBySlot, weaponRoute)
    local parts = {}
    for _, slotKey in ipairs(P.ANCHOR_SLOT_ORDER) do
        local candidate = sourceBySlot and sourceBySlot[slotKey]
        parts[#parts + 1] = slotKey .. "=" .. SourceIdentity(candidate and candidate.source or candidate)
    end
    local route = weaponRoute or {}
    parts[#parts + 1] = "W=" .. tostring(route.mainSourceID or "") .. ":" .. tostring(route.offSourceID or "")
    return table.concat(parts, "|")
end
