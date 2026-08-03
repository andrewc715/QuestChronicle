# v1.9.0.4 Novelty Scoring and Parity Report

The Phase B beam, candidate pools, pairwise cohesion, mode relevance, hard constraints, quality window, and legal weapon bundle generation are unchanged from v1.9.0.3.

Novelty is applied only after complete legal finalists have been ranked by their original base score.

## Centralized repeat penalties

```text
Chest          -10
Legs            -6
Shoulders       -8
Weapon bundle  -10
Exact repeat   -12 additional
```

## Automated coverage

`test_anchor_novelty_selection.lua` verifies:

- meaningfully new, partial, exact-repeat, and initial classes;
- quality-window protection;
- each calibrated component penalty;
- exact-repeat total of -46;
- locked and hidden anchor exclusion;
- visual rather than source identity;
- initial-generation weighted parity.

`test_anchor_worker_integration.lua` verifies the approved novelty context reaches the live anchor worker and records changed components.

`test_anchor_novelty_benchmark.lua` performs 10,000 four-finalist selections and enforces an average synthetic overhead below 0.5 ms.

## v1.9.0.3 comparison

The following unmodified deterministic harness outputs were byte-for-byte identical between the packaged v1.9.0.3 baseline and v1.9.0.4:

```text
test_anchor_beam_search.lua
test_anchor_mode_identity.lua
test_anchor_pipeline_benchmark.lua
test_generation_selection_parity.lua
test_weapon_pipeline.lua
```

This confirms that novelty does not alter initial-generation beam ranking, mode identity, the synthetic Phase B pipeline, legacy supporting-slot selection, or legal weapon routing when current-skeleton repetition is not involved.
