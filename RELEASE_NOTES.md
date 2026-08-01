# Quest Chronicle v0.4.0 Release Notes

Version 0.4.0 gives Quest Chronicle its own native-styled home without altering Blizzard's Quest Log.

The tested v0.3.0 lifecycle recorder remains the engine. A small public API now exposes safe read and action methods to separate UI modules, keeping the interface from reaching into private tracking state.

## First-release scope

- Chronicle event browser
- Active quest and objective browser
- Multiline RP-note editor
- Status and maintenance dashboard
- Recording controls
- WoW AddOns settings category
- AddOn Compartment launcher
- Remembered and lockable window placement

## Compatibility promises

- Existing Chronicle history is preserved.
- Data schema remains version 2.
- Courier export format remains version 1.
- Warcraft Quest Chronicle Courier v1.0.0 requires no structural update.
- Every v0.3.0 slash command remains available.

## First live-test priorities

The mock harness validated UI creation, tab switching, v0.3.0 data preservation, note recording, Courier refresh, lifecycle progression, turn-in handling, and confirmed abandonment. The live client still needs to validate Blizzard frame templates, AddOn Compartment metadata, window interaction, and the modern Settings panel on the installed Retail build.
