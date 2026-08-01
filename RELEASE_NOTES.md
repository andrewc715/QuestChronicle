# Quest Chronicle v0.9.1: Zone Preference Toggle Hotfix

Version 0.9.1 fixes the two-way controls for per-zone appearance preferences introduced before v0.9.0.

## Fixed

- **Favor in Zone** still marks the selected collapsed visual as a zone favorite.
- **Unfavor** now actually clears that favorite.
- **Exclude in Zone** still removes the selected visual from automatic generation in the current zone.
- **Allow in Zone** now actually clears that exclusion and returns the visual to the eligible pool when it passes the remaining era, provenance, promotional, coherence, and weapon rules.
- The button tooltip now changes with its action: Favorite/Remove Favorite and Exclude/Allow.

The cause was a Lua pseudo-ternary that attempted to return `nil`. Because Lua's `and/or` expression falls through whenever the middle result is `nil`, the clearing path reapplied the original preference. v0.9.1 uses explicit branches and tests both directions of both controls.

## Preserved from v0.9.0

- expansion progression restriction;
- debounced automatic collection updates;
- stable-visual missing-appearance recovery;
- scan timing and performance diagnostics;
- extensive Classic-through-Midnight zone coverage;
- settings and high-contrast outfit states.

## Compatibility

- SavedVariables schema 2 is preserved.
- Courier format 1 is preserved.
- Wardrobe cache format 5 is preserved.
- Existing favorites and exclusions remain intact.
- No collection rescan is required.
- Preview only: no transmog is applied and no Blizzard outfit slot is changed.

See `ZONE_PREFERENCE_TOGGLE_V091_TEST_CHECKLIST.md` for the live verification pass.
