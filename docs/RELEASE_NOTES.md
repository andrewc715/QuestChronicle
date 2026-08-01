# Quest Chronicle v1.6.5: Preview Rollback and Fury Off-Hand Repair

Version 1.6.5 is an emergency stabilization release after the v1.6.3 and v1.6.4 preview experiments caused model corruption and still failed to generate Fury's second one-handed weapon.

## What the live screenshots proved

- Quest Chronicle correctly detected Fury's dual-two-hand physical topology.
- Blizzard correctly allowed one-hand appearance categories in both equipped weapon hands.
- Main-hand one-hand generation succeeded.
- The secondary generated selection was rejected by older appearance `isUsable` fields even though Blizzard's native slot-and-option API allowed it.
- The deferred `OnModelLoaded` and slot-explicit preview pipeline could leave the embedded actor tiny, dark, partially dressed, or otherwise corrupted.

## Changes

- Completely removes the v1.6.3/v1.6.4 deferred model-load preview experiment.
- Removes preview tokens, pending model callbacks, timer fallbacks, and per-slot `SetItemTransmogInfo()` dressing from the embedded preview.
- Restores the stable synchronous player-model and `TryOn()` path used before those experiments.
- Keeps explicit Main Hand and Secondary Hand targets when previewing weapon selections.
- Treats Blizzard's native `GetCollectionInfoForSlotAndOption()` permission as authoritative for specialization exceptions.
- Prevents older `appearance.isUsable`, `appearanceIsUsable`, and `isAnySourceValidForPlayer` fields from vetoing a category Blizzard's current Transmog UI explicitly permits for that hand.
- Still requires a collected preview source and rejects explicit collection or display failures.
- Preserves strict linked-hand behavior: exact visual first, same exact weapon subtype second, never an unrelated type.

## Expected Fury behavior

With two two-handed weapons physically equipped, One-Hand enabled, Two-Hand disabled, One-Handed Sword selected, and Link weapon hands enabled:

- Quest Chronicle selects a one-handed sword for Main Hand.
- Quest Chronicle selects the same visual, or another one-handed sword, for Secondary Hand.
- Current Preview lists both generated selections rather than labeling Secondary Hand as equipped.
- The embedded character remains full-sized and fully dressed.

## Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 6.
- No wardrobe scan or concept migration is required.
- Existing concepts, Custom Set links, Chronicle records, RP notes, and Courier data are preserved.
