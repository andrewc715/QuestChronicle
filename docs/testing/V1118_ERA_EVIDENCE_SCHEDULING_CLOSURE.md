# Quest Chronicle v1.11.8 Cooperative Era-Evidence Scheduling Closure

## Retail defect addressed

The v1.11.7 warm sequence produced one 8.9 ms worker slice. Its largest instrumented call was the broad `eraEvidence` bucket at 8.3 ms, with 3.40 ms maximum slice debt. Support scheduling in the same action peaked at only 1.17 ms.

The outer era worker already limited itself to one visual sibling, but one sibling still synchronously resolved curated, set, tracking, encounter, and item evidence. v1.11.8 moves that inner pipeline behind explicit operation boundaries.

## Execution model

```text
Cheap deterministic stages: ordinary phase admission
SET_LIST:                  fresh-slice admission
TRACKING:                  fresh-slice admission
ENCOUNTER_LIST:            fresh-slice admission
ITEM_METADATA:             fresh-slice admission
Set entries:               one per operation
Encounter drops/tiers:     one per operation
Aggregate finalization:    separate operation
```

The frozen scheduler contract remains 5.5 ms preferred, 7.5 ms soft ceiling, and 2.0 ms expensive-call force-yield.

## Memoization model

Stable complete sibling evidence fragments may be reused during aggregate rebuilds. Pending fragments never enter the cache. Aggregate persistent evidence remains the authority and keeps its existing format and retry windows.

## Closure metrics

```text
era operations
era sibling completions
era fresh-slice deferrals
era fragment-cache hits/builds
era pending candidate completions
era set/tracking/encounter/item operation counts
era aggregate finalizations
largest era subphase
largest era subphase ms
```

## Release gate

The first Zone anchor-policy implementation slice closes only after Retail records:

```text
Cold worker slice < 16 ms
Warm worker slices < 8 ms for all three consecutive rerolls
Warm largest calls < 8 ms
Warm maximum slice debt <= 2 ms
Post-expensive continuations = 0
No performance warnings
No diagnostic rejection
```

The era-specific target is a largest era subphase below 4 ms to retain useful margin beneath the hard gate.
