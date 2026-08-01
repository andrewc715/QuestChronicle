# Quest Chronicle v0.9.2: Internal Collection Event Hotfix

Version 0.9.2 stops outfit generation from causing an unnecessary automatic wardrobe rescan.

## Fixed

Quest Chronicle refreshes Blizzard's current-character usable-appearance state before choosing weapons. That check is still required so generated weapons obey the equipped weapon and Blizzard's transmog rules. Blizzard also emits the broad `TRANSMOG_COLLECTION_UPDATED` event for that internal refresh, which v0.9.0 interpreted as a real collection mutation.

v0.9.2 marks the brief usability update as internal and ignores only its matching generic notification. As a result:

- **Generate Outfit** no longer starts a wardrobe scan;
- **Reroll Unlocked** no longer starts a wardrobe scan;
- weapon-slot rerolls no longer start a wardrobe scan;
- Blizzard-safe equipped-weapon validation is preserved;
- genuine source-added, source-removed, and cosmetic-added events still queue an automatic refresh;
- a later external generic collection update still queues an automatic refresh.

The regression harness now simulates both the internal event and a later external event so the guard cannot silence real collection maintenance.

## Also included

- The v0.9.1 two-way Favor/Unfavor and Exclude/Allow repair.
- All v0.9.0 era restriction, collection recovery, performance, zone coverage, settings, and accessibility improvements.

## Compatibility

- SavedVariables schema 2 is preserved.
- Courier format 1 is preserved.
- Wardrobe cache format 5 is preserved.
- Existing concepts, favorites, exclusions, selections, and locks remain compatible.
- No collection rescan is required after updating.
- Preview only: no transmog is applied and no Blizzard outfit slot is changed.

See `INTERNAL_COLLECTION_EVENT_V092_TEST_CHECKLIST.md` for the live verification pass.
