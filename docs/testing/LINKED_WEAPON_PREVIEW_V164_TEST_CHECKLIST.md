# Quest Chronicle v1.6.4 Deferred Linked Preview Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.6.4.
3. Log into the Fury Warrior used for the previous linked-hand tests.
4. Open `/qc` and select **Outfits**.

No wardrobe rescan is required.

## Fury one-hand linked preview

1. Equip two physical two-handed weapons.
2. Enable **One-Hand**.
3. Disable **Two-Hand**, **Ranged**, and **Off-Hand**.
4. Enable **Link weapon hands**.
5. Select one or more Blizzard-compatible one-hand subtypes.
6. Click **Generate Outfit** several times.
7. Confirm **Current Look** includes both weapon hands.
8. Confirm the embedded model displays a generated one-hand appearance in both hands.
9. Confirm the second hand no longer reverts to the physically equipped two-handed weapon.

## Two-hand regression

1. Disable One-Hand and enable Two-Hand.
2. Generate several linked outfits.
3. Confirm both generated two-hand appearances still render.

## Model-load race

1. Rapidly switch between Zone, Traveler, Class, and Echo.
2. Generate and reroll several times in quick succession.
3. Open and close a weapon-type flyout while previews refresh.
4. Confirm the character remains fully rendered and does not collapse into a tiny dark silhouette.
5. Confirm only the latest requested outfit remains visible.

## Reset and concept regression

1. Click **Reset Outfit** and confirm equipped gear returns.
2. Load an existing saved concept and confirm its complete appearance renders.
3. Save or update a WoW Custom Set and confirm the native set still verifies every selected slot.

Report any Lua error plus whether the failure occurred before or after the character actor became visible.
