# Quest Chronicle v1.11.11 Scoring-Pothole Closure

## Scope

v1.11.11 preserves the productive v1.11.10 era scheduler and removes the two remaining indivisible scoring islands observed in Retail:

- `anchorCandidateScoring` at 10.2 ms on the cold action;
- `supportCandidateBridge` at 7.8 ms on one warm reroll.

No scoring coefficient, support budget, random-consumption rule, beam width, weapon route, era policy, scheduler constant, cache schema, diagnostic format, or Zone export format changes in this release.

## Anchor candidate execution contract

Zone anchor candidates now advance through prepared, resumable stages. Variable item metadata, set membership, and tracking provenance are admitted before use. Coherence, legacy scoring, descriptor construction, Zone affinity, policy application, and preference finalization consume the prepared inputs instead of rediscovering them.

The frozen `Core/ZoneStyle/Scoring.lua` remains byte-identical to v1.11.10.

Accepted candidates consume exactly one pool-priority random draw after descriptor construction and before tracking/Zone affinity. Rejected incoherent candidates consume no draw.

Weapon finalist scoring uses the same cooperative candidate worker and then advances one armor-to-weapon relationship at a time.

## Support bridge execution contract

Support bridge scoring reuses descriptors already owned by the support profile or beam node. A fallback descriptor resolution occurs only when a legitimate target exists without a prepared descriptor.

Bridge work is split into:

- target resolution;
- descriptor resolution;
- candidate-to-target pair scoring;
- candidate-side finalization;
- baseline target-pair scoring;
- bridge finalization.

Partial bridge work cannot mutate the beam, budget, selected support state, expansion count, or candidate index.

## Frozen v1.11.10 boundaries

The following files are byte-identical to v1.11.10 and are hash-guarded by the v1.11.11 verifier:

- `Core/ZoneStyle/Scoring.lua`
- `Core/ZoneStyle/EraExecution.lua`
- `Core/ZoneStyle/EraCandidateWork.lua`
- `Core/Workers/SliceBudget.lua`

## Synthetic performance gates

The packaged source must demonstrate:

- largest pure synthetic anchor candidate subphase below 4.0 ms;
- largest synthetic variable anchor API subphase below 8.0 ms;
- simulated warm anchor slice below 8.0 ms;
- simulated warm anchor slice debt at or below 2.0 ms;
- zero post-expensive continuations;
- 768 support candidates across 24 nodes × 32 candidates with largest bridge microphase below 4.0 ms;
- zero prepared-descriptor fallbacks in the normal support bridge fixture;
- exact legacy-oracle parity for anchor score/reasons, weapon aggregation, support candidate decisions, fallback tie behavior, and floating-point accumulation order.
