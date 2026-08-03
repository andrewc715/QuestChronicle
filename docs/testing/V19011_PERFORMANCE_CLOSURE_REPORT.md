# Quest Chronicle v1.9.0.11 Phase C Performance-Closure Report

## Scope

v1.9.0.11 closes the remaining execution paths identified by v1.9.0.10 Retail testing: oversized cumulative reroll slices, a monolithic diagnostic-foundation call, variable-cost eligibility work, and intermittent synchronous weapon candidate indexing. It does not retune anchor, weapon, support, mismatch, bridge, novelty, or naming behavior.

## Shared worker budget

`Core/Workers/SliceBudget.lua` centralizes elapsed-time accounting. Workers reserve time before phase transitions, yield immediately after an expensive call, and avoid beginning another batch after the preferred allowance is consumed. `AdaptiveBatch.lua` selects batches from 1, 2, 4, 8, or 16 using recent operation cost and remaining slice time.

The dedicated worker-budget harness verified:

- elapsed-time yielding;
- phase-transition reserve;
- immediate yielding after an expensive operation;
- larger batches for inexpensive cached work;
- single-operation batches after a slow call.

## Diagnostic decomposition

The former `rerollDiagnosticFoundation` phase is no longer emitted. Support rerolls now materialize diagnostic identity, anchor summary, state, style context, eligibility context, support summary, and cache summary independently. Each stage is resumable through the existing job continuation state.

## Resumable eligibility

`EligibilityWork.lua` advances eligibility through precheck, era, provenance, curated source, drop source, tracked source, metadata, and marker stages. `GenerationEligibility.lua` wraps the same work with existing transient and persistent cache semantics. Legacy synchronous callers drain the resumable work without changing results.

## Weapon candidate index

Weapon index format 1 is a session acceleration structure keyed by the completed scan identity, visual count, character key, and index format. Subtype buckets build through the existing weapon-generation coroutine, are reused when warm, and can be invalidated and repaired independently.

Synthetic weapon-index result:

```text
240 examined sources
80 matching sources
31 cold cooperative frames
1 warm frame with zero yields
31 incremental-repair frames
1 repaired subtype bucket
```

The index remains non-authoritative. Existing weapon route generation, filtering, ordering, and seeded selection remain the source of truth.

## Support-reroll stress boundary

The existing 32-candidate contextual support fixture continues to enforce:

```text
Prepared candidates: 32 maximum
Final shortlist:       6 maximum
Target-only commit:    preserved
Profile and budget:    preserved
```

## Compatibility

```text
SavedVariables schema:  2
Courier format:         1
Wardrobe cache format:  7
Generation cache:       2
Diagnostic format:      1
Weapon index format:    1
```
