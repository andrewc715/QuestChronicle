# Quest Chronicle v1.11.6 Implementation Conformance

## Approved scope

```text
Adaptive diagnostic compaction
Mandatory-core report retention
Emergency/minimal persistence stubs
Exact serialized-size telemetry
Worst-case persistence fixtures
```

## Conformance

- The 20,480-byte report ceiling is unchanged.
- Diagnostic format remains 1.
- Adaptive compaction is isolated to `Core/Diagnostics`.
- The emergency builder is loaded before report compaction.
- History invokes the emergency fallback during insertion and pruning.
- The formatter exposes tier, original bytes, final bytes, and emergency state.
- Valid oversized reports are retained before the final rejection guard is considered.
- Generation-facing runtime modules remain unchanged from v1.11.5 except version metadata.

## Explicit non-goals

- no Zone policy tuning;
- no performance-budget increase;
- no reroll modernization;
- no data migration;
- no UI redesign;
- no cache reset;
- no Courier change.
