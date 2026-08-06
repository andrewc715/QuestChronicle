QuestChronicle = { Diagnostics = nil, _Core = {} }
QuestChronicleDB = { ui = {} }
QuestChronicle.Notify = function() end
QuestChronicle.GetCurrentCharacter = function() return { key = "Tester-Realm", name = "Tester", realm = "Realm" } end

dofile("Core/Diagnostics/Foundation.lua")
dofile("Core/Diagnostics/ReportCompaction.lua")
dofile("Core/Diagnostics/History.lua")

local D = QuestChronicle.Diagnostics
local slots = { "CHEST", "LEGS", "SHOULDER", "TWO_HAND", "OFF_HAND" }
local components, selected = {}, {}
for index, slotKey in ipairs(slots) do
    local policy = {
        policyID = "ZONE_ANCHOR_POLICY_V1", policyFormat = 1, authority = "ACTIVE",
        legacyRelevance = 20 + index, zoneAffinity = 0.602, zoneConfidence = 0.624,
        zoneClassification = "SUPPORTED_LOCAL_VARIATION", zoneAdjustment = 5.1,
        slotMultiplier = 1.1, rawAdjustment = 5.04, boundedAdjustment = 5.04,
        confidenceFactor = 0.96, finalRelevance = 25 + index,
        reasons = { string.rep("Long Zone policy reason ", 18), string.rep("Secondary explanation ", 12) },
    }
    components[#components + 1] = {
        slotKey = slotKey, slotLabel = slotKey, name = string.rep("Selected Zone anchor ", 8),
        sourceID = 1000 + index, visualID = 2000 + index, itemID = 3000 + index,
        baseScore = 25 + index, scoreReasons = { string.rep("Score reason ", 30) }, anchorPolicy = policy,
    }
    selected[#selected + 1] = {
        slotKey = slotKey, name = "Selected Zone anchor", sourceID = 1000 + index, visualID = 2000 + index,
        legacyRelevance = 20 + index, affinity = 0.602, confidence = 0.624,
        classification = "SUPPORTED_LOCAL_VARIATION", adjustment = 5.1, finalRelevance = 25 + index,
    }
end

local affinityPieces = {}
for index = 1, 12 do
    affinityPieces[index] = {
        slotKey = "SLOT_" .. index, sourceID = 4000 + index, visualID = 5000 + index,
        score = 0.434, confidence = 0.512, classification = "WEAK_LOCAL_SIGNAL",
        components = { palette = 0.6, material = 0.6, finish = 0, motif = 0, culture = 0, magic = 0 },
        componentStatus = {
            palette = "VALUE", material = "VALUE", finish = "MISSING", motif = "MISSING",
            culture = "VALUE", magic = "VALUE", avoids = "NOT_APPLICABLE", provenance = "MISSING",
        },
        missingChannels = { "finish", "motif", "provenance" }, notApplicableChannels = { "avoids" },
    }
end

local supportDecisions = {}
for index = 1, 8 do
    supportDecisions[index] = {
        slotKey = "SUPPORT_" .. index, name = string.rep("Support decision ", 6),
        sourceID = 6000 + index, visualID = 7000 + index, itemID = 8000 + index,
        role = string.rep("Context role ", 8), scoreReasons = { string.rep("support score ", 20) },
    }
end

local phaseStats = {}
for index = 1, 45 do phaseStats["phase_" .. index] = { calls = 100 + index, totalMs = 50 + index, maxMs = 1 + index / 10 } end

local report, message = D.AddReport({
    formatVersion = D.FORMAT_VERSION, id = "QCDBG-ZONE-PERSIST-1", sequence = 1,
    timestamp = 1785981000, timestampText = "2026-08-06 09:50:00", version = "1.11.4",
    action = "GENERATE_OUTFIT", result = "COMPLETED", generationToken = "QCGEN-ZONE-PERSIST-1",
    lineageID = "Tester-Realm", character = { key = "Tester-Realm", name = "Tester", realm = "Realm" },
    outfit = { generatedName = "Zone Policy Persistence", slots = components },
    skeleton = { components = components, scoreBreakdown = { total = 123 }, cohesionComponents = {}, excludedComponents = {} },
    support = {
        profile = {
            profileID = "QCPROFILE-ZONE-PERSIST", activeAnchors = components, entries = components,
            descriptor = { palette = { steel = 1, purple = 0.8 }, material = { plate = 1 }, setIDs = { 1, 2, 3 } },
        },
        decisions = supportDecisions, repairs = {}, finalValidationStatus = "CLEAN",
    },
    performance = { elapsedMs = 6000, maxStepMs = 7.1, phaseStats = phaseStats },
    cache = { invalidationReasons = { NONE = 0 } }, warnings = {},
    zoneFoundation = {
        foundation = "CONTEXT_EVIDENCE_V1", fingerprint = "ZCTX-ZONE-PERSIST", compatibility = "PASS",
        identity = { label = "Outland", profileKey = "outland" }, era = { label = "Through TBC" },
        provenance = { label = "Shadowmoon Valley" }, coverage = {},
        affinity = {
            selected = 12, score = 0.297, confidence = 0.470,
            classifications = { OFF_ZONE_SIGNAL = 3, WEAK_LOCAL_SIGNAL = 6, UNKNOWN = 2, SUPPORTED_LOCAL_VARIATION = 1 },
            pieces = affinityPieces,
        },
        anchorPolicy = {
            policyID = "ZONE_ANCHOR_POLICY_V1", policyFormat = 1, authority = "ACTIVE", supportPolicy = "LEGACY",
            snapshotFingerprint = "ZCTX-ZONE-PERSIST", selected = selected,
            pools = {
                CHEST = { prepared = 42, eligible = 42, retained = 32, unknown = 3, offZone = 12, weakLocal = 17, supportedLocal = 8, strongLocal = 2, meanAffinity = 0.33, meanAdjustment = 0.2 },
                LEGS = { prepared = 32, eligible = 29, retained = 24, unknown = 2, offZone = 10, weakLocal = 12, supportedLocal = 4, strongLocal = 1, meanAffinity = 0.35, meanAdjustment = 0.4 },
                SHOULDER = { prepared = 31, eligible = 31, retained = 24, unknown = 2, offZone = 10, weakLocal = 13, supportedLocal = 5, strongLocal = 1, meanAffinity = 0.37, meanAdjustment = 0.5 },
            },
            armorPairSupport = 2.1, weaponPairSupport = 1.2,
            visualArmorRelationshipBonus = 30, visualWeaponRelationshipBonus = 12,
            logicalWeapons = { { slotKey = "TWO_HAND", name = "Brutal War Axe", sourceID = 1134, visualID = 1118, affinity = 0, confidence = 0, adjustment = 0 } },
            linkedVisualDeduplicated = true, routeFamily = "TWO_HAND",
        },
    },
})

assert(report, message or "realistic v1.11.3 Zone report must survive compaction")
assert(#D.GetReports() == 1 and D.GetReports()[1].id == "QCDBG-ZONE-PERSIST-1", "Zone report must remain visible in Debug History")
assert((report.approximateBytes or math.huge) <= D.MAX_REPORT_BYTES, "Zone report remained above the persistence ceiling")
assert(report.zoneFoundation.anchorPolicy.policyID == "ZONE_ANCHOR_POLICY_V1", "authoritative Zone policy summary was lost")
assert(#(report.zoneFoundation.anchorPolicy.selected or {}) == 5, "selected Zone anchor evidence was lost")
assert(report.zoneFoundation.anchorPolicy.pools.CHEST.retained == 32, "Zone pool summary was lost")
assert(report.zoneFoundation.anchorPolicy.armorPairSupport == 2.1, "Zone pair support was lost")
assert(report.zoneFoundation.anchorPolicy.linkedVisualDeduplicated == true, "weapon deduplication result was lost")
assert(report.zoneFoundation.affinity.pieces == nil, "duplicate per-piece affinity ledger should be compacted")
for _, component in ipairs(report.skeleton.components or {}) do
    assert(component.anchorPolicy == nil, "component-level Zone policy duplicate should be compacted")
end
assert(report.support.profile.entries, "support-profile ancestry required by rerolls must survive")
assert(report.support.finalValidationStatus == "CLEAN", "Phase D result must survive")
local trimmed = false
for _, warning in ipairs(report.warnings or {}) do if warning.key == "REPORT_TRIMMED" then trimmed = true end end
assert(trimmed, "compacted Zone report must retain a trimming warning")

print(string.format("PASS v1.11.4 realistic Zone report retained after policy-aware compaction: %d bytes", report.approximateBytes or 0))
