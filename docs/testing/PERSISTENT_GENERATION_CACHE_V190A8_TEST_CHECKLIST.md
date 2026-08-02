# Quest Chronicle v1.9.0a8 Live Test Checklist

## Purpose

Validate that generation-era evidence and reusable eligibility decisions survive `/reload` and the automatic wardrobe scan. The responsive v1.9.0a7 armor, weapon, and UI pipeline must remain unchanged.

The decisive comparison is the v1.9.0a7 post-reload result:

```text
1,799 frames
32.1 seconds
6.5 ms worst step
10,658 era-source checks
82 era-cache hits
124 eligibility-cache hits
```

## Install

1. Exit World of Warcraft completely.
2. Replace the complete installed `QuestChronicle` folder with v1.9.0a8.
3. Start Retail and log in.
4. Confirm Status & Maintenance reports `Quest Chronicle 1.9.0a8`.
5. Confirm schema 2, Courier format 1, and wardrobe cache format 7.
6. Allow the automatic collection scan to finish before generation testing.

Do not delete `QuestChronicleDB`. v1.9.0a8 is designed to migrate usable v1.9.0a7 era evidence and then populate its dedicated persistent store.

## Test A: first v1.9.0a8 generation

1. Open the Outfits tab.
2. Use the same Traveler, Outland, and Through TBC configuration used for the v1.9.0a7 measurements.
3. Click **Generate Outfit**.
4. Record the timing line.
5. Hover over the timing line and capture the full Generation Performance tooltip.

Expected cache diagnostics:

- `Migrated` may be nonzero on this first upgrade session.
- Persistent evidence, precheck, and eligibility counts should populate.
- `Retained after scan` should be nonzero when compatible v1.9.0a7 evidence existed.
- Worst worker steps should remain near the responsive v1.9.0a7 range rather than returning to the old 50 to 334 ms stalls.

The first a8 generation may still learn records that were never resolved or stored by a7. It is not the decisive persistence result.

## Test B: warm rerolls

1. Click **Reroll Unlocked**.
2. Capture the timing line and tooltip.
3. Click **Reroll Unlocked** a second time.
4. Capture the timing line and tooltip again.

Expected:

- Era-cache hits and eligibility-cache hits rise.
- Era-source checks fall or remain below the first generation.
- Persistent entry totals rise as newly learned records are added.
- Weapon routing remains cooperative, with many weapon yields and no large single-frame weapon stall.
- The preview changes atomically and preserves locks and hidden slots.

## Test C: persistence across `/reload`

1. Use `/reload` after the warm rerolls.
2. Let the automatic collection scan finish.
3. Open the Outfits tab.
4. Click **Generate Outfit** once.
5. Capture the timing line and complete performance tooltip.

This is the release gate.

Expected:

- `Loaded from SavedVariables` reports substantial evidence, precheck, and eligibility counts.
- `Retained after scan` remains substantial rather than collapsing to near zero.
- Era-cache and eligibility-cache hits remain in the warm range.
- Era-source checks do not return to the v1.9.0a7 cold value of 10,658.
- Generation duration remains near the warm-path result rather than returning to 32 seconds.
- Worst step remains in the responsive range.
- Invalidation diagnostics do not show a mass `EVIDENCE_IDENTITY_CHANGED`, `PRECHECK_IDENTITY_CHANGED`, or `ELIGIBILITY_IDENTITY_CHANGED` event.

## Test D: second persistence crossing

1. Perform one additional warm reroll.
2. Use `/reload` again.
3. Let the scan finish.
4. Generate one more outfit and capture the tooltip.

Expected:

- Saved persistent counts remain stable or grow normally.
- Loaded and retained counts continue to agree closely.
- No new cold-cache reset appears.

## Regression checks

Confirm throughout testing:

- No Lua errors.
- No significant login or `/reload` freeze.
- Generation remains cancel-safe and atomic.
- Locked and hidden slots are preserved.
- Main Hand and Off Hand routes remain valid in linked and unlinked modes.
- Generated outfit names and summaries remain visible.
- The separate performance line and tooltip remain visible.
- Traveler diagnostics remain read-only.
- Quest Chronicle applies no transmog and spends no gold.

## Report back

For each of these four operations, provide the timing line and performance tooltip:

1. First Generate Outfit after installing a8.
2. Warm Reroll Unlocked #1.
3. Warm Reroll Unlocked #2.
4. Generate Outfit after `/reload` and completed automatic scan.

The post-reload tooltip is the most important artifact because its loaded, retained, hit, check, and invalidation counts reveal the complete cache lifecycle.
