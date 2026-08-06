local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone

Zone.DEBUG_EXPORT_FORMAT = 2

local STYLE_CHANNELS = {
    "culture", "climate", "terrain", "palette", "material",
    "finish", "motif", "magic", "silhouette", "avoids",
}
local AFFINITY_COMPONENTS = {
    "palette", "material", "finish", "motif",
    "culture", "magic", "avoids", "provenance",
}
local STATUS = Zone.AFFINITY_COMPONENT_STATUS or {
    VALUE = "VALUE", MISSING = "MISSING", NOT_APPLICABLE = "NOT_APPLICABLE",
}

local function Add(lines, text)
    lines[#lines + 1] = tostring(text or "")
end

local function Value(value)
    return Zone.EscapeDiagnosticValue and Zone.EscapeDiagnosticValue(value) or tostring(value == nil and "" or value)
end

local function Cell(value)
    return Zone.MarkdownCell and Zone.MarkdownCell(value) or Value(value)
end

local function Code(value)
    return Zone.MarkdownCode and Zone.MarkdownCode(value) or ("`" .. Value(value) .. "`")
end

local function SortedKeys(values)
    local keys = {}
    for key in pairs(type(values) == "table" and values or {}) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

local function JoinList(values)
    local output = {}
    for _, value in ipairs(type(values) == "table" and values or {}) do output[#output + 1] = tostring(value) end
    return #output > 0 and table.concat(output, ", ") or "None"
end

local function FormatMap(values)
    local output = {}
    for _, key in ipairs(SortedKeys(values)) do
        local value = values[key]
        if type(value) == "number" then output[#output + 1] = string.format("%s=%.3f", tostring(key), value)
        elseif value then output[#output + 1] = tostring(key) .. (value == true and "" or ("=" .. tostring(value))) end
    end
    return #output > 0 and table.concat(output, " • ") or "None"
end

local function ModeRows()
    local Generation = QC.Generation
    local rows = {}
    for _, modeID in ipairs({
        ZoneStyle.MODE_TRAVELER or "TRAVELER",
        ZoneStyle.MODE_ZONE_NATIVE or "ZONE_NATIVE",
        ZoneStyle.MODE_CLASS_FANTASY or "CLASS_FANTASY",
        ZoneStyle.MODE_CHRONICLE_ECHO or "CHRONICLE_ECHO",
    }) do
        local caps = Generation and Generation.GetModeCapabilities and Generation.GetModeCapabilities(modeID) or nil
        rows[#rows + 1] = {
            label = caps and caps.displayLabel or modeID,
            modeID = modeID,
            implementation = caps and caps.implementation or "UNAVAILABLE",
            generation = caps and caps.implementationGeneration or "?",
            foundation = caps and caps.zoneFoundation or nil,
        }
    end
    return rows
end

local function LatestZoneReport()
    local D = QC.Diagnostics
    if not D then return nil end
    local reports = type(D.PeekReports) == "function" and D.PeekReports()
        or (type(D.GetReports) == "function" and D.GetReports()) or {}
    for _, report in ipairs(reports) do
        if report.mode == (ZoneStyle.MODE_ZONE_NATIVE or "ZONE_NATIVE") then return report end
    end
    return nil
end

local function SourceLabel(piece)
    local Wardrobe = QC.Wardrobe
    local P = Wardrobe and Wardrobe._Private
    local source = P and P.GetSourceByID and P.GetSourceByID(piece.slotKey, piece.sourceID) or nil
    if not source then return "Unknown appearance" end
    return source.name or source.itemName or source.sourceName or source.label or "Unknown appearance"
end

local function AddArchitecture(lines)
    Add(lines, "## Generation architecture")
    Add(lines, "")
    Add(lines, "| Mode | Mode ID | Implementation | Generation | Foundation |")
    Add(lines, "|---|---|---|---:|---|")
    for _, row in ipairs(ModeRows()) do
        Add(lines, string.format("| %s | %s | %s | %s | %s |",
            Cell(row.label), Code(row.modeID), Code(row.implementation), Cell(row.generation),
            row.foundation and Code(row.foundation) or "None"))
    end
    Add(lines, "")
    Add(lines, "- Policy contract: " .. Code(QC.Generation and QC.Generation.POLICY_CONTRACT_VERSION or "?"))
    Add(lines, "- Generation API contract: " .. Code(QC.Generation and QC.Generation.API_CONTRACT_VERSION or "?"))
    Add(lines, "- Zone debug export format: " .. Code(Zone.DEBUG_EXPORT_FORMAT))
    Add(lines, "- Zone affinity format: " .. Code(Zone.AFFINITY_FORMAT))
    Add(lines, "- Dynamic value encoding: " .. Code(Zone.DIAGNOSTIC_VALUE_ENCODING or "DIAGNOSTIC_ESCAPE_V1"))
    Add(lines, "- Literal pipe representation: `\\u007C`")
    Add(lines, "")
end

local function AddFoundation(lines, foundation, compatibility)
    Add(lines, "## Zone foundation")
    Add(lines, "")
    Add(lines, "- Foundation: " .. Code(foundation.foundation or Zone.FOUNDATION_ID))
    Add(lines, "- Context format: " .. Code(foundation.contextFormat or "?"))
    Add(lines, "- Profile registry: " .. Code(foundation.profileRegistryVersion or "?"))
    Add(lines, "- Provenance registry: " .. Code(foundation.provenanceRegistryVersion or "?"))
    Add(lines, "- Starting-zone registry: " .. Code(foundation.startingZoneRegistryVersion or "?"))
    Add(lines, "- Era rules: " .. Code(foundation.eraRuleVersion or "?"))
    Add(lines, "- Affinity format: " .. Code(foundation.affinityFormat or "?"))
    Add(lines, "- Snapshot builds this session: " .. Code(Zone.snapshotBuildCount or 0))
    Add(lines, "- Compatibility parity: " .. Code(compatibility and compatibility.pass == true and "PASS" or "FAIL"))
    for _, difference in ipairs(compatibility and compatibility.differences or {}) do
        Add(lines, "  - Difference: " .. Value(difference))
    end
    Add(lines, string.format("- Registries: `%d` profiles • `%d` provenance pools • `%d` starting-zone cases",
        #(Zone.ProfileRegistry and Zone.ProfileRegistry.order or {}),
        #(Zone.ProvenanceRegistry and Zone.ProvenanceRegistry.list or {}),
        #(Zone.StartingZoneRegistry and Zone.StartingZoneRegistry.list or {})))
    local collisions = Zone.ProfileRegistry and Zone.ProfileRegistry.collisions or {}
    Add(lines, "- Profile alias collisions: " .. tostring(#SortedKeys(collisions)))
    for _, alias in ipairs(SortedKeys(collisions)) do
        Add(lines, "  - " .. Code(alias) .. ": " .. Value(JoinList(collisions[alias])))
    end
    Add(lines, "")
end

local function AddSnapshot(lines, snapshot)
    local location, identity = snapshot.location or {}, snapshot.identity or {}
    local era, provenance = snapshot.era or {}, snapshot.provenance or {}
    local fallback, restrictions = snapshot.fallback or {}, snapshot.restrictions or {}
    Add(lines, "## Current Zone context snapshot")
    Add(lines, "")
    Add(lines, "- Fingerprint: " .. Code(snapshot.fingerprint or "Unknown"))
    local captured = type(date) == "function" and date("%Y-%m-%d %H:%M:%S", snapshot.capturedAt or 0) or tostring(snapshot.capturedAt or 0)
    Add(lines, "- Captured: " .. Code(captured))
    Add(lines, string.format("- Location: **%s%s**", Cell(location.zone or "Unknown"), location.subzone and location.subzone ~= "" and (" / " .. Cell(location.subzone)) or ""))
    Add(lines, "- Map: " .. Code(location.mapID or "Unknown") .. " • " .. Value(location.mapName or "Unknown"))
    Add(lines, "- Map trail: " .. Value(JoinList(location.mapTrail)))
    Add(lines, "- Zone key: " .. Code(location.zoneKey or "") .. " • detail key: " .. Code(location.detailKey or ""))
    Add(lines, string.format("- Style identity: **%s** (%s) • %s • confidence `%.3f`",
        Cell(identity.label), Code(identity.profileKey), Code(identity.resolutionLevel), tonumber(identity.confidence) or 0))
    Add(lines, "- Description: " .. Value(identity.description or ""))
    Add(lines, string.format("- Era: **Through %s** (%s) • %s • confidence `%.3f`",
        Cell(era.shortLabel or era.label), Code(era.maxExpansionID or "?"), Code(era.resolutionLevel), tonumber(era.confidence) or 0))
    Add(lines, string.format("- Provenance: **%s**%s • %s • confidence `%.3f`",
        Cell(provenance.label or "Unresolved"), provenance.key and (" (" .. Code(provenance.key) .. ")") or "",
        Code(provenance.resolutionLevel), tonumber(provenance.confidence) or 0))
    Add(lines, "- Restriction: " .. Value(restrictions.restrictionLabel or "Unknown"))
    Add(lines, "- Era restriction enabled: " .. Code(restrictions.eraEnabled == true))
    Add(lines, "- Favorite scope: " .. Code(restrictions.favoriteScopeKey or "") .. " • exclusion scope: " .. Code(restrictions.exclusionScopeKey or ""))
    Add(lines, "- Starting-zone case: " .. Code(snapshot.startingZoneCaseID or "None"))
    Add(lines, "- Fallback: " .. Code(fallback.used and "YES" or "NO") .. (fallback.reason and (" • " .. Value(fallback.reason)) or ""))
    Add(lines, "")
end

local function AddStyle(lines, snapshot)
    local style = snapshot.style or {}
    Add(lines, "## Canonical Zone style evidence")
    Add(lines, "")
    Add(lines, "| Channel | Coverage | Signals |")
    Add(lines, "|---|---|---|")
    for _, channel in ipairs(STYLE_CHANNELS) do
        Add(lines, string.format("| %s | %s | %s |",
            Cell(channel), Code(style.coverage and style.coverage[channel] or "UNKNOWN"), Cell(FormatMap(style[channel]))))
    end
    Add(lines, "")
end

local function AddEvidence(lines, snapshot)
    local evidence = snapshot.evidence or {}
    Add(lines, "## Complete evidence ancestry")
    Add(lines, "")
    Add(lines, string.format("Entries: **%d** • warnings: **%d**", #(evidence.entries or {}), #(evidence.warnings or {})))
    Add(lines, "")
    Add(lines, "| # | Channel | Subject | Value | Matched text | Alias | Source level | Confidence | Registry key |")
    Add(lines, "|---:|---|---|---|---|---|---|---:|---|")
    for index, entry in ipairs(evidence.entries or {}) do
        Add(lines, string.format("| %d | %s | %s | %s | %s | %s | %s | %.3f | %s |",
            index, Code(entry.channel), Cell(entry.subject), Cell(entry.value), Cell(entry.matchedText),
            Cell(entry.matchedAlias), Code(entry.sourceLevel), tonumber(entry.confidence) or 0, Code(entry.registryKey)))
    end
    if #(evidence.entries or {}) == 0 then Add(lines, "|  |  |  |  |  |  |  |  |  |") end
    Add(lines, "")
    for _, warning in ipairs(evidence.warnings or {}) do Add(lines, "- Evidence warning: " .. Value(warning)) end
    if #(evidence.warnings or {}) > 0 then Add(lines, "") end
end

local function AddAffinity(lines, affinity, snapshot)
    affinity = Zone.NormalizeSelectedOutfitAffinity and Zone.NormalizeSelectedOutfitAffinity(affinity, snapshot) or affinity
    Add(lines, "## Current-look Zone affinity")
    Add(lines, "")
    Add(lines, string.format("- Selected visible pieces: **%d**", tonumber(affinity.selected) or 0))
    Add(lines, string.format("- Mean affinity: `%.3f`", tonumber(affinity.score) or 0))
    Add(lines, string.format("- Mean confidence: `%.3f`", tonumber(affinity.confidence) or 0))
    Add(lines, "- Classifications: " .. Value(FormatMap(affinity.classifications)))
    Add(lines, "")
    Add(lines, "| Slot | Appearance | Source ID | Visual ID | Classification | Score | Confidence | Missing channels | N/A channels |")
    Add(lines, "|---|---|---:|---:|---|---:|---:|---|---|")
    for _, piece in ipairs(affinity.pieces or {}) do
        Add(lines, string.format("| %s | %s | %s | %s | %s | %.3f | %.3f | %s | %s |",
            Code(piece.slotKey), Cell(SourceLabel(piece)), Cell(piece.sourceID), Cell(piece.visualID),
            Code(piece.classification), tonumber(piece.score) or 0, tonumber(piece.confidence) or 0,
            Cell(JoinList(piece.missingChannels)), Cell(JoinList(piece.notApplicableChannels))))
    end
    if #(affinity.pieces or {}) == 0 then Add(lines, "|  | No selected visible pieces |  |  |  |  |  |  |  |") end
    Add(lines, "")
    for _, piece in ipairs(affinity.pieces or {}) do
        Add(lines, string.format("### %s • %s", Cell(piece.slotKey), Cell(SourceLabel(piece))))
        Add(lines, "")
        Add(lines, string.format("- Classification: %s • score `%.3f` • confidence `%.3f`", Code(piece.classification), tonumber(piece.score) or 0, tonumber(piece.confidence) or 0))
        Add(lines, "- Descriptor: " .. Code(piece.descriptorFingerprint or "Unknown"))
        Add(lines, "- Profile: " .. Code(piece.profileKey or "Unknown") .. " • provenance: " .. Code(piece.provenanceKey or "None"))
        Add(lines, "- Missing channels: " .. Value(JoinList(piece.missingChannels)))
        Add(lines, "- N/A channels: " .. Value(JoinList(piece.notApplicableChannels)))
        Add(lines, "- Components:")
        for _, component in ipairs(AFFINITY_COMPONENTS) do
            local status = piece.componentStatus and piece.componentStatus[component]
            local value = piece.components and piece.components[component]
            local display = status == STATUS.VALUE and string.format("%.3f", tonumber(value) or 0)
                or status == STATUS.NOT_APPLICABLE and STATUS.NOT_APPLICABLE or STATUS.MISSING
            Add(lines, "  - " .. component .. ": " .. Code(display))
        end
        Add(lines, "- Evidence:")
        for _, entry in ipairs(piece.evidence or {}) do
            Add(lines, string.format("  - %s • %s • confidence `%.3f`", Code(entry.channel), Value(entry.value), tonumber(entry.confidence) or 0))
        end
        if #(piece.evidence or {}) == 0 then Add(lines, "  - None") end
        Add(lines, "")
    end
    return affinity
end

local function AddLatestReport(lines, report)
    Add(lines, "## Latest Zone Native diagnostic report")
    Add(lines, "")
    if not report then
        Add(lines, "No Zone Native generation report is currently available.")
        Add(lines, "")
        return
    end
    local foundation = report.zoneFoundation or {}
    Add(lines, "- Report ID: " .. Code(report.id or "Unknown"))
    Add(lines, "- Time: " .. Code(report.timestampText or report.timestamp or "Unknown"))
    Add(lines, "- Action: " .. Code(report.action or "Unknown") .. " • result: " .. Code(report.result or "Unknown"))
    Add(lines, "- Generation implementation: " .. Code(report.generationImplementation or "Unknown"))
    Add(lines, "- Zone foundation: " .. Code(foundation.foundation or "Not recorded"))
    Add(lines, "- Snapshot fingerprint: " .. Code(foundation.fingerprint or "Not recorded"))
    Add(lines, "- Compatibility parity: " .. Code(foundation.compatibility or "Not recorded"))
    local affinity = foundation.affinity or {}
    Add(lines, string.format("- Recorded affinity: `%.3f` • confidence `%.3f` • `%d` pieces",
        tonumber(affinity.score) or 0, tonumber(affinity.confidence) or 0, tonumber(affinity.selected) or 0))
    Add(lines, "- Message: " .. Value(report.message or ""))
    Add(lines, "")
end

function Zone.BuildZoneDebugExport(snapshot, affinity)
    snapshot = snapshot or ZoneStyle.GetZoneContextSnapshot()
    affinity = affinity or Zone.BuildSelectedOutfitAffinity(nil, snapshot)
    local foundation = Zone.GetFoundationStatus and Zone.GetFoundationStatus() or {}
    local compatibility = ZoneStyle.GetZoneCompatibilityStatus and ZoneStyle.GetZoneCompatibilityStatus()
        or { pass = false, differences = { "Compatibility status unavailable." } }
    local lines = {}
    Add(lines, "# Quest Chronicle Zone Debug Export")
    Add(lines, "")
    Add(lines, "- Quest Chronicle version: " .. Code(QC.version or "Unknown"))
    local generated = type(date) == "function" and date("%Y-%m-%d %H:%M:%S") or "Unknown"
    Add(lines, "- Generated: " .. Code(generated))
    Add(lines, "- Command: `/qc zone debug export`")
    Add(lines, "")
    AddArchitecture(lines)
    AddFoundation(lines, foundation, compatibility)
    AddSnapshot(lines, snapshot)
    AddStyle(lines, snapshot)
    AddEvidence(lines, snapshot)
    affinity = AddAffinity(lines, affinity, snapshot)
    AddLatestReport(lines, LatestZoneReport())
    local text = table.concat(lines, "\n")
    return text, {
        format = Zone.DEBUG_EXPORT_FORMAT,
        affinityFormat = Zone.AFFINITY_FORMAT,
        encoding = Zone.DIAGNOSTIC_VALUE_ENCODING,
        unsafeControlDetected = Zone.ContainsUnsafeWoWControl and Zone.ContainsUnsafeWoWControl(text) or false,
        evidenceEntries = #(snapshot.evidence and snapshot.evidence.entries or {}),
        selectedPieces = tonumber(affinity.selected) or 0,
        profileKey = snapshot.identity and snapshot.identity.profileKey or nil,
        fingerprint = snapshot.fingerprint,
    }
end

function ZoneStyle.BuildZoneDebugExport(snapshot, affinity)
    return Zone.BuildZoneDebugExport(snapshot, affinity)
end
