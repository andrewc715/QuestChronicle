# Quest Chronicle v1.11.2 Automated Validation

## Reference baseline

Quest Chronicle v1.11.2 was built directly from the final v1.11.1 package whose SHA-256 is:

```text
e730107ff53e81aceab876fe054796ca9dc62df5134ca086ea492647e5a03413
```

## Executable Lua regression suite

```text
85 / 85 tests passed
```

The inherited 82-test suite remains green. New tests are:

```text
test_zone_export_encoding_v1112.lua
test_zone_affinity_applicability_v1112.lua
test_zone_debug_export_v1112.lua
```

They verify reversible diagnostic encoding, unsafe WoW control-token removal, tri-state affinity applicability, format-1 normalization, exact v1 arithmetic parity, and the frozen Netherstorm Retail fixture.

## Python static verifiers

```text
30 / 30 verifiers passed
```

The new `verify_zone_diagnostic_fidelity_v1112.py` checks format identities, TOC wiring, serializer ownership, tri-state status fields, report persistence, format-1 compatibility helpers, legacy Zone identity, selection neutrality, and generic copy-dialog separation.

## Runtime syntax and hygiene

```text
141 / 141 runtime Lua modules parsed successfully
141 / 141 TOC modules listed exactly once
0 runtime Lua files at or above 500 lines
Largest runtime Lua file: Core/ZoneStyle/SourceMetadata.lua, 499 lines
```

## Automated result

```text
Automated validation: PASS
Package readiness: PASS
Retail validation: Pending
```
