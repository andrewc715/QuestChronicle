# Quest Chronicle v0.5.6 Embedded Preview Live Test

## Upgrade

1. Install v0.5.6 and run `/reload` or restart WoW.
2. Open `/qc` and select **Outfits**.
3. Confirm the format 5 collection counts remain populated without rescanning.

## Armor preview

1. Select Head and click an appearance visibly different from the equipped helm.
2. Confirm the embedded model changes immediately and the row shows **Selected**.
3. Repeat with Shoulders, Chest, Hands, Waist, Legs, and Feet.
4. Confirm earlier selected slots remain visible as later pieces are added.
5. Use **Clear Slot** and confirm only the active slot returns to the equipped appearance after the preview rebuild.

## Weapon preview

1. Select Two-Hand and choose a weapon with a clearly different silhouette.
2. Confirm the embedded main-hand weapon changes.
3. Repeat with One-Hand and Ranged.
4. Select Off-Hand and confirm its appearance is routed to the off-hand slot.
5. Test an incompatible weapon combination and confirm the interface remains responsive even if WoW rejects that combination.

## Persistence and reset

1. Change pages and slots; confirm selections remain applied.
2. Close and reopen Quest Chronicle; confirm the saved selections rebuild on the model.
3. Run `/reload`; confirm the selections and format 5 cache persist.
4. Click **Clear Selections** and confirm the model returns to the player's equipped appearance set.

## Regression

1. Confirm Head, Legs, and weapon counts still match the successful v0.5.5 scan scale.
2. Confirm Chronicle history, active quests, notes, settings, and Courier export remain unchanged.
