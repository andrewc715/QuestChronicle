# Quest Chronicle v0.5.4: Native Visual Indexing

Version 0.5.4 fixes the wardrobe catalog regression revealed by the live Legs comparison. Blizzard's native Wardrobe already returns one row per collapsed visual appearance. Quest Chronicle v0.5.3 resolved a source for each row, but then used a source-level appearance identifier as the cache key. That mixed two identifier namespaces and could overwrite hundreds of distinct Blizzard visual rows with one entry.

## Scanner correction

- Treats `GetCategoryAppearances(...).visualID` as the authoritative catalog identity.
- Keeps one cache record per collected, non-hidden Blizzard visual row.
- Resolves all sources belonging to that visual and retains the best collected source the current character can display.
- Never uses a source's `appearanceID` or `itemAppearanceID` to deduplicate the catalog.
- Handles API paths that return either full source records or numeric source IDs.
- Uses Blizzard's collection source-to-item lookup before the older transmog fallback.
- Preserves staged-cache protection: an impossible empty result cannot replace a healthy cache.

## Cache migration

The rebuildable wardrobe cache advances from format 3 to format 4. On first load, v0.5.4 marks the old cache stale and requires **Scan Collection**. This is intentional because format 3 may already have lost distinct visuals. The migration does not change or delete Chronicle history, quest state, RP notes, drafts, settings, or Courier data. Manual preview selections remain stored and will reconnect when their source is present in the rebuilt cache.

## Compatibility

- Addon version 0.5.4.
- SavedVariables schema 2.
- Courier format 1.
- Warcraft Quest Chronicle Courier v1.0.0 remains compatible.
- Preview only: Quest Chronicle does not apply transmog or alter Blizzard outfit slots.

## Expected live result

After a clean scan, **Legs** should contain roughly the same collapsed collected visual catalog shown by Blizzard's native Wardrobe. For the reported collection, that means approximately 15 seven-row pages rather than one cached visual. Small count differences are acceptable only when Blizzard marks a visual hidden, unusable, or undisplayable on the current character.
