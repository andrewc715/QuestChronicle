QuestChronicle = {
    version = "1.11.4",
    ZoneStyle = {
        MODE_TRAVELER = "TRAVELER", MODE_ZONE_NATIVE = "ZONE_NATIVE",
        MODE_CLASS_FANTASY = "CLASS_FANTASY", MODE_CHRONICLE_ECHO = "CHRONICLE_ECHO",
        Zone = {}, _Private = {},
    },
    Generation = { POLICY_CONTRACT_VERSION = 1, API_CONTRACT_VERSION = 1 },
    Diagnostics = {}, Wardrobe = { _Private = {} },
}
local QC = QuestChronicle
local ZoneStyle, Zone = QC.ZoneStyle, QC.ZoneStyle.Zone
ZoneStyle._Private.Normalize = function(value) return tostring(value or ""):lower() end
Zone.AFFINITY_FORMAT = 2
Zone.FOUNDATION_ID = "CONTEXT_EVIDENCE_V1"
Zone.CONTEXT_FORMAT = 1
Zone.AFFINITY_COMPONENT_STATUS = { VALUE = "VALUE", MISSING = "MISSING", NOT_APPLICABLE = "NOT_APPLICABLE" }
local function Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for key, child in pairs(value) do out[key] = Copy(child) end; return out
end
Zone.CopyPrimitive = Copy
Zone.ProfileRegistry = { order = { "outland" }, collisions = {} }
Zone.ProvenanceRegistry = { list = { {} } }
Zone.StartingZoneRegistry = { list = { {} } }
Zone.GetFoundationStatus = function()
    return { foundation = Zone.FOUNDATION_ID, contextFormat = 1, profileRegistryVersion = 1,
        provenanceRegistryVersion = 1, startingZoneRegistryVersion = 1, eraRuleVersion = 1, affinityFormat = 2 }
end
ZoneStyle.GetZoneCompatibilityStatus = function() return { pass = true, differences = {} } end
QC.Generation.GetModeCapabilities = function(modeID)
    local shared = modeID == "TRAVELER"
    return { displayLabel = ({TRAVELER="Traveler",ZONE_NATIVE="Zone Native",CLASS_FANTASY="Class Fantasy",CHRONICLE_ECHO="Chronicle Echo"})[modeID],
        implementation = shared and "SHARED_FRAMEWORK" or "LEGACY", implementationGeneration = 1,
        zoneFoundation = modeID == "ZONE_NATIVE" and "CONTEXT_EVIDENCE_V1" or nil }
end
QC.Diagnostics.GetReports = function() return {} end
local labels = {
    HEAD = "Templar Crown", SHOULDER = "Imperial Plate Shoulders", BACK = "Royal Cloak of the Sunstriders",
    CHEST = "Replica Lightforge Breastplate", SHIRT = "Stylish Black Shirt", WRIST = "Templar Bracers",
    HANDS = "Templar Gauntlets", WAIST = "G-Team Belt", LEGS = "Warrior's Greaves", FEET = "Heavy Lamellar Boots",
    TWO_HAND = "Splintering Battle Axe", OFF_HAND = "Splintering Battle Axe",
}
QC.Wardrobe._Private.GetSourceByID = function(slotKey) return { name = labels[slotKey] } end
local snapshot = {
    capturedAt = 0, fingerprint = "ZCTX-87cf0e98", location = { zone = "Netherstorm", subzone = "Ethereum Staging Grounds", mapID = 109, mapName = "Netherstorm", mapTrail = { "Netherstorm", "Outland", "Cosmic" }, zoneKey = "109:netherstorm", detailKey = "109:netherstorm:ethereum staging grounds:outland" },
    identity = { label = "Outland", profileKey = "outland", description = "Shattered-world survival gear.", resolutionLevel = "EXACT_ZONE", confidence = 0.9 },
    era = { shortLabel = "TBC", maxExpansionID = 1, resolutionLevel = "MAP_TRAIL", confidence = 0.8 },
    provenance = { label = "Netherstorm", key = "netherstorm", resolutionLevel = "EXACT_ZONE", confidence = 0.9 },
    restrictions = { restrictionLabel = "Through TBC • Netherstorm sources", eraEnabled = true, favoriteScopeKey = "netherstorm", exclusionScopeKey = "netherstorm" },
    fallback = { used = false },
    style = { coverage = { culture="KNOWN",climate="KNOWN",terrain="KNOWN",palette="KNOWN",material="KNOWN",finish="KNOWN",motif="KNOWN",magic="KNOWN",silhouette="KNOWN",avoids="NOT_APPLICABLE" }, culture={ethereal=.8}, climate={shattered=1}, terrain={nether=1}, palette={purple=.8}, material={plate=.6}, finish={weathered=.9}, motif={outland=1}, magic={nether=1}, silhouette={survival=1}, avoids={} },
    evidence = { entries = { { channel="PROFILE_ALIAS",subject="zone_profile",value="Outland|Netherstorm",matchedText="Netherstorm",matchedAlias="netherstorm",sourceLevel="EXACT_ZONE",confidence=.9,registryKey="outland" } }, warnings = {} },
}
local slots = { "HEAD","SHOULDER","BACK","CHEST","SHIRT","WRIST","HANDS","WAIST","LEGS","FEET","TWO_HAND","OFF_HAND" }
local scores = { .293,.293,.139,.293,0,.350,.350,.434,.434,.434,.233,.233 }
local confidences = { .624,.624,.629,.624,.579,.630,.630,.512,.512,.512,.277,.277 }
local classes = { "OFF_ZONE_SIGNAL","OFF_ZONE_SIGNAL","OFF_ZONE_SIGNAL","OFF_ZONE_SIGNAL","OFF_ZONE_SIGNAL","WEAK_LOCAL_SIGNAL","WEAK_LOCAL_SIGNAL","WEAK_LOCAL_SIGNAL","WEAK_LOCAL_SIGNAL","WEAK_LOCAL_SIGNAL","PARTIAL_EVIDENCE","PARTIAL_EVIDENCE" }
local dangerous = {
    "3153|3795|10168|Templar Crown|Plate|HEAD|Templar Crown",
    "|Hitem:123|h[Test]|h", "|Ttexture:path|t", "|cffffffffColor|r",
}
local affinity = { format=2, selected=12, score=0, confidence=0, classifications={ OFF_ZONE_SIGNAL=5, PARTIAL_EVIDENCE=2, WEAK_LOCAL_SIGNAL=5 }, pieces={} }
for index, slot in ipairs(slots) do
    affinity.score = affinity.score + scores[index]
    affinity.confidence = affinity.confidence + confidences[index]
    affinity.pieces[#affinity.pieces+1] = {
        format=2, slotKey=slot, sourceID=index, visualID=index+100, classification=classes[index], score=scores[index], confidence=confidences[index],
        missingChannels={"provenance"}, notApplicableChannels={"avoids"},
        descriptorFingerprint=dangerous[index] or (slot .. "|fixture"), profileKey="outland", provenanceKey="netherstorm",
        components={palette=.6}, componentStatus={palette="VALUE",material="MISSING",finish="MISSING",motif="MISSING",culture="MISSING",magic="MISSING",avoids="NOT_APPLICABLE",provenance="MISSING"},
        evidence={{channel="VISUAL_DESCRIPTOR",value=dangerous[index] or (slot .. "|fixture"),confidence=.5}},
    }
end
affinity.score = affinity.score / 12
affinity.confidence = affinity.confidence / 12
ZoneStyle.GetZoneContextSnapshot = function() return snapshot end
Zone.BuildSelectedOutfitAffinity = function() return affinity end

local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_debug_export_v1112.lua$", "")
assert(loadfile(root .. "Core/ZoneStyle/Zone/ExportEncoding.lua"))()
assert(loadfile(root .. "Core/ZoneStyle/Zone/Affinity.lua"))()
assert(loadfile(root .. "Core/ZoneStyle/Zone/DebugExport.lua"))()
local text, status = Zone.BuildZoneDebugExport(snapshot, affinity)
for _, expected in ipairs({
    "Quest Chronicle version: `1.11.4`", "Zone debug export format: `3`", "Zone affinity format: `2`",
    "Dynamic value encoding: `DIAGNOSTIC_ESCAPE_V1`", "Literal pipe representation: `\\u007C`",
    "Mean affinity: `0.291`", "Mean confidence: `0.536`",
    "OFF_ZONE_SIGNAL=5.000 • PARTIAL_EVIDENCE=2.000 • WEAK_LOCAL_SIGNAL=5.000",
    "3153\\u007C3795\\u007C10168\\u007CTemplar Crown\\u007CPlate\\u007CHEAD\\u007CTemplar Crown",
    "\\u007CHitem:123\\u007Ch[Test]\\u007Ch", "\\u007CTtexture:path\\u007Ct", "\\u007CcffffffffColor\\u007Cr",
    "Missing channels | N/A channels", "avoids: `NOT_APPLICABLE`", "N/A channels: avoids",
}) do assert(text:find(expected, 1, true), "missing v1.11.2 export text: " .. expected) end
assert(not text:find("HEADemplar", 1, true), "descriptor was corrupted at the export boundary")
assert(not Zone.ContainsUnsafeWoWControl(text), "serialized export retained an unsafe WoW control prefix")
assert(status.format == 3 and status.affinityFormat == 2 and status.encoding == "DIAGNOSTIC_ESCAPE_V1", "format metadata is incorrect")
assert(status.unsafeControlDetected == false, "export status detected an unsafe control token")
print("PASS v1.11.2 Zone debug export: Retail fixture is lossless, coverage-aware, and numerically unchanged")
