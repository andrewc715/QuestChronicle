# Quest Chronicle v1.8.0: Code Normalization

Version 1.8.0 is a structure-only maintenance release built from the live-validated v1.7.2 baseline.

## Mandate

No runtime Lua file may exceed 500 physical lines.

The v1.7.2 addon contained four oversized implementation files:

- `Core/Wardrobe.lua`: 4,626 lines
- `Core/ZoneStyle.lua`: 1,736 lines
- `UI/OutfitsTab.lua`: 1,717 lines
- `QuestChronicle.lua`: 1,535 lines

v1.8.0 replaces those monoliths with focused modules. The largest Lua file in the release is 474 lines.

## Runtime behavior

This release intentionally makes no feature, generation-rule, SavedVariables, Courier, UI, or gameplay behavior changes.

Preserved unchanged from v1.7.2:

- Chronicle event recording and quest lifecycle behavior
- Courier export format and synchronization workflow
- Wardrobe scanning and cache policy
- Zone and Chronicle outfit scoring
- Weapon Appearance Routes
- Fury One-Hand and Two-Hand pair generation
- linked and unlinked hand behavior
- Current Preview Main Hand and Off Hand labels
- Custom Set creation, updating, replacement, and verification
- window, minimap, AddOn Compartment, and settings behavior

## New module layout

### Chronicle core

- `Foundation.lua`: constants, JSON helpers, database/session initialization, Courier snapshot construction
- `QuestLifecycle.lua`: quest snapshots, objective/state transitions, removal classification
- `Commands.lua`: synchronization, event recording, status output, slash-command handling
- `PublicAPI.lua`: public API completion, abandon hooks, and event dispatch

### Wardrobe core

- `Foundation.lua`
- `StateAndPreferences.lua`
- `EquipmentTopology.lua`
- `AppearanceRoutes.lua`
- `WeaponFilters.lua`
- `WeaponSelection.lua`
- `GenerationAndConcepts.lua`
- `CustomSetBuild.lua`
- `CustomSetSyncAndManifest.lua`
- `CollectionScanAndPreview.lua`
- `Events.lua`

### Zone style engine

- `Profiles.lua`
- `Context.lua`
- `SourceMetadata.lua`
- `Scoring.lua`

### Outfits UI

- `OutfitsHelpers.lua`
- `Layout.lua`
- `ConceptManager.lua`
- `AppearanceBrowser.lua`
- `RefreshAndEvents.lua`
- `OutfitsTab.lua`

Private cross-module implementation state is held in namespace-private tables. Public Quest Chronicle, Wardrobe, ZoneStyle, and UI APIs remain unchanged.

## Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache format remains 6.
- Existing concepts, Custom Set links, selections, locks, hidden slots, preferences, and Chronicle records are preserved.
- No wardrobe scan, concept migration, or Custom Set rebuild is required.

## Validation

The release passed:

- a hard line-count check across every Lua file
- Lua syntax loading for every runtime module
- TOC path and load-order validation
- full addon loading under a mocked WoW environment
- public API shape comparison against v1.7.2
- representative Chronicle event-summary equivalence
- zone-era and provenance equivalence
- weapon-family and concept-summary equivalence
- slot and subtype definition equivalence
- Outfits pane construction for both builds
- Outfits pane public-structure equivalence
- ZIP integrity validation
