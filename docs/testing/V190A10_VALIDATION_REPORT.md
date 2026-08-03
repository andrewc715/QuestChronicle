# Quest Chronicle v1.9.0a10 Validation Report

Date: 2026-08-02

Build: `1.9.0a10`

## Scope

v1.9.0a10 repairs the pending-item dependency lifecycle exposed by the v1.9.0a9 Retail diagnostics. v1.9.0a9 preserved the live-validated v1.9.0a8 persistent cache, but each generation still reopened roughly 814 to 848 pending records and invalidated roughly 1,628 to 1,696 downstream records. The new pipeline tracks exact missing-item dependencies, compares the normalized era result after those dependencies resolve, and invalidates downstream eligibility only when the generation-relevant outcome actually changes.

The release does not change armor weighting, random selection order, zone preferences, era restrictions, weapon permissions, linked-hand behavior, atomic commit behavior, or Traveler generation behavior.

## Runtime changes validated

- Persistent evidence uses explicit `RESOLVED`, `PENDING_ITEMS`, `TRACKING_ONLY`, `STALE`, and `UNKNOWN` states.
- Exact missing item IDs are stored per pending visual.
- A reverse dependency index maps each item ID to only the affected evidence records.
- Partial dependency completion leaves unresolved records pending and indexed.
- Item-complete but tracking-pending evidence becomes `TRACKING_ONLY` without eligibility invalidation.
- Fully satisfied dependencies enter one cooperative evidence reevaluation.
- Normalized outcome fingerprints ignore presentation-only metadata.
- Unchanged outcomes update evidence in place and preserve prechecks and final eligibility.
- Changed outcomes invalidate only dependent final eligibility contexts.
- Duplicate item callbacks coalesce before dependency evaluation.
- Failed or incomplete dependencies remain bounded and fail closed.
- The generation-cache store migrates from internal version 1 to version 2 without a cache purge.
- Generation telemetry reports dependency, outcome, and downstream-invalidation counts.
- Slow cooperative weapon resumes identify their exact phase when they exceed the guard threshold.

## Compatibility invariants

```text
SavedVariables schema:     2
Courier format:            1
Wardrobe cache format:     7
Generation-cache store:    version 2, in-place migration from version 1
Runtime Lua line limit:    500 physical lines
```

No user data reset is required.

## Lua regression harnesses

All 24 Lua harnesses passed:

```text
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

## Static and packaging guards

All 11 Python verification tools passed:

```text
verify_adaptive_generation_worker.py
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

Additional results:

- All 77 runtime and test Lua files passed `loadfile` syntax validation.
- All 53 runtime Lua modules appear exactly once in the TOC and every path exists.
- No runtime Lua file exceeds 500 physical lines.
- The largest runtime Lua file is exactly 500 lines: `Core/ZoneStyle/SourceMetadata.lua`.
- No runtime call to `C_TransmogCollection.UpdateUsableAppearances()` exists.
- TOC metadata, `VERSION.txt`, and the runtime fallback agree on `1.9.0a10`.
- Runtime version display reads authoritative TOC metadata.
- The Courier configuration JSON parses successfully.

## Pending-dependency churn benchmark

The benchmark models 850 pairs of Blizzard item callbacks for records that complete their item dependency but remain pending on content tracking:

```text
1,700 callbacks received
850 duplicate callbacks coalesced
850 exact dependencies examined
850 dependencies satisfied
850 outcomes retained as tracking-only
0 evidence reevaluations
0 downstream invalidations
```

This directly covers the v1.9.0a9 Retail pattern where approximately 800 pending records reopened and roughly twice that number of cache records were invalidated during each generation.

## Outcome-comparison regression

The focused outcome test verifies both branches:

```text
Unchanged normalized evidence:
- persistent evidence updated in place
- precheck retained
- final eligibility retained
- zero downstream invalidation

Changed normalized evidence:
- evidence replaced
- precheck retained
- only dependent final eligibility invalidated
```

## Existing performance harnesses

### Warm cache pipeline

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

### Simulated post-reload persistent pipeline

```text
3,256 persistent candidates
25 worker frames
2.80 ms maximum synthetic step
0 era-sibling reevaluations
```

## Behavioral parity

- Weighted armor selection parity passed.
- Synchronous weapon-route logic and cooperative weapon resumption produced identical results.
- Positive, negative, pending, tracking-only, and pre-era cache behavior passed.
- Persistent evidence and eligibility survived reconstructed source tables and session-local metadata resets.
- Version 1 generation-cache records migrated in place to version 2.
- Changed manifests, source identity, zone context, and player level still invalidate safely.
- Traveler calibration remains unchanged and instrumentation-only.
- Atomic private-draft generation remains intact.

## Validation status

Automated validation: **PASS**

Retail validation: **PENDING**

v1.9.0a8 remains the last fully live-validated baseline. The decisive Retail test is Generate Outfit, two Reroll Unlocked operations, `/reload`, and one final Generate Outfit while capturing the complete dependency and outcome diagnostics.
