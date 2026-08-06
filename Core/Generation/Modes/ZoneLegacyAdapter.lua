local QC = QuestChronicle
local Generation = QC.Generation
local ZoneStyle = QC.ZoneStyle
local modeID = ZoneStyle and ZoneStyle.MODE_ZONE_NATIVE or "ZONE_NATIVE"
local policy = Generation._Private.CreateLegacyWardrobePolicy({
    modeID = modeID,
    displayLabel = "Zone Native",
    diagnosticLabel = "Zone",
    implementationGeneration = 1,
})
local ok, reason = Generation.RegisterGenerationMode(modeID, policy)
assert(ok, reason)
