# Quest Chronicle v1.11.5 Parity Report

## Baseline

```text
Baseline: Quest Chronicle v1.11.4
Target:   Quest Chronicle v1.11.5
```

## Intentional differences

```text
VERSION_ONLY
- package metadata and fallback version are 1.11.5

EXPORT_LINEAGE
- Zone export format advances from 3 to 4
- latest Zone report and latest policy-bearing report are selected independently
- malformed policy payloads are skipped

COOPERATIVE_SCHEDULING
- weapon eligibility is stepped with markerBatch = 4
- weapon capabilities use one action snapshot with explicit invalidation
- timing and capability diagnostics are decomposed into bounded subphases
```

## Frozen selection contract

Exact parity is required for an identical state and random stream:

- source eligibility decisions;
- retained weapon candidate sequence;
- coherence decisions;
- random-call count and order;
- `stylePriority` values;
- final sorted weapon order;
- legal route selection and linked-hand behavior;
- Zone candidate and pair adjustments;
- selected anchor skeleton;
- contextual support, novelty, repeat penalties, validation, and repair;
- locks, hidden slots, exclusions, and atomic commit.

Automated weapon-ordering fixtures compare retained IDs, exact priorities, random consumption, and sorted output.

## Runtime boundary

```text
133 inherited runtime modules byte-identical
13 inherited runtime modules changed
2 runtime modules added
0 runtime modules removed
```

The changed modules are limited to version metadata, weapon-work routing, capability invalidation and commit validation, cooperative ordering, performance snapshots/formatting, and Zone export lineage.

## Classification

```text
Traveler selection parity:           UNCHANGED
Zone policy coefficients:            UNCHANGED
Zone anchor selection semantics:     UNCHANGED
Weapon eligibility semantics:        UNCHANGED
Weapon random and ordering semantics:UNCHANGED
Weapon scheduling:                   INTENTIONAL CHANGE
Zone export lineage:                 INTENTIONAL FIX
Zone support and repair:             UNCHANGED
Saved data and cache formats:        UNCHANGED
Retail performance thresholds:       PENDING
```
