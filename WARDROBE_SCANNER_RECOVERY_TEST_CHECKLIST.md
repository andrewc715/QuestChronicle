# Quest Chronicle v0.5.2 Wardrobe Scanner Recovery Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Back up the account SavedVariables file if desired.
3. Replace the existing `QuestChronicle` addon folder with v0.5.2.
4. Log into Xyrkian and wait approximately five seconds after the world finishes loading.
5. Keep Blizzard's Transmogrify and Collections Wardrobe windows closed.

## Required test

1. Run `/qc`.
2. Open **Outfits**.
3. Click **Scan Collection**.
4. Confirm the status first says that WoW's wardrobe collection is being prepared.
5. Confirm the scan advances through all equipment groups.
6. Check Head, Chest, Hands, Legs, and Feet.

Expected result:

- `WoW reports ... collected` should be substantially greater than zero for normal armor categories.
- `... compatible visuals cached` should resemble the size of the character's actual collected Wardrobe rather than the two or three equipped/bag appearances seen in v0.5.0.
- The slot list should paginate when more than eight appearances exist.
- Clicking appearances should preview them without changing the equipped transmog.

## Native Wardrobe comparison

1. Record the Quest Chronicle Chest count.
2. Close Quest Chronicle.
3. Open Blizzard's Collections Wardrobe or visit a Transmogrifier.
4. Select Chest and ensure the native window shows a substantial collected collection.

The counts do not need to match exactly. Quest Chronicle intentionally:

- excludes hidden-slot visuals;
- keeps one representative source per visual;
- excludes appearances WoW says the current character cannot display or use.

They should nevertheless be in the same general neighborhood, not `0`, `1`, or `2` against many pages in Blizzard's interface.

## Failure behavior

If WoW's search database does not become ready within twelve seconds, the Outfits tab should display a clear failure message rather than silently replacing the cache with zeros.

If a healthy cache already exists, a failed rescan should leave those prior appearances intact.

## Report back

A screenshot of Head and Chest after scanning is enough for the first verdict. The most useful text is:

```text
WoW reports N collected for these categories
M compatible visuals cached
```
