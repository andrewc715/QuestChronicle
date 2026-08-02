# Quest Chronicle v1.8.1 Validation Report

## Scope

v1.8.1 repairs namespace qualification mistakes introduced during the v1.8.0 structural split. No runtime behavior was intentionally redesigned.

## Regressions found

The audit found three private helpers still called by their pre-split local names:

1. `SafeCall()` in `Core/Wardrobe/Foundation.lua` during collection-filter preparation.
2. `SafeCall()` in `Core/Wardrobe/CollectionScanAndPreview.lua` during player-model reset.
3. `Shuffle()` in `Core/Wardrobe/GenerationAndConcepts.lua` during route candidate randomization.

All now call `P.SafeCall()` or `P.Shuffle()` through the normalized `Wardrobe._Private` namespace.

## Automated checks

- 33 runtime Lua files parsed successfully.
- Every runtime Lua file remains at or below 500 lines.
- Largest Lua file remains 474 lines: `Core/Wardrobe/Foundation.lua`.
- The new split-helper reference guard found no orphaned private-helper calls.
- A focused Lua harness executed collection-filter setup, weapon-route shuffling, and preview-model reset successfully.
- Every TOC runtime path resolved.
- Every JSON file parsed.
- Runtime, TOC, and text version metadata matched 1.8.1.
- Public API comparison against the validated v1.7.2 baseline reported no missing or additional public APIs.
- ZIP integrity validation passed.

## Behavioral boundary

The package changes namespace qualification and validation tooling only. SavedVariables schema 2, Courier format 1, wardrobe cache format 6, Weapon Appearance Routes, Current Preview hand labels, Custom Set integration, and UI behavior remain unchanged.
