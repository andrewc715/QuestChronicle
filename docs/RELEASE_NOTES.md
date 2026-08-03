# Quest Chronicle v1.9.0.3 - Phase B Diagnostics Workbench

v1.9.0.3 turns the growing Phase B telemetry into a dedicated in-game workbench. The anchor generator itself remains the v1.9.0.2 implementation. This release records what happened, why the skeleton won, where time was spent, and what the cache did without changing any selection result.

## Debug tab

A new top-level **Debug** tab uses a two-column layout:

- **Generation History** lists the ten newest attempts with time, action, mode, result, duration, and skeleton rank.
- **Selected Report** shows the complete immutable snapshot for the chosen attempt.

The tab opens through the main window or:

```text
/qc debug
```

A new report never pulls the player away from the Outfits tab. Opening Debug selects the newest report.

## Immutable generation snapshots

Quest Chronicle records one bounded snapshot for:

```text
Generate Outfit
Reroll Unlocked
Reroll Slot
Completed generation
Legacy fallback
Cancellation
Failure
```

Snapshots copy only stable primitive data after the generation pipeline settles. They do not retain beam nodes, coroutine workers, candidate arrays, or live wardrobe tables.

## Complete diagnostic report

Each report can include:

- version, character, action, mode, context, result, outfit name, and timing;
- Chest, Legs, Shoulders, and physical weapon appearances;
- locks, hidden anchors, chosen rank, score, cohesion, and hard clashes;
- strongest and weakest anchor relationships;
- candidate pools, expansions, retained beam nodes, legal weapon bundles, pair-cache activity, shortlist, and fallback;
- recorded anchor score components and mean pair-cohesion dimensions;
- every performance phase with maximum, total, and call count;
- persistent cache, item dependency, evidence outcome, and invalidation metrics;
- warnings for performance overruns, fallback, and repeated Chest/Shoulder foundations;
- a lightweight comparison with the previous completed report.

The compact Outfits tooltip now carries only headline timing and skeleton information, then points to the Debug tab for the full ledger.

## History and persistence

Diagnostic format 1 is stored under:

```text
QuestChronicleDB.debug
```

The store is deliberately bounded:

```text
Maximum reports:          10
Maximum report size:      20 KB
Maximum history size:     approximately 200 KB
Pruning order:            oldest first
```

History survives `/reload` and ordinary logout. **Clear History** removes only diagnostic reports. Chronicle events, wardrobe caches, concepts, selections, preferences, Custom Set links, and Courier data are untouched.

## Copy Report

**Copy Report** opens a multiline read-only report box with all text selected. Press `Ctrl+C` to copy it for a development report. **Show raw IDs** adds visual, source, item, and category identifiers. **Verbose diagnostics** includes otherwise hidden zero-count fields.

## Selection parity

v1.9.0.3 does not calibrate the Phase B beam. Seeded and deterministic harnesses produce the same anchor ranking, mode identity, worker result, selection parity, weapon result, and synthetic benchmark output as v1.9.0.2.

The repeated Rugged Plate Vest and Expedition Defender's Shoulders, plus the observed Anchor weapon-expansion overrun, remain evidence for the planned v1.9.0.4 calibration release rather than changes hidden inside this patch.

## Compatibility

```text
SavedVariables schema:   2
Courier format:          1
Wardrobe cache format:   7
Diagnostic format:       1
Generation-cache store:  2
```

No reset is required. Quest Chronicle still applies no transmog and spends no gold.
