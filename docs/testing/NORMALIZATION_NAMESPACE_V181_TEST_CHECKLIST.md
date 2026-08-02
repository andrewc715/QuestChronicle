# Quest Chronicle v1.8.1 Normalization Namespace Test Checklist

## Installation

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` folder with v1.8.1.
3. Log into Xyrkian or use `/reload`.

## Automatic wardrobe scan

1. Wait for the one automatic login/reload scan.
2. Confirm no Lua error appears from `ApplyScanCollectionState`.
3. Open **Status & Maintenance** and confirm the wardrobe eventually reports Current.
4. Open **Outfits** and verify cached appearance counts are populated.

## Preview helper

1. Generate an outfit.
2. Confirm the embedded character model resets and displays the selected armor and weapons.
3. Confirm no Lua error appears from `Wardrobe.ApplyPreview`.

## Route shuffling helper

1. Enable a weapon family with more than one valid route, such as Fury One-Hand.
2. Click **Generate Outfit** several times.
3. Confirm generation succeeds without a global `Shuffle` error.
4. Run `/qc weapon debug` and verify a complete route and both expected hand selections are reported.

## Regression

- Chronicle, Active Quests, Write Note, Status, and Outfits tabs open.
- `/qc export` followed by `/reload` still updates SavedVariables.
- Saved concepts and linked Custom Sets remain present.
- One-Hand and Two-Hand pair generation remain functional.
- Current Preview still labels generated weapons as Main Hand and Off Hand.
