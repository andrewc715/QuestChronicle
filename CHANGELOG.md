# Changelog

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
