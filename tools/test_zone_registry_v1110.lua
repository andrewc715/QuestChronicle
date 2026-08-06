QuestChronicle = {
    ZoneStyle = {},
    GetUIState = function() return { outfits = {}, zoneStyle = {} } end,
    GetSettings = function() return {} end,
}

local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_registry_v1110.lua$", "")
local function Load(path) assert(loadfile(root .. path))() end
Load("Core/ZoneStyle/Profiles.lua")
Load("Core/ZoneStyle/Context.lua")
Load("Core/ZoneStyle/Zone/Foundation.lua")
Load("Core/ZoneStyle/Zone/EvidenceLedger.lua")
Load("Core/ZoneStyle/Zone/CanonicalStyles.lua")

local Z = QuestChronicle.ZoneStyle
local P = Z._Private
local Zone = Z.Zone
local profileFixtures, provenanceFixtures, startingFixtures = {}, {}, {}
for key, profile in pairs(Z.profiles) do
    profileFixtures[key] = {
        label = profile.label, seed = profile.seed, description = profile.description,
        match = Zone.StableEncode(profile.match), keywords = Zone.StableEncode(profile.keywords), avoid = Zone.StableEncode(profile.avoid),
    }
end
for index, profile in ipairs(Z.provenanceProfiles) do
    provenanceFixtures[index] = {
        key = profile.key, label = profile.label, match = Zone.StableEncode(profile.match), origins = Zone.StableEncode(profile.origins),
        minExpansionID = profile.minExpansionID, maxExpansionID = profile.maxExpansionID,
    }
end
for index, case in ipairs(Z.startingZoneCases) do
    startingFixtures[index] = {
        race = case.race, zone = case.zone, subzone = case.subzone,
        provenanceKey = case.provenanceKey, maxExpansionID = case.maxExpansionID,
    }
end
local originalOrder = Zone.StableEncode(P.profileOrder)

Load("Core/ZoneStyle/Zone/ProfileRegistry.lua")
Load("Core/ZoneStyle/Zone/ProvenanceRegistry.lua")
Load("Core/ZoneStyle/Zone/StartingZoneRegistry.lua")

assert(#Zone.ProfileRegistry.order == 25, "expected 25 Zone profiles")
assert(#Zone.ProvenanceRegistry.list == 134, "expected 134 provenance profiles")
assert(#Zone.StartingZoneRegistry.list == 30, "expected 30 starting-zone cases")
assert(Zone.StableEncode(P.profileOrder) == originalOrder, "profile registration order changed")

for key, expected in pairs(profileFixtures) do
    local actual = assert(Z.profiles[key], "missing profile " .. key)
    assert(actual.label == expected.label and actual.seed == expected.seed and actual.description == expected.description, "profile identity changed: " .. key)
    assert(Zone.StableEncode(actual.match) == expected.match, "profile aliases changed: " .. key)
    assert(Zone.StableEncode(actual.keywords) == expected.keywords, "profile keywords changed: " .. key)
    assert(Zone.StableEncode(actual.avoid) == expected.avoid, "profile avoid values changed: " .. key)
    assert(type(actual.style) == "table" and type(actual.style.palette) == "table", "profile lacks explicit style evidence: " .. key)
end
for index, expected in ipairs(provenanceFixtures) do
    local actual = assert(Z.provenanceProfiles[index], "missing provenance index " .. index)
    assert(actual.key == expected.key and actual.label == expected.label, "provenance identity changed: " .. index)
    assert(Zone.StableEncode(actual.match) == expected.match and Zone.StableEncode(actual.origins) == expected.origins, "provenance vocabulary changed: " .. actual.key)
    assert(actual.minExpansionID == expected.minExpansionID and actual.maxExpansionID == expected.maxExpansionID, "provenance bounds changed: " .. actual.key)
    assert(actual.registrationOrder == index, "provenance order metadata changed")
end
for index, expected in ipairs(startingFixtures) do
    local actual = assert(Z.startingZoneCases[index], "missing starting-zone case " .. index)
    for key, value in pairs(expected) do assert(actual[key] == value, "starting-zone field changed: " .. index .. " " .. key) end
end

local ok = Zone.RegisterZoneProfile("human", { key = "human" })
assert(ok == false, "duplicate profile registration should fail")
ok = Zone.ValidateZoneProfile({ key = "bad", label = "Bad", description = "Bad", seed = 1, match = { "x" }, style = { palette = { red = 2 } } })
assert(ok == false, "invalid style weight should fail")
ok = Zone.ValidateZoneProvenance({ key = "bad", label = "Bad", match = { "x" }, origins = { "x" }, minExpansionID = 5, maxExpansionID = 4 })
assert(ok == false, "reversed provenance bounds should fail")

print("PASS v1.11.0 Zone registries: 25 profiles, 134 provenance pools, 30 starting-zone cases, exact compatibility fields")
