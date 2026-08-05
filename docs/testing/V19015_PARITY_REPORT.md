# Quest Chronicle v1.9.0.15 Parity Report

## Comparison baseline

The release candidate was compared directly against the exact uploaded Retail-validated a2 package:

```text
SHA-256: 7fbf907d44247881a3dd860cf5ce2869eb63663aace814dec1a9bfb2ef7f75ee
```

## Shared Lua harnesses

- 70 shared Lua harnesses passed in both trees.
- 69 outputs matched byte for byte.
- The only textual difference was wall-clock timing in `test_anchor_novelty_benchmark.lua`:
  - baseline: 0.0249 ms average;
  - release candidate: 0.0253 ms average.
- No selection, score, descriptor, route, repair, cache, audit, reroll, scheduler, or diagnostic semantic difference appeared.

## Runtime module parity

- 99 TOC runtime modules compared.
- 98 were byte-identical.
- `Core/Chronicle/Foundation.lua` differed only in the addon-version fallback token.
- After normalizing the version token, Foundation was byte-identical.

## Approved non-runtime differences

- package version metadata;
- static-verifier version expectations;
- README, release notes, changelog, architecture, testing, tuning-ledger, and promotion documentation.

## Frozen behavior

The release candidate adds no new curated entries, palette judgments, finish judgments, echo tags, lexicon rules, scoring changes, Phase D changes, routes, scheduler changes, cache-format changes, or Courier-format changes.
