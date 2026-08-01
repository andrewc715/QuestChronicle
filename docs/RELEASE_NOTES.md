# Quest Chronicle v1.0.2: Complete Custom Set Handoff Repair

Version 1.0.2 repairs the disconnect between Quest Chronicle's complete outfit preview and Blizzard's partial Custom Set result.

## What the live screenshots proved

The native set retained only Head and Chest. Those are inventory slot IDs 1 and 5, and they were the only two positions that accidentally matched Quest Chronicle's old compact transmog-category list. Other appearances were placed at indices Blizzard interpreted as Neck, Shirt, rings, trinkets, or unrelated equipment slots, so the Custom Sets system quietly discarded them.

A second risk also existed beneath that mapping bug: a collected visual can have several sibling item sources. Quest Chronicle's preview only needs one source capable of rendering the visual, but Blizzard Custom Sets need a source the account actually owns.

## Fixed

- Builds the Custom Set payload through `INVSLOT_LAST_EQUIPPED` rather than a compact 17-entry category layout.
- Resolves every destination through `GetInventorySlotInfo(definition.slotName)` with Retail inventory-slot fallbacks.
- Correctly maps:
  - Head 1
  - Shoulders 3
  - Shirt 4
  - Chest 5
  - Waist 6
  - Legs 7
  - Feet 8
  - Wrists 9
  - Hands 10
  - Back 15
  - Main Hand 16
  - Off Hand 17
  - Tabard 19
- Re-resolves every selected visual to a genuinely collected and displayable source before saving.
- Encodes hidden Head, Back, Shirt, and Tabard choices using Blizzard's hidden visual source rather than leaving the previous appearance behind.
- Rejects the entire native save when any selected or hidden slot cannot be resolved. Quest Chronicle will never deliberately create another partial recipe.
- Detects conflicting stale weapon selections that target the same inventory slot.
- Recovers a same-name partial v1.0.1 Custom Set and replaces it instead of creating a duplicate.
- Reads the native Custom Set back and verifies every intended inventory slot.
- Accepts Blizzard substituting a different collected source only when it represents the same visual appearance.
- Stores the resolved source manifest and verification report on the authoritative Quest Chronicle concept.

## Wardrobe source rebuild

Wardrobe cache format advances from 5 to 6. The first v1.0.2 login or manual **Scan Collection** rebuilds each visual around a source WoW confirms is actually collected. Saved concepts, visual identities, locks, hidden slots, generated names, and native Custom Set links are preserved.

## Expected result

For the reported Blade's Edge Mountains concept, a healthy save should report something like:

```text
Custom Set saved and verified: 12/12 selected slots matched.
```

The native Custom Sets preview should then reproduce the Quest Chronicle concept across Head, Shoulders, Back, Chest, Shirt, hidden Tabard, Wrists, Hands, Waist, Legs, Feet, and the Two-Hand weapon.

## Compatibility

- Addon version: 1.0.2
- SavedVariables schema: 2
- Courier format: 1
- Wardrobe cache format: 6

Warcraft Quest Chronicle Courier v1.0.0 remains compatible. Chronicle events, RP notes, active quests, Courier data, concepts, and Custom Set IDs are retained.
