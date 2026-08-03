# Quest Chronicle v1.9.0.4 Live-Test Checklist

Install v1.9.0.4 without deleting `QuestChronicleDB`. Let the automatic wardrobe scan finish before beginning.

## Core sequence

1. Open Traveler mode and press **Generate Outfit**.
2. Copy the complete Debug report.
3. Press **Generate Outfit** again and copy the report.
4. Press **Generate Outfit** a third time and copy the report.
5. Press **Reroll Unlocked** and copy the report.
6. Lock Chest, then press **Generate Outfit** and copy the report.
7. Hide Shoulders, then press **Generate Outfit** and copy the report.
8. Use `/reload`, allow the automatic scan to finish, open `/qc debug`, and confirm the reports survived.

## Generate Outfit acceptance

For the second and third Generate Outfit reports, verify:

- `Novelty` is **Meaningfully New** when at least two unlocked logical anchors changed.
- A **Partial Change** is used only when no meaningfully new candidate survived the quality window.
- An **Exact Repeat** includes an explicit reason.
- Locked and hidden anchors do not appear in `Repeated` or contribute a repeat penalty.
- Base score plus repeat penalty equals adjusted selection score exactly.
- A different collected source for the same visual is not counted as a change.

## Reroll acceptance

Verify Reroll Unlocked still replaces current unlocked appearances and reports novelty as not applicable. No Generate Outfit soft penalty should replace its existing hard exclusion behavior.

## Diagnostic corrections

Verify:

- Weapons are labeled **Main Hand** and **Off Hand**.
- Weapon subtype appears separately where available.
- The previous report's base and adjusted scores exactly match the original report.
- Overview shows **Longest worker slice** and **Largest instrumented call** as separate measurements.
- v1.9.0.3 reports remain readable and state that novelty data was not recorded by that version.

## Responsiveness

Record frames, elapsed time, longest worker slice, and largest instrumented call for every run.

Preferred targets:

```text
Novelty overhead:             not visibly measurable
Additional generation frames: no more than 2
Longest normal worker slice:  below 8 ms
Largest normal call:          below 8 ms
No new operation:             above 12 ms
```

A transient warning may be investigated, but repeated Anchor weapon-expansion overruns block promotion.

## Regression checks

- Locked Chest remains unchanged.
- Hidden Shoulders remain hidden.
- Linked and unlinked weapon routes remain legal.
- Current Preview and Debug report match.
- Save to Custom Sets still reproduces the preview.
- No Lua errors occur.
