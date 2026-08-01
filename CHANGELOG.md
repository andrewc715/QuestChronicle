# Changelog

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
