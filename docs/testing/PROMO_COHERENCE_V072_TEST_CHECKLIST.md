# Quest Chronicle v0.7.2 Live Test Checklist

## Install and compatibility

1. Exit World of Warcraft completely and install v0.7.2.
2. Confirm the Status tab reports v0.7.2, SavedVariables schema 2, and Courier format 1.
3. Open Outfits and confirm the existing wardrobe cache, selections, locks, hidden slots, and saved concepts remain available without rescanning.

## Promotional exclusions

1. Browse to **Renowned Explorer's Akubra** and **Wooly Wendigo Hood**.
2. Confirm each row says **Promo excluded**.
3. Hover each row and confirm the tooltip says the appearance is excluded from generated outfits.
4. Manually select each appearance and confirm it still previews normally.
5. Run **Generate Outfit** and **Reroll Unlocked** at least 20 times across the three style modes.
6. Confirm no Renowned Explorer, Wooly Wendigo, Trading Post, shop, subscription, Recruit-a-Friend, or other labeled promotional piece is selected.

## Cohesive complete outfits

1. Clear selections and generate several outfits in each style mode.
2. Confirm the chest, shoulders, legs, helm, smaller layers, and weapon read as a coordinated concept rather than unrelated slot rolls.
3. When a strong fire, frost, shadow, holy, nature, arcane, storm, fel, necrotic, mechanical, rustic, or regal motif appears, confirm other strongly themed pieces support it.
4. Confirm a dramatic flaming, glowing, cosmic, or similarly loud piece does not appear alone against an otherwise unrelated outfit.
5. When several collected pieces belong to the same Blizzard transmog set, confirm generation visibly favors those relationships without requiring a complete matching set.

## Locks and rerolls

1. Lock two or more coordinated armor slots, then use **Reroll Unlocked**.
2. Confirm locked slots remain unchanged and unlocked pieces coordinate with them.
3. Reroll Head, Shoulders, Chest, and the active weapon individually.
4. Confirm each replacement coordinates with the rest of the visible preview and promotional items remain excluded.
5. Hide a hideable slot and reroll another slot; confirm the hidden layer does not steer the visible outfit profile.

## Weapon safety and rollback

1. Test one-hand, dual-wield, two-hand, ranged, and off-hand equipment configurations.
2. Confirm generated and individually rerolled weapons remain valid for the currently equipped items.
3. Create an intentionally incompatible locked-weapon condition and run generation.
4. Confirm Quest Chronicle explains the conflict and leaves the previous preview intact rather than partially changing the armor.

## Regression pass

1. Confirm era ceilings and local provenance still exclude later-expansion and foreign-zone sources.
2. Confirm Current Look, thumbnails, padlocks, hidden markers, concepts, bottom tabs, pagination, and manual preview selection still work.
3. Confirm no Lua errors appear during login, `/reload`, zone changes, generation, bulk rerolls, individual rerolls, item-data loading, or concept operations.
