# Quest Chronicle v0.6.1 Live Test: Weapon Rules and Bottom Tabs

## Install and preserve data

1. Exit World of Warcraft completely.
2. Replace the installed `QuestChronicle` folder with v0.6.1.
3. Start WoW, log into the character used for v0.6.0 testing, and open Quest Chronicle.
4. Confirm the wardrobe counts and saved outfit concepts are still present without rescanning.

## Bottom tabs

1. Confirm Chronicle, Active Quests, Write Note, Status, and Outfits appear along the bottom edge of the Quest Chronicle window.
2. Confirm the selected tab uses Blizzard's raised gold-highlight treatment and visually connects to the content above it.
3. Click every tab and confirm the correct page opens.
4. Close and reopen Quest Chronicle and confirm the last selected tab is remembered.
5. Resize the window at its minimum and maximum sizes. Confirm the tabs, content, and resize grip do not overlap or leave the screen.

## One-hand and off-hand equipment

1. Equip a one-hand main-hand weapon and a shield or held-in-off-hand item that the character can transmogrify.
2. Open Outfits and click **Generate Outfit**.
3. Confirm One-Hand receives a selected appearance and Two-Hand and Ranged remain clear.
4. If the Off-Hand cache contains a compatible visual, confirm Off-Hand receives one; otherwise confirm the current off-hand appearance remains on the model and the status explains why.
5. Click **Reroll Unlocked** and then reroll the active One-Hand or Off-Hand slot. Confirm every result remains available in Blizzard's native Transmogrify UI for the equipped item.
6. Equip a second one-hand weapon instead of the shield or held item, generate again, and confirm the Off-Hand selection now comes from a weapon category Blizzard permits for that secondary-hand item.

## Two-hand equipment

1. Equip a two-hand weapon and leave the off hand empty.
2. Click **Generate Outfit** several times.
3. Confirm only the Blizzard-valid main-hand category is selected; One-Hand, Ranged, and Off-Hand do not appear together with it.
4. Open Blizzard's Transmogrify UI and spot-check several generated appearances against the choices it offers for the equipped weapon.

## Ranged equipment

1. Equip a bow, gun, or crossbow.
2. Click **Generate Outfit** and **Reroll Unlocked** several times.
3. Confirm every generated weapon visual belongs to a category Blizzard permits for that equipped ranged item.
4. Confirm One-Hand, Two-Hand, and Off-Hand selections are cleared when Ranged is generated.

## Empty hands and changed gear

1. Unequip the main-hand item and click **Generate Outfit**.
2. Confirm armor is generated, no weapon appearance is invented, and the status says armor-only generation was used.
3. Equip a weapon, generate an appearance, and lock its weapon slot.
4. Change to an incompatible weapon type and click **Generate Outfit** again.
5. Confirm generation stops with an unlock-or-equip explanation and does not silently keep the invalid locked weapon.
6. Unlock the slot and generate again. Confirm the new weapon appearance matches the newly equipped item.

## Regression checks

1. Manually browse Head, Legs, and weapon pages and confirm the full native-scale catalog is still present.
2. Select manual appearances and confirm they still preview on the embedded model.
3. Save and load a concept created in v0.6.0, then save a new v0.6.1 concept.
4. Confirm locks, hidden helm/cloak/shirt/tabard choices, and armor selections round-trip correctly.
5. Confirm no transmog is applied to the character and no Blizzard outfit slot is changed.
