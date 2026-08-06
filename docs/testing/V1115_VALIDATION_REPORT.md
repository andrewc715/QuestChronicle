# Quest Chronicle v1.11.5 Validation Report

## Release purpose

Correct Zone policy-report lineage and remove the remaining structural cooperative weapon-path overages without changing selection semantics.

## Automated validation

```text
Lua regression tests:      96 / 96 PASS
Python static verifiers:   33 / 33 PASS
Runtime Lua syntax:       148 / 148 PASS
TOC runtime modules:      148 / 148 exactly once
Runtime Lua files >= 500:   0
```

## Export-lineage result

Synthetic newest-first histories verify that:

- the newest Zone Native report can be a legacy individual reroll;
- the newest structurally valid policy-bearing report is selected independently;
- malformed newer policy payloads are skipped;
- policy source ID, action, result, lineage, and snapshot remain report-local;
- format-4 empty-history states are distinct and explicit.

## Cooperative ordering result

Fixed-stream fixtures verify:

- marker batch 4;
- multi-step eligibility yields before completion;
- one coherence call after eligibility;
- no random consumption during eligibility;
- one random draw per retained candidate;
- exact retained IDs, priorities, sorted order, and route-facing output.

## Capability snapshot result

Fixtures verify:

- first request builds at most once;
- later contexts in the action reuse the same generation;
- explicit route invalidation clears the session snapshot and increments generation;
- stale generation blocks commit atomically;
- the next request rebuilds once and later work reuses it.

## Cross-version scope

```text
133 inherited runtime modules byte-identical
13 inherited runtime modules changed
2 runtime modules added
0 runtime modules removed
```

## Result

```text
Automated validation: PASS
Package readiness: PASS
Exact-ZIP validation: PASS
Retail lineage validation: Pending
Retail cold/warm performance closure: Pending
```
