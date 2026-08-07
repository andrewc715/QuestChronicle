# Quest Chronicle v1.11.10 Parity Report

## Selection parity boundary

v1.11.10 is a scheduling release. It does not intentionally alter any scoring input, weighting, candidate-order rule, random-consumption rule, mismatch budget, legal route, or final-validation rule.

The synchronous support scorer remains the oracle for the new resumable `SupportCandidateWork`. Dedicated fixtures compare the final decision fields, including score, neighbor cohesion, bridge bonus, bridge target, before/after cohesion, mismatch cost, budget result, repeat penalty, and fallback state.

## Era evidence parity boundary

The v1.11.8/v1.11.9 resumable era state machine remains authoritative. v1.11.10 changes admission timing only:

- local/cache work no longer asks for API headroom;
- API work can begin with sufficient scheduler headroom rather than requiring an empty slice;
- actually expensive API calls still force-yield after the call.

Evidence rank, earliest-era aggregation, equal-era evidence precedence, pending semantics, retry behavior, and cache-key formats remain unchanged.

## Random parity

No random draw was moved into or out of a candidate stage. Candidate completion still reaches the existing random-consumption point in the same semantic order.

## Persistent-data parity

No SavedVariables, wardrobe-cache, evidence-cache, eligibility-cache, weapon-index, diagnostic-report, or Courier schema version changes are included.

## Runtime boundary

The handoff records the exact byte-level runtime delta from v1.11.9. The only new runtime module is `Core/Wardrobe/SupportCandidateWork.lua`; all other changes are focused on era admission, support scheduling, performance diagnostics, version metadata, and Zone export rendering.
