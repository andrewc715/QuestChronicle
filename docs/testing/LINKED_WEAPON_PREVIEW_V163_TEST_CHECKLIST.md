# Quest Chronicle v1.6.3 Linked Weapon Preview Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.6.3.
3. Log into the Fury Warrior used for the v1.6.2 test.
4. No wardrobe rescan is required.

## Exact live regression

1. Equip two two-handed weapons.
2. Open `/qc` and select **Outfits**.
3. Enable **One-Hand** and disable other weapon families.
4. In One-Hand Types, select only **One-Handed Sword**.
5. Enable **Link weapon hands**.
6. Click **Generate Outfit**.
7. Confirm both visible hands now show:
   - the exact same one-handed sword visual, or
   - two one-handed sword visuals when Blizzard refuses the exact duplicate.
8. Confirm the physically equipped two-handed off-hand axe or mace no longer remains visible beneath a supposedly linked preview.

## Manual and reroll paths

1. Manually select a one-handed sword from the browser.
2. Confirm both hands update immediately.
3. Click **Reroll Slot** while browsing One-Hand.
4. Confirm the second hand remains linked.
5. Click **Reroll Unlocked** and repeat.

## Independent mode

1. Disable **Link weapon hands**.
2. Generate again.
3. Confirm the two hands may now use different selected-compatible weapon appearances.

## Failure reporting

If WoW refuses a selected hand, Quest Chronicle should report the named slot, such as:

```text
Previewed 12 selected appearances; WoW could not apply Off-Hand.
```

Report the message, the selected source IDs, and any Lua error.

## Regression

- Save Concept still preserves linked-hands preference.
- Custom Set save and 11/11 verification still work.
- Chronicle, Active Quests, Write Note, Status, minimap, and Courier behavior remain unchanged.
