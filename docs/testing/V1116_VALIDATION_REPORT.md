# Quest Chronicle v1.11.6 Validation Report

## Release purpose

Guarantee persistence of valid oversized diagnostic reports through exact-size adaptive compaction without changing generation behavior or raising the persistence ceiling.

## Automated validation

```text
Lua regression tests:      97 / 97 PASS
Python static verifiers:   34 / 34 PASS
Runtime Lua syntax:       149 / 149 PASS
TOC runtime modules:      149 / 149 exactly once
Runtime Lua files >= 500:   0
ZIP integrity:              PASS
Fresh extraction:          PASS
```

## Automated coverage

The v1.11.6 fixture constructs:

- a multi-megabyte Zone report containing selected anchors, policy pools, affinity pieces, support ancestry, Phase D state, capability metrics, scheduler metrics, cache tables, and detailed phase timing;
- a pathological report with extremely large message, warning, policy, support, and timing branches;
- an artificially impossible ceiling to preserve visible final-rejection behavior.

The fixtures require:

- exact encoded final size at or below 20,480 bytes;
- retained Debug History entry;
- no rejection callback for valid oversized reports;
- preserved Zone policy, selected anchors, capability counters, scheduler integrity, support result, Phase D result, and skeleton identity;
- emergency or minimal stub persistence for pathological valid input;
- visible warning and callback only when even the minimal stub cannot fit.

The principal fixture begins at `8,147,167` serialized bytes and persists at `13,787` bytes through `EMERGENCY_STUB`.

## Runtime boundary

```text
v1.11.5 runtime modules: 148
Byte-identical modules:  144
Changed existing:          4
New runtime modules:       1
Removed modules:           0
v1.11.6 runtime modules: 149
```

## Package status

```text
Worktree automated validation: PASS
Exact-ZIP validation:          PASS
Retail adaptive persistence:   Pending
Zone policy export lineage:    Pending reconfirmation
Cold/warm performance closure: Pending
```
