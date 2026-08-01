# Quest Chronicle v0.5.1 Wardrobe Collection Hotfix Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Back up the account-level `SavedVariables\QuestChronicle.lua` file.
3. Replace the existing `QuestChronicle` addon folder with v0.5.1.
4. Log in and run `/qc`.

The v0.5.0 wardrobe cache is intentionally invalidated. Chronicle history and other saved data are preserved.

## Collection scan

1. Close Blizzard's Transmogrify window and Collections Wardrobe if either is open.
2. Open Quest Chronicle and select **Outfits**.
3. Click **Scan Collection**.
4. Confirm the progress line reports each slot as `compatible of collected`.
5. Confirm Chest, Head, Shoulders, and other common slots contain substantially more than the v0.5.0 counts.
6. Confirm Chest contains chest appearances, Shirt contains shirts, Tabard contains tabards, Back contains cloaks, and Shoulders contains shoulders.

If Blizzard's Transmogrify or Wardrobe frame is open, the scan should refuse to start and ask you to close it.

## Compare with Blizzard

1. After Quest Chronicle finishes scanning, open Blizzard's Transmogrify window.
2. Select the same slot in both interfaces.
3. Compare Quest Chronicle's diagnostic collected count with Blizzard's collection.
4. Quest Chronicle may cache fewer entries than Blizzard reports because it excludes hidden visuals, sources the current character cannot display, sources with unmet player conditions, and duplicate sources sharing the same visual.
5. It should no longer return inventory-sized counts such as two Chest appearances when Blizzard shows pages of collected Chest appearances.

## Preview

1. Select several appearances from different armor slots.
2. Confirm each appears on the embedded model.
3. Confirm changing pages does not clear earlier selections.
4. Test a weapon and an off-hand appearance.
5. Confirm **Clear Slot** and **Clear Selections** still work.

## Filter restoration

1. Before scanning, set a distinctive source filter or search in Blizzard's Wardrobe, then close it.
2. Run the Quest Chronicle scan.
3. Reopen Blizzard's Wardrobe.
4. Confirm the prior source filters and search text were restored.

Report the Quest Chronicle slot name, `compatible of collected` counts, and any Lua error if a slot remains unexpectedly small.
