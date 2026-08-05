# Quest Chronicle v1.9.0.15 Final Live Validation Steps

The full curated a2 build has already passed Retail validation. This is a short package and promotion smoke test. Do not perform another tuning batch.

## 1. Install

1. Replace the existing `QuestChronicle` folder with the release-candidate folder.
2. Use `/reload`.
3. Confirm the addon reports version `1.9.0.15`.
4. Do not run **Scan Collection**.

## 2. Confirm three curated descriptors

Preview each appearance and run `/qc traveler debug`.

Expected:

```text
Rugged Plate Vest
Palette: blue 45%, steel 35%, dark 20% • curated
Finish: weathered 60%, plain 40% • curated

Orcish Scout Boots
Palette: dark 70%, blue 20%, steel 10% • curated
Finish: plain 75%, polished 25% • curated

Expedition Defender's Shoulders
Palette: green 70%, steel 30% • curated
Finish: military 80%, polished 20% • curated
```

Orcish Scout Boots must not report green.

## 3. Run four outfit actions

In Traveler mode:

1. **Generate Outfit**
2. **Generate Outfit** again
3. **Reroll Unlocked**
4. Reroll one visible support slot, preferably Hands or Back

After each action, confirm:

```text
Result: Completed
Fallback: None
Report visible and copyable in Debug History
0 duplicate reports
0 malformed reports
0 post-expensive continuations
```

For the support-slot reroll, confirm only the requested slot changes. Locks and hidden slots must remain unchanged.

## 4. Run one audit action

```text
/qc traveler tuning clear confirm
/qc traveler tuning start
```

Complete one Traveler action, then run:

```text
/qc traveler tuning stop
/qc traveler tuning status
/qc traveler tuning export
```

Expected:

```text
Completed Traveler actions: 1
Collection errors: 0
```

Confirm the Markdown export is copyable and does not replace normal Debug History.

## 5. Return

Return:

1. The three curated descriptor outputs
2. The four completed Debug reports
3. The tuning status and exported Markdown

If all checks pass, promote this exact ZIP without rebuilding it.
