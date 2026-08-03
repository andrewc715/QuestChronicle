# Quest Chronicle v1.9.0.9 Retail Live-Test Checklist

Use Traveler mode and allow the automatic wardrobe scan to finish before testing.

## Profile-integrity sequence

1. Hide Shoulders.
2. Generate Outfit.
3. Reroll Unlocked.
4. Reroll Waist.
5. Reroll Head.
6. Reroll Back.
7. Reroll Hands.
8. Lock Back.
9. Reroll Head.
10. Reroll Waist.
11. `/reload`.
12. Reroll Head.
13. Generate Outfit.
14. Open `/qc debug` and copy every report.

## Required profile results

Across every support-only reroll:

- `Active anchors` remains `Chest, Legs, Weapon bundle` while Shoulders are hidden.
- The same Profile ID and Profile source report are reused throughout the unchanged anchor lineage.
- `Profile phase` says Reused and `Profile repaired` remains No for the new healthy lineage.
- Shoulders appear only as hidden or excluded and never become a Head or Back relationship endpoint.
- Only the requested support slot changes; all other unlocked support pieces remain Context Fixed.
- User-locked Back remains explicitly Locked rather than Context Fixed.
- Candidate preparation never exceeds 32 and the final shortlist never exceeds six.
- Anchor rank, score, adjusted score, cohesion, beam data, and anchor-source report remain intact.

## Required budget results

- Profile adjustment is `0.00` for every healthy support-only reroll.
- Budget reconciliation says Pass.
- The stored full-precision equation obeys `after = before - removed + replacement`.
- Rounded values shown in the copied report do not form an impossible equation.
- A failed profile or budget validation leaves the visible preview unchanged.

## Required timing results

- Overview reports Pre-worker preparation separately from the cooperative worker.
- Longest cooperative worker slice does not include state capture or UI presentation.
- Largest cooperative call names a cooperative phase.
- Pre-worker preparation remains below 8 ms.
- Largest cooperative call remains below 8 ms.
- No profile-integrity operation exceeds 12 ms.

## Warm-generation watch

After the primary sequence, perform two additional warmed Generate Outfit actions and record:

- weapon-context call duration;
- longest worker slice;
- era-source checks;
- cache additions and invalidations.

Repeated warmed weapon-context calls above 8 ms require investigation. One metadata-repair outlier remains a watch item rather than a Phase C scoring change.
