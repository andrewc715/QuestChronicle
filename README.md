# Quest Chronicle v0.4.0

Quest Chronicle records a character's quest journey for later Chronicle and roleplay work. Version 0.4.0 adds a standalone Blizzard-styled interface while preserving the lifecycle recorder and Courier export introduced in v0.3.0.

It does **not** modify, skin, hook into, or add tabs to Blizzard's Quest Log.

## UI foundation

Open the window with:

```text
/qc
/qc show
```

You can also open it through WoW's AddOn Compartment beside the minimap:

- Left-click: toggle the main window.
- Right-click: open Status & Maintenance.

The window remembers its position unless that option is disabled. It can also be locked in WoW's AddOns settings.

## Chronicle tab

The Chronicle tab browses the complete event history for the current character.

Features in v0.4.0:

- 25-event pages, so thousands of records do not create thousands of UI frames.
- Newest-first or oldest-first display.
- Text search across event type, quest name and ID, objective text, RP notes, location, and change reason.
- Filters for all events, quest lifecycle, objectives and state, RP notes, and removals.
- Event sequence, timestamp, location, level, quest rewards, and lifecycle details.

## Active Quests tab

The Active Quests tab shows the addon's current quest-log snapshot:

- quest name, ID, and state;
- quest level;
- accepted or first-seen time;
- elapsed active time;
- all current objectives and completion marks;
- ready-for-turn-in state.

`Rescan Quest Log` performs the same underlying operation as `/qc sync` and refreshes the Courier snapshot.

## Write Note tab

The note editor replaces the need to compose longer RP observations inside a slash command.

- Multiline notes up to 4,000 characters.
- Automatic character, level, time, zone, map, and coordinate context.
- Per-character draft preservation.
- Record, Record & Close, and Clear controls.
- `Ctrl+Enter` records the current note.

The underlying event remains `RP_NOTE`, so Courier behavior is unchanged.

## Status & Maintenance tab

The status page contains:

- current character and recorder health;
- event, active quest, acceptance, completion, abandonment, removal, and RP-note counts;
- last event and quest-sync timestamps;
- Courier snapshot size;
- manual quest-log rescan;
- manual Courier export refresh;
- all existing recording toggles.

WoW still decides when SavedVariables are written to disk. Use `/reload`, log out, or exit WoW after refreshing the Courier export when you need the external Courier to see it immediately.

## WoW AddOns settings

Quest Chronicle registers a native category under:

```text
Escape → Options → AddOns → Quest Chronicle
```

Settings include:

- Enable all recording
- Show chat notifications
- Record quest lifecycle
- Record objective progress
- Record abandonments and removals
- Remember window position
- Lock window position

## Existing slash commands

All v0.3.0 commands remain available:

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

The only intentional behavior change is that bare `/qc` now opens the main window. Use `/qc help` for the command list.

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

- Existing v0.1, v0.2, and v0.3 SavedVariables are retained.
- Addon schema version remains 2 because the recorded data model is unchanged.
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
└── COURIER_CONFIG_PATCH.json
```

The recorder remains in `QuestChronicle.lua`. UI modules use a small public API instead of reaching into the recorder's local state.
