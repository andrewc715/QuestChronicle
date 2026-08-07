# Quest Chronicle v1.11.9 Era Execution-Boundary Contract

## Purpose

v1.11.9 corrects the v1.11.8 Retail watchdog failure in which cooperative era work returned `DEFERRED` to a synchronous drain that immediately retried the same operation without returning to WoW.

## Execution modes

- `GENERATION_COOPERATIVE`: may defer and owns a generation scheduler job.
- `SUPPORT_REROLL_COOPERATIVE`: may defer and owns the modern support-reroll scheduler job.
- `BACKGROUND_TICK`: performs bounded work per callback and ignores unrelated foreground slice state.
- `SYNCHRONOUS`: never defers and must prove forward progress on every source-era step.

## Hard invariants

A cooperative `DEFERRED` return may not advance eligibility, scoring, random consumption, cache identity, or source-era progress. The caller must return to its scheduler before trying that work again.

Synchronous era resolution uses the same evidence state machine but bypasses fresh-slice deferral. Every loop iteration must advance `progressSerial` or complete. A no-progress result aborts safely as pending and increments the synchronous progress-guard counter.

## Eligibility boundary

Cached eligibility no longer computes era evidence in its constructor. Missing evidence advances through `ERA_INIT` and `ERA_STEP` before `CACHE_KEY` and `CACHE_LOOKUP`.

Raw eligibility similarly advances through `ERA_INIT`, `ERA_STEP`, and `ERA_APPLY`. Cooperative raw eligibility never calls `GetSourceEraEvidence()`.

## Watchdog counters

Expected Retail values:

- same-slice deferred retries: `0`
- synchronous progress-guard trips: `0`
- post-expensive continuations: `0`

Any nonzero same-slice retry or synchronous guard trip rejects the release.
