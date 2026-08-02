# Quest Chronicle v1.9.0a8 Validation Report

Date: 2026-08-02

Build: `1.9.0a8`

## Scope

v1.9.0a8 is a focused persistent-cache lifecycle repair built from the corrected v1.9.0a7 package. It addresses the Retail result where era and eligibility caches warmed during one session but returned almost completely cold after `/reload` and the automatic wardrobe scan.

The release does not change outfit weighting, random selection order, zone preferences, route permissions, linked-hand behavior, atomic commit behavior, or Traveler generation behavior.

## Runtime changes validated

- A versioned persistent generation-cache substore lives under the existing account-level `QuestChronicleDB.wardrobe` table.
- Era evidence is keyed by stable visual and complete manifest identity rather than runtime source-table identity.
- Pre-era and final eligibility records use stable source and generation-context identities.
- Session-local `metadataRevision` and mutable display names do not participate in persistent identity.
- Resolved, unknown, and pending v1.9.0a7 source evidence migrates before the first collection scan.
- Matching records restore while the scan builds its staging cache.
- Resolved strong evidence survives ordinary item-data completion events.
- Pending and unknown evidence reopen when item data changes, pending retry time arrives, or the unknown-result lifetime expires.
- Changed manifests, source identity, level, zone preference, era, provenance, or relevant generation context invalidate affected records.
- Persistent context maps are age-bounded and least-recently-used bounded.
- Generation telemetry reports loaded, migrated, retained, added, invalidated, and reason-specific cache counts.

## Compatibility invariants

```text
SavedVariables schema:  2
Courier format:         1
Wardrobe cache format:  7
Runtime Lua line limit: 500 physical lines
```

## Lua regression harnesses

All 18 Lua harnesses passed:

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
test_item_data_cache_invalidation.lua
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

All nine Python verification tools passed:

```text
verify_adaptive_generation_worker.py
verify_cache_pipeline_repair.py
verify_generation_performance_status.py
verify_lua_line_limit.py
verify_no_blocking_usability_refresh.py
verify_persistent_generation_cache.py
verify_split_helper_references.py
verify_toc_manifest.py
verify_version_consistency.py
```

Additional results:

- All runtime and test Lua files passed `loadfile` syntax validation.
- All 49 runtime Lua modules appear exactly once in the TOC and every path exists.
- No runtime Lua file exceeds 500 physical lines.
- The largest runtime Lua file is exactly 500 lines: `Core/ZoneStyle/SourceMetadata.lua`.
- No runtime call to `C_TransmogCollection.UpdateUsableAppearances()` exists.
- TOC metadata, `VERSION.txt`, and the runtime fallback agree on `1.9.0a8`.
- Runtime version display reads authoritative TOC metadata.

## Performance harnesses

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

The post-reload harness constructs new source tables and resets session-local metadata revisions before generation. Persistent era and eligibility records still match and are reused.

## Behavioral parity

- Weighted armor selection parity passed.
- Synchronous weapon-route logic and cooperative weapon resumption produced identical results.
- Positive, negative, pending, and pre-era cache behavior passed.
- Strong item-data evidence preservation and pending-evidence reopening passed.
- Changed manifests fail closed.
- Player-level and stable source-identity changes invalidate eligibility.
- Traveler calibration remains unchanged and instrumentation-only.
- Atomic private-draft generation remains intact.

## Validation status

Automated validation: **PASS**

Retail validation: **PENDING**

The decisive Retail test is a warm generation sequence followed by `/reload`, the completed automatic collection scan, and another Generate Outfit. Persistent loaded and retained counts must remain substantial, cache hits must remain warm, and era-source checks must not return to the v1.9.0a7 cold value of 10,658.
