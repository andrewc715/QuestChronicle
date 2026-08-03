# Quest Chronicle Architecture

Quest Chronicle v1.9.0.2 enforces a maximum of 500 physical lines per runtime Lua file. The public subsystem namespaces remain stable while implementation helpers and shared private state live behind internal namespace tables.

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

## Diagnostics Workbench

`QuestChronicle.Diagnostics` owns bounded, immutable generation reports. `Core/Diagnostics/SnapshotBuilder.lua` copies only primitive generation results after completion, cancellation, fallback, or failure; it never stores mutable beam nodes, coroutine state, candidate arrays, or live wardrobe-source tables. UI callbacks consume completed snapshots only.

`Core/Diagnostics/History.lua` persists diagnostic format 1 at `QuestChronicleDB.debug`. The store retains at most ten reports, rejects malformed or incompatible entries, caps each report at 20 KB, caps approximate history at 200 KB, and prunes oldest entries first. Clearing the store is isolated from Chronicle history, wardrobe caches, concepts, and Courier data.

`Core/Diagnostics/ReportFormatter.lua` renders the same snapshot as rich in-game text or a plain copy report. Raw IDs and verbose zero-count diagnostics are presentation options and do not mutate stored reports. `UI/DebugHistory.lua`, `UI/DebugReport.lua`, and `UI/DebugTab.lua` provide the two-column workbench. A new report refreshes the tab only when it is visible and never changes the active main-window tab.

Generation integration is deliberately read-only. `GenerationWorker.lua` queues a snapshot after its existing completion pipeline, and the Reroll Slot wrapper preserves the original return values. Anchor score reasons and selected pair diagnostics are copied only after the winner has already been chosen, preserving v1.9.0.2 selection behavior.

## Wardrobe

`Core/Wardrobe/Foundation.lua`
: Static definitions, cache/concept stores, Blizzard collection state, and source retrieval helpers.

`Core/Wardrobe/GenerationCacheStore.lua`
: Versioned persistent evidence records, stable outcome identities, migration, state transitions, and bounded pruning.

`Core/Wardrobe/GenerationCacheAccess.lua`
: Persistent evidence, precheck, and final-eligibility accessors kept separate from store construction and migration.

`Core/Wardrobe/GenerationDependencyIndex.lua`
: Runtime reverse indexes from missing item IDs to affected visual evidence and from visuals to their current source records.

`Core/Wardrobe/GenerationCacheInvalidation.lua`
: Item-event classification, exact dependency completion, genuine identity invalidation, and narrow cache-state transitions.

`Core/Wardrobe/GenerationCacheDiagnostics.lua`
: Scan-retention counters, dependency and outcome deltas, and tooltip-ready lifecycle diagnostics.

`Core/Wardrobe/PendingEvidenceResolver.lua`
: Cooperative reevaluation of fully satisfied item dependencies and normalized outcome comparison before downstream invalidation.

`Core/Wardrobe/StateAndPreferences.lua`
: Selection recovery, locks, hidden slots, zone preferences, and generated-name state.

`Core/Wardrobe/EquipmentTopology.lua`
: Equipped item facts, physical weapon topology, transmog slot resolution, and option discovery.

`Core/Wardrobe/AppearanceRoutes.lua`
: Provenance-preserving weapon route construction and per-hand route permissions.

`Core/Wardrobe/WeaponFilters.lua`
: Route diagnostics, capability matrices, family/subtype controls, and browser filters.

`Core/Wardrobe/WeaponCandidateIndex.lua`
: Reusable subtype-to-source indexes for generated weapon routes.

`Core/Wardrobe/WeaponSelection.lua`
: Candidate validation, weighted weapon selection, linked hands, route eligibility, and cooperative yield boundaries.

`Core/Wardrobe/GenerationAndConcepts.lua`
: Synchronous generation primitives, atomic weapon bundles, rerolls, and concept persistence.

`Core/Wardrobe/AnchorSkeletonCache.lua`
: Phase B anchor constants, bounded pairwise cohesion cache, candidate construction, relationship scoring, and stable skeleton signatures.

`Core/Wardrobe/AnchorSkeletonSearch.lua`
: Diversity-balanced candidate pools, bounded Chest/Legs/Shoulders beam expansion, legal weapon-bundle scoring, quality-window selection, and `/qc skeleton debug` diagnostics.

`Core/Wardrobe/WeaponPipeline.lua`
: Coroutine adapter that resumes the unchanged weapon-route algorithm within the foreground generation budget.

`Core/Wardrobe/GenerationPerformance.lua`
: Generation phase measurements, persistent performance summaries, post-worker preview/UI timing, and tooltip-ready diagnostics.

`Core/Wardrobe/GenerationWorker.lua`
: Time-first cooperative foreground generation, anchor-phase dispatch, supporting-slot generation, resumable era-evidence work, private draft state, progress callbacks, and atomic commits.

`Core/Wardrobe/AnchorSkeletonWorker.lua`
: Cooperative anchor candidate preparation, beam stepping, legal weapon expansion, skeleton selection, supporting-slot context rebuilding, and preserved legacy fallback.

`Core/Wardrobe/CustomSetBuild.lua`
: Collected-source rebinding and native Custom Set payload construction.

`Core/Wardrobe/CustomSetSyncAndManifest.lua`
: Native save verification, concept synchronization, Current Preview manifest, and source normalization.

`Core/Wardrobe/AppearanceMetadata.lua`
: Full visual-source manifests, item-data prefetching, persistent-cache migration, and era-evidence invalidation.

`Core/Wardrobe/CollectionScanWorker.lua`
: Cooperative per-slot category and appearance enumeration into a staging cache.

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

`Core/ZoneStyle/GenerationEligibility.lua`
: Context-keyed pre-era and final generation eligibility records reused across rerolls.

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

`UI/Outfits/GenerationRefresh.lua`
: Targeted post-generation updates for the manifest, selected rows, slot icons, actions, and status text.

`UI/Outfits/RefreshAndEvents.lua`
: Full refresh logic, callbacks, and OnShow behavior.

`UI/Outfits/OutfitsTab.lua`
: Small public constructor that executes the ordered builders.

## Debug UI

`UI/DebugTab.lua` constructs the workbench and owns report-added and history-cleared callbacks. `UI/DebugHistory.lua` renders the ten bounded report rows and persists only the selected report ID in ordinary UI state. `UI/DebugReport.lua` renders the selected immutable snapshot and opens a multiline copy dialog with the report preselected for `Ctrl+C`.

The compact Outfits performance tooltip retains only headline timing and skeleton information. Complete phase, cache, score, beam, warning, and comparison ledgers live in the Debug tab, preventing tooltip growth from becoming a usability constraint.

## Line-limit policy

Run from the addon root:

```text
python tools/verify_lua_line_limit.py
```

The command exits nonzero if any Lua file reaches or exceeds 500 physical lines.

## Traveler cohesion instrumentation (v1.9.0a1 calibration)

`Core/ZoneStyle/Traveler/` contains the observation layer for the Traveler Cohesion Rewrite:

- `StyleLexicon.lua` owns coarse style families, compatibility relations, thresholds, and weights.
- `Descriptors.lua` converts an appearance's available metadata into confidence-bearing visual descriptors.
- `Cohesion.lua` computes pair compatibility, anchor profiles, accent echo, mismatch classes, and the diagnostic budget.
- `Debug.lua` analyzes the current outfit and implements `/qc traveler debug`.

In v1.9.0.2 the calibrated descriptors and pair-cohesion function become active inputs to the anchor-skeleton search. `/qc traveler debug` remains a read-only explanation of the completed preview and never mutates generation state.


## Phase B anchor skeletons (v1.9.0.2)

The foreground worker begins with an `ANCHORS` phase when the Phase B modules are loaded. It prepares bounded legal pools for Chest, Legs, and Shoulders through the same source validation, persistent era evidence, progression restrictions, zone preferences, and eligibility caches used by the legacy generator. Locked anchors are fixed candidates. Shoulders are now hideable through the existing hidden-slot pipeline, and hidden anchors are omitted. Missing or generation-ineligible locked anchors force the legacy fallback rather than disappearing from the result.

`AnchorSkeletonSearch.lua` expands Chest seeds through Legs and Shoulders while retaining only the highest-scoring 32 partial skeletons after each stage. Pairwise scores combine the Phase A Traveler descriptors with mode-specific source relevance and loudness balance. A bounded runtime cache avoids recomputing the same stable visual pair. Candidate-pool diversity limits prevent one set or visual family from occupying the entire beam.

The top four legal armor skeletons enter cooperative weapon expansion. Each expansion clones the private draft and resumes the existing weapon-route algorithm through `WeaponPipeline.lua`; no beam score can make an illegal hand, subtype, artifact, or linked appearance valid. The final shortlist is constrained to a quality window and selected with weighted randomness, including a penalty for immediately repeating the previous skeleton.

After selection, the worker rebuilds the style context around the chosen Chest, Legs, Shoulders, and weapon bundle. Waist, Head, Hands, Feet, Wrists, Back, Shirt, and Tabard are then generated as supporting pieces. The complete draft remains private until the existing atomic commit. If the beam cannot produce at least two active legal components, the unchanged independent generator remains available as a compatibility fallback.

Performance telemetry reports candidate-pool sizes, beam expansions and retained counts, pair-cache hits and misses, legal weapon bundles, chosen rank and score, and fallback reason. `/qc skeleton debug` prints the most recent anchor composition and search summary.

## Phase B diagnostics workbench (v1.9.0.3)

Each generation attempt produces one format-1 diagnostic snapshot after the existing pipeline has settled. The snapshot includes the selected physical appearance recipe, anchor diagnostics, beam counters, recorded score components, phase telemetry, cache lifecycle counters, warnings, and comparison with the previous completed report. Reroll Slot uses a synchronous timing snapshot and intentionally does not inherit a previous anchor beam.

Reports remain bounded and immutable across `/reload`. The Debug tab can show raw visual, source, item, and category IDs without persisting alternate copies. Copy formatting is generated only when requested. `/qc debug` opens the latest report; `/qc skeleton debug` remains the concise chat path.

The release has a strict parity boundary: diagnostics may observe recorded values but may not change candidate preparation, beam ordering, weighted finalist selection, weapon routing, supporting-slot generation, locks, hidden slots, or the atomic commit.

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

## Persistent generation cache (v1.9.0a8)

`GenerationCacheStore.lua` owns a versioned SavedVariables substore at `QuestChronicleDB.wardrobe.generationCache`. The store is independent of `wardrobe.bySlot`, whose source tables are intentionally replaced by every successful collection scan. Era evidence is stored once per visual. Pre-era and final eligibility records are stored in small bounded maps per visual.

Persistent evidence identity uses the era resolver version, visual ID, visual-source manifest, and sibling-item manifest. Eligibility identity adds the representative source and item, player progression, zone preference, era/provenance context, restriction setting, mode, and evidence result. The session-local `metadataRevision` counter is deliberately excluded because it restarts when a scan constructs new source tables.

At the start of an automatic or manual scan, the store migrates any v1.9.0a7 evidence still embedded on old source records. Each matching source discovered by the staging scan can then restore evidence from the persistent store. The old transient visual snapshot remains as a compatibility bridge, but it is no longer the persistence boundary.

Item-data events are classified by `GenerationCacheInvalidation.lua`. Ordinary stable callbacks do not invalidate evidence. A pending record reopens only when the exact missing item recorded by its era work becomes available, while genuine generation-relevant metadata identity changes invalidate item-derived evidence. Manifest changes still invalidate evidence. Item-pending records use a bounded ten-minute retry window, tracking-only records use a six-hour retry window, and unknown fail-closed records expire after six hours. Context maps are bounded and age-pruned to prevent unbounded SavedVariables growth.

The generation performance record snapshots cache lifecycle counters. Its tooltip reports loaded, migrated, retained, added, and invalidated entries plus exact invalidation reasons, allowing a post-`/reload` test to distinguish a genuine persistent hit from a fresh session-only warmup.

## Precise item-data invalidation (v1.9.0a9)

`EraEvidence.lua` records `pendingItemIDs` separately from `trackingPending`. This distinction prevents unrelated callbacks from reopening evidence that is waiting on Blizzard content-tracking data rather than item metadata. `AppearanceMetadata.lua` coalesces duplicate item IDs before processing and suppresses presentation refreshes when the representative row did not change.

Retail diagnostics showed that the first implementation still removed pending evidence as soon as a dependency became available, even when recomputation produced the same generation outcome. v1.9.0a10 replaces that destructive transition with the pending-dependency pipeline below.

## Pending-dependency pipeline (v1.9.0a10)

The internal persistent generation-cache store migrates to version 2 in place. Evidence records have explicit `RESOLVED`, `PENDING_ITEMS`, `TRACKING_ONLY`, `STALE`, and `UNKNOWN` states. Item-pending records retain exact unresolved item IDs and a normalized outcome fingerprint containing only generation-relevant facts.

`GenerationDependencyIndex.lua` rebuilds a runtime reverse index from SavedVariables and registers each current scan source by visual. An item callback examines only records that depend on that item. Satisfying one dependency removes only that dependency; records with remaining items stay `PENDING_ITEMS`. Records waiting only on content tracking become `TRACKING_ONLY` and retain their existing eligibility.

When all item dependencies are satisfied, `PendingEvidenceResolver.lua` reevaluates the visual cooperatively. The resolver processes one sibling-source operation at a time and pauses while scanning or foreground generation owns the wardrobe pipeline. The new outcome fingerprint is compared with the cached result before any dependent cache is touched.

An unchanged outcome updates the evidence record in place and preserves both prechecks and final eligibility. A changed outcome invalidates only final eligibility contexts derived from that visual; era-independent prechecks remain reusable. Genuine metadata identity changes and manifest changes continue to invalidate safely through their dedicated paths.

`GenerationCacheDiagnostics.lua` reports callbacks received and coalesced, exact dependencies examined, dependencies still pending or fully satisfied, unchanged and changed evidence outcomes, pending records created, and downstream eligibility invalidations. These counters distinguish real semantic changes from harmless Blizzard metadata completion traffic.

## Cache-and-pipeline generation repair (v1.9.0a7)

The original v1.9.0a7 cache stored era evidence as an explicit `RESOLVED`, `UNKNOWN`, or `PENDING` result. Every result is keyed to the era-evidence version, visual identity, complete visual-source manifest, and representative metadata revision. Unknown results fail closed until metadata or the manifest changes. Pending results failed closed and used a short retry before the later dependency-state pipeline replaced that lifecycle.

A collection scan builds new source tables in a staging cache. Before scanning, `AppearanceMetadata.lua` captures valid generation evidence by visual ID. Matching manifests receive that evidence after the new representative is hydrated. Legacy v1.9.0a6 resolved evidence is upgraded with an explicit state and manifest signature during this transfer. A changed manifest rejects the old evidence.

`GenerationEligibility.lua` caches the inexpensive but frequently repeated result of promotion, Heritage/progression, zone-preference, era-limit, and provenance checks. Its key includes player identity, zone preference, era/provenance context, the restriction setting, source metadata, and the resolved evidence state.

Weapon routing keeps the public and synchronous `GenerateWeapons()` implementation as its source of truth. During cooperative foreground generation, `WeaponPipeline.lua` runs that implementation inside a coroutine. Explicit yield boundaries in route enumeration, candidate indexing, style eligibility, scoring, Blizzard permission checks, and appearance validation return control to `GenerationWorker.lua` before the frame budget is monopolized.

The successful completion callback applies the model on one frame and calls `RefreshGeneratedResult()` on the next. That targeted refresh updates only controls whose values can change after an atomic generated outfit commit, avoiding the expensive weapon-capability and full-layout work performed by the ordinary workbench refresh.


## Phase B Generate Outfit novelty (v1.9.0.4)

`Core/Wardrobe/AnchorSkeletonNovelty.lua` snapshots the currently displayed unlocked Chest, Legs, Shoulders, and logical weapon bundle before generation. Identity is based on stable visual IDs rather than source IDs. Locked and hidden anchors are excluded from overlap scoring.

The beam and legal weapon-route pipeline remain unchanged. After complete legal skeletons enter the existing 28-point quality window, `AnchorSkeletonSearch.lua` classifies them as Initial Generation, Meaningfully New, Partial Change, or Exact Repeat. Generate Outfit selects from the strongest available novelty class and applies centralized repeat penalties only to the final weighted selection score. Reroll Unlocked retains its existing candidate exclusion behavior.

`AnchorSkeletonWorker.lua` records the base score, repeat penalty, adjusted score, compared anchors, changed anchors, repeated anchors, and exact-repeat exception in the immutable diagnostic source. No mutable candidate or beam tables cross the diagnostics boundary.

Generation telemetry distinguishes the complete cooperative worker slice from the largest individually instrumented call inside that slice. Weapon expansion returns control immediately when a weapon operation consumes the time budget.

## Phase B stabilization (v1.9.0.5)

Diagnostic reports reserve a stable report identity and capture their completed parent before generation begins. Hidden, locked, and unavailable anchors are explicit comparison states, and repeated-foundation warnings follow immutable report ancestry rather than searching mutable history after the fact.

Wardrobe scans prewarm weapon-category appearance indexes and compact collected-source metadata. Anchor weapon generation reuses those indexes and validation outcomes across armor finalists, avoiding repeated synchronous collection queries while preserving the existing route and selection semantics. Cooperative resume diagnostics retain the exact slow weapon subphase.

## Phase C contextual support pipeline (v1.9.0.7)

After Phase B commits Chest, Legs, Shoulders, and the legal weapon bundle, the generator derives an immutable Traveler descriptor profile. SupportProfile aggregates palette, material, finish, visual weight, motif, provenance, confidence, tolerance, and anchor relationship diagnostics. SupportBudget creates a slot-aware cumulative mismatch ledger. SupportScoring evaluates profile fit, local neighbor cohesion, bridge improvements, visual impact, repeat pressure, and outlier risk. SupportBeam expands bounded 32-candidate pools through a 24-node cooperative beam and selects from at most six final configurations. SupportWorker applies the winning configuration without changing the Phase B skeleton. SupportReroll provides contextual single-slot replacements and rebuilds support context after anchor or weapon rerolls.

The Debug workbench stores only selected support decisions and aggregate counters. Candidate arrays remain transient. Existing schema, Courier, wardrobe cache, generation cache, and diagnostic format versions remain unchanged.
