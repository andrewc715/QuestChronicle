# Quest Chronicle v1.6.6 Weapon Option Matrix Test Checklist

## Install

1. Exit World of Warcraft completely.
2. Replace the current `QuestChronicle` addon folder with v1.6.6.
3. Log into Xyrkian as Fury with two two-handed weapons equipped.
4. Open `/qc` and select **Outfits**.

No wardrobe rescan is required solely for this update.

## Confirm the topology remains physical

The center summary should continue to report:

```text
Dual two-handed weapons equipped
```

Quest Chronicle should not relabel the physical equipment as dual one-hand merely because one-hand appearances are permitted.

## Inspect subtype permission

1. Open the **One-Hand** subtype flyout.
2. Hover an available one-hand type such as **One-Handed Sword**.
3. Confirm the tooltip says Blizzard permits it through a named enabled weapon option, such as **One-Handed Weapon**, rather than only referring to the equipped two-hand option.
4. Confirm types Blizzard does not permit remain disabled.

## Fury linked one-hand generation

1. Enable **One-Hand**.
2. Disable **Two-Hand**, **Ranged**, and **Off-Hand**.
3. In the One-Hand flyout, select only **One-Handed Sword**.
4. Enable **Link weapon hands**.
5. Click **Generate Outfit** several times.
6. Open **Current Look** after each generation.

Expected:

- `One-Hand` is **Selected**.
- `Off-Hand` is also **Selected**, never merely **Equipped**.
- Both selections are one-handed swords.
- The two hands use the same visual when WoW accepts it, otherwise another one-handed sword.
- No axe, mace, staff, polearm, or physically equipped two-hander is substituted while linking is enabled.

## Preview

Confirm the embedded model:

- remains full-sized and fully dressed;
- shows a generated one-handed weapon in Main Hand;
- shows a generated one-handed weapon in Secondary Hand;
- does not retain the physically equipped secondary two-hander.

## Two-hand regression

1. Disable **One-Hand**.
2. Enable **Two-Hand**.
3. Select one or more permitted two-hand subtypes.
4. Generate several outfits.

Expected:

- both weapon hands continue to generate correctly;
- Current Look lists both selected weapon layers where applicable;
- no character-model corruption returns.

## Independent-hand regression

1. Re-enable One-Hand.
2. Turn off **Link weapon hands**.
3. Generate repeatedly.

Expected:

- both hands are still generated when Blizzard permits them;
- each hand may choose independently from the enabled subtype pool.

## Non-Fury guard

When testing another specialization or character whose native weapon-option list does not expose a one-hand option over the equipped two-hander:

- One-Hand should remain unavailable;
- Quest Chronicle must not infer the Fury exception from the collection cache alone.

If a failure remains, capture:

- the physical-topology summary;
- the One-Hand subtype tooltip;
- the Current Look weapon rows;
- any Lua error.
