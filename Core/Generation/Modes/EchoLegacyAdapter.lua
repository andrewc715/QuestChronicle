local QC = QuestChronicle
local Generation = QC.Generation
local ZoneStyle = QC.ZoneStyle
local modeID = ZoneStyle and ZoneStyle.MODE_CHRONICLE_ECHO or "CHRONICLE_ECHO"
local policy = Generation._Private.CreateLegacyWardrobePolicy({
    modeID = modeID,
    displayLabel = "Chronicle Echo",
    diagnosticLabel = "Echo",
    implementationGeneration = 1,
})
local ok, reason = Generation.RegisterGenerationMode(modeID, policy)
assert(ok, reason)
