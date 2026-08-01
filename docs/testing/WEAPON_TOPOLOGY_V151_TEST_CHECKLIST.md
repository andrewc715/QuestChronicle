# Quest Chronicle v1.5.1 Weapon Topology Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.5.1.
3. Log in and open `/qc` → **Outfits**.
4. No wardrobe rescan is required solely for this update.

## Two-handed sword regression

1. Equip **Elexorien Blade of the Aurora** or another item whose tooltip says **Two-Hand**.
2. Open Outfits.
3. Confirm the heading reads:

   `Weapon Generation • Two-handed weapon equipped`

4. Confirm:
   - Two-Hand is enabled and checked.
   - One-Hand is disabled.
   - Ranged is disabled.
   - Off-Hand is disabled.
5. Hover One-Hand and confirm its tooltip explains that it is unavailable for the current layout.
6. Generate or reroll an outfit and confirm it chooses only a Two-Hand appearance.

## Other layouts

- Equip a bow, gun, or crossbow and confirm **Ranged only**.
- Equip a one-hand weapon with an empty off-hand and confirm **One-Hand only**.
- Equip a one-hand weapon plus shield/focus and confirm **One-Hand + optional Off-Hand**.
- Dual wield and confirm **One-Hand** controls both weapon hands.
- Unequip the main hand and confirm all compatible cached families can be selected.

## Live equipment changes

1. Keep the Outfits tab open.
2. Swap from a two-handed weapon to a one-handed weapon.
3. Confirm the heading and checkbox availability update without `/reload`.

## Regression

- Saved concepts still restore weapon-family preferences.
- Custom Set creation and update still verify all intended slots.
- Chronicle, RP notes, active quests, and Courier export remain unchanged.
