# Quest Chronicle v0.5.5: Native Appearance Eligibility

The live SavedVariables diagnostics explain the one-item result: v0.5.3 received hundreds of collected collapsed appearances from WoW, then rejected almost every one while validating individual item sources. Legs returned 302 collected appearance rows and 1,039 source rows, but only one appearance survived the source gate. Other armor slots showed the same pattern.

Blizzard's native Wardrobe determines whether a visual belongs in the catalog from the collapsed category appearance row. Individual source records describe the items sharing that visual and help choose a representative item; they are not separate catalog entries and their restrictions must not erase an already-unlocked appearance.

## Scanner correction

- Uses the category appearance's `visualID` as the catalog identity.
- Uses the category appearance's `isCollected` flag as the visual's collection state.
- Uses the category appearance's display flag for preview eligibility.
- Keeps source-level collection, validity, condition, and use-error fields only for ranking the best preview source.
- Allows an appearance unlocked through one source to use another item sharing the same visual as its preview representative.
- Continues to exclude hidden visuals and entries for which WoW provides no previewable item.
- Handles source-info records and numeric source-ID API results.

## Cache migration

The rebuildable wardrobe cache advances to format 5. Older wardrobe caches are marked stale and rebuilt with **Scan Collection**. Chronicle history, quest state, RP notes, drafts, settings, Courier data, and manual selection storage are preserved.

## Compatibility

- Addon version 0.5.5.
- SavedVariables schema 2.
- Courier format 1.
- Warcraft Quest Chronicle Courier v1.0.0 remains compatible.
- Preview only; Quest Chronicle does not apply transmog or alter Blizzard outfit slots.

## Expected live result

The native screenshot shows 17 Head pages. After rescanning with v0.5.5, Quest Chronicle should expose approximately the same collected Head catalog across its seven-row pages instead of a single Clefthoof Helm. Legs should similarly expand from one result to roughly the full native collection. Small differences remain possible for hidden visuals or rows for which WoW supplies no item that the embedded model can preview.
