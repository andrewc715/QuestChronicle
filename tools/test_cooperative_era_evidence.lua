QuestChronicle = {
    ZoneStyle = {
        _Private = {},
        expansions = {},
    },
}

local ZoneStyle = QuestChronicle.ZoneStyle
local P = ZoneStyle._Private

function P.Normalize(value) return string.lower(tostring(value or "")) end
function P.TextMatchesAny() return false end
function P.SafeCall(callback, ...) return callback(...) end
function P.GetCuratedSourceOrigin() return nil end
function P.GetTrackedSourceOrigin() return nil end
function P.GetAppearanceTrackingType() return nil end
P.trackedOriginCache = {}

local root = (... and (...):match("^(.*)[/\\]") or "")
local base = root ~= "" and root .. "/../" or ""
dofile("Core/ZoneStyle/EraExecution.lua")
dofile(base .. "Core/ZoneStyle/EraEvidence.lua")

local calls = 0
function P.BuildEraCandidate(source, sourceID)
    return { sourceID = sourceID, itemID = sourceID + 1000, visualID = source.visualID }
end
function P.ResolveEraCandidate(candidate)
    calls = calls + 1
    local expansionID = candidate.sourceID == 4 and 1 or 3
    return {
        expansionID = expansionID,
        method = "item",
        label = "test",
        sourceID = candidate.sourceID,
        itemID = candidate.itemID,
        rank = 40,
    }, false
end

local source = {
    sourceID = 1,
    visualID = 77,
    eraManifestVersion = P.ERA_MANIFEST_VERSION,
    eraSourceIDs = { 1, 2, 3, 4, 5 },
    eraItemIDs = { 1001, 1002, 1003, 1004, 1005 },
}

local work = ZoneStyle.CreateSourceEraEvidenceWork(source)
assert(work.done == false, "uncached evidence should create cooperative work")
for expected = 1, 4 do
    local done, result, processed = ZoneStyle.StepSourceEraEvidenceWork(work, 1)
    assert(done == false, "era work finished before all siblings were processed")
    assert(result == nil, "incomplete era work returned a result")
    assert(processed == 1 and calls == expected, "era worker exceeded its per-step sibling limit")
end

local done, result, processed = ZoneStyle.StepSourceEraEvidenceWork(work, 1)
assert(done == true and processed == 1 and calls == 5, "era worker did not finish on the fifth sibling")
assert(result.expansionID == 1 and result.sourceID == 4, "earliest-era evidence was not selected")
assert(source.eraEvidenceExpansionID == 1, "resolved era evidence was not cached on the source")

local cached = ZoneStyle.CreateSourceEraEvidenceWork(source)
assert(cached.done == true and cached.cached == true, "cached evidence did not bypass sibling enumeration")
assert(calls == 5, "cached evidence unexpectedly repeated source work")

print("PASS cooperative era evidence: 5 sibling sources processed one at a time and cached")
