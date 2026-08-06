# Quest Chronicle v1.11.4 Parity Report

## Baseline

```text
Baseline: Quest Chronicle v1.11.3
Target:   Quest Chronicle v1.11.4
```

## Intentional differences

```text
VERSION_ONLY
- package metadata and fallback version are 1.11.4

DIAGNOSTIC_PERSISTENCE
- oversized Zone reports remove duplicated policy and affinity detail before insertion
- uncompactable reports produce a visible warning and callback

WORDING_ONLY
- Zone export no-report text is version-neutral
```

## Frozen semantic behavior

Exact parity is required for:

- Zone context and evidence resolution;
- Affinity v2 scores and classifications;
- `ZONE_ANCHOR_POLICY_V1` constants;
- candidate and pair adjustments;
- beam results for the same random stream;
- novelty and repeat penalties;
- legal weapon bundles and linked-visual deduplication;
- support profile, budget, scoring, beam, validation, repair, and rerolls;
- locks and hidden slots;
- Traveler selection and diagnostics;
- Class Fantasy and Chronicle Echo behavior;
- caches, SavedVariables, and Courier output.

## Runtime module comparison

```text
142 / 145 inherited runtime modules are byte-identical
3 inherited runtime modules changed
1 runtime module added
0 runtime modules removed
```

No generation-facing module changed.

## Report-content parity

Compacted reports retain all user-visible results and reusable ancestry. Only duplicated or reconstructible detail changes:

```text
Removed when oversized:
- duplicate outfit slot list
- display-only active anchor list
- duplicated component Zone policy calculations
- reconstructible per-piece persisted affinity ledger
- lower-value raw timing details at later stages

Retained:
- authoritative Zone policy summary
- selected sources and scores
- pair channels
- weapon route and deduplication
- support ancestry
- Phase D
- warnings
```

## Classification

```text
Traveler selection parity:     UNCHANGED
Zone generation parity:        UNCHANGED
Zone policy score parity:      UNCHANGED
Support and repair parity:     UNCHANGED
Weapon route parity:           UNCHANGED
Scheduler parity:              UNCHANGED
Diagnostic persistence:        INTENTIONAL FIX
Saved data and cache parity:   UNCHANGED
```
