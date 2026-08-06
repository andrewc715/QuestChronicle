# Quest Chronicle v1.11.6 Retail Live Validation Steps

## Purpose

Prove that the v1.11.5 Retail-sized Zone report persists through adaptive compaction, then resume the anchor-policy lineage and performance closure sequence.

## Install

1. Exit World of Warcraft.
2. Replace the addon with the `QuestChronicle` folder from `QuestChronicle-v1.11.6.zip`.
3. Confirm the top-level folder is exactly `QuestChronicle`.
4. Log into Xyrkian on Retail and confirm version `1.11.6`.
5. Wait for the normal wardrobe refresh to settle.

## Test 1: first Zone generation persistence

1. Select **Zone Native**.
2. Press **Generate Outfit** once.
3. Confirm no chat message begins with:

```text
Quest Chronicle: Debug report could not be saved
```

4. Open Debug History and confirm a new **Generate Outfit** report exists.
5. Copy the report and confirm its Warnings section includes a line such as:

```text
Diagnostic persistence: <tier> • <original> → <final> bytes • emergency stub <Yes/No>
```

6. Confirm final bytes are at or below `20,480`.
7. Confirm the retained report still includes:

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Policy: ZONE_ANCHOR_POLICY_V1 • ACTIVE
Selected anchor evidence
Weapon capabilities
Scheduler integrity
Contextual Support
Final validation
```

## Test 2: retained reroll chain

Run **Reroll Unlocked** three consecutive times. Every action must create a new Debug History report and none may print a persistence rejection.

Record for each:

```text
Longest worker slice
Largest instrumented call
Maximum slice debt
Capability status/builds/reuses
Eligibility steps/yields
Compaction tier and final bytes
```

Performance closure remains:

```text
Longest worker slice < 8.0 ms
Largest instrumented call < 8.0 ms
Maximum slice debt <= 2.0 ms
Post-expensive continuations = 0
```

## Test 3: export lineage

1. Perform a legacy individual anchor-slot reroll after at least one policy-bearing action.
2. Run `/qc zone debug export`.
3. Confirm the export separately identifies:

```text
Latest Zone Native report
Latest Zone anchor-policy-bearing report
```

The policy section must still select the newest valid `ZONE_ANCHOR_POLICY_V1` report.

## Pass gate

```text
First generation report retained
Three warm reroll reports retained
No DIAGNOSTIC_REPORT_REJECTED warning
All final report sizes <= 20,480 bytes
Mandatory Zone and performance sections retained
Format-4 export lineage correct
Warm performance thresholds pass
```
