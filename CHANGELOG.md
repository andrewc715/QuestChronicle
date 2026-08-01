# Changelog

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

### Changed

- Bare `/qc` now toggles the Quest Chronicle window.
- `/qc help` explicitly displays slash-command help.
- Login message now points players to `/qc`.
- Addon version advanced to 0.4.0 while data schema remains version 2 and Courier format remains version 1.

### Preserved

- Every v0.3.0 lifecycle event and classification rule.
- Existing SavedVariables and historical records.
- Existing Courier JSON structure and compatibility.
- All previous slash commands.

## 0.3.0

- Added quest acceptance, active-state discovery, objective progression, state changes, confirmed abandonment, uncertain removals, and active quest snapshots.
