# Quest Chronicle v1.9.0a4 — Cooperative Generation Live Test

## Installation

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.9.0a4.
3. Log in and wait for the automatic wardrobe refresh to complete.
4. Open Quest Chronicle → Outfits.

No wardrobe rescan or SavedVariables migration is required solely for this update.

## Generate Outfit

1. Select Traveler mode.
2. Click **Generate Outfit** repeatedly on a large wardrobe.
3. Confirm the button immediately changes to **Generating...** and WoW remains responsive.
4. Confirm the existing preview stays intact while the draft is being prepared.
5. Confirm the completed outfit appears all at once rather than slot by slot.
6. Confirm the status message reports preparation frames and the longest Quest Chronicle step.

Expected:

```text
Prepared across <n> frames; longest Quest Chronicle step <ms> ms.
```

The longest step should normally remain in the low single-digit millisecond range. The synchronous weapon-route step can be somewhat higher on very large weapon collections; report the displayed value if a visible hitch remains.

## Reroll Unlocked

1. Lock two armor slots.
2. Click **Reroll Unlocked**.
3. Confirm the locked pieces remain unchanged.
4. Confirm the rest of the outfit changes atomically.
5. Confirm the game remains responsive.

## Workbench-change cancellation

1. Start Generate Outfit.
2. Immediately change a lock, hidden state, appearance selection, weapon family, weapon subtype, hand-link setting, or generation mode.
3. Confirm Quest Chronicle cancels the draft rather than overwriting the new choice.

## Scanner interaction

1. Start outfit generation.
2. Attempt to click **Scan Collection**.
3. Confirm the scan button is disabled while generation is active.
4. After generation finishes, start a scan and confirm generation remains disabled during the scan.

## Regression checks

- Run `/qc traveler debug` and confirm calibrated instrumentation is unchanged.
- Generate linked One-Hand and linked Two-Hand Fury outfits.
- Generate unlinked weapon pairs.
- Load and save concepts.
- Save or update a Blizzard Custom Set.
- Confirm no Lua errors occur.
