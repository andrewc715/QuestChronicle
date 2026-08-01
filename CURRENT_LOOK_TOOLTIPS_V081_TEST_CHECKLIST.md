# Quest Chronicle v0.8.1 Live Test Checklist

## Selected appearance parity

1. Open `/qc`, choose **Outfits**, and generate or manually assemble a preview.
2. Hover a selected appearance in the main browser and note its compatibility, generated-pool reason, active style score, and preference text.
3. Open **Current Look** and hover the same selected layer.
4. Confirm Current Look shows the same appearance name, Source ID, Item ID, compatibility, generated-pool reason, style score, matching terms, and zone-preference state.
5. Confirm the first detail line identifies `Selected` plus `Locked` or `Hidden` when applicable.

## Style and preference changes

1. Switch among **Zone**, **Traveler**, **Class**, and **Echo**.
2. Reopen or hover Current Look and confirm its score label follows the selected mode.
3. Mark the appearance **Favor in Zone** and confirm both tooltips show the favorite explanation.
4. Change it to **Exclude in Zone** and confirm both tooltips show the exclusion and identical generated-pool reason.

## Equipped-only rows

1. Reset the preview so at least one slot uses currently equipped gear.
2. Open Current Look and hover that equipped-only row.
3. Confirm the tooltip shows the equipped item name, slot, and Item ID when available.
4. Confirm it explains that no collected appearance is overriding the slot and does not invent an appearance score.

## Regression

1. Confirm Current Look still lists only the active weapon configuration.
2. Confirm hidden layers remain desaturated and locked layers retain their state.
3. Confirm browser-row clicking and tooltips still work normally.
4. Confirm Chronicle Echo, generated outfit names, concepts, and per-zone preferences remain intact after `/reload`.

## Pass criteria

- Selected Current Look and browser tooltips expose the same appearance intelligence.
- Equipped-only rows remain truthful and omit unsupported scoring.
- Wardrobe cache format 5, SavedVariables schema 2, and Courier format 1 remain unchanged.
