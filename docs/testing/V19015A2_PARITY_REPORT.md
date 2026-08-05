# Quest Chronicle v1.9.0.15a2 Parity Report

## Comparison baseline

v1.9.0.15a2 was compared directly against the corrected uploaded v1.9.0.15a1 package with SHA-256:

```text
eee80d03681ddaa49ae1a06de59ac8b99ac74cc856d901540ee800c2b76f90b6
```

## Shared harness results

- 67 shared Lua harnesses passed in both packages.
- 66 shared outputs were byte-identical.
- The only textual difference was the wall-clock average printed by `test_anchor_novelty_benchmark.lua`.
- No shared harness changed its selected IDs, scores, routes, repair result, cache result, scheduler result, or diagnostic semantics.

## Intentional runtime differences

Only the following runtime areas differ from corrected a1:

- version metadata;
- the new curated override module;
- descriptor construction and fingerprinting;
- the behavior-identical echo-palette read path;
- compact curated Debug and audit markers.

The six reviewed identities may legitimately change profile, cohesion, selection, or Phase D behavior because their palette or finish descriptors are now accurate. No formula or threshold changed.

## Scope boundary

Unreviewed identities remain on the original lexicon path. Item and source override tables are empty. No global lexicon token, relation matrix, score weight, mismatch budget, severity threshold, palette limit, repair limit, route, scheduler budget, or cache schema changed.
