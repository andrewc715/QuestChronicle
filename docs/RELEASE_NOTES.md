# Quest Chronicle v1.9.0.12

## Scheduler and Diagnostics Closure

Quest Chronicle now ends a cooperative slice immediately after expensive work, reserves frame time before every phase transition, captures generation-cache diagnostics from constant-time scalar ledgers, and decomposes full-generation setup into resumable stages.

- Enforces immediate post-operation yielding after calls at or above the expensive-call threshold.
- Prevents workers from beginning a new phase when the remaining frame allowance cannot cover that phase's reservation.
- Records expensive-call yields, prevented phase transitions, slice debt, and post-expensive-call continuations.
- Replaces generation-time cache aggregation with an immutable scalar snapshot backed by incrementally maintained evidence, precheck, and eligibility counters.
- Splits full-generation Setup into action identity, state snapshot, mode context, context seeding, eligibility context, novelty reference, cache snapshot, and weapon-index snapshot stages.
- Adds adaptive batching with a 32-operation fast lane for consistently cheap cached work and immediate single-operation fallback after expensive work.
- Reports weapon-index state before and after each action, action-local buckets built, repaired, and reused, action-local examined sources and yields, lifetime totals, and canonical invalidation reasons.
- Corrects bucket-repair bookkeeping so incremental repair is recorded when the bucket is actually rebuilt.
- Preserves v1.9.0.11 anchor, weapon, support, contextual-reroll, profile, mismatch, and outfit-name selections for identical seeds and state.
- Keeps SavedVariables schema 2, Courier format 1, wardrobe cache format 7, generation-cache store 2, diagnostic format 1, and weapon-index format 1 unchanged.

The package is automated-validated and requires Retail validation before replacing v1.9.0.5 as the live baseline.
