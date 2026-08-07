# Quest Chronicle v1.11.7 Automated Validation

## Exact worktree gate

```text
Lua regression tests:      100 / 100 PASS
Python static verifiers:    35 / 35 PASS
Runtime Lua modules:       149
TOC entries:               149 exactly once
Runtime Lua files >=500:     0
```

## New executable coverage

### Cooperative eligibility parity

```text
Marker batch: 4
Eligibility steps: 32
Eligibility continuations: 16
Cache completions: 8
Computed completions: 8
Synchronous and cooperative selected appearances: identical
```

### Resumable fallback and fresh-stage admission

The fixture proves:

- one fallback candidate is evaluated per operation;
- strict-lower replacement preserves the first candidate on an exact mismatch tie;
- a used slice defers stage finalization without mutating beam state;
- the next fresh slice performs the same finalization;
- specific and compatibility timing identities are both retained.

### Worst-case stage finalization

```text
Input nodes: 768
Frozen retained width: 24
Latest measured maximum: 0.608 ms
Contingency trigger: 7.5 ms
Result: cooperative-finalization contingency not required
```

### Adaptive persistence

```text
Worst-case original: 8,147,558 bytes
Emergency retained: 14,178 bytes
Realistic policy report retained: 17,687 bytes
Persistence ceiling: 20,480 bytes
Support scheduling core retained through compaction
```

## Inherited coverage

All inherited tests for Traveler parity, Zone policy scoring, candidate eligibility, anchor search, weapon routes, capability snapshots, contextual support, fallback behavior, Phase D validation and repair, rerolls, locks, hidden slots, cache lifecycle, report persistence, export lineage, and numeric versioning passed unchanged.

Retail timing remains the final validation gate.
