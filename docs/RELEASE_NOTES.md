# Quest Chronicle v1.8.3: Era Metadata Revalidation

Version 1.8.3 fixes a progression leak where a later-expansion appearance could enter an earlier-zone generation pool because a stale `expansionID` persisted on the cached wardrobe source.

## Live symptom

While questing in Outland, automatic generation selected **Green Belt of Quiet Understanding** (item 89561), a Mists of Pandaria reward. Its tooltip incorrectly reported:

```text
Generated pool: Era eligible; no conflicting source zone is reported by WoW.
```

## Root cause

Wardrobe sources persist in SavedVariables. Earlier versions cached `source.expansionID` but did not record which representative item ID had supplied that value. `LoadItemMetadata()` returned any existing value immediately, so an unverified or stale era could survive indefinitely.

## Correction

- Item metadata is now keyed to `itemMetadataItemID`.
- Cached era data is trusted only when `itemMetadataVerified` is true for that exact item ID.
- Older unverified values are re-read through `C_Item.GetItemInfo` the next time the source is evaluated.
- If WoW has not loaded the item yet, the source fails closed as **Loading era**.
- Unverified SavedVariables era data is never used to admit an appearance into generation.
- No curated item-name blacklist was added. The repair applies to every appearance.

## Compatibility

- SavedVariables schema: 2
- Courier format: 1
- Wardrobe cache format: 6
- No collection rescan is required solely for this update.
- Existing concepts, selections, weapon routes, Custom Set links, and Chronicle data are preserved.
