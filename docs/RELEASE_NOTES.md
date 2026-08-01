# Quest Chronicle v1.0.4: AddOn Compartment Fix

Version 1.0.4 is a focused access-point repair following the successful v1.0.3 outfit-interface polish.

## Fixed

- Corrects the `AddonCompartmentFuncOnEnter` callback signature.
- Blizzard passes `(addonName, menuButtonFrame)` to the hover callback. Quest Chronicle previously treated the addon-name string as the tooltip owner, causing `GameTooltip:SetOwner(region)` usage errors.
- The tooltip now anchors to Blizzard's actual AddOn Compartment menu button.
- Left-click still toggles the main Quest Chronicle window.
- Right-click still opens **Status & Maintenance**.
- Leaving the tray entry cleanly hides the tooltip.

## Access behavior

Quest Chronicle is already registered in Blizzard's native AddOns tray through TOC metadata. v1.0.4 repairs that existing integration; it does not add a second standalone minimap icon or a new library dependency.

## Preserved

- SavedVariables schema 2.
- Courier format 1.
- Wardrobe cache and outfit concepts.
- Linked and verified WoW Custom Sets.
- Quest history, active quests, RP notes, settings, and window state.
