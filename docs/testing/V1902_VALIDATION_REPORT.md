# Quest Chronicle v1.9.0.2 Validation Report

Date: 2026-08-02

Build: `1.9.0.2`

## Scope

v1.9.0.2 implements Phase B of the Traveler Cohesion Rewrite. Chest, Legs, Shoulders, and the legal weapon bundle are prepared as a cooperative beam-searched anchor skeleton. Supporting armor is then generated against that completed foundation.

The release is built from the live-validated v1.9.0a10 baseline. It does not replace the persistent generation cache, dependency resolver, weapon-route legality engine, targeted completion refresh, concept format, Custom Set format, or atomic draft commit.

## Runtime changes validated

- Bounded candidate pools are prepared for Chest, Legs, and Shoulders.
- Visual-family balancing prevents one family from occupying an entire candidate pool.
- Beam search expands Chest seeds through Legs and Shoulders while retaining at most 32 partial skeletons per stage.
- Phase A Traveler descriptors and pair cohesion participate in active anchor ranking.
- Zone Native, Traveler, Class Fantasy, and Chronicle Echo retain separate source relevance.
- A bounded pairwise cohesion cache avoids repeated visual-pair work.
- The strongest four armor foundations expand through the existing cooperative weapon-route generator.
- Weapon legality remains controlled by physical topology, Blizzard route permissions, subtype filters, locks, artifacts, and linked-hand rules.
- Finalists are constrained to a quality window and selected with weighted variety.
- The previous skeleton receives a repetition penalty.
- Supporting armor is generated after rebuilding the style context around the selected skeleton.
- The private draft remains isolated until the existing atomic commit.
- Locked anchors remain fixed and unavailable locked anchors force the legacy fallback.
- Shoulders can be deliberately hidden and hidden anchors are omitted from the beam.
- Searches with fewer than two active legal components use the preserved legacy generator.
- Generation Performance and `/qc skeleton debug` expose the selected skeleton and beam statistics.

## Compatibility invariants

```text
SavedVariables schema:  2
Courier format:         1
Wardrobe cache format:  7
Generation-cache store: 2
Runtime Lua line limit: 500 physical lines
```

No SavedVariables reset or migration is required.

## Lua regression harnesses

All 28 Lua harnesses passed:

```text
test_anchor_beam_search.lua
test_anchor_mode_identity.lua
test_anchor_pipeline_benchmark.lua
test_anchor_worker_integration.lua
test_cache_pipeline_benchmark.lua
test_cooperative_era_evidence.lua
test_cooperative_generation.lua
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

## Phase B focused regressions

### Beam-search quality

The synthetic quality harness verifies that a coherent Chest, Legs, and Shoulders combination can outrank independently higher-scoring but clashing pieces. It also verifies bounded pair caching, diversity balancing, expansion counts, and quality-window finalist selection.

```text
Best synthetic skeleton score: 131.4
Mean pair cohesion:             0.950
Expansion progression:         2 / 4 / 8
```

### Mode identity

The same candidate structure was scored through all four modes. Zone Native, Traveler, Class Fantasy, and Chronicle Echo retained distinct preferred foundations rather than collapsing into one ranking.

### Worker integration

The cooperative worker test verifies:

- candidate preparation;
- armor beam expansion;
- cooperative weapon expansion;
- atomic private-draft selection;
- supporting-context rebuilding;
- locked Chest preservation;
- single-seeding of locked anchors;
- hidden Shoulder omission;
- unavailable locked-source fallback;
- no-active-anchor fallback without draft mutation.

### Cooperative Phase B benchmark

```text
112 prepared anchor candidates
2,096 armor beam expansions
80 cooperative weapon yields
18 synthetic worker frames
2.85 ms maximum synthetic step
```

This benchmark models the configured 48 Chest, 32 Legs, and 32 Shoulder pools, a 32-wide beam, and four legal weapon expansions. It is a deterministic laboratory result, not a Retail timing promise.

## Existing performance regressions

### Warm persistent pipeline

```text
3,256 armor candidates
120 cooperative weapon yields
29 worker frames
2.80 ms maximum synthetic step
```

### Large adaptive pipeline

```text
6,000 armor candidates
100 uncached era siblings
34 worker frames
2.80 ms maximum synthetic step
```

### Simulated post-reload pipeline

```text
3,256 persistent candidates
25 worker frames
2.80 ms maximum synthetic step
0 era-sibling reevaluations
```

The v1.9.0a10 dependency-churn and outcome-comparison regressions remain green.

## Static verification

All 12 Python guards passed:

```text
verify_adaptive_generation_worker.py
verify_anchor_skeleton_pipeline.py
verify_cache_pipeline_repair.py
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

Additional static results:

- All 84 runtime and test Lua files passed `loadfile` syntax validation.
- All 56 runtime Lua modules appear exactly once in the TOC and every path exists.
- No Lua file exceeds 500 physical lines.
- The largest runtime Lua file is exactly 500 lines: `Core/ZoneStyle/SourceMetadata.lua`.
- `Core/Wardrobe/GenerationWorker.lua` remains below the limit at 499 lines.
- No runtime Lua calls `C_TransmogCollection.UpdateUsableAppearances()`.
- TOC metadata, `VERSION.txt`, and the runtime fallback agree on `1.9.0.2`.
- Runtime version display reads authoritative TOC metadata.
- The Courier configuration JSON parses successfully.

## Packaging validation

- ZIP root is `QuestChronicle/`.
- ZIP integrity test passed.
- Clean extraction reproduced the expected file tree.
- Version, TOC, syntax, line-limit, static, and Lua regression checks passed against the clean extraction.

## Behavioral parity

- Existing independent generation remains available as a fallback.
- Persistent era, precheck, and eligibility cache behavior remains unchanged.
- Pending dependency resolution and narrow invalidation remain unchanged.
- Synchronous weapon-route semantics and cooperative weapon resumption remain equivalent.
- Existing concepts and Custom Set payload construction remain unchanged.
- Manual browsing remains unrestricted.
- Atomic preview commits and cancellation safety remain intact.
- Courier and Chronicle recording behavior remain unchanged.

## Validation status

Automated validation: **PASS**

Retail validation: **PENDING**

Quest Chronicle v1.9.0a10 remains the live-validated baseline until the Phase B visual-quality, mode-identity, lock, hidden-Shoulder, weapon-route, fallback, and performance checklist passes in Retail.
