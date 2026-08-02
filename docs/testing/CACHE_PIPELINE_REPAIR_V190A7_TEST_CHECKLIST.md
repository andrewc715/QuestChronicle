# Quest Chronicle v1.9.0a7 Live Test Checklist

## Purpose

Validate the cache-and-pipeline repair against the v1.9.0a6 Retail measurements:

```text
Cold Generate Outfit: 2348 frames, 34.0 sec, 333.7 ms worst step
Warm reroll:            204 frames,  3.1 sec,  51.5 ms worst step
Warm reroll:            205 frames,  3.1 sec,  53.8 ms worst step
```

v1.9.0a7 should remove repeated fail-closed era work, split weapon routing across bounded worker steps, and avoid the final full Outfits refresh.

## Install and baseline

1. Exit WoW or return to the character-selection screen.
2. Replace the installed `QuestChronicle` folder with the v1.9.0a7 folder.
3. Log in and confirm `/qc status` reports `1.9.0a7`.
4. Allow the automatic wardrobe scan to finish before generating an outfit.
5. Confirm the existing Chronicle history, active quests, preferences, concepts, selections, locks, and hidden slots remain present.

Expected:

- No SavedVariables migration warning.
- Schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 7.
- The automatic wardrobe scan remains responsive.

## Test A: first generation after upgrading from v1.9.0a6

1. Open `/qc` and select the same generation mode and weapon settings used for the v1.9.0a6 test.
2. Click **Generate Outfit** once.
3. Record the performance line.
4. Hover over the line and capture the complete performance tooltip.

Check:

- The old preview remains visible while generation is running.
- The completed armor and weapon result appears atomically.
- `Weapon-pipeline yields` is greater than zero when weapon routing has work to perform.
- Weapon routing no longer appears as one 50 to 334 ms synchronous step.
- The result summary and performance line remain visible after completion.
- No Lua error occurs.

Note: the first v1.9.0a7 generation may still seed negative era results that v1.9.0a6 never stored. Its warm rerolls are the decisive cache test.

## Test B: warm cache rerolls

1. Without changing the workbench, click **Reroll Unlocked**.
2. Capture the timing line and tooltip.
3. Click **Reroll Unlocked** a second time.
4. Capture the second timing line and tooltip.

Expected direction:

- Total frames fall dramatically below the v1.9.0a6 floor of 204 to 205 frames.
- Era-source checks fall to zero or a very small number after the cache is seeded.
- Era-cache hits are high.
- Eligibility-cache hits are high.
- Weapon work is distributed across many small yields rather than one large stall.
- Locked, hidden, and manually selected pieces remain preserved.

Record for each run:

```text
Frames:
Elapsed seconds:
Worst Quest Chronicle step:
Slowest phase:
Appearance candidates:
Era-source checks:
Era-cache hits:
Eligibility-cache hits:
Weapon-pipeline yields:
Weapon routing max and total:
UI refresh max and total:
```

## Test C: cache survival through reload and scan

1. Run `/reload` after completing Tests A and B.
2. Allow the automatic wardrobe scan to finish.
3. Click **Generate Outfit** once.
4. Capture the timing line and tooltip.

Expected:

- Resolved, unknown, and unexpired pending era results survive the successful cache rebuild when the visual manifest still matches.
- Era-source checks remain near the warm-cache level instead of returning to the original 11,028 checks.
- Changed manifests or newly loaded metadata still invalidate stale evidence and fail closed.

## Test D: weapon route regression

Repeat generation with the character's available configurations:

1. Linked hands enabled.
2. Linked hands disabled.
3. One-Hand enabled where Blizzard permits it.
4. Two-Hand enabled where Blizzard permits it.
5. Shield or holdable companion enabled where applicable.
6. A locked Main Hand or Off Hand, then **Reroll Unlocked**.

Expected:

- Main Hand and Off Hand remain physically truthful in Current Preview.
- Linked hands still prefer the same visual, then the same subtype, according to the existing route rules.
- Unlinked hands generate independently.
- Locked weapons do not change.
- No weapon family appears when Blizzard's live option matrix rejects it.
- The final weapon bundle commits atomically with the armor result.

## Test E: targeted UI refresh

After generation completes, verify:

- The generated outfit name updates above the model and in Current Look.
- The generated result summary remains visible.
- The separate performance line remains visible and hoverable.
- Slot icons, selected labels, locks, hidden markers, and visible appearance rows match the new preview.
- Generate, reroll, scan, save, clear, lock, hide, favorite, and exclude controls have correct states.
- A consumed Zone Native suggestion loses its `*` marker and `Suggestion ready` text.
- Pagination and the currently browsed slot do not jump.
- The UI-refresh phase is materially lower than the v1.9.0a6 result of roughly 25 ms.

## Test F: cancellation and ordinary workbench behavior

1. Start generation and immediately change a selection, lock, hidden slot, mode, weapon family, subtype, or linked-hands setting.
2. Confirm the in-progress draft is cancelled rather than overwriting the newer state.
3. Browse appearances, change pages, open Current Look, load a concept, and manually scan the collection.

Expected:

- Cancellation remains safe.
- Ordinary full workbench refreshes still update every control.
- Manual browsing remains unrestricted.
- Traveler cohesion remains diagnostic only.
- No transmog is applied and no gold is spent.

## Report back

Provide screenshots of:

1. First Generate Outfit after upgrade.
2. Warm Reroll Unlocked number 1.
3. Warm Reroll Unlocked number 2.
4. First Generate Outfit after the later `/reload` and scan.

Include any Lua error text, visible hitch, missing appearance, incorrect weapon route, stale UI control, or non-atomic preview behavior.
