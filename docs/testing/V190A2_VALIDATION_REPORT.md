# Quest Chronicle v1.9.0a2 Validation Report

## Scope

v1.9.0a2 is a performance and scheduling repair. It does not change Traveler cohesion formulas, outfit generation, wardrobe eligibility, era evidence decisions, or weapon routes.

## Root-cause verification

The v1.9.0a1 login path was confirmed to perform a full `RebuildAppearanceMetadataIndex()` over the existing cache immediately on `PLAYER_ENTERING_WORLD`, followed by the automatic collection scan, followed by another full index rebuild after the scan.

That pre-scan call was removed. The completed scan now finalizes sorting and retains the watch index it built while discovering sources rather than hydrating the entire cache again.

## Metadata request harness

`tools/test_wardrobe_login_performance.lua` constructed 250 cached sources, each with three sibling item IDs.

Results:

```text
Representative GetItemInfo calls: 250
Sibling item requests during scan: 0
Item API calls while restoring watch index: 0
```

The broad sibling-source manifests remain attached to each appearance. Sibling item data is requested lazily by the era-evidence resolver when an appearance is actually evaluated.

## Cooperative scan harness

A mocked slot containing 103 collected appearances was processed with the production limits:

```text
Appearance batch: 18
Time budget: approximately 3 ms
Worker steps: 6
Returned visuals: 103
```

The worker preserved source validation, visual deduplication, sorting, and diagnostic totals while yielding between batches.

## Behavior parity

These validated generation files remain byte-for-byte identical to v1.8.5:

- `Core/Wardrobe/GenerationAndConcepts.lua`
- `Core/Wardrobe/WeaponSelection.lua`
- `Core/ZoneStyle/Scoring.lua`

All four Traveler instrumentation modules remain byte-for-byte identical to v1.9.0a1.

## Structural validation

```text
Runtime modules added: Core/Wardrobe/CollectionScanWorker.lua
Lua syntax: PASS
Lua files over 500 lines: 0
Largest Lua file: 479 lines
Orphaned private helpers: 0
TOC paths: PASS
JSON: PASS
Traveler calibration harness: PASS
Wardrobe performance harness: PASS
```

## Live-client gate

The local harness proves duplicate work and long synchronous loops were removed. Actual frame responsiveness and scan duration still require the Retail login and `/reload` checks in the accompanying checklist.
