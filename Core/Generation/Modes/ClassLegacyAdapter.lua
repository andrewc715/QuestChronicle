local QC = QuestChronicle
local Generation = QC.Generation
local ZoneStyle = QC.ZoneStyle
local modeID = ZoneStyle and ZoneStyle.MODE_CLASS_FANTASY or "CLASS_FANTASY"
local policy = Generation._Private.CreateLegacyWardrobePolicy({
    modeID = modeID,
    displayLabel = "Class Fantasy",
    diagnosticLabel = "Class",
    implementationGeneration = 1,
})
local ok, reason = Generation.RegisterGenerationMode(modeID, policy)
assert(ok, reason)
