local QC = QuestChronicle
local Generation = QC.Generation
local ZoneStyle = QC.ZoneStyle
local Traveler = ZoneStyle and ZoneStyle.Traveler
local modeID = ZoneStyle and ZoneStyle.MODE_ZONE_NATIVE or "ZONE_NATIVE"

local policy = Generation._Private.CreateLegacyWardrobePolicy({
    modeID = modeID,
    displayLabel = "Zone Native",
    diagnosticLabel = "Zone",
    implementationGeneration = 1,
    capabilities = {
        generate = true, rerollUnlocked = true, rerollSlot = true,
        rerollSupportSlot = true, cancel = true,
        sharedFramework = false, legacy = true,
        zoneContextFormat = 1, zoneEvidence = true, zoneAffinityDiagnostics = true,
        zoneAnchorPolicy = false, zoneSupportPolicy = false,
        zoneFinalValidation = false, zoneTuningAudit = false,
        zoneFoundation = "CONTEXT_EVIDENCE_V1",
    },
    visualLanguage = {
        GetDescriptor = function(...) return Traveler and Traveler.GetDescriptor and Traveler.GetDescriptor(...) end,
        GetPairCohesion = function(...) return Traveler and Traveler.GetPairCohesion and Traveler.GetPairCohesion(...) end,
        GetCuratedMetadata = function(...) return Traveler and Traveler.GetCuratedDescriptorMetadata and Traveler.GetCuratedDescriptorMetadata(...) end,
    },
    contextPolicy = Generation.ZoneContextPolicy,
    diagnosticsPolicy = Generation.ZoneDiagnosticsPolicy,
})
policy.affinityPolicy = Generation.ZoneAffinityPolicy

local ok, reason = Generation.RegisterGenerationMode(modeID, policy)
assert(ok, reason)
