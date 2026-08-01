# Changelog

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
