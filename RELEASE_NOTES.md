# Quest Chronicle v1.9.0.15a2

## Phase E: First Curated Descriptor Corrections

Quest Chronicle now applies the first human-reviewed Traveler descriptor corrections collected through the v1.9.0.15a1 observation batch and standardized appearance renders.

- Adds a versioned exact-identity correction layer in `CuratedOverrides.lua`.
- Corrects six reviewed visual identities without changing any scoring formula or repair threshold.
- Keeps Gray Woolen Shirt neutral and Stylish Black Shirt dark while classifying both as plain cloth finishes.
- Reclassifies Hide of Lupos as dark violet-gray fur with primal and weathered finish evidence.
- Reclassifies Rugged Plate Vest as blue, steel, and dark with a weathered practical finish.
- Reclassifies Expedition Defender's Shoulders as green-dominant steel armor with a military and polished finish.
- Reclassifies Orcish Scout Boots as dark navy, muted blue, and steel with a plain lightly polished finish. They are explicitly not green.
- Adds curated descriptor confidence, cache fingerprinting, compact Debug markers, and audit-export markers.
- Adds an `echoPalette` descriptor channel with behavior-identical defaults; this batch adds no echo-only corrections.
- Preserves the corrected v1.9.0.15a1 support-reroll ledger reconciliation.
- Preserves all Phase B and Phase C scoring, all Phase D gates and repair limits, weapon routes, lock and hidden behavior, scheduler budgets, SavedVariables schemas, and Courier format.

This alpha requires focused Retail validation of all six descriptors and a ten-action Traveler batch before promotion toward the v1.9.0.15 release candidate.

Follow `docs/testing/V19015A2_LIVE_VALIDATION_STEPS.md` for the streamlined validation sequence.
