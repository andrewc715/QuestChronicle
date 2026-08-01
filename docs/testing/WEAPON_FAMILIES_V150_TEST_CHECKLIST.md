# Quest Chronicle v1.5.0 Weapon Families Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.5.0.
3. Log in and open `/qc` → **Outfits**.
4. No manual collection rescan should be required if the v1.0.6 cache was healthy.

## Checkbox interface

1. Confirm the center panel shows One-Hand, Two-Hand, Ranged, and Off-Hand checkboxes.
2. Hover every checkbox, including unavailable ones.
3. Confirm each tooltip explains the current equipped layout and availability rule.
4. Confirm unavailable checkboxes remain visible but visually muted.
5. Confirm at least one available main family must remain selected.

## Equipped topology tests

### Two-hand

1. Equip a two-handed sword, axe, mace, staff, or polearm.
2. Confirm Two-Hand is the only available checked family.
3. Confirm Ranged and Off-Hand cannot be enabled.
4. Generate and verify the selected weapon comes from Two-Hand.

### Ranged

1. Equip a bow, crossbow, or gun.
2. Confirm Ranged is the only available family.
3. Generate and verify no melee or off-hand appearance is selected.

### One-hand, empty off-hand

1. Equip one one-hand weapon and leave the off-hand empty.
2. Confirm One-Hand is available and Off-Hand is unavailable.

### One-hand with shield or focus

1. Equip a one-hand weapon plus a shield or held-in-off-hand item.
2. Confirm One-Hand and Off-Hand are available.
3. Uncheck Off-Hand and generate; the current off-hand appearance should remain unchanged.
4. Check Off-Hand and generate; both hands should receive valid appearances.

### Dual wield

1. Equip one-hand weapons in both hands.
2. Confirm only One-Hand is available.
3. Generate and verify both weapon hands are drawn from the One-Hand appearance pool.

### No weapon

1. Unequip the main hand.
2. Confirm cached One-Hand, Two-Hand, and Ranged families can be independently checked.
3. Confirm Off-Hand requires One-Hand.
4. Generate several times and verify only checked main families appear.

## Concepts

1. Select a distinctive checkbox combination.
2. Save a concept.
3. Change the checkbox combination.
4. Load the concept and confirm its weapon-family choices return.
5. Confirm the Outfit Concepts detail line includes a compact weapon-family summary.
6. Save or update a linked Blizzard Custom Set and confirm the existing handoff still verifies all intended slots.

## Equipment changes

1. Leave the Outfits tab open.
2. Swap from a two-hand weapon to a one-hand plus shield.
3. Confirm the checkbox availability and header update immediately without `/reload`.
4. Confirm existing concepts remain saved even if their stored family choices are unavailable for the new equipment.
