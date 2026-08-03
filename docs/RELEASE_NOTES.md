# Quest Chronicle v1.9.0.4 - Phase B Diversity Calibration

v1.9.0.4 gives repeated **Generate Outfit** clicks their intended meaning: produce a meaningfully different complete outfit when a sufficiently strong alternative exists. The release also corrects the diagnostic ambiguities uncovered by the v1.9.0.3 Debug Workbench.

## Generate Outfit novelty

Quest Chronicle compares each complete legal anchor skeleton with the currently displayed unlocked foundation:

```text
Chest
Legs
Shoulders
Logical weapon bundle
```

Locked and deliberately hidden anchors are excluded. Appearance identity is visual-based, so Blizzard resolving the same appearance through another collected source does not create false novelty.

A candidate is classified as:

```text
Meaningfully New  two or more unlocked logical anchors changed
Partial Change    exactly one unlocked logical anchor changed
Exact Repeat      no unlocked logical anchor changed
Initial Generation no current anchor foundation was available
```

Generate Outfit selects from the strongest available novelty class inside the existing 28-point quality window. Weighted randomness remains active within that class. Novelty cannot make an illegal or dramatically weaker skeleton win.

## Repeat penalties

The intrinsic Phase B score remains unchanged. Repetition affects only the final selection score:

```text
Repeated Chest          -10
Repeated Legs            -6
Repeated Shoulders       -8
Repeated weapon bundle  -10
Exact unlocked repeat   -12 additional
```

An exact repeat remains legal when no meaningfully new or partial-change skeleton survives the quality window. The Debug report records the reason.

## Reroll behavior

**Reroll Unlocked** retains its existing hard replacement semantics and does not use Generate Outfit's novelty classes. **Reroll Slot** remains isolated to the requested slot.

## Diagnostic corrections

The Debug report now records immutable:

- base skeleton score;
- current-skeleton repeat penalty;
- adjusted selection score;
- novelty class;
- compared, changed, and repeated logical anchors;
- exact-repeat exception and reason.

Previous-run comparisons read those stored values directly, so a historical score cannot drift after metadata hydration or a later generation context.

Weapon appearances are always labeled by their physical slots:

```text
Main Hand
Off Hand
```

Weapon subtype remains separate metadata, such as `Two-Handed Sword`.

## Timing terminology

The report now distinguishes:

```text
Longest worker slice
Largest instrumented call
Largest-call phase
```

This removes the apparent contradiction where a complete cooperative slice could be longer than any individually timed call inside it.

Anchor weapon expansion also yields immediately when one weapon operation consumes the frame budget. Legal routes and weighted weapon selection are unchanged.

## Compatibility

```text
SavedVariables schema:   2
Courier format:          1
Wardrobe cache format:   7
Generation-cache store:  2
Diagnostic format:       1
```

Existing v1.9.0.3 reports remain readable and show that novelty data was not recorded by that version. No reset or cache deletion is required. Quest Chronicle still applies no transmog and spends no gold.
