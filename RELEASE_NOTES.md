# Quest Chronicle v0.6.1: Equipped-Weapon Rules and Bottom Tabs

Version 0.6.1 corrects generated weapon choices and finishes the main-window tab treatment requested during Outfit Workbench testing.

## Equipped-weapon-safe generation

**Generate Outfit**, **Reroll Unlocked**, and individual weapon rerolls now start with the items currently equipped in `MAINHANDSLOT` and `SECONDARYHANDSLOT`.

For every generated weapon visual, Quest Chronicle asks WoW to confirm:

- the visual's collection category is valid for the equipped item;
- the collapsed visual is still collected, displayable, and usable;
- at least one source for the visual is valid for the current character.

The generator no longer chooses randomly between One-Hand, Two-Hand, and Ranged just because those caches contain entries. An equipped two-hand weapon produces only Blizzard-valid two-hand choices, an equipped ranged weapon produces only valid ranged choices, and an empty hand is left unchanged. Shields and held items draw from the Off-Hand cache; dual-wield off-hand weapons reuse the One-Hand cache but are revalidated against `SECONDARYHANDSLOT` and the actual equipped off-hand item.

Locked weapon appearances are revalidated against the current equipment before any unlocked armor changes. If gear changed after a concept was locked, generation stops with an actionable unlock-or-equip message instead of preserving an impossible weapon combination.

The scanner remains intentionally broad so the manual appearance browser still matches Blizzard's collapsed Wardrobe catalog. Strict equipped-item checks apply only to generated and rerolled weapons.

## Bottom navigation tabs

Chronicle, Active Quests, Write Note, Status, and Outfits now use Blizzard's bottom `PanelTabButtonTemplate` treatment. The tabs sit along the lower edge of the window like Journeys, Traveler's Log, Suggested Content, Dungeons, Raids, and Tutorials. Removing the top tab row also returns that vertical space to the active page.

## Compatibility

- Addon version 0.6.1.
- Wardrobe cache format 5; upgrading from v0.6.0 does not require a collection rescan.
- Existing manual selections and v0.6.0 saved outfit concepts remain readable.
- SavedVariables schema 2.
- Courier format 1 and Courier v1.0.0 compatibility.
- Quest history, active quests, notes, drafts, settings, and saved concepts remain intact.
- Preview only; Quest Chronicle never applies transmog or changes Blizzard outfit slots.
