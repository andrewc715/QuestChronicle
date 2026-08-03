# Quest Chronicle v1.9.0a10 Live Test Checklist

## Purpose

Validate that exact pending item dependencies resolve without recreating the v1.9.0a9 cache-churn wave. A dependency becoming available must not invalidate reusable generation records unless the normalized era outcome actually changes.

## Installation

1. Exit World of Warcraft completely.
2. Replace the complete installed `QuestChronicle` folder with v1.9.0a10.
3. Do not delete `QuestChronicleDB`, the wardrobe cache, or the persistent generation cache.
4. Start Retail and confirm Status & Maintenance reports `Quest Chronicle 1.9.0a10`.
5. Let the automatic wardrobe scan finish before generating.

## Test A: Generate Outfit

1. Use **Generate Outfit**.
2. Capture the timing line and complete Generation Performance tooltip.
3. Confirm the outfit appears atomically and no Lua error occurs.
4. Record:
   - frames, total seconds, worst step, and slowest phase;
   - era-source checks and cache hits;
   - item callbacks received and coalesced;
   - exact dependencies examined, still pending, and fully satisfied;
   - evidence outcomes unchanged and changed;
   - pending records created and downstream records invalidated;
   - any exact invalidation reasons;
   - any slow weapon-resume phase detail.

Expected: item callbacks may be numerous, but most satisfied dependencies should either remain tracking-only or report an unchanged evidence outcome. Downstream invalidations should be far lower than the v1.9.0a9 wave of roughly 1,600 to 1,700 records.

## Test B: Reroll Unlocked twice

1. Use **Reroll Unlocked** twice without changing outfit settings.
2. Capture both timing lines and tooltips.
3. Confirm locks, hidden slots, linked hands, and weapon subtype behavior remain correct.

Expected:

- cache-hit counts remain warm;
- exact dependency work shrinks or remains bounded;
- unchanged outcomes do not clear eligibility;
- changed outcomes and downstream invalidations remain small;
- warm performance does not regress from the v1.9.0a8 baseline of about 100 frames and 1.5 seconds.

## Test C: persistence crossing

1. Use `/reload`.
2. Let the automatic wardrobe scan finish.
3. Use **Generate Outfit** once.
4. Capture the complete tooltip.

Expected:

- thousands of persistent evidence, precheck, and eligibility records load before generation;
- the automatic scan retains those records;
- dependency indexes rebuild from the persistent store;
- era and eligibility cache hits remain warm;
- there is no return to the v1.9.0a7 cold value of 10,658 era-source checks;
- unchanged dependency outcomes preserve downstream eligibility;
- worst-step responsiveness remains in the cooperative range.

## Acceptance goals

Correctness requirements:

- no Lua errors;
- no non-atomic preview changes;
- no weapon-route, linked-hand, lock, hidden-slot, or Traveler-selection regressions;
- no broad pending-resolution invalidation wave;
- persistent cache survives `/reload` and the automatic scan.

Performance targets:

```text
Warm reroll:              <= 75 frames and <= 1.2 seconds
Generate after /reload:   <= 120 frames and <= 1.8 seconds
Warm era-source checks:   below 1,000
Worst normal step:        below 8 ms
Downstream invalidations: below 200 per warm generation
```

These timing numbers are targets rather than correctness gates. The decisive signal is that dependency completion produces mostly unchanged outcomes with narrow or zero downstream invalidation.

## Failure signals

- hundreds or thousands of downstream eligibility invalidations after unchanged outcomes;
- a single loaded item fan-outs into unrelated visual records;
- records leave `PENDING_ITEMS` while unresolved item dependencies remain;
- tracking-only evidence repeatedly reevaluates during normal item callbacks;
- persistent cache totals collapse after `/reload` or the automatic scan;
- first or warm generation regresses materially from v1.9.0a8;
- Lua errors, visible frame freezes, weapon mismatches, or changed Traveler behavior.
