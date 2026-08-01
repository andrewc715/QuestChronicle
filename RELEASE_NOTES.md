# Quest Chronicle v0.6.0: Outfit Workbench

Version 0.6.0 builds the first complete outfit-design workflow on the validated native-scale wardrobe scanner and embedded character preview.

The main Quest Chronicle navigation now uses Blizzard-style top tabs instead of five wide red push-buttons. The selected tab visually joins the content panel while preserving the remembered last tab and existing tooltips.

## Generate and refine

- **Generate Outfit** chooses a complete random set of cached armor appearances plus a valid weapon configuration.
- **Reroll Unlocked** replaces every unlocked choice while keeping locked and hidden decisions intact.
- **Reroll Slot** replaces only the active equipment slot.
- **Lock Slot** protects a piece from generation and bulk rerolls.
- Manual appearance selection continues to work through the seven-row paged browser.

## Optional visibility

Head, Back, Shirt, and Tabard expose **Hide Slot** and **Show Slot** controls. Hiding a slot removes it from the embedded model without forgetting its appearance. Saved concepts remember visibility choices.

## Weapon rules

The workbench maintains one valid main-hand mode:

- One-Hand may be paired with an Off-Hand appearance.
- Two-Hand clears One-Hand, Ranged, and Off-Hand selections.
- Ranged clears One-Hand, Two-Hand, and Off-Hand selections.
- Choosing an Off-Hand appearance automatically supplies a cached One-Hand appearance when needed.
- Generation honors compatible locked weapon choices and reports conflicting imported locks instead of producing an invalid outfit.

## Saved concepts

**Save Concept** stores a named character-specific concept containing:

- selected source IDs by slot;
- locked slots;
- hidden helm, cloak, shirt, and tabard choices;
- the resulting weapon configuration;
- creation and update timestamps.

Saving with the same name updates that concept. **Load Concept** opens a menu of the current character's concepts. Missing collection entries are skipped safely and reported when loading.

## Compatibility

- Addon version 0.6.0.
- Wardrobe cache format 5; no rescan is required when upgrading from v0.5.5 or v0.5.6.
- SavedVariables schema 2.
- Courier format 1 and Courier v1.0.0 compatibility.
- Quest history, active quests, notes, drafts, settings, and existing manual selections remain intact.
- Preview only; Quest Chronicle never applies transmog or changes Blizzard outfit slots.
