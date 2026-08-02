# Quest Chronicle v1.8.4: Era Evidence Rebuild

Version 1.8.4 replaces the representative-item-only era shortcut with a provenance-bearing evidence resolver and advances the wardrobe cache format from 6 to 7. The cache migration deliberately forces one complete wardrobe rebuild after login or `/reload`.

## Live regressions addressed

Two Mists of Pandaria belt appearances were admitted into an Outland generation pool:

- Green Belt of Quiet Understanding, item 89561
- Biting Yellow Belt, item 89565

Both displayed `Era eligible` because older cache records either carried stale era metadata or lacked enough source evidence and were treated as safe.

## New era evidence model

Each collapsed visual now records all source IDs exposed by Blizzard rather than only the currently selected representative source. Quest Chronicle can establish an era from:

1. reviewed exact-source corrections for confirmed legacy metadata defects;
2. native transmog-set expansion metadata;
3. Blizzard appearance-tracking map provenance;
4. encounter-journal source and tier text;
5. item expansion metadata for every available visual sibling.

The chosen conclusion stores its expansion, method, source ID, item ID, and number of source candidates examined. Tooltips can therefore explain how the era was established instead of merely saying `Era eligible`.

## Fail-closed behavior

Unknown, unverified, or partially loading era evidence is excluded from automatic generation until Blizzard finishes supplying the required data. The appearance remains browseable and manually previewable.

A weak item-only conclusion is not cached while another visual sibling is still loading potentially stronger source evidence.

## Cache migration

- Wardrobe cache format: **6 → 7**
- SavedVariables schema: **2**, unchanged
- Courier format: **1**, unchanged

The v1.8.4 cache migration clears and rebuilds only the wardrobe appearance cache. It preserves Chronicle history, active quests, notes, settings, outfit concepts, appearance locks, hidden slots, Custom Set links, and current selections.

Quest Chronicle retains the deliberate refresh policy: the migration produces the normal single automatic wardrobe scan after login or `/reload`; later collection changes only mark the cache stale until **Scan Collection** is clicked.

## Normalization policy

The new logic remains split across focused modules:

- `Core/Wardrobe/AppearanceMetadata.lua`
- `Core/ZoneStyle/EraEvidence.lua`

Every runtime Lua file remains at or below 500 physical lines.
