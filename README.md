# Quest Chronicle v1.11.9

Quest Chronicle v1.11.9 repairs the cooperative era-evidence execution boundary exposed by the v1.11.8 Retail watchdog failure. Cooperative generation now owns nested era work explicitly, synchronous compatibility getters cannot defer, and cached/raw eligibility no longer trigger synchronous era resolution while a generation scheduler is active.

## v1.11.9 focus

- Explicit era execution modes: generation cooperative, support-reroll cooperative, background tick, and synchronous.
- Cached eligibility resolves missing era evidence through resumable nested work before constructing its cache key.
- Raw eligibility uses ERA_INIT / ERA_STEP / ERA_APPLY rather than the synchronous era getter.
- Weapon style ordering passes its generation scheduler owner into cached eligibility, eliminating the v1.11.8 Anchor Weapons busy-spin route.
- The synchronous era getter uses the same evidence state machine in non-deferring mode with a forward-progress watchdog guard.
- Background reevaluation is isolated from ambient foreground generation slices.
- Debug diagnostics expose deferred returns, same-slice retries, synchronous guard trips, and execution mode.

## Architecture identity

Traveler remains `SHARED_FRAMEWORK`. Zone Native remains `LEGACY` with `CONTEXT_EVIDENCE_V1`, authoritative `ZONE_ANCHOR_POLICY_V1`, and legacy support policy. Class Fantasy and Chronicle Echo remain `LEGACY`. Scheduler budgets, scoring coefficients, evidence formats, cache formats, random consumption, legal weapon routes, locks, hidden slots, contextual support, and Phase D behavior remain unchanged.

Retail validation is required before v1.11.9 becomes the accepted Zone anchor-policy baseline.
