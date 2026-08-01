# Quest Chronicle v0.8.1: Current Look Tooltip Parity

Version 0.8.1 gives selected appearances in **Current Look** the same detailed tooltip used by the main appearance browser.

## What changed

Hovering a selected Current Look row now shows:

- the appearance name;
- Source ID and Item ID;
- current-character compatibility;
- whether it belongs to the generated pool and the full reason;
- the active Zone, Traveler, Class, or Chronicle Echo score and its matching terms;
- the current zone-favorite or zone-exclusion state.

The Current Look-specific line still identifies whether the layer is Selected, Locked, or Hidden. Equipped-only rows use an equipment-focused tooltip because no collected transmog source is overriding that slot and therefore there is no appearance source to score.

Both Current Look and the browser now call one shared tooltip builder, preventing their descriptions from drifting apart again.

## Compatibility

- Wardrobe cache format 5 remains valid; no collection rescan is required.
- SavedVariables schema 2 is preserved.
- Courier format 1 remains compatible.
- Existing history, concepts, generated names, selections, locks, hidden slots, Chronicle Intelligence, and per-zone preferences are unchanged.
- Preview only: no transmog is applied and no Blizzard outfit slot is changed.

See `CURRENT_LOOK_TOOLTIPS_V081_TEST_CHECKLIST.md` for the live verification pass.
