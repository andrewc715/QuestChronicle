# Quest Chronicle v1.6.1 Fury Appearance Permission Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the current `QuestChronicle` addon folder with v1.6.1.
3. Log into a Fury Warrior with two two-handed weapons equipped.
4. Open `/qc` and select **Outfits**.

No wardrobe rescan is required solely for this patch.

## Family controls

1. Confirm the preview summary still says **Dual two-handed weapons equipped**.
2. Confirm **Two-Hand** remains available.
3. Confirm **One-Hand** is now available when Blizzard's native Transmog UI permits one-handed appearances for those equipped Fury weapon slots.
4. Confirm **Ranged** and shield/focus **Off-Hand** remain unavailable unless Blizzard explicitly exposes them.

## One-Hand flyout

1. Open the `>` flyout beside **One-Hand**.
2. Confirm ordinary one-handed categories permitted by Blizzard are enabled, rather than only Paired Artifact.
3. Hover an enabled category and confirm the tooltip says Blizzard's native outfit-slot rules permit it.
4. Categories with no collected cached visuals may remain disabled even when Blizzard permits the category.

## Browser and generation

1. Check at least one ordinary One-Hand subtype, such as Sword, Axe, or Mace.
2. Browse One-Hand and confirm matching appearances are listed.
3. Click **Generate Outfit** several times.
4. Confirm the embedded Fury preview can receive one-handed appearances on the equipped two-handed weapon hands.
5. Test with **Link weapon hands** enabled and disabled.
6. Save the concept to a WoW Custom Set and verify both weapon slots survive native readback.

## Native comparison

Open Blizzard's Transmogrify window for the same Fury character and compare its weapon-category dropdown with Quest Chronicle. The available category families should agree because both now use `GetCollectionInfoForSlotAndOption()`.

## Regression

- Non-Fury two-handed users should not gain one-handed categories unless Blizzard exposes them.
- One-hand plus shield, ranged, and dual-one-hand layouts should retain their existing behavior.
- Existing concepts, Custom Set links, Chronicle data, and Courier data remain intact.
