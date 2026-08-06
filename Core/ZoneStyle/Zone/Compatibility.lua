local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone
local P = ZoneStyle._Private

Zone.LegacyResolveProfile = Zone.LegacyResolveProfile or ZoneStyle.ResolveProfile
Zone.LegacyResolveEra = Zone.LegacyResolveEra or ZoneStyle.ResolveEra
Zone.LegacyResolveProvenance = Zone.LegacyResolveProvenance or ZoneStyle.ResolveProvenance
Zone.LegacyRefreshZone = Zone.LegacyRefreshZone or ZoneStyle.RefreshZone
Zone.LegacyGetCurrentContext = Zone.LegacyGetCurrentContext or ZoneStyle.GetCurrentContext

function Zone.BuildLegacyContextView(snapshot)
    snapshot = snapshot or Zone.BuildZoneContextSnapshot(nil, false)
    local location, identity, era, provenance = snapshot.location, snapshot.identity, snapshot.era, snapshot.provenance
    return {
        mapID = location.mapID,
        mapName = location.mapName,
        zone = location.zone,
        subzone = location.subzone,
        mapTrail = Zone.Copy(location.mapTrail),
        profileKey = identity.profileKey,
        profileLabel = identity.label,
        profileDescription = identity.description,
        eraMax = era.maxExpansionID,
        eraLabel = era.label,
        eraShortLabel = era.shortLabel,
        provenanceKey = provenance.key,
        provenanceResolved = true,
        provenanceLabel = provenance.label,
        zoneKey = location.zoneKey,
        detailKey = location.detailKey,
        zoneContextFingerprint = snapshot.fingerprint,
        zoneFoundation = Zone.FOUNDATION_ID,
    }
end

function Zone.CompareCompatibility(snapshot, legacyContext)
    local current = Zone.BuildLegacyContextView(snapshot)
    legacyContext = legacyContext or current
    local differences = {}
    for _, field in ipairs({
        "mapID", "mapName", "zone", "subzone", "profileKey", "profileLabel", "profileDescription",
        "eraMax", "eraLabel", "eraShortLabel", "provenanceKey", "provenanceLabel", "zoneKey", "detailKey",
    }) do
        if tostring(current[field]) ~= tostring(legacyContext[field]) then
            differences[#differences + 1] = { field = field, expected = legacyContext[field], actual = current[field] }
        end
    end
    return #differences == 0, differences
end

function ZoneStyle.ResolveProfile(context)
    local profile, key = Zone.ResolveZoneProfile(context or ZoneStyle.DetectContext())
    return profile, key
end

function ZoneStyle.ResolveEra(context)
    context = context or ZoneStyle.DetectContext()
    local text = P.BuildContextText(context)
    for _, rule in ipairs(P.eraRules or {}) do
        if P.TextMatchesAny(text, rule.match) then
            local info = ZoneStyle.expansions[rule.maxExpansionID]
            return rule.maxExpansionID, info.label, info.shortLabel
        end
    end
    local info = ZoneStyle.expansions[0]
    return 0, info.label, info.shortLabel
end

function ZoneStyle.ResolveProvenance(context)
    context = context or ZoneStyle.DetectContext()
    return Zone.ResolveZoneProvenance(context, select(1, ZoneStyle.ResolveEra(context)))
end

local function BuildLegacyReference(facts)
    local profile, profileKey = Zone.LegacyResolveProfile(facts)
    local eraMax, eraLabel, eraShortLabel = Zone.LegacyResolveEra(facts)
    local provenance, provenanceKey = Zone.LegacyResolveProvenance(facts)
    local context = Zone.Copy(facts)
    context.profileKey = profileKey
    context.profileLabel = profile and profile.label or nil
    context.profileDescription = profile and profile.description or nil
    context.eraMax, context.eraLabel, context.eraShortLabel = eraMax, eraLabel, eraShortLabel
    context.provenanceKey = provenanceKey
    context.provenanceResolved = true
    context.provenanceLabel = provenance and provenance.label or context.zone
    context.zoneKey = P.ContextZoneKey(context)
    context.detailKey = P.ContextDetailKey(context, profileKey)
    return context
end

function ZoneStyle.RefreshZone(force, silent)
    local state = P.GetStyleState()
    local facts = ZoneStyle.DetectContext()
    if force == true then Zone.ClearSnapshotCache() end
    local legacyReference = BuildLegacyReference(facts)
    local snapshot = Zone.BuildZoneContextSnapshot(facts, force == true)
    local context = Zone.BuildLegacyContextView(snapshot)
    local parityPass, parityDifferences = Zone.CompareCompatibility(snapshot, legacyReference)
    local previous = state.currentContext
    local zoneChanged = force == true or not previous or previous.zoneKey ~= context.zoneKey or previous.profileKey ~= context.profileKey
    local detailChanged = zoneChanged or not previous or previous.detailKey ~= context.detailKey
    state.currentContext = context
    Zone.currentSnapshot = Zone.CopyPrimitive(snapshot)
    Zone.compatibilityStatus = { pass = parityPass, differences = parityDifferences }

    if zoneChanged then
        state.pendingSuggestion = {
            mapID = context.mapID, zone = context.zone, subzone = context.subzone,
            profileKey = context.profileKey, profileLabel = context.profileLabel,
            eraMax = context.eraMax, eraLabel = context.eraLabel,
            provenanceKey = context.provenanceKey, provenanceLabel = context.provenanceLabel,
            createdAt = type(time) == "function" and time() or 0, unread = true,
        }
        if QC.Notify then QC.Notify("ZONE_STYLE_SUGGESTION", state.pendingSuggestion, context) end
        if not silent and QC.Print then
            QC.Print(string.format("New Zone Native outfit suggestion: %s (%s). Open Outfits to preview it.", context.zone, context.profileLabel))
        end
    elseif detailChanged and QC.Notify then
        QC.Notify("ZONE_STYLE_CONTEXT_CHANGED", context)
    end
    return context, zoneChanged
end

function ZoneStyle.GetCurrentContext()
    local state = P.GetStyleState()
    if not state.currentContext then return ZoneStyle.RefreshZone(true, true) end
    if not Zone.currentSnapshot then return ZoneStyle.RefreshZone(false, true) end
    return state.currentContext
end

function ZoneStyle.GetZoneContextSnapshot()
    if not Zone.currentSnapshot then ZoneStyle.GetCurrentContext() end
    return Zone.CopyPrimitive(Zone.currentSnapshot)
end

function ZoneStyle.GetCurrentProfile()
    local context = ZoneStyle.GetCurrentContext()
    return Zone.GetZoneProfile(context.profileKey) or Zone.GetZoneProfile("azeroth"), context.profileKey, context
end

function ZoneStyle.GetZoneCompatibilityStatus()
    return Zone.CopyPrimitive(Zone.compatibilityStatus or { pass = false, differences = { { field = "snapshot", actual = "missing" } } })
end

function ZoneStyle.ForceZoneContextRefresh(silent)
    return ZoneStyle.RefreshZone(true, silent == true)
end
