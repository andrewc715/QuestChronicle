# Quest Chronicle v1.6.5 Preview Rollback and Fury Off-Hand Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the current `QuestChronicle` addon folder with v1.6.5.
3. Log into the Fury Warrior used for the v1.6.4 test.
4. Open `/qc` and select **Outfits**.

No wardrobe rescan is required.

## Character model stability

1. Generate several armor outfits.
2. Switch between Chronicle generation modes.
3. Open and close Current Look and weapon-type flyouts repeatedly.
4. Confirm the character remains full-sized, illuminated, and fully dressed.
5. Confirm no tiny black silhouette appears.

## Fury linked one-hand generation

1. Equip two two-handed weapons.
2. Enable **One-Hand**.
3. Disable **Two-Hand**.
4. In One-Hand Types, select only **One-Handed Sword**.
5. Enable **Link weapon hands**.
6. Click **Generate Outfit**.
7. Open **Current Look**.

Expected:

- Main Hand is a generated one-handed sword.
- Secondary Hand is a generated one-handed sword.
- The second entry is not labeled **Equipped**.
- Both hands use the same visual when possible, otherwise the same exact subtype.

## Two-hand regression

1. Disable One-Hand.
2. Enable Two-Hand.
3. Select one two-hand subtype.
4. Generate again.

Expected:

- Both physical Fury weapon hands preview correctly.
- The model remains stable.

## Custom Set regression

1. Save the repaired look as a Quest Chronicle concept.
2. Save or update its WoW Custom Set.
3. Confirm native Custom Set verification still reports every selected slot matched.
