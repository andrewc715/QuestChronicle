# Quest Chronicle v0.5.1: Wardrobe Collection Hotfix

Version 0.5.1 corrects the first live-client defect discovered in the Wardrobe Foundation scanner.

## Fixed

- The scanner now queries Blizzard's account transmog collection with the equipment-slot-specific `TransmogLocation` expected by the current Retail wardrobe APIs.
- Armor collection category fallback IDs are corrected: Shoulder 2, Back 3, Chest 4, Shirt 5, and Tabard 6.
- Category enum values are resolved at scan time instead of addon load time, preventing early-loading enum gaps from silently swapping equipment categories.
- The scan temporarily uses a clean collected-only, all-source-types collection view and restores the player's prior collection filters and search afterward.
- The scanner refuses to start while Blizzard's Transmogrify or Wardrobe frame is open, preventing the temporary scan context from repainting or disturbing the live Blizzard interface.
- Collected source detection now has fallbacks through `PlayerKnowsSource`, appearance-source information, valid-class sources, and the full source list for a visual.
- The wardrobe cache advances to version 2, automatically invalidating the incomplete v0.5.0 cache.
- Per-slot diagnostics now compare compatible cached visuals with the collected count reported by WoW.
- A cache built for another character is invalidated because display compatibility can differ by class and character.

## Preserved

- SavedVariables schema remains 2.
- Courier format remains 1.
- Chronicle history, active quest tracking, RP notes, drafts, UI settings, and Courier compatibility are unchanged.
- v0.5.1 still designs and previews only. It does not apply transmogrification or modify WoW outfit slots.
