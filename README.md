# Quest Chronicle v0.4.1

Quest Chronicle records a character's quest journey for later Chronicle and roleplay work. Version 0.4.1 polishes the standalone Blizzard-styled interface introduced in v0.4.0 while preserving the tested lifecycle recorder and Courier export.

It does **not** modify, skin, hook into, or add tabs to Blizzard's Quest Log.

## Opening the interface

```text
/qc
/qc show
```

The AddOn Compartment beside the minimap also opens it:

- Left-click: toggle the main window.
- Right-click: open Status & Maintenance.

The window remembers both its position and size. Drag the lower-right resize grip to enlarge it, lock it through WoW's AddOns settings, or use **Reset Window** on the Status tab.

## Chronicle tab

The Chronicle tab browses the complete event history for the current character.

Features:

- 25-event pages suitable for histories containing thousands of records.
- Newest-first or oldest-first display.
- Search across event type, quest name and ID, objective text, RP notes, locations, removal reasons, and friendly quest-state names.
- Filters for all events, quest lifecycle, objectives and state, RP notes, and removals.
- Optional date separators.
- Human-readable event labels and quest-state transitions.
- Quest IDs that can be shown or hidden through Settings.
- Persisted search text, filter, sort direction, and page-safe refresh behavior.

## Active Quests tab

The Active Quests tab shows the addon's current quest-log snapshot:

- friendly states such as **Active**, **Ready for Turn-In**, and **Failed**;
- ready-for-turn-in, active, and failed filters;
- sorting by Ready First, Quest Name, or Recently Accepted;
- quest level, accepted or first-seen time, and elapsed active time;
- explicit **Complete** and **In Progress** objective labels;
- summary counts and manual quest-log rescan.

The old unsupported checkmark and bullet glyphs were removed so objective rows render reliably in the default WoW font.

## Write Note tab

The multiline RP-note editor supports:

- notes up to 4,000 characters;
- automatic character, level, time, zone, map, and coordinate context;
- per-character draft preservation;
- a visible empty-editor prompt;
- live character-count warnings near the limit;
- disabled record buttons while the note is empty or recording is disabled;
- optional confirmation before clearing an unfinished draft;
- `Ctrl+Enter` to record without closing;
- Record, Record & Close, and Clear Draft controls.

The underlying event remains `RP_NOTE`, so Courier behavior is unchanged.

## Status & Maintenance tab

The status page contains:

- addon, schema, and Courier-format versions;
- recorder and Courier snapshot readiness;
- event, active quest, note, acceptance, completion, objective, state-change, abandonment, and removal counts;
- last event and quest-sync timestamps;
- manual quest-log rescan and Courier export refresh;
- recording toggles;
- a Reset Window command.

WoW still decides when SavedVariables are written to disk. Use `/reload`, log out, or exit WoW after refreshing the Courier export when the external Courier needs the new snapshot immediately.

## WoW AddOns settings

```text
Escape → Options → AddOns → Quest Chronicle
```

Settings include:

- Enable all recording
- Show chat notifications
- Record quest lifecycle
- Record objective progress
- Record abandonments and removals
- Show quest IDs in the UI
- Group Chronicle events by date
- Confirm before clearing note drafts
- Remember window position and size
- Lock window position and size

## Slash commands

```text
/qc help
/qc status
/qc recent [1-30]
/qc active [1-50]
/qc sync
/qc note <text>
/qc export
/qc on|off
/qc chat on|off
/qc lifecycle on|off
/qc objectives on|off
/qc removals on|off
```

Bare `/qc` toggles the main window. `/qc help` displays command help.

## Recorded event types

- `QUEST_ACCEPTED`
- `QUEST_BECAME_ACTIVE`
- `QUEST_OBJECTIVE_UPDATED`
- `QUEST_STATE_CHANGED`
- `QUEST_ABANDONED`
- `QUEST_REMOVED`
- `QUEST_TURNED_IN`
- `RP_NOTE`

## Compatibility

- Existing v0.1 through v0.4.0 SavedVariables and historical records are retained.
- Addon schema remains version 2 because the recorded data model is unchanged.
- Courier export `formatVersion` remains 1.
- Warcraft Quest Chronicle Courier v1.0.0 remains compatible.

## File layout

```text
QuestChronicle\
├── QuestChronicle.toc
├── QuestChronicle.lua
├── UI\
│   ├── Shared.lua
│   ├── ChronicleTab.lua
│   ├── ActiveQuestsTab.lua
│   ├── NoteTab.lua
│   ├── StatusTab.lua
│   ├── Settings.lua
│   └── MainWindow.lua
├── CHANGELOG.md
├── LIVE_TEST_CHECKLIST.md
├── UI_FOUNDATION_TEST_CHECKLIST.md
├── POLISH_TEST_CHECKLIST.md
└── COURIER_CONFIG_PATCH.json
```

The lifecycle recorder remains in `QuestChronicle.lua`. UI modules use the public addon API and callback bus rather than reaching into the recorder's local tracking state.
