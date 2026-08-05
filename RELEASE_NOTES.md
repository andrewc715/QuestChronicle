# Quest Chronicle v1.9.0.14

## Phase D: Outlier Repair

Quest Chronicle now validates the completed Traveler outfit after Phase C support selection and before the visible preview is committed.

- Enforces the original final-composition gates: a 2.00-point mismatch budget, a strict 0.72 outlier-severity threshold, no more than three dominant palette families, and visible echo for loud accents.
- Repairs the worst unlocked support outlier through at most two deterministic passes using the already prepared Phase C candidate pools.
- Rebuilds the exact contextual budget and complete-outfit analysis for every trial replacement without rescanning the wardrobe, repeating eligibility, querying the weapon index, or consuming a new random roll.
- Preserves locked and hidden appearances. Locked-only violations commit explicitly as `LOCKED_OVERRIDE` rather than being silently replaced.
- Uses the next valid Phase B finalist only after both support repair passes are exhausted, with one alternate-skeleton attempt inside the original quality window.
- Applies the same final validator to support-only rerolls while allowing only the requested support slot to change.
- Adds compact before-and-after diagnostics for mismatch, severity, palette families, zero-echo accents, accepted repairs, locked overrides, and alternate skeleton use.
- Preserves v1.9.0.13 weapon routes, candidate ordering, Phase B and Phase C scoring, cache formats, scheduler budgets, locks, hidden slots, and atomic preview commits.

The package is automated-validated and requires Retail validation before replacing v1.9.0.13 as the live baseline.

Follow `docs/testing/V19014_LIVE_VALIDATION_STEPS.md` for the streamlined Retail validation sequence.
