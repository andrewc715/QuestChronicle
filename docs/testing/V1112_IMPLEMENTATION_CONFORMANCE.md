# Quest Chronicle v1.11.2 Implementation Conformance

## Architecture contract

v1.11.2 implements the approved diagnostic-correctness plan without beginning Zone selection modernization.

```text
Zone Context Snapshot: 1
Zone foundation: CONTEXT_EVIDENCE_V1
Zone affinity: 2
Zone debug export: 2
Zone Native implementation: LEGACY
```

## Export boundary

`Core/ZoneStyle/Zone/ExportEncoding.lua` owns `DIAGNOSTIC_ESCAPE_V1` and has no UI, generation, cache, SavedVariables, or Courier dependencies.

Dynamic values encode:

```text
backslash       → \\
pipes           → \u007C
backticks       → \u0060
carriage return → \r
line feed       → \n
```

The generic Debug Workbench copy dialog remains unchanged in responsibility and receives already-safe Zone export text.

## Affinity boundary

Affinity format 2 adds:

```text
componentStatus
notApplicableChannels
```

Each component is explicitly `VALUE`, `MISSING`, or `NOT_APPLICABLE`. Existing numeric calculations, weights, confidence formulas, thresholds, and classifications remain frozen.

Format-1 records are normalized at read time and are not migrated in place.

## Selection neutrality

Static and executable guards confirm that the correction path:

- makes zero random calls;
- enumerates no generation candidates;
- invokes no generation or reroll action;
- does not mutate preview state;
- does not write SavedVariables or Courier data;
- does not promote Zone Native to the shared framework.

## Result

```text
Implementation conformance: PASS
Retail validation: Pending
```
