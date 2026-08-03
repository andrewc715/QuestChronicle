# Quest Chronicle v1.9.0.8 Retail Live-Test Checklist

Use Traveler mode and allow the automatic wardrobe scan to finish before testing.

## Core sequence

1. Generate Outfit.
2. Reroll Unlocked.
3. Reroll Waist.
4. Reroll Head.
5. Reroll Back.
6. Reroll Hands.
7. Lock Back and reroll Head.
8. Hide Shoulders and reroll Waist.
9. `/reload`.
10. Reroll Head.
11. Generate Outfit.
12. Open `/qc debug` and copy the reports.

## Required results

- Each support reroll starts asynchronously and changes only its requested slot.
- Prepared target candidates never exceed 32; finalists never exceed six.
- Anchor rank, score, adjusted score, cohesion, and beam data remain inherited rather than becoming zero.
- The report marks `Anchor phase: Reused` and identifies the anchor source report.
- Other visible support pieces are marked Context Fixed, not user Locked.
- Support rerolls do not trigger or advance repeated Chest/Shoulders warnings.
- The next Generate Outfit compares against the preserved prior anchor score rather than `0.0`.
- No monolithic `Reroll slot` phase appears.
- No instrumented reroll call exceeds 8 ms and no worker slice exceeds 12 ms.
- A positive relationship delta says `Bridge improvement`; a neutral or negative delta says `Relationship` with no bridge bonus.
- Cancellation, failure, and no-alternative outcomes leave the current preview unchanged.
