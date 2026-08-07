# Quest Chronicle v1.11.10

Quest Chronicle v1.11.10 closes the two scheduling defects exposed by v1.11.9 Retail validation: unnecessary era fresh-frame deferrals and an oversized contextual-support candidate operation. Era evidence now asks for scheduler headroom only when it is actually about to cross a variable API boundary, while support candidate scoring advances through resumable neighbor, bridge, budget, and finalize substeps.

## v1.11.10 focus

- Demand-aware era admission distinguishes local work from API-headroom work instead of treating every variable stage as fresh-only.
- Stable source-cache and fragment-cache completions remain local and pay no frame admission tax.
- Cheap era API operations may share a slice when at least 3.0 ms of scheduler headroom remains.
- Actual expensive calls still trigger the existing force-yield contract without changing scheduler budgets.
- Diagnostics expose API admissions, headroom deferrals, fresh-only deferrals, phantom deferrals, and local/cache completions.
- Contextual-support candidate scoring is resumable across neighbor, bridge, budget, and finalize substeps.
- Partial support candidates cannot mutate the beam or consume a completed expansion until their decision is final.
- The synchronous support scorer remains the parity oracle and fallback tie behavior remains first-best strict-lower.

## Architecture identity

Traveler remains `SHARED_FRAMEWORK`. Zone Native remains `LEGACY` with `CONTEXT_EVIDENCE_V1`, authoritative `ZONE_ANCHOR_POLICY_V1`, and legacy support policy. Class Fantasy and Chronicle Echo remain `LEGACY`. Scheduler budgets, Zone coefficients, era evidence precedence, random consumption, support scoring, beam widths, weapon routes, locks, hidden slots, Phase D, SavedVariables, persistent cache formats, diagnostic format 1, and Zone export format 4 remain unchanged.

Retail validation is required before v1.11.10 becomes the accepted Zone anchor-policy performance baseline.
