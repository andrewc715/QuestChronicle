# Quest Chronicle v1.8.0 Code Normalization Test Checklist

v1.8.0 is intended to behave exactly like the validated v1.7.2 build. This checklist looks for accidental restructuring regressions rather than new features.

## Installation and data preservation

1. Exit World of Warcraft completely.
2. Back up `QuestChronicle.lua` from the account SavedVariables folder.
3. Replace the addon folder with v1.8.0.
4. Log into Xyrkian.
5. Confirm existing Chronicle records, active quests, wardrobe cache, concepts, Custom Set links, preferences, and preview selections remain present.

No migration or wardrobe rescan should be required.

## Core recorder

1. Accept a quest.
2. Advance an objective.
3. Turn in or abandon a disposable quest when practical.
4. Run `/qc recent 20`.
5. Confirm the event sequence and summaries remain correct.
6. Run `/qc export`, followed by `/reload`.
7. Confirm the Courier watcher processes the refreshed snapshot normally.

## Main interface

Open every tab:

- Chronicle
- Active Quests
- Write Note
- Status
- Outfits

Confirm window resizing, remembered position, minimap button, AddOn Compartment entry, and Settings still function.

## Outfits regression

1. Confirm the cached collection is available without a forced rescan.
2. Generate each available style mode.
3. Open Current Preview and inspect all selected layers.
4. Save and reload a Quest Chronicle concept.
5. Update or create a native Custom Set and confirm verification succeeds.

## Weapon route regression

With Xyrkian's Fury dual-two-hand layout:

1. Generate a linked One-Hand pair.
2. Confirm Main Hand and Off Hand are both selected.
3. Generate an unlinked One-Hand pair and confirm both remain inside the One-Hand route.
4. Generate a linked Two-Hand pair.
5. Run `/qc weapon debug` and confirm both source IDs are present.
6. Confirm Ranged and shield/focus Off-Hand remain topology-gated out.

## Structural validation

From the addon root, run:

```text
python tools/verify_lua_line_limit.py
```

Expected result:

```text
PASS: every Lua file is at or below 500 lines.
```

## Failure evidence

For any regression, capture:

- the affected tab or command;
- the first Lua error;
- `/qc status`;
- `/qc weapon debug` for weapon issues;
- whether the same SavedVariables work after restoring v1.7.2.
