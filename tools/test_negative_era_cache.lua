local now = 1000
function time() return now end

QuestChronicle = {
    Wardrobe = { _Private = {} },
    ZoneStyle = { _Private = {}, expansions = {} },
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
dofile(base .. "Core/ZoneStyle/EraEvidence.lua")

local calls = 0
function P.BuildEraCandidate(source, sourceID)
    return { sourceID = sourceID, visualID = source.visualID }
end
function P.ResolveEraCandidate()
    calls = calls + 1
    return nil, false
end

local source = {
    sourceID = 1,
    visualID = 88,
    metadataRevision = 4,
    eraManifestVersion = P.ERA_MANIFEST_VERSION,
    eraManifestSignature = "1,2,3",
    eraSourceIDs = { 1, 2, 3 },
}
local work = ZoneStyle.CreateSourceEraEvidenceWork(source)
local done, result = ZoneStyle.StepSourceEraEvidenceWork(work, 10)
assert(done and result.unknown == true and calls == 3, "unknown evidence did not finish")
local cached = ZoneStyle.CreateSourceEraEvidenceWork(source)
assert(cached.done and cached.cached and cached.result.unknown, "unknown result was not cached")
assert(calls == 3, "unknown cache repeated sibling checks")

source.metadataRevision = 5
local invalidated = ZoneStyle.CreateSourceEraEvidenceWork(source)
assert(not invalidated.done, "metadata revision did not invalidate unknown evidence")

local pendingCalls = 0
function P.ResolveEraCandidate()
    pendingCalls = pendingCalls + 1
    return nil, true
end
local pendingSource = {
    sourceID = 10,
    visualID = 99,
    metadataRevision = 1,
    eraManifestVersion = P.ERA_MANIFEST_VERSION,
    eraManifestSignature = "10,11",
    eraSourceIDs = { 10, 11 },
}
local pendingWork = ZoneStyle.CreateSourceEraEvidenceWork(pendingSource)
local pendingDone, pendingResult = ZoneStyle.StepSourceEraEvidenceWork(pendingWork, 10)
assert(pendingDone and pendingResult.pending and pendingCalls == 2, "pending result did not finish")
local pendingCached = ZoneStyle.CreateSourceEraEvidenceWork(pendingSource)
assert(pendingCached.done and pendingCached.cached and pendingCached.result.pending, "pending result was not cached")
now = now + 601
local retry = ZoneStyle.CreateSourceEraEvidenceWork(pendingSource)
assert(not retry.done, "expired pending evidence did not reopen")

print("PASS negative era cache: unknown results reuse immediately, pending results retry after the bounded dependency window")
