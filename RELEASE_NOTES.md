# Quest Chronicle v1.11.11

v1.11.11 targets the two remaining Retail performance islands from v1.11.10 without changing scoring or selection semantics.

## Highlights

- Replaces monolithic Zone anchor-candidate scoring with resumable prepared-input stages.
- Prevents duplicate item/set/tracking work inside descriptor and Zone-affinity evaluation.
- Preserves exactly one pool-priority random draw for each accepted anchor candidate, at the existing ordering boundary.
- Extends the same cooperative candidate construction to weapon finalist scoring.
- Reuses authoritative support-profile and beam-node descriptors during bridge scoring.
- Splits bridge target, descriptor, candidate-pair, baseline-pair, and finalize work into individually timed steps.
- Adds retained scalar diagnostics for anchor preparation/scoring and support bridge work.
- Keeps scheduler constants, era admission, Zone policy coefficients, support budgets, weapon routes, caches, schemas, and export formats unchanged.

Retail performance validation remains pending.
