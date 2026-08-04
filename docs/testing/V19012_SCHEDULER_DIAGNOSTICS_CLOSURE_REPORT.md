# Quest Chronicle v1.9.0.12 Scheduler and Diagnostics Closure Report

## Scope

This release changes execution timing and diagnostic capture only. It does not change Phase B anchor scoring, weapon-route semantics, Phase C support scoring, mismatch allowances, bridge bonuses, shortlist sizes, seeded selection, or outfit naming.

## Scheduler closure

The shared slice budget now records an immediate force-yield after calls at or above 2.0 ms and blocks phase transitions when the remaining preferred allowance cannot cover the phase reservation. Scheduler snapshots track expensive-call yields, prevented transitions, phase-transition yields, post-expensive-call continuations, and maximum slice debt.

Adaptive batches use levels `1, 2, 4, 8, 16, 32`. Two consecutive very cheap batches may raise the level, while calls above 1 ms reduce it and calls at or above 2 ms collapse the next batch to one operation and end the slice.

## Constant-time cache diagnostics

`GenerationCacheCounters.lua` maintains current evidence, precheck, and eligibility totals as cache mutations occur. Generation and reroll workers copy those totals and existing session counters rather than walking persistent cache records. A compatibility fallback remains for isolated legacy harnesses that do not load the counter module.

The dedicated scalar test rejects any unexpected full recount and verifies immutable invalidation-reason copies and exact during-generation deltas.

## Cooperative full-generation setup

The former Setup operation is divided into:

```text
Generation action identity
Generation state snapshot
Generation mode context
Generation context seed
Generation eligibility context
Generation novelty reference
Generation cache scalar snapshot
Generation weapon-index snapshot
```

The worker-local draft and state signature are complete before anchor work begins. No report text or candidate arrays are built during setup.

## Weapon-index action diagnostics

Weapon index format 1 now reports before/after state, action classification, buckets built/repaired/reused, examined sources and yields for the current action, lifetime totals, and canonical invalidation reasons. Bucket repair counts increment when the rebuild completes rather than when invalidation is queued.

Automated action sequence:

```text
Cold build: explicit LOGIN_SESSION_RESET, one bucket built, action-local examination and yields
Warm reuse: one bucket reused, zero action-local examination and yields
Incremental repair: one bucket repaired, ELIGIBILITY_OUTCOME_CHANGED preserved
```

## Synthetic results

```text
6,000 candidates + 100 cooperative era siblings: 19 frames, 5.60 ms maximum slice
3,256 cached candidates + 120 weapon yields: 16 frames, 5.60 ms maximum slice
3,256 post-reload persistent candidates: 14 frames, 5.60 ms maximum slice
360 ordinary candidates: 4 frames, 2.88 ms maximum slice
256 support candidates + 5,408 expansions: 82 frames, 2.55 ms maximum slice
```

All synthetic maximum slices remained below the 8 ms hard gate.
