# Quest Chronicle v1.6.4: Deferred Linked Preview Fix

Version 1.6.4 repairs two related live-client failures in the embedded Outfits character preview.

## What the screenshots proved

The generated outfit contained 13 selected appearances, confirming that Quest Chronicle had already created both weapon-hand selections. The missing one-handed secondary weapon was therefore not a generator failure. The model was restoring the physically equipped off-hand after Quest Chronicle applied the linked appearance.

A separate screenshot showed the player actor reduced to a tiny dark silhouette. Both failures came from dressing the model while `SetUnit("player")` was still loading or refreshing its actor.

## Fixed

- Preview dressing waits for `OnModelLoaded` before applying any selected appearance.
- A short timer fallback handles clients that do not emit `OnModelLoaded` when refreshing the same unit.
- Every preview request receives a token. A newer refresh cancels any older pending pass.
- Main Hand is applied before Secondary Hand.
- Secondary Hand is replayed on the next timer frame, after main-hand weapon-option child updates have settled.
- Weapon slots are no longer cleared while the player actor is loading.
- `SetItemTransmogInfo()` remains the exact source-aware path. The collected item ID is used only as a compatibility fallback.
- The preview reports its final applied count through the existing Quest Chronicle callback channel.

## Behavior retained

When **Link weapon hands** is enabled, Quest Chronicle still chooses:

1. the exact same visual for both hands when Blizzard permits it;
2. another appearance from the same exact weapon subtype when the visual cannot be duplicated;
3. no unrelated weapon family or subtype.

The v1.6.4 change affects only when and how those stored selections are handed to the embedded model.

## Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 6.
- No collection rescan is required.
- Existing concepts and linked Custom Sets remain valid.
