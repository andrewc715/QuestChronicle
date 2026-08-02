# Quest Chronicle v1.9.0a3 Validation Report

## Scope

v1.9.0a3 removes a blocking Blizzard API call from foreground wardrobe actions. It does not alter Traveler scoring, outfit selection, route construction, collection validation, or cache data.

## Root-cause verification

The v1.9.0a2 runtime contained three calls to `C_TransmogCollection.UpdateUsableAppearances()`:

```text
Core/Wardrobe/CollectionScanAndPreview.lua
Core/Wardrobe/WeaponFilters.lua
Core/Wardrobe/Events.lua
```

The first ran before the cooperative collection worker started. The second ran on every outfit generation while creating the weapon context. The third ran on equipment, specialization, talent-group, and trait changes.

All three calls were removed. Equipment and specialization events still invalidate the route cache and query live weapon capabilities immediately and after the existing 0.25-second settling delay.

## Static blocking-call guard

`tools/verify_no_blocking_usability_refresh.py` scans every runtime Lua module. Result:

```text
PASS: no runtime Lua calls C_TransmogCollection.UpdateUsableAppearances.
```

## Existing performance harness

The v1.9.0a2 cooperative scanner harness remains green:

```text
Representative item queries: 250
Eager sibling requests: 0
Worker steps for 103 visuals: 6
Returned visuals: 103
```

## Traveler calibration regression

The calibrated Traveler harness remains green. Linked weapons collapse into one block, strong echo support is free, and isolated loud accents remain postal-code outliers. No instrumentation formulas changed.

## Structural validation

```text
Lua syntax: PASS
Lua files checked: 43
Lua files over 500 lines: 0
Largest Lua file: 479 lines
Orphaned private helpers: 0
Blocking usability refresh calls: 0
TOC paths: PASS
JSON: PASS
ZIP integrity: PASS
```

## Live-client gate

The local checks prove the synchronous global recalculation is absent. Retail testing must confirm Generate Outfit, Scan Collection, and equipment/spec refreshes no longer produce multi-second client lockups.
