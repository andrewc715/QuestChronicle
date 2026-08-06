# Quest Chronicle v1.11.3 Zone Anchor Calibration Report

## Purpose

Record the first Zone anchor-policy coefficient set and the evidence used to accept it for package validation.

This report does not claim Retail tuning completion. It confirms that the planned v1 coefficients were implemented exactly, remain bounded, and pass deterministic fixtures.

## Implemented coefficients

```text
Neutral affinity:         0.35
Affinity scale:           20.00
Maximum candidate bonus:  +8.00
Maximum candidate penalty: -6.00
Full-confidence point:     0.65
Maximum pair bonus:        +4.00
Pair scale:                 6.00
Chest multiplier:           1.00
Legs multiplier:            0.90
Shoulders multiplier:       1.00
Weapon multiplier:          1.10
```

These values match the approved architecture plan. No coefficient was changed during implementation.

## Deterministic candidate fixtures

The executable fixtures prove:

```text
Strong local evidence > weak local evidence when legacy factors are equal
Known off-zone evidence < neutral when legacy factors are equal
Unknown evidence adjustment = 0
Confidence 0 adjustment = 0
NOT_APPLICABLE creates no penalty
Favorite state remains visible and existing preference survives
Locked low-affinity candidates remain accepted
Maximum bonus and penalty remain bounded after slot multiplier
```

## Candidate-priority fixture

Two candidates with equal legacy relevance and the same pre-consumed pool-random structure are evaluated through the active policy. The locally supported candidate becomes the higher-priority retained candidate without adding a random draw.

This proves authority transfer at the candidate-preference seam rather than by a second selection pass.

## Pair fixtures

The deterministic pair fixtures prove:

- visual cohesion values remain unchanged;
- the Zone pair channel is additive and separately reported;
- the local pair bonus never exceeds `+4.00`;
- unknown or partial evidence adds no pair bonus;
- a hard clash cannot be cleared;
- two locally supported, otherwise equal candidates may outrank a neutral pair.

## Weapon fixtures

The logical-weapon fixture proves:

- linked copies of one visual receive one affinity contribution;
- a two-handed presentation is not double-counted across physical slots;
- distinct weapon visuals remain independently represented;
- legal route construction is not modified by the policy.

## Random-consumption fixture

The candidate cache stores the existing pool random value. When the Zone adjustment changes candidate weight, the policy recomputes priority from that value rather than calling `math.random()` again.

```text
Additional Zone-policy random draws: 0
Second candidate pass: 0
```

## Performance instrumentation

Every Zone policy callback is recorded under:

```text
Zone anchor policy
```

The package requires each call and repeated worker slice to remain below 8 ms in Retail, with zero post-expensive continuations.

## Calibration status

```text
Planned constants implemented exactly: PASS
Deterministic candidate ordering: PASS
Bounded adjustment: PASS
Neutral unknown evidence: PASS
Pair-channel separation: PASS
Logical weapon deduplication: PASS
Random-consumption parity: PASS
Retail coefficient review: Pending
```

No tuning expansion or coefficient change should occur until Retail reports provide evidence for a later numeric v1.11.x release.
