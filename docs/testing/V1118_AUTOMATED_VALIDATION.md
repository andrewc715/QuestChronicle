# Quest Chronicle v1.11.8 Automated Validation

## Status

```text
Package-ready: PASS
Retail validation: PENDING
```

The v1.11.8 package is required to pass the complete inherited regression wall plus the new cooperative era-evidence fixtures from a fresh extraction of the delivered ZIP.

## Regression wall

```text
Lua regression tests:      107 / 107 PASS
Python static verifiers:    36 / 36 PASS
Runtime Lua syntax:        151 / 151 PASS
TOC runtime modules:       151 / 151 exactly once
Runtime Lua files >= 500:    0
```

## v1.11.8-specific coverage

The new fixtures prove:

- the cooperative candidate state machine returns the exact v1.11.7 evidence tuple for curated, set, tracking, encounter, item, early-return, and pending cases;
- multi-sibling aggregation preserves earliest-era selection, stronger evidence on equal era, pending item IDs, tracking pending, candidate count, and separate aggregate finalization;
- one candidate step performs at most one bounded list, set-entry, tracking, drop-list, drop/tier, or item operation;
- `SET_LIST`, `TRACKING`, `ENCOUNTER_LIST`, and `ITEM_METADATA` defer without callback or state mutation when a fresh slice is unavailable;
- stable resolved and stable no-evidence fragments are memoized, while item-pending and tracking-pending fragments are never stored;
- item and source invalidation clear matching fragments and manifest rebuild clears conservatively;
- adaptive compaction preserves headline era scheduling and largest-subphase diagnostics, including emergency persistence;
- Zone debug export remains format 4 and adds era scheduling without disturbing independent latest-Zone and latest-policy lineage;
- all cooperative generation callers prefer `CreateSourceEraEvidenceWork` / `StepSourceEraEvidenceWork` and retain the synchronous resolver only as a compatibility fallback.

## Frozen contracts checked

```text
Preferred slice:             5.5 ms
Soft slice ceiling:          7.5 ms
Expensive-call threshold:    2.0 ms
Fresh-slice prior elapsed:   <= 0.25 ms
Era evidence version:        2
Era manifest version:        3
Zone debug export format:    4
Diagnostic format:           1
Report ceiling:              20,480 bytes
```

Retail performance remains the acceptance gate.
