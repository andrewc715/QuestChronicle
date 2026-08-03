# Quest Chronicle v1.9.0.4 Validation Report

Date: 2026-08-02

Build: `1.9.0.4`

## Scope

v1.9.0.4 calibrates the Phase B anchor-skeleton selector so repeated **Generate Outfit** actions prefer a meaningfully new unlocked skeleton without weakening legality, the existing 28-point quality window, mode identity, pairwise cohesion, or weapon-route rules. Reroll Unlocked retains its stronger current-appearance exclusion behavior, and Reroll Slot remains isolated to the requested slot.

The release also repairs three diagnostic issues found during v1.9.0.3 Retail testing: historical score comparisons now use immutable stored values, weapon appearances are labeled by physical Main Hand and Off Hand slots, and the report distinguishes the longest cooperative worker slice from the largest individually instrumented call.

## Runtime changes validated

- Generate Outfit compares complete legal finalists against the currently displayed unlocked anchor skeleton.
- Logical novelty components are Chest, Legs, Shoulders, and the complete weapon bundle.
- Locked, hidden, unavailable, and physically irrelevant anchors are excluded from novelty scoring.
- Stable visual identity is used, so a different collected source for the same visual is not false novelty.
- Finalists remain behind the unchanged best-score-minus-28 quality gate.
- Selection class priority is Meaningfully New, Partial Change, then Exact Repeat.
- Weighted randomness remains active inside the selected novelty class.
- Centralized repeat penalties are Chest -10, Legs -6, Shoulders -8, weapon bundle -10, and an additional -12 for an exact unlocked-skeleton repeat.
- Base skeleton scores are unchanged; repeat penalties affect final selection only.
- Exact repeats remain legal when no stronger novelty class survives the quality gate and the reason is recorded.
- Reroll Unlocked and Reroll Slot retain their v1.9.0.3 behavior.
- Historical reports store immutable base score, repeat penalty, adjusted selection score, cohesion, rank, and shortlist size.
- Debug reports and `/qc skeleton debug` use Main Hand and Off Hand physical labels with weapon subtype as metadata.
- Performance reports distinguish longest worker slice from largest instrumented call.
- Anchor weapon expansion yields immediately after an over-budget operation rather than beginning another bundle in the same worker slice.

## Compatibility invariants

```text
SavedVariables schema:     2
Courier format:            1
Wardrobe cache format:     7
Generation-cache store:    2
Diagnostic format:         1
Runtime Lua line limit:    below 500 physical lines
```

No user data reset is required. Existing v1.9.0.3 diagnostic reports remain readable and identify novelty fields as unavailable for that older report.

## Lua regression harnesses

All 33 Lua harnesses passed:

```text
test_anchor_beam_search.lua
test_anchor_mode_identity.lua
test_anchor_novelty_benchmark.lua
test_anchor_novelty_selection.lua
test_anchor_pipeline_benchmark.lua
test_anchor_worker_integration.lua
test_cache_pipeline_benchmark.lua
test_cooperative_era_evidence.lua
test_cooperative_generation.lua
test_diagnostics_history.lua
test_diagnostics_snapshot.lua
test_diagnostics_v194_consistency.lua
test_generation_cache_carryover.lua
test_generation_eligibility_cache.lua
test_generation_metadata_cache.lua
test_generation_precheck.lua
test_generation_scheduler_benchmark.lua
test_generation_selection_parity.lua
test_generation_store_v2_migration.lua
test_item_data_batch_precision.lua
test_item_data_cache_invalidation.lua
test_item_data_invalidation_benchmark.lua
test_negative_era_cache.lua
test_pending_dependency_churn_benchmark.lua
test_pending_dependency_lifecycle.lua
test_pending_dependency_outcome.lua
test_persistent_cache_migration.lua
test_persistent_generation_cache.lua
test_persistent_generation_eligibility.lua
test_post_reload_cache_pipeline.lua
test_traveler_instrumentation.lua
test_wardrobe_login_performance.lua
test_weapon_pipeline.lua
```

## Static and packaging guards

All 14 Python verification tools passed:

```text
verify_adaptive_generation_worker.py
verify_anchor_novelty_pipeline.py
verify_anchor_skeleton_pipeline.py
verify_cache_pipeline_repair.py
verify_diagnostics_workbench.py
verify_generation_performance_status.py
verify_item_data_invalidation_precision.py
verify_lua_line_limit.py
verify_no_blocking_usability_refresh.py
verify_pending_dependency_pipeline.py
verify_persistent_generation_cache.py
verify_split_helper_references.py
verify_toc_manifest.py
verify_version_consistency.py
```

Additional results:

- All 97 runtime and test Lua files passed syntax validation.
- All 64 runtime Lua modules appear exactly once in the TOC and every path exists.
- No runtime Lua file reaches 500 physical lines.
- The largest Lua file is 499 lines: `Core/ZoneStyle/SourceMetadata.lua`.
- No runtime call to `C_TransmogCollection.UpdateUsableAppearances()` exists.
- TOC metadata, `VERSION.txt`, and the runtime fallback agree on `1.9.0.4`.
- Runtime version display reads authoritative TOC metadata.
- The Courier configuration JSON parses successfully.

## Novelty-selection validation

The focused novelty harness covers:

```text
Initial generation with no current skeleton
Meaningfully new candidate defeating an exact repeat inside the quality window
Partial change when no meaningful alternative survives
Exact-repeat fallback when it is the only valid class
Low-quality novelty blocked by the unchanged quality floor
Stable visual identity across alternate source IDs
Locked and hidden anchors excluded from repeat penalties
Logical linked and unlinked weapon-bundle comparison
Exact reconciliation of base score, repeat penalty, and adjusted score
Weighted randomness among candidates in the selected novelty class
```

The novelty benchmark performed 10,000 four-finalist selections at approximately 0.0261 ms per selection in the validation environment, well below the 0.5 ms design ceiling.

## Deterministic v1.9.0.3 parity

The following unchanged deterministic harness outputs were byte-for-byte identical between the v1.9.0.3 baseline and v1.9.0.4:

```text
test_anchor_beam_search.lua
test_anchor_mode_identity.lua
test_anchor_pipeline_benchmark.lua
test_generation_selection_parity.lua
test_weapon_pipeline.lua
```

This verifies unchanged anchor beam ranking, mode identity, worker selection, legacy armor selection, and cooperative weapon routing where current-skeleton novelty is not involved.

## Diagnostic consistency validation

The focused diagnostic harness verifies:

- Previous-run comparisons read immutable stored scores rather than recalculating old skeletons.
- Detailed and compact score rounding derive from the same stored value.
- Base score, repeat penalty, and adjusted score reconcile exactly.
- Main Hand and Off Hand labels are used for dual-wield and Titan's Grip-style routes.
- Weapon subtype is presented separately from physical slot identity.
- Longest worker slice and largest instrumented call are displayed as distinct measurements.
- v1.9.0.3 reports remain readable without fabricated novelty data.

## Existing performance harnesses

### Anchor pipeline

```text
112 prepared anchor candidates
2,096 armor beam expansions
80 cooperative weapon yields
18 synthetic frames
2.85 ms maximum synthetic step
```

### Warm generation cache

```text
3,256 armor candidates
120 cooperative weapon yields
29 worker frames
2.80 ms maximum synthetic step
```

### Simulated post-reload persistent cache

```text
3,256 persistent candidates
25 worker frames
2.80 ms maximum synthetic step
0 era-sibling reevaluations
```

## Behavioral parity

- Hard legality, era restrictions, zone preferences, class eligibility, and collection validation remain authoritative.
- Phase B candidate preparation, beam widths, pairwise cohesion, hard-clash pruning, and final quality window are unchanged.
- Reroll Unlocked retains current unlocked-appearance exclusion.
- Reroll Slot remains isolated to the requested slot.
- Linked and unlinked hands, Titan's Grip, artifacts, shields, holdables, and exact-visual routes remain unchanged.
- Locks and hidden slots remain authoritative.
- Supporting armor remains conditioned on the selected anchor skeleton.
- Persistent evidence and eligibility caches survive reload and scan reconstruction.
- Traveler, Zone, Class, and Echo modes remain distinct.
- Custom Set, Chronicle, and Courier contracts remain unchanged.

## Validation status

Automated validation: **PASS**

Retail validation: **PENDING**

The decisive Retail sequence is three consecutive Generate Outfit actions, one Reroll Unlocked, one Generate with a locked Chest, one Generate with hidden Shoulders, and a `/reload` history check through the Debug tab.
