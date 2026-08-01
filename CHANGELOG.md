# Changelog

## 0.3.0 - 2026-07-28

### Added

- Quest acceptance recording.
- Persistent and exported active-quest snapshots.
- Objective-progress diffing and intermediate-stage events.
- Quest state transition events.
- Confirmed player-abandonment detection through the built-in quest abandonment flow.
- Honest fallback events for automatic or uncertain quest removals.
- `/qc active`, `/qc sync`, and lifecycle tracking controls.
- Nested objective data in the Courier JSON export.

### Changed

- Addon database schema advanced from 1 to 2.
- Existing Courier format version remains 1 for backward compatibility.
- Status and recent-event output now understand lifecycle events.

### Preserved

- Existing quest completion events.
- Existing RP notes.
- Existing sessions and character history.
- Existing SavedVariables names and upgrade path.
