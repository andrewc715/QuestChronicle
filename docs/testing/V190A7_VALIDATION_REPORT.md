# Quest Chronicle v1.9.0a7 Validation Report

## Status

**Automated validation passed. Retail live validation is still required.**

v1.9.0a7 is the cache-and-pipeline repair built from the exact v1.9.0a6 package that produced the live phase telemetry. It does not change outfit weighting, route permissions, linked-hand semantics, atomic commit behavior, or Traveler selection behavior.

## Repair coverage

### Era evidence

- Stores `RESOLVED`, `UNKNOWN`, and `PENDING` outcomes.
- Uses resolver version, visual identity, complete source-manifest signature, and metadata revision guards.
- Keeps unknown results fail-closed until invalidation.
- Retries pending results after 30 seconds if no metadata event invalidates them sooner.
- Carries valid visual-level results through successful wardrobe cache rebuilding.
- Migrates positive v1.9.0a6 evidence that predates explicit state and manifest-signature fields.
- Rejects carryover when the visual source manifest changes.

### Eligibility

- Reuses pre-era and final eligibility results during warm rerolls.
- Keys results to source identity, metadata, player class, race, level, reachable maximum level, zone preference, era ceiling, provenance, restriction setting, generation mode, and era evidence.
- Invalidates naturally when any key input changes.

### Weapons

- Reuses subtype candidate indexes until the wardrobe or capability routes are invalidated.
- Runs the existing weapon generator inside a coroutine during cooperative foreground generation.
- Yields between route enumeration, candidate construction, era and style eligibility, weighted scoring, permission checks, appearance checks, linked validation, and source validation.
- Keeps the synchronous public generator available for compatibility callers and timerless fallback behavior.

### Completion UI

- Applies the model on a later frame.
- Refreshes generation-affected controls on the following frame.
- Avoids rebuilding the weapon capability matrix and unrelated workbench structures after a successful atomic commit.
- Refreshes the consumed Zone Native suggestion state, generated name, manifest, slot icons, visible rows, action controls, result summary, and performance display.

## Automated Lua tests

All Lua harnesses passed under `texlua`:

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
test_negative_era_cache.lua
test_traveler_instrumentation.lua
test_wardrobe_login_performance.lua
test_weapon_pipeline.lua
```

Notable results:

```text
Warm cache-and-pipeline benchmark:
3256 armor candidates + 120 weapon yields
29 worker frames
2.80 ms longest synthetic worker step
0 era sibling checks on cached evidence

Large adaptive scheduler benchmark:
6000 armor candidates + 100 uncached era siblings
34 worker frames
2.80 ms longest synthetic worker step
```

## Static verification

The following guards passed:

```text
Lua syntax validation
Adaptive generation worker wiring
Cache-and-pipeline repair wiring
Generation performance status separation
500-line runtime Lua limit
No runtime C_TransmogCollection.UpdateUsableAppearances calls
No orphaned split-module helper references
TOC manifest completeness and path validity
```

At validation time:

```text
Runtime Lua modules: 47
Largest runtime Lua file: Core/ZoneStyle/SourceMetadata.lua at 500 lines
SavedVariables schema: 2
Courier format: 1
Wardrobe cache format: 7
```

## Compatibility and migration

- No SavedVariables schema migration.
- No Courier format migration.
- No wardrobe cache format migration.
- No destructive rescan requirement.
- Existing concepts, selections, visual identities, locks, hidden slots, preferences, and Custom Set links remain compatible.
- Successful login scans continue using a staging cache and preserve the previous healthy cache on failure.

## Remaining live questions

Automated harnesses cannot reproduce Retail API latency, Blizzard transmog permission timing, real wardrobe size, model dressing cost, or frame scheduling under the game client. Live testing must confirm:

- Warm rerolls no longer sit near 204 frames.
- Era-source checks collapse after the first cache-seeding run and remain low after `/reload`.
- Weapon routing no longer creates a 50 to 334 ms single-frame stall.
- Targeted UI refresh materially reduces the previous roughly 25 ms completion hitch.
- Linked and unlinked weapon behavior remains identical to v1.9.0a6.
- No stale Zone Native suggestion marker or other UI state remains after completion.
