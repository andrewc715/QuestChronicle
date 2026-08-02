# Quest Chronicle v1.9.0a9 Live Test Checklist

## Purpose

Validate that the live-validated v1.9.0a8 persistent cache remains intact while stable Blizzard item-data callbacks stop invalidating roughly 1,700 records during every outfit generation.

## Installation

1. Exit World of Warcraft completely.
2. Replace the complete installed `QuestChronicle` folder with v1.9.0a9.
3. Do not delete `QuestChronicleDB` or the wardrobe cache.
4. Start Retail and confirm Status & Maintenance reports `Quest Chronicle 1.9.0a9`.
5. Let the automatic wardrobe scan finish before generating.

## Test A: warm Generate Outfit

1. Use **Generate Outfit**.
2. Capture the timing line and hover tooltip.
3. Confirm the outfit appears atomically and no Lua error occurs.
4. Record:
   - frames and total seconds;
   - worst step and slowest phase;
   - era-source checks;
   - era and eligibility cache hits;
   - entries added and invalidated;
   - the new `Item data` diagnostic line;
   - exact invalidation reasons.

Expected: stable-ignored callbacks may be numerous, but `ITEM_DATA_LOADED` must not appear as a mass invalidation reason. `ITEM_DATA_PENDING_RESOLVED` should be small and represent only genuinely completed missing items.

## Test B: Reroll Unlocked twice

1. Use **Reroll Unlocked** twice without changing settings.
2. Capture both tooltips.
3. Confirm locks, hidden slots, and weapon behavior remain correct.

Expected: invalidations should remain near zero or a small genuine-pending count. Stable-ignored and coalesced counters may increase without reducing persistent cache totals.

## Test C: persistence crossing

1. Use `/reload`.
2. Let the automatic wardrobe scan finish.
3. Use **Generate Outfit** once.
4. Capture the tooltip.

Expected:

- thousands of evidence and eligibility records load and survive the scan;
- era and eligibility cache hits remain warm;
- no return to the v1.9.0a7 cold value of 10,658 era-source checks;
- no recurrence of approximately 1,700 `ITEM_DATA_LOADED` invalidations;
- worst step remains within the responsive cooperative range.

## Failure signals

- `ITEM_DATA_LOADED` invalidates hundreds or thousands of records;
- persistent evidence falls sharply during generation;
- stable item callbacks trigger repeated row refreshes;
- item-derived evidence remains stale after a genuine metadata identity change;
- Lua errors, weapon mismatches, non-atomic previews, or changed Traveler selection behavior.
