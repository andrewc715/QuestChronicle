# Quest Chronicle v1.11.9 Parity Report

## Protected semantics

v1.11.9 changes execution ownership and resumability only. It does not change:

- Era Evidence format 2 or Manifest format 3;
- evidence ranks or precedence;
- earliest-era aggregation or equal-era stronger-evidence preference;
- pending-item and tracking-pending semantics;
- stable fragment-cache identity;
- generation eligibility keys for equivalent evidence;
- Zone context, affinity, or `ZONE_ANCHOR_POLICY_V1` coefficients;
- support scoring, mismatch budgets, or Phase D repair;
- legal weapon routes or weapon capability policy;
- random-call order/count or candidate order;
- locks, hidden slots, SavedVariables, or persistent cache formats.

## Regression evidence

All inherited v1.11.8 Lua tests continue to pass after adapting focused harnesses to load the new `EraExecution.lua` dependency. Candidate-state-machine parity, aggregate era parity, fragment-cache pending safety, fixed generation selection, weapon ordering, support selection, and cache persistence tests remain green.

The new v1.11.9 tests additionally prove that synchronous and cooperative execution modes reach equivalent authoritative evidence while differing only in scheduling behavior.
