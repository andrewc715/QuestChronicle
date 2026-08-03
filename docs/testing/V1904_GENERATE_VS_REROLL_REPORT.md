# v1.9.0.4 Generate Outfit versus Reroll Semantics

## Generate Outfit

Generate Outfit performs soft novelty selection after the legal beam shortlist is complete.

```text
Meaningfully New > Partial Change > Exact Repeat
```

Only candidates inside the existing 28-point base-score quality window participate. Repeat penalties adjust weighted selection inside the chosen novelty class but never change candidate legality or intrinsic skeleton score.

## Reroll Unlocked

Reroll Unlocked preserves the v1.9.0.3 candidate-exclusion path. Current unlocked source appearances are excluded during candidate preparation where legal alternatives exist. Generate Outfit novelty classes and calibrated repeat penalties are not applied.

## Reroll Slot

Reroll Slot remains isolated to its requested slot and bypasses whole-skeleton novelty selection.

## Locked and hidden anchors

Locked and hidden anchors are removed from the novelty denominator. Their continued presence is obedience to user intent rather than repetition.
