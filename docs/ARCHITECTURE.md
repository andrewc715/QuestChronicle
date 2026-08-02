# Quest Chronicle Architecture

Quest Chronicle v1.9.0a6 enforces a maximum of 500 physical lines per runtime Lua file. The public subsystem namespaces remain stable while implementation helpers and shared private state live behind internal namespace tables.

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
: Synchronous generation primitives, atomic weapon bundles, rerolls, and concept persistence.

`Core/Wardrobe/GenerationPerformance.lua`
: Generation phase measurements, persistent performance summaries, post-worker preview/UI timing, and tooltip-ready diagnostics.

`Core/Wardrobe/GenerationWorker.lua`
: Time-first cooperative foreground generation, resumable era-evidence work, private draft state, progress callbacks, and atomic commits.

`Core/Wardrobe/CustomSetBuild.lua`
: Collected-source rebinding and native Custom Set payload construction.

`Core/Wardrobe/CustomSetSyncAndManifest.lua`
: Native save verification, concept synchronization, Current Preview manifest, and source normalization.

`Core/Wardrobe/AppearanceMetadata.lua`
: Full visual-source manifests, item-data prefetching, and era-evidence cache invalidation.

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
: Item/source metadata, promotion detection, Chronicle Intelligence, tracking origins, and source signals.

`Core/ZoneStyle/EraEvidence.lua`
: Provenance-bearing era resolution across curated corrections, native sets, tracked maps, encounter data, item metadata, and visual siblings, including a resumable sibling-source worker for generation.

`Core/ZoneStyle/ProgressionRestrictions.lua`
: Character-progression restrictions such as below-cap Heritage Armor exclusion.

`Core/ZoneStyle/Scoring.lua`
: Outfit naming, coherence, eligibility, source weighting, and weapon ordering.

`Core/ZoneStyle/Traveler/StyleLexicon.lua`
: Traveler-only style vocabulary, compatibility relations, formula weights, visibility weights, and mismatch thresholds.

`Core/ZoneStyle/Traveler/Descriptors.lua`
: Confidence-bearing palette, material, finish, motif, visual-weight, and loudness descriptors.

`Core/ZoneStyle/Traveler/Cohesion.lua`
: Pair cohesion, anchor profiles, accent echo, mismatch classification, and diagnostic budget accounting.

`Core/ZoneStyle/Traveler/Debug.lua`
: Read-only current-outfit analysis and `/qc traveler debug` output.

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

## Traveler cohesion instrumentation (v1.9.0a1 calibration)

`Core/ZoneStyle/Traveler/` contains the observation layer for the Traveler Cohesion Rewrite:

- `StyleLexicon.lua` owns coarse style families, compatibility relations, thresholds, and weights.
- `Descriptors.lua` converts an appearance's available metadata into confidence-bearing visual descriptors.
- `Cohesion.lua` computes pair compatibility, anchor profiles, accent echo, mismatch classes, and the diagnostic budget.
- `Debug.lua` analyzes the current outfit and implements `/qc traveler debug`.

In v1.9.0a6 this subsystem remains read-only. It does not participate in candidate selection or mutate the wardrobe preview.


## Cooperative wardrobe refresh (v1.9.0a2)

The login collection refresh is divided into bounded appearance batches. A slot scan yields after 18 appearances or approximately 3 milliseconds of addon work, whichever comes first. Metadata watch tables are rebuilt during the scan rather than through a full pre-scan hydration pass, and sibling item metadata is requested lazily when era evidence is actually needed.

This preserves the single automatic login refresh while preventing the scan from monopolizing one frame.


## Non-blocking transmog capability refresh (v1.9.0a3)

Quest Chronicle never calls `C_TransmogCollection.UpdateUsableAppearances()` from runtime Lua. On large collections Blizzard may perform that global recalculation synchronously, blocking the client before Quest Chronicle's cooperative workers can yield.

Current weapon permissions are read through the live outfit-slot and weapon-option APIs. Equipment, specialization, talent, and trait events invalidate the cached route matrix and query those live APIs immediately and once more after a short settling delay. Collection scans use the temporary collection filters and category queries directly.

`tools/verify_no_blocking_usability_refresh.py` enforces this boundary during packaging.

## Adaptive cooperative generation (v1.9.0a6)

Armor generation is governed primarily by a 2.5 ms addon-time budget. The worker continues processing inexpensive cached candidates until that budget is consumed; the 2,000-operation ceiling exists only as protection against a stalled or non-advancing timer. This replaces the former 30-candidate limit that produced a stable 204-frame warm-reroll floor on a large wardrobe.

Uncached era evidence uses `ZoneStyle.CreateSourceEraEvidenceWork()` and `ZoneStyle.StepSourceEraEvidenceWork()` to process one visual sibling per operation. Candidates rejected by zone preferences, promotional rules, or progression restrictions are discarded before that era work begins. The ordinary synchronous era API remains available for browser and compatibility callers.

Generation diagnostics are divided among `GenerationPerformance.lua`, the worker, and the Outfits completion callback. Core phases are measured during preparation; preview-model application and the final full workbench refresh are measured on their later frames. The selected armor and weapon bundle remains private until the atomic state commit.

