# Quest Chronicle v1.11.5 Retail Live Validation Steps

## Purpose

Close the first Zone anchor-policy slice by validating independent report lineage and cooperative weapon-path timing on Retail.

## Install

1. Exit World of Warcraft.
2. Replace the existing addon folder with the `QuestChronicle` folder from `QuestChronicle-v1.11.5.zip`.
3. Confirm the top-level addon folder is exactly `QuestChronicle`.
4. Start Retail and log into Xyrkian.
5. Use `/reload` once after login if needed.
6. Open Quest Chronicle and confirm version `1.11.5`.
7. Wait for the normal wardrobe refresh to settle before the cold timing test.

## Test 1: cold Zone Generate Outfit

1. Select **Zone Native**.
2. Press **Generate Outfit** once.
3. Open the newest Debug report.
4. Confirm:

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Policy: ZONE_ANCHOR_POLICY_V1 • ACTIVE
Support policy: LEGACY
Capability builds this action: 1 or fewer
Capability stale at commit: No
Post-expensive continuations: 0
```

5. Record:

```text
Longest worker slice
Largest instrumented call and phase
Maximum slice debt
Capability status and generation
Eligibility steps and yields
```

Cold pass gate:

```text
Longest worker slice < 16.0 ms
Largest instrumented call < 16.0 ms
No old aggregate weaponStyleEligibility hotspot
```

A warning between 8.0 and 16.0 ms is acceptable only when it identifies one exact bounded subphase.

## Test 2: three consecutive warm Reroll Unlocked actions

Without changing equipment, specialization, talents, collection state, mode, or zone, run **Reroll Unlocked** three times.

For each report, confirm:

```text
Capability snapshot: REUSED
Capability builds this action: 0
Capability stale at commit: No
Post-expensive continuations: 0
```

Every one of the three reports must pass:

```text
Longest worker slice < 8.0 ms
Largest instrumented call < 8.0 ms
Maximum slice debt <= 2.0 ms
No WORKER_SLICE warning
No SEVERE_WORKER_SLICE warning
No INSTRUMENTED_CALL warning
No SEVERE_INSTRUMENTED_CALL warning
```

## Test 3: explicit capability invalidation

1. Change the equipped weapon or specialization.
2. Wait for the normal equipment/spec event to settle.
3. Generate or use Reroll Unlocked.
4. Confirm the next action reports:

```text
Capability builds this action: 1
Capability stale at commit: No
```

5. Run one more Reroll Unlocked without another change and confirm:

```text
Capability snapshot: REUSED
Capability builds this action: 0
```

## Test 4: export lineage

1. Ensure Debug History contains a policy-bearing Generate or Reroll Unlocked report.
2. Perform one legacy individual anchor-slot reroll so it becomes the newest Zone report.
3. Run:

```text
/qc zone debug export
```

4. Confirm:

```text
Zone debug export format: 4
Latest Zone report carries policy: NO
The latest Zone Native report is a legacy action without an anchor-policy payload.
Showing the most recent policy-bearing Zone report instead.
```

5. Confirm the **Zone Anchor Policy** source report is the newest policy-bearing Generate or Reroll Unlocked report.
6. Confirm **Latest Zone Native diagnostic report** is the newer legacy individual reroll.
7. Confirm report IDs, actions, results, and snapshots are not blended.

## Test 5: report persistence and reload

1. Confirm every test action produced a retained Debug report.
2. Confirm no chat message says `Debug report could not be saved`.
3. Note the newest policy-bearing report ID.
4. Use `/reload`.
5. Confirm the report remains visible and the format-4 export still selects it correctly.

## Pass criteria

```text
Cold timing gate:                    PASS
Warm reroll 1 timing gate:           PASS
Warm reroll 2 timing gate:           PASS
Warm reroll 3 timing gate:           PASS
Capability invalidation and reuse:   PASS
Independent export lineage:          PASS
Report persistence after reload:     PASS
Post-expensive continuations:        0
Lua errors:                          NONE
```

The synchronous legacy individual anchor/weapon reroll timing is not a v1.11.5 closure gate.
