# Quest Chronicle v1.7.0: Weapon Appearance Routes

Version 1.7.0 replaces the flattened weapon-permission matrix with complete, provenance-preserving weapon appearance routes.

## Why this refactor was necessary

The v1.6.x rule engine correctly discovered Fury's one-handed appearance option, but then merged every category permitted by every native weapon option into one large capability union. That discarded the option that granted each category and caused unrelated families to leak into the UI:

- Ranged could appear available beside Fury's linked melee pair.
- Shield and holdable categories could appear available even though the Secondary Hand was another linked weapon.
- Main Hand and Secondary Hand could be generated from different option families.

The native Transmog UI keeps one weapon option active at a time and queries categories for that specific slot-and-option combination. Blizzard also lets a linked primary weapon slot handle its secondary appearance with the same weapon option. Quest Chronicle now preserves that structure.

## Route model

Quest Chronicle first detects the physical equipment topology, then constructs separate native routes:

- `ONE_HAND_PAIR` or `ONE_HAND_SINGLE`
- `TWO_HAND_PAIR` or `TWO_HAND_SINGLE`
- `RANGED_PAIR` or `RANGED_SINGLE` when Blizzard genuinely exposes such a route
- `OFF_HAND_COMPANION` only for an independent shield or holdable slot

Every route retains:

- native option owner slot;
- weapon option ID and name;
- primary and linked-secondary target slots;
- exact permitted collection categories for each target;
- whether Secondary Hand permission was inherited from Blizzard's linked primary route;
- standard, artifact, or equipped-option provenance.

An option that exposes multiple unrelated main-weapon families is rejected rather than flattened. Unknown or ambiguous data fails closed.

## Correct family behavior

For Fury with dual two-handed weapons, a typical result is now:

```text
One-Hand: available through a complete linked pair route
Two-Hand: available through a complete linked pair route
Ranged: unavailable unless Blizzard exposes a distinct ranged route
Off-Hand: unavailable because Secondary Hand is part of the linked weapon pair
```

A sword generated into Secondary Hand remains part of the One-Hand route. It does not activate the separate Off-Hand family. Off-Hand continues to mean shields and holdables only.

## Atomic generation

Weapon generation now follows this transaction:

1. Choose one valid native route.
2. Choose a selected subtype within that route.
3. Resolve and validate Main Hand.
4. Resolve and validate every required linked or companion target.
5. Commit all weapon selections together.

If any required hand cannot be resolved, no part of the new weapon bundle is committed. This prevents half-applied looks and stale weapons from a previous route.

Linked hands remain strict:

1. exact same visual;
2. same exact subtype;
3. fail the complete route rather than substitute an unrelated weapon family.

With linking disabled, both hands may differ, but they remain inside the same selected route.

## Browser, reroll, and manual-selection behavior

The route-derived capability model now drives:

- Equipment Slot family checkboxes;
- subtype flyouts;
- appearance browser filtering;
- Generate Outfit;
- Reroll Unlocked;
- individual weapon rerolls;
- manual Main Hand selection and linked-secondary synchronization.

The familiar four-family UI is retained. Only the internal permission and generation model changed.

## Diagnostics

`/qc weapon debug` now prints:

- physical topology;
- Main Hand and Secondary Hand inventory and native outfit slots;
- whether Blizzard reports a linked pair;
- every accepted route with its option, route kind, primary subtype count, and secondary subtype count;
- ambiguous options rejected by fail-closed classification;
- the last atomically committed route and source IDs.

## Compatibility

- Addon version: 1.7.0
- SavedVariables schema: 2
- Courier format: 1
- Wardrobe cache format: 6

No wardrobe rescan, concept migration, or Custom Set rebuild is required solely for this update. Existing concepts continue storing user intent, subtype choices, selected appearances, and linked-hand preference. Native option IDs are diagnostic runtime data and are not treated as permanent concept truth.
