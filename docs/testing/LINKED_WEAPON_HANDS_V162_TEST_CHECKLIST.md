# Quest Chronicle v1.6.2 Linked Weapon Hands Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.6.2.
3. Log into the Fury Warrior used for the v1.6.1 test.
4. Open `/qc` and select **Outfits**.

No wardrobe rescan is required.

## Exact visual linking

1. Equip two weapons so both physical hands are occupied.
2. Enable **Link weapon hands**.
3. Enable One-Hand and select only **One-Handed Sword** in its type flyout.
4. Generate several outfits.
5. Confirm both preview hands use the same sword visual whenever Blizzard permits that visual in both hands.
6. Confirm the second hand never becomes an axe, mace, staff, polearm, or another unrelated type.

## Same-subtype fallback

1. Test a visual that Blizzard permits in the main hand but not as the exact second-hand source, if one is available.
2. Confirm Quest Chronicle remains within **One-Handed Sword** rather than choosing another subtype.
3. Confirm any fallback notice explains that the exact visual was unavailable and the same weapon type was used.

## No linked match

1. Restrict the subtype pool until no valid second-hand match is available.
2. Generate an outfit.
3. Confirm Quest Chronicle leaves the second hand on its equipped appearance rather than choosing an unrelated category.
4. Confirm a notice explains why the second hand was not replaced.

## Rerolls and manual selection

1. Generate a linked pair.
2. Reroll the main weapon slot.
3. Confirm the second hand relinks to the new visual or exact subtype.
4. Manually select a main-hand weapon appearance from the browser.
5. Confirm the second hand is synchronized under the same rules.

## Independent mode

1. Disable **Link weapon hands**.
2. Generate several outfits with multiple permitted weapon subtypes selected.
3. Confirm each hand may now choose independently.

## Regression

- Fury still exposes Blizzard-permitted One-Hand and Two-Hand categories.
- Non-Fury two-handed layouts remain limited to Blizzard-permitted categories.
- Saved concepts retain the Link weapon hands preference.
- Custom Set save and verification still include both weapon slots correctly.
- Chronicle, Active Quests, Write Note, Status, minimap button, and Courier export remain functional.
