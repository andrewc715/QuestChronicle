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
    local wardrobePrivate = QC.Wardrobe and QC.Wardrobe._Private
    if wardrobePrivate and wardrobePrivate.GetStableGenerationSourceIdentity then
        return wardrobePrivate.GetStableGenerationSourceIdentity(source)
    end
    return table.concat({
        tostring(source and source.visualID or 0),
        tostring(source and source.sourceID or 0),
        tostring(source and source.itemID or 0),
        tostring(source and source.eraManifestSignature or ""),
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
    local wardrobePrivate = QC.Wardrobe and QC.Wardrobe._Private
    local persistent = wardrobePrivate and wardrobePrivate.GetPersistentGenerationPrecheck
        and wardrobePrivate.GetPersistentGenerationPrecheck(source, key)
    if persistent then
        source.generationPrecheckKey = key
        source.generationPrecheckEligible = persistent.eligible == true
        source.generationPrecheckKind = persistent.kind
        source.generationPrecheckReason = persistent.reason
        CountCacheHit()
        return persistent.eligible == true, persistent.kind, persistent.reason, true
    end
    local eligible, kind, reason = ZoneStyle.GetSourcePreEraEligibility(source, context)
    source.generationPrecheckKey = key
    source.generationPrecheckEligible = eligible == true
    source.generationPrecheckKind = kind
    source.generationPrecheckReason = reason
    if wardrobePrivate and wardrobePrivate.StorePersistentGenerationPrecheck then
        wardrobePrivate.StorePersistentGenerationPrecheck(source, key, eligible, kind, reason)
    end
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

local function CompletedEligibilityWork(source, key, eligible, kind, reason, fromCache)
    return {
        source = source,
        key = key,
        done = true,
        eligible = eligible == true,
        kind = kind,
        reason = reason,
        fromCache = fromCache == true,
    }
end

function ZoneStyle.CreateCachedSourceEligibilityWork(source, modeKey, context, evidence, prechecked)
    if not source then return CompletedEligibilityWork(source, nil, false, "pending", "No appearance source was provided.", false) end
    context = ResolveContext(context)
    if not prechecked then
        local preEligible, preKind, preReason = ZoneStyle.GetSourcePreEraEligibilityCached(source, context)
        if not preEligible then return CompletedEligibilityWork(source, nil, false, preKind, preReason, true) end
    end
    if evidence == nil and ZoneStyle.GetSourceEraEvidence then evidence = ZoneStyle.GetSourceEraEvidence(source) end
    local key = EligibilityKey(source, modeKey, context, evidence)
    if source.generationEligibilityKey == key and source.generationEligibilityEligible ~= nil then
        CountCacheHit()
        return CompletedEligibilityWork(source, key, source.generationEligibilityEligible, source.generationEligibilityKind, source.generationEligibilityReason, true)
    end
    local wardrobePrivate = QC.Wardrobe and QC.Wardrobe._Private
    local persistent = wardrobePrivate and wardrobePrivate.GetPersistentGenerationEligibility
        and wardrobePrivate.GetPersistentGenerationEligibility(source, key)
    if persistent then
        source.generationEligibilityKey = key
        source.generationEligibilityEligible = persistent.eligible == true
        source.generationEligibilityKind = persistent.kind
        source.generationEligibilityReason = persistent.reason
        CountCacheHit()
        return CompletedEligibilityWork(source, key, persistent.eligible, persistent.kind, persistent.reason, true)
    end
    local raw = ZoneStyle.CreateSourceEligibilityWork
        and ZoneStyle.CreateSourceEligibilityWork(source, modeKey, context, evidence, true) or nil
    return {
        source = source,
        key = key,
        modeKey = modeKey,
        context = context,
        evidence = evidence,
        raw = raw,
        legacy = raw == nil,
        done = false,
        fromCache = false,
    }
end

function ZoneStyle.StepCachedSourceEligibilityWork(work, markerBatch)
    if not work then return true, false, "pending", "No cached eligibility work was provided.", false end
    if work.done then return true, work.eligible, work.kind, work.reason, work.fromCache end
    local done, eligible, kind, reason
    if work.legacy then
        eligible, kind, reason = ZoneStyle.GetSourceEligibility(work.source, work.modeKey, work.context, work.evidence, true)
        done = true
    else
        done, eligible, kind, reason = ZoneStyle.StepSourceEligibilityWork(work.raw, markerBatch)
    end
    if not done then return false end
    work.done, work.eligible, work.kind, work.reason = true, eligible == true, kind, reason
    local source = work.source
    source.generationEligibilityKey = work.key
    source.generationEligibilityEligible = work.eligible
    source.generationEligibilityKind = kind
    source.generationEligibilityReason = reason
    local wardrobePrivate = QC.Wardrobe and QC.Wardrobe._Private
    if wardrobePrivate and wardrobePrivate.StorePersistentGenerationEligibility then
        wardrobePrivate.StorePersistentGenerationEligibility(source, work.key, work.eligible, kind, reason)
    end
    return true, work.eligible, kind, reason, false
end

function ZoneStyle.GetSourceEligibilityCached(source, modeKey, context, evidence, prechecked)
    local work = ZoneStyle.CreateCachedSourceEligibilityWork(source, modeKey, context, evidence, prechecked)
    while not work.done do ZoneStyle.StepCachedSourceEligibilityWork(work, 1000000) end
    return work.eligible, work.kind, work.reason, work.fromCache
end
