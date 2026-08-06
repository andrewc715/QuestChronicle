# Quest Chronicle v1.11.2 Validation Report

## Release purpose

Quest Chronicle v1.11.2 corrects Zone debug copy fidelity and per-component applicability semantics while preserving all Zone Native selection behavior.

## Automated validation

```text
Executable Lua regression tests: 85 / 85 PASS
Python static verifiers:          30 / 30 PASS
Runtime Lua syntax:              141 / 141 PASS
TOC runtime modules:             141 / 141 exactly once
Runtime Lua files >= 500 lines:    0
```

Largest runtime Lua file:

```text
Core/ZoneStyle/SourceMetadata.lua
499 physical lines
```

## Cross-version boundary

Compared with v1.11.1:

```text
Existing runtime modules:        140
Byte-identical modules:          135
Changed existing modules:          5
New runtime modules:               1
Removed runtime modules:           0
Current runtime modules:          141
```

## Corrective behavior

- Zone debug export format is 2.
- Zone affinity format is 2.
- Dynamic values use `DIAGNOSTIC_ESCAPE_V1`.
- Literal pipes use `\u007C` and cannot form WoW formatting tokens in the copy EditBox.
- Affinity components use `VALUE`, `MISSING`, or `NOT_APPLICABLE`.
- Not-applicable channels are excluded from score, confidence, and missing-channel warnings.
- The Netherstorm Retail fixture remains numerically identical to v1.11.1.
- Format-1 affinity records remain readable through display-time normalization.

## Compatibility

```text
SavedVariables schema:        2
Courier format:               1
Wardrobe cache:               7
Diagnostic format:            1
Zone Context Snapshot:        1
Zone foundation:              CONTEXT_EVIDENCE_V1
Zone Native implementation:   LEGACY
Traveler implementation:      SHARED_FRAMEWORK
```

## Result

```text
Automated validation: PASS
Exact-ZIP validation: PASS
Retail validation: Pending
```
