# Quest Chronicle v1.7.1 Physical Weapon Pair Routes Test Checklist

## Installation

1. Exit World of Warcraft completely.
2. Replace the current `QuestChronicle` addon folder with v1.7.1.
3. Log into the Fury Warrior with two two-handed weapons equipped.
4. Open Quest Chronicle and select **Outfits**.

No wardrobe rescan is required solely for this update.

## Route diagnostics

Run:

```text
/qc weapon debug
```

Confirm the output reports:

```text
Topology: Dual two-handed weapons equipped
Inventory slots: MH 16 | OH 17
Outfit slots: MH <main> | OH <secondary>
physical pair true
native linked pair false
```

`native linked pair false` is valid. The physical pair must still create pair routes.

Confirm the route list contains at least one of each Blizzard-permitted family:

```text
ONE_HAND_PAIR ... primary > 0 secondary > 0
TWO_HAND_PAIR ... primary > 0 secondary > 0
```

Confirm it does not contain an available `RANGED_SINGLE` route for this dual-melee topology.

A Ranged option may appear only as:

```text
SUPPRESSED RANGED ... incompatible with the current physical topology
```

## Family panel

For the current Fury layout, verify the panel is approximately:

```text
One-Hand: available
Two-Hand: available
Ranged: 0 available types
Off-Hand: 0 available types
```

Exact One-Hand and Two-Hand subtype counts depend on Blizzard's live rules and the collected wardrobe.

## Linked One-Hand generation

1. Enable **One-Hand**.
2. Disable **Two-Hand**.
3. Select one or more valid One-Hand subtypes.
4. Enable **Link weapon hands**.
5. Click **Generate Outfit**.
6. Open **Current Look**.

Confirm:

```text
One-Hand: Selected
Off-Hand: Selected
```

Both entries should use the same visual when possible, otherwise the same exact subtype.

Run `/qc weapon debug` again and confirm:

```text
Last route: ... [ONE_HAND_PAIR]
Selections: MH <sourceID> | OH <sourceID> | linked true
```

## Linked Two-Hand generation

1. Enable **Two-Hand**.
2. Disable **One-Hand**.
3. Select one or more valid Two-Hand subtypes.
4. Leave **Link weapon hands** enabled.
5. Generate again.

Confirm both Main Hand and Secondary Hand are selected and the last route is `TWO_HAND_PAIR`.

## Unlinked generation

1. Enable one valid family.
2. Disable **Link weapon hands**.
3. Generate repeatedly.

The two hands may differ, but both must remain inside the selected family route.

## Companion regression

On a character or loadout using a one-hand weapon plus shield/focus:

- One-Hand and Off-Hand companion routes may be available.
- Generating a One-Hand route may include the shield/focus.
- Generating a Two-Hand route must clear an unlocked shield/focus rather than preserve it.

## Ranged regression

On a character with an actual bow, gun, or crossbow equipped:

- Ranged should be available.
- One-Hand and Two-Hand must not leak in unless Blizzard exposes a valid route appropriate to that physical presentation.

## General regression

- Character preview remains full-sized and fully dressed.
- Chronicle, Active Quests, Write Note, Status, concepts, and Custom Sets remain functional.
- `/qc export` and `/reload` remain unchanged.
