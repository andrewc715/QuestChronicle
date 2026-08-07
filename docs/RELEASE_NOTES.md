# Quest Chronicle v1.11.8

## Cooperative era-evidence scheduling closure

The v1.11.7 Retail closure batch proved contextual-support scheduling was bounded, but one of three warm rerolls still reached an 8.9 ms worker slice because the monolithic per-sibling `eraEvidence` call consumed 8.3 ms and produced 3.40 ms of slice debt.

### Improved

- Per-sibling era resolution now advances through explicit `BUILD`, `CURATED`, set, tracking, encounter, item, and finalization stages.
- Variable Blizzard API stages require fresh-slice admission before they execute.
- Set records, encounter drops, and encounter tiers are reduced one record per operation.
- The outer era worker still owns visual-sibling aggregation, earliest-era selection, pending semantics, and existing persistent cache writes.
- Stable non-pending sibling fragments can be reused from a session-only cache; item-pending and tracking-pending fragments are never stored.
- Item, source-identity, tracking, and manifest invalidations conservatively clear affected fragments.
- Reports and format-4 Zone exports now identify the largest era subphase and retain operation, sibling, deferral, and fragment-cache counters through adaptive compaction.

### Preserved

- Era evidence version 2, era manifest version 3, evidence ranks, later-era conflict behavior within one sibling, and earliest-era behavior across siblings;
- `ZONE_ANCHOR_POLICY_V1`, Zone Context Snapshot format 1, Zone Affinity format 2, and Zone debug export format 4;
- support and weapon scheduling already validated in v1.11.7;
- adaptive diagnostic persistence and the 20,480-byte ceiling;
- scoring, candidate order, random-call order, legal routes, Phase D, rerolls, locks, hidden slots, SavedVariables, caches, and Courier behavior.
