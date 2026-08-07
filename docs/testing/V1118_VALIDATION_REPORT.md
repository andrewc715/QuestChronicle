# Quest Chronicle v1.11.8 Validation Report

## Status

```text
Build status: Package-ready
Automated validation: PASS
Retail validation: PENDING
Zone anchor-policy closure: PENDING RETAIL TIMING
```

## Implemented repair

v1.11.8 decomposes the remaining monolithic per-visual-sibling era-evidence call without changing evidence semantics.

Candidate work advances through:

```text
BUILD
CURATED
SET_LIST
SET_ENTRY
TRACKING
ENCOUNTER_LIST
ENCOUNTER_DROP
ENCOUNTER_TIER
ENCOUNTER_RESOLVE
EARLY_DECISION
ITEM_METADATA
FINALIZE
DONE
```

Each cooperative step advances one bounded operation. The outer `CreateSourceEraEvidenceWork` / `StepSourceEraEvidenceWork` pair still owns visual-sibling aggregation, earliest-era selection, pending state, sorted pending item IDs, and aggregate cache persistence.

## Fresh-slice operations

Variable Blizzard API stages are admitted only from a fresh slice:

```text
SET_LIST
TRACKING
ENCOUNTER_LIST
ITEM_METADATA
```

A fresh operation requires zero recorded operations, no force-yield state, and at most 0.25 ms of prior elapsed time.

## Session fragment cache

The new fragment cache is in-memory only and keyed by source ID, item ID, and source type. It stores only complete non-pending candidate tuples, including stable no-evidence results.

It never stores item-pending or tracking-pending results. Item-data, source identity, tracking origin, and manifest changes invalidate conservatively. Persistent aggregate cache keys and versions are unchanged.

## Frozen semantics

No changes were made to evidence ranks, curated corrections, era text rules, set/tracking/encounter/item evidence meaning, later-era conflict behavior, earliest-era aggregation, retry windows, Zone scoring, support scoring, random consumption, weapon routes, Phase D, locks, hidden slots, or data formats.

## Diagnostics

Performance reports now retain era operation count, visual siblings completed, fresh-slice deferrals, stable-fragment hits/builds, pending completions, detailed stage counts, and the largest era subphase. Format-4 Zone export remains additive and adaptive report persistence remains authoritative.
