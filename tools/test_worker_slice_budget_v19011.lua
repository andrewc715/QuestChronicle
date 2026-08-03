QuestChronicle = { _Core = {} }
local clock = 0
debugprofilestop = function() return clock end

dofile("Core/Workers/SliceBudget.lua")
dofile("Core/Workers/AdaptiveBatch.lua")
local W = QuestChronicle._Core.Workers

local slice = W.BeginSlice(6.0, 7.5)
clock = 2.0
assert(not W.ShouldYield(slice, 0.5), "fresh slice yielded too early")
clock = 5.7
assert(W.ShouldYield(slice, 0.5), "slice did not reserve phase-transition time")

slice = W.BeginSlice(6.0, 7.5)
clock = 0.9
W.NoteCall(slice, 2.1)
assert(W.ShouldYield(slice), "expensive call did not force an immediate yield")

local fast = {}
for _ = 1, 8 do fast = W.NoteAdaptiveCost(fast, 0.03) end
assert(W.GetAdaptiveBatchSize(fast, 5.0, 100) == 16, "fast cached work did not expand its batch")
local slow = W.NoteAdaptiveCost({}, 2.4)
assert(W.GetAdaptiveBatchSize(slow, 5.0, 100) == 1, "slow work did not shrink to a single operation")

print("PASS v1.9.0.11 worker budget: elapsed guard, phase reserve, expensive-call yield, and adaptive batching")
