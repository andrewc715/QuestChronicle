# Quest Chronicle v1.9.0.7 Phase B Parity Report

The exact v1.9.0.5 package was extracted as the comparison baseline. Each deterministic harness below was executed in both trees, and stdout was compared byte for byte.

```text
test_anchor_beam_search.lua          PASS exact output
test_anchor_mode_identity.lua        PASS exact output
test_anchor_pipeline_benchmark.lua   PASS exact output
test_generation_selection_parity.lua PASS exact output
test_weapon_pipeline.lua             PASS exact output
test_anchor_novelty_selection.lua    PASS exact output
```

Verified invariants:

- Anchor candidate preparation is unchanged.
- Beam expansion and ranking are unchanged.
- Zone Native, Traveler, Class Fantasy, and Chronicle Echo retain their Phase B identities.
- Generate Outfit novelty classification and penalties are unchanged.
- Legacy armor-selection fallback behavior is unchanged.
- Blizzard-safe weapon route enumeration and chosen bundles are unchanged.

Phase C begins only after the selected Phase B skeleton and weapon bundle are committed to the generation draft.
