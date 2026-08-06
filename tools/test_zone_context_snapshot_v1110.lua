QuestChronicle = {
    ZoneStyle = {},
    GetUIState = function() return { outfits = {}, zoneStyle = {} } end,
    GetSettings = function() return { restrictOutfitsToZoneEra = true } end,
    GetCurrentCharacter = function() return { raceName = "Human" } end,
}
time = function() return 100 end
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_context_snapshot_v1110.lua$", "")
local function Load(path) assert(loadfile(root .. path))() end
for _, path in ipairs({
    "Core/ZoneStyle/Profiles.lua", "Core/ZoneStyle/Context.lua",
    "Core/ZoneStyle/Zone/Foundation.lua", "Core/ZoneStyle/Zone/EvidenceLedger.lua", "Core/ZoneStyle/Zone/CanonicalStyles.lua",
    "Core/ZoneStyle/Zone/ProfileRegistry.lua", "Core/ZoneStyle/Zone/ProvenanceRegistry.lua", "Core/ZoneStyle/Zone/StartingZoneRegistry.lua",
    "Core/ZoneStyle/Zone/ContextResolver.lua", "Core/ZoneStyle/Zone/Compatibility.lua",
}) do Load(path) end

local Z, Zone = QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle.Zone
local fixtures = {
    { mapID = 109, mapName = "Netherstorm", zone = "Netherstorm", subzone = "", mapTrail = { "Outland" }, profile = "outland", era = 1, provenance = "netherstorm" },
    { mapID = 2215, mapName = "Hallowfall", zone = "Hallowfall", subzone = "Mereldar", mapTrail = { "Khaz Algar" }, profile = "hallowfall", era = 10, provenance = "hallowfall" },
    { mapID = 84, mapName = "Stormwind City", zone = "Stormwind City", subzone = "Trade District", mapTrail = { "Eastern Kingdoms", "Azeroth" }, profile = "human", era = 0, provenance = nil },
    { mapID = 99999, mapName = "Unknown Place", zone = "Unknown Place", subzone = "", mapTrail = {}, profile = "azeroth", era = 0, provenance = nil },
}
for _, facts in ipairs(fixtures) do
    local snapshot = Z.BuildZoneContextSnapshot(facts)
    local context = Zone.BuildLegacyContextView(snapshot)
    assert(snapshot.format == 1 and type(snapshot.fingerprint) == "string", "snapshot identity missing")
    assert(context.profileKey == facts.profile, "profile mismatch for " .. facts.zone)
    assert(context.eraMax == facts.era, "era mismatch for " .. facts.zone)
    assert(context.provenanceKey == facts.provenance, "provenance mismatch for " .. facts.zone)
    local oldProfile, oldKey = Zone.LegacyResolveProfile(facts)
    local oldEra, oldEraLabel, oldEraShort = Zone.LegacyResolveEra(facts)
    local oldProvenance, oldProvenanceKey = Zone.LegacyResolveProvenance(facts)
    assert(oldKey == context.profileKey and oldProfile.label == context.profileLabel, "legacy profile parity failed")
    assert(oldEra == context.eraMax and oldEraLabel == context.eraLabel and oldEraShort == context.eraShortLabel, "legacy era parity failed")
    assert(oldProvenanceKey == context.provenanceKey, "legacy provenance parity failed")
    assert((oldProvenance and oldProvenance.label or facts.zone) == context.provenanceLabel, "legacy provenance label parity failed")
end

for _, profileKey in ipairs(Zone.ProfileRegistry.order) do
    local profile = Zone.ProfileRegistry.byKey[profileKey]
    if profileKey ~= "azeroth" and profile.match[1] then
        local facts = { mapID = profileKey, mapName = profile.match[1], zone = profile.match[1], subzone = "", mapTrail = {} }
        local snapshot = Z.BuildZoneContextSnapshot(facts)
        local _, legacyKey = Zone.LegacyResolveProfile(facts)
        assert(snapshot.identity.profileKey == legacyKey, "all-profile parity failed for " .. profileKey)
    end
end

for _, case in ipairs(Zone.StartingZoneRegistry.list) do
    local override = Zone.ResolveStartingZoneOverride({ zone = case.zone, subzone = case.subzone }, { raceName = case.race })
    assert(override and override.provenanceKey == case.provenanceKey and override.maxExpansionID == case.maxExpansionID, "starting-zone resolution failed: " .. case.caseID)
end

local first = Z.BuildZoneContextSnapshot(fixtures[1])
local firstFingerprint = first.fingerprint
local buildsBeforeReuse = Zone.snapshotBuildCount
first.identity.profileKey = "tampered"
first.location.mapTrail[1] = "tampered"
local second = Z.BuildZoneContextSnapshot(fixtures[1])
assert(second.identity.profileKey == "outland" and second.location.mapTrail[1] == "Outland", "public snapshot mutated cached state")
assert(second.fingerprint == firstFingerprint, "same facts did not produce stable fingerprint")
assert(Zone.snapshotBuildCount == buildsBeforeReuse, "same detail key rebuilt instead of reusing the snapshot")

print("PASS v1.11.0 Zone context snapshots: parity, evidence, deterministic identity, cache isolation, and starting-zone matrix")
