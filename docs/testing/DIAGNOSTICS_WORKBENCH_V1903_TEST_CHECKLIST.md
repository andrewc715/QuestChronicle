# Quest Chronicle v1.9.0.3 Live Test Checklist

v1.9.0.3 adds the Phase B Diagnostics Workbench around the unchanged v1.9.0.2 Anchor Skeleton generator. This checklist verifies UI behavior, immutable history, report accuracy, persistence, copy output, and selection/performance non-regression.

## Installation

1. Exit World of Warcraft completely.
2. Replace the complete installed `QuestChronicle` folder with v1.9.0.3.
3. Do **not** delete `QuestChronicleDB` or other SavedVariables.
4. Start Retail and confirm Status & Maintenance reports `Quest Chronicle 1.9.0.3`.
5. Let the automatic wardrobe scan finish.

Expected contracts:

```text
SavedVariables schema: 2
Courier format:        1
Wardrobe cache format: 7
Diagnostic format:     1
```

## Test A: empty Debug tab and navigation

1. Open `/qc` and select **Debug**.
2. If no reports exist, confirm the history column shows a friendly empty-state message.
3. Run `/qc debug`.

Expected:

- Debug appears as a top-level tab.
- `/qc debug` opens the main window directly to Debug.
- Empty history produces no Lua error or broken controls.
- Copy Report and Clear History are disabled until a report exists.

## Test B: first Generate Outfit report

1. Return to Outfits and select Traveler.
2. Use **Generate Outfit**.
3. Confirm the Outfits tooltip remains compact.
4. Open Debug.

Verify the newest report contains:

- action, mode, context, result, outfit name, frames, duration, worst step, and fallback;
- Chest, Legs, Shoulders, Main Hand, and Off Hand matching the preview;
- chosen rank, shortlist size, skeleton score, cohesion, and hard clashes;
- candidate pools, beam expansions, retained entries, weapon bundles, pair-cache hits and misses;
- score breakdown and cohesion dimensions;
- full performance phase table;
- persistent-cache and item-dependency counters;
- warnings and fallback section.

Expected: values match the compact tooltip and `/qc skeleton debug` where those older surfaces overlap.

## Test C: history and focus behavior

1. While viewing Outfits, use **Reroll Unlocked** twice.
2. Confirm Quest Chronicle does not switch to Debug automatically.
3. Open Debug and select each history row.

Expected:

- one new report appears per completed action;
- newest report is selected when Debug opens;
- history rows show time, action, mode, result, duration, and rank;
- selecting an older row changes only the displayed report;
- the selected report remains stable while later generations occur.

## Test D: previous-run comparison

Inspect the second and third completed reports.

Expected:

- changed anchor slots are listed;
- unchanged anchor slots are listed;
- score and cohesion movement matches the two reports;
- three consecutive identical Chest/Shoulder foundations produce a warning only, without changing generation.

## Test E: Reroll Slot

1. Return to Outfits.
2. Use **Reroll Slot** on a supporting armor slot.
3. Open Debug.

Expected:

- action is `Reroll Slot` and identifies the slot;
- timing is recorded;
- the report does not claim that a new beam search occurred;
- the underlying Reroll Slot result remains unchanged from ordinary behavior.

## Test F: locks, hidden anchors, and weapon representation

1. Lock Chest.
2. Hide Shoulders.
3. Generate or reroll with two weapon hands equipped.
4. Inspect the report.

Expected:

- Chest is marked Locked;
- Shoulders are marked Hidden;
- physical Main Hand and Off Hand appearances match the preview;
- no hidden anchor is invented;
- raw IDs can reveal visual, source, item, and category IDs.

## Test G: raw IDs and verbose diagnostics

1. Toggle **Show raw IDs**.
2. Toggle **Verbose diagnostics**.
3. Switch between reports.

Expected:

- presentation updates immediately without creating or mutating reports;
- raw IDs appear only while enabled;
- verbose mode exposes zero-count or lower-level diagnostic fields;
- generation results and history counts remain unchanged.

## Test H: Copy Report

1. Select a detailed report.
2. Press **Copy Report**.
3. Press `Ctrl+C` and paste into a text editor.
4. Repeat with raw IDs enabled.

Expected:

- the multiline report is already selected;
- copied text represents the selected run, not merely the newest run;
- warnings, fallback, phases, cache, and skeleton data are included;
- raw IDs appear only when requested;
- no Chronicle event history, local file path, or SavedVariables dump appears.

## Test I: bounded history

1. Produce at least twelve total generation attempts.
2. Reopen Debug.

Expected:

- only the newest ten reports remain;
- the oldest entries are removed first;
- report switching remains responsive;
- ordinary addon data is unaffected.

## Test J: persistence

1. Note several report timestamps.
2. Use `/reload`.
3. Let the wardrobe scan finish.
4. Open Debug, then generate once more.
5. Log out normally and return if practical.

Expected:

- prior reports survive `/reload` and ordinary logout;
- the new post-reload report is added at the top;
- malformed or incompatible diagnostics never block addon loading;
- persistent generation-cache performance remains warm.

## Test K: Clear History isolation

1. Press **Clear History**.
2. Confirm the empty state.
3. Check Chronicle, Outfits selections, concepts, and Status.

Expected:

- only diagnostic reports disappear;
- Chronicle events, active quests, RP notes, wardrobe cache, selections, locks, hidden slots, concepts, Custom Set links, preferences, and Courier data remain intact.

## Test L: mode coverage

Generate at least one report in:

```text
Zone Native
Traveler
Class Fantasy
Chronicle Echo
```

Expected: each report identifies the correct mode and generation context. The diagnostics patch must not flatten or alter the mode rankings established by v1.9.0.2.

## Test M: fallback, cancellation, and failure

Exercise these naturally if encountered, or through a development harness:

- unavailable locked anchor fallback;
- generation cancelled by a workbench change;
- controlled generation failure.

Expected:

- result is labeled Fallback, Cancelled, or Failed;
- reason or message is preserved;
- the old preview remains intact when generation does not commit;
- no fictional complete beam is reported.

## Performance acceptance

Compared with the same warmed v1.9.0.2 context:

```text
Generation-duration regression: no more than 5% preferred
Worst-step regression:         no more than 2 ms preferred
Additional generation frames:  0 expected
Debug tab opening:             visually immediate
History switching:             visually immediate
Snapshot capture:              not the slowest generation phase
```

The known Phase B Anchor weapon-expansion overrun may still appear. v1.9.0.3 reports it but intentionally does not calibrate it.

## Acceptance matrix

| ID | Requirement | Live pass criterion |
|---|---|---|
| DBG-UI-001 | Top-level Debug tab | Visible and selectable |
| DBG-UI-002 | `/qc debug` | Opens latest Debug report |
| DBG-UI-003 | No focus theft | Generation leaves user on Outfits |
| DBG-UI-004 | Empty state | Clear, functional, no Lua error |
| DBG-DATA-001 | Immutable snapshot | Old report does not change after hydration or reroll |
| DBG-DATA-002 | Generate captured | Exactly one correctly labeled report |
| DBG-DATA-003 | Reroll Unlocked captured | Exactly one correctly labeled report |
| DBG-DATA-004 | Reroll Slot captured | Slot identified, no fictional beam |
| DBG-DATA-005 | Skeleton accuracy | Physical preview components match report |
| DBG-DATA-006 | Lock/hidden accuracy | States match workbench |
| DBG-BEAM-001 | Beam counters | Match tooltip and skeleton debug where shared |
| DBG-BEAM-002 | Chosen rank and score | Match generated skeleton |
| DBG-BEAM-003 | Score ledger | Contributions reconcile within rounding |
| DBG-PERF-001 | Full phase table | All recorded phases visible |
| DBG-PERF-002 | Warning thresholds | Above 8 ms warning, above 16 ms severe |
| DBG-CACHE-001 | Cache counters | Match generated performance snapshot |
| DBG-HIST-001 | Ten-report cap | Twelve attempts retain newest ten |
| DBG-HIST-002 | Reload persistence | History remains after `/reload` |
| DBG-HIST-003 | Clear isolation | Only Debug history is removed |
| DBG-COPY-001 | Copy selected report | Pasted report matches selected row |
| DBG-COPY-002 | Privacy boundary | No unrelated data or paths included |
| DBG-REG-001 | Selection parity | No visible generator behavior change from v1.9.0.2 |
| DBG-REG-002 | Cache parity | Persistent cache remains warm after reload |
| DBG-REG-003 | Concepts/Custom Sets | Save and restore remain unchanged |
| DBG-REG-004 | Courier | Format 1 output remains unchanged |

## Failure signals

- the Debug tab opens blank despite a completed generation;
- one action creates duplicate reports;
- a historical report changes after another generation;
- opening Debug changes the preview or generator state;
- Reroll Slot claims old anchor-beam statistics;
- history exceeds ten entries or disappears unexpectedly after `/reload`;
- Clear History removes unrelated addon data;
- copied text represents the wrong report;
- Debug work becomes the new slowest generation phase;
- v1.9.0.3 chooses a different seeded skeleton than v1.9.0.2;
- Lua errors, focus theft, broken scrolling, or unusable copy dialog.
