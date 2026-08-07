# Quest Chronicle v1.11.9 Automated Validation

## Baseline

Implementation began from the exact v1.11.8 package SHA-256:

`bf0cd555dfd1cf560be5bba2b3c8243c84b84defd2faaed47604d73bb891e930`

The untouched baseline passed 107/107 inherited Lua tests and 36/36 inherited Python verifiers before the correction was implemented.

The exact v1.11.8 source also contains the confirmed fatal boundary:

- `Core/ZoneStyle/EraEvidence.lua` synchronously drains `StepSourceEraEvidenceWork(work, 1000000)`.
- `Core/ZoneStyle/GenerationEligibility.lua` eagerly calls `GetSourceEraEvidence(source)` while constructing cached eligibility without supplied evidence.

## v1.11.9 coverage

New automated coverage verifies:

- exact Anchor Weapons cached-eligibility deferral route returns to the scheduler;
- synchronous era resolution ignores ambient used generation slices;
- raw cooperative eligibility owns nested era work;
- background work is isolated from foreground slice admission;
- no-progress synchronous work is stopped by the watchdog guard;
- a finite 300-set synchronous evidence workload completes without a guard trip;
- execution-boundary counters survive diagnostics and adaptive persistence;
- static production code contains no eager cached-eligibility era getter and no million-step synchronous era drain.

## Source-tree result

- Lua regression tests: 112/112 PASS
- Python static verifiers: 37/37 PASS
- Runtime Lua syntax: 152/152 PASS
- TOC runtime modules: 152/152 exactly once
- Runtime Lua files at or above 500 lines: 0

Exact-ZIP validation is repeated after packaging and recorded in the release handoff.
