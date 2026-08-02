local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local P = ZoneStyle._Private

P.GENERATION_ELIGIBILITY_VERSION = 2

local function ResolveContext(context)
    context = context or ZoneStyle.GetCurrentContext()
    if context.eraMax == nil then
        context.eraMax, context.eraLabel, context.eraShortLabel = ZoneStyle.ResolveEra(context)
    end
    if not context.provenanceResolved then
        local resolved, resolvedKey = ZoneStyle.ResolveProvenance(context)
        context.provenanceKey = resolvedKey
        context.provenanceLabel = resolved and resolved.label or context.zone
        context.provenanceResolved = true
    end
    return context
end

local function PlayerKey()
    local classID, raceFile, raceID
    if type(UnitClass) == "function" then _, _, classID = UnitClass("player") end
    if type(UnitRace) == "function" then _, raceFile, raceID = UnitRace("player") end
    local currentLevel = tonumber(UnitLevel and UnitLevel("player")) or 0
    local maxLevel = P.GetReachableMaxPlayerLevel and P.GetReachableMaxPlayerLevel() or 0
    return table.concat({
        tostring(classID or 0), tostring(raceFile or ""), tostring(raceID or 0),
        tostring(currentLevel), tostring(maxLevel or 0),
    }, ":")
end

function ZoneStyle.PrepareGenerationEligibilityContext(context)
    context = ResolveContext(context)
    local settings = QC.GetSettings and QC.GetSettings() or {}
    local zoneKey = QC.Wardrobe and QC.Wardrobe.GetZonePreferenceKey
        and QC.Wardrobe.GetZonePreferenceKey(context) or ""
    context.generationEligibilityContextKey = table.concat({
        tostring(P.GENERATION_ELIGIBILITY_VERSION),
        PlayerKey(),
        tostring(zoneKey or ""),
        tostring(context.eraMax or ""),
        tostring(context.provenanceKey or ""),
        tostring(settings.restrictOutfitsToZoneEra ~= false),
    }, "|")
    return context
end

local function ContextKey(context)
    context = ResolveContext(context)
    if not context.generationEligibilityContextKey then
        ZoneStyle.PrepareGenerationEligibilityContext(context)
    end
    return context.generationEligibilityContextKey, context
end

local function PreferenceKey(source, context)
    local preference = ZoneStyle.GetSourcePreference(source, context)
    return tostring(preference or "none"), preference
end

local function SourceIdentity(source)
    return table.concat({
        tostring(source and source.visualID or 0),
        tostring(source and source.sourceID or 0),
        tostring(source and source.itemID or 0),
        tostring(source and source.metadataRevision or 0),
    }, ":")
end

local function PrecheckKey(source, context)
    local contextKey = ContextKey(context)
    local preferenceKey = PreferenceKey(source, context)
    return table.concat({ contextKey, SourceIdentity(source), preferenceKey }, "|")
end

local function CountCacheHit()
    local wardrobePrivate = QC.Wardrobe and QC.Wardrobe._Private
    if wardrobePrivate and wardrobePrivate.generationJob then
        wardrobePrivate.generationJob.eligibilityCacheHits =
            (wardrobePrivate.generationJob.eligibilityCacheHits or 0) + 1
    end
end

function ZoneStyle.GetSourcePreEraEligibilityCached(source, context)
    if not source then return false, "pending", "No appearance source was provided.", false end
    context = context or ZoneStyle.GetCurrentContext()
    local key = PrecheckKey(source, context)
    if source.generationPrecheckKey == key and source.generationPrecheckEligible ~= nil then
        CountCacheHit()
        return source.generationPrecheckEligible == true,
            source.generationPrecheckKind,
            source.generationPrecheckReason,
            true
    end
    local eligible, kind, reason = ZoneStyle.GetSourcePreEraEligibility(source, context)
    source.generationPrecheckKey = key
    source.generationPrecheckEligible = eligible == true
    source.generationPrecheckKind = kind
    source.generationPrecheckReason = reason
    return eligible == true, kind, reason, false
end

local function EvidenceKey(evidence)
    evidence = evidence or {}
    return table.concat({
        tostring(evidence.expansionID or ""),
        tostring(evidence.method or ""),
        tostring(evidence.sourceID or ""),
        tostring(evidence.pending == true),
        tostring(evidence.unknown == true),
        tostring(evidence.candidateCount or 0),
    }, ":")
end

local function EligibilityKey(source, modeKey, context, evidence)
    local contextKey = ContextKey(context)
    local preferenceKey = PreferenceKey(source, context)
    return table.concat({
        contextKey,
        tostring(modeKey or ""),
        SourceIdentity(source),
        preferenceKey,
        EvidenceKey(evidence),
    }, "|")
end

function ZoneStyle.GetSourceEligibilityCached(source, modeKey, context, evidence, prechecked)
    if not source then return false, "pending", "No appearance source was provided.", false end
    context = ResolveContext(context)
    if not prechecked then
        local preEligible, preKind, preReason = ZoneStyle.GetSourcePreEraEligibilityCached(source, context)
        if not preEligible then return false, preKind, preReason, true end
    end
    if evidence == nil and ZoneStyle.GetSourceEraEvidence then
        evidence = ZoneStyle.GetSourceEraEvidence(source)
    end
    local key = EligibilityKey(source, modeKey, context, evidence)
    if source.generationEligibilityKey == key and source.generationEligibilityEligible ~= nil then
        CountCacheHit()
        return source.generationEligibilityEligible == true,
            source.generationEligibilityKind,
            source.generationEligibilityReason,
            true
    end
    local eligible, kind, reason = ZoneStyle.GetSourceEligibility(source, modeKey, context, evidence, true)
    source.generationEligibilityKey = key
    source.generationEligibilityEligible = eligible == true
    source.generationEligibilityKind = kind
    source.generationEligibilityReason = reason
    return eligible == true, kind, reason, false
end
