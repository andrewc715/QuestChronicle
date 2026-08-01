# Quest Chronicle v0.7.2

> **Cohesive, Promo-Free Generation:** v0.7.2 excludes promotional appearances and coordinates generated pieces through Blizzard set membership and shared visual motifs.

Quest Chronicle records a character's quest journey for later Chronicle and roleplay work. Version 0.7.2 tightens outfit generation without changing the validated wardrobe cache, SavedVariables schema, or Courier format.

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
- Existing v0.6.x wardrobe caches, outfit selections, locks, hidden slots, and saved concepts are retained.
- Addon schema remains version 2 because the recorded data model is unchanged.
- Courier export `formatVersion` remains 1.
- Warcraft Quest Chronicle Courier v1.0.0 remains compatible.

## File layout

```text
QuestChronicle\
├── QuestChronicle.toc
├── QuestChronicle.lua
├── Wardrobe.lua
├── ZoneStyle.lua
├── UI\
│   ├── Shared.lua
│   ├── ChronicleTab.lua
│   ├── ActiveQuestsTab.lua
│   ├── NoteTab.lua
│   ├── StatusTab.lua
│   ├── OutfitsTab.lua
│   ├── Settings.lua
│   └── MainWindow.lua
├── CHANGELOG.md
├── LIVE_TEST_CHECKLIST.md
├── UI_FOUNDATION_TEST_CHECKLIST.md
├── POLISH_TEST_CHECKLIST.md
├── ZONE_STYLE_ENGINE_V070_TEST_CHECKLIST.md
├── ZONE_POOL_CURRENT_LOOK_V071_TEST_CHECKLIST.md
├── PROMO_COHERENCE_V072_TEST_CHECKLIST.md
├── WARDROBE_SCANNER_RECOVERY_TEST_CHECKLIST.md
└── COURIER_CONFIG_PATCH.json
```

The lifecycle recorder remains in `QuestChronicle.lua`. UI modules use the public addon API and callback bus rather than reaching into the recorder's local tracking state.

## Zone Style Engine

The Outfit Workbench offers three weighted generation modes:

- **Zone Native** favors the culture, climate, magic, materials, and motifs in the current curated zone profile.
- **Traveler** favors practical, weathered, expedition-ready appearances with a lighter local accent.
- **Class Fantasy** favors iconic class terms and silhouettes with a smaller accent from the current zone.

Quest Chronicle detects the current map, zone, subzone, and parent-map trail. Profiles cover the Midnight regions—Quel'Thalas, the Amani Highlands, Harandar, and the Voidstorm—plus major cultures and expansion regions across Azeroth. Unknown areas fall back to an Azeroth Adventurer profile.

When the character enters a different zone or profile, Quest Chronicle announces a new Zone Native suggestion and marks the Outfits tab. Opening Outfits acknowledges the notice; generating a Zone Native outfit consumes it. Suggestions never replace the preview automatically.

Scoring uses cached source and item names when available. If WoW has not loaded an item's name yet, Quest Chronicle requests it and uses a stable profile affinity in the meantime. The result remains varied while favoring pieces from the same native transmog set or a compatible material and magic motif.

The engine only ranks candidates. Existing equipped-item weapon checks still decide whether a weapon appearance can be used.

### Chronological and local source pools

Generated outfits and rerolls now pass two eligibility gates before weighted scoring:

- The **era ceiling** admits the current expansion and everything before it. Blade's Edge, for example, admits Classic and The Burning Crusade but rejects Wrath and later items.
- The **zone provenance gate** admits boss drops whose Blizzard-provided instance or encounter belongs to the current curated zone family. Gruul's Lair is local to Blade's Edge; Sunwell Plateau is not.

Explicit item/source names associated with another curated zone are also rejected. When Blizzard exposes no usable location for a non-boss source, Quest Chronicle admits it only after the era gate and only when its metadata contains no conflicting zone marker.

The full collected appearance browser remains available for deliberate manual previews. Rows outside the generated pool say **Not generated**, and their tooltip explains the era or zone exclusion.

### Promotional exclusion and outfit coherence

Generated outfits and rerolls always reject Blizzard's Trading Post source type. Legacy promotion families that WoW reports without an acquisition type—such as Renowned Explorer, Wooly Wendigo, Sprite Darter, Celestial Observer, the original store helms, Eternal Traveler, and Fireplume—are recognized through stable item and native-set metadata. Future native sets whose description identifies a shop, subscription, promotion, or Recruit-a-Friend origin are also excluded.

Manual browsing remains unrestricted. Promotional rows say **Promo excluded**, and their tooltip explains that the restriction applies only to generation.

For visual coherence, the generator establishes the outfit from major armor silhouettes first. It strongly favors pieces belonging to the same Blizzard transmog set, rewards shared motifs such as fire, frost, shadow, radiant, nature, arcane, storm, fel, necrotic, mechanical, rustic, or regal, and rejects isolated dramatic accents that conflict with the established outfit. Weapons are chosen afterward so they reinforce the armor while still passing every equipped-item transmog rule. Individual rerolls build their profile from the rest of the visible preview.

### Current Look

Every equipment-slot button now shows the icon currently represented by the embedded model, whether it comes from a selected appearance or equipped gear. Hidden icons are desaturated, while locked slots retain the gold padlock and border.

The **Current Look** button opens a compact two-column manifest listing every preview layer, its exact appearance or equipped-item name, and its Selected, Equipped, Hidden, and Locked state. Only the active weapon configuration is listed.


## Outfits: Wardrobe Foundation

The Outfits tab can scan the account wardrobe for appearances collected and displayable by the current character. It caches compatible sources by equipment slot and lets the player manually assemble a non-destructive preview on an embedded character model.

The preview does not apply transmogrification, spend gold, or alter Blizzard outfit slots. Use **Scan Collection** after installation and **Rescan Collection** whenever the tab reports that the collection changed.
