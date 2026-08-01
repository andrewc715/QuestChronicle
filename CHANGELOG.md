# Changelog

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
