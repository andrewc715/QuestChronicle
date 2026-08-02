# Quest Chronicle v1.9.0a8

> **Persistent generation cache:** era evidence and eligibility records now survive `/reload` and the automatic wardrobe scan through a dedicated versioned SavedVariables store, while the cooperative weapon pipeline and targeted completion refresh remain intact.

Quest Chronicle records a character's quest journey, builds zone-aware outfit concepts, and exports verified Custom Sets. Version 1.9.0a8 makes the generation cache persistent across reloads and collection-cache rebuilds, using stable visual and context identities while preserving the responsive v1.9.0a7 pipeline.

It does **not** modify, skin, hook into, or add tabs to Blizzard's Quest Log.

## Opening the interface

```text
/qc
/qc show
```

Quest Chronicle provides both a standalone minimap button and a native AddOn Compartment entry:

- Left-click: toggle the main window.
- Right-click: open Status & Maintenance.
- Drag the standalone button around the minimap edge.
- Use `/qc minimap show|hide|toggle|reset` if it is hidden or misplaced.

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
- Restrict generated outfits to the zone's expansion
- Recover changed appearance sources
- Announce wardrobe maintenance in chat
- High-contrast outfit states
- Show minimap button

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
/qc minimap show|hide|toggle|reset
/qc weapon debug
/qc traveler debug
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
- Existing v0.6.x through v0.9.x wardrobe caches, outfit selections, locks, hidden slots, style modes, generated names, zone preferences, and saved concepts are retained.
- Existing concepts remain **Quest Chronicle only** until you deliberately choose **Save to Custom Sets**. No native Outfit slots are touched.
- A linked concept remembers its Blizzard Custom Set ID so later saves update the same native recipe instead of creating duplicates.
- Addon schema remains version 2 because the recorded data model is unchanged.
- Courier export `formatVersion` remains 1.
- Warcraft Quest Chronicle Courier v1.0.0 remains compatible.
- Wardrobe cache format 7 forces one full collection rebuild and records all visual sibling sources plus the evidence that established each appearance era; saved concepts and visual identities are preserved.

## File layout

```text
QuestChronicle\
├── QuestChronicle.toc
├── VERSION.txt
├── README.md
├── Core\
│   ├── Chronicle\
│   │   ├── Foundation.lua
│   │   ├── QuestLifecycle.lua
│   │   ├── Commands.lua
│   │   └── PublicAPI.lua
│   ├── Wardrobe\
│   │   ├── Foundation.lua
│   │   ├── StateAndPreferences.lua
│   │   ├── EquipmentTopology.lua
│   │   ├── AppearanceRoutes.lua
│   │   ├── WeaponFilters.lua
│   │   ├── WeaponCandidateIndex.lua
│   │   ├── WeaponSelection.lua
│   │   ├── GenerationAndConcepts.lua
│   │   ├── WeaponPipeline.lua
│   │   ├── GenerationPerformance.lua
│   │   ├── GenerationWorker.lua
│   │   ├── CustomSetBuild.lua
│   │   ├── CustomSetSyncAndManifest.lua
│   │   ├── AppearanceMetadata.lua
│   │   ├── CollectionScanWorker.lua
│   │   ├── CollectionScanAndPreview.lua
│   │   └── Events.lua
│   └── ZoneStyle\
│       ├── Profiles.lua
│       ├── Context.lua
│       ├── SourceMetadata.lua
│       ├── EraEvidence.lua
│       ├── ProgressionRestrictions.lua
│       ├── Scoring.lua
│       ├── GenerationEligibility.lua
│       └── Traveler│           ├── StyleLexicon.lua
│           ├── Descriptors.lua
│           ├── Cohesion.lua
│           └── Debug.lua
├── UI\
│   ├── Shared.lua
│   ├── ChronicleTab.lua
│   ├── ActiveQuestsTab.lua
│   ├── NoteTab.lua
│   ├── StatusTab.lua
│   ├── Outfits\
│   │   ├── OutfitsHelpers.lua
│   │   ├── Layout.lua
│   │   ├── ConceptManager.lua
│   │   ├── AppearanceBrowser.lua
│   │   ├── GenerationRefresh.lua
│   │   ├── RefreshAndEvents.lua
│   │   └── OutfitsTab.lua
│   ├── Settings.lua
│   ├── MainWindow.lua
│   └── MinimapButton.lua
├── docs\
│   ├── ARCHITECTURE.md
│   ├── CHANGELOG.md
│   ├── RELEASE_NOTES.md
│   └── testing\
├── tools\
│   └── verify_lua_line_limit.py
└── config\
    └── COURIER_CONFIG_PATCH.json
```

The TOC is the dependency manifest. Public subsystem APIs remain on `QuestChronicle`, `QuestChronicle.Wardrobe`, `QuestChronicle.ZoneStyle`, and `QuestChronicle.UI`; module-private helpers are documented in `docs/ARCHITECTURE.md`.

The project enforces a maximum of 500 physical lines per runtime Lua file:

```text
python tools/verify_lua_line_limit.py
```

## Zone Style Engine

The Outfit Workbench offers four weighted generation modes:

- **Zone Native** favors the culture, climate, magic, materials, and motifs in the current curated zone profile.
- **Traveler** favors practical, weathered, expedition-ready appearances with a lighter local accent.
- **Class Fantasy** favors iconic class terms and silhouettes with a smaller accent from the current zone.
- **Chronicle Echo** favors themes found in the character's recent quests, recognizable factions, and recurring enemies.

Quest Chronicle detects the current map, zone, subzone, and parent-map trail. Profiles cover the Midnight regions—Quel'Thalas, Zul'Aman, Harandar, and the Voidstorm—plus Classic questing zones across both continents, Cataclysm's launch and patch regions, the missing Pandaria and Battle for Azeroth areas, Siren Isle, K'aresh, and the major culture and expansion profiles across Azeroth. Unknown areas fall back to an Azeroth Adventurer profile.

When the character enters a different zone or profile, Quest Chronicle announces a new Zone Native suggestion and marks the Outfits tab. Opening Outfits acknowledges the notice; generating a Zone Native outfit consumes it. Suggestions never replace the preview automatically.

Scoring uses cached source and item names when available. If WoW has not loaded an item's name yet, Quest Chronicle requests it and uses a stable profile affinity in the meantime. The result remains varied while favoring pieces from the same native transmog set or a compatible material and magic motif.

The engine only ranks candidates. Existing equipped-item weapon checks still decide whether a weapon appearance can be used.

### Chronicle Intelligence

Chronicle Intelligence reads up to twelve distinct recent quests from the existing event history and active-quest snapshot. Repeated objective updates are folded into their quest, so one busy objective cannot drown out the rest of the character's journey. Quest titles, objectives, and recorded quest locations can establish Alliance or Horde influence and enemy themes including fel and the Burning Legion, undead and the Scourge, void forces, elementals, dragons, beasts, trolls, naga, pirates, and mechanical forces. RP notes are intentionally excluded from style scoring.

Chronicle Echo gives those signals the strongest weight. Zone Native, Traveler, and Class Fantasy use them as a smaller accent. The Workbench's Echo summary names the leading enemy and faction signals, and appearance tooltips show which Echo terms contributed to a score. Era limits, local source pools, promotional exclusion, outfit coherence, and Blizzard weapon validity are always applied before or alongside that weighting.

Generated looks receive stable names derived from their mode, zone, Chronicle theme, and selected visual identities. The name appears above the preview and in Current Look, becomes the suggested Save Concept name, and is restored by newly saved concepts. Existing concepts remain compatible because the name is optional. A deliberate manual selection clears the generated label.

The appearance panel also supports per-character, per-zone preferences:

- **Favor in Zone** strongly weights the collapsed visual whenever it remains eligible.
- **Exclude in Zone** removes that visual from automatic generation in the current zone while leaving manual browsing and preview available.

Favorites and exclusions are mutually exclusive and follow Blizzard's collapsed visual identity rather than one interchangeable item source. Their counts appear under the mode buttons, and they remain isolated to the zone where they were set.

### Chronological and local source pools

Generated outfits and rerolls now pass two eligibility gates before weighted scoring:

- The **era ceiling** admits the current expansion and everything before it. Blade's Edge, for example, admits Classic and The Burning Crusade but rejects Wrath and later items. This strict progression rule is enabled by default and can be changed in WoW's AddOns settings.
- The **zone provenance gate** admits boss drops whose Blizzard-provided instance or encounter belongs to the current curated zone family. Gruul's Lair is local to Blade's Edge; Sunwell Plateau is not.

Quest rewards now receive a second provenance lookup through WoW's appearance-tracking map. Quest Chronicle resolves that map and its parent trail through the same local-source profiles, accepting rewards tracked to the current pool and rejecting rewards tracked elsewhere. The engine covers every retail racial start, allied-race arrival area, both death-knight openings, Mardum, and Exile's Reach.

Some older starter rewards carry misleading generic item-era values. The published Wandering Isle questing sets and weapons therefore have an exact curated fallback: Cord of Grieving and its family are treated as Mists of Pandaria items from the Wandering Isle even when WoW presents an older era. Explicit item/source names associated with another curated zone are also rejected. When Blizzard exposes no usable location for a non-boss source, Quest Chronicle admits it only after the era gate and only when its metadata contains no conflicting zone marker.

The full collected appearance browser remains available for deliberate manual previews. Rows outside the generated pool say **Not generated**, and their tooltip explains the era or zone exclusion.

### Promotional exclusion and outfit coherence

Generated outfits and rerolls always reject Blizzard's Trading Post source type. Legacy promotion families that WoW reports without an acquisition type—such as Renowned Explorer, Wooly Wendigo, Sprite Darter, Celestial Observer, the original store helms, Eternal Traveler, and Fireplume—are recognized through stable item and native-set metadata. Future native sets whose description identifies a shop, subscription, promotion, or Recruit-a-Friend origin are also excluded.

Manual browsing remains unrestricted. Promotional rows say **Promo excluded**, and their tooltip explains that the restriction applies only to generation.

For visual coherence, the generator establishes the outfit from major armor silhouettes first. It strongly favors pieces belonging to the same Blizzard transmog set, rewards shared motifs such as fire, frost, shadow, radiant, nature, arcane, storm, fel, necrotic, mechanical, rustic, or regal, and rejects isolated dramatic accents that conflict with the established outfit. Weapons are chosen afterward so they reinforce the armor while still passing every equipped-item transmog rule. Individual rerolls build their profile from the rest of the visible preview.

### Weapon Appearance Rules

The Equipment Slot panel now owns every weapon-generation control. Armor remains a normal slot list, followed by a dedicated **Weapon Appearances** section containing independent family checkboxes and type-configuration arrows:

- **One-Hand**: wand, one-handed axe, sword, mace, dagger, fist weapon, warglaive, and paired artifact.
- **Two-Hand**: two-handed axe, sword, mace, staff, and polearm.
- **Ranged**: bow, gun, and crossbow.
- **Off-Hand**: shield and holdable/focus.

The equipped item's inventory location determines physical topology only: single two-hand, dual two-hand, dual one-hand, mixed dual weapons, weapon plus shield/focus, ranged, or unarmed. Quest Chronicle then asks Blizzard whether each exact appearance category is valid for the equipped item in each hand. This preserves unusual class, specialization, talent, artifact, and patch-specific rules without hardcoding a growing class exception table.

For example, a Fury warrior can physically dual-wield two-handed weapons while Blizzard may permit both one-handed and two-handed appearance categories on those items. Both families become available when Blizzard reports them as valid. Ranged and shield/focus remain unavailable unless Blizzard permits those categories for the corresponding equipped hand.

Clicking a weapon family row browses its filtered collection. Its checkbox includes or excludes the family from generation, while the **>** button opens an anchored type flyout containing:

- one checkbox per exact weapon type;
- collected previewable counts;
- **All Compatible**;
- **Equipped Type**;
- **Clear**;
- **Done**.

Only types checked by the player and currently permitted by Blizzard appear in the weapon browser or generation pool. Quest Chronicle chooses a type before choosing an appearance so categories with enormous collections do not automatically drown out smaller selected categories.

When two weapon hands are equipped, **Link weapon hands** prefers the same family and exact type in both hands. Disabling it lets each hand generate independently from its own Blizzard capability matrix. Equipment, specialization, active talent group, and trait-configuration changes refresh those permissions without rescanning the wardrobe.

Weapon-family choices, exact type filters, and the linked-hands preference are stored with every outfit concept. Loading a concept restores its preferences, then intersects them with Blizzard's current permissions. Dormant preferences remain saved rather than being deleted. Custom Sets continue to receive only the finished appearance recipe.

### Current Look

Every equipment-slot button now shows the icon currently represented by the embedded model, whether it comes from a selected appearance or equipped gear. Hidden icons are desaturated, while locked slots retain the gold padlock and border.

The **Current Look** button opens a compact two-column manifest listing every preview layer, its exact appearance or equipped-item name, and its Selected, Equipped, Hidden, and Locked state. Only the active weapon configuration is listed.

Selected Current Look layers use the same detailed tooltip as the appearance browser: source and item IDs, compatibility, generated-pool eligibility, the active style or Chronicle Echo score, matching terms, and zone preferences. Equipped-only rows use a truthful equipment summary because no collected appearance source is available to score.


## Outfits: Wardrobe Foundation

The Outfits tab can scan the account wardrobe for appearances collected and displayable by the current character. It caches compatible sources by equipment slot and lets the player manually assemble a non-destructive preview on an embedded character model. Quest Chronicle performs exactly one automatic wardrobe scan after each login or `/reload`. Collection changes later in the same session only mark the cache as potentially stale; they never trigger another scan. Each scan records its duration.

Selections and concepts retain each collapsed visual ID beside Blizzard's representative source ID. If a later scan chooses a different compatible source for the same visual, Quest Chronicle rebinds the preview and saved concept instead of treating the appearance as missing. Legacy selections and concepts gain this identity additively from the existing cache.

Ordinary **Save / Update** stores only the Quest Chronicle concept. Native export is separate:

- **Save to Custom Sets** creates a new Blizzard Custom Set or updates the linked one.
- **Save as New** creates another Custom Set and links the concept to it.
- **Replace Existing** lets you choose a native Custom Set whose appearance recipe will be replaced.

Quest Chronicle remains the authoritative backup. Replacing a native Custom Set stores up to five internal backups of the overwritten Custom Set data. No transmog is applied, no gold is spent, and Blizzard Outfit slots are never changed.

Existing pre-v1 concepts remain local until explicitly migrated. The login scan refreshes the collection once per addon session. If WoW reports a later collection change, **Collection may be stale** appears beside **Scan Collection** until the player chooses a convenient time to refresh manually.
