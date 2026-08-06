# Quest Chronicle v1.11.0 Automated Validation

## Validation environment

The v1.11.0 worktree was created directly from the live-validated v1.10.0 ZIP whose SHA-256 is:

```text
0120a5805726c6d55629d3cc12dab84fac1159d8ab1ab495cf7c97741b888511
```

## Executable Lua regression suite

```text
80 / 80 tests passed
```

The inherited v1.10.0 suite remains green. New v1.11.0 suites cover:

```text
test_zone_registry_v1110.lua
test_zone_context_snapshot_v1110.lua
test_zone_affinity_v1110.lua
test_zone_mode_adapter_v1110.lua
test_zone_suggestion_parity_v1110.lua
test_zone_report_format_v1110.lua
```

Headline results:

```text
Registries: 25 profiles, 134 provenance pools, 30 starting-zone cases
Snapshot: deterministic identity, evidence, cache isolation, and starting-zone parity
Affinity fixture: native 0.893 > foreign 0.112
Adapter: LEGACY with CONTEXT_EVIDENCE_V1 read-only providers
Suggestion lifecycle: no duplicates and clean reload reconstruction
Reports: additive foundation, parity, evidence, and affinity sections
```

## Python static verifiers

```text
28 / 28 verifiers passed
```

The new `verify_zone_context_foundation_v1110.py` performs 17 dedicated checks, including:

- exact version and TOC wiring;
- registry module and count presence;
- legacy implementation identity;
- secondary foundation identity;
- no `math.random()` in Zone foundation modules;
- no canonical Zone evidence read from the legacy scoring path;
- diagnostic command and report integration;
- line-limit and module-boundary checks.

## Runtime syntax

```text
138 / 138 runtime Lua files parsed successfully
```

## File and TOC hygiene

```text
Runtime TOC modules: 138
Listed exactly once: 138
Missing runtime modules: 0
Duplicate TOC entries: 0
Runtime Lua files at or above 500 lines: 0
Largest runtime Lua file: Core/ZoneStyle/SourceMetadata.lua, 499 lines
```

## Cross-version runtime diff

Against the 125 runtime Lua modules in v1.10.0:

```text
Byte-identical original modules: 120
Changed original modules:          5
Removed original modules:          0
New runtime modules:              13
Current runtime modules:          138
```

Changed existing modules are limited to version metadata, slash-command routing, additive diagnostic snapshot/formatting, and the Zone legacy adapter.

## Automated result

```text
Automated validation: PASS
Exact-ZIP revalidation: PASS
Package readiness: PASS
Retail validation: Pending
```
