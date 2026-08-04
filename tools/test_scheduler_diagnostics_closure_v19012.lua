QuestChronicle = { _Core = {} }
local clock = 0
debugprofilestop = function() return clock end

dofile("Core/Workers/SliceBudget.lua")
dofile("Core/Workers/AdaptiveBatch.lua")
local W = QuestChronicle._Core.Workers

local slice = W.BeginSlice(5.5, 7.5)
clock = 2.2
assert(W.NoteCall(slice, 2.2), "expensive call did not request an immediate yield")
assert(W.ShouldYield(slice, 0), "expensive call did not end the slice")
assert(not W.CanStartPhase(slice, 0.25), "phase transition continued after an expensive call")
local diagnostics = W.ExportSliceDiagnostics(slice)
assert(diagnostics.expensiveCalls == 1, "expensive-call yield was not counted")
assert(diagnostics.postExpensiveContinuations == 0, "scheduler recorded a post-expensive continuation")

clock = 10
slice = W.BeginSlice(5.5, 7.5)
clock = 14.8
assert(not W.CanStartPhase(slice, 1.0), "phase reservation allowed an unsafe transition")
diagnostics = W.ExportSliceDiagnostics(slice)
assert(diagnostics.preventedTransitions == 1 and diagnostics.phaseTransitionYields == 1,
    "phase-reservation yield was not diagnosed")

local fast = {}
for _ = 1, 12 do fast = W.NoteAdaptiveCost(fast, 0.02) end
assert(W.GetAdaptiveBatchSize(fast, 5.0, 100) == 32, "cheap cached work did not reach the v1.9.0.12 fast lane")
local slow = W.NoteAdaptiveCost(fast, 2.3)
assert(W.GetAdaptiveBatchSize(slow, 5.0, 100) == 1, "expensive work did not collapse to a single operation")

print("PASS v1.9.0.12 scheduler closure: immediate yields, phase reservations, diagnostics, and fast-lane hysteresis")
