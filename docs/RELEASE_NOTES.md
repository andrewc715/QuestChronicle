# Quest Chronicle v1.8.1: Normalization Namespace Hotfix

Version 1.8.1 repairs a runtime regression introduced by the v1.8.0 code-only module split. It contains no intended feature, UI, generation-rule, SavedVariables, Courier, wardrobe-cache, or gameplay behavior changes.

## Root cause

Before normalization, `SafeCall` and `Shuffle` were local functions inside the large `Core/Wardrobe.lua` file. The normalized modules expose those shared private helpers through `Wardrobe._Private`, locally named `P`.

Three call sites retained the old unqualified names after the split:

- `Foundation.lua` called `SafeCall()` while preparing collection filters.
- `CollectionScanAndPreview.lua` called `SafeCall()` while resetting the preview model.
- `GenerationAndConcepts.lua` called `Shuffle()` while randomizing route candidates.

Those names no longer existed as module globals, so the first automatic wardrobe scan failed immediately after login or `/reload`.

## Corrections

The affected calls now use their normalized private namespace:

```lua
P.SafeCall(...)
P.Shuffle(...)
```

A new repository check, `tools/verify_split_helper_references.py`, scans every normalized subsystem and fails when a helper declared as `P.Helper()` is later called as an orphaned global `Helper()`.

## Preserved

- Every runtime Lua file remains at or below 500 physical lines.
- The v1.7.2 feature behavior remains the target baseline.
- Weapon Appearance Routes and linked/unlinked hand generation are unchanged.
- Main Hand and Off Hand Current Preview labels are unchanged.
- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 6.
- No collection rescan, concept migration, or Custom Set rebuild is required beyond the normal one automatic scan for the new login or `/reload` session.
