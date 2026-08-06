local ui = { outfits = {}, zoneStyle = {} }
local notifications, prints = {}, {}
QuestChronicle = {
    ZoneStyle = {},
    GetUIState = function() return ui end,
    GetSettings = function() return { restrictOutfitsToZoneEra = true } end,
    GetCurrentCharacter = function() return { raceName = "Human" } end,
    Notify = function(event) notifications[#notifications + 1] = event end,
    Print = function(text) prints[#prints + 1] = text end,
}
time = function() return 100 end
local root = debug.getinfo(1, "S").source:sub(2):gsub("tools/test_zone_suggestion_parity_v1110.lua$", "")
local function Load(path) assert(loadfile(root .. path))() end
for _, path in ipairs({
    "Core/ZoneStyle/Profiles.lua", "Core/ZoneStyle/Context.lua",
    "Core/ZoneStyle/Zone/Foundation.lua", "Core/ZoneStyle/Zone/EvidenceLedger.lua", "Core/ZoneStyle/Zone/CanonicalStyles.lua",
    "Core/ZoneStyle/Zone/ProfileRegistry.lua", "Core/ZoneStyle/Zone/ProvenanceRegistry.lua", "Core/ZoneStyle/Zone/StartingZoneRegistry.lua",
    "Core/ZoneStyle/Zone/ContextResolver.lua", "Core/ZoneStyle/Zone/Compatibility.lua",
}) do Load(path) end
local Z, Zone = QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle.Zone
local current = { mapID = 109, mapName = "Netherstorm", zone = "Netherstorm", subzone = "", mapTrail = { "Outland" } }
Z.DetectContext = function() return Zone.Copy(current) end

local context, changed = Z.RefreshZone(false, true)
assert(changed and context.profileKey == "outland", "initial zone did not create a suggestion")
local suggestion = assert(Z.GetPendingSuggestion(), "initial suggestion missing")
assert(suggestion.unread == true and suggestion.provenanceKey == "netherstorm", "suggestion fields changed")
local suggestionCount = 0
for _, event in ipairs(notifications) do if event == "ZONE_STYLE_SUGGESTION" then suggestionCount = suggestionCount + 1 end end
assert(suggestionCount == 1, "initial suggestion count mismatch")

Z.RefreshZone(false, true)
suggestionCount = 0
for _, event in ipairs(notifications) do if event == "ZONE_STYLE_SUGGESTION" then suggestionCount = suggestionCount + 1 end end
assert(suggestionCount == 1, "same detail key created a duplicate suggestion")

current.subzone = "Manaforge B'naar"
local _, subzoneChanged = Z.RefreshZone(false, true)
assert(subzoneChanged == false, "subzone-only change was treated as a zone change")
suggestionCount = 0
local contextChanged = 0
for _, event in ipairs(notifications) do
    if event == "ZONE_STYLE_SUGGESTION" then suggestionCount = suggestionCount + 1 end
    if event == "ZONE_STYLE_CONTEXT_CHANGED" then contextChanged = contextChanged + 1 end
end
assert(suggestionCount == 1 and contextChanged == 1, "subzone suggestion lifecycle changed")

Z.AcknowledgeSuggestion()
assert(Z.GetPendingSuggestion() and Z.GetPendingSuggestion().unread == false, "acknowledge removed the ready suggestion")
local consumed = Z.ConsumeSuggestion()
assert(consumed and Z.GetPendingSuggestion() == nil, "consume did not clear the suggestion")

-- Simulate reload: the compatibility context persisted, but the session-only
-- snapshot did not. Rebuilding must not create a duplicate suggestion.
Zone.currentSnapshot = nil
local beforeSuggestions = 0
for _, event in ipairs(notifications) do if event == "ZONE_STYLE_SUGGESTION" then beforeSuggestions = beforeSuggestions + 1 end end
Z.GetCurrentContext()
local afterSuggestions = 0
for _, event in ipairs(notifications) do if event == "ZONE_STYLE_SUGGESTION" then afterSuggestions = afterSuggestions + 1 end end
assert(afterSuggestions == beforeSuggestions, "session snapshot rebuild created a duplicate suggestion")
assert(Z.GetZoneContextSnapshot().identity.profileKey == "outland", "snapshot did not rebuild after reload")

current = { mapID = 110, mapName = "Nagrand", zone = "Nagrand", subzone = "", mapTrail = { "Outland" } }
local _, newZone = Z.RefreshZone(false, true)
assert(newZone == true and Z.GetPendingSuggestion() ~= nil, "real zone change did not create a suggestion")
print("PASS v1.11.0 Zone suggestion lifecycle: no duplicates, subzone parity, acknowledge/consume, and reload rebuild")
