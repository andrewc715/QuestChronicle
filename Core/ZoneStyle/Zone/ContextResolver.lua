local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone
local P = ZoneStyle._Private

Zone.snapshotCache = Zone.snapshotCache or {}
Zone.snapshotBuildCount = Zone.snapshotBuildCount or 0

local SOURCE_LEVELS = {
    { field = "subzone", level = "EXACT_SUBZONE", channel = "SUBZONE_NAME" },
    { field = "zone", level = "EXACT_ZONE", channel = "ZONE_NAME" },
    { field = "mapName", level = "EXACT_MAP_NAME", channel = "MAP_NAME" },
}

local function ContainsAlias(value, alias)
    local text = " " .. P.Normalize(value) .. " "
    local needle = P.Normalize(alias)
    return needle ~= "" and text:find(" " .. needle .. " ", 1, true) ~= nil
end

local function FindAliasSource(facts, alias)
    for _, source in ipairs(SOURCE_LEVELS) do
        if ContainsAlias(facts[source.field], alias) then return source.level, source.channel, facts[source.field] end
    end
    for _, name in ipairs(facts.mapTrail or {}) do
        if ContainsAlias(name, alias) then return "MAP_TRAIL", "MAP_TRAIL", name end
    end
    return "REGION_FALLBACK", "REGION_FALLBACK", facts.zone
end

local function CaptureFacts(locationFacts)
    locationFacts = type(locationFacts) == "table" and locationFacts or ZoneStyle.DetectContext()
    local facts = {
        mapID = locationFacts.mapID,
        mapName = tostring(locationFacts.mapName or locationFacts.zone or "Unknown Zone"),
        zone = tostring(locationFacts.zone or locationFacts.mapName or "Unknown Zone"),
        subzone = tostring(locationFacts.subzone or locationFacts.subZone or ""),
        mapTrail = {},
    }
    for _, name in ipairs(locationFacts.mapTrail or {}) do
        if name and name ~= "" then facts.mapTrail[#facts.mapTrail + 1] = tostring(name) end
    end
    if facts.subzone == facts.zone then facts.subzone = "" end
    facts.normalizedText = P.Normalize(table.concat({ facts.subzone, facts.zone, facts.mapName, table.concat(facts.mapTrail, " ") }, " "))
    facts.zoneKey = P.ContextZoneKey(facts)
    return facts
end

local function ResolveProfile(facts, ledger)
    local profile, profileKey, alias = Zone.ResolveZoneProfile(facts)
    local level, channel, matchedText
    if profileKey == "azeroth" then
        level, channel, matchedText = "AZEROTH_FALLBACK", "AZEROTH_FALLBACK", facts.normalizedText
        Zone.AddEvidence(ledger, {
            channel = channel, subject = "zone_profile", value = profile.label,
            matchedText = matchedText, sourceLevel = level,
            confidence = Zone.RESOLUTION_CONFIDENCE[level], registryKey = profileKey,
        })
    else
        level, channel, matchedText = FindAliasSource(facts, alias)
        Zone.AddEvidence(ledger, {
            channel = "PROFILE_ALIAS", subject = "zone_profile", value = profile.label,
            matchedText = matchedText, matchedAlias = alias, sourceLevel = level,
            confidence = Zone.RESOLUTION_CONFIDENCE[level], registryKey = profileKey,
        })
        Zone.AddEvidence(ledger, {
            channel = channel, subject = "location", value = matchedText,
            matchedText = matchedText, matchedAlias = alias, sourceLevel = level,
            confidence = Zone.RESOLUTION_CONFIDENCE[level], registryKey = profileKey,
        })
    end
    Zone.AddEvidence(ledger, {
        channel = "PROFILE_DEFINITION", subject = "style", value = profile.description,
        sourceLevel = "REGISTRY", confidence = 1, registryKey = profileKey,
    })
    return profile, profileKey, alias, level, Zone.RESOLUTION_CONFIDENCE[level] or 0
end

local function ResolveEra(facts, ledger)
    local text = P.BuildContextText(facts)
    for _, rule in ipairs(P.eraRules or {}) do
        local matched, alias = P.TextMatchesAny(text, rule.match)
        if matched then
            local info = ZoneStyle.expansions[rule.maxExpansionID]
            local level, _, matchedText = FindAliasSource(facts, alias)
            Zone.AddEvidence(ledger, {
                channel = "ERA_RULE", subject = "era", value = rule.maxExpansionID,
                matchedText = matchedText, matchedAlias = alias, sourceLevel = level,
                confidence = Zone.RESOLUTION_CONFIDENCE[level], registryKey = tostring(rule.maxExpansionID),
            })
            return rule.maxExpansionID, info.label, info.shortLabel, level, Zone.RESOLUTION_CONFIDENCE[level] or 0, alias
        end
    end
    local info = ZoneStyle.expansions[0]
    Zone.AddEvidence(ledger, {
        channel = "REGION_FALLBACK", subject = "era", value = 0,
        matchedText = facts.normalizedText, sourceLevel = "REGION_FALLBACK",
        confidence = Zone.RESOLUTION_CONFIDENCE.REGION_FALLBACK, registryKey = "0",
    })
    return 0, info.label, info.shortLabel, "REGION_FALLBACK", Zone.RESOLUTION_CONFIDENCE.REGION_FALLBACK
end

local function ResolveProvenance(facts, eraMax, ledger)
    local profile, key, alias = Zone.ResolveZoneProvenance(facts, eraMax)
    if profile then
        local level, _, matchedText = FindAliasSource(facts, alias)
        Zone.AddEvidence(ledger, {
            channel = "PROVENANCE_ALIAS", subject = "provenance", value = profile.label,
            matchedText = matchedText, matchedAlias = alias, sourceLevel = level,
            confidence = Zone.RESOLUTION_CONFIDENCE[level], registryKey = key,
        })
        return profile, key, alias, level, Zone.RESOLUTION_CONFIDENCE[level] or 0
    end
    return nil, nil, nil, "UNRESOLVED", 0
end

local function AddLocationFacts(facts, ledger)
    if facts.mapID ~= nil then Zone.AddEvidence(ledger, { channel = "MAP_ID", subject = "location", value = facts.mapID, sourceLevel = "RUNTIME", confidence = 1 }) end
    if facts.mapName ~= "" then Zone.AddEvidence(ledger, { channel = "MAP_NAME", subject = "location", value = facts.mapName, sourceLevel = "RUNTIME", confidence = 1 }) end
    if facts.zone ~= "" then Zone.AddEvidence(ledger, { channel = "ZONE_NAME", subject = "location", value = facts.zone, sourceLevel = "RUNTIME", confidence = 1 }) end
    if facts.subzone ~= "" then Zone.AddEvidence(ledger, { channel = "SUBZONE_NAME", subject = "location", value = facts.subzone, sourceLevel = "RUNTIME", confidence = 1 }) end
    for _, name in ipairs(facts.mapTrail) do Zone.AddEvidence(ledger, { channel = "MAP_TRAIL", subject = "location", value = name, sourceLevel = "RUNTIME", confidence = 1 }) end
end

local function Coverage(style)
    local result = {}
    for _, channel in ipairs({ "culture", "climate", "terrain", "palette", "material", "finish", "motif", "magic", "silhouette", "avoids" }) do
        local count = 0
        for _ in pairs(style[channel] or {}) do count = count + 1 end
        result[channel] = count > 0 and "KNOWN" or (channel == "avoids" and "NOT_APPLICABLE" or "UNKNOWN")
    end
    return result
end

local function RestrictionLabel(eraShortLabel, provenance)
    local settings = QC.GetSettings and QC.GetSettings() or {}
    local eraText = settings.restrictOutfitsToZoneEra ~= false and ("Through " .. tostring(eraShortLabel)) or "Zone era limit off"
    return eraText .. (provenance and (" • " .. provenance.label .. " sources") or "")
end

local function CacheKey(facts)
    return table.concat({
        tostring(facts.mapID or ""), P.Normalize(facts.zone), P.Normalize(facts.subzone),
        tostring(Zone.PROFILE_REGISTRY_VERSION), tostring(Zone.PROVENANCE_REGISTRY_VERSION), tostring(Zone.ERA_RULE_VERSION),
    }, "|")
end

local function BuildSnapshot(facts)
    local ledger = Zone.NewEvidenceLedger()
    AddLocationFacts(facts, ledger)
    local profile, profileKey, _, profileLevel, profileConfidence = ResolveProfile(facts, ledger)
    local eraMax, eraLabel, eraShortLabel, eraLevel, eraConfidence = ResolveEra(facts, ledger)
    local provenance, provenanceKey, _, provenanceLevel, provenanceConfidence = ResolveProvenance(facts, eraMax, ledger)
    local character = QC.GetCurrentCharacter and QC.GetCurrentCharacter() or nil
    local startingCase = Zone.ResolveStartingZoneOverride(facts, character)
    if startingCase then
        Zone.AddEvidence(ledger, {
            channel = "STARTING_ZONE_RULE", subject = "starting_zone", value = startingCase.caseID,
            matchedText = facts.subzone, matchedAlias = startingCase.subzone, sourceLevel = "EXACT_SUBZONE",
            confidence = Zone.RESOLUTION_CONFIDENCE.EXACT_SUBZONE, registryKey = startingCase.provenanceKey,
        })
    end
    local style = Zone.Copy(profile.style or {})
    style.coverage = Coverage(style)
    local detailKey = P.ContextDetailKey(facts, profileKey)
    local snapshot = {
        format = Zone.CONTEXT_FORMAT,
        registryVersion = Zone.PROFILE_REGISTRY_VERSION,
        provenanceRegistryVersion = Zone.PROVENANCE_REGISTRY_VERSION,
        eraRuleVersion = Zone.ERA_RULE_VERSION,
        capturedAt = type(time) == "function" and time() or 0,
        location = {
            mapID = facts.mapID, mapName = facts.mapName, zone = facts.zone, subzone = facts.subzone,
            mapTrail = Zone.Copy(facts.mapTrail), normalizedText = facts.normalizedText,
            zoneKey = facts.zoneKey, detailKey = detailKey,
        },
        identity = {
            profileKey = profileKey, label = profile.label, description = profile.description,
            resolutionLevel = profileLevel, confidence = profileConfidence,
        },
        era = {
            maxExpansionID = eraMax, label = eraLabel, shortLabel = eraShortLabel,
            resolutionLevel = eraLevel, confidence = eraConfidence,
        },
        provenance = {
            key = provenanceKey, label = provenance and provenance.label or facts.zone,
            resolutionLevel = provenanceLevel, confidence = provenanceConfidence,
        },
        style = style,
        restrictions = {
            eraEnabled = not (QC.GetSettings and QC.GetSettings().restrictOutfitsToZoneEra == false),
            restrictionLabel = RestrictionLabel(eraShortLabel, provenance),
            favoriteScopeKey = provenanceKey or facts.zoneKey or profileKey,
            exclusionScopeKey = provenanceKey or facts.zoneKey or profileKey,
        },
        fallback = {
            used = profileKey == "azeroth" or provenanceKey == nil,
            level = profileKey == "azeroth" and "AZEROTH_FALLBACK" or (provenanceKey == nil and "PROVENANCE_UNRESOLVED" or nil),
            reason = profileKey == "azeroth" and "No registered Zone profile alias matched the runtime location facts."
                or (provenanceKey == nil and "No era-valid local provenance pool matched the runtime location facts." or nil),
        },
        evidence = Zone.CopyEvidence(ledger),
        startingZoneCaseID = startingCase and startingCase.caseID or nil,
    }
    local fingerprintSeed = Zone.CopyPrimitive(snapshot)
    fingerprintSeed.capturedAt = nil
    snapshot.fingerprint = Zone.Fingerprint(fingerprintSeed)
    Zone.snapshotBuildCount = Zone.snapshotBuildCount + 1
    return snapshot
end

function Zone.BuildZoneContextSnapshot(locationFacts, force)
    local facts = CaptureFacts(locationFacts)
    local key = CacheKey(facts)
    if not force and Zone.snapshotCache[key] then return Zone.CopyPrimitive(Zone.snapshotCache[key]) end
    local snapshot = BuildSnapshot(facts)
    Zone.snapshotCache[key] = snapshot
    return Zone.CopyPrimitive(snapshot)
end

function Zone.GetCachedSnapshot(locationFacts)
    local facts = CaptureFacts(locationFacts)
    return Zone.snapshotCache[CacheKey(facts)]
end

function Zone.ClearSnapshotCache()
    Zone.snapshotCache = {}
end

function ZoneStyle.BuildZoneContextSnapshot(locationFacts)
    return Zone.BuildZoneContextSnapshot(locationFacts, false)
end
