# Quest Chronicle v1.9.0a9 Validation Report

Date: 2026-08-02

Build: `1.9.0a9`

## Scope

v1.9.0a9 is a focused item-data invalidation repair built from the live-validated v1.9.0a8 persistent-cache baseline. Retail testing of v1.9.0a8 confirmed that generation evidence and eligibility records survived `/reload`, but approximately 1,700 ordinary item-data callbacks still invalidated and rebuilt records during each generation.

The release does not change outfit weighting, random selection order, zone preferences, era restrictions, route permissions, linked-hand behavior, atomic commit behavior, or Traveler generation behavior.

## Runtime changes validated

- Era evidence records the exact item IDs that were unavailable when the result became pending.
- Tracking-only pending evidence is distinct from item-data pending evidence.
- Stable, unrelated, failed, and duplicate item-data callbacks do not invalidate reusable evidence.
- A relevant pending record reopens once when its exact missing item becomes available.
- Presentation-only metadata hydration does not count as a generation-identity change.
- Genuine generation-relevant item identity changes invalidate item-derived evidence.
- Stronger set, tracking, encounter, and curated evidence survives unrelated representative-item changes.
- Duplicate item events coalesce within the metadata batch.
- UI metadata notifications occur only when a representative row actually changes.
- Era-independent prechecks survive era-evidence reopening.
- Generation telemetry reports stable events ignored, pending records reopened, identity changes, failed events, and coalesced callbacks.

## Compatibility invariants

```text
SavedVariables schema:  2
Courier format:         1
Wardrobe cache format:  7
Generation-cache store: backward-compatible version 1
Runtime Lua line limit: 500 physical lines
```

No cache reset or SavedVariables migration is required.

## Lua regression harnesses

All 20 Lua harnesses passed:

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
test_item_data_batch_precision.lua
test_item_data_cache_invalidation.lua
test_item_data_invalidation_benchmark.lua
test_negative_era_cache.lua
test_persistent_cache_migration.lua
test_persistent_generation_cache.lua
test_persistent_generation_eligibility.lua
test_post_reload_cache_pipeline.lua
test_traveler_instrumentation.lua
test_wardrobe_login_performance.lua
test_weapon_pipeline.lua
```

## Static and packaging guards

All 10 Python verification tools passed:

```text
verify_adaptive_generation_worker.py
verify_cache_pipeline_repair.py
verify_generation_performance_status.py
verify_item_data_invalidation_precision.py
verify_lua_line_limit.py
verify_no_blocking_usability_refresh.py
verify_persistent_generation_cache.py
verify_split_helper_references.py
verify_toc_manifest.py
verify_version_consistency.py
```

Additional results:

- All runtime and test Lua files passed `loadfile` syntax validation.
- All 50 runtime Lua modules appear exactly once in the TOC and every path exists.
- No runtime Lua file exceeds 500 physical lines.
- The largest runtime Lua file is exactly 500 lines: `Core/ZoneStyle/SourceMetadata.lua`.
- No runtime call to `C_TransmogCollection.UpdateUsableAppearances()` exists.
- TOC metadata, `VERSION.txt`, and the runtime fallback agree on `1.9.0a9`.
- Runtime version display reads authoritative TOC metadata.
- The Courier configuration JSON parses successfully.

## Item-data precision benchmark

The synthetic benchmark modeled the Retail invalidation pattern:

```text
1,700 stable tracking-pending item callbacks
40 genuinely relevant item-pending callbacks
1,700 stable records retained
40 relevant pending records reopened
40 total invalidations
```

Under v1.9.0a8-style broad invalidation, the stable callbacks could repeatedly remove roughly 1,700 records. v1.9.0a9 ignores those stable callbacks and reopens only the 40 records whose exact missing item became available.

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
- Positive, negative, pending, and pre-era cache behavior passed.
- Persistent evidence and eligibility survived reconstructed source tables and session-local metadata resets.
- Changed manifests, source identity, zone context, and player level still invalidate safely.
- Traveler calibration remains unchanged and instrumentation-only.
- Atomic private-draft generation remains intact.

## Validation status

Automated validation: **PASS**

Retail validation: **PENDING**

The decisive Retail signal is the Generation Performance tooltip after Generate Outfit, two Reroll Unlocked operations, and a post-`/reload` Generate Outfit. Stable item-data callbacks may be numerous, but mass `ITEM_DATA_LOADED` invalidations must disappear. Only a small number of `ITEM_DATA_PENDING_RESOLVED` or genuine identity-change invalidations should remain.
