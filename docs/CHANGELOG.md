# Changelog

## 1.8.2 - 2026-08-01

### Added

- Excludes race Heritage Armor from automatic outfit generation while the character is below the account's maximum reachable level.
- Detects Heritage Armor through Blizzard transmog-set membership and set metadata rather than item-name blacklists.
- Keeps Heritage appearances visible and manually previewable, with a `Heritage locked` browser label below max level.
- Adds a dedicated progression-restriction module while preserving the 500-line Lua-file cap.

### Preserved

- SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- Weapon Appearance Routes, concepts, Custom Sets, and existing wardrobe data.

## 1.8.1 - 2026-08-01

### Fixed

- Qualified three shared Wardrobe helpers through `Wardrobe._Private` after the v1.8.0 module split.
- Restored the automatic collection scan by changing the orphaned `SafeCall()` in `Foundation.lua` to `P.SafeCall()`.
- Restored preview reset behavior by changing the orphaned `SafeCall()` in `CollectionScanAndPreview.lua` to `P.SafeCall()`.
- Restored route randomization by changing the orphaned `Shuffle()` in `GenerationAndConcepts.lua` to `P.Shuffle()`.
- Added `tools/verify_split_helper_references.py` to prevent private-helper namespace regressions in normalized modules.
- Preserved the 500-line Lua file limit and all v1.7.2 gameplay behavior.

## 1.8.0 - 2026-08-01

### Normalized

- Split every oversized runtime Lua file into focused modules.
- Enforced a hard maximum of 500 physical lines per Lua file.
- Replaced the 4,626-line Wardrobe monolith with eleven ordered modules.
- Split the Chronicle recorder, Zone Style engine, and Outfits constructor into cohesive subsystems.
- Preserved all public addon, Wardrobe, ZoneStyle, and UI APIs.
- Added architecture documentation and an automated line-limit verifier.
- Made no intentional runtime behavior, UI, generation-rule, SavedVariables, Courier, or cache changes.

### Compatibility

- Preserves SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- No wardrobe rescan, concept migration, or Custom Set rebuild is required.

## 1.7.2 - 2026-08-01

### Polished

- Current Preview now labels generated weapons as Main Hand and Off Hand.
- Linked Two-Hand pairs are listed as two selected rows instead of one collapsed family row.
- One-Hand, Two-Hand, and companion layouts now use consistent hand terminology.
- Current Look counts both generated weapon hands when both selections exist.
- Preserved the v1.7.1 route engine and preview behavior unchanged.

## 1.7.1 - 2026-08-01

### Fixed

- Separates physical dual-weapon topology from Blizzard native linked-secondary appearance state.
- Builds One-Hand and Two-Hand pair routes for physically equipped Main Hand and Secondary Hand weapons even when `GetLinkedSlotInfo()` returns no native link.
- Queries each physical hand independently while probing shared primary options against the real Secondary Hand slot when needed.
- Splits mixed Fury options into family-specific pair routes instead of rejecting the full option.
- Topology-gates Ranged out of melee layouts and keeps Shield/Holdable restricted to independent companion slots.
- Stores distinct Main Hand and Secondary Hand native option provenance on pair routes.
- Prevents shields/focuses from remaining attached to generated Two-Hand routes.
- Expands `/qc weapon debug` with physical-pair, native-link, per-hand option, and suppressed-family diagnostics.

### Compatibility

- Preserves SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- No wardrobe rescan, concept migration, or Custom Set rebuild is required.

## 1.7.0 - 2026-08-01

### Changed

- Replaced the flat union of Blizzard weapon-category permissions with provenance-preserving weapon appearance routes.
- Classifies each native weapon option independently and rejects ambiguous multi-family options instead of activating unrelated families.
- Models linked Main Hand and Secondary Hand targets as one complete One-Hand, Two-Hand, or Ranged route.
- Restricts Off-Hand to independent Shield and Holdable / Focus companion routes.
- Generates and validates a complete weapon bundle before committing any selection.
- Keeps linked hands inside the same route and exact subtype.
- Applies route provenance to browser filtering, rerolls, manual selection, and diagnostics.
- Expands `/qc weapon debug` with accepted routes, rejected options, and the last committed route.

### Compatibility

- Preserves SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- No wardrobe rescan, concept migration, or Custom Set rebuild is required.

## 1.6.8 - 2026-08-01

### Fixed

- Corrected the one-based `INVSLOT_*` to zero-based `InventorySlots` conversion used by the Transmog Outfit API.
- Prevented Main Hand native-rule queries from addressing Off Hand and Off Hand queries from addressing Ranged.
- Resolved linked-secondary collection permissions through the linked primary slot.
- Added `/qc weapon debug` live diagnostics for slot mapping, option ownership, capabilities, and selections.
- Preserved the stable synchronous preview path.

## 1.6.7 - 2026-08-01

### Fixed

- Corrected Fury linked-hand permission discovery by treating Main Hand and Secondary Hand as Blizzard's linked weapon-slot pair.
- Uses `GetLinkedSlotInfo()` to identify the primary slot that owns the weapon-option dropdown.
- Resolves the secondary hand with the primary hand's enabled weapon options, matching Blizzard's native Transmog preview behavior.
- Keeps the permission query targeted at the actual secondary slot while sharing the primary option channel.
- Restores linked one-handed Fury generation so both `ONE_HAND` and `OFF_HAND` selections are committed.
- Adds linked-slot diagnostics identifying the primary option owner and secondary target.
- Leaves the stable synchronous preview path untouched.

### Compatibility

- Preserves SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- No wardrobe rescan, concept migration, or Custom Set rebuild is required.

## 1.6.6 - 2026-08-01

### Fixed

- Replaced the single equipped-weapon-option query with Blizzard's complete enabled weapon-option matrix for each hand.
- Enumerates standard and artifact options returned by `GetWeaponOptionsForSlot()`.
- Treats the equipped option as the preferred default rather than the full permission set, matching Blizzard's native Transmog UI.
- Restores Fury secondary-hand one-handed appearance generation while both physical weapons remain two-handed.
- Records the exact native option granting each subtype and exposes it through subtype tooltips.
- Preserves strict linked-hand generation and the stable synchronous preview path from v1.6.5.
- Keeps non-Fury two-handed layouts restricted when Blizzard exposes no one-hand option.

### Compatibility

- Preserves SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- No wardrobe rescan or concept migration is required.

## 1.6.5 - 2026-08-01

### Stabilized

- Rolled back the v1.6.3/v1.6.4 deferred and slot-explicit embedded preview experiment.
- Restored the stable synchronous player model plus targeted `TryOn()` preview path.
- Removed preview tokens, model-load callbacks, delayed off-hand dressing, and preview timer races.
- Fixed Fury one-hand linked generation by treating Blizzard's native slot-and-option permission as authoritative over stale legacy usability flags.
- Preserved collection and display safety checks while allowing specialization-specific weapon appearance rules.
- Added a focused model-stability and Fury secondary-hand regression checklist.

## 1.6.4 - 2026-08-01

### Fixed

- Defers preview dressing until the player actor reports `OnModelLoaded`.
- Cancels stale preview requests when the Outfits UI refreshes several times in quick succession.
- Applies Main Hand before Secondary Hand.
- Replays Secondary Hand on the following timer frame so Fury weapon-option child updates cannot overwrite the linked appearance.
- Stops clearing weapon slots while the actor is still loading.
- Uses the collected source item as the compatibility fallback for explicit hand previews.
- Repairs the black or tiny character-model race introduced by immediate slot assignment.
- Preserves strict same-visual or same-subtype linked-hand selection.

### Compatibility

- Preserves SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- No wardrobe rescan, concept migration, or Custom Set rebuild is required.

## 1.6.3 - 2026-08-01

### Fixed

- Replaced weapon preview `TryOn()` calls with explicit per-inventory-slot `SetItemTransmogInfo()` assignments.
- Applies Main Hand before Secondary Hand and isolates secondary-hand child-item behavior.
- Clears the equipped weapon visual before assigning an explicit generated weapon.
- Verifies the resulting model-slot appearance when `GetItemTransmogInfo()` is available.
- Retains verified `TryOn()` only as a compatibility fallback.
- Reports the exact preview slot WoW refused.
- Fixes linked Fury previews that stored matching one-handed selections but continued displaying the equipped two-handed off-hand weapon.

### Compatibility

- Preserves SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- No wardrobe rescan or concept migration is required.

## 1.6.2 - 2026-08-01

### Fixed

- Strengthened **Link weapon hands** from a loose type preference into an enforced coordination rule.
- Attempts the exact same collapsed visual in both weapon hands first.
- Falls back only to another appearance from the same exact Blizzard weapon subtype.
- Prevents linked generation from substituting an unrelated family or weapon type.
- Keeps manual main-hand selections and main-hand rerolls synchronized with the second hand.
- Leaves the equipped second-hand appearance untouched when no valid linked match exists.
- Updated the Link Weapon Hands tooltip and status text to describe the stricter behavior.

### Compatibility

- Preserves SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- No wardrobe rescan or concept migration is required.

## 1.6.1 - 2026-08-01

### Fixed

- Replaced `IsCategoryValidForItem()` as the primary weapon-appearance permission source.
- Mirrored Blizzard's native `GetCollectionInfoForSlotAndOption()` weapon-category rules per equipped hand.
- Restored Fury Warrior one-handed appearance categories over equipped two-handed weapons when Blizzard permits them.
- Applied the same slot/option permission check to browsing, generation, rerolls, and locked-weapon validation.
- Retained the older item-category query only as a compatibility fallback.

## 1.6.0 - 2026-07-31

### Added

- Blizzard-driven weapon appearance capability matrices for the main hand and off hand.
- Exact weapon-type filters for one-hand, two-hand, ranged, and off-hand families.
- Equipment Slot panel weapon rows with generation checkboxes, browse behavior, and subtype flyouts.
- All Compatible, Equipped Type, Clear, and Done flyout actions.
- Linked or independent dual-weapon generation.
- Spec, talent-group, trait, and equipment change permission refreshes.
- Concept persistence for subtype filters and linked-hands preference.

### Changed

- Physical topology and visual transmog permission are now separate systems.
- Weapon browsing, generation, unlocked rerolls, and slot rerolls use the same effective type filters.
- Weapon generation chooses an exact type before an appearance, preventing large categories from automatically dominating smaller selected categories.
- Secondary weapon Custom Set validation accepts Blizzard-permitted one-hand, two-hand, and ranged sources.
- Weapon controls moved from the character-preview panel into the Equipment Slot panel.

## 1.5.1 - 2026-07-31

### Fixed

- Prioritizes equipped-item `itemEquipLoc` over broad transmog category compatibility when detecting weapon topology.
- Correctly classifies two-handed swords, axes, maces, staves, and polearms as Two-Hand.
- Keeps category compatibility only as a fallback when item equipment-location data is unavailable.
- Adds equipment-location diagnostics to the internal topology record.

### Compatibility

- Preserves SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- No collection rescan or concept migration is required.

## 1.5.0 - 2026-07-31

### Added

- Added One-Hand, Two-Hand, Ranged, and Off-Hand generation checkboxes to the Outfits workbench.
- Added equipped weapon topology detection and live `PLAYER_EQUIPMENT_CHANGED` refreshes.
- Added coherent rules for two-hand, ranged, one-hand, shield/focus, dual-wield, and unarmed layouts.
- Added dynamic availability tooltips that remain readable even for unavailable families.
- Saved weapon-family choices with Quest Chronicle outfit concepts.
- Added weapon-family summaries to the concept manager.

### Changed

- Generate Outfit and Reroll Unlocked now use only checked, topology-compatible weapon families.
- Off-Hand generation requires One-Hand; dual wield uses the One-Hand pool for both hands.
- Locked weapon conflicts now stop generation with an explicit explanation.

### Compatibility

- Preserves SavedVariables schema 2, Courier format 1, and wardrobe cache format 6.
- Existing concepts migrate to all-family preferences without requiring a wardrobe rescan.

## 1.0.6 - 2026-07-31

### Changed

- Limits automatic wardrobe scanning to exactly one attempt per addon session, after login or `/reload`.
- Prevents `TRANSMOG_COLLECTION_*` events from scheduling background rescans during play.
- Marks the wardrobe cache stale when appearances are learned or removed.
- Adds a visible **Collection may be stale** notice beside **Scan Collection**.
- Keeps manual Scan Collection as the only additional refresh path during the session.
- Removes the obsolete automatic-refresh setting while preserving all wardrobe data and concepts.
- Updates Status and diagnostics to distinguish the one-time login refresh from later stale collection state.

## 1.0.5 - 2026-07-31

### Added

- Added a draggable standalone Quest Chronicle minimap button.
- Added saved minimap position and a WoW Settings visibility toggle.
- Added `/qc minimap show|hide|toggle|reset` recovery commands.
- Preserved the native AddOn Compartment entry as a second launcher.
- Left Ctrl+Right-click unconsumed for minimap-button organizer reattachment workflows.

## 1.0.4 - 2026-07-31

### Fixed

- Corrected AddOn Compartment hover callback arguments.
- Anchored the Quest Chronicle tray tooltip to Blizzard's supplied menu button instead of the addon-name string.
- Preserved left-click window toggling and right-click Status access.

## 1.0.3 - 2026-07-31

### Polished

- Split the Outfit Concepts footer into a native Custom Set row and a separate paging/load/delete row.
- Increased the concept manager height and widened dynamic Custom Set controls.
- Kept selected generation-mode buttons enabled so active-mode tooltips remain available.
- Added selected-mode highlighting without disabling mouse interaction.
- Preserved the v1.0.2 Custom Set handoff and verification pipeline.

## 1.0.2 - 2026-07-31

### Fixed

- Replaces the incorrect compact transmog-category Custom Set layout with actual WoW inventory slot IDs.
- Builds the complete `ItemTransmogInfo` array through `INVSLOT_LAST_EQUIPPED`.
- Correctly maps armor, Back, Tabard, Main Hand, and Off Hand destinations.
- Rebinds each selected visual to a source WoW confirms is actually collected.
- Encodes hidden Head, Back, Shirt, and Tabard choices with native hidden visuals.
- Aborts before `NewCustomSet` or `ModifyCustomSet` when any intended slot is unresolved.
- Repairs an unlinked same-name partial v1.0.1 set instead of creating a duplicate.
- Verifies every intended inventory slot after saving and accepts only an exact source or the same visual.
- Stores the resolved-source manifest and slot verification on the authoritative concept.

### Compatibility

- Advances wardrobe cache format from 5 to 6 so source representatives are rebuilt around genuinely collected sources.
- Preserves SavedVariables schema 2 and Courier format 1.
- Preserves Chronicle history, concepts, visual identities, locks, hidden slots, and linked Custom Set IDs.

## 1.0.1 - 2026-07-31

### Fixed

- Removed the protected `C_TransmogOutfitInfo` save pipeline that caused `ADDON_ACTION_FORBIDDEN`.
- Ordinary concept Save / Update no longer performs any native save.
- Migrates away obsolete `blizzardOutfitID` synchronization fields.

### Added

- Saves concepts to Blizzard Custom Sets through `C_TransmogCollection.NewCustomSet` and `ModifyCustomSet`.
- Dynamic Save to Custom Sets / Update Custom Set action.
- Save as New and Replace Existing workflows.
- Native Custom Set picker and replacement backups.
- `TRANSMOG_CUSTOM_SETS_CHANGED` verification with timeout fallback.

## 1.0.0 - 2026-07-31

### Added

- Saves Quest Chronicle concepts into real World of Warcraft transmog outfit slots through the current `C_TransmogOutfitInfo` system.
- Links each concept to its Blizzard outfit ID so later saves update the same native slot.
- Adds **Save to WoW** for migrating existing concepts without allocating slots automatically at login.
- Shows **Quest Chronicle only**, **Saving to WoW**, **WoW Outfit**, missing, and failed states directly in the concept manager.
- Converts stable collapsed visual IDs, hidden/equipped armor states, and the valid current weapon option into Blizzard's native outfit format.

### Completed

- Complete Chronicle recorder and active quest lifecycle.
- RP journal and Courier format 1 export snapshot.
- Zone-aware, era-aware, Chronicle-aware outfit designer.
- Saved concept lifecycle, stable appearance recovery, and native outfit persistence.
- Stable migrations, release documentation, and live verification coverage.

### Compatibility

- Preserves wardrobe cache format 5, SavedVariables schema 2, and Courier format 1.
- Existing concepts remain intact and migrate to native outfit slots only when the player chooses to save them.
- Native outfit saving does not apply a transmog or spend gold.

## 0.9.2 - 2026-07-31

### Fixed

- Stops **Generate Outfit**, **Reroll Unlocked**, and weapon-slot rerolls from scheduling a full wardrobe rescan after their own Blizzard usability refresh.
- Distinguishes the short-lived internal `TRANSMOG_COLLECTION_UPDATED` notification from genuine collection mutations.
- Continues to react normally to source-added, source-removed, cosmetic-added, and later external collection-update events.

### Compatibility

- Preserves wardrobe cache format 5, SavedVariables schema 2, and Courier format 1.
- Requires no collection rescan.

## 0.9.1 - 2026-07-31

### Fixed

- Fixes **Unfavor** silently reapplying the current zone favorite instead of clearing it.
- Fixes **Allow in Zone** silently reapplying the current zone exclusion instead of clearing it.
- Replaces the invalid Lua `condition and nil or value` pseudo-ternary with explicit clear/apply branches.
- Updates both preference-button tooltips with the action currently shown on the button.

### Compatibility

- Preserves every v0.9.0 era, collection, recovery, performance, coverage, settings, and accessibility improvement.
- Preserves wardrobe cache format 5, SavedVariables schema 2, and Courier format 1.
- Requires no collection rescan.

## 0.9.0 - 2026-07-31

### Added

- Adds a default-on setting that makes the zone expansion ceiling an explicit progression rule for generated outfits and rerolls.
- Debounces transmog collection events into one automatic refresh and waits until combat and Blizzard Wardrobe windows are clear.
- Stores collapsed visual identities beside preview selections and saved concepts, then recovers them when Blizzard changes the representative source after a scan.
- Records scan duration, automatic-refresh time, and appearance-recovery results in wardrobe diagnostics.
- Expands local provenance across Classic Eastern Kingdoms and Kalimdor questing zones, Cataclysm regions, missing Pandaria and Battle for Azeroth zones, Ashran, Siren Isle, K'aresh, and current Midnight content.
- Adds Cataclysm, Draenor, Broken Isles, Nazjatar, Fourth War, Eastern Kingdoms, and Kalimdor style profiles.
- Adds settings for automatic refresh, source recovery, chat maintenance notices, and high-contrast selected/favorite/excluded rows.

### Improved

- Keeps repeated collection events from causing repeated rescans.
- Preserves the healthy staging-cache scanner, empty-result protection, per-slot retry behavior, and source-query fallbacks.
- Surfaces wardrobe readiness on Status & Maintenance and automatic refresh/recovery details in the Outfits diagnostics tooltip.

### Compatibility

- Preserves wardrobe cache format 5, SavedVariables schema 2, and Courier format 1.
- Migrates existing selections and concepts additively; no cache reset or mandatory rescan is introduced by the release.

## 0.8.1 - 2026-07-31

### Improved

- Gives selected Current Look rows the same compatibility, generation-pool, active style score, Chronicle Echo reasons, and zone-preference details as appearance-browser rows.
- Preserves Current Look's Selected, Locked, and Hidden state line above the shared appearance intelligence.
- Gives equipped-only rows a truthful equipment tooltip instead of presenting unsupported appearance scoring.
- Routes both views through one shared tooltip builder so their behavior cannot drift independently.

### Preserved

- Chronicle Intelligence, generated outfit names, per-zone favorites and exclusions, and all v0.7 eligibility and coherence safeguards.
- Wardrobe cache format 5, SavedVariables schema 2, and Courier format 1; no rescan is required.

## 0.8.0 - 2026-07-31

### Added

- Adds Chronicle Echo as a fourth weighted outfit-generation mode.
- Builds a bounded intelligence profile from the twelve most recent distinct quests in schema-2 history and the active-quest snapshot.
- Merges repeated objective events by quest so event volume cannot distort recent-quest influence.
- Recognizes Alliance and Horde signals plus Burning Legion, undead, void, elemental, dragon, beast, troll, naga, pirate, and mechanical enemy themes.
- Applies a lighter recent-quest accent to Zone Native, Traveler, and Class Fantasy scoring.
- Displays a compact Chronicle Echo summary and Echo scoring reasons in appearance tooltips.
- Generates stable outfit names from mode, zone, Chronicle theme, and selected collapsed visuals.
- Shows generated names in Character Preview and Current Look and offers them as the default Save Concept name.
- Adds per-character, per-zone favorites and exclusions keyed to Blizzard's collapsed visual identity.
- Adds Favor in Zone / Exclude in Zone controls, browser markers, tooltips, and per-zone counts.

### Compatibility

- Saves generated names as optional concept fields; legacy concepts without them remain loadable.
- Stores zone preferences additively without changing wardrobe cache format 5.
- Preserves SavedVariables schema 2 and Courier format 1.
- Requires no wardrobe rescan and retains existing history, caches, concepts, selections, locks, hidden slots, and style modes.

### Preserved

- Era ceilings, local source provenance, starting-zone corrections, and the full manual appearance browser.
- Promotional exclusion, native-set affinity, motif coherence, and dramatic-outlier rejection.
- Blizzard-safe equipped-item and hand-slot weapon validation.
- Preview-only behavior with no transmog application, gold cost, or Blizzard outfit-slot mutation.

## 0.7.3 - 2026-07-31

### Fixed

- Corrects Cord of Grieving from WoW's misleading legacy item-era value to its Mists of Pandaria / Wandering Isle origin.
- Applies the same curated fallback to the published Wandering Isle questing armor sets and weapons when their item records present as Classic or TBC.
- Uses WoW's appearance-tracking map for quest-source provenance when the transmog source itself contains no quest or location.
- Tries both the item-modified source ID and collapsed visual ID for compatibility across client tracking behavior.
- Rejects tracked quest rewards from foreign source pools before weighted outfit scoring.

### Added

- Adds curated provenance profiles for every distinct retail racial, allied-race, hero-class, and Exile's Reach starting geography.
- Adds a 30-case regression matrix covering every current race, shared starts, both death-knight openings, Mardum, and Exile's Reach.
- Verifies every starting context's expansion ceiling, local-source acceptance, and cross-zone rejection.

### Preserved

- Promotional exclusion, outfit coherence, Blizzard-safe weapon handling, full manual wardrobe browsing, and deliberate previews.
- Wardrobe cache format 5, SavedVariables schema 2, and Courier format 1; no collection rescan is required.

## 0.7.2 - 2026-07-31

### Fixed

- Hard-excludes Blizzard's Trading Post source type from Generate Outfit, Reroll Unlocked, and individual slot rerolls.
- Excludes legacy subscription, shop, Recruit-a-Friend, preorder, and promotional families that WoW reports without a source type, including every Renowned Explorer and Wooly Wendigo piece.
- Checks native transmog-set names, labels, and descriptions for promotional origin metadata.
- Labels affected browser rows **Promo excluded** while keeping deliberate manual preview selection available.

### Improved

- Generates the major armor silhouette before smaller layers and weapons.
- Strongly favors appearances belonging to the same Blizzard native transmog set.
- Builds a shared motif across fire, frost, shadow, radiant, nature, arcane, storm, fel, necrotic, mechanical, rustic, and regal themes.
- Rejects isolated dramatic pieces when they would conflict with or overpower the established outfit.
- Makes Reroll Slot coordinate with the rest of the visible preview instead of choosing in isolation.
- Chooses weapons after armor so they reinforce the outfit while retaining every equipped-item compatibility rule.
- Restores the previous selections if an invalid locked weapon blocks generation, preventing a partial reroll.

### Preserved

- Full collected wardrobe browsing and manual previews, including promotional appearances.
- Era ceilings, local source provenance, three Zone Style modes, locks, hidden slots, concepts, and Current Look.
- Wardrobe cache format 5, SavedVariables schema 2, and Courier format 1; no collection rescan is required.

## 0.7.1 - 2026-07-31

### Fixed

- Adds an expansion-era ceiling to every generated and rerolled armor or weapon candidate.
- Limits Outland zones to Classic and The Burning Crusade items, Northrend through Wrath, and subsequent regions through their corresponding expansion.
- Distinguishes Midnight-parented versions of renewed regions from their original-era counterparts when the parent map is available.
- Uses Blizzard's boss-drop instance and encounter metadata to reject appearances sourced outside the current curated zone family.
- Rejects non-boss sources whose loaded item metadata explicitly names another curated zone family.
- Keeps unknown-origin sources only when they pass the era ceiling and contain no conflicting provenance marker.
- Applies era and provenance filtering before weighted scoring and before Blizzard-safe weapon validation.
- Marks manually browsable appearances that are excluded from automatic generation and explains the reason in their tooltip.

### Added

- Shows the previewed appearance or equipped-item icon on every active equipment-slot button.
- Desaturates thumbnails for hidden layers while retaining the visible padlock and gold border for locked layers.
- Adds a Current Look manifest with exact names and Selected, Equipped, Hidden, and Locked states.
- Lists only the active main-hand mode and applicable off-hand in the Current Look weapon summary.
- Displays the current era ceiling and local source pool beneath the generation modes.

### Preserved

- The full collected wardrobe browser and deliberate manual preview selection.
- Zone Native, Traveler, and Class Fantasy weighted scoring after eligibility filtering.
- Equipped-item, category, usability, class, display, valid-source, and hand-slot checks for weapons.
- Wardrobe cache format 5, SavedVariables schema 2, and Courier format 1.
- Existing concepts, selections, locks, hidden slots, quest history, notes, and Courier data.

## 0.7.0 - 2026-07-31

### Added

- Detects the player's current map, zone, subzone, and parent-map trail through Blizzard's map API and zone-change events.
- Adds curated profiles for Quel'Thalas, the Amani Highlands, Harandar, the Voidstorm, and major cultures and expansion regions across Azeroth.
- Adds Zone Native, Traveler, and Class Fantasy generation modes directly above the character preview.
- Scores cached appearances using loaded item/source names, mode-specific terms, profile affinities, class themes, and slot accents.
- Requests missing item data and uses a stable affinity fallback so generic cached appearance names still produce varied weighted results.
- Announces a non-destructive Zone Native suggestion when entering a new zone or profile and marks the Outfits tab until it is opened.
- Displays the active profile and detected location in the Outfit Workbench.
- Shows an appearance's current style score and matching reasons in its hover tooltip.
- Saves and restores the selected style mode with outfit concepts; legacy concepts remain loadable.

### Preserved

- Equipped-item, category, usability, class, display, and valid-source checks for generated and rerolled weapons.
- Locked-slot, hidden-slot, concept-manager, embedded-preview, and native bottom-tab behavior.
- Wardrobe cache format 5; no collection rescan is required from v0.6.2.
- SavedVariables schema 2 and Courier format 1.
- Preview-only behavior; no transmog is applied and no Blizzard outfit slot is changed.

## 0.6.2 - 2026-07-31

### Fixed

- Replaces the conditional save popup and load context menu with a dependable in-panel Outfit Concepts manager.
- Completes concept save, same-name overwrite, selection, loading, paging, and confirmed deletion.
- Prevents new concept identifiers from colliding after concepts are deleted and recreated within the same timestamp.
- Returns saved and loaded concept records consistently to the UI.

### Polished

- Shows a gold padlock and persistent gold border on every locked equipment-slot button.
- Keeps lock state visible on inactive slots and the disabled active-slot button.
- Removes the ambiguous trailing `L` marker.
- Displays saved appearance, lock, hidden-slot, and update details in the concept list.

### Preserved

- Existing v0.6.0 and v0.6.1 outfit concepts and per-character storage.
- Wardrobe cache format 5, SavedVariables schema 2, and Courier format 1.
- Equipped-weapon-safe generation and native bottom tabs.

## 0.6.1 - 2026-07-31

### Fixed

- Derives generated weapon categories from the currently equipped main- and off-hand items instead of randomly choosing any populated weapon cache.
- Uses Blizzard's `IsCategoryValidForItem` result for every generated or rerolled weapon candidate.
- Requeries the collapsed appearance and requires it to be collected, displayable, and usable for the current character.
- Revalidates locked weapon choices against changed equipment before modifying unlocked armor slots.
- Leaves empty hands and equipped items with no compatible cached visual unchanged.
- Supports dual-wield off-hand weapons by revalidating cached One-Hand visuals against the equipped secondary-hand item and location.

### Polished

- Moves Chronicle, Active Quests, Write Note, Status, and Outfits to native `PanelTabButtonTemplate` tabs along the bottom edge of the window.
- Reclaims the old top-tab row for page content.

### Preserved

- Wardrobe cache format 5; no rescan is required from v0.6.0.
- Existing saved outfit concepts, manual selections, locks, and hidden-slot choices.
- SavedVariables schema 2 and Courier format 1.

## 0.6.0 - 2026-07-31

### Added

- Generates complete random armor and weapon outfit previews from the format 5 wardrobe cache.
- Rerolls the active slot or every unlocked slot.
- Locks individual slots so generation and bulk rerolls preserve them.
- Hides and restores helm, cloak, shirt, and tabard without discarding their selected appearances.
- Enforces mutually compatible One-Hand, Two-Hand, Ranged, and Off-Hand combinations.
- Automatically supplies a One-Hand selection when an Off-Hand appearance is chosen by itself.
- Saves and loads named concepts per character, including selections, locks, hidden slots, and weapon configuration.
- Adds workbench controls while retaining the seven-row paged appearance browser.
- Replaces the five wide navigation push-buttons with native `PanelTopTabButtonTemplate` tabs connected to the content panel.

### Preserved

- Wardrobe cache format 5 and the successful v0.5.5 collection scan.
- SavedVariables schema 2 and Courier format 1.
- Preview-only behavior; no transmog is applied and no Blizzard outfit slot is changed.

## 0.5.6 - 2026-07-31

### Fixed

- Passes the cached item-modified appearance/source ID to `DressUpModel:TryOn` instead of the ordinary item ID.
- Supplies `MAINHANDSLOT` or `SECONDARYHANDSLOT` when previewing weapon appearances.
- Checks WoW's `ItemTryOnReason` result instead of treating every protected call as a successful preview.
- Preserves wardrobe cache format 5, SavedVariables schema 2, and Courier format 1.

## 0.5.5 - 2026-07-31

### Fixed

- Uses the collapsed category appearance's collection and display flags to decide whether a visual belongs in the catalog.
- Stops rejecting an unlocked visual merely because an individual item source is unknown, restricted, or reports a transmog-use error.
- Retains source-specific flags to rank the best representative preview item.
- Advances the rebuildable wardrobe cache to format 5.
- Preserves SavedVariables schema 2 and Courier format 1.

## 0.5.4 - 2026-07-31

### Fixed

- Uses each `GetCategoryAppearances` row's `visualID` as the catalog identity, matching Blizzard's already-collapsed Wardrobe list.
- Stops source-level `appearanceID` and `itemAppearanceID` values from merging unrelated visual rows.
- Resolves the best collected, character-compatible source independently inside each visual row.
- Accepts either source-info records or source-ID arrays from compatible client API paths.
- Uses `C_TransmogCollection.GetSourceItemID` before the legacy transmog fallback.
- Advances the rebuildable wardrobe cache to format 4 and marks format 3 stale while preserving Chronicle data and manual selection state.
- Preserves SavedVariables schema 2 and Courier format 1.

## 0.5.3 - 2026-07-31

### Polished

- Reworked the Outfits source browser for real collection sizes.
- Replaced the variable-height diagnostic block with a compact two-line header.
- Reduced pages to seven stable rows to prevent row/footer overlap at minimum window size.
- Moved Clear Slot out of the pagination footer.
- Separated Previous, centered page text, and Next into a collision-free footer.
- Added mouse-wheel paging and row hover feedback.
- Added detailed scan diagnostics through a hover tooltip.
- Removed the false warning that treated collected source counts and unique compatible visual counts as directly comparable.
- Preserved wardrobe cache format 3 and the v0.5.2 scanner.

## 0.5.2 - 2026-07-31

### Fixed

- Repaired the v0.5.1 empty wardrobe-cache regression.
- Waits for WoW's asynchronous transmog search database before scanning.
- Queries `GetCategoryAppearances` and source APIs with both the documented `TransmogLocationMixin` and Blizzard's current `GetData()` representation, then uses the richest valid result.
- Uses unfiltered category collection counts for diagnostics instead of transient filtered counts.
- Removes per-category search mutation from the scan loop.
- Scans a broad collected-and-uncollected view and filters collected appearances locally without resetting unrelated native Wardrobe defaults.
- Retries a slot when WoW reports collected appearances but temporarily returns no rows.
- Builds into a staging cache so a failed or impossible empty scan cannot erase a healthy cache.
- Adds explicit Preparing and Failed scanner states with actionable errors.
- Invalidates v0.5.1 wardrobe data through cache schema 3.

## 0.5.1 - 2026-07-31

### Fixed

- Replaced the incomplete wardrobe query with slot-aware account collection scanning.
- Corrected armor category fallback IDs and delayed enum resolution until scan time.
- Isolated and restored Blizzard collection filters and search state.
- Added robust collected-source fallbacks and per-slot scan diagnostics.
- Invalidated the v0.5.0 wardrobe cache through cache schema 2.

## 0.5.0 - 2026-07-31

### Added

- Fifth Outfits tab.
- Collected-appearance scanner and account-wide cache by equipment slot.
- Batched scanning with live progress callbacks.
- Embedded character preview model.
- Manual source selection, pagination, rotation, clearing, and persistent preview state.
- Source compatibility validation.
- Transmog collection change detection and rescan prompting.

### Compatibility

- Preserves SavedVariables schema 2 and Courier format 1.
- No changes to the tested quest lifecycle recorder.

## 0.4.1 - 2026-07-30

### Polished

- Replaced raw internal states such as `READY_FOR_TURN_IN` with friendly labels throughout the UI and slash-command state summaries.
- Replaced unsupported objective checkmark and bullet glyphs with reliable **Complete** and **In Progress** labels.
- Added thousands separators to large event and quest counts.
- Added optional Chronicle date headings.
- Improved event labels, quest-state transitions, removal explanations, reward formatting, and quest-ID presentation.
- Added persistent Chronicle search text and a dedicated Clear Search button.
- Improved Chronicle page labels with the displayed event range.
- Added control tooltips across Chronicle, Active Quests, Write Note, Status, tabs, and resize grip.

### Added

- Active Quest filters for All, Ready for Turn-In, Active, and Failed.
- Active Quest sorting by Ready First, Quest Name, and Recently Accepted.
- Active Quest summary counts and friendly accepted-time formatting.
- Empty-note placeholder text and near-limit character-count warnings.
- Optional confirmation before clearing unfinished RP-note drafts.
- Automatic disabling of note-record buttons while empty or while recording is disabled.
- Resizable main window with remembered dimensions.
- Reset Window command on Status & Maintenance.
- Settings for quest-ID visibility, Chronicle date grouping, and note-draft clear confirmation.
- Objective-update and quest-state-change counts on Status & Maintenance.

### Preserved

- The complete v0.4.0 lifecycle recorder and event classification behavior.
- Existing SavedVariables, active quest snapshots, note drafts, and historical records.
- Data schema version 2.
- Courier export format version 1 and Warcraft Quest Chronicle Courier v1.0.0 compatibility.
- Every existing slash command.

## 0.4.0 - 2026-07-30

### Added

- Standalone Blizzard-styled Quest Chronicle window.
- AddOn Compartment integration with left-click Chronicle and right-click Status behavior.
- Native AddOns settings category using Blizzard's modern Settings API.
- Chronicle browser with pagination, search, filtering, and chronological ordering.
- Active Quests browser with objectives, state, timestamps, and manual rescan.
- Multiline RP-note editor with per-character draft preservation and Ctrl+Enter submission.
- Status & Maintenance page with event counts, snapshot information, synchronization controls, and recording toggles.
- Remembered window position and optional position locking.
- Public read/action API between the tested recorder and separate UI modules.
- UI callback bus for event, active-quest, settings, and Courier refresh updates.

## 0.3.0

- Added quest acceptance, active-state discovery, objective progression, state changes, confirmed abandonment, uncertain removals, and active quest snapshots.
