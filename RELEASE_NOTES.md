# Quest Chronicle v0.5.3: Wardrobe UI Cleanup

Version 0.5.3 keeps the recovered account wardrobe scanner from v0.5.2 and cleans up the Outfits appearance browser around real-world collection sizes.

## What the live test revealed

The scanner successfully found the account collection, but the right-hand browser still used the foundation layout designed around tiny test collections:

- a variable-height diagnostic message pushed into eight fixed appearance rows;
- the eighth row collided with the footer;
- Previous, Next, page text, and Clear Slot competed for the same narrow horizontal strip;
- collected source counts and unique previewable visual counts were presented as though they should match;
- the healthy difference between those totals triggered an alarming red warning.

## Changes

- Reduces the fixed page from eight to seven appearance rows so the minimum window height remains safe.
- Uses a compact, fixed two-line browser header.
- Separates the selected appearance from scan-summary text.
- Moves Clear Slot into the header rather than the pagination footer.
- Anchors Previous and Next to opposite sides with centered page text.
- Adds mouse-wheel page navigation over the appearance browser.
- Adds row hover highlighting.
- Keeps source names and details to single lines so rows cannot unexpectedly grow.
- Replaces the misleading red count warning with neutral diagnostics.
- Explains in a hover tooltip that WoW's collected count is a source count, while Quest Chronicle caches unique character-previewable visuals.
- Preserves detailed returned-appearance, returned-source, compatible-visual, error, and scan-state information in that tooltip.

## Preserved

- Wardrobe cache format 3.
- SavedVariables schema 2.
- Courier format 1.
- The v0.5.2 account collection scanner and staging-cache recovery behavior.
- All Chronicle events, active quest state, RP notes, settings, drafts, and manual preview selections.
- Preview-only behavior. Quest Chronicle does not apply transmog or alter Blizzard outfit slots.
