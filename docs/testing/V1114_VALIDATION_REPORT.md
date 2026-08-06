# Quest Chronicle v1.11.4 Validation Report

## Release purpose

Restore Debug History persistence for Zone Native generation and reroll actions after v1.11.3 Zone policy diagnostics exceeded the report ceiling.

## Automated validation

```text
Lua regression tests:      93 / 93 PASS
Python static verifiers:   32 / 32 PASS
Runtime Lua syntax:       146 / 146 PASS
TOC runtime modules:      146 / 146 exactly once
Runtime Lua files >= 500:   0
```

## Reproduced defect

A realistic v1.11.3-shaped Zone report returned:

```text
nil
Diagnostic report remained above the persistence limit after compaction.
```

## Corrected result

The same report shape now persists at approximately 17 KB after policy-aware compaction.

Retained:

- authoritative Zone policy summary;
- five selected anchor rows;
- candidate-pool summaries;
- pair support;
- route and weapon deduplication;
- support profile entries;
- Phase D result;
- `REPORT_TRIMMED` warning.

Removed:

- duplicate component policy tables;
- duplicate persisted affinity-piece ledger.

## Rejection visibility

A deliberately uncompactable report now:

- returns the existing rejection reason;
- prints a visible `Debug report could not be saved` message;
- emits `DIAGNOSTIC_REPORT_REJECTED`;
- increments the discard counter.

## Cross-version scope

```text
142 inherited runtime modules byte-identical
3 inherited runtime modules changed
1 runtime module added
0 runtime modules removed
```

## Result

```text
Automated validation: PASS
Package readiness: PASS
Exact-ZIP validation: PASS
Retail validation: Pending
```
