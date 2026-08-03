# Quest Chronicle v1.9.0.5 Live-Test Checklist

Install v1.9.0.5 without deleting `QuestChronicleDB`, then allow the automatic wardrobe scan to finish.

## Traveler sequence

1. Generate Outfit.
2. Generate Outfit again.
3. Reroll Unlocked.
4. Hide Shoulders and generate three times.
5. Lock Chest and generate twice.
6. Use `/reload`, generate once, and open `/qc debug`.

## Capture

Copy the complete Debug report for each run. Confirm:

- Hidden Shoulders appear under `Excluded` and never under `Unchanged`.
- Hidden or locked anchors do not trigger repeated-foundation warnings.
- Every generation creates exactly one report.
- Every comparison references the actual previous completed report.
- `Reports` counters show no unexpected duplicate insertions.
- The largest weapon call names a precise subphase such as Weapon appearance index or Weapon source metadata.
- No 18–20 ms anchor weapon call remains after the scan-prewarmed metadata is active.
- Traveler selections, novelty classes, locks, hidden slots, and weapon routes remain correct.
