# Quest Chronicle v1.8.5 Validation Report

## Automated checks

- All 36 Lua files passed `loadfile` syntax validation through LuaTeX.
- Every Lua file remains at or below the 500-line mandate.
- Largest Lua file: `Core/Wardrobe/CollectionScanAndPreview.lua` at 477 lines.
- No orphaned split-module private helper calls were found.
- Every TOC path resolves.
- Courier configuration JSON parses successfully.
- Addon and VERSION metadata both report 1.8.5.

## Metadata regression harness

The harness began with a cached source named `Appearance 100` for item 63205.

1. Tracking the source requested its representative item and sibling item data.
2. Simulating `ITEM_DATA_LOAD_RESULT` changed the source name to `Safety Goggles`.
3. Quality, icon, style metadata, and expansion metadata were hydrated.
4. Cached era evidence was invalidated.
5. Exactly one `WARDROBE_SOURCE_METADATA_UPDATED` notification identified the affected source.
6. Loading a sibling item invalidated the same visual's era evidence and emitted another targeted update.

## UI invariants

- The metadata callback invokes `RefreshVisibleAppearanceMetadata`, not the full workbench `Refresh` method.
- Only visible rows whose source IDs changed are redrawn.
- An open tooltip is rebuilt in place when its row changes.
- Selected-source text and the open Current Preview manifest are refreshed.
- The appearance click handler no longer performs a duplicate full refresh after `WARDROBE_SELECTION_CHANGED`.
