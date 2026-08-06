# Quest Chronicle v1.11.4 Retail Live Validation Steps

## Purpose

Confirm that every affected Zone action again creates a retained Debug History report and that v1.11.4 does not alter Zone generation behavior.

## Install

1. Exit World of Warcraft.
2. Replace the existing addon folder with the `QuestChronicle` folder from `QuestChronicle-v1.11.4.zip`.
3. Confirm the top-level addon folder is exactly `QuestChronicle`.
4. Start Retail and log into Xyrkian.
5. Use `/reload` once after login if needed.
6. Open Quest Chronicle and confirm version `1.11.4`.

## Test 1: Zone Generate Outfit

1. Select **Zone Native**.
2. Press **Generate Outfit**.
3. Wait for completion.
4. Open **Debug**.
5. Confirm a new report appears at the top.
6. Confirm its overview includes:

```text
Version: 1.11.4
Action: Generate Outfit
Mode: Zone Native
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
```

7. Confirm `Fallback: None` unless the generation legitimately reports another existing outcome.
8. A `REPORT_TRIMMED` warning is expected and acceptable.
9. The chat must not show `Debug report could not be saved`.

## Test 2: Reroll Unlocked

1. Press **Reroll Unlocked**.
2. Confirm a second v1.11.4 report appears.
3. Confirm its selected anchor and Zone policy sections remain readable.
4. Confirm legal weapon routing, locks, and hidden slots remain correct.

## Test 3: contextual support reroll

1. Reroll one visible support slot such as Feet, Waist, Hands, Back, or Shirt.
2. Confirm a third report appears.
3. Confirm:

```text
Anchor phase: Reused from parent report
Anchor selection changed: No
only the target support slot changed
budget reconciliation passed
Phase D result remains visible
```

4. Confirm the report remains copyable even when compacted.

## Test 4: individual slot reroll

1. Use one existing individual non-support reroll action.
2. Confirm another report appears in Debug History.
3. This test validates persistence only; the legacy action itself is not modernized by v1.11.4.

## Test 5: Zone debug export

Run:

```text
/qc zone debug export
```

Copy the export and confirm:

```text
Quest Chronicle version: 1.11.4
Zone debug export format: 3
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Latest Zone Native diagnostic report: a new v1.11.4 report
```

The Zone Anchor Policy section must no longer say that no current report is available.

## Test 6: persistence after reload

1. Note the newest report ID.
2. Use `/reload`.
3. Open Debug.
4. Confirm the retained report remains visible and copyable.
5. Confirm no cache reset or migration notice appears.

## Pass criteria

```text
Generate Outfit report:             PASS
Reroll Unlocked report:             PASS
Contextual support reroll report:   PASS
Individual reroll report:           PASS
Zone export newest report:          PASS
Reload persistence:                 PASS
Visible persistence failure:        NONE
Lua errors:                          NONE
```
