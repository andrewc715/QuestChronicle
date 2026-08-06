# Quest Chronicle v1.11.1 Automated Validation

## Reference baseline

Quest Chronicle v1.11.1 was built directly from the package-ready v1.11.0 worktree. The release changes only version metadata, command routing, the shared copy dialog surface, and two new Zone export modules.

## Executable Lua regression suite

```text
82 / 82 tests passed
```

The inherited 80-test v1.11.0 suite remains green. New tests are:

```text
test_zone_debug_export_v1111.lua
test_zone_debug_export_command_v1111.lua
```

They verify:

- all four generation architecture identities;
- `CONTEXT_EVIDENCE_V1` foundation identity;
- complete untruncated evidence ancestry;
- current-look and per-piece affinity details;
- latest Zone Native report lookup;
- preservation of compact `/qc zone debug` routing;
- copy-dialog routing for `/qc zone debug export`;
- confirmation counters for evidence entries and selected pieces.

## Python static verifiers

```text
29 / 29 verifiers passed
```

The new `verify_zone_debug_export_v1111.py` checks:

- numeric v1.11.1 metadata;
- exact TOC wiring;
- slash-command help and delegation;
- copy-dialog integration;
- architecture, evidence, affinity, and report sections;
- no SavedVariables or Courier storage;
- no random calls;
- no generation or reroll invocation.

## Runtime syntax and hygiene

```text
140 / 140 runtime Lua modules parsed successfully
140 / 140 TOC modules listed exactly once
0 runtime Lua files at or above 500 lines
Largest runtime Lua file: Core/ZoneStyle/SourceMetadata.lua, 499 lines
```

## Automated result

```text
Automated validation: PASS
Package readiness: PASS
Retail validation: Pending
```
