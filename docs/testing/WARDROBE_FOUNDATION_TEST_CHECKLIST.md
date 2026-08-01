# Quest Chronicle v0.5.0 Wardrobe Foundation Test Checklist

## Installation safety

1. Exit World of Warcraft completely.
2. Back up the account-level `QuestChronicle.lua` SavedVariables file.
3. Replace the existing `QuestChronicle` addon folder with v0.5.0.
4. Log in on the character whose wardrobe should be tested.
5. Run `/qc` and confirm the existing Chronicle, Active Quests, Write Note, and Status tabs still open normally.

## Outfits tab

1. Open the new **Outfits** tab.
2. Confirm the player model renders with the character's current equipment.
3. Confirm all equipment-slot buttons fit in the left column.
4. Confirm the page initially explains that the collection has not yet been scanned.

## Collection scan

1. Click **Scan Collection**.
2. Confirm the button changes to **Scanning...**.
3. Confirm progress advances through the equipment slots without freezing the client.
4. Confirm the scan completes and reports a nonzero cached visual count.
5. Confirm slot buttons display cached counts.
6. Confirm selecting a slot displays only collected appearances for that slot.

The first scan can take several seconds on a large collection because WoW must enumerate many appearance sources. The work is split across frames to keep the client responsive.

## Manual preview

1. Select **Head**.
2. Click a collected head appearance.
3. Confirm the model changes and the row displays **Selected**.
4. Select additional armor slots and confirm previous choices remain in the model preview.
5. Test **Previous** and **Next** on a slot with more than eight appearances.
6. Test **Clear Slot** and confirm only that stored selection is removed.
7. Test **Clear Selections** and confirm the model returns to the equipped look.
8. Test **Rotate Left**, **Rotate Right**, and **Reset View**.

## Compatibility behavior

1. Confirm uncollected appearances do not appear.
2. Confirm sources WoW says the character cannot display are excluded or disabled.
3. Confirm weapon categories show only compatible collected sources returned by the client.
4. Confirm no appearance is applied to the actual character.
5. Confirm no gold is spent and no Transmogrifier is required.

## Collection change detection

1. Learn a new appearance, if practical.
2. Reopen the Outfits tab.
3. Confirm the scan button changes to **Rescan Collection** or reports that the collection changed.
4. Rescan and confirm the cached total updates.

## Regression checks

1. Accept or progress a quest and confirm lifecycle recording still works.
2. Record an RP note.
3. Refresh the Courier snapshot.
4. Run `/reload` and confirm the Outfits cache and manual selections persist.
5. Confirm Warcraft Quest Chronicle Courier v1.0.0 continues exporting normally.

## Useful report details

When reporting a problem, include:

- character class and armor type;
- affected slot;
- whether the scan completed;
- the exact Lua error from BugSack or the WoW error window;
- a screenshot of the Outfits tab;
- whether the appearance previews correctly in Blizzard's own Collections wardrobe.
