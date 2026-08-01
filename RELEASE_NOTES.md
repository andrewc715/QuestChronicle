# Quest Chronicle v0.5.6: Embedded Preview Repair

The collection scanner is now returning native-scale appearance counts. The remaining preview failure came from passing the wrong identifier type to the embedded `DressUpModel`.

WoW's `TryOn` method accepts an item link or an item-modified appearance ID. Quest Chronicle stored both the ordinary item ID and the transmog source ID, but v0.5.5 passed the ordinary item ID. For collected appearance records this could fail silently or leave the character's currently equipped appearance unchanged.

## Preview correction

- Passes the cached transmog `sourceID` to `DressUpModel:TryOn`.
- Routes One-Hand, Two-Hand, and Ranged previews to `MAINHANDSLOT`.
- Routes Off-Hand previews to `SECONDARYHANDSLOT`.
- Uses the returned `ItemTryOnReason` to distinguish successful and failed applications.
- Reapplies every selected slot after resetting the model to the player, preserving multi-piece manual outfit previews.

## Cache and data compatibility

The corrected format 5 wardrobe cache remains valid. Upgrading from v0.5.5 does not require another collection scan.

- Addon version 0.5.6.
- Wardrobe cache format 5.
- SavedVariables schema 2.
- Courier format 1.
- Warcraft Quest Chronicle Courier v1.0.0 remains compatible.
- Preview only; Quest Chronicle never applies transmog to the character or changes Blizzard outfit slots.

## Focused live check

After reloading the UI, open Outfits and select visibly different Head, Chest, Legs, and Two-Hand appearances. Each click should immediately update the embedded character model while prior selections in other slots remain applied. No rescan should be necessary.
