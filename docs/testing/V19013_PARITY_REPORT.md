# Quest Chronicle v1.9.0.13 Behavior-Parity Report

v1.9.0.13 is intentionally limited to weapon-index invalidation lifecycle diagnostics.

## Runtime boundaries

No Phase B or Phase C selection, scoring, weapon-route, support, scheduler, worker, cache-store, or commit module changed. Runtime edits are limited to:

- version fallback metadata;
- weapon-index lifecycle reason tracking;
- explicit reason assignment at collection, scan, and character-capability entrypoints;
- one diagnostic warning for genuine `UNKNOWN` fallback.

## Harness comparison

The 56 Lua harnesses shared by v1.9.0.12 and v1.9.0.13 were executed from their respective release trees.

```text
54 outputs matched byte for byte
1 novelty benchmark retained the same 10,000 selections and differed only in measured average milliseconds
1 weapon-index diagnostics harness changed intentionally to add partial-build retention and warm `NONE`
```

The changed weapon-index harness preserves the same source filtering and bucket contents while adding these assertions:

```text
COLD_BUILD    -> LOGIN_SESSION_RESET
PARTIAL_BUILD -> LOGIN_SESSION_RESET
WARM_REUSE    -> NONE
REPAIR        -> ELIGIBILITY_OUTCOME_CHANGED
```

Two new focused harnesses verify canonical lifecycle transitions and the `UNKNOWN`-only warning rule.

## Preserved behavior

v1.9.0.13 does not alter:

- candidate arrays or their ordering;
- anchor or support shortlist construction;
- scoring weights, mismatch budgets, or novelty windows;
- weapon family, subtype, hand, or topology routes;
- worker slice budgets, adaptive batch sizes, or phase transitions;
- preview state, locks, hidden slots, or atomic commit behavior;
- SavedVariables, Courier, wardrobe cache, generation cache, diagnostic, or weapon-index formats.
