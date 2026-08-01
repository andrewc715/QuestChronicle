# Quest Chronicle v1.6.8 Inventory Slot Enum Test Checklist

## Install

1. Exit WoW completely.
2. Replace the current QuestChronicle folder with v1.6.8.
3. Log into Xyrkian as Fury with both two-handed weapons equipped.
4. No wardrobe rescan is required.

## Diagnostics first

Run:

`/qc weapon debug`

The output should show:

- Inventory slots: Main Hand 16 -> enum 15
- Inventory slots: Off Hand 17 -> enum 16
- distinct resolved Main Hand and Off Hand outfit slots
- the same linked option owner for both hands when Blizzard reports the pair as linked

If the output differs, capture the chat lines before testing generation.

## Linked one-hand generation

1. Enable One-Hand.
2. Disable Two-Hand.
3. Open One-Hand Types and select One-Handed Sword only.
4. Enable Link weapon hands.
5. Click Generate Outfit.
6. Open Current Look.

Expected:

- One-Hand is `Selected`.
- Off-Hand is `Selected`, not `Equipped`.
- both selections use the same visual when possible, otherwise the same exact subtype.

Run `/qc weapon debug` again. It should print non-nil Main Hand and Off Hand selections.

## Two-hand regression

1. Disable One-Hand.
2. Enable Two-Hand.
3. Generate again.
4. Confirm the existing dual-two-hand behavior remains intact.

## Other regression checks

- Character model remains full-sized and dressed.
- Chronicle, Active Quests, Write Note, Status, minimap button, and AddOn Compartment still work.
- Saving and updating a Custom Set still verifies every selected slot.
