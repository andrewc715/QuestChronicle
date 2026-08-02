# Quest Chronicle v1.8.3 Era Metadata Revalidation Test Checklist

## Installation

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` folder with v1.8.3.
3. Log into the same character in Outland.
4. A wardrobe rescan is not required.

## Known regression item

1. Browse Waist appearances and locate **Green Belt of Quiet Understanding** if collected.
2. Hover the row.
3. Confirm the tooltip identifies it as excluded from generation in an Outland/TBC context because it is a Mists of Pandaria item.
4. Generate and reroll several outfits.
5. Confirm the belt is not selected automatically.
6. Confirm it remains available for manual preview.

## Stale-cache migration

1. Begin with a wardrobe source carrying an older cached `expansionID` but no `itemMetadataVerified` marker.
2. Confirm Quest Chronicle re-queries the item rather than trusting the old value.
3. If item data is temporarily unavailable, confirm the row reports **Loading era** and is excluded from generation.
4. After item data loads, reopen or refresh the Outfits view and confirm the correct expansion restriction appears.

## Regression

- Classic and TBC appearances remain eligible in Outland when other rules permit them.
- Mists of Pandaria and later appearances remain browseable but are not generated in Outland.
- Heritage Armor progression restrictions still work.
- Weapon Appearance Routes still generate Main Hand and Off Hand correctly.
- Saved concepts and native Custom Sets remain unchanged.
