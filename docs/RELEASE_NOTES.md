# Quest Chronicle v1.7.2: Current Preview Hand Labels

Version 1.7.2 is a presentation-only follow-up to the validated v1.7.1 weapon-route engine.

## Changed

The **Current Preview** panel now describes generated weapons by their physical preview slots:

```text
Main Hand    Northern Shortsword    Selected
Off Hand     Northern Shortsword    Selected
```

Previously, a linked Two-Hand pair was collapsed into one row labeled `Two-Hand`, even though the route state contained valid Main Hand and Off Hand selections. One-Hand pairs already displayed two rows, but mixed appearance-family and slot terminology.

## Behavior

- One-Hand pair routes display **Main Hand** and **Off Hand**.
- Two-Hand pair routes display **Main Hand** and **Off Hand**.
- Unlinked pairs display both hands independently.
- Single Ranged or single Two-Hand presentations display only **Main Hand**.
- One-Hand plus shield/focus continues to display **Main Hand** and **Off Hand**.
- The Current Look count now includes both generated hands when both selections exist.

## Unchanged

- Weapon route construction and provenance
- Physical topology detection
- Linked and unlinked generation
- Atomic weapon bundle commits
- Appearance browsing and family filters
- Character preview rendering
- Custom Set export
- SavedVariables schema 2
- Courier format 1
- Wardrobe cache format 6

No wardrobe rescan, concept migration, or Custom Set rebuild is required.
