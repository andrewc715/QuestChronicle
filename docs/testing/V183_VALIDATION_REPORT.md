# Quest Chronicle v1.8.3 Validation Report

## Scope

This release changes only cached item-era metadata validation. Weapon Appearance Routes, preview rendering, Custom Sets, Chronicle recording, Courier export, and Heritage Armor rules are unchanged.

## Regression reproduced

The test source began with:

```text
itemID: 89561
cached expansionID: 0 (Classic)
verification marker: absent
```

The mocked current WoW item API returned expansion ID `4` for the same item. The patched loader replaced the stale value with `4`, recorded the verified representative item ID, and reused it only for that exact item.

## Additional cases

- Verified metadata for the same item is reused without another API request.
- Changing the source's representative item ID forces revalidation.
- Unavailable item data clears unverified era data, requests item loading, and returns no era.
- Unknown era therefore remains excluded from automatic generation until verified.

## Structural validation

```text
Runtime Lua files: 34
Files over 500 lines: 0
Largest Lua file: 474 lines
Orphaned split-helper calls: 0
```

All runtime Lua files passed syntax loading. TOC paths, JSON, version metadata, and ZIP integrity were validated.
