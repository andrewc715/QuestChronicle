# Quest Chronicle Architecture

Quest Chronicle v1.8.0 enforces a maximum of 500 physical lines per runtime Lua file. The public subsystem namespaces remain stable while implementation helpers and shared private state live behind internal namespace tables.

## Load order

The TOC is the dependency manifest. Modules must remain in the listed order.

1. Chronicle core initializes the global addon namespace and public recorder API.
2. UI Shared initializes the callback bus and common widget helpers.
3. Wardrobe modules build the collection, generation, concepts, Custom Set, and preview APIs.
4. ZoneStyle modules build context, source metadata, and scoring APIs.
5. Tab modules register their constructors.
6. MainWindow and MinimapButton connect the assembled interface.

## Private implementation namespaces

- `QuestChronicle._Core`
- `QuestChronicle.Wardrobe._Private`
- `QuestChronicle.ZoneStyle._Private`
- `QuestChronicle.UI._Outfits`

These tables are runtime implementation details. Other subsystems should use public functions on `QuestChronicle`, `QuestChronicle.Wardrobe`, `QuestChronicle.ZoneStyle`, and `QuestChronicle.UI`.

## Chronicle

`Core/Chronicle/Foundation.lua`
: Core constants, JSON encoding, Courier export construction, database and character/session setup.

`Core/Chronicle/QuestLifecycle.lua`
: Quest-log normalization, fingerprints, active snapshots, objective/state changes, and removal classification.

`Core/Chronicle/Commands.lua`
: Synchronization, acceptance/turn-in/note recording, status/recent/active output, and slash commands.

`Core/Chronicle/PublicAPI.lua`
: Public API completion, abandon hooks, frame events, and lifecycle dispatch.

## Wardrobe

`Core/Wardrobe/Foundation.lua`
: Static definitions, cache/concept stores, Blizzard collection state, and source retrieval helpers.

`Core/Wardrobe/StateAndPreferences.lua`
: Selection recovery, locks, hidden slots, zone preferences, and generated-name state.

`Core/Wardrobe/EquipmentTopology.lua`
: Equipped item facts, physical weapon topology, transmog slot resolution, and option discovery.

`Core/Wardrobe/AppearanceRoutes.lua`
: Provenance-preserving weapon route construction and per-hand route permissions.

`Core/Wardrobe/WeaponFilters.lua`
: Route diagnostics, capability matrices, family/subtype controls, and browser filters.

`Core/Wardrobe/WeaponSelection.lua`
: Candidate validation, weighted weapon selection, linked hands, and route eligibility.

`Core/Wardrobe/GenerationAndConcepts.lua`
: Atomic weapon bundles, full outfit generation, rerolls, and concept persistence.

`Core/Wardrobe/CustomSetBuild.lua`
: Collected-source rebinding and native Custom Set payload construction.

`Core/Wardrobe/CustomSetSyncAndManifest.lua`
: Native save verification, concept synchronization, Current Preview manifest, and source normalization.

`Core/Wardrobe/CollectionScanAndPreview.lua`
: Collection scanning, deliberate refresh policy, manual selections, and model preview application.

`Core/Wardrobe/Events.lua`
: Transmog, equipment, specialization, talent, trait, and login event handling.

## Zone style

`Core/ZoneStyle/Profiles.lua`
: Modes, expansion and zone profiles, starting-zone provenance, and era resolution.

`Core/ZoneStyle/Context.lua`
: Live location detection, profile selection, suggestion state, and zone changes.

`Core/ZoneStyle/SourceMetadata.lua`
: Item/source metadata, promotion detection, Chronicle Intelligence, and source signals.

`Core/ZoneStyle/Scoring.lua`
: Outfit naming, coherence, eligibility, source weighting, and weapon ordering.

## Outfits UI

The Outfits tab uses a shared construction context so its formerly 1,700-line constructor can be assembled by focused modules without changing the resulting frame hierarchy or callbacks.

`UI/Outfits/OutfitsHelpers.lua`
: Stateless formatting, tooltips, diagnostics, and slot-state visuals.

`UI/Outfits/Layout.lua`
: Equipment panel, weapon controls and flyout, model panel, and primary actions.

`UI/Outfits/ConceptManager.lua`
: Local concept management and native Custom Set picker.

`UI/Outfits/AppearanceBrowser.lua`
: Source browser, Current Preview overlay, slot actions, and pagination.

`UI/Outfits/RefreshAndEvents.lua`
: Refresh logic, callbacks, and OnShow behavior.

`UI/Outfits/OutfitsTab.lua`
: Small public constructor that executes the ordered builders.

## Line-limit policy

Run from the addon root:

```text
python tools/verify_lua_line_limit.py
```

The command exits nonzero if any Lua file exceeds 500 physical lines.
