local QC = QuestChronicle
QC._Core = QC._Core or {}
QC._Core.Workers = QC._Core.Workers or {}
local W = QC._Core.Workers

W.PREFERRED_SLICE_MS = 5.5
W.SOFT_SLICE_CEILING_MS = 7.5
W.EXPENSIVE_CALL_MS = 2.0

local function NowMilliseconds()
    if type(debugprofilestop) == "function" then return debugprofilestop() end
    if type(GetTimePreciseSec) == "function" then return GetTimePreciseSec() * 1000 end
    if type(GetTime) == "function" then return GetTime() * 1000 end
    return 0
end

function W.NowMilliseconds()
    return NowMilliseconds()
end

function W.BeginSlice(preferredMs, ceilingMs)
    return {
        startedAtMs = NowMilliseconds(),
        preferredMs = tonumber(preferredMs) or W.PREFERRED_SLICE_MS,
        ceilingMs = tonumber(ceilingMs) or W.SOFT_SLICE_CEILING_MS,
        forceYield = false,
        lastCallMs = 0,
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
    if not slice then return end
    elapsedMs = math.max(0, tonumber(elapsedMs) or 0)
    slice.lastCallMs = elapsedMs
    if elapsedMs >= W.EXPENSIVE_CALL_MS then slice.forceYield = true end
end

function W.ShouldYield(slice, reserveMs)
    if not slice then return false end
    if slice.forceYield then return true end
    reserveMs = math.max(0, tonumber(reserveMs) or 0)
    return W.Elapsed(slice) + reserveMs >= (tonumber(slice.preferredMs) or W.PREFERRED_SLICE_MS)
end

function W.HardExceeded(slice)
    if not slice then return false end
    return W.Elapsed(slice) >= (tonumber(slice.ceilingMs) or W.SOFT_SLICE_CEILING_MS)
end
