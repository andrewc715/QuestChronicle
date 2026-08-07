# Quest Chronicle v1.11.7 Retail Live Validation Steps

## Purpose

Close the first authoritative Zone anchor-policy slice by proving contextual-support work remains below the cooperative scheduler limits in one cold action and three consecutive warm actions.

## Install

1. Exit World of Warcraft completely.
2. Replace the existing addon folder with the `QuestChronicle` folder from `QuestChronicle-v1.11.7.zip`.
3. Start Retail and enable Quest Chronicle.
4. Log into Xyrkian and confirm version `1.11.7` on Status & Maintenance.
5. Keep Zone Native selected and remain in the same zone for the entire performance sequence.

## A. Cold Generate Outfit

1. Use `/reload` so the action begins with a fresh session-local worker state.
2. Generate one Zone Native outfit.
3. Open Debug History and copy the new Generate Outfit report.
4. Confirm:

```text
Result: Completed
Zone anchor policy: ZONE_ANCHOR_POLICY_V1 / ACTIVE
Zone support policy: LEGACY
Context stale at commit: No
Diagnostic report retained
No “Debug report could not be saved” warning
```

5. Confirm the Performance section includes:

```text
Support eligibility: <n> steps • <n> yields • batch 4
Support eligibility completions: <n> cache • <n> computed
Support beam scheduling: <n> candidate • <n> fallback • <n> fallback yields
Support stage finalizations: <n> • fresh-slice deferrals <n> • <ms> max
Largest support subphase: <phase> <ms>
```

6. Cold closure gate:

```text
Longest worker slice < 16.0 ms
Post-expensive continuations = 0
No report rejection
```

## B. Three consecutive warm Reroll Unlocked actions

Without reloading or leaving the zone, run **Reroll Unlocked** three times consecutively. Copy all three reports.

Every warm report must satisfy:

```text
Longest worker slice < 8.0 ms
Largest instrumented call < 8.0 ms
Maximum slice debt <= 2.0 ms
Post-expensive continuations = 0
No performance warning
No diagnostic rejection
```

All three must pass. Two of three is not closure.

Also confirm each report retains:

```text
ZONE_ANCHOR_POLICY_V1 / ACTIVE
Weapon capability stale at commit: No
Support eligibility marker batch: 4
At least one support stage finalization
Fresh-slice deferrals recorded when finalization follows used work
Final validation: CLEAN or truthful repaired result
```

## C. Selection and state safety

Across the cold and warm actions confirm:

- locked slots never change;
- hidden slots remain hidden;
- the equipped weapon route remains legal;
- linked or two-handed visuals are deduplicated logically;
- no partial preview appears before commit;
- no random fallback or empty support slot appears unexpectedly;
- Zone context remains the same at commit.

## D. Zone debug export

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
Support eligibility steps and yields present
Support stage finalizations and fresh-slice deferrals present
Largest support subphase present
```

If a newer legacy individual reroll exists, the Latest Zone report may be that reroll, but the Zone Anchor Policy section must still use the newest policy-bearing report.

## Pass decision

v1.11.7 closes the Zone anchor-policy slice only when the cold action and all three warm actions pass their numerical gates with retained reports and correct export lineage.
