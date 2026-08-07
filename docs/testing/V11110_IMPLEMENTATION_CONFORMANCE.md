# Quest Chronicle v1.11.10 Implementation Conformance

## Approved-plan conformance

v1.11.10 implements the approved productive cooperative scheduling plan.

### Track A: demand-aware era admission

Implemented:

- explicit local/API-headroom/fresh-only/complete admission classes;
- 3.0 ms API headroom reserve;
- pre-admission probes for set, tracking, encounter, and item metadata stages;
- local completion for source-cache and fragment-cache hits;
- existing expensive-call force-yield retained.

### Track B: productive-deferral diagnostics

Implemented headline counters for:

- local era operations;
- API operations and admissions;
- API-headroom deferrals;
- fresh-only deferrals;
- phantom deferrals;
- source-cache and fragment-cache completions.

Invalid zero-work deferral states produce diagnostic warnings.

### Track C: resumable contextual-support candidate scoring

Implemented `SupportCandidateWork` with bounded neighbor, bridge, budget, and finalize steps. Normal beam expansion and fallback paths use the nested worker. Partial candidates cannot mutate the beam.

### Track D: support candidate diagnostics

Implemented:

- candidate substep count;
- candidate completion count;
- admission deferrals;
- largest support-candidate subphase identity and time.

The fields are retained by adaptive diagnostic compaction and rendered by the existing diagnostic and Zone export formats.

### Track E: end-to-end latency contract

Retail validation now treats total duration as part of correctness in addition to maximum worker slice. No scheduler budget was widened.

## Frozen boundaries

No intentional changes were made to:

- `ZONE_ANCHOR_POLICY_V1` or its coefficients;
- Zone Affinity format 2;
- era evidence rank or precedence;
- random-call count or order;
- support scoring formulas, budgets, beam widths, or shortlist rules;
- Phase D validation and repair;
- weapon capability or legal route semantics;
- locks or hidden-slot sovereignty;
- SavedVariables or persistent cache formats;
- diagnostic format 1;
- Zone debug export format 4;
- scheduler budgets;
- Traveler, Class Fantasy, or Chronicle Echo policy behavior.

Retail remains pending.
