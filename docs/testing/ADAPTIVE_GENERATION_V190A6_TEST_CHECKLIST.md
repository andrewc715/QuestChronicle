# Quest Chronicle v1.9.0a6 Live Test Checklist

## Purpose

Validate the time-first generation scheduler, resumable era evidence, phase-aware telemetry, and unchanged atomic outfit behavior against the large live wardrobe that exposed v1.9.0a5's 204-frame warm-reroll floor.

## Installation

1. Exit WoW or disable Quest Chronicle before replacing files.
2. Replace the complete `QuestChronicle` addon folder with v1.9.0a6.
3. Start Retail WoW and run `/reload` once after login.
4. Open `/qc` and select **Outfits**.
5. Confirm no Lua error appears and the existing wardrobe cache, preview, locks, hidden slots, preferences, and concepts remain intact.

No cache migration or forced rescan is expected. Schema remains 2, Courier format remains 1, and wardrobe cache format remains 7.

## Test A — cold post-reload generation

1. After the automatic wardrobe scan is complete, click **Generate Outfit**.
2. Keep moving the character or camera while generation runs.
3. Confirm the existing outfit remains intact until the replacement appears all at once.
4. Record the complete performance line.
5. Hover the performance line and capture the phase breakdown.

Expected format:

```text
Prepared in <n> frames • <seconds> sec • worst <ms> ms • slowest <phase> <ms> ms
```

Primary comparison against v1.9.0a5:

```text
1,408 frames • about 23 seconds • 331.2 ms worst step
```

The new build should show a major reduction in total latency and should no longer process an entire visual-sibling era family inside one worker operation. Any remaining large spike must identify its phase.

## Test B — warm Reroll Unlocked

1. Without `/reload`, click **Reroll Unlocked**.
2. Confirm locked pieces do not change.
3. Confirm hidden slots remain hidden.
4. Confirm the completed armor and weapon bundle appears atomically.
5. Record the performance line and hover breakdown.
6. Repeat once more without changing the workbench.

Primary comparison against v1.9.0a5:

```text
204 frames • 96.7 ms worst step
204 frames • 56.2 ms worst step
```

The 204-frame floor should be gone. A warm reroll should use materially fewer frames, with no visible long hitch.

## Test C — diagnostics persistence

1. Change the selected appearance slot after generation.
2. Page through appearances.
3. Open and close Current Look.
4. Confirm the timing line remains present.
5. Hover it again and confirm the details remain available.
6. Start another generation and confirm the previous measurement clears immediately.

## Test D — weapon and cancellation safety

1. Generate once with linked weapon hands enabled when the physical layout supports it.
2. Generate once with linked weapon hands disabled.
3. Confirm Main Hand and Off Hand still follow their permitted routes.
4. Start a generation and immediately change a lock, hidden slot, style mode, or weapon filter.
5. Confirm the in-progress job cancels rather than committing a stale partial outfit.

## Report back

Provide screenshots of the final performance line and its hover tooltip for:

- first Generate Outfit after `/reload`;
- first warm Reroll Unlocked;
- second warm Reroll Unlocked;
- any run with a visible hitch or incorrect outfit behavior.
