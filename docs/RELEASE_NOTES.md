# Quest Chronicle v1.9.0.11

## Final Phase C Performance Closure

Quest Chronicle now applies one elapsed-time budget across cooperative generation work, decomposes support-reroll diagnostics into resumable stages, and reuses a session weapon-source index instead of repeatedly rebuilding subtype buckets.

- Adds shared slice-budget and adaptive-batch helpers for support rerolls and full foreground generation.
- Yields before phase transitions when the remaining frame allowance is too small and immediately after expensive operations.
- Replaces the monolithic support-reroll diagnostic foundation with incremental identity, anchor, state, style-context, support-summary, and cache-summary stages.
- Makes source eligibility resumable through precheck, era, provenance, curated-source, drop-source, tracked-source, metadata, and marker stages.
- Dynamically sizes reroll candidate and scoring batches from observed operation cost and remaining slice time.
- Adds weapon candidate index format 1 as a session acceleration layer with cold-build, partial-warm, warm, and incremental-repair diagnostics.
- Repairs only an invalidated weapon subtype bucket when possible and coalesces reuse through the existing weapon-generation coroutine.
- Preserves v1.9.0.10 anchor, weapon, support, contextual-reroll, profile, mismatch, and outfit-name selections for identical seeds and state.
- Keeps SavedVariables schema 2, Courier format 1, wardrobe cache format 7, generation-cache store 2, and diagnostic format 1 unchanged.

The package is automated-validated and requires Retail validation before replacing v1.9.0.5 as the live baseline.
