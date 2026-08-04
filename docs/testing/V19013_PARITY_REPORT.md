# Quest Chronicle v1.9.0.13 Behavior-Parity Report

v1.9.0.13 is intentionally limited to weapon-index invalidation lifecycle diagnostics.

## Runtime boundaries

No Phase B or Phase C selection, scoring, weapon-route resolution, support, scheduler, worker-budget, cache-store, or commit module changed. Runtime edits are limited to:

- version fallback metadata;
- weapon-index lifecycle reason and sequence tracking;
- explicit reason forwarding at collection, scan, and character-capability entrypoints;
- action-local cold, partial, repair, warm, and idle classification;
- one diagnostic warning for a genuine final `UNKNOWN` result.

## Harness comparison

The 56 Lua harnesses shared by the untouched v1.9.0.12 release tree and the rebuilt v1.9.0.13 tree were executed from their respective roots.

```text
55 outputs matched byte for byte
1 benchmark differed only in measured elapsed time
0 shared harnesses showed a semantic output difference
```

The sole textual difference was the wall-clock measurement in the 10,000-iteration anchor novelty benchmark:

```text
v1.9.0.12: 0.0251 ms average
v1.9.0.13: 0.0254 ms average
```

The benchmark performed the same 10,000 four-finalist selections. No selected identity, score, route, frame count, cache count, or scheduler result changed.

Two additional v1.9.0.13 harnesses cover the new lifecycle and warning behavior.

## Preserved behavior

v1.9.0.13 does not alter:

- candidate arrays or their ordering;
- anchor or support shortlist construction;
- scoring weights, mismatch budgets, or novelty windows;
- weapon family, subtype, hand, or topology routes;
- worker slice budgets, adaptive batch sizes, or phase transitions;
- preview state, locks, hidden slots, or atomic commit behavior;
- SavedVariables, Courier, wardrobe cache, generation cache, diagnostic, or weapon-index formats.
