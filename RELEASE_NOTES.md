# Quest Chronicle v0.6.2: Concept Manager and Visible Locks

Version 0.6.2 completes two Outfit Workbench pieces that were functionally present but not ready for live use: saved concepts and locked-slot visibility.

## Complete Outfit Concepts manager

The fragile name popup and load context menu have been replaced by a self-contained **Outfit Concepts** manager inside Quest Chronicle. It provides:

- a visible concept-name field;
- **Save / Update** for the current preview;
- case-insensitive overwrite when an existing name is saved again;
- a paged list showing appearance, lock, and hidden-slot counts plus update time;
- explicit selection and **Load Selected**;
- two-step confirmed deletion;
- a live concept count on the main **Concepts** button.

Saved concepts remain character-specific and include selected appearance source IDs, locked slots, hidden helm/cloak/shirt/tabard state, and weapon configuration. Existing concepts written by v0.6.0 or v0.6.1 remain readable. Concept identifiers now avoid collisions even after older concepts are deleted and another is saved during the same second.

## Visible lock state

Locked equipment-slot buttons now show both a gold padlock and a persistent two-pixel gold border. The lock remains visible when another slot is selected and when the locked button itself is the disabled active slot. The previous tiny trailing `L` marker has been removed.

The active appearance header still says **Locked**, and its action changes to **Unlock Slot**, providing confirmation in both the slot list and detail panel.

## Preserved behavior

- Equipped main- and off-hand weapon validation from v0.6.1.
- Dual-wield, two-hand, ranged, empty-hand, and incompatible-lock handling.
- Native bottom navigation tabs.
- Wardrobe cache format 5; no collection rescan is required.
- SavedVariables schema 2.
- Courier format 1 and Courier v1.0.0 compatibility.
- Quest history, active quests, notes, drafts, settings, wardrobe cache, and existing concepts.
- Preview only; Quest Chronicle never applies transmog or changes Blizzard outfit slots.
