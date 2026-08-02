# Quest Chronicle v1.8.4 Era Evidence Rebuild Test Checklist

## Install and migration

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` folder with v1.8.4.
3. Log in or use `/reload` after installation.
4. Confirm Quest Chronicle performs one automatic wardrobe scan.
5. Wait for that scan to finish before generating an outfit.
6. Confirm the Status tab reports the wardrobe as current afterward.

The rebuild is expected because wardrobe cache format 7 invalidates the previous appearance cache. Chronicle history, concepts, Custom Set links, locks, and hidden slots should remain intact.

## Biting Yellow Belt regression

1. Remain in Outland with **Restrict generated outfits to the zone's expansion** enabled.
2. Browse the Waist slot and locate **Biting Yellow Belt**, item 89565, when available.
3. Hover it.
4. Confirm it remains browseable and manually previewable.
5. Confirm the tooltip says it is excluded from generation as a Mists of Pandaria appearance and names the era-evidence method.
6. Generate and reroll several outfits.
7. Confirm Biting Yellow Belt is never automatically selected.

## Green Belt regression

Repeat the same test for **Green Belt of Quiet Understanding**, item 89561. It must be excluded from an Outland/TBC generation pool.

## Broader visual-family evidence

1. Inspect several appearances whose displayed source is missing useful location text.
2. Confirm the tooltip reports a concrete era-evidence path when Blizzard exposes one, such as:
   - transmog set metadata;
   - appearance tracking;
   - encounter journal;
   - item metadata from one of multiple visual sources.
3. Confirm the tooltip no longer presents an unexplained `Era eligible` conclusion.

## Loading and unknown evidence

1. Immediately after a fresh cache rebuild, inspect appearances while item data is still arriving.
2. Confirm unresolved rows show **Loading era** or another fail-closed exclusion.
3. Confirm unresolved appearances are not generated.
4. Reopen or refresh the Outfits tab after item data loads and confirm verified appearances become eligible only when their era fits the current zone cap.

## Refresh policy

1. Learn or remove an appearance after the initial scan.
2. Confirm Quest Chronicle marks the collection stale but does not automatically rescan again in the same session.
3. Click **Scan Collection** and confirm the stale notice clears.
4. Use `/reload` and confirm exactly one automatic scan occurs in the new session.

## Regression coverage

- Generate linked One-Hand weapon pairs.
- Generate linked Two-Hand weapon pairs.
- Verify Main Hand and Off Hand labels.
- Save and reload an outfit concept.
- Update a linked native Custom Set.
- Run `/qc export` followed by `/reload` and confirm Courier data remains healthy.
- Confirm no Lua errors occur during the automatic wardrobe scan.
