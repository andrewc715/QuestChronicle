# Quest Chronicle v1.8.5 — Live Appearance Metadata

## Fixed

- Appearance names now hydrate automatically when WoW finishes loading item data.
- Era eligibility, row detail text, quality color, icon, selected-label text, and open tooltips update from the item-data event instead of waiting for a click.
- Metadata updates are batched and applied only to affected visible rows; they no longer rebuild the entire Outfits page.
- The existing cache is indexed at login, and a completed wardrobe scan rebuilds the metadata index for the new cache.
- Duplicate full workbench refreshes after clicking an appearance were removed.

## Preserved

- Wardrobe cache format remains 7.
- SavedVariables schema remains 2.
- Courier format remains 1.
- Era evidence still fails closed while source data is pending.
- The one automatic scan per login policy remains unchanged.
