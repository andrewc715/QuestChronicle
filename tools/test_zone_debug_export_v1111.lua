QuestChronicle = {
    version = "1.11.2",
    ZoneStyle = {
        MODE_TRAVELER = "TRAVELER",
        MODE_ZONE_NATIVE = "ZONE_NATIVE",
        MODE_CLASS_FANTASY = "CLASS_FANTASY",
        MODE_CHRONICLE_ECHO = "CHRONICLE_ECHO",
        Zone = {},
    },
    Generation = {
        POLICY_CONTRACT_VERSION = 1,
        API_CONTRACT_VERSION = 1,
    },
    Diagnostics = {},
    Wardrobe = { _Private = {} },
}
local QC = QuestChronicle
local Zone = QC.ZoneStyle.Zone
Zone.FOUNDATION_ID = "CONTEXT_EVIDENCE_V1"
Zone.CONTEXT_FORMAT = 1
Zone.AFFINITY_FORMAT = 2
Zone.ProfileRegistry = { order = { "azeroth", "outland" }, collisions = { storm = { "one", "two" } } }
Zone.ProvenanceRegistry = { list = { {}, {}, {} } }
Zone.StartingZoneRegistry = { list = { {} } }
Zone.snapshotBuildCount = 2
Zone.GetFoundationStatus = function()
    return {
        foundation = "CONTEXT_EVIDENCE_V1", contextFormat = 1,
        profileRegistryVersion = 1, provenanceRegistryVersion = 1,
        startingZoneRegistryVersion = 1, eraRuleVersion = 1, affinityFormat = 2,
    }
end
QC.ZoneStyle.GetZoneCompatibilityStatus = function() return { pass = true, differences = {} } end

local modes = {
    TRAVELER = { displayLabel = "Traveler", implementation = "SHARED_FRAMEWORK", implementationGeneration = 1 },
    ZONE_NATIVE = { displayLabel = "Zone Native", implementation = "LEGACY", implementationGeneration = 1, zoneFoundation = "CONTEXT_EVIDENCE_V1" },
    CLASS_FANTASY = { displayLabel = "Class Fantasy", implementation = "LEGACY", implementationGeneration = 1 },
    CHRONICLE_ECHO = { displayLabel = "Chronicle Echo", implementation = "LEGACY", implementationGeneration = 1 },
}
QC.Generation.GetModeCapabilities = function(modeID) return modes[modeID] end
QC.Diagnostics.GetReports = function()
    return {
        { mode = "TRAVELER", id = "traveler" },
        {
            mode = "ZONE_NATIVE", id = "zone-report", timestampText = "2026-08-05 20:30:00",
            action = "GENERATE_OUTFIT", result = "COMPLETED", generationImplementation = "LEGACY",
            message = "Generated a Zone Native outfit.",
            zoneFoundation = {
                foundation = "CONTEXT_EVIDENCE_V1", fingerprint = "ZCTX-test",
                compatibility = "PASS", affinity = { score = 0.75, confidence = 0.65, selected = 1 },
            },
        },
    }
end
QC.Wardrobe._Private.GetSourceByID = function(slotKey, sourceID)
    return { name = slotKey == "CHEST" and "Field Plate Armor" or "Unknown" }
end

local evidence = {}
for index = 1, 12 do
    evidence[index] = {
        channel = index == 1 and "PROFILE_ALIAS" or "MAP_TRAIL",
        subject = "zone_profile", value = "Outland " .. index,
        matchedText = "Netherstorm", matchedAlias = "outland",
        sourceLevel = "EXACT_ZONE", confidence = 0.9, registryKey = "outland",
    }
end
local snapshot = {
    capturedAt = 0, fingerprint = "ZCTX-test", startingZoneCaseID = nil,
    location = { zone = "Netherstorm", subzone = "Area 52", mapID = 109, mapName = "Netherstorm", mapTrail = { "Outland" }, zoneKey = "netherstorm", detailKey = "outland:netherstorm" },
    identity = { label = "Outland", profileKey = "outland", description = "A harsh alien frontier.", resolutionLevel = "EXACT_ZONE", confidence = 0.9 },
    era = { shortLabel = "TBC", label = "The Burning Crusade", maxExpansionID = 1, resolutionLevel = "EXACT_ZONE", confidence = 0.9 },
    provenance = { label = "Netherstorm", key = "netherstorm", resolutionLevel = "EXACT_ZONE", confidence = 0.9 },
    restrictions = { restrictionLabel = "Through TBC • Netherstorm sources", eraEnabled = true, favoriteScopeKey = "netherstorm", exclusionScopeKey = "netherstorm" },
    fallback = { used = false },
    style = {
        coverage = { culture = "KNOWN", climate = "KNOWN", terrain = "KNOWN", palette = "KNOWN", material = "KNOWN", finish = "KNOWN", motif = "KNOWN", magic = "KNOWN", silhouette = "KNOWN", avoids = "NOT_APPLICABLE" },
        culture = { ethereal = 1 }, climate = { arcane = 1 }, terrain = { shattered = 1 },
        palette = { purple = 0.6, steel = 0.4 }, material = { plate = 1 }, finish = { weathered = 1 },
        motif = { frontier = 1 }, magic = { arcane = 1 }, silhouette = { practical = 1 }, avoids = {},
    },
    evidence = { entries = evidence, warnings = {} },
}
local affinity = {
    selected = 1, score = 0.72, confidence = 0.66, classifications = { LOCALLY_COHERENT = 1 },
    pieces = {
        {
            slotKey = "CHEST", sourceID = 101, visualID = 202,
            classification = "LOCALLY_COHERENT", score = 0.72, confidence = 0.66,
            missingChannels = {}, descriptorFingerprint = "TRAVELER-test",
            profileKey = "outland", provenanceKey = "netherstorm",
            components = { palette = 0.8, material = 1, finish = 0.6, motif = 0.7, culture = 0.5, magic = 0.4, avoids = 1, provenance = 1 },
            evidence = { { channel = "VISUAL_DESCRIPTOR", value = "TRAVELER-test", confidence = 0.8 } },
        },
    },
}
QC.ZoneStyle.GetZoneContextSnapshot = function() return snapshot end
Zone.BuildSelectedOutfitAffinity = function() return affinity end

local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_debug_export_v1111.lua$", "")
assert(loadfile(root .. "Core/ZoneStyle/Zone/ExportEncoding.lua"))()
assert(loadfile(root .. "Core/ZoneStyle/Zone/DebugExport.lua"))()
local text, status = Zone.BuildZoneDebugExport(snapshot, affinity)
for _, expected in ipairs({
    "# Quest Chronicle Zone Debug Export",
    "Quest Chronicle version: `1.11.2`",
    "| Traveler | `TRAVELER` | `SHARED_FRAMEWORK`",
    "| Zone Native | `ZONE_NATIVE` | `LEGACY` | 1 | `CONTEXT_EVIDENCE_V1` |",
    "## Complete evidence ancestry",
    "Entries: **12**",
    "Outland 12",
    "## Current-look Zone affinity",
    "Field Plate Armor",
    "Descriptor: `TRAVELER-test`",
    "## Latest Zone Native diagnostic report",
    "Report ID: `zone-report`",
}) do
    assert(text:find(expected, 1, true), "missing Zone export text: " .. expected)
end
assert(not text:find("additional entries omitted", 1, true), "export truncated evidence ancestry")
assert(status.evidenceEntries == 12 and status.selectedPieces == 1, "export status counters are incorrect")
print("PASS inherited Zone debug export: complete architecture, evidence, affinity, and report snapshot")
