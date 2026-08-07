local QC = QuestChronicle
local D = QC.Diagnostics
local P = D._Private

local function Integer(value) return tostring(math.floor(tonumber(value) or 0)) end

function P.AddEraSchedulingPerformanceLines(lines, performance, phaseLabels)
    local era = performance and performance.eraScheduling
    if not era then return end
    lines[#lines + 1] = string.format(
        "Era evidence scheduling: %s operations • %s siblings • %s fresh-slice deferrals • %s fragment hits",
        Integer(era.operations), Integer(era.siblingCompletions), Integer(era.freshSliceDeferrals), Integer(era.fragmentCacheHits)
    )
    lines[#lines + 1] = string.format(
        "Era execution boundary: %s • %s deferred returns • %s same-slice retries • %s synchronous guard trips",
        tostring(era.executionMode or "Not recorded"), Integer(era.deferredReturns),
        Integer(era.sameSliceDeferredRetries), Integer(era.synchronousProgressGuardTrips)
    )
    lines[#lines + 1] = string.format(
        "Era evidence completions: %s fragment builds • %s pending • %s aggregate finalizations",
        Integer(era.fragmentCacheBuilds), Integer(era.pendingCandidateCompletions), Integer(era.aggregateFinalizations)
    )
    lines[#lines + 1] = string.format(
        "Era API work: %s set lists • %s set entries • %s tracking • %s encounter lists • %s encounter entries • %s item metadata",
        Integer(era.setListCalls), Integer(era.setEntryCalls), Integer(era.trackingCalls), Integer(era.encounterListCalls),
        Integer(era.encounterEntryOperations), Integer(era.itemMetadataCalls)
    )
    local key, ms = era.largestSubphase, tonumber(era.largestSubphaseMs) or 0
    if key then lines[#lines + 1] = string.format("Largest era subphase: %s %.2f ms", phaseLabels and phaseLabels[key] or key, ms) end
end
