# Quest Chronicle v0.9.2 Live Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Install Quest Chronicle v0.9.2.
3. Start WoW and enter the world.
4. Confirm the chat load message reports v0.9.2.

## Generate without a collection rescan

1. Open Quest Chronicle and select **Outfits**.
2. Click **Generate Outfit** several times, allowing each preview to finish.
3. Confirm no `Wardrobe refreshed automatically` message appears.
4. Repeat with **Reroll Unlocked**.
5. Select an active weapon category and click **Reroll Slot**.
6. Confirm the weapon remains valid for the currently equipped weapon and none of those actions starts a collection scan.

## Genuine collection update

1. Learn a previously uncollected appearance or remove/restore a refundable appearance if a safe test item is available.
2. Confirm Quest Chronicle queues and completes one automatic wardrobe refresh after Blizzard reports the collection change.
3. If the event occurs during combat or while Blizzard's Wardrobe is busy, confirm the refresh waits and then completes afterward.

## Regression checks

1. Confirm **Favor in Zone** changes to **Unfavor** and can be toggled back.
2. Confirm **Exclude in Zone** changes to **Allow in Zone** and can be toggled back.
3. Confirm saved concepts, locked slots, hidden slots, and the existing wardrobe cache remain present.

Expected result: outfit generation performs its required weapon-usability validation without masquerading as a collection change, while real wardrobe changes still refresh automatically.
