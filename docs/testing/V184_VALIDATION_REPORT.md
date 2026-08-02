# Quest Chronicle v1.8.4 Validation Report

## Static structure

- Addon version: 1.8.4
- SavedVariables schema: 2
- Courier format: 1
- Wardrobe cache format: 7
- Runtime Lua modules: 36
- Lua files over 500 lines: 0
- Largest runtime Lua file: 474 lines
- Orphaned normalized private-helper calls: 0

## Focused era-evidence regression

The mock suite verified:

- item 89565 resolves to Mists of Pandaria through the reviewed correction path;
- a visual can resolve its era from a non-representative sibling source;
- weak item-era evidence fails closed while another sibling remains pending;
- pending item data is explicitly requested from Blizzard;
- once all siblings are known, the earliest verified visual era is retained;
- Mists of Pandaria evidence is rejected by a Burning Crusade era cap.

## Cache migration

Static validation confirmed:

- `Wardrobe.CACHE_VERSION` is 7;
- a format mismatch clears the old appearance cache and marks it for the normal session scan;
- the migration does not alter SavedVariables schema 2 or Courier format 1;
- the TOC loads appearance-manifest support before collection scanning and era evidence before scoring.

## Package validation

- All Lua modules compile with the available Lua parser.
- Every TOC runtime path exists.
- JSON documents parse successfully.
- Version metadata is consistent.
- ZIP integrity passes.
