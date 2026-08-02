# Quest Chronicle v1.9.0a6 — Adaptive Outfit Generation

v1.9.0a6 repairs the live performance problems measured in v1.9.0a5. The cooperative generator no longer stops after only 30 appearance candidates when the current frame still has time available, and uncached visual-sibling era evidence is now resolved incrementally instead of as one indivisible candidate operation.

## Performance changes

- Replaces the fixed 30-candidate batch with a time-first worker that continues inexpensive cached work until the 2.5 ms addon budget is consumed.
- Retains a 2,000-operation emergency ceiling solely as a runaway guard.
- Resolves uncached era evidence one visual sibling at a time so a large appearance family can yield between Blizzard metadata queries.
- Performs promotional, Heritage Armor, and zone-exclusion checks before beginning expensive era work.
- Reuses normalized source-metadata text while the source remains unchanged.
- Reuses already-computed coherence values during weighting instead of evaluating the same candidate relationship twice.
- Preserves the private draft, cancellation signature, separate weapon frame, and atomic final commit.

## Phase-aware diagnostics

The persistent performance line now reports:

```text
Prepared in <n> frames • <seconds> sec • worst <ms> ms • slowest <phase> <ms> ms
```

Measured phases include setup, source validation, era evidence, eligibility, outfit coherence, candidate scoring, slot setup/finalization, progress callbacks, weapon routing, state commit, preview application, final UI refresh, and the completion callback.

Hover the performance line to see candidate counts, era-source checks, selected armor slots, and per-phase maximum, total, and call-count measurements.

## Preserved behavior

- Weighted candidate formulas, random-selection order, locks, hidden slots, rerolls, weapon routes, and outfit naming remain unchanged.
- Traveler cohesion remains calibrated instrumentation only and does not affect candidate selection.
- Cooperative wardrobe scanning, live metadata, concepts, Custom Sets, and Courier behavior remain unchanged.
- SavedVariables schema remains 2, Courier format remains 1, and wardrobe cache format remains 7.
- No wardrobe rescan or data migration is required.
