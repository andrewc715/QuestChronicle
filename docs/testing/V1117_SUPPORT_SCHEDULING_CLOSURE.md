# Quest Chronicle v1.11.7 Cooperative Support Scheduling Closure

## Retail defect addressed

The v1.11.6 warm sequence produced one 9.0 ms worker slice even though its largest support beam call was 7.1 ms. The call began after earlier work had consumed the slice, creating 3.52 ms of debt.

v1.11.7 repairs admission rather than raising budgets:

```text
Support candidate: ordinary bounded operation
Support fallback: one-candidate resumable operation
Support stage finalization: fresh-slice operation
```

Cold support eligibility is also converted from a synchronous marker drain to cached work stepped in batches of four.

## Closure metrics recorded

```text
supportEligibilitySteps
supportEligibilityYields
supportEligibilityCacheCompletions
supportEligibilityComputedCompletions
supportEligibilityMarkerBatch
supportBeamCandidateSteps
supportBeamFallbackSteps
supportBeamFallbackYields
supportBeamStageFinalizations
supportBeamFreshSliceDeferrals
supportBeamStageFinalizeMaxMs
largestSubphase
largestSubphaseMs
```

## Release gate

The slice closes only after Retail records:

```text
Cold worker slice < 16 ms
Warm worker slices < 8 ms for all three consecutive rerolls
Warm largest calls < 8 ms
Warm maximum slice debt <= 2 ms
Post-expensive continuations = 0
No performance warnings
```
