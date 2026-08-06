QuestChronicle = { Diagnostics = { _Private = {} } }
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_report_format_v1110.lua$", "")
assert(loadfile(root .. "Core/Diagnostics/ReportFormatter.lua"))()
local D = QuestChronicle.Diagnostics
local report = {
    version = "1.11.0", timestamp = 1, timestampText = "2026-08-05 20:00:00",
    character = { name = "Xyrkian", realm = "MoonGuard", className = "WARRIOR" },
    action = "GENERATE_OUTFIT", mode = "ZONE_NATIVE", generationImplementation = "LEGACY",
    result = "COMPLETED", message = "Generated a Zone Native outfit.",
    context = { profileLabel = "Outland", eraLabel = "The Burning Crusade" },
    outfit = { generatedName = "Netherstorm Field Kit" },
    skeleton = { components = {}, scoreBreakdown = {}, cohesionComponents = {}, excludedComponents = {} },
    beam = {}, cache = {}, performance = { steps = 1, elapsedMs = 1, phaseStats = {}, schedulerDiagnostics = {} },
    warnings = {},
    zoneFoundation = {
        foundation = "CONTEXT_EVIDENCE_V1", contextFormat = 1, profileRegistryVersion = 1, provenanceRegistryVersion = 1,
        fingerprint = "ZCTX-test", evidenceCount = 9, compatibility = "PASS",
        identity = { label = "Outland", profileKey = "outland", resolutionLevel = "EXACT_ZONE", confidence = 0.9 },
        era = { shortLabel = "TBC", resolutionLevel = "EXACT_ZONE", confidence = 0.9 },
        provenance = { label = "Netherstorm", key = "netherstorm", resolutionLevel = "EXACT_ZONE", confidence = 0.9 },
        fallback = { used = false }, coverage = { palette = "KNOWN", material = "KNOWN", magic = "KNOWN", avoids = "NOT_APPLICABLE" },
        affinity = { selected = 2, score = 0.72, confidence = 0.65, classifications = { LOCALLY_COHERENT = 2 } },
    },
}
local text = D.FormatCopyReport(report, false, false)
for _, expected in ipairs({
    "Generation implementation: LEGACY", "Zone foundation: CONTEXT_EVIDENCE_V1",
    "== Zone Context and Evidence ==", "Profile: Outland (outland)",
    "Provenance: Netherstorm (netherstorm)", "Compatibility parity: PASS",
    "Selected-outfit Zone affinity: 0.720",
}) do assert(text:find(expected, 1, true), "missing Zone report text: " .. expected) end
print("PASS v1.11.0 Zone report formatting: additive foundation, parity, evidence, and affinity sections")
