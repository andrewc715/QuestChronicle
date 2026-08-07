# Quest Chronicle v1.11.8 Architecture & Development Plan

## Cooperative era-evidence scheduling closure

## Release purpose

Quest Chronicle v1.11.8 closes the remaining cooperative-performance gap in the first authoritative Zone anchor-policy slice.

The current Zone architecture remains:

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
```

The preceding closure releases established and Retail-validated the surrounding machinery:

```text
v1.11.3  Zone anchor-policy authority
v1.11.4  realistic Debug History persistence
v1.11.5  bounded weapon eligibility and capability snapshots
v1.11.6  adaptive diagnostic compaction and export lineage
v1.11.7  cooperative contextual-support eligibility, fallback, and beam finalization
```

The v1.11.7 Retail batch proved that contextual-support scheduling is no longer the bottleneck. Its cold generation and two of three warm rerolls passed the frozen performance gate. The sole failed warm run was:

```text
Longest worker slice: 8.9 ms
Largest instrumented call: Era evidence 8.3 ms
Maximum slice debt: 3.40 ms
Post-expensive continuations: 0
```

The same action recorded healthy support scheduling:

```text
Largest support subphase: 1.17 ms
Support stage finalizations: 7
Fresh-slice deferrals: 7
```

v1.11.8 therefore has one narrow purpose:

```text
Preserve every era-evidence result, cache outcome, candidate order,
Zone score, random draw, and selected appearance, while splitting
one synchronous per-source evidence bundle into bounded cooperative
operations that cannot begin late in an already-used worker slice.
```

This release closes execution scheduling only. It does not redesign the era model or begin the Zone-native support-policy slice.

---

# Starting point

Create v1.11.8 directly from the exact Quest Chronicle v1.11.7 package:

```text
QuestChronicle-v1.11.7.zip
SHA-256:
e0eddc6c6c66d407a0960dc1355c89a64845db68792293c9d0c9055b6d449ff0
```

v1.11.7 remains authoritative for:

- `CONTEXT_EVIDENCE_V1`;
- Zone Context Snapshot format 1;
- Zone Affinity format 2;
- `ZONE_ANCHOR_POLICY_V1` coefficients and authority;
- Zone debug export format 4;
- independent latest-Zone and latest-policy report lineage;
- `DIAGNOSTIC_ESCAPE_V1`;
- adaptive diagnostic compaction tiers 0 through 6;
- the 20,480-byte report ceiling;
- bounded weapon-style eligibility;
- reusable weapon capability snapshots;
- cooperative support eligibility with marker batch 4;
- resumable support fallback scans;
- fresh-slice support beam finalization;
- legal weapon routes and linked-visual handling;
- stale Zone-context and weapon-capability commit protection;
- current support scoring, budgets, validation, and repair;
- all locks, hidden slots, novelty classes, and repeat penalties.

No earlier package is an acceptable implementation baseline.

---

# Retail evidence

## Cold Generate Outfit

Observed in v1.11.7:

```text
Prepared: 465 frames • 6.7 sec
Longest worker slice: 7.6 ms
Largest instrumented call: UI refresh 2.3 ms
Maximum slice debt: 0.00 ms
Post-expensive continuations: 0
```

Era evidence did not dominate this action. The cold action already passes the below-16-ms closure gate.

## Warm Reroll Unlocked sequence

Observed:

```text
Warm 1
Worker slice: 7.7 ms
Largest call: UI refresh 2.7 ms
Maximum slice debt: 0.00 ms
Post-expensive continuations: 0

Warm 2
Worker slice: 8.9 ms
Largest call: Era evidence 8.3 ms
Maximum slice debt: 3.40 ms
Post-expensive continuations: 0

Warm 3
Worker slice: 5.5 ms
Largest call: UI refresh 2.4 ms
Maximum slice debt: 0.00 ms
Post-expensive continuations: 0
```

Two of three warm runs passed. The middle run failed all of the following closure expectations:

```text
worker slice below 8.0 ms
largest instrumented call below 8.0 ms
maximum slice debt at or below 2.0 ms
zero performance warnings
```

The failure was isolated to `eraEvidence`. Weapon and support work remained bounded.

## Diagnostic contracts remained healthy

All four v1.11.7 reports persisted at `SUMMARY_TABLES` without emergency stubs or rejection.

Format-4 Zone export retained:

- `ZONE_ANCHOR_POLICY_V1` source lineage;
- worker-slice and largest-call timing;
- weapon capability and eligibility counters;
- support operation and fresh-slice counters;
- scheduler debt and continuation integrity.

v1.11.8 must preserve these validated contracts.

---

# Root-cause model

## The outer era worker is already cooperative

`Core/ZoneStyle/EraEvidence.lua` already exposes:

```text
CreateSourceEraEvidenceWork(source)
StepSourceEraEvidenceWork(work, maxCandidates)
```

Generation callers pass:

```text
GENERATION_ERA_CANDIDATES_PER_OPERATION = 1
```

This means Quest Chronicle processes at most one visual sibling per outer era operation.

That boundary is necessary, but it is not sufficient.

## One visual sibling still resolves synchronously

For each visual sibling, `StepSourceEraEvidenceWork()` currently invokes the monolithic sequence:

```text
BuildEraCandidate
ResolveEraCandidate
```

`ResolveEraCandidate()` performs, in order:

```text
curated correction lookup
set membership lookup
all set-info lookups
tracking-origin lookup
appearance-drop lookup
all drop and tier processing
encounter-era text resolution
item metadata lookup or request
final evidence precedence and pending decision
```

All of that work occurs inside one timed `eraEvidence` call.

A single visual sibling can therefore consume 8 ms or more even though the outer worker correctly limits itself to one sibling.

## Internal yield hooks cannot preempt the call

`StepSourceEraEvidenceWork()` calls `MaybeYieldWeaponGeneration("eraEvidence")` only after a sibling has finished.

That hook can request a yield after the expensive work, but it cannot interrupt:

- set enumeration;
- drop enumeration;
- tracking resolution;
- item metadata access;
- the combined evidence precedence calculation.

The v1.11.7 report confirms the scheduler did yield after the expensive call:

```text
Post-expensive continuations: 0
```

The remaining failure happens inside the call and, secondarily, because that call may begin after prior slice work.

## Existing cache semantics are correct

Era evidence currently uses:

- source-local cache fields;
- persistent generation cache records;
- manifest signatures;
- metadata revisions;
- pending and tracking retry windows;
- item-data and tracking invalidation;
- earliest-era aggregation across all visual siblings;
- stronger-evidence preference within a sibling.

The v1.11.8 repair must not weaken or bypass any of those rules.

---

# Release identity

v1.11.8 retains the established hybrid identity:

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
```

The support policy remains `LEGACY` because no support relevance rule changes.

The era-evidence identity remains unchanged:

```text
Era evidence version: 2
Era manifest version: 3
```

Schema and format state remains:

```text
SavedVariables schema:        2
Courier format:               1
Wardrobe cache:               7
Generation cache:             2
Diagnostic format:            1
Zone Context Snapshot:        1
Zone Affinity:                2
Zone debug export:            4
Zone anchor policy:           1
Adaptive compaction format:   1
```

No migration, cache reset, evidence-version bump, report-format bump, or export-format bump is planned.

---

# Design principles

## 1. Preserve exact evidence precedence

The current evidence ranks remain frozen:

```text
curated   100
set        90
tracking   80
encounter  70
item       40
```

Within one sibling:

- stronger evidence wins;
- equal-rank conflicting eras fail toward the later era;
- an encounter-or-stronger result skips item metadata;
- tracking `DataPending` blocks a weak item-only resolution;
- item pending IDs remain accumulated exactly as today.

Across visual siblings:

- the earliest expansion wins;
- equal expansion prefers stronger evidence;
- pending stronger evidence prevents freezing a weak provisional result;
- pending item IDs are sorted before persistence.

## 2. One bounded operation per cooperative step

A cooperative era step may perform one of the following:

- one state transition;
- one Blizzard list acquisition;
- one set-info lookup;
- one drop record reduction;
- one tier reduction;
- one tracking lookup;
- one item metadata lookup;
- one candidate finalization;
- one aggregate sibling finalization.

It may not perform the entire sibling evidence pipeline in one call.

## 3. Variable external work starts fresh

Operations with variable Blizzard API cost must not begin after earlier work has already consumed the slice.

Fresh-slice admission applies to:

```text
SET_LIST
TRACKING
ENCOUNTER_LIST
ITEM_METADATA
```

A fresh operation begins only when:

```text
operationCount == 0
prior elapsed <= 0.25 ms
forceYield == false
```

Cheap deterministic reduction steps use ordinary phase admission rather than consuming an entire fresh slice.

## 4. Do not raise scheduler budgets

The frozen worker contract remains:

```text
Preferred slice:             5.5 ms
Soft ceiling:                7.5 ms
Expensive-call threshold:    2.0 ms
Fresh-slice prior elapsed:   0.25 ms
```

v1.11.8 must solve the operation boundary, not widen the runway.

## 5. Cache only semantically stable work

The existing aggregate era cache remains authoritative.

A session candidate-fragment cache may be introduced only for fully resolved, non-pending per-sourceID evidence fragments. It must never cache:

- tracking-pending results;
- item-pending results;
- unknown results created while data is loading;
- results whose item or tracking dependency is unresolved.

Any new fragment cache must use conservative invalidation and must not replace the persistent aggregate cache.

## 6. Diagnostics must name the actual expensive operation

A future warning must identify whether time was spent in:

- set-list acquisition;
- set-entry reduction;
- tracking evidence;
- encounter-list acquisition;
- encounter-entry reduction;
- item metadata;
- candidate finalization;
- aggregate finalization.

`Era evidence 8.3 ms` is not sufficient for another closure pass.

---

# Track A: resumable per-sibling era evidence

## New candidate work object

Introduce an internal candidate-resolution work object created for one visual sibling:

```text
CreateEraCandidateResolutionWork(source, sourceID)
StepEraCandidateResolutionWork(work)
DescribeNextEraCandidateOperation(work)
```

Suggested state:

```text
source
sourceID
candidate
stage
best
setIDs
setIndex
setBest
drops
dropIndex
tierIndex
encounterParts
trackingPending
itemPending
pendingItemID
done
result
```

The object is internal. No public addon API is added.

## Candidate stages

The exact stage order is:

```text
BUILD
CURATED
SET_LIST
SET_ENTRY
TRACKING
ENCOUNTER_LIST
ENCOUNTER_DROP
ENCOUNTER_TIER
ENCOUNTER_RESOLVE
EARLY_DECISION
ITEM_METADATA
FINALIZE
DONE
```

### BUILD

Build the candidate once with the same source-info and item-ID fallback rules currently used by `BuildEraCandidate()`.

No evidence decision occurs here.

### CURATED

Apply:

```text
curatedEraItemIDs
GetCuratedSourceOrigin
```

Update `best` through the unchanged `PreferStronger()` rule.

### SET_LIST

Acquire the set-ID list once:

```text
C_TransmogSets.GetSetsContainingSourceID(sourceID)
```

This is a fresh-slice operation.

Missing APIs produce the same no-set-evidence result as today.

### SET_ENTRY

Process exactly one set ID per operation:

```text
C_TransmogSets.GetSetInfo(setID)
```

Only set records with a non-nil `expansionID` participate.

Set labels remain:

```text
set <name-or-setID>
```

Set evidence is folded into `best` with the unchanged rank and later-era conflict rule.

### TRACKING

Resolve tracking exactly once with the current tracking cache and `DataPending` distinction.

This is a fresh-slice operation.

The result updates:

```text
best
trackingPending
```

No item fallback is allowed to override tracking pending.

### ENCOUNTER_LIST

Acquire appearance drops once:

```text
C_TransmogCollection.GetAppearanceSourceDrops(sourceID)
```

This is a fresh-slice operation.

### ENCOUNTER_DROP and ENCOUNTER_TIER

Reduce one drop record or one tier string per operation into the same ordered text stream used by the existing resolver:

```text
instance
encounter
tier 1
tier 2
...
```

The final concatenated text and `ResolveEraFromText()` result must match the current monolithic implementation exactly.

### ENCOUNTER_RESOLVE

Resolve the accumulated encounter text and fold evidence into `best`.

### EARLY_DECISION

Preserve the current early return:

```text
if best.rank >= encounter rank:
    finish without item metadata
```

### ITEM_METADATA

Perform one item metadata lookup, or one data request when missing.

This is a fresh-slice operation.

Preserve the exact explicit 15-result tuple used to read `expansionID`.

### FINALIZE

Return the same tuple currently produced by `ResolveEraCandidate()`:

```text
evidence
candidatePending
pendingItemID
trackingPending
```

If tracking remains pending, the result must remain pending even when item metadata supplied weak evidence.

## Compatibility wrapper

Keep `ResolveEraCandidate(candidate)` as a synchronous compatibility wrapper for non-generation callers and focused tests:

```text
create candidate work
step until done
return existing tuple
```

Generation, support generation, support rerolls, and pending reevaluation must use the cooperative work directly.

---

# Track B: nested aggregate era work

## Outer work retains current semantic responsibility

`CreateSourceEraEvidenceWork(source)` remains responsible for:

- reading valid local or persistent aggregate cache;
- enumerating all visual sibling source IDs;
- selecting the earliest expansion across siblings;
- preserving stronger evidence on equal expansion;
- tracking aggregate pending state;
- sorting pending item IDs;
- writing the existing source-local and persistent aggregate cache.

## Add active candidate work

Extend the outer work object with:

```text
candidateWork
candidateOperations
candidateCompletions
freshSliceDeferrals
fragmentCacheHits
```

`StepSourceEraEvidenceWork()` becomes a driver for the nested candidate work:

1. create `candidateWork` for the current sibling;
2. execute one candidate operation;
3. return to the scheduler if the candidate is not finished;
4. fold the completed candidate result into aggregate state;
5. increment the visual sibling index;
6. finalize aggregate evidence only after every sibling completes.

## Preserve caller-facing return values

The existing return shape remains:

```text
done, result, processed
```

`processed` continues to count completed visual siblings, not internal candidate operations.

A partially advanced sibling returns:

```text
false, nil, 0
```

A completed sibling returns `processed = 1` unless the aggregate also completes.

## Remove ineffective internal yield expectation

The nested work must not rely on `MaybeYieldWeaponGeneration()` to interrupt candidate resolution.

The hook may remain for compatibility, but correctness and bounded work must come from explicit state transitions.

---

# Track C: operation-aware scheduler admission

## Describe the next era operation

Add an operation descriptor on the outer work:

```text
DescribeNextSourceEraEvidenceOperation(work)
```

Suggested results:

```text
CACHE_READ
CANDIDATE_BUILD
CURATED
SET_LIST
SET_ENTRY
TRACKING
ENCOUNTER_LIST
ENCOUNTER_DROP
ENCOUNTER_TIER
ENCOUNTER_RESOLVE
EARLY_DECISION
ITEM_METADATA
CANDIDATE_FINALIZE
AGGREGATE_FINALIZE
COMPLETE
```

The descriptor must also identify whether the operation requires a fresh slice.

## Generation callers

Apply operation-aware admission in every cooperative generation path:

```text
Core/Wardrobe/GenerationWorker.lua
Core/Wardrobe/AnchorSkeletonWorker.lua
Core/Wardrobe/SupportWorker.lua
Core/Wardrobe/SupportRerollScoring.lua
```

For fresh operations:

```text
CanStartFreshGenerationPhase(job, 0.25)
```

For normal operations:

```text
CanStartGenerationPhase(job, reserve)
```

Support rerolls use the equivalent support-reroll slice admission helper. If necessary, add:

```text
CanStartFreshSupportRerollPhase(slice, 0.25)
```

with the same semantics as the generation helper.

## Pending background reevaluation

`PendingEvidenceResolver.lua` must also consume one nested candidate operation at a time.

Its existing background budget remains frozen.

It does not need generation-report diagnostics, but it must not reintroduce monolithic candidate resolution while processing pending item or tracking callbacks.

## No busy waiting

A caller that cannot admit the next operation must:

- return `RUNNING`;
- allow the existing zero-delay timer to schedule the next slice;
- increment the appropriate fresh-slice deferral counter;
- perform no state mutation before the next slice.

---

# Track D: stable candidate-fragment memoization

## Purpose

The aggregate era cache is keyed to a visual manifest and metadata revision. A legitimate aggregate invalidation can force several already-stable sibling fragments to be recomputed.

A small session-only fragment cache prevents repeated set, tracking, encounter, and item work for a sourceID whose evidence is already stable.

## Cache scope

Add an in-memory cache under ZoneStyle private state:

```text
eraCandidateFragmentCache
```

A fragment key must include enough identity to prevent accidental cross-source reuse:

```text
sourceID
itemID
sourceType
```

The fragment stores only the final per-sibling tuple:

```text
evidence
candidatePending = false
pendingItemID = nil
trackingPending = false
```

## Cache eligibility

A fragment may be stored only when:

- candidate resolution is complete;
- `trackingPending == false`;
- `itemPending == false`;
- the result is stable, including a stable no-evidence result;
- the candidate identity is complete enough to build the key.

Pending fragments are never memoized.

## Invalidation

Conservatively clear affected fragments on:

- item-data completion for the fragment itemID;
- tracking-origin invalidation for the fragment sourceID;
- collection or source-manifest changes;
- explicit generation-cache invalidation that changes source metadata identity;
- login-session reset.

A broad session cache clear is acceptable when a precise dependency is unavailable. Stale reuse is not.

## Aggregate cache remains authoritative

The fragment cache accelerates rebuilding one aggregate result. It does not:

- change aggregate cache keys;
- alter retry windows;
- write SavedVariables;
- replace `StorePersistentEraEvidence()`;
- bypass manifest or metadata revision validation.

---

# Track E: era diagnostics and export

## Phase labels

Add detailed timing keys while preserving the compatibility `eraEvidence` aggregate timing:

```text
eraCandidateBuild
eraCurated
eraSetList
eraSetEntry
eraTracking
eraEncounterList
eraEncounterEntry
eraEncounterResolve
eraItemMetadata
eraCandidateFinalize
eraAggregateFinalize
```

For support generation and support rerolls, the same internal operation names may be recorded under the shared era domain rather than duplicating every phase prefix.

## Report counters

Generation performance should expose:

```text
era operations
era visual siblings completed
era fresh-slice deferrals
era fragment-cache hits
era fragment-cache builds
era pending candidate completions
era set-list calls
era set-entry calls
era tracking calls
era encounter-list calls
era encounter-entry operations
era item metadata calls
era aggregate finalizations
largest era subphase key
largest era subphase ms
```

## Debug History rendering

Add a compact line under Performance:

```text
Era evidence scheduling: <operations> operations • <siblings> siblings •
<deferrals> fresh-slice deferrals • <fragment hits> fragment hits
```

Add:

```text
Largest era subphase: <label> <ms>
```

Do not print empty zero-only detail when an old report lacks the fields. Use `Not recorded` where historical distinction matters.

## Zone debug export format 4

Keep export format 4.

Extend `Zone Anchor Policy Performance` with:

```text
Era operations
Era sibling completions
Era fresh-slice deferrals
Era fragment-cache hits
Largest era subphase and time
```

This is an additive diagnostic extension, not a schema change.

## Adaptive compaction

Preserve headline era diagnostics through adaptive compaction:

```text
operations
siblings completed
fresh-slice deferrals
fragment-cache hits
largest subphase key
largest subphase ms
```

Detailed per-stage counts may be removed at `SUMMARY_TABLES` or later.

Emergency and minimal stubs retain the largest era subphase when it caused a performance warning.

---

# Compatibility and parity contract

## Evidence semantics remain frozen

Do not change:

- evidence ranks;
- curated item corrections;
- expansion resolution text rules;
- set, tracking, encounter, or item evidence meaning;
- later-era conflict behavior within one sibling;
- earliest-era behavior across siblings;
- pending tracking precedence;
- pending item collection and sorting;
- retry windows;
- persistent cache keys or version numbers.

## Candidate and selection parity

For fixed source metadata and deterministic random seeds, v1.11.8 must produce exactly the same:

- pre-era eligibility;
- final era eligibility;
- anchor candidate pools and order;
- Zone affinity and policy adjustments;
- armor beam finalists;
- weapon routes and finalists;
- support pools and selected support;
- Phase D repairs;
- final outfit;
- random-call count and order.

## Mode parity

Traveler, Class Fantasy, and Chronicle Echo must remain byte-for-byte behaviorally unchanged.

The shared era-evidence implementation may be called by more than Zone Native, so tests must prove no mode regression.

## Atomicity

A generation action may not commit partially evaluated era evidence.

If the workbench, Zone context, or capability generation becomes stale while era work is suspended, the existing atomic cancellation and stale-commit rules remain authoritative.

---

# Proposed runtime module changes

Expected changes are limited to the era-evidence execution path, scheduler admission, diagnostics, and version metadata.

## New module

```text
Core/ZoneStyle/EraCandidateWork.lua
```

Responsibilities:

- per-sibling candidate state machine;
- exact evidence precedence;
- set and encounter resumable reduction;
- stable fragment-cache lookup and storage;
- next-operation description.

## Existing modules likely changed

```text
Core/ZoneStyle/EraEvidence.lua
Core/Wardrobe/GenerationWorker.lua
Core/Wardrobe/AnchorSkeletonWorker.lua
Core/Wardrobe/SupportWorker.lua
Core/Wardrobe/SupportRerollScoring.lua
Core/Wardrobe/SupportRerollScheduling.lua
Core/Wardrobe/PendingEvidenceResolver.lua
Core/Wardrobe/GenerationPerformance.lua
Core/Diagnostics/PerformanceFormatter.lua
Core/Diagnostics/ReportCompaction.lua
Core/Diagnostics/ReportEmergencyStub.lua
Core/ZoneStyle/Zone/DebugExport.lua
QuestChronicle.lua
QuestChronicle.toc
```

The exact file list may shrink after implementation.

No runtime Lua file may reach 500 lines. Candidate-resolution logic must remain in the new focused module rather than inflating `EraEvidence.lua` beyond the project ceiling.

---

# Implementation sequence

## Phase 0: freeze v1.11.7

1. Verify the exact v1.11.7 ZIP checksum.
2. Extract into a clean worktree.
3. Run the inherited test suite unchanged.
4. Record runtime file hashes and TOC inventory.
5. Add a red fixture reproducing one monolithic candidate with multiple set and encounter entries.

## Phase 1: diagnostics-only decomposition

1. Add detailed era subphase labels.
2. Instrument the existing monolithic resolver without changing behavior.
3. Verify fixed-seed and evidence-result parity.
4. Use the fixture to prove the combined resolver can exceed a synthetic budget.

This phase establishes the precise cost map before changing scheduling.

## Phase 2: extract candidate work

1. Move candidate evidence helpers into `EraCandidateWork.lua`.
2. Implement the stage machine.
3. Keep `ResolveEraCandidate()` as the synchronous compatibility wrapper.
4. Prove exact tuple parity across all evidence and pending cases.

## Phase 3: nest candidate work inside aggregate work

1. Add `candidateWork` to `CreateSourceEraEvidenceWork()`.
2. Advance one candidate operation per step.
3. Preserve `processed` as completed sibling count.
4. Preserve aggregate earliest-era and pending semantics.
5. Preserve local and persistent cache writes.

## Phase 4: add operation-aware admission

1. Add next-operation description.
2. Gate variable API operations on fresh generation slices.
3. Add equivalent fresh admission for cooperative support rerolls.
4. Update the pending resolver to one nested operation per tick.
5. Verify zero state mutation on deferred operations.

## Phase 5: add stable fragment memoization

1. Add the session-only stable fragment cache.
2. Cache only fully resolved non-pending fragments.
3. Wire conservative invalidation.
4. Verify aggregate cache semantics remain unchanged.
5. Verify warm rerolls reuse stable sibling fragments after aggregate invalidation.

## Phase 6: diagnostics and compaction

1. Add era scheduling counters to performance snapshots.
2. Add Debug History rendering.
3. Extend format-4 Zone export.
4. Preserve headline counters through adaptive compaction.
5. Verify worst-case reports remain below 20,480 bytes.

## Phase 7: exact-package validation

1. Run all Lua regression tests.
2. Run all Python static verifiers.
3. Parse every runtime Lua module.
4. Verify every TOC runtime module appears exactly once.
5. Verify no runtime Lua file is 500 lines or longer.
6. Build the final ZIP.
7. Extract the final ZIP into a fresh directory.
8. Repeat the complete validation wall from that extraction.
9. Generate SHA-256 and handoff documents from the exact final archive.

---

# Automated validation

## Monolithic-reference parity fixture

Build a reference implementation matching v1.11.7 and compare it with the cooperative candidate state machine.

Cover:

- no evidence;
- curated correction;
- curated source origin;
- one set;
- multiple sets with conflicting eras;
- tracking evidence;
- tracking pending;
- encounter evidence;
- multiple drops and tiers;
- item evidence;
- item pending;
- encounter-or-stronger early return;
- tracking pending suppressing weak item evidence.

Assert identical:

```text
evidence expansionID
method
label
sourceID
itemID
rank
pending flag
pending itemID
trackingPending flag
```

## Aggregate sibling parity fixture

Use several visual siblings and assert identical:

- earliest expansion selection;
- stronger rank on equal expansion;
- provisional pending behavior;
- candidate count;
- sorted pending item IDs;
- tracking pending flag;
- persisted aggregate cache fields.

## Operation granularity fixture

Instrument every external callback and assert one cooperative step performs at most:

- one list acquisition;
- one set-info lookup;
- one drop reduction;
- one tier reduction;
- one tracking lookup;
- one item lookup.

No step may complete the whole sibling when several operations remain.

## Fresh-slice admission fixture

Start an era operation in a used slice and assert:

- the operation is deferred;
- no Blizzard callback runs;
- no work index advances;
- the deferral counter increments.

Start the same operation in a fresh slice and assert it proceeds.

Cover:

```text
SET_LIST
TRACKING
ENCOUNTER_LIST
ITEM_METADATA
```

## Fragment-cache fixture

Assert:

- stable resolved fragments are reused;
- stable no-evidence fragments are reused;
- item-pending fragments are not cached;
- tracking-pending fragments are not cached;
- item-data invalidation clears affected fragments;
- collection or manifest invalidation clears conservatively;
- aggregate result remains identical with and without fragment reuse.

## Warm aggregate-rebuild fixture

Invalidate only the aggregate visual result while retaining stable sibling fragments.

Assert:

- all stable fragments are reused;
- only unresolved siblings perform API work;
- aggregate evidence is identical;
- no stale fragment survives dependency invalidation.

## Caller coverage fixture

Exercise cooperative era work through:

- legacy armor generation;
- anchor skeleton generation;
- contextual support generation;
- contextual support reroll;
- pending evidence reevaluation.

No path may fall back to monolithic `GetSourceEraEvidence()` when the cooperative API exists.

## Scheduler integrity fixture

Inject synthetic subphase costs and assert:

```text
maximum slice debt <= 2.0 ms
post-expensive continuations == 0
fresh operations never start late
```

An expensive API callback may set force-yield, but no subsequent operation may run in that slice.

## Fixed-seed generation parity fixture

Compare v1.11.7 and v1.11.8 with identical:

- wardrobe data;
- context snapshot;
- cache state;
- random seed;
- locks and hidden slots.

Assert identical:

- candidate ordering;
- policy pool summaries;
- selected anchors;
- weapon bundle;
- support configuration;
- Phase D result;
- final preview state;
- random-call trace.

## Diagnostic compaction fixture

Create a large Zone report containing full era scheduling counters.

Assert:

- report persists below 20,480 bytes;
- adaptive tier and exact final size are correct;
- policy, selected anchors, capability, support, scheduler, and headline era fields survive;
- no emergency stub is needed for the realistic fixture.

## Export regression fixture

Assert format 4 renders:

- latest Zone and policy report lineage;
- capability performance;
- support scheduling performance;
- era scheduling performance;
- `Not recorded` for historical reports lacking v1.11.8 fields.

## Full project regression wall

Retain every inherited v1.11.7 test and verifier.

The final package must pass all inherited and new tests from a fresh extraction.

---

# Retail live validation

## Test 1: cold Zone Generate Outfit

1. Install v1.11.8.
2. Run `/reload`.
3. Wait for the collection refresh to settle as required by the normal test procedure.
4. Generate one Zone Native outfit in the same test zone.
5. Open the new Debug History report.

Required:

```text
Result: Completed
Zone policy: ZONE_ANCHOR_POLICY_V1 • ACTIVE
Fallback: None
Worker slice: < 16.0 ms
Largest call: < 8.0 ms
Maximum slice debt: <= 2.0 ms
Post-expensive continuations: 0
No performance warning
No diagnostic rejection warning
```

Era-specific required evidence:

```text
Era operations: recorded
Era siblings completed: recorded
Largest era subphase: recorded
Largest era subphase: < 4.0 ms target
Fresh-slice deferrals: coherent with variable API work
```

The below-4-ms era target provides margin. The hard closure boundary remains below 8 ms.

## Test 2: three consecutive warm Reroll Unlocked actions

Without reloading, changing zones, changing equipment, or modifying the collection:

1. Run Reroll Unlocked.
2. Wait for completion.
3. Repeat twice more.
4. Open each report.

Every warm run must satisfy:

```text
Worker slice: < 8.0 ms
Largest call: < 8.0 ms
Maximum slice debt: <= 2.0 ms
Post-expensive continuations: 0
No performance warning
Fallback: None
Context stale at commit: No
Capability stale at commit: No
```

Era-specific:

```text
No monolithic eraEvidence overage
Largest era subphase identified
Stable fragment hits visible when applicable
No pending fragment reused as stable
```

All three runs must pass. An average or two-of-three pass does not close the slice.

## Test 3: evidence-result parity

Compare the selected outfit and report semantics with ordinary expected Zone behavior:

- Zone profile and era remain correct;
- no unexpected era-pending fallback appears;
- candidate pools remain populated;
- policy adjustments remain plausible and bounded;
- legal weapon route remains valid;
- support final validation remains clean or legitimately repaired.

The scheduling change must not alter the evidence answer.

## Test 4: pending item-data path

Trigger or observe an item-data pending case when practical.

Required:

- pending evidence remains pending;
- the report does not pass it as stable evidence;
- item-data completion reevaluates the dependency;
- no stale fragment-cache hit survives the callback;
- generation remains atomic.

This test may be marked not naturally reproducible if Retail exposes no pending candidate during the session, but automated coverage remains mandatory.

## Test 5: format-4 export

Run:

```text
/qc zone debug export
```

Required:

- export format remains 4;
- latest Zone report is correct;
- latest policy-bearing report is correct;
- `ZONE_ANCHOR_POLICY_V1` is `ACTIVE`;
- support scheduling counters remain present;
- era scheduling counters are present;
- largest era subphase matches the latest policy report;
- diagnostic persistence metadata is coherent.

## Test 6: latency sanity

The cooperative split must not trade hitches for pathological total latency.

Under the same session and zone, investigate before acceptance if:

```text
cold frames or elapsed time increase by more than roughly 25%
warm frames or elapsed time increase by more than roughly 25%
```

This is a review threshold rather than an automatic failure when Retail variance explains the difference, but any large repeatable regression blocks closure.

## Test 7: individual reroll non-regression

Perform one individual support-slot reroll.

Required:

- retained report;
- correct parent and profile lineage;
- no diagnostic rejection;
- no regression in the already-cooperative contextual reroll path.

The synchronous legacy individual anchor reroll remains outside this release.

---

# Acceptance criteria

v1.11.8 is accepted only when all of the following are true.

## Architecture

- per-sibling era resolution is a resumable state machine;
- one cooperative step performs one bounded operation;
- variable Blizzard API operations require fresh-slice admission;
- the outer aggregate work remains responsible for sibling aggregation and persistence;
- no generation caller uses monolithic era resolution when cooperative APIs are available;
- session fragment caching stores only stable non-pending results;
- all existing cache invalidation and retry semantics remain intact.

## Parity

- evidence tuples match v1.11.7 reference behavior;
- aggregate evidence matches v1.11.7;
- fixed-seed candidate and outfit selection match;
- random consumption matches;
- all mode regressions pass;
- locks, hidden slots, legal routes, support, and Phase D remain unchanged.

## Diagnostics

- era operation counters are recorded;
- the largest era subphase is named and timed;
- fresh-slice deferrals are visible;
- fragment-cache reuse is visible;
- adaptive compaction preserves headline era data;
- format-4 export remains correct;
- no realistic report is rejected.

## Retail performance

- cold Generate Outfit remains below 16 ms;
- all three consecutive warm rerolls remain below 8 ms;
- every largest call remains below 8 ms;
- maximum slice debt remains at or below 2 ms;
- post-expensive continuations remain zero;
- no performance warnings occur;
- no diagnostic report is rejected.

## Package quality

- all Lua regression tests pass;
- all Python verifiers pass;
- every runtime Lua module parses;
- TOC inventory is exact;
- no runtime Lua file is 500 lines or longer;
- final ZIP passes clean-extraction validation;
- SHA-256 matches the delivered package.

---

# Explicit non-goals

v1.11.8 does not:

- change `ZONE_ANCHOR_POLICY_V1` coefficients;
- change evidence ranks or era rules;
- change curated era corrections;
- change Zone profile or provenance registries;
- change support scoring or introduce a Zone-native support policy;
- change beam widths, pool limits, budgets, or repair thresholds;
- change weapon capability, eligibility, or route behavior;
- modernize synchronous individual anchor or weapon rerolls;
- raise scheduler budgets or warning thresholds;
- bump SavedVariables, cache, evidence, diagnostic, or export formats;
- add a persistent candidate-fragment cache;
- precompute the entire wardrobe era graph at login;
- reduce candidate coverage to gain speed;
- change total random calls or their order.

---

# Expected release result

When v1.11.8 passes its Retail closure sequence, Quest Chronicle will have:

```text
Authoritative Zone context and evidence
Authoritative Zone anchor preference
Persistent and exportable policy diagnostics
Bounded weapon eligibility and capability work
Bounded contextual-support work
Bounded per-sibling era-evidence work
Three consecutive warm generations below the closure ceiling
```

At that point the first Zone anchor-policy implementation slice can be declared live-validated and closed.

The next Zone release may then begin policy work beyond anchor selection, rather than continuing to chase scheduler overages through the machinery beneath it.
