QuestChronicle = { Wardrobe = { _Private = {} } }
local Wardrobe = QuestChronicle.Wardrobe
local P = Wardrobe._Private

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/Wardrobe/AppearanceMetadata.lua")

local old = {
    sourceID = 10, visualID = 50, metadataRevision = 7,
    eraManifestVersion = 3, eraSourceIDs = { 10, 11 },
    eraEvidenceVersion = 2, eraEvidenceVisualID = 50, eraEvidenceManifestVersion = 3,
    eraEvidenceMetadataRevision = 7, eraEvidenceExpansionID = 2,
    eraEvidenceMethod = "item", eraEvidenceCandidateCount = 2,
}
P.CaptureAppearanceGenerationCaches({ bySlot = { CHEST = { old } } })
local rebuilt = {
    sourceID = 10, visualID = 50, metadataRevision = 1,
    eraManifestVersion = 3, eraSourceIDs = { 10, 11 }, eraManifestSignature = "10,11",
}
assert(P.RestoreAppearanceGenerationCache(rebuilt), "matching visual cache was not restored")
assert(rebuilt.eraEvidenceState == "RESOLVED", "legacy resolved era state was not migrated")
assert(rebuilt.eraEvidenceExpansionID == 2, "resolved era expansion did not survive cache rebuild")
assert(rebuilt.eraEvidenceManifestSignature == "10,11", "legacy cache did not gain a manifest signature")

local changed = {
    sourceID = 10, visualID = 50, metadataRevision = 1,
    eraManifestVersion = 3, eraSourceIDs = { 10, 12 }, eraManifestSignature = "10,12",
}
assert(not P.RestoreAppearanceGenerationCache(changed), "changed visual manifest accepted stale evidence")

local unknown = {
    sourceID = 20, visualID = 60, metadataRevision = 3,
    eraManifestVersion = 3, eraSourceIDs = { 20, 21 }, eraManifestSignature = "20,21",
    eraEvidenceVersion = 2, eraEvidenceVisualID = 60, eraEvidenceManifestVersion = 3,
    eraEvidenceManifestSignature = "20,21", eraEvidenceMetadataRevision = 3,
    eraEvidenceState = "UNKNOWN", eraEvidenceUnknown = true,
    eraEvidenceReason = "No stable evidence.", eraEvidenceCandidateCount = 2,
}
P.CaptureAppearanceGenerationCaches({ bySlot = { HEAD = { unknown } } })
local rebuiltUnknown = {
    sourceID = 20, visualID = 60, metadataRevision = 1,
    eraManifestVersion = 3, eraSourceIDs = { 20, 21 }, eraManifestSignature = "20,21",
}
assert(P.RestoreAppearanceGenerationCache(rebuiltUnknown), "matching negative era cache was not restored")
assert(rebuiltUnknown.eraEvidenceState == "UNKNOWN" and rebuiltUnknown.eraEvidenceUnknown == true,
    "negative era result did not survive cache rebuild")

local prechecked = {
    sourceID = 30, visualID = 70, metadataRevision = 2,
    eraManifestVersion = 3, eraSourceIDs = { 30 }, eraManifestSignature = "30",
    generationPrecheckKey = "precheck-key", generationPrecheckEligible = false,
    generationPrecheckKind = "promotional", generationPrecheckReason = "Promo excluded.",
}
P.CaptureAppearanceGenerationCaches({ bySlot = { BACK = { prechecked } } })
local rebuiltPrechecked = {
    sourceID = 30, visualID = 70, metadataRevision = 1,
    eraManifestVersion = 3, eraSourceIDs = { 30 }, eraManifestSignature = "30",
}
assert(P.RestoreAppearanceGenerationCache(rebuiltPrechecked), "pre-era-only cache was not restored")
assert(rebuiltPrechecked.generationPrecheckKind == "promotional", "pre-era cache did not survive rebuild")

print("PASS generation cache carryover: positive, negative, and pre-era results survive matching scans; changed manifests fail closed")
