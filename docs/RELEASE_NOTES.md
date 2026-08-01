# Quest Chronicle v1.7.1: Physical Weapon Pair Routes

Version 1.7.1 corrects the route-construction defect exposed by `/qc weapon debug` on a Fury Warrior with two physically equipped two-handed weapons.

## Live evidence

The v1.7.0 diagnostic correctly reported:

```text
Topology: Dual two-handed weapons equipped
Inventory slots: MH 16 | OH 17
Outfit slots: MH 12 | OH 13
```

But it also reported `linked pair false`, then created only `ONE_HAND_SINGLE` and `RANGED_SINGLE` routes. Generation therefore had no Secondary Hand target and committed only Main Hand.

## Root cause

Quest Chronicle incorrectly treated `C_TransmogOutfitInfo.GetLinkedSlotInfo()` as the definition of every dual-weapon pair.

That API describes Blizzard's native primary/secondary appearance relationship for a transmog slot. It does not replace physical equipment topology. Main Hand and Off Hand may be two independent native outfit slots while still forming a real dual-weapon layout that must be generated as one pair.

## Changes

- Adds a distinct `physicalWeaponPair` state derived from equipped Main Hand and Secondary Hand inventory types.
- Retains `nativeLinkedPair` separately for Blizzard-native secondary appearances.
- Keeps the existing `linkedPair` compatibility field generation-facing and maps it to the physical weapon pair.
- Queries Main Hand and Secondary Hand weapon permissions independently.
- Probes primary-slot weapon options against the actual Secondary Hand slot when Blizzard does not list those options independently there.
- Preserves separate Main Hand and Secondary Hand option IDs, option names, owner slots, subtype permissions, and source kinds on every pair route.
- Creates `ONE_HAND_PAIR` and `TWO_HAND_PAIR` whenever both physical hands permit the same family.
- Splits a native option that exposes both One-Hand and Two-Hand categories into separate family-specific routes instead of rejecting the complete option.
- Suppresses Ranged routes for physical melee layouts.
- Restricts Off-Hand to a genuine independent Shield or Holdable / Focus companion slot.
- Prevents a shield or focus from accompanying a generated Two-Hand route.
- Continues validating the full weapon bundle before committing either hand.
- Keeps same-option pair routes preferentially and uses cross-option pair routes only when the secondary hand rejects the primary option.

## Diagnostics

`/qc weapon debug` now distinguishes:

```text
physical pair true
native linked pair false
```

Pair routes display separate native options for both hands:

```text
ONE_HAND_PAIR MH option=One Handed Weapon OH option=One Handed Weapon
TWO_HAND_PAIR MH option=Two Handed Weapon (Fury) OH option=Two Handed Weapon (Fury)
```

Topology-gated permissions are reported explicitly:

```text
SUPPRESSED RANGED ... incompatible with the current physical topology
```

## Expected Fury result

With dual two-handed weapons physically equipped:

```text
One-Hand: available when Blizzard permits it for both hands
Two-Hand: available when Blizzard permits it for both hands
Ranged: unavailable
Off-Hand companion: unavailable
```

Generating a linked One-Hand or Two-Hand outfit must commit both Main Hand and Secondary Hand selections atomically.

## Compatibility

- Addon version: 1.7.1
- SavedVariables schema: 2
- Courier format: 1
- Wardrobe cache format: 6

No wardrobe rescan, concept migration, or Custom Set rebuild is required solely for this update.
