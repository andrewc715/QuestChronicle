# Quest Chronicle v1.9.0.3 Validation Report

Date: 2026-08-02

Build: `1.9.0.3`

## Scope

v1.9.0.3 adds the Phase B Diagnostics Workbench around the v1.9.0.2 Anchor Skeleton generator. It records bounded immutable reports for Generate Outfit, Reroll Unlocked, Reroll Slot, fallback, cancellation, and failure outcomes. The release intentionally does not calibrate candidate pools, beam ranking, score weights, weapon expansion, supporting-slot selection, or weighted randomness.

## Runtime changes validated

- A top-level Debug tab is registered in the main Quest Chronicle window.
- `/qc debug` opens the main window directly to Debug.
- Diagnostic format 1 persists under `QuestChronicleDB.debug`.
- History retains at most ten reports, caps individual reports at 20 KB, caps approximate combined history at 200 KB, and prunes oldest entries first.
- Malformed or incompatible diagnostic reports are discarded without touching other addon data.
- Completed reports deep-copy supported primitive data rather than retaining mutable generation tables.
- Reports capture character and context, final outfit, anchor skeleton, beam counters, score components, pair cohesion, phase telemetry, cache lifecycle, warnings, and previous-run comparison.
- Reroll Slot preserves the original return values and records a slot-specific report without inheriting an old beam.
- The Debug UI displays report history and a scrollable selected report.
- Raw-ID and verbose toggles alter presentation only.
- Copy Report generates plain text on demand and preselects it for `Ctrl+C`.
- Clear History removes only the diagnostic store.
- The compact Outfits performance tooltip points to Debug for the full ledger.
- New report callbacks refresh Debug only while it is visible and never switch the active tab.

## Compatibility invariants

```text
SavedVariables schema:   2
Courier format:          1
Wardrobe cache format:   7
Generation-cache store:  2
Diagnostic format:       1
Runtime Lua line limit:  below 500 physical lines
```

No database reset is required.

## Lua syntax validation

All 93 Lua files in the packaged project parsed successfully with `texluac -p`.

## Lua regression harnesses

All 30 Lua harnesses passed:

```text
test_anchor_beam_search.lua
test_anchor_mode_identity.lua
test_anchor_pipeline_benchmark.lua
test_anchor_worker_integration.lua
test_cache_pipeline_benchmark.lua
test_cooperative_era_evidence.lua
test_cooperative_generation.lua
test_diagnostics_history.lua
test_diagnostics_snapshot.lua
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

New diagnostics results:

```text
History: newest ten retained, malformed data discarded, isolated clear preserved database
Snapshot: 5,940-byte immutable report, beam/scoring/performance captured, Reroll Slot wrapper preserved
```

## Static verification

All 13 static verification tools passed:

```text
verify_adaptive_generation_worker.py
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

Key static results:

```text
63 runtime Lua modules appear exactly once in the TOC.
Every TOC path exists.
Every Lua file remains below 500 physical lines.
Largest Lua file: 499 lines, Core/ZoneStyle/SourceMetadata.lua.
VERSION.txt, TOC metadata, and runtime fallback agree on 1.9.0.3.
Runtime version display reads authoritative TOC metadata.
No runtime Lua calls C_TransmogCollection.UpdateUsableAppearances().
Diagnostic modules do not call generation-selection or preview-mutation functions.
```

## JSON validation

The one packaged JSON file parsed successfully with Python's JSON parser.

## Selection parity against v1.9.0.2

The same deterministic harnesses were run from the extracted v1.9.0.2 baseline and the v1.9.0.3 candidate. Their output matched exactly:

```text
test_anchor_beam_search.lua
test_anchor_mode_identity.lua
test_anchor_pipeline_benchmark.lua
test_anchor_worker_integration.lua
test_generation_selection_parity.lua
test_weapon_pipeline.lua
```

Matched benchmark and selection results:

```text
Anchor winner:            score 131.4, cohesion 0.950
Anchor benchmark:         112 candidates, 2,096 expansions, 80 weapon yields
Synthetic worker timing:  18 frames, 2.85 ms maximum step
Worker integration:       rank 1/1, score 222.8
Legacy selection:         Chest 105, Legs 204
Weapon route results:     unchanged
```

Verdict: deterministic v1.9.0.2 selection parity passed.

## Automated acceptance matrix

| Requirement | Result |
|---|---|
| Top-level Debug tab and `/qc debug` wiring | PASS |
| Bounded ten-report persistent history | PASS |
| Malformed report soft failure | PASS |
| Immutable deep-copied snapshot | PASS |
| Generate and Reroll Unlocked completion capture | PASS |
| Reroll Slot return-value preservation and capture | PASS |
| Anchor, beam, score, performance, and cache formatting | PASS |
| Raw-ID and verbose presentation paths | PASS |
| Copy-report generation | PASS |
| Clear-history isolation | PASS |
| No Debug callback focus theft | PASS |
| Complete TOC and version consistency | PASS |
| v1.9.0.2 deterministic selection parity | PASS |
| Retail frame and visual behavior | AWAITING LIVE TEST |
| In-game scrolling, copy dialog, and persistence | AWAITING LIVE TEST |

## Known live-test focus

- Confirm the two-column tab fits the actual Retail frame and remains readable at supported window sizes.
- Confirm one report is produced per user action and no action produces duplicates.
- Confirm report history survives `/reload` and ordinary logout.
- Confirm the copy dialog accepts `Ctrl+C` and closes cleanly.
- Confirm diagnostic snapshot capture does not become a measurable new slow phase.
- Confirm the known v1.9.0.2 Anchor weapon-expansion overrun is reported but not changed.
- Confirm repeated Chest/Shoulder foundations produce an observational warning without altering rerolls.

## Clean-package validation

The finished addon folder was zipped with `QuestChronicle` as the archive root, tested with `unzip -t`, extracted into an empty directory, and validated again from that extraction.

Clean extraction results:

```text
ZIP integrity:             PASS
VERSION.txt:               1.9.0.3
Lua syntax:                93 files PASS
Lua regression harnesses:  30 PASS
Static verification tools: 13 PASS
TOC runtime modules:        63
Largest Lua file:           499 lines
```

## Automated verdict

```text
Diagnostics architecture:       PASS
History bounds and persistence: PASS in harness
Snapshot immutability:          PASS
Report formatting:              PASS
Selection parity:               PASS
Compatibility contracts:       PASS
Retail UI validation:           REQUIRED
```

v1.9.0.3 is automated-validated and ready for Retail testing. It is not yet live-validated.
