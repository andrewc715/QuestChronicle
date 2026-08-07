QuestChronicle = { ZoneStyle = { _Private = {}, expansions = {} } }
local Z = QuestChronicle.ZoneStyle
local P = Z._Private
for i = 0, 11 do Z.expansions[i] = { label = "Expansion " .. i, shortLabel = "E" .. i } end
Z.expansions[1] = { label = "The Burning Crusade", shortLabel = "TBC" }
Z.expansions[3] = { label = "Cataclysm", shortLabel = "Cata" }
Z.expansions[4] = { label = "Mists of Pandaria", shortLabel = "MoP" }

function P.Normalize(value) return string.lower(tostring(value or "")) end
function P.TextMatchesAny(text, values)
    text = P.Normalize(text)
    for _, value in ipairs(values or {}) do
        value = P.Normalize(value)
        if value ~= "" and string.find(text, value, 1, true) then return true end
    end
    return false
end
function P.SafeCall(callback, ...) return callback(...) end
function P.GetCuratedSourceOrigin(candidate) return candidate and candidate.curatedOrigin or nil end
function P.GetAppearanceTrackingType() return 1 end
P.trackedOriginCache = {}

local scenario = {}
C_TransmogSets = {
    GetSetsContainingSourceID = function() return scenario.setIDs or {} end,
    GetSetInfo = function(setID) return scenario.setInfo and scenario.setInfo[setID] or nil end,
}
C_ContentTracking = { GetBestMapForTrackable = function() return 1, nil end }
Enum = { ContentTrackingResult = { Failure = 2 }, ContentTrackingType = { Appearance = 1 } }
function P.GetTrackedSourceOrigin(candidate)
    if scenario.trackingOrigin then P.trackedOriginCache[candidate.sourceID] = scenario.trackingOrigin return scenario.trackingOrigin end
    if scenario.trackingPending then P.trackedOriginCache[candidate.sourceID] = nil return nil end
    P.trackedOriginCache[candidate.sourceID] = false
    return nil
end
C_TransmogCollection = {
    GetAppearanceSourceDrops = function() return scenario.drops or {} end,
    GetSourceInfo = function(sourceID) return { sourceID = sourceID, itemID = scenario.itemID or 9001, sourceType = 1, name = "Test" } end,
    GetSourceItemID = function() return scenario.itemID or 9001 end,
}
C_Item = {
    GetItemInfo = function(itemID)
        if scenario.itemPending then return nil end
        if scenario.itemExpansion == nil then return nil end
        return "Item", "link", 2, 1, 1, "Armor", "Plate", 1, "INVTYPE_CHEST", 1, 0, 4, 4, 1, scenario.itemExpansion
    end,
    RequestLoadItemDataByID = function(itemID) scenario.requestedItem = itemID end,
}

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile(base .. "Core/ZoneStyle/EraEvidence.lua")
dofile(base .. "Core/ZoneStyle/EraCandidateWork.lua")

local function tuple(candidate, cooperative)
    P.trackedOriginCache = {}
    scenario.requestedItem = nil
    if cooperative then
        local work = P.CreateEraCandidateResolutionWork(nil, candidate.sourceID, { candidate = candidate, skipFragmentCache = true })
        local guard = 0
        while not work.done and guard < 100 do P.StepEraCandidateResolutionWork(work) guard = guard + 1 end
        assert(work.done, "cooperative candidate did not finish")
        return work.resultEvidence, work.candidatePending, work.pendingItemID, work.trackingPending
    end
    return P.ResolveEraCandidateReference(candidate)
end

local function assertEvidenceEqual(a, b, label)
    if a == nil or b == nil then assert(a == b, label .. ": evidence nil mismatch") return end
    for _, key in ipairs({ "expansionID", "method", "label", "sourceID", "itemID", "rank" }) do
        assert(a[key] == b[key], string.format("%s: %s mismatch (%s vs %s)", label, key, tostring(a[key]), tostring(b[key])))
    end
end

local function run(label, config, candidate)
    scenario = config
    candidate = candidate or { sourceID = 10, itemID = config.itemID or 9001, sourceType = 1, name = "Test" }
    if config.curatedItem then P.curatedEraItemIDs[candidate.itemID] = config.curatedItem else P.curatedEraItemIDs[candidate.itemID] = nil end
    local a, ap, ai, at = tuple(candidate, false)
    local b, bp, bi, bt = tuple(candidate, true)
    assertEvidenceEqual(a, b, label)
    assert(ap == bp, label .. ": pending mismatch")
    assert(ai == bi, label .. ": pending item mismatch")
    assert(at == bt, label .. ": tracking pending mismatch")
end

run("no evidence", {})
run("curated correction", { curatedItem = 4, itemExpansion = 1 })
run("set evidence", { setIDs = { 1 }, setInfo = { [1] = { expansionID = 3, name = "Set A" } }, itemExpansion = 1 })
run("conflicting set evidence", { setIDs = { 1, 2 }, setInfo = { [1] = { expansionID = 1, name = "Old" }, [2] = { expansionID = 4, name = "Late" } }, itemExpansion = 1 })
run("tracking evidence", { trackingOrigin = { expansionID = 3, label = "Tracked" }, itemExpansion = 1 })
run("tracking pending", { trackingPending = true, itemExpansion = 1 })
run("encounter evidence", { drops = { { instance = "TBC raid", encounter = "Boss", tiers = { "TBC" } } }, itemExpansion = 4 })
run("multiple drops and tiers", { drops = { { instance = "Unknown", encounter = "Boss", tiers = { "Cata", "MoP" } }, { instance = "TBC", encounter = "Other", tiers = {} } }, itemExpansion = 1 })
run("item evidence", { itemExpansion = 3 })
run("item pending", { itemPending = true })
run("encounter early return", { drops = { { instance = "TBC", tiers = {} } }, itemPending = true })
run("tracking pending suppresses item", { trackingPending = true, itemExpansion = 4 })

print("PASS v1.11.8 era candidate state-machine parity across evidence and pending cases")
