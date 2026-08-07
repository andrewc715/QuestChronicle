# Quest Chronicle v1.11.10 Productive Scheduling Closure

## Purpose

v1.11.10 closes the two scheduling defects exposed by v1.11.9 Retail validation without changing Zone scoring or selection semantics:

1. cooperative era work paid a fresh-frame tax before stages that frequently performed no Blizzard API work; and
2. contextual-support candidate scoring still executed neighbor, bridge, budget, and final arithmetic as one monolithic beam operation.

The release changes when work receives scheduler time, not which candidate wins.

## Era admission contract

Era work now classifies its next operation as one of:

- `LOCAL`
- `API_HEADROOM`
- `FRESH_ONLY`
- `COMPLETE`

Stable source-cache hits, stable fragment-cache hits, curated/local transitions, unavailable API branches, and other non-API stages execute locally. `API_HEADROOM` is requested only when the next step will actually cross a variable API boundary.

The initial API reserve is 3.0 ms. This does not alter the scheduler budgets: 5.5 ms preferred, 7.5 ms soft, and 2.0 ms expensive-call force-yield remain frozen.

An admitted API call that actually exceeds the 2.0 ms expensive-call threshold still forces the current slice to end.

## Productive-deferral invariants

A valid v1.11.10 action must satisfy:

- zero same-slice era `DEFERRED` retries;
- zero synchronous progress-guard trips;
- zero phantom era deferrals;
- zero era API deferrals when era API work is zero;
- cache-only era completions do not consume API admission;
- admission denial leaves the era work item unchanged.

## Resumable support candidate contract

`Core/Wardrobe/SupportCandidateWork.lua` decomposes the existing candidate scorer into bounded stages:

- `INIT`
- `NEIGHBOR_SOURCE`
- `NEIGHBOR_PAIR`
- `NEIGHBOR_FINALIZE`
- `BRIDGE_SOURCE`
- `BRIDGE_PAIR`
- `BRIDGE_BEFORE`
- `BRIDGE_FINALIZE`
- `BUDGET`
- `SCORE`
- `COMPLETE`

Only one neighbor or bridge relationship is processed per step. Partial candidate work cannot mutate `nextBeam`, consume a completed expansion, or alter the selected support state. The synchronous `ScoreSupportCandidate` function remains the parity oracle.

Fallback selection uses the same resumable worker and preserves the existing strict-lower first-best tie rule.

## Automated closure evidence

The dedicated v1.11.10 fixtures prove:

- local and cache-only era paths pay no API admission tax;
- multiple cheap API operations can share one slice when headroom exists;
- insufficient headroom defers without mutating work;
- an admitted 2.2 ms API call triggers force-yield;
- support decisions match the synchronous oracle across support slots;
- partial candidate work cannot commit to the beam;
- fallback tie behavior is unchanged;
- a synthetic 768-candidate support workload peaks at 0.750 ms per candidate substep, below the 4.0 ms target.

## Retail closure

Retail remains authoritative for latency. v1.11.10 is accepted only when the cold generation and all three consecutive warm rerolls satisfy both worker-slice and end-to-end duration gates defined in `V11110_LIVE_VALIDATION_STEPS.md`.
