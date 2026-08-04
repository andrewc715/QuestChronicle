local QC = QuestChronicle
QC._Core = QC._Core or {}
QC._Core.Workers = QC._Core.Workers or {}
local W = QC._Core.Workers

W.PREFERRED_SLICE_MS = 5.5
W.SOFT_SLICE_CEILING_MS = 7.5
W.EXPENSIVE_CALL_MS = 2.0
W.PHASE_TRANSITION_RESERVE_MS = 1.0

local function NowMilliseconds()
    if type(debugprofilestop) == "function" then return debugprofilestop() end
    if type(GetTimePreciseSec) == "function" then return GetTimePreciseSec() * 1000 end
    if type(GetTime) == "function" then return GetTime() * 1000 end
    return 0
end

function W.NowMilliseconds() return NowMilliseconds() end

function W.BeginSlice(preferredMs, ceilingMs)
    return {
        startedAtMs = NowMilliseconds(),
        preferredMs = tonumber(preferredMs) or W.PREFERRED_SLICE_MS,
        ceilingMs = tonumber(ceilingMs) or W.SOFT_SLICE_CEILING_MS,
        forceYield = false, lastCallMs = 0, expensiveCalls = 0,
        phaseTransitionYields = 0, preventedTransitions = 0,
        postExpensiveContinuations = 0, operationCount = 0,
    }
end

function W.Elapsed(slice)
    if not slice then return 0 end
    return math.max(0, NowMilliseconds() - (tonumber(slice.startedAtMs) or 0))
end

function W.Remaining(slice)
    if not slice then return 0 end
    return math.max(0, (tonumber(slice.preferredMs) or W.PREFERRED_SLICE_MS) - W.Elapsed(slice))
end

function W.NoteCall(slice, elapsedMs)
    if not slice then return false end
    elapsedMs = math.max(0, tonumber(elapsedMs) or 0)
    slice.lastCallMs = elapsedMs
    slice.operationCount = (slice.operationCount or 0) + 1
    if elapsedMs >= W.EXPENSIVE_CALL_MS then
        slice.forceYield = true
        slice.expensiveCalls = (slice.expensiveCalls or 0) + 1
        slice.sliceDebtMs = math.max(0, W.Elapsed(slice) - (slice.preferredMs or W.PREFERRED_SLICE_MS))
        return true
    end
    return false
end

function W.CanStartPhase(slice, reserveMs)
    if not slice or slice.forceYield then return false end
    reserveMs = math.max(W.PHASE_TRANSITION_RESERVE_MS, tonumber(reserveMs) or 0)
    local canStart = W.Elapsed(slice) + reserveMs < (tonumber(slice.preferredMs) or W.PREFERRED_SLICE_MS)
    if not canStart then
        slice.preventedTransitions = (slice.preventedTransitions or 0) + 1
        slice.phaseTransitionYields = (slice.phaseTransitionYields or 0) + 1
    end
    return canStart
end

function W.ShouldYield(slice, reserveMs)
    if not slice then return false end
    if slice.forceYield then return true end
    reserveMs = math.max(0, tonumber(reserveMs) or 0)
    return W.Elapsed(slice) + reserveMs >= (tonumber(slice.preferredMs) or W.PREFERRED_SLICE_MS)
end

function W.HardExceeded(slice)
    return slice and W.Elapsed(slice) >= (tonumber(slice.ceilingMs) or W.SOFT_SLICE_CEILING_MS) or false
end

function W.ExportSliceDiagnostics(slice)
    return {
        expensiveCalls = slice and slice.expensiveCalls or 0,
        phaseTransitionYields = slice and slice.phaseTransitionYields or 0,
        preventedTransitions = slice and slice.preventedTransitions or 0,
        postExpensiveContinuations = slice and slice.postExpensiveContinuations or 0,
        sliceDebtMs = slice and slice.sliceDebtMs or 0,
    }
end
