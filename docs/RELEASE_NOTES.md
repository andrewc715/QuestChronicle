# Quest Chronicle v1.6.0: Weapon Appearance Rules

Version 1.6.0 separates the physical weapon layout from the appearance categories Blizzard currently permits for each equipped hand.

## Why this release exists

The v1.5 family controls correctly detected whether a weapon was physically one-handed, two-handed, ranged, or an off-hand item. Physical topology alone is not enough to model modern transmog rules. Class, specialization, talents, artifacts, and Blizzard exceptions can allow an equipped item to use appearance categories that do not match its inventory type.

Quest Chronicle now uses two independent layers:

1. **Physical topology** from the equipped items' inventory locations.
2. **Appearance capability** from Blizzard's live category validation for each equipped hand.

A Fury warrior can therefore remain physically dual-two-hand while One-Hand and Two-Hand appearance families are both available when Blizzard permits them.

## Equipment Slot UI

Weapon controls move out of the character-preview panel and into a dedicated **Weapon Appearances** section beneath the armor slots.

Each family row contains:

- a generation checkbox;
- a row that opens the corresponding appearance browser;
- a `>` type-configuration control;
- selected/available type counts;
- current preview and lock indicators.

The character-preview panel now uses a compact weapon summary instead of four detached checkboxes.

## Exact weapon-type filters

### One-Hand

- Wand
- One-Handed Axe
- One-Handed Sword
- One-Handed Mace
- Dagger
- Fist Weapon
- Warglaive
- Paired Artifact

### Two-Hand

- Two-Handed Axe
- Two-Handed Sword
- Two-Handed Mace
- Staff
- Polearm

### Ranged

- Bow
- Gun
- Crossbow

### Off-Hand

- Shield
- Holdable / Focus

The type flyout offers **All Compatible**, **Equipped Type**, **Clear**, and **Done**. Types with no collected previewable appearances or which Blizzard rejects for the equipped hand remain visible but dimmed with an explanatory tooltip.

## Per-hand capability matrix

Quest Chronicle evaluates the main hand and off hand separately. This supports:

- single two-handed weapons;
- dual one-handed weapons;
- dual two-handed weapons;
- mixed weapon hands;
- weapon plus shield/focus;
- ranged weapons;
- unarmed preview generation.

`IsCategoryValidForItem()` is used only for appearance permission. The equipped item's inventory location remains authoritative for physical topology.

Permissions refresh when equipment, specialization, active talent group, or trait configuration changes. No wardrobe rescan is required.

## Linked weapon hands

**Link weapon hands** is enabled by default when two weapon hands are present. Linked generation prefers the same broad family and exact type in both hands. If Blizzard cannot provide the linked type for the second hand, Quest Chronicle falls back to another selected and permitted type with a notice.

Disabling the option allows each hand to generate independently.

## Browser and generation integration

The appearance browser and all generation operations use the same effective filters:

- Generate Outfit
- Reroll Unlocked
- Reroll Slot
- weapon-family browsing

Quest Chronicle chooses an enabled exact type first, then chooses an eligible appearance inside that type. This gives selected weapon types a fair initial chance even when their collection sizes differ greatly.

## Saved concepts and Custom Sets

Outfit concepts now preserve:

- broad weapon-family choices;
- exact subtype choices;
- linked-hands preference.

Existing concepts migrate with every subtype enabled, preserving previous behavior. Loading a concept restores dormant preferences and intersects them with current Blizzard permissions.

Custom Set slot mapping, collected-source rebinding, and readback verification remain unchanged. The secondary weapon slot now accepts collected one-hand, two-hand, or ranged sources when Blizzard's rules permit them.

## Compatibility

- Addon version: `1.6.0`
- SavedVariables schema: `2`
- Courier format: `1`
- Wardrobe cache format: `6`

No wardrobe rescan is required solely for this update.
