local normalizeCalls = 0
local itemCalls = 0
local loaded = false

QuestChronicle = {
    Wardrobe = {},
    ZoneStyle = {
        _Private = {},
        MODE_ZONE_NATIVE = "ZONE",
        MODE_TRAVELER = "TRAVELER",
        MODE_CLASS_FANTASY = "CLASS",
        MODE_CHRONICLE_ECHO = "ECHO",
    },
}
local P = QuestChronicle.ZoneStyle._Private
function P.Normalize(value)
    normalizeCalls = normalizeCalls + 1
    return string.lower(tostring(value or ""))
end
function P.SafeCall(callback, ...) return callback(...) end
function P.TextMatchesAny() return false end
P.styleFamilies = {}
P.dramaticFamilies = {}
P.chronicleThemes = {}

C_Item = {
    GetItemInfo = function(itemID)
        itemCalls = itemCalls + 1
        if not loaded then return nil end
        return "Loaded Name", "item:" .. tostring(itemID), 2, 10, 1, "Armor", "Plate", 1, "INVTYPE_CHEST", 123, 0, 4, 4, 1, 2
    end,
    RequestLoadItemDataByID = function() end,
}

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/ZoneStyle/SourceMetadata.lua")

local verified = {
    itemID = 10,
    itemMetadataVerified = true,
    itemMetadataItemID = 10,
    expansionID = 1,
    name = "Verified",
    styleName = "Verified Chest",
    styleItemType = "Armor",
    styleItemSubType = "Plate",
}
local first = P.SourceMetadata(verified)
local callsAfterFirst = normalizeCalls
local second = P.SourceMetadata(verified)
assert(first == second, "cached metadata text changed without source changes")
assert(normalizeCalls == callsAfterFirst, "verified metadata text was rebuilt instead of cached")
assert(itemCalls == 0, "verified metadata unexpectedly queried C_Item")

verified.styleName = "Changed Chest"
local changed = P.SourceMetadata(verified)
assert(changed ~= first and changed:find("changed chest", 1, true), "metadata cache did not invalidate after source mutation")

local pending = { itemID = 20, name = "Appearance 20" }
local pendingText = P.SourceMetadata(pending)
assert(itemCalls == 1 and pendingText:find("appearance 20", 1, true), "initial pending metadata lookup failed")
loaded = true
local loadedText = P.SourceMetadata(pending)
assert(itemCalls == 2, "pending metadata cache blocked a later item-data retry")
assert(loadedText:find("loaded name", 1, true), "loaded metadata did not replace the placeholder")

print("PASS generation metadata cache: verified text reused and pending item data retried")
