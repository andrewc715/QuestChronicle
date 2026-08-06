local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone

local function Emit(text)
    if QC.Print then QC.Print(text)
    elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then DEFAULT_CHAT_FRAME:AddMessage(text)
    end
end

local function JoinKeys(values, limit)
    local keys = {}
    for key, value in pairs(values or {}) do
        if value then keys[#keys + 1] = tostring(key) end
    end
    table.sort(keys)
    limit = tonumber(limit) or #keys
    if #keys > limit then
        local trimmed = {}
        for index = 1, limit do trimmed[index] = keys[index] end
        return table.concat(trimmed, ", ") .. string.format(" (+%d more)", #keys - limit)
    end
    return #keys > 0 and table.concat(keys, ", ") or "None"
end

local function CoverageText(coverage)
    local values = {}
    for _, key in ipairs({ "culture", "climate", "terrain", "palette", "material", "finish", "motif", "magic", "silhouette", "avoids" }) do
        values[#values + 1] = key .. "=" .. tostring(coverage and coverage[key] or "UNKNOWN")
    end
    return table.concat(values, " • ")
end

function Zone.BuildZoneDebugLines(snapshot, affinity)
    snapshot = snapshot or ZoneStyle.GetZoneContextSnapshot()
    affinity = affinity or Zone.BuildSelectedOutfitAffinity(nil, snapshot)
    local lines = {}
    local function Add(text) lines[#lines + 1] = text end
    Add(string.format("Zone foundation: %s • context format %d", Zone.FOUNDATION_ID, Zone.CONTEXT_FORMAT))
    Add(string.format("Location: %s%s • map %s", tostring(snapshot.location.zone), snapshot.location.subzone ~= "" and (" / " .. snapshot.location.subzone) or "", tostring(snapshot.location.mapID or "unknown")))
    Add("Map trail: " .. (#(snapshot.location.mapTrail or {}) > 0 and table.concat(snapshot.location.mapTrail, " → ") or "None"))
    Add(string.format("Style profile: %s (%s) • %s • confidence %.2f", snapshot.identity.label, snapshot.identity.profileKey, snapshot.identity.resolutionLevel, snapshot.identity.confidence))
    Add(string.format("Era: Through %s • %s • confidence %.2f", snapshot.era.shortLabel, snapshot.era.resolutionLevel, snapshot.era.confidence))
    Add(string.format("Provenance: %s%s • %s • confidence %.2f", tostring(snapshot.provenance.label or "Unresolved"), snapshot.provenance.key and (" (" .. snapshot.provenance.key .. ")") or "", snapshot.provenance.resolutionLevel, snapshot.provenance.confidence))
    Add("Restriction: " .. tostring(snapshot.restrictions.restrictionLabel))
    Add(string.format("Fallback: %s%s", snapshot.fallback.used and "Yes" or "No", snapshot.fallback.reason and (" • " .. snapshot.fallback.reason) or ""))
    Add("Evidence coverage: " .. CoverageText(snapshot.style.coverage))
    Add("Palette signals: " .. JoinKeys(snapshot.style.palette, 8))
    Add("Material signals: " .. JoinKeys(snapshot.style.material, 8))
    Add("Finish signals: " .. JoinKeys(snapshot.style.finish, 8))
    Add("Motif signals: " .. JoinKeys(snapshot.style.motif, 8))
    Add(string.format("Current-look Zone affinity: %.3f • confidence %.3f • %d selected pieces", affinity.score or 0, affinity.confidence or 0, affinity.selected or 0))
    Add("Affinity classes: " .. JoinKeys(affinity.classifications, 8))
    Add(string.format("Registries: %d profiles • %d provenance pools • %d starting-zone cases", #Zone.ProfileRegistry.order, #Zone.ProvenanceRegistry.list, #Zone.StartingZoneRegistry.list))
    Add("Snapshot fingerprint: " .. tostring(snapshot.fingerprint))
    local evidence = snapshot.evidence and snapshot.evidence.entries or {}
    Add(string.format("Evidence ancestry: %d entries", #evidence))
    for index = 1, math.min(8, #evidence) do
        local entry = evidence[index]
        Add(string.format("  %s • %s • %s • %.2f", tostring(entry.channel), tostring(entry.registryKey or entry.value or ""), tostring(entry.sourceLevel or ""), tonumber(entry.confidence) or 0))
    end
    if #evidence > 8 then Add(string.format("  ... %d additional entries omitted", #evidence - 8)) end
    return lines
end

function ZoneStyle.PrintZoneDiagnostics()
    local snapshot = ZoneStyle.GetZoneContextSnapshot()
    local affinity = Zone.BuildSelectedOutfitAffinity(nil, snapshot)
    for _, line in ipairs(Zone.BuildZoneDebugLines(snapshot, affinity)) do Emit(line) end
    return true
end
