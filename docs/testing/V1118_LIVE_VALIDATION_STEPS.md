# Quest Chronicle v1.11.8 Retail Live Validation Steps

## Purpose

Close the first authoritative Zone anchor-policy slice by proving the final monolithic era-evidence cost has been decomposed without changing evidence or selection behavior.

## Install

1. Exit World of Warcraft completely.
2. Replace the existing addon folder with the `QuestChronicle` folder from `QuestChronicle-v1.11.8.zip`.
3. Start Retail and enable Quest Chronicle.
4. Log into Xyrkian and confirm version `1.11.8` on Status & Maintenance.
5. Keep Zone Native selected and remain in the same zone for the complete performance sequence.

## A. Cold Generate Outfit

1. Run `/reload`.
2. Wait for the normal collection refresh to settle.
3. Generate one Zone Native outfit.
4. Open Debug History and copy the new report.
5. Confirm:

```text
Result: Completed
Zone anchor policy: ZONE_ANCHOR_POLICY_V1 / ACTIVE
Zone support policy: LEGACY
Context stale at commit: No
Diagnostic report retained
No “Debug report could not be saved” warning
```

6. Confirm Performance includes:

```text
Era evidence scheduling: <operations> operations • <siblings> siblings • <deferrals> fresh-slice deferrals • <hits> fragment hits
Era evidence completions: <builds> fragment builds • <pending> pending • <finalizations> aggregate finalizations
Era API work: <set lists> • <set entries> • <tracking> • <encounter lists> • <encounter entries> • <item metadata>
Largest era subphase: <phase> <ms>
```

7. Cold gate:

```text
Longest worker slice < 16.0 ms
Largest instrumented call < 8.0 ms
Maximum slice debt <= 2.0 ms
Post-expensive continuations = 0
Largest era subphase < 4.0 ms target
No performance warning
No diagnostic rejection
```

## B. Three consecutive warm Reroll Unlocked actions

Without reloading, changing zone, changing equipment, or modifying the collection, run **Reroll Unlocked** three times consecutively and copy all three reports.

Every report must satisfy:

```text
Longest worker slice < 8.0 ms
Largest instrumented call < 8.0 ms
Maximum slice debt <= 2.0 ms
Post-expensive continuations = 0
No performance warning
No diagnostic rejection
Fallback: None
Context stale at commit: No
Capability stale at commit: No
```

Era-specific checks:

```text
No broad monolithic eraEvidence overage
Largest era subphase is identified
Fresh-slice deferrals are coherent
Stable fragment hits appear when applicable
No pending candidate is reported as a stable fragment hit
```

All three warm actions must pass. Two of three is not closure.

## C. Evidence and state parity

Across the sequence confirm:

- Zone profile, era, and provenance remain correct;
- candidate pools remain populated and policy adjustments remain bounded;
- legal weapon routes remain valid;
- locked slots never change and hidden slots remain hidden;
- support final validation is `CLEAN` or truthfully `REPAIRED`;
- no unexpected pending-era fallback or partial preview appears.

## D. Pending item-data path

When a natural pending candidate appears, confirm it remains pending until Blizzard data arrives, then reevaluates without stale fragment reuse. This may be marked not naturally reproducible in the Retail session because automated coverage is mandatory and already present.

## E. Zone debug export

Run:

```text
/qc zone debug export
```

Confirm:

```text
Zone debug export format: 4
Latest Zone Native report selected independently
Latest policy-bearing report selected independently
Zone anchor policy: ZONE_ANCHOR_POLICY_V1 / ACTIVE
Support scheduling counters present
Era operations and sibling completions present
Era fresh-slice deferrals and fragment-cache hits present
Largest era subphase matches the latest policy report
```

## F. Latency sanity

Compare with the v1.11.7 Retail sample. Investigate before acceptance if cold or warm frames/elapsed time show a repeatable increase of roughly 25% or more that cannot be explained by normal Retail variance.

## G. Individual support-slot reroll

Perform one contextual support-slot reroll and confirm a retained report, correct parent/profile lineage, and no diagnostic rejection. The synchronous legacy individual anchor reroll remains outside this release.

## Pass decision

v1.11.8 closes the Zone anchor-policy slice only when the cold action and all three warm actions pass the numerical gates with retained diagnostics and correct format-4 export lineage.
