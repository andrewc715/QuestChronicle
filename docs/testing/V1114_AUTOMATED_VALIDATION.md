# Quest Chronicle v1.11.4 Automated Validation

## Reference baseline

Quest Chronicle v1.11.4 was built directly from the v1.11.3 package:

```text
d5f88168d5c8f0a9da901e1174e5c983e91a2dde30c76a002c341817a47cf721
```

## Lua regression suite

```text
93 / 93 tests passed
```

The 91 inherited tests remain green. Two new tests are:

```text
test_zone_report_persistence_v1114.lua
test_diagnostic_rejection_visibility_v1114.lua
```

They verify realistic Zone report retention, policy-aware duplicate removal, selected policy preservation, support ancestry, Phase D retention, compaction warnings, visible rejection messages, callback emission, and rejection counters.

## Python static verifiers

```text
32 / 32 verifiers passed
```

The new `verify_zone_report_persistence_v1114.py` checks the numeric version, TOC order, policy-summary ownership, duplicate-removal boundaries, retained support and Phase D data, visible failure path, new executable fixtures, and frozen 20,480-byte ceiling.

## Runtime syntax and hygiene

```text
146 / 146 runtime Lua modules parsed successfully
146 / 146 TOC modules listed exactly once
0 runtime Lua files at or above 500 physical lines
Largest runtime Lua file: Core/ZoneStyle/SourceMetadata.lua, 499 lines
```

## Cross-version runtime boundary

```text
v1.11.3 runtime modules: 145
Byte-identical modules:  142
Changed existing:          3
New runtime modules:       1
Removed runtime modules:   0
v1.11.4 runtime modules: 146
```

Changed existing modules:

```text
Core/Chronicle/Foundation.lua        version fallback only
Core/Diagnostics/History.lua         delegate compaction and surface rejection
Core/ZoneStyle/Zone/DebugExport.lua  version-neutral no-report wording
```

New module:

```text
Core/Diagnostics/ReportCompaction.lua
```

All generation-facing v1.11.3 Zone policy, beam, support, repair, reroll, weapon, scheduler, and Traveler modules remain byte-identical.

## Automated result

```text
Automated validation: PASS
Worktree package readiness: PASS
Exact-ZIP validation: PASS
Retail validation: Pending
```
