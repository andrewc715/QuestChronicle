# Quest Chronicle v1.9.0a5 — Generation Performance Status Live Test

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.9.0a5.
3. Log in or use `/reload`.
4. Open Quest Chronicle and select the Outfits tab.

## Generate Outfit

1. Click **Generate Outfit**.
2. Confirm the existing gray status area reports the generated outfit summary.
3. Confirm a separate line immediately beneath it reports:

```text
Prepared across <n> frames • longest Quest Chronicle step <ms> ms
```

4. Confirm the timing line remains visible after the model preview and appearance list finish refreshing.
5. Change equipment slots or browse appearance pages and confirm the timing line remains available.

## Reroll Unlocked

1. Click **Reroll Unlocked**.
2. Confirm the prior timing line clears when reroll preparation starts.
3. Confirm a new timing line appears when the reroll finishes.
4. Confirm the generated-outfit summary and performance line do not overwrite one another.

## Scan separation

1. Hover the normal wardrobe-status area.
2. Confirm the tooltip remains **Wardrobe Scan Details** and contains scan information only.
3. Click **Scan Collection** and confirm scan progress uses the normal status area without corrupting the last generation-performance field.
4. Generate another outfit and confirm the performance line updates normally.

## Regression

1. Confirm Generate Outfit and Reroll Unlocked remain cooperative and atomic.
2. Confirm linked and unlinked weapon generation remains correct.
3. Confirm `/qc traveler debug` remains calibrated instrumentation only.
4. Confirm no Lua errors occur.
