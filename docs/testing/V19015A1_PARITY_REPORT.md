# Quest Chronicle v1.9.0.15a1 Parity Report

## Baseline

Compared against the corrected, live-validated Quest Chronicle v1.9.0.14 package.

## Shared Lua harnesses

- 63 shared harnesses executed against both trees.
- 63 passed in both versions.
- 62 outputs matched byte for byte.
- 1 output differed only in measured wall-clock benchmark time:
  - `test_anchor_novelty_benchmark.lua`
- 0 semantic selection, score, route, repair, budget, cache, or scheduler differences were observed.

## New observation-only harnesses

v1.9.0.15a1 adds three Phase E-specific harnesses:

- tuning audit aggregation, controls, thresholds, and Markdown export;
- diagnostic-history observation hook, duplicate isolation, and failure containment;
- bounded 300-identity capacity, deterministic pruning, and compact export.

## Parity conclusion

With the tuning audit disabled, v1.9.0.15a1 preserves v1.9.0.14 runtime behavior. With the audit enabled, collection occurs only after an accepted immutable diagnostic report and does not alter that report, the preview, random consumption, scoring, repair selection, or scheduler state.
