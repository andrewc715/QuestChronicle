QuestChronicle = { Diagnostics = { _Private = {} } }
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_anchor_report_v1113.lua$", "")
assert(loadfile(root .. "Core/Diagnostics/ReportFormatter.lua"))()
local report = {
    version = "1.11.4", timestamp = 1, timestampText = "2026-08-06 08:00:00",
    character = { name = "Xyrkian", realm = "MoonGuard", className = "WARRIOR" },
    action = "GENERATE_OUTFIT", mode = "ZONE_NATIVE", generationImplementation = "LEGACY",
    result = "COMPLETED", message = "Generated a Zone Native outfit.", context = { profileLabel = "Outland" },
    outfit = { generatedName = "Netherstorm Field Kit" },
    skeleton = { components = {}, scoreBreakdown = {}, cohesionComponents = {}, excludedComponents = {} },
    beam = {}, cache = {}, performance = { steps = 1, elapsedMs = 1, phaseStats = { zoneAnchorPolicy = { maxMs = 0.4, totalMs = 2, calls = 10 } }, schedulerDiagnostics = {} },
    warnings = {}, zoneFoundation = {
        foundation = "CONTEXT_EVIDENCE_V1", fingerprint = "ZCTX-test", compatibility = "PASS",
        identity = { label = "Outland", profileKey = "outland" }, era = {}, provenance = {}, coverage = {},
        anchorPolicy = {
            policyID = "ZONE_ANCHOR_POLICY_V1", authority = "ACTIVE", snapshotFingerprint = "ZCTX-test",
            supportPolicy = "LEGACY", selected = {
                { slotKey = "CHEST", legacyRelevance = 20, affinity = 0.8, confidence = 0.7, adjustment = 7, finalRelevance = 27 },
            }, pools = { CHEST = { prepared = 42, retained = 32, unknown = 2, meanAffinity = 0.5, meanAdjustment = 1.2 } },
            visualArmorRelationshipBonus = 10, armorPairSupport = 2, visualWeaponRelationshipBonus = 8, weaponPairSupport = 1,
            routeFamily = "TWO_HAND", logicalWeapons = { {} }, linkedVisualDeduplicated = true,
        },
    },
}
local text = QuestChronicle.Diagnostics.FormatCopyReport(report, false, false)
for _, expected in ipairs({
    "== Zone Anchor Policy ==", "Policy: ZONE_ANCHOR_POLICY_V1 • ACTIVE", "Support policy: LEGACY",
    "CHEST", "Pair interpretation: visual armor 10.00 • Zone armor 2.00",
    "Weapon bundle: TWO_HAND • 1 logical visual • linked deduplicated Yes", "Zone anchor policy",
}) do assert(text:find(expected, 1, true), "missing v1.11.4 Zone policy report text: " .. expected) end
print("PASS v1.11.4 Zone report: policy decomposition, legacy support boundary, weapon dedup, and performance")
