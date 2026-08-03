# Quest Chronicle v1.9.0.3 Selection Parity Report

Date: 2026-08-02

Baseline: `1.9.0.2`

Candidate: `1.9.0.3`

## Purpose

v1.9.0.3 is a read-only diagnostics release. Candidate preparation, beam ordering, weighted finalist choice, mode relevance, cooperative weapon generation, and the legacy generator must remain behaviorally identical to v1.9.0.2.

## Deterministic comparison

The same harness files were executed from the extracted v1.9.0.2 baseline and the v1.9.0.3 candidate. Standard output matched exactly for every comparison:

```text
test_anchor_beam_search.lua
test_anchor_mode_identity.lua
test_anchor_pipeline_benchmark.lua
test_anchor_worker_integration.lua
test_generation_selection_parity.lua
test_weapon_pipeline.lua
```

Matched results:

```text
Anchor beam winner:       score 131.4, cohesion 0.950, expansions 2/4/8
Mode identity:            Zone, Traveler, Class, and Echo rankings distinct
Anchor benchmark:         112 candidates, 2,096 expansions, 80 weapon yields, 18 frames, 2.85 ms
Worker integration:       rank 1/1, score 222.8, four yields, locks/hidden/fallback preserved
Legacy selection parity:  Chest 105, Legs 204
Weapon pipeline:          synchronous and cooperative route results identical
```

## Code boundary

The only new generation-adjacent data collection occurs after selection or completion:

- selected anchor score reasons are copied into diagnostics after candidates have already been ranked;
- selected pair relationships are read after the winning skeleton has been chosen;
- `GenerationWorker` queues a snapshot after its existing completion call;
- Reroll Slot is wrapped only to preserve the original return values and record elapsed time.

No diagnostic module calls candidate selection, reroll, weapon generation, state commit, or preview mutation functions.

## Verdict

```text
Deterministic v1.9.0.2 parity: PASS
Selection/scoring change intended: No
Retail quality calibration: Deferred to v1.9.0.4
```
