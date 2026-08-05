# Quest Chronicle v1.9.0.14 Behavior-Parity Report

## Scope

v1.9.0.14 changes only the Traveler pipeline after Phase C has selected a complete support configuration. The clean path must preserve v1.9.0.13 anchor, weapon, support, score, route, lock, hidden-slot, random-selection, scheduler, and atomic-commit behavior.

## Shared harness comparison

The 58 Lua harnesses shared by the untouched v1.9.0.13 tree and the v1.9.0.14 tree were executed from their respective roots.

```text
58 shared harnesses executed successfully
54 outputs matched byte for byte
1 benchmark differed only in measured execution time
3 diagnostics-size outputs changed intentionally for additive Phase D reporting
0 selection, score, route, budget, or scheduler semantic differences
```

Intentional differences:

- `test_anchor_novelty_benchmark.lua`: wall-clock benchmark variance only
- `test_contextual_support_diagnostics.lua`: additive `Final validation: CLEAN` reporting
- `test_contextual_support_report_size.lua`: maximum-detail Phase D formatter fixture
- `test_contextual_support_snapshot_size_v199.lua`: maximum-detail Phase D persisted snapshot fixture

## New Phase D coverage

Four new Lua harnesses cover:

- threshold boundaries and locked sovereignty;
- clean-worker selection parity;
- deterministic one-pass and two-pass repair;
- hard two-pass exhaustion and alternate request;
- alternate-skeleton novelty and quality-window ordering.

A new static verifier guards load order, constants, deterministic repair, pool reuse, reroll isolation, diagnostics, and alternate-skeleton wiring.
