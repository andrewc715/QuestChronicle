# Quest Chronicle v1.6.7 Linked Weapon Option-Owner Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the existing `QuestChronicle` addon folder with v1.6.7.
3. Log into Xyrkian as Fury.
4. Open `/qc` and select **Outfits**.

No wardrobe rescan is required solely for this update.

## Confirm physical topology

With two two-handed weapons equipped, verify the center panel still says:

```text
Dual two-handed weapons equipped
```

This label should not change when one-handed appearance families are selected. It describes physical equipment, not transmog appearance permission.

## Linked one-hand generation

1. Enable **One-Hand**.
2. Disable **Two-Hand**, **Ranged**, and **Off-Hand**.
3. Open One-Hand types and select one collected subtype, preferably **One-Handed Sword**.
4. Enable **Link weapon hands**.
5. Click **Generate Outfit** several times.

Expected Current Preview:

```text
One-Hand    <generated appearance>    Selected
Off-Hand    <linked appearance>       Selected
```

The Off-Hand line must not remain `Equipped`.

Expected model:

- both physical weapon hands display one-handed appearances;
- exact same visual is preferred;
- another appearance from the same exact subtype is acceptable when WoW rejects the duplicate;
- an unrelated axe, mace, staff, or two-hander must not appear as a fallback when only One-Handed Sword is selected.

## Reroll coverage

Repeat the check with:

- **Reroll Unlocked**;
- rerolling the main weapon slot;
- manually selecting a one-handed Main Hand appearance from the browser.

With linking enabled, each path should update the Secondary Hand selection as well.

## Two-hand regression

1. Disable One-Hand.
2. Enable Two-Hand.
3. Select one Two-Hand subtype.
4. Generate several outfits.

Expected:

- both weapon hands remain generated and selected;
- the stable two-handed preview behavior remains unchanged.

## Non-Fury guard

On a character or specialization where Blizzard exposes no one-handed option for the linked weapon pair:

- One-Hand must remain unavailable;
- Two-Hand must remain available when appropriate;
- Quest Chronicle must not invent the Fury exception.

## Report useful evidence

If the issue remains, capture:

- the physical topology line;
- the `Allowed:` summary;
- the One-Hand subtype flyout;
- Current Preview weapon rows;
- any Lua error from BugGrabber.
