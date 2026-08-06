local QC = QuestChronicle
local ZoneStyle = QC.ZoneStyle
local Zone = ZoneStyle.Zone

Zone.DEBUG_EXPORT_FORMAT = 1

local STYLE_CHANNELS = {
    "culture", "climate", "terrain", "palette", "material",
    "finish", "motif", "magic", "silhouette", "avoids",
}
local AFFINITY_COMPONENTS = {
    "palette", "material", "finish", "motif",
    "culture", "magic", "avoids", "provenance",
}

local function Add(lines, text)
    lines[#lines + 1] = tostring(text or "")
end

local function Cell(value)
    local text = tostring(value == nil and "" or value)
    text = text:gsub("\r", " "):gsub("\n", " "):gsub("|", "\\|")
    return text
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

local function AddArchitecture(lines, status)
    Add(lines, "## Generation architecture")
    Add(lines, "")
    Add(lines, "| Mode | Mode ID | Implementation | Generation | Foundation |")
    Add(lines, "|---|---|---|---:|---|")
    for _, row in ipairs(ModeRows()) do
        Add(lines, string.format("| %s | `%s` | `%s` | %s | %s |",
            Cell(row.label), Cell(row.modeID), Cell(row.implementation), Cell(row.generation),
            row.foundation and ("`" .. Cell(row.foundation) .. "`") or "None"))
    end
    Add(lines, "")
    Add(lines, string.format("- Policy contract: `%s`", tostring(QC.Generation and QC.Generation.POLICY_CONTRACT_VERSION or "?")))
    Add(lines, string.format("- Generation API contract: `%s`", tostring(QC.Generation and QC.Generation.API_CONTRACT_VERSION or "?")))
    Add(lines, string.format("- Zone debug export format: `%d`", Zone.DEBUG_EXPORT_FORMAT))
    Add(lines, "")
end

local function AddFoundation(lines, foundation, compatibility)
    Add(lines, "## Zone foundation")
    Add(lines, "")
    Add(lines, string.format("- Foundation: `%s`", tostring(foundation.foundation or Zone.FOUNDATION_ID)))
    Add(lines, string.format("- Context format: `%s`", tostring(foundation.contextFormat or "?")))
    Add(lines, string.format("- Profile registry: `%s`", tostring(foundation.profileRegistryVersion or "?")))
    Add(lines, string.format("- Provenance registry: `%s`", tostring(foundation.provenanceRegistryVersion or "?")))
    Add(lines, string.format("- Starting-zone registry: `%s`", tostring(foundation.startingZoneRegistryVersion or "?")))
    Add(lines, string.format("- Era rules: `%s`", tostring(foundation.eraRuleVersion or "?")))
    Add(lines, string.format("- Affinity format: `%s`", tostring(foundation.affinityFormat or "?")))
    Add(lines, string.format("- Snapshot builds this session: `%s`", tostring(Zone.snapshotBuildCount or 0)))
    Add(lines, string.format("- Compatibility parity: `%s`", compatibility and compatibility.pass == true and "PASS" or "FAIL"))
    for _, difference in ipairs(compatibility and compatibility.differences or {}) do
        Add(lines, "  - Difference: " .. tostring(difference))
    end
    Add(lines, string.format("- Registries: `%d` profiles • `%d` provenance pools • `%d` starting-zone cases",
        #(Zone.ProfileRegistry and Zone.ProfileRegistry.order or {}),
        #(Zone.ProvenanceRegistry and Zone.ProvenanceRegistry.list or {}),
        #(Zone.StartingZoneRegistry and Zone.StartingZoneRegistry.list or {})))
    local collisions = Zone.ProfileRegistry and Zone.ProfileRegistry.collisions or {}
    Add(lines, "- Profile alias collisions: " .. tostring(#SortedKeys(collisions)))
    for _, alias in ipairs(SortedKeys(collisions)) do
        Add(lines, string.format("  - `%s`: %s", tostring(alias), JoinList(collisions[alias])))
    end
    Add(lines, "")
end

local function AddSnapshot(lines, snapshot)
    local location, identity = snapshot.location or {}, snapshot.identity or {}
    local era, provenance = snapshot.era or {}, snapshot.provenance or {}
    local fallback, restrictions = snapshot.fallback or {}, snapshot.restrictions or {}
    Add(lines, "## Current Zone context snapshot")
    Add(lines, "")
    Add(lines, string.format("- Fingerprint: `%s`", tostring(snapshot.fingerprint or "Unknown")))
    Add(lines, string.format("- Captured: `%s`", type(date) == "function" and date("%Y-%m-%d %H:%M:%S", snapshot.capturedAt or 0) or tostring(snapshot.capturedAt or 0)))
    Add(lines, string.format("- Location: **%s%s**", Cell(location.zone or "Unknown"), location.subzone and location.subzone ~= "" and (" / " .. Cell(location.subzone)) or ""))
    Add(lines, string.format("- Map: `%s` • %s", tostring(location.mapID or "Unknown"), Cell(location.mapName or "Unknown")))
    Add(lines, "- Map trail: " .. JoinList(location.mapTrail))
    Add(lines, string.format("- Zone key: `%s` • detail key: `%s`", tostring(location.zoneKey or ""), tostring(location.detailKey or "")))
    Add(lines, string.format("- Style identity: **%s** (`%s`) • `%s` • confidence `%.3f`", Cell(identity.label), Cell(identity.profileKey), Cell(identity.resolutionLevel), tonumber(identity.confidence) or 0))
    Add(lines, "- Description: " .. Cell(identity.description or ""))
    Add(lines, string.format("- Era: **Through %s** (`%s`) • `%s` • confidence `%.3f`", Cell(era.shortLabel or era.label), tostring(era.maxExpansionID or "?"), Cell(era.resolutionLevel), tonumber(era.confidence) or 0))
    Add(lines, string.format("- Provenance: **%s**%s • `%s` • confidence `%.3f`", Cell(provenance.label or "Unresolved"), provenance.key and (" (`" .. Cell(provenance.key) .. "`)") or "", Cell(provenance.resolutionLevel), tonumber(provenance.confidence) or 0))
    Add(lines, "- Restriction: " .. Cell(restrictions.restrictionLabel or "Unknown"))
    Add(lines, string.format("- Era restriction enabled: `%s`", tostring(restrictions.eraEnabled == true)))
    Add(lines, string.format("- Favorite scope: `%s` • exclusion scope: `%s`", tostring(restrictions.favoriteScopeKey or ""), tostring(restrictions.exclusionScopeKey or "")))
    Add(lines, string.format("- Starting-zone case: `%s`", tostring(snapshot.startingZoneCaseID or "None")))
    Add(lines, string.format("- Fallback: `%s`%s", fallback.used and "YES" or "NO", fallback.reason and (" • " .. Cell(fallback.reason)) or ""))
    Add(lines, "")
end

local function AddStyle(lines, snapshot)
    local style = snapshot.style or {}
    Add(lines, "## Canonical Zone style evidence")
    Add(lines, "")
    Add(lines, "| Channel | Coverage | Signals |")
    Add(lines, "|---|---|---|")
    for _, channel in ipairs(STYLE_CHANNELS) do
        Add(lines, string.format("| %s | `%s` | %s |", channel, Cell(style.coverage and style.coverage[channel] or "UNKNOWN"), Cell(FormatMap(style[channel]))))
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
        Add(lines, string.format("| %d | `%s` | %s | %s | %s | %s | `%s` | %.3f | `%s` |",
            index, Cell(entry.channel), Cell(entry.subject), Cell(entry.value), Cell(entry.matchedText),
            Cell(entry.matchedAlias), Cell(entry.sourceLevel), tonumber(entry.confidence) or 0, Cell(entry.registryKey)))
    end
    if #(evidence.entries or {}) == 0 then Add(lines, "|  |  |  |  |  |  |  |  |  |") end
    Add(lines, "")
    for _, warning in ipairs(evidence.warnings or {}) do Add(lines, "- Evidence warning: " .. Cell(warning)) end
    if #(evidence.warnings or {}) > 0 then Add(lines, "") end
end

local function AddAffinity(lines, affinity)
    Add(lines, "## Current-look Zone affinity")
    Add(lines, "")
    Add(lines, string.format("- Selected visible pieces: **%d**", tonumber(affinity.selected) or 0))
    Add(lines, string.format("- Mean affinity: `%.3f`", tonumber(affinity.score) or 0))
    Add(lines, string.format("- Mean confidence: `%.3f`", tonumber(affinity.confidence) or 0))
    Add(lines, "- Classifications: " .. FormatMap(affinity.classifications))
    Add(lines, "")
    Add(lines, "| Slot | Appearance | Source ID | Visual ID | Classification | Score | Confidence | Missing channels |")
    Add(lines, "|---|---|---:|---:|---|---:|---:|---|")
    for _, piece in ipairs(affinity.pieces or {}) do
        Add(lines, string.format("| `%s` | %s | %s | %s | `%s` | %.3f | %.3f | %s |",
            Cell(piece.slotKey), Cell(SourceLabel(piece)), Cell(piece.sourceID), Cell(piece.visualID),
            Cell(piece.classification), tonumber(piece.score) or 0, tonumber(piece.confidence) or 0,
            Cell(JoinList(piece.missingChannels))))
    end
    if #(affinity.pieces or {}) == 0 then Add(lines, "|  | No selected visible pieces |  |  |  |  |  |  |") end
    Add(lines, "")
    for _, piece in ipairs(affinity.pieces or {}) do
        Add(lines, string.format("### %s • %s", Cell(piece.slotKey), Cell(SourceLabel(piece))))
        Add(lines, "")
        Add(lines, string.format("- Classification: `%s` • score `%.3f` • confidence `%.3f`", Cell(piece.classification), tonumber(piece.score) or 0, tonumber(piece.confidence) or 0))
        Add(lines, string.format("- Descriptor: `%s`", tostring(piece.descriptorFingerprint or "Unknown")))
        Add(lines, string.format("- Profile: `%s` • provenance: `%s`", tostring(piece.profileKey or "Unknown"), tostring(piece.provenanceKey or "None")))
        Add(lines, "- Components:")
        for _, component in ipairs(AFFINITY_COMPONENTS) do
            local value = piece.components and piece.components[component]
            Add(lines, string.format("  - %s: `%s`", component, value == nil and "MISSING" or string.format("%.3f", tonumber(value) or 0)))
        end
        Add(lines, "- Evidence:")
        for _, entry in ipairs(piece.evidence or {}) do
            Add(lines, string.format("  - `%s` • %s • confidence `%.3f`", Cell(entry.channel), Cell(entry.value), tonumber(entry.confidence) or 0))
        end
        if #(piece.evidence or {}) == 0 then Add(lines, "  - None") end
        Add(lines, "")
    end
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
    Add(lines, string.format("- Report ID: `%s`", tostring(report.id or "Unknown")))
    Add(lines, string.format("- Time: `%s`", tostring(report.timestampText or report.timestamp or "Unknown")))
    Add(lines, string.format("- Action: `%s` • result: `%s`", tostring(report.action or "Unknown"), tostring(report.result or "Unknown")))
    Add(lines, string.format("- Generation implementation: `%s`", tostring(report.generationImplementation or "Unknown")))
    Add(lines, string.format("- Zone foundation: `%s`", tostring(foundation.foundation or "Not recorded")))
    Add(lines, string.format("- Snapshot fingerprint: `%s`", tostring(foundation.fingerprint or "Not recorded")))
    Add(lines, string.format("- Compatibility parity: `%s`", tostring(foundation.compatibility or "Not recorded")))
    local affinity = foundation.affinity or {}
    Add(lines, string.format("- Recorded affinity: `%.3f` • confidence `%.3f` • `%d` pieces",
        tonumber(affinity.score) or 0, tonumber(affinity.confidence) or 0, tonumber(affinity.selected) or 0))
    Add(lines, "- Message: " .. Cell(report.message or ""))
    Add(lines, "")
end

function Zone.BuildZoneDebugExport(snapshot, affinity)
    snapshot = snapshot or ZoneStyle.GetZoneContextSnapshot()
    affinity = affinity or Zone.BuildSelectedOutfitAffinity(nil, snapshot)
    local foundation = Zone.GetFoundationStatus and Zone.GetFoundationStatus() or {}
    local compatibility = ZoneStyle.GetZoneCompatibilityStatus and ZoneStyle.GetZoneCompatibilityStatus() or { pass = false, differences = { "Compatibility status unavailable." } }
    local lines = {}
    Add(lines, "# Quest Chronicle Zone Debug Export")
    Add(lines, "")
    Add(lines, string.format("- Quest Chronicle version: `%s`", tostring(QC.version or "Unknown")))
    Add(lines, string.format("- Generated: `%s`", type(date) == "function" and date("%Y-%m-%d %H:%M:%S") or "Unknown"))
    Add(lines, "- Command: `/qc zone debug export`")
    Add(lines, "")
    AddArchitecture(lines, foundation)
    AddFoundation(lines, foundation, compatibility)
    AddSnapshot(lines, snapshot)
    AddStyle(lines, snapshot)
    AddEvidence(lines, snapshot)
    AddAffinity(lines, affinity)
    AddLatestReport(lines, LatestZoneReport())
    return table.concat(lines, "\n"), {
        format = Zone.DEBUG_EXPORT_FORMAT,
        evidenceEntries = #(snapshot.evidence and snapshot.evidence.entries or {}),
        selectedPieces = tonumber(affinity.selected) or 0,
        profileKey = snapshot.identity and snapshot.identity.profileKey or nil,
        fingerprint = snapshot.fingerprint,
    }
end

function ZoneStyle.BuildZoneDebugExport(snapshot, affinity)
    return Zone.BuildZoneDebugExport(snapshot, affinity)
end
