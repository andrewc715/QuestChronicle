# Quest Chronicle v1.11.6 Adaptive Diagnostic Budget Plan

## Release purpose

Guarantee Debug History persistence for every valid diagnostic action without raising the frozen 20,480-byte per-report ceiling or changing generation behavior.

## Retail trigger

The first v1.11.5 Zone Generate Outfit action completed but printed:

```text
Debug report could not be saved: Diagnostic report remained above the persistence limit after compaction.
```

The visible warning contract worked. The persistence contract did not.

## Architecture

### Exact-size authority

`QuestChronicle._Core.JsonEncode` is the authoritative size measurement whenever available. Approximate recursive counting remains a defensive bootstrap fallback only.

### Deterministic tiers

```text
0 NONE
1 DUPLICATE_FIELDS
2 RECONSTRUCTIBLE_DETAIL
3 SUMMARY_TABLES
4 MANDATORY_CORE
5 EMERGENCY_STUB
6 MINIMAL_STUB
```

Each tier is applied only when the preceding serialized result remains above the limit.

### Mandatory retention contract

Before optional detail is retained, the report must preserve:

- ID, lineage, action, result, mode, character, and final message;
- Zone foundation, snapshot identity, policy identity and authority;
- selected anchors and their legacy, affinity, confidence, adjustment, and final values;
- weapon capability build/reuse, invalidation, eligibility, and stale-commit summary;
- scheduler yields, debt, and post-expensive-call integrity;
- selected skeleton identity and headline scores;
- support budget and final validation outcome;
- Phase D initial/final state and compact repair ledger;
- warnings and fallback state.

### Emergency behavior

A valid report that cannot fit at tier 4 is rebuilt as a bounded emergency payload. If even that cannot fit because the ceiling is artificially impossible, tier 6 retains the smallest valid action stub and the existing visible rejection path remains the final guard.

## Frozen boundaries

No changes are permitted to generation selection, random calls, Zone policy coefficients, weapon ordering, legal routes, contextual support, repair, rerolls, locks, hidden slots, SavedVariables, caches, or Courier output.
