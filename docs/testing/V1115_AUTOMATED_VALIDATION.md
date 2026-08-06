# Quest Chronicle v1.11.5 Automated Validation

## Reference baseline

Quest Chronicle v1.11.5 was built directly from the Retail-validated v1.11.4 package:

```text
d4829fd2ac476e47c0d12ebcf89fdf5cb2a806d6d21c08cee0884e2ae5adab2c
```

## Lua regression suite

```text
96 / 96 tests passed
```

The 93 inherited tests remain green. Three new executable fixtures are:

```text
test_zone_debug_export_lineage_v1115.lua
test_weapon_style_ordering_v1115.lua
test_weapon_capability_snapshot_v1115.lua
```

They verify independent report lineage, malformed-policy filtering, format-4 empty-history behavior, bounded marker batches of four, exact retained candidate and random parity, one capability build per action, warm reuse, explicit invalidation, and stale-at-commit cancellation.

## Python static verifiers

```text
33 / 33 verifiers passed
```

The new `verify_zone_anchor_closure_v1115.py` checks numeric version metadata, format 4, independent report selectors, capability-cache invalidation, bounded eligibility ownership, removal of synchronous cached eligibility from the weapon ordering function, frozen Zone policy constants, legacy support-policy identity, and the runtime file-size limit.

## Runtime syntax and hygiene

```text
148 / 148 runtime Lua modules parsed successfully
148 / 148 TOC modules listed exactly once
0 runtime Lua files at or above 500 physical lines
Largest runtime Lua files: Core/ZoneStyle/SourceMetadata.lua and Core/Wardrobe/GenerationWorker.lua, 499 lines
```

## Cross-version runtime boundary

```text
v1.11.4 runtime modules: 146
Byte-identical modules:  133
Changed existing:         13
New runtime modules:       2
Removed runtime modules:   0
v1.11.5 runtime modules: 148
```

New modules:

```text
Core/Wardrobe/WeaponCapabilitySnapshot.lua
Core/Wardrobe/WeaponStyleOrdering.lua
```

## Automated result

```text
Automated validation: PASS
Worktree package readiness: PASS
Exact-ZIP validation: PASS
Retail performance closure: Pending
```
