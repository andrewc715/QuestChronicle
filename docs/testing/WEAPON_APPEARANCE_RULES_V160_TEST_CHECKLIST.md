# Quest Chronicle v1.6.0 Weapon Appearance Rules Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.6.0.
3. Log in and open `/qc` → **Outfits**.
4. Existing wardrobe cache, concepts, Custom Set links, Chronicle data, and Courier data should remain intact.

## Equipment Slot panel

1. Confirm armor slots remain normal buttons.
2. Confirm a **Weapon Appearances** heading follows Feet.
3. Confirm One-Hand, Two-Hand, Ranged, and Off-Hand each have:
   - a checkbox;
   - a clickable browse row;
   - a `>` type button;
   - selected/available type counts.
4. Confirm **Link weapon hands** appears below the family rows.
5. Confirm the old detached checkbox block is gone from the character-preview panel.

## Fury dual-two-hand rule

1. Equip two two-handed weapons as Fury.
2. Confirm the physical summary says **Dual two-handed weapons equipped**.
3. Confirm One-Hand and Two-Hand become available when Blizzard permits both.
4. Confirm Ranged and Off-Hand remain unavailable unless Blizzard explicitly permits them.
5. Open One-Hand types and verify only Blizzard-compatible one-hand categories are enabled.
6. Open Two-Hand types and verify the compatible two-hand categories are enabled.

## Standard two-hand rule

1. Equip a two-handed weapon on a specialization without the one-hand appearance exception.
2. Confirm Two-Hand is available.
3. Confirm One-Hand remains unavailable when Blizzard rejects those categories.
4. Verify the physical topology still says Two-Hand even if Blizzard permits an unusual appearance category.

## Type flyout

For each available family:

1. Click `>` and verify the flyout opens beside the Equipment Slot panel.
2. Hover each type and verify its tooltip explains Blizzard compatibility or why it is unavailable.
3. Click **All Compatible** and verify every available type is checked.
4. Click **Equipped Type** and verify only the physical item's category is selected when that category belongs to the open family.
5. Click **Clear** and verify compatible types are unchecked.
6. Click **Done** and verify the flyout closes.

## Browser filtering

1. Select only Two-Handed Sword and Polearm.
2. Click the Two-Hand family row.
3. Confirm the browser title reports `2 of 5 Types`.
4. Confirm only swords and polearms are listed.
5. Change the filters and verify pagination safely clamps to the new page count.

## Generation

1. Select at least two exact types with different collection sizes.
2. Generate repeatedly and confirm both types can appear.
3. Confirm an unchecked type is never generated.
4. Confirm **Reroll Unlocked** and **Reroll Slot** obey the same filters.
5. Clear every compatible type and confirm generation refuses with a useful message rather than selecting an unapproved type.

## Linked hands

1. Equip two weapon hands.
2. Enable **Link weapon hands**.
3. Generate repeatedly and confirm both hands prefer the same family and exact type.
4. Disable it and confirm the two hands may generate independently.
5. Verify a Blizzard-incompatible second-hand category is never forced merely to preserve linking.

## Concepts

1. Configure a distinctive set of families and types.
2. Disable Link weapon hands.
3. Save a concept.
4. Change the controls.
5. Reload the concept.
6. Confirm families, exact types, and linked-hands preference are restored.
7. Change specialization and verify unavailable saved preferences become dormant rather than being deleted.

## Custom Sets

1. Generate and save a dual-weapon concept.
2. Save or update its Blizzard Custom Set.
3. Confirm every selected slot verifies successfully.
4. Confirm a Fury off-hand can retain a Blizzard-permitted one-hand or two-hand source.

## Regression

- Chronicle, Active Quests, Write Note, Status, minimap button, and AddOn Compartment still work.
- `/qc export` followed by `/reload` still updates SavedVariables.
- The one automatic wardrobe scan per login policy remains unchanged.
