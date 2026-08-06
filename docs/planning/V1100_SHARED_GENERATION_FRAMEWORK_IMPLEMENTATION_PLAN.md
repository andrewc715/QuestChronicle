# Quest Chronicle v1.10.0 Implementation Plan

## Shared Generation Framework Extraction

## Release purpose

Quest Chronicle v1.10.0 extracts the live-validated Traveler generation machinery into a shared, mode-neutral framework.

This release creates the architectural foundation required to rebuild Zone, Class, and Echo with the same mature systems already proven by Traveler:

- legal anchor skeleton generation;
- contextual support beam search;
- mismatch budgeting;
- completed-outfit validation;
- bounded outlier repair;
- alternate-skeleton fallback;
- cooperative scheduling;
- legal weapon routing;
- locks and hidden slots;
- atomic preview commits;
- contextual rerolls;
- immutable diagnostics;
- report compaction;
- curated descriptor support;
- tuning audit support.

v1.10.0 does not begin the Zone rewrite.

The release succeeds only when Traveler remains behaviorally identical to v1.9.0.15 while running through the new shared framework.

```text
v1.10.0 = extraction and parity
v1.11.0 = first Zone implementation slice
```

---

# Starting point

Create v1.10.0 directly from the final live-validated Quest Chronicle v1.9.0.15 source.

Required baseline:

```text
Quest Chronicle v1.9.0.15
SHA-256:
9090655fb8bbec7170698df2b45caae499bdde4da8df67ae6e9dcf32ad49ec66
```

v1.9.0.15 is the authoritative baseline for:

- Traveler descriptor construction;
- the six validated curated visual overrides;
- Phase B anchor behavior;
- Phase C support behavior;
- Phase D final validation and repair;
- Phase E tuning audit;
- weapon-index lifecycle reporting;
- reroll reconciliation;
- report compaction;
- scheduler behavior.

Do not base v1.10.0 on an alpha, release candidate reconstruction, or earlier Traveler branch.

---

# Versioning strategy

The multi-mode rewrite uses clean minor-version trains so each major generation mode has its own dedicated release line.

## Shared framework extraction train

```text
v1.10.0  Shared generation framework extraction baseline
v1.10.x  Continue until extraction is complete and live-validated
```

`v1.10.0` defines the extraction contract and first integrated shared-framework build.

Any follow-up release that still belongs to extraction, Traveler parity repair, framework cleanup, shared diagnostics, legacy-adapter correction, or extraction validation remains inside the `v1.10.x` train.

The extraction train closes only when:

- Traveler is live-validated on the shared framework;
- Zone, Class, and Echo remain stable behind legacy adapters;
- all parity, scheduler, report, reroll, cache, and UI-routing gates pass.

## Zone implementation train

```text
v1.11.0  First Zone implementation release
v1.11.x  Continue until Zone is complete and live-validated
```

Zone begins only after the v1.10.x extraction train is formally closed.

The exact Zone releases are chosen from implementation evidence rather than forced into a predetermined count. Likely areas include:

```text
Zone context and evidence
Zone anchor policy
Zone contextual support
Zone final validation and repair
Zone diagnostics and rerolls
Zone curated tuning and promotion
```

## Class implementation train

```text
v1.12.0  First Class implementation release
v1.12.x  Continue until Class is complete and live-validated
```

## Echo implementation train

```text
v1.13.0  First Echo implementation release
v1.13.x  Continue until Echo is complete and live-validated
```

This gives each generation mode a clean, separate minor-version family:

```text
v1.10.x  Shared framework extraction
v1.11.x  Zone generation rewrite
v1.12.x  Class generation rewrite
v1.13.x  Echo generation rewrite
```

---

# Core architectural rule

The shared framework owns generation mechanics.

Each mode owns generation policy.

```text
Shared framework:
How generation runs

Mode policy:
Why one appearance is preferred over another
```

The framework must not contain Traveler-specific assumptions disguised as generic behavior.

Traveler becomes the first policy implementation and the parity reference for every extracted interface.

---

# Target architecture

```text
Quest Chronicle Outfits
│
├── Shared Generation Framework
│   ├── action lifecycle
│   ├── cooperative job scheduling
│   ├── candidate retrieval orchestration
│   ├── anchor search orchestration
│   ├── support search orchestration
│   ├── final validation orchestration
│   ├── repair orchestration
│   ├── legal weapon topology
│   ├── locks and hidden state
│   ├── reroll orchestration
│   ├── atomic commit
│   ├── report snapshots
│   ├── report compaction
│   └── performance diagnostics
│
├── Shared Visual Language
│   ├── appearance descriptors
│   ├── curated overrides
│   ├── palette relationships
│   ├── finish relationships
│   ├── material relationships
│   ├── visual weight
│   ├── motif
│   ├── echo support
│   └── mismatch analysis
│
├── Mode Registry
│   ├── Traveler policy
│   ├── Zone legacy adapter
│   ├── Class legacy adapter
│   └── Echo legacy adapter
│
└── Existing Outfits UI
```

Traveler uses the shared framework in v1.10.0.

Zone, Class, and Echo remain on their existing behavior through explicit legacy adapters until their own rewrite releases begin.

---

# Shared framework responsibilities

## 1. Generation action lifecycle

The framework owns:

- action identity;
- action type;
- revision snapshots;
- cancellation;
- stale-work detection;
- completion state;
- failure state;
- report ancestry;
- atomic commit eligibility.

Supported actions include:

```text
Generate Outfit
Reroll Unlocked
Reroll Support Slot
```

Legacy individual anchor and weapon-slot rerolls remain outside the extracted modern path unless they already use shared modern machinery.

v1.10.0 does not redesign those legacy actions.

## 2. Cooperative scheduler integration

The framework owns:

- phase registration;
- worker budgets;
- elapsed-time guards;
- force-yield checks;
- phase-transition reservations;
- resumable candidate indices;
- post-expensive-call continuation protection;
- scheduler diagnostics.

The existing budgets remain frozen:

```text
Preferred worker budget: 5.5 ms
Soft ceiling: 7.5 ms
Expensive-call force-yield threshold: 2.0 ms
```

No scheduler surgery is permitted.

## 3. Candidate orchestration

The framework owns the process of:

- requesting candidate sets for a slot;
- applying shared legality checks;
- preserving stable candidate identity;
- controlling candidate limits;
- handling prepared and retained counts;
- storing resumable candidate cursors;
- reusing already prepared pools during repair.

The policy owns:

- contextual relevance;
- mode-specific exclusions;
- mode-specific evidence;
- mode-specific candidate score components.

## 4. Anchor search orchestration

The framework owns:

- anchor slot sequence;
- beam lifecycle;
- beam-width enforcement;
- hard-constraint rejection;
- hard-clash rejection;
- pair-cache orchestration;
- final shortlist construction;
- deterministic tie breaking;
- quality-window enforcement;
- random choice orchestration;
- novelty-reference plumbing.

The policy owns:

- anchor relevance;
- pair cohesion interpretation;
- anchor slot weighting;
- mode-specific novelty meaning;
- score labels used in diagnostics;
- mode-specific anchor quality rules.

Traveler’s current values remain unchanged.

## 5. Support search orchestration

The framework owns:

- support slot sequence;
- candidate-pool lifecycle;
- support beam lifecycle;
- beam-width enforcement;
- shortlist construction;
- budget-ledger mechanics;
- locked commitments;
- hidden-slot exclusion;
- stable tie breaking;
- candidate rejection accounting.

The policy owns:

- support roles;
- profile construction;
- contextual relevance;
- neighbor relationships;
- bridge meaning;
- mode-specific score components;
- mismatch allowance configuration.

## 6. Final validation and repair orchestration

The framework owns:

- completed-configuration validation calls;
- repair target sequencing;
- candidate substitution;
- strict-improvement comparison;
- two-pass cap;
- alternate-skeleton request;
- atomic failure behavior;
- repair ancestry;
- repair diagnostics.

The policy owns:

- what constitutes a final violation;
- mismatch thresholds;
- palette or motif limits;
- echo rules;
- severity formulas;
- repair-target priority;
- completed-configuration objective.

Traveler returns its existing validated Phase D rules unchanged.

## 7. Weapon topology

The shared framework continues to use the current legal weapon-bundle system.

It owns:

- equipment topology snapshot;
- legal bundle construction;
- linked weapon handling;
- one-hand and shield rules;
- two-hand rules;
- ranged routes;
- off-hand companion legality;
- weapon-index use and diagnostics.

Mode policies may score legal bundles differently but may not invent illegal bundles.

## 8. Locks and hidden state

The framework owns the authoritative state rules:

- locked slots are sovereign;
- hidden slots remain hidden;
- unavailable slots remain unavailable;
- locked pieces participate in context;
- hidden pieces do not participate in visual analysis;
- no repair or reroll may silently unlock or unhide a slot.

## 9. Atomic preview commit

The framework owns:

- transient draft state;
- final validation gate;
- preview application;
- state commit;
- UI refresh;
- report completion;
- cancellation rollback.

No mode may commit a partial result.

## 10. Diagnostics and compaction

The framework owns:

- immutable snapshots;
- report identity;
- comparison ancestry;
- cache summaries;
- performance ledgers;
- warning normalization;
- report compaction;
- persistence limits;
- Debug History insertion.

The policy provides mode-specific sections and labels.

---

# Shared visual language

The calibrated Traveler descriptor system should be renamed or wrapped as shared visual-language infrastructure because Zone, Class, and Echo will all need the same factual visual description.

Shared visual properties include:

```text
palette
material
finish
visual weight
motif
provenance
loudness
echo palette
curated fields
descriptor confidence
```

## Extraction rule

Relocate or wrap the current Traveler visual-language modules without changing their formulas or output.

The v1.9.0.15 curated override set remains exact:

```text
Gray Woolen Shirt
Stylish Black Shirt
Hide of Lupos
Rugged Plate Vest
Expedition Defender's Shoulders
Orcish Scout Boots
```

Orcish Scout Boots remain:

```text
palette dark 70%, blue 20%, steel 10%
finish plain 75%, polished 25%
```

They must never regress to green.

## Compatibility aliases

During v1.10.0, compatibility aliases may preserve existing internal call sites while modules are moved.

Every alias must be documented and assigned one of these outcomes:

```text
REMOVE IN v1.10.x
KEEP AS PUBLIC COMPATIBILITY API
LEGACY MODE ONLY
```

No silent duplicate descriptor implementation is allowed.

---

# Mode registry

Add one authoritative mode registry.

Suggested interface:

```lua
RegisterGenerationMode(modeID, policy)
GetGenerationMode(modeID)
GetActiveGenerationMode()
SupportsSharedFramework(modeID)
```

Required registered modes:

```text
TRAVELER
ZONE
CLASS
ECHO
```

In v1.10.0:

```text
TRAVELER → shared framework policy
ZONE     → legacy adapter
CLASS    → legacy adapter
ECHO     → legacy adapter
```

The UI must not infer implementation type from the mode label.

---

# Mode policy contract

Create one documented policy contract.

The exact function names may change during implementation, but the responsibilities must remain explicit.

## Identity

```text
mode ID
display label
diagnostic label
implementation generation
```

## Context

```text
BuildModeContext
BuildContextSeed
DescribeContext
ValidateContext
```

## Candidate relevance

```text
EvaluateAnchorCandidate
EvaluateSupportCandidate
EvaluateWeaponBundle
```

## Anchor policy

```text
GetAnchorSlots
GetAnchorSearchConfiguration
ScoreAnchorPair
ScoreAnchorSkeleton
BuildNoveltyReference
ClassifyNovelty
```

## Support policy

```text
BuildSupportProfile
GetSupportSlots
GetSupportRole
ScoreSupportCandidate
GetSupportBudgetConfiguration
```

## Final validation policy

```text
AnalyzeCompletedConfiguration
CompareValidationObjectives
RankRepairTargets
ApproveLockedOverride
RequestAlternateSkeleton
```

## Naming and diagnostics

```text
BuildOutfitName
BuildModeReportSections
BuildModeWarnings
BuildModeComparison
```

## Tuning support

```text
GetDescriptorProvider
SupportsTuningAudit
BuildTuningObservation
```

Every required callback must fail loudly during development when omitted.

The production runtime must report a clear unsupported-policy error rather than falling back to Traveler behavior.

---

# Traveler policy extraction

Create a dedicated Traveler policy layer that supplies the current behavior to the shared framework.

Suggested modules:

```text
Core/Generation/Modes/Traveler/Policy.lua
Core/Generation/Modes/Traveler/Context.lua
Core/Generation/Modes/Traveler/AnchorPolicy.lua
Core/Generation/Modes/Traveler/SupportPolicy.lua
Core/Generation/Modes/Traveler/ValidationPolicy.lua
Core/Generation/Modes/Traveler/Diagnostics.lua
```

Existing modules may be retained and wrapped where moving them would create unnecessary risk.

The final structure matters less than the responsibility boundary.

## Traveler parity rule

The extracted Traveler policy must preserve:

- every selected appearance ID;
- every anchor score;
- every support score;
- every pair and profile cohesion value;
- every mismatch value;
- every repair decision;
- every novelty result;
- every weapon route;
- every lock and hidden outcome;
- every deterministic scheduler counter;
- every report field;
- every tuning-audit observation.

Allowed differences:

- version number;
- internal module path;
- additive framework identity diagnostics;
- nondeterministic wall-clock timings.

---

# Legacy adapters

Zone, Class, and Echo remain available in v1.10.0.

Create explicit adapters that preserve their existing behavior.

The adapters must:

- keep current mode selection working;
- keep current UI controls working;
- preserve current generation results;
- preserve current reports;
- make the legacy status visible in internal diagnostics;
- prevent legacy logic from accidentally calling Traveler policy callbacks.

Suggested internal marker:

```text
Generation implementation: LEGACY
```

Traveler reports may show:

```text
Generation implementation: SHARED_FRAMEWORK
```

This marker should be compact and may remain Debug-only.

---

# UI scope

The Outfits tab remains visually and functionally in Quest Chronicle.

v1.10.0 must not:

- move the tab;
- redesign the panel;
- dock into the Transmog window;
- rename user-facing modes;
- remove existing controls;
- add Zone rewrite controls;
- change saved UI preferences.

The UI should call the mode registry and shared action API rather than directly invoking Traveler workers.

This prepares the eventual Transmog-window move without beginning it.

---

# New shared API

Create a small internal generation API used by the Outfits UI.

Suggested surface:

```text
GenerateCurrentMode(options)
RerollUnlockedCurrentMode(options)
RerollSupportSlotCurrentMode(slot, options)
CancelCurrentGeneration()
GetCurrentGenerationState()
GetModeCapabilities(modeID)
```

The UI must not know which worker modules implement the action.

Quest Chronicle-specific context remains available to mode policies through a context-provider interface.

---

# Quest Chronicle context provider

Create an explicit adapter for Chronicle-specific information.

Potential inputs:

```text
current zone
current expansion ceiling
current quest context
recent quest themes
character era restrictions
RP journey context
favor or exclusion settings
```

Traveler may continue consuming the same context it uses today.

The shared engine must not import Chronicle quest-history modules directly.

This boundary is required for the eventual Transmog-window extraction.

---

# Saved data and cache compatibility

Retain:

```text
SavedVariables schema: 2
Courier format: 1
Wardrobe cache format: 7
Generation cache: 2
Diagnostic format: 1
Weapon-index format: 1
Traveler tuning audit format: 1
Curated tuning version: 1
```

No cache reset is required.

No SavedVariables migration is planned.

When internal module names change, serialized reports and caches must remain independent of Lua file paths.

---

# Runtime module plan

Suggested new shared modules:

```text
Core/Generation/ModeRegistry.lua
Core/Generation/ModePolicy.lua
Core/Generation/GenerationAPI.lua
Core/Generation/GenerationJob.lua
Core/Generation/GenerationLifecycle.lua
Core/Generation/AnchorEngine.lua
Core/Generation/SupportEngine.lua
Core/Generation/ValidationEngine.lua
Core/Generation/RepairEngine.lua
Core/Generation/RerollEngine.lua
Core/Generation/CommitEngine.lua
Core/Generation/DiagnosticsEngine.lua
Core/Generation/ContextProvider.lua
```

Suggested Traveler policy modules:

```text
Core/Generation/Modes/Traveler/Policy.lua
Core/Generation/Modes/Traveler/Context.lua
Core/Generation/Modes/Traveler/AnchorPolicy.lua
Core/Generation/Modes/Traveler/SupportPolicy.lua
Core/Generation/Modes/Traveler/ValidationPolicy.lua
Core/Generation/Modes/Traveler/Diagnostics.lua
```

Suggested legacy adapters:

```text
Core/Generation/Modes/ZoneLegacyAdapter.lua
Core/Generation/Modes/ClassLegacyAdapter.lua
Core/Generation/Modes/EchoLegacyAdapter.lua
```

These names are planning targets, not a requirement to create empty wrapper files.

Every new module must own a real responsibility.

All runtime Lua files remain below 500 physical lines.

---

# Implementation strategy

## Step 1: Freeze v1.9.0.15 parity fixtures

Before moving code:

- record deterministic Traveler outputs;
- record mode-selection behavior;
- record Zone, Class, and Echo legacy outputs;
- record scheduler counters;
- record tuning-audit behavior;
- record report compaction behavior.

## Step 2: Add the mode registry

Register all four modes without changing generation routing.

Prove mode identity and UI selection parity.

## Step 3: Add the shared generation API

Route existing UI actions through one API while still delegating to the old workers.

Prove zero behavior change.

## Step 4: Extract lifecycle and commit mechanics

Move action identity, cancellation, snapshots, atomic commit, and report completion into shared modules.

Keep Traveler selection logic unchanged.

## Step 5: Extract scheduler orchestration

Move cooperative phase orchestration without changing budgets, phase order, or yields.

## Step 6: Extract anchor orchestration

Separate beam mechanics from Traveler scoring policy.

Run complete parity before continuing.

## Step 7: Extract support orchestration

Separate support beam and ledger mechanics from Traveler profile and scoring policy.

Run complete parity before continuing.

## Step 8: Extract validation and repair orchestration

Separate bounded repair mechanics from Traveler final-analysis policy.

Run complete parity before continuing.

## Step 9: Extract reroll orchestration

Move Reroll Unlocked and support-slot reroll mechanics behind the shared API.

Preserve current-live-outfit reconciliation.

## Step 10: Extract diagnostics

Move shared report construction and compaction while keeping Traveler sections unchanged.

## Step 11: Establish legacy adapters

Route Zone, Class, and Echo explicitly through their unchanged paths.

## Step 12: Remove duplicate routing

Delete superseded direct UI-to-worker calls after all parity tests pass.

## Step 13: Full regression and Retail validation

Package only after every parity and hygiene gate is green.

---

# Automated test plan

## Mode registry

Verify:

- all four modes register exactly once;
- duplicate registration fails;
- unknown mode lookup fails clearly;
- Traveler reports shared-framework capability;
- Zone, Class, and Echo report legacy capability;
- UI mode selection remains stable.

## API routing

Verify:

```text
Generate Outfit
Reroll Unlocked
Reroll Support Slot
Cancel
```

route through the shared API.

No UI code may call a Traveler worker directly after extraction is complete.

## Traveler deterministic parity

Compare v1.10.0 against v1.9.0.15.

Require exact deterministic parity for:

- anchor candidate identities;
- anchor beam results;
- selected skeleton;
- novelty;
- weapon bundles;
- support candidate pools;
- support beam results;
- budgets;
- final validation;
- repair passes;
- alternate skeleton;
- names;
- reports;
- tuning audit;
- reroll ancestry;
- locks and hidden slots.

## Scheduler parity

Require identical deterministic values for:

- phase sequence;
- prevented transitions;
- cooperative yield positions;
- candidate cursors;
- post-expensive continuations;
- worker completion state.

Wall-clock milliseconds may differ.

## Curated descriptor parity

Verify all six curated visuals remain exact.

Fail immediately if Orcish Scout Boots contain green.

## Legacy-mode parity

Run current deterministic fixtures for Zone, Class, and Echo.

Require no output change except additive internal implementation labels.

## Cancellation

Cancel during:

- anchor search;
- weapon expansion;
- support beam;
- final validation;
- repair;
- support reroll.

Every action must preserve the prior preview and record one cancellation result.

## Rerolls

Verify:

- Reroll Unlocked uses the shared framework;
- support rerolls reuse anchors and profile;
- only the target support slot changes;
- current-live-outfit ledger reconciliation passes;
- locks and hidden slots survive;
- no stale-parent false failure returns.

## Report compaction

Verify:

- oversized reports remain visible;
- policy sections survive;
- shared sections survive;
- ancestry survives;
- curated markers survive;
- report size stays below the persistence ceiling.

## Cache compatibility

Load v1.9.0.15 SavedVariables into v1.10.0.

Verify no migration or reset is required.

## File and dependency hygiene

Verify:

- no circular generation-module dependencies;
- no direct Traveler imports from shared modules;
- no duplicated engine implementations;
- all TOC entries appear exactly once;
- all runtime files remain below 500 lines;
- all Lua files parse;
- JSON remains valid.

---

# Cross-version parity report

The release handoff must include a parity report with these categories:

```text
Traveler selection parity
Traveler score parity
Traveler repair parity
Traveler reroll parity
Traveler scheduler parity
Curated descriptor parity
Legacy Zone parity
Legacy Class parity
Legacy Echo parity
Report and cache parity
```

Every difference must be classified as:

```text
VERSION_ONLY
TIMING_ONLY
ADDITIVE_FRAMEWORK_DIAGNOSTIC
SEMANTIC
```

Any unexplained semantic difference blocks the release.

---

# Performance requirements

v1.10.0 must not introduce a repeatable performance regression.

Required:

```text
No new repeated worker slice above 8 ms
No new individual shared-framework call above 8 ms
0 post-expensive continuations
No new synchronous launch stall
No increase in candidate counts
No repeated phase
No extra wardrobe scan
No extra eligibility pass
No extra weapon-index query
```

Framework dispatch and policy callbacks should be constant-time.

The legacy individual anchor and weapon-slot reroll performance issue remains deferred and must not expand this release.

---

# Retail live-validation plan

## Test 1: Version and mode registry

Confirm:

```text
Version: 1.10.0
Traveler implementation: SHARED_FRAMEWORK
Zone implementation: LEGACY
Class implementation: LEGACY
Echo implementation: LEGACY
```

The implementation labels may be Debug-only.

## Test 2: Traveler generation

Perform:

```text
Generate Outfit
Generate Outfit
Reroll Unlocked
Reroll one visible support slot
```

Confirm:

- legal weapon routes;
- final validation;
- repairs when required;
- `Fallback: None`;
- report history;
- report compaction;
- target-isolated support reroll;
- locks and hidden state;
- scheduler integrity.

## Test 3: Curated descriptor spot checks

Inspect:

```text
Rugged Plate Vest
Expedition Defender's Shoulders
Orcish Scout Boots
```

Require the exact v1.9.0.15 vectors.

## Test 4: Legacy modes

Generate one outfit in each existing mode:

```text
Zone
Class
Echo
```

Confirm their existing behavior remains unchanged and no shared Traveler policy leaks into them.

## Test 5: Tuning audit

Run a one-action Traveler audit.

Expected:

```text
Completed Traveler actions: 1
Collection errors: 0
```

## Test 6: Reload persistence

Use `/reload`.

Confirm:

- mode selection persists;
- generated preview persists as before;
- report history behaves as before;
- no cache reset occurs;
- tuning audit persists according to current rules.

---

# Acceptance criteria

v1.10.0 becomes a release candidate only when:

1. Traveler uses the shared generation API.
2. Traveler uses a documented mode policy.
3. Shared modules contain no Traveler-specific policy assumptions.
4. Traveler remains semantically identical to v1.9.0.15.
5. All six curated descriptor results remain exact.
6. Zone, Class, and Echo remain behaviorally unchanged through legacy adapters.
7. UI actions no longer call Traveler workers directly.
8. Locks, hidden slots, weapon routes, rerolls, repair, and atomic commit remain stable.
9. Scheduler phase order and deterministic counters remain stable.
10. Reports and compaction remain stable.
11. Existing SavedVariables load without reset or migration.
12. No runtime Lua file exceeds 500 lines.
13. All automated tests and static verifiers pass.
14. Cross-version parity contains no unexplained semantic difference.
15. Retail validation passes for Traveler and all three legacy modes.
16. No new repeatable performance regression appears.

---

# Explicit non-goals

v1.10.0 does not:

- improve Zone generation;
- improve Class generation;
- improve Echo generation;
- move Outfits into the Transmog window;
- change the Outfits UI;
- add new curated overrides;
- change Traveler scoring;
- change Phase D thresholds;
- fix the legacy individual anchor or weapon reroll path;
- change cache formats;
- change Courier;
- rename user-facing modes.

---

# Handoff to v1.11.0

v1.11.0 begins Zone implementation only after the entire v1.10.x extraction train is live-validated and formally closed.

The first Zone release should consume the shared framework through a new Zone policy rather than modifying shared engine mechanics.

The first v1.11.0 Zone scope is likely:

```text
Zone context contract
Zone evidence model
Zone-native relevance foundation
Zone diagnostics foundation
No support or repair rewrite yet unless the evidence proves the slice is ready
```

The exact v1.11.0 scope will be planned after the extraction reveals the cleanest policy boundary.

---

# Planned release artifacts

```text
QuestChronicle-v1.10.0.zip
QuestChronicle-v1.10.0-Implementation-Plan.md
QuestChronicle-v1.10.0-Live-Validation-Steps.md
QuestChronicle-v1.10.0-Automated-Validation.md
QuestChronicle-v1.10.0-Parity-Report.md
QuestChronicle-v1.10.0-Architecture-Map.md
QuestChronicle-v1.10.0.sha256
```

---

# Planned commit message

```text
refactor: Update Quest Chronicle to v1.10.0

Extract Traveler generation into a shared mode-neutral framework
Add explicit mode policies, registry, and shared generation API
Preserve Traveler selections, scores, repairs, rerolls, and scheduler behavior
Keep Zone, Class, and Echo unchanged behind legacy adapters
Prepare the Outfits system for the v1.11.x Zone implementation train
```
