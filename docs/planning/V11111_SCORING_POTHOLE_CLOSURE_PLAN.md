# Quest Chronicle v1.11.11 Architecture & Development Plan

## Anchor candidate and support bridge scheduling closure

## Release purpose

Quest Chronicle v1.11.11 is the focused performance-closure release that follows the productive scheduling improvements in v1.11.10.

v1.11.10 achieved the large architectural goals that had remained open after the v1.11.8 and v1.11.9 work:

```text
watchdog deadlock: eliminated
same-slice DEFERRED retries: 0
synchronous era progress-guard trips: 0
phantom era deferrals: 0
cold end-to-end latency: 7.0 sec
warm end-to-end latency: 4.3 sec, 4.3 sec, 3.8 sec
contextual support-slot reroll: 0.1 sec
```

The remaining failures are now two narrow scoring islands:

```text
Cold Generate Outfit
worker slice: 11.5 ms
largest call: anchorCandidateScoring 10.2 ms
maximum slice debt: 5.94 ms

Warm Reroll Unlocked #2
worker slice: 11.5 ms
largest call: supportCandidateBridge 7.8 ms
maximum slice debt: 6.01 ms
```

Neither failure is caused by era admission, weapon capability scheduling, support stage finalization, report persistence, or end-to-end frame tax.

v1.11.11 therefore has one tightly bounded purpose:

```text
1. Replace Zone anchor candidate scoring as one opaque operation with a
   resumable candidate-preparation and scoring worker whose variable API
   dependencies are explicitly admitted and whose pure scoring work is
   independently measurable.

2. Remove the remaining indivisible support bridge relationship operation
   by consuming already-materialized descriptors whenever possible and by
   splitting descriptor resolution, candidate-to-target pair scoring, and
   baseline bridge scoring into separate resumable operations.
```

The successful v1.11.10 era admission system is frozen for this release.

---

# Baseline and release authority

## Exact implementation baseline

Build v1.11.11 directly from the exact Retail-tested v1.11.10 package:

```text
QuestChronicle-v1.11.10.zip
SHA-256:
6710405c70d34389809c85751276a08f7570785ca6959443ae7d8cd79d262dfd
```

No earlier package is an acceptable implementation baseline.

## Retail evidence baseline

The authoritative v1.11.10 Retail batch was run in Stormwind City and produced:

```text
Cold Generate Outfit
476 frames • 7.0 sec
worker slice 11.5 ms
largest call anchorCandidateScoring 10.2 ms
slice debt 5.94 ms
phantom era deferrals 0
same-slice retries 0
sync guard trips 0
largest era subphase 1.88 ms
largest support candidate subphase 0.51 ms

Warm #1
297 frames • 4.3 sec
worker slice 5.9 ms
largest call weaponAppearanceLookup 3.5 ms
slice debt 0.36 ms

Warm #2
294 frames • 4.3 sec
worker slice 11.5 ms
largest call supportCandidateBridge 7.8 ms
slice debt 6.01 ms
era API work 0
era deferrals 0

Warm #3
260 frames • 3.8 sec
worker slice 6.2 ms
largest call uiRefresh 1.8 ms
slice debt 0.00 ms

Contextual HANDS reroll
8 frames • 0.1 sec
worker slice 4.7 ms
largest cooperative call rerollStateCommit 0.7 ms
```

This establishes that the remaining performance work is not broad. It is localized to the anchor candidate builder and one support bridge suboperation.

---

# Architecture identity remains frozen

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone context format: 1
Zone affinity format: 2
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor policy format: 1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
Generation API contract: 1
Policy contract: 1
Zone debug export format: 4
Diagnostic report format: 1
SavedVariables schema: 2
Wardrobe cache format: 7
Generation cache format: 2
Persistence ceiling: 20,480 bytes
```

Scheduler constants remain frozen:

```text
Preferred worker budget: 5.5 ms
Soft worker ceiling: 7.5 ms
Expensive-call force-yield threshold: 2.0 ms
Phase-transition reserve: 1.0 ms
Era API headroom reserve: 3.0 ms
```

v1.11.11 may not raise any budget to make a failing call appear acceptable.

---

# Successful v1.11.10 systems that are frozen

The following are treated as validated infrastructure and are not redesign targets in v1.11.11.

## Demand-aware era admission

The v1.11.10 contract remains:

```text
LOCAL
API_HEADROOM
FRESH_ONLY
COMPLETE
```

Required invariants remain:

```text
phantom era deferrals = 0
same-slice DEFERRED retries = 0
synchronous progress-guard trips = 0
post-expensive continuations = 0
```

No changes to `EraExecution.lua`, admission thresholds, or era scheduling policy are planned unless a direct integration defect is discovered while implementing the anchor worker.

Any such defect requires explicit justification and a dedicated parity fixture before inclusion.

## Era evidence semantics

Frozen:

```text
ERA_EVIDENCE_VERSION = 2
ERA_MANIFEST_VERSION = 3
curated > set > tracking > encounter > item precedence
pending item behavior
tracking pending behavior
visual-sibling aggregation
persistent era caches
session fragment cache semantics
```

## Contextual support selection semantics

Frozen:

```text
SUPPORT_POOL_LIMIT = 32
SUPPORT_BEAM_WIDTH = 24
SUPPORT_FINAL_SHORTLIST = 6
SUPPORT_FINAL_SCORE_WINDOW = 20
support profile weights
neighbor definitions
bridge-target definitions
mismatch budget
outlier classes
repeat penalties
fallback first-best tie behavior
Phase D final validation and repair
```

## Weapon architecture

Frozen:

```text
legal weapon routes
capability snapshot lifecycle
weapon style ordering
weapon index invalidation semantics
linked-visual deduplication
```

---

# Source diagnosis A: anchor candidate scoring is still an opaque bundle

## Current foreground path

The Zone armor anchor pool currently reaches this path in `Core/Wardrobe/AnchorSkeletonWorker.lua`:

```text
ValidateSource
Pre-era eligibility
Cooperative era evidence
Final eligibility
EvaluateAnchorCandidateForJob
```

The final call is instrumented as one phase:

```text
anchorCandidateScoring
```

For Zone Native, `EvaluateAnchorCandidateForJob()` calls the active Zone anchor policy, which performs:

```text
BuildAnchorCandidate(...)
AnalyzeAppearance(...)
ApplyAnchorEvidence(...)
GetSourcePreference(...)
```

The Retail 10.2 ms spike can therefore contain several different classes of work while the scheduler sees only one call.

## Legacy candidate construction currently bundles

`BuildAnchorCandidate()` performs, in order:

```text
GetSourceCoherence
ScoreSource
GetTravelerDescriptor
weight calculation
math.random()
poolPriority calculation
candidate table construction
```

Those calls are not guaranteed to be pure cache reads.

### Hidden item metadata boundary

`ScoreSource()` and descriptor construction consume `SourceMetadata()`.

`SourceMetadata()` may call:

```text
C_Item.GetItemInfo / GetItemInfo
C_Item.RequestLoadItemDataByID
```

when source metadata has not yet been verified for the exact current item ID.

That means a call reported only as `anchorCandidateScoring` can still cross a variable Blizzard API boundary.

### Hidden set boundary

`GetSourceCoherence()` and descriptor construction can call:

```text
GetSourceSetIDs
→ C_TransmogSets.GetSetsContainingSourceID
```

on a source-set cache miss.

Again, that API time is currently charged to the opaque anchor candidate score.

### Hidden tracking boundary inside Zone affinity

Zone affinity currently computes provenance with:

```text
GetCuratedSourceOrigin
GetTrackedSourceOrigin
```

`GetTrackedSourceOrigin()` may call:

```text
C_ContentTracking.GetBestMapForTrackable
C_Map.GetMapInfo
BuildMapTrail
ResolveProvenance
```

when `trackedOriginCache[sourceID]` is still unresolved.

A source whose era evidence was tracking-pending can therefore make a second synchronous tracking attempt during anchor candidate scoring.

This is particularly important because v1.11.10 intentionally made era tracking cooperative, but Zone affinity can still cross the same tracking boundary later through an unrelated synchronous scoring call.

## Conclusion

The 10.2 ms Retail result is not evidence that the Zone policy arithmetic is inherently expensive.

The current label combines:

```text
metadata preparation
set preparation
style signal preparation
legacy coherence
legacy scoring
descriptor construction
random pool priority
tracking provenance
Zone affinity
Zone evidence adjustment
favorite lookup
```

v1.11.11 must make those boundaries explicit.

---

# Track A: resumable Zone anchor candidate work

## New runtime module

Preferred new module:

```text
Core/Wardrobe/AnchorCandidateWork.lua
```

Its job is to reproduce the exact candidate produced by the current Zone policy while allowing the scheduler to stop between meaningful suboperations.

The existing synchronous functions remain the reference oracle:

```text
P.BuildAnchorCandidate
P.EvaluateAnchorCandidateForJob
Generation.ZoneAnchorPolicy.EvaluateAnchorCandidate
```

They are not deleted in v1.11.11.

## Scope of cooperative conversion

The cooperative anchor candidate worker is required for Zone Native foreground generation and Zone Native Reroll Unlocked.

Other modes keep their current implementation unless they already route through the same generic worker without semantic change.

Required behavior:

```text
Traveler: unchanged
Class Fantasy: unchanged
Chronicle Echo: unchanged
Zone Native: cooperative candidate worker
```

## Proposed candidate stages

The worker should expose an operation identity before each step.

Recommended stages:

```text
INIT
METADATA_ADMISSION
METADATA_SNAPSHOT
SET_IDS_ADMISSION
SET_IDS_SNAPSHOT
STYLE_SIGNALS
COHERENCE
LEGACY_SCORE
DESCRIPTOR
POOL_RANDOM
TRACKING_ADMISSION
ZONE_AFFINITY
ZONE_POLICY_APPLY
PREFERENCE
COMPLETE
```

The exact names may change during implementation, but the semantic boundaries may not collapse back into one monolithic score.

---

# Track A1: prepared source inputs

## Purpose

The cooperative worker must not split the outer function while leaving hidden API calls inside `ScoreSource()`, `GetSourceCoherence()`, descriptor construction, or Zone affinity.

It therefore needs a small immutable prepared-input object for the current candidate.

Recommended shape:

```text
prepared.metadataText
prepared.itemMetadataVerified
prepared.setIDs
prepared.styleSignals
prepared.expansionID
prepared.trackedOrigin
prepared.trackedOriginKnown
prepared.descriptor
```

This is action-local runtime data only.

It is not persisted and does not change any cache format.

## Metadata preparation

Before legacy scoring, the worker determines whether the source's exact item metadata is already trusted.

If trusted:

```text
admission = LOCAL
```

If an item lookup is actually required:

```text
admission = API_HEADROOM
reserve = 3.0 ms
```

The worker may then call the existing item metadata loader once.

After that attempt, the worker constructs a metadata text snapshot from the source's current fields without issuing another item API call in the same candidate.

This is critical.

A pending item lookup must not cause:

```text
metadata stage API call
→ ScoreSource calls SourceMetadata
→ second unadmitted API call
```

The prepared metadata snapshot is the authoritative text for the remainder of that candidate's score operation.

## Set-ID preparation

Before coherence or descriptor construction, determine whether `sourceSetCache[sourceID]` is already populated.

Cache hit:

```text
LOCAL
```

Cache miss with set API available:

```text
API_HEADROOM
```

The result must be stored through the same session cache semantics already used by `GetSourceSetIDs()`.

No second set-list API call is permitted later in the same candidate.

## Style signals

Style-family analysis is local work and should consume the prepared metadata text.

It must not call the metadata loader again.

The existing style signal cache semantics remain authoritative.

## Expansion identity

The candidate already completed era evidence before anchor scoring.

The worker should therefore use:

```text
candidate.eraEvidence.expansionID
```

as the prepared expansion identity when available.

Descriptor construction must not synchronously resolve era evidence again merely to learn the same expansion ID.

Fallback to the existing synchronous getter is allowed only outside cooperative generation or when no resolved era evidence exists.

---

# Track A2: pure legacy candidate scoring after preparation

Once prepared inputs exist, the following operations must be pure Lua/cache work:

```text
COHERENCE
LEGACY_SCORE
DESCRIPTOR
```

## Coherence parity

The cooperative result must exactly match:

```text
ZoneStyle.GetSourceCoherence(source, context)
```

for:

```text
score
coherent flag
reason
rejection behavior
```

Prepared set IDs and style signals may be passed as optional inputs, but the mathematical and branching rules remain unchanged.

## Legacy score parity

The result must exactly match:

```text
ZoneStyle.ScoreSource(...)
```

including:

```text
profile keyword scoring
avoid keyword scoring
class keyword scoring
traveler keyword scoring
Chronicle score
slot bonus
coherence contribution
favorite bonus
stable affinity
reason ordering and four-reason cap
```

The prepared metadata text must be consumed in place of another metadata-loading call.

## Descriptor parity

Descriptor output must exactly match the current traveler descriptor for the same source state:

```text
fingerprint
palette
material
finish
motifs
setIDs
expansionID
confidence fields
dominant fields
echo palette
visual weight
loudness
curated overrides
```

Prepared metadata, set IDs, style signals, and expansion ID may be injected only to avoid repeated API/cache discovery.

They may not change descriptor values.

---

# Track A3: random-consumption contract

`BuildAnchorCandidate()` currently consumes exactly one `math.random()` after descriptor construction and before Zone affinity is applied.

That order is frozen.

The cooperative worker must preserve:

```text
rejected incoherent candidate → no random call
accepted candidate → exactly one random call
random call occurs after legacy descriptor construction
random call occurs before Zone affinity/policy application
candidate source order remains unchanged
```

No scheduler yield may cause the next source to consume its random value before the current candidate completes.

The pool remains strictly serial at the candidate level.

Fixed-seed traces must prove identical random consumption.

---

# Track A4: cooperative Zone provenance and affinity

## Current hidden problem

`Zone.GetZoneAffinity()` may call `GetTrackedSourceOrigin()` synchronously.

That is not acceptable inside a supposedly pure scoring phase.

## Prepared provenance contract

Before Zone affinity, the worker inspects the tracked-origin cache.

Known cached origin:

```text
LOCAL
prepared.trackedOrigin = cached origin
prepared.trackedOriginKnown = true
```

Stable cached failure:

```text
LOCAL
prepared.trackedOrigin = nil
prepared.trackedOriginKnown = true
```

Unresolved tracking state with tracking API available:

```text
API_HEADROOM
perform one tracking attempt
record resulting origin or unresolved result
prepared.trackedOriginKnown = true for this candidate evaluation
```

The global tracked-origin cache keeps its existing semantics:

```text
success may be cached
stable Failure may be cached as false
DataPending remains globally retryable
```

The candidate-local `trackedOriginKnown` flag only means:

```text
this anchor candidate evaluation already made the one tracking decision
that the old synchronous affinity call would have made
```

It does not convert global DataPending into a permanent failure.

## Pure affinity calculation

Zone affinity should accept optional prepared inputs:

```text
descriptor
expansionID
trackedOrigin
trackedOriginKnown
```

When those inputs are supplied by the cooperative anchor worker, affinity analysis must not invoke item, set, tracking, era, or map APIs.

The result must exactly match the legacy affinity calculation for the same resolved input state:

```text
score
confidence
classification
components
componentStatus
missingChannels
notApplicableChannels
evidence
descriptorFingerprint
profileKey
provenanceKey
```

## Policy application

`Zone.ApplyAnchorEvidence()` remains mathematically unchanged.

Frozen constants remain:

```text
neutral affinity: 0.35
affinity scale: 20
maximum bonus: +8
maximum penalty: -6
full confidence: 0.65
pair bonus maximum: +4
pair scale: 6
CHEST prominence: 1.00
LEGS prominence: 0.90
SHOULDER prominence: 1.00
weapon prominence: 1.10
```

---

# Track A5: locked anchor candidates

Locked anchor sources currently skip normal eligibility and still call the same synchronous candidate scorer.

v1.11.11 must not leave locked anchors as an unbounded escape hatch.

Locked candidate work must use the same resumable preparation stages, with only the existing semantic difference:

```text
coherence rejection is suppressed for fixed=true
candidate.anchorPolicy.locked = true
pool candidate remains sovereign
```

No scoring coefficient or lock rule changes.

---

# Track A6: weapon candidate construction

The same anchor candidate evaluator is also used when the selected legal weapon route is converted into anchor candidates inside weapon-bundle scoring.

v1.11.11 should not create a new cooperative armor path while leaving the exact same synchronous evaluator hidden inside `weaponBundleCohesion`.

Implementation options, in priority order:

```text
Preferred:
Reuse AnchorCandidateWork for main-hand and distinct off-hand candidate
construction inside the existing weapon expansion state machine.

Acceptable only with measured proof:
Keep the synchronous weapon candidate path if a dedicated worst-case fixture
proves each weapon candidate evaluation remains <4.0 ms with all variable
inputs already prepared by weapon eligibility/order work.
```

If the proof fails, cooperative weapon candidate construction becomes mandatory in v1.11.11.

Weapon relationship scoring itself is not redesigned unless it independently violates the Retail gate.

---

# Track B: eliminate the remaining support bridge island

## Current v1.11.10 worker

`SupportCandidateWork.lua` already decomposes candidate scoring into:

```text
INIT
NEIGHBOR_SOURCE
NEIGHBOR_PAIR
NEIGHBOR_FINALIZE
BRIDGE_SOURCE
BRIDGE_PAIR
BRIDGE_BEFORE
BRIDGE_FINALIZE
BUDGET
SCORE
COMPLETE
```

This solved most of the old `supportBeamCandidate` problem.

Retail v1.11.10 shows the decomposition works on most actions:

```text
cold largest support candidate subphase: 0.51 ms
warm #1: 1.45 ms
warm #3: 1.45 ms
```

But warm #2 recorded:

```text
supportCandidateBridge: 7.80 ms
```

The current diagnostic label still combines more than one logical kind of bridge work.

## What BRIDGE currently hides

A `BRIDGE_SOURCE` step can perform:

```text
resolve active anchor or selected support source
GetTravelerDescriptor for a source without a directly attached descriptor
SourceMetadata and descriptor-cache validation
set lookup through descriptor construction
expansion lookup through descriptor construction
style-signal work
```

A `BRIDGE_PAIR` step performs:

```text
GetPairCohesion(candidate.descriptor, targetDescriptor)
```

`BRIDGE_BEFORE` can perform another pair calculation between the two bridge targets.

All are currently reported under the broad `supportCandidateBridge` label.

---

# Track B1: descriptor reuse must be authoritative

The support system already owns most descriptors it needs.

## Anchor descriptors

`BuildContextualSupportProfile()` stores an entry for each active anchor:

```text
profile.entries[*].slotKey
profile.entries[*].descriptor
```

Bridge and neighbor scoring should reuse these descriptors directly.

It should not refetch the anchor source and rebuild its descriptor for every candidate.

## Previously selected support descriptors

Beam nodes store selected support candidates, and each candidate already owns:

```text
candidate.descriptor
```

Use it directly.

## Locked support descriptors

Locked selections are converted to support candidates before the beam root is created.

Their attached candidate descriptors must remain the source of truth.

## Fallback descriptor resolution

Only if a bridge/neighbor target legitimately exists without one of the above prepared descriptors may the worker perform explicit descriptor resolution.

That fallback must be separately staged and measured.

It may not occur inside pair cohesion.

---

# Track B2: finer bridge state machine

Recommended replacement for the current broad bridge sequence:

```text
BRIDGE_TARGET_RESOLVE
BRIDGE_DESCRIPTOR_RESOLVE
BRIDGE_PAIR_CANDIDATE
BRIDGE_AFTER_FINALIZE
BRIDGE_BASELINE_PAIR
BRIDGE_FINALIZE
```

The existing iteration order remains unchanged.

For a two-target bridge such as HANDS:

```text
CHEST
WEAPON
```

candidate-to-target pair scores are still accumulated in that exact order.

The baseline pair remains:

```text
Pair(firstTargetDescriptor, secondTargetDescriptor)
```

and remains after the candidate-to-target accumulation, preserving floating-point and call ordering semantics.

## Required diagnostic identity

The worker should expose at least:

```text
supportCandidateBridgeTarget
supportCandidateBridgeDescriptor
supportCandidateBridgePair
supportCandidateBridgeBaseline
supportCandidateBridgeFinalize
```

The existing compatibility aggregate:

```text
supportCandidateBridge
```

may remain as a summary, but it must no longer be the only timing evidence.

---

# Track B3: bridge admission policy

Normal cached descriptor lookup and pair cohesion are expected to be local operations.

Do not automatically force every bridge pair onto a fresh frame.

That would recreate the frame-tax problem v1.11.10 just removed.

Admission rules:

```text
cached target descriptor → LOCAL
node-selected descriptor → LOCAL
profile anchor descriptor → LOCAL
pair cohesion → normal generation phase admission
fallback descriptor materialization with possible API boundary → API_HEADROOM
```

If profiling proves a pure pair operation can itself exceed 4 ms, add a narrow fresh-slice admission rule for that specific pair operation only.

Do not apply a blanket fresh-slice rule to all bridge work without evidence.

---

# Track B4: partial candidate immutability remains frozen

v1.11.10 established this invariant and v1.11.11 must retain it:

```text
candidate work incomplete
→ no nextBeam mutation
→ no node extension
→ no budget commit
→ no candidate index advance
→ no selected source mutation
```

A bridge yield may only mutate the candidate work object's private progress fields.

The completed decision must remain byte-for-byte semantically equivalent to the legacy `ScoreSupportCandidate()` oracle.

---

# Track B5: fallback path must use the same bridge worker

Fallback scanning must not call a synchronous bridge scorer as a shortcut.

The fallback path keeps:

```text
one candidate at a time
same cooperative SupportCandidateWork
strict lower mismatchSpent wins
exact tie keeps first encountered candidate
no random calls
```

The v1.11.10 fallback parity fixture remains inherited.

---

# Track C: operation-aware scheduler admission

## Anchor candidate admission

The anchor candidate worker should publish a descriptor of its next operation, similar to the era candidate worker.

Recommended operation classes:

```text
LOCAL
API_HEADROOM
COMPLETE
```

`FRESH_ONLY` is not expected initially.

An API-sensitive anchor dependency may start only when the existing scheduler has the required headroom.

Use the existing 3.0 ms API reserve unless a fixture proves a different reserve is necessary.

Do not change the global scheduler constants.

## Support bridge admission

The Support Worker should inspect the detailed candidate subphase before stepping it.

A cached pair operation should use ordinary phase admission.

A fallback descriptor operation that can invoke item/set/tracking APIs should use API headroom admission rather than generic 1.0 ms phase admission.

## Post-expensive rule

The existing `>=2.0 ms` force-yield rule remains authoritative.

After any anchor or support operation that measures at least 2.0 ms:

```text
forceYield = true
post-expensive continuations must remain 0
```

---

# Track D: diagnostics and performance decomposition

## Anchor candidate diagnostics

Add action-level counters:

```text
anchorCandidateSubsteps
anchorCandidateCompletions
anchorCandidateAdmissionDeferrals
anchorCandidateMetadataAPICalls
anchorCandidateSetAPICalls
anchorCandidateTrackingAPICalls
anchorCandidatePreparedMetadataHits
anchorCandidatePreparedSetHits
anchorCandidatePreparedTrackingHits
```

Add maximum timing fields for:

```text
anchorCandidateMetadata
anchorCandidateSetPreparation
anchorCandidateCoherence
anchorCandidateLegacyScore
anchorCandidateDescriptor
anchorCandidateTracking
anchorCandidateAffinity
anchorCandidatePolicyApply
anchorCandidateFinalize
```

The old `anchorCandidateScoring` phase may remain as a compatibility aggregate but should no longer correspond to one indivisible call.

## Support bridge diagnostics

Add counters:

```text
supportBridgeTargetResolutions
supportBridgeDescriptorHits
supportBridgeDescriptorFallbacks
supportBridgeCandidatePairs
supportBridgeBaselinePairs
supportBridgeAdmissionDeferrals
```

Add maximum timings for the detailed bridge phases listed above.

## Zone debug export format

Keep:

```text
Zone debug export format = 4
```

Add optional lines to `Zone Anchor Policy Performance` for the new counters.

Older reports display:

```text
Not recorded
```

No format bump is required because fields are additive diagnostics.

## Adaptive compaction

Headline anchor and bridge performance fields must survive:

```text
SUMMARY_TABLES
MANDATORY_CORE
EMERGENCY_STUB
```

The 20,480-byte report ceiling remains unchanged.

The current report sizes near 19.5-19.8 KB after compaction mean v1.11.11 must not retain large per-candidate arrays in persisted reports.

Persist scalar counters and maximums only.

---

# File-size and module-boundary constraints

The runtime rule remains:

```text
no Lua runtime file >=500 lines
```

This matters immediately because the v1.11.10 baseline contains near-ceiling files:

```text
Core/ZoneStyle/SourceMetadata.lua: 499 lines
Core/Wardrobe/GenerationPerformance.lua: 497 lines
```

## SourceMetadata.lua rule

Do not grow this file.

Optional prepared-input parameters may be implemented through line-neutral replacements where practical.

If more than a trivial line-neutral change is required, extract new prepared-source helpers into a new module rather than adding lines.

Preferred helper module if needed:

```text
Core/ZoneStyle/PreparedSourceView.lua
```

It may own:

```text
metadata text snapshot from current source fields
prepared set ID view
prepared style signal view
prepared tracked-origin view
```

without changing cache formats.

## GenerationPerformance.lua rule

Do not append another label block to the 497-line file.

If new phase labels require more than the available line budget, extract the existing phase-label registry into:

```text
Core/Wardrobe/GenerationPerformanceLabels.lua
```

This extraction must be behavior-neutral and covered by the existing report-format fixtures.

It is preferable to violating the 500-line rule or compressing diagnostics into unreadable one-line tables merely to fit.

---

# Proposed runtime file changes

## New modules likely

```text
Core/Wardrobe/AnchorCandidateWork.lua
```

Potential additional modules only if required by line-budget constraints:

```text
Core/ZoneStyle/PreparedSourceView.lua
Core/Wardrobe/GenerationPerformanceLabels.lua
```

## Existing modules likely modified

```text
Core/Wardrobe/AnchorSkeletonWorker.lua
Core/Wardrobe/AnchorSkeletonSearch.lua
Core/Wardrobe/AnchorPolicyBridge.lua
Core/Wardrobe/SupportCandidateWork.lua
Core/Wardrobe/SupportBeam.lua
Core/Wardrobe/SupportWorker.lua
Core/Wardrobe/GenerationScheduling.lua
Core/Wardrobe/GenerationPerformance.lua
Core/ZoneStyle/Scoring.lua
Core/ZoneStyle/Traveler/Descriptors.lua
Core/ZoneStyle/Zone/Affinity.lua
Core/Generation/Modes/Zone/AnchorPolicy.lua
Core/Diagnostics/SnapshotBuilder.lua
Core/Diagnostics/ReportFormatter.lua
Core/Diagnostics/ReportCompaction.lua
Core/Diagnostics/ReportEmergencyStub.lua
Core/ZoneStyle/Zone/DebugExport.lua
QuestChronicle.toc
version metadata
```

This is an expected list, not permission to change all files.

The implementation should keep the actual diff narrower wherever possible.

---

# Implementation phases

## Phase 0: freeze the exact v1.11.10 baseline

Before modification:

```text
verify ZIP SHA-256
extract to a clean worktree
run all inherited Lua tests
run all inherited Python/static verifiers
parse every TOC runtime Lua module
record line counts
record byte-level runtime baseline
```

The untouched baseline must pass before v1.11.11 work begins.

## Phase 1: diagnostics-first reproduction

Before changing scoring semantics, add synthetic instrumentation capable of distinguishing:

```text
anchor metadata
anchor set preparation
anchor legacy coherence
anchor legacy score
anchor descriptor
anchor tracking
anchor Zone affinity
anchor policy apply

support bridge target resolution
support bridge descriptor resolution
support bridge candidate pair
support bridge baseline pair
```

Synthetic fixtures should deliberately inject a slow boundary into each candidate operation one at a time.

The test must prove that the diagnostic names the correct subphase.

## Phase 2: prepared source input contract

Implement the action-local prepared input object.

Prove:

```text
one metadata API attempt maximum per candidate evaluation
one set-list API attempt maximum per candidate evaluation
one tracking API attempt maximum per candidate affinity evaluation
no hidden second API call from legacy scoring or descriptor construction
```

No random call occurs in this phase.

## Phase 3: cooperative anchor candidate worker

Implement the staged worker and integrate it into Zone armor anchor pool generation.

The source cannot advance until the current candidate is complete or rejected.

Then integrate locked anchor sources.

Run fixed-seed parity before touching weapon candidate construction.

## Phase 4: weapon candidate boundary audit

Measure main/off-hand candidate construction with the prepared-input worker available.

If the existing weapon path cannot prove <4.0 ms per candidate in worst-case fixtures, integrate the cooperative candidate worker into weapon finalist scoring.

Do not redesign weapon route selection.

## Phase 5: support bridge descriptor reuse

Modify `SupportCandidateWork` so anchor bridge targets reuse descriptors from the support profile and node-selected support targets reuse candidate descriptors.

Add a narrow fallback descriptor-resolution path only where no prepared descriptor exists.

## Phase 6: support bridge micro-steps

Replace broad bridge timing with target, descriptor, candidate-pair, baseline-pair, and finalize substeps.

Preserve accumulation order.

## Phase 7: report/export integration

Add scalar counters and maximums.

Verify adaptive compaction.

Keep export format 4.

## Phase 8: release stamping and exact-package validation

Only after all tests are green:

```text
stamp 1.11.11
update TOC
build exact ZIP
compute SHA-256
extract ZIP fresh
rerun entire Lua wall
rerun every static verifier
rerun runtime syntax and TOC uniqueness checks
rerun line-count verifier
```

The package tested after fresh extraction is the only package eligible for Retail handoff.

---

# Automated test plan

## Test A: anchor candidate exact parity

For a matrix of sources and contexts, compare the cooperative result to the v1.11.10 reference oracle.

Cover:

```text
normal armor candidate
favorite candidate
candidate with Chronicle score
candidate sharing Blizzard set with profile
candidate sharing style family with profile
incoherent dramatic candidate
fixed/locked incoherent candidate
candidate with curated descriptor override
candidate with no descriptor lexicon hits
candidate with known tracked origin
candidate with stable tracked-origin failure
candidate with tracking DataPending
candidate with metadata pending
candidate with known set IDs
candidate with empty set list
```

Compare:

```text
candidate exists / rejected
baseScore
legacyBaseScore
scoreReasons and ordering
coherenceScore
coherenceReason
weight
poolRandomValue
poolPriority
descriptor fingerprint and values
diversityKey
anchorPolicy classification
affinity
confidence
adjustment
final relevance
favorite flag
locked flag
```

## Test B: anchor random trace parity

Use a fixed random seed and a known source sequence.

Record every `math.random()` consumed by candidate construction.

Require:

```text
same number of calls
same candidate consumes each call
same call order
same poolRandomValue
same poolPriority
```

Rejected candidates consume no random value.

## Test C: metadata double-call prevention

Arrange a source whose metadata is initially unresolved.

Instrument item metadata API calls.

Require:

```text
candidate preparation performs at most one admitted item lookup
legacy score performs zero additional item lookups
descriptor performs zero additional item lookups
Zone affinity performs zero item lookups
```

## Test D: set-list double-call prevention

Arrange an uncached source set list.

Require:

```text
one admitted set-list lookup maximum
coherence consumes prepared set IDs
descriptor consumes prepared set IDs
no second set API call
```

## Test E: tracking double-call prevention

Arrange tracking cache as unresolved.

Require:

```text
one admitted tracking lookup during candidate affinity preparation
Zone affinity consumes prepared tracking result
no second tracking API call inside affinity
```

For DataPending, global cache remains retryable after the candidate completes.

## Test F: anchor admission immutability

Simulate insufficient API headroom.

Before denied admission, snapshot the work object.

Require:

```text
status = DEFERRED/RUNNING
no metadata mutation
no set cache mutation
no tracking cache mutation
no stage advancement
no random call
no pool mutation
```

Resume with sufficient headroom and prove normal completion.

## Test G: anchor subphase performance fixture

Use synthetic delays and confirm each delay is isolated to the correct diagnostic label.

Then run a normal worst-case fixture with:

```text
uncached metadata
uncached set IDs
uncached tracking
curated descriptor override
full profile keyword maps
full Zone style evidence
```

Target:

```text
pure anchor scoring subphase <4.0 ms
variable API call <8.0 ms
post-expensive continuation = 0
```

## Test H: support profile descriptor reuse

Construct a support profile with CHEST, LEGS, SHOULDER, and weapon descriptors.

Step hundreds of support candidates.

Require:

```text
anchor bridge targets use profile descriptors
selected support targets use node candidate descriptors
GetTravelerDescriptor is not called for those prepared targets
```

## Test I: support bridge exact parity

Compare `SupportCandidateWork` to `ScoreSupportCandidate()` for every support slot:

```text
WAIST
HANDS
FEET
HEAD
BACK
WRIST
SHIRT
TABARD
```

Cover active and inactive Shoulders, one-visual and two-visual weapon bundles, locked targets, and partial beam nodes.

Compare exact:

```text
neighborCohesion
bridgeBonus
bridgeTarget
bridgeBefore
bridgeAfter
bridgeImprovement
mismatchSpent
budgetState
outlierState
repeatPenalty
fallback
score
allowed
budgetEvaluation
role
```

## Test J: bridge floating-point order

Use crafted descriptors whose pair scores make accumulation order observable.

Require the cooperative worker to preserve:

```text
bridge target order
candidate pair accumulation order
baseline pair timing and order
final subtraction order
```

## Test K: bridge partial-state immutability

Suspend after every bridge substage.

Require:

```text
nextBeam unchanged
budget unchanged
node.selected unchanged
candidate index unchanged
expansion count unchanged
```

Only COMPLETE may commit.

## Test L: support fallback tie parity

Retain inherited v1.11.10 fallback fixture.

Additionally force multiple fallback candidates through the newly split bridge path.

Require exact first-best tie semantics.

## Test M: scheduler integrity

For anchor and support paths:

```text
operation >=2.0 ms
→ forceYield true
→ current frame ends
→ post-expensive continuations = 0
```

## Test N: no era regression

Rerun all era admission tests unchanged.

Require:

```text
phantom deferrals 0
same-slice retries 0
sync guard trips 0
zero-API warm action → zero era API deferrals
```

## Test O: report compaction

Generate a realistic diagnostic report above 35 KB.

Compact under 20,480 bytes.

Require new headline anchor/bridge scalars survive.

## Test P: format-4 export lineage

Use a report history where:

```text
latest Zone report = contextual support REROLL_SLOT
latest policy-bearing report = prior REROLL_UNLOCKED
```

Require the export to continue showing the correct policy-bearing source report and latest Zone report independently.

## Test Q: mode non-regression

Fixed-seed smoke tests:

```text
Traveler
Zone Native
Class Fantasy
Chronicle Echo
```

No selection change is allowed outside the explicit scheduler decomposition.

---

# Synthetic performance gates before packaging

v1.11.11 may not be packaged merely because functional tests pass.

## Anchor candidate synthetic gate

Use a worst-case candidate set large enough to exercise:

```text
metadata preparation
set preparation
style signals
coherence
legacy score
descriptor
tracking provenance
Zone affinity
policy application
```

Require:

```text
largest pure anchor candidate subphase <4.0 ms
largest variable API operation <8.0 ms
maximum simulated warm slice <8.0 ms
maximum simulated warm slice debt <=2.0 ms
post-expensive continuations = 0
```

## Support bridge synthetic gate

Use at least:

```text
24 beam nodes
32 candidates
all support slots represented
anchor bridge targets
selected support bridge targets
fallback candidates
```

Require:

```text
largest bridge target/descriptor/pair/baseline subphase <4.0 ms
no partial beam mutation
same final beam decisions as v1.11.10 oracle
```

## End-to-end synthetic sanity

The new decomposition may not recreate a frame-tax hydra.

Compare operation count and simulated frame count against v1.11.10.

Reject the build if anchor splitting creates hundreds of unnecessary one-operation frames on warm cache reuse.

---

# Retail validation plan

Retail closure must use the exact handoff ZIP.

## Test 1: cold Generate Outfit

After `/reload`, run one Zone Native Generate Outfit.

Hard gates:

```text
Result: Completed
worker slice <16.0 ms
total time <=10.0 sec
largest pure anchor candidate subphase <4.0 ms
no anchor candidate call >=8.0 ms
largest support bridge subphase <4.0 ms
phantom era deferrals = 0
same-slice retries = 0
sync guard trips = 0
post-expensive continuations = 0
no diagnostic rejection
```

Preferred targets:

```text
worker slice <8.0 ms
total time <=8.0 sec
maximum slice debt <=2.0 ms
```

A cold Blizzard API call above 4 ms is not automatically a release failure if:

```text
it was explicitly admitted as API work
it remained <8 ms
it force-yielded when >=2 ms
post-expensive continuation remained 0
```

But it must not be hidden inside anchor scoring.

## Test 2: three consecutive warm Reroll Unlocked actions

Without reload, zone change, equipment change, or spec change, run three consecutive Reroll Unlocked actions.

Every run must satisfy:

```text
worker slice <8.0 ms
largest instrumented call <8.0 ms
maximum slice debt <=2.0 ms
total time <=6.0 sec
preferred total <=5.0 sec
largest pure anchor candidate subphase <4.0 ms
largest support bridge subphase <4.0 ms
phantom era deferrals = 0
same-slice retries = 0
sync guard trips = 0
post-expensive continuations = 0
no worker performance warning
no instrumented-call performance warning
no diagnostic rejection
```

All three must pass.

`2/3` is not closure.

## Test 3: contextual support-slot reroll

Run one contextual support reroll such as HANDS.

Require:

```text
anchor phase reused
profile phase reused
worker slice <8.0 ms
largest call <8.0 ms
no support bridge subphase >=4.0 ms
budget reconciliation PASS
anchor selection unchanged
only requested support slot changes
```

## Test 4: format-4 export

Run:

```text
/qc zone debug export
```

Require:

```text
Zone debug export format 4
correct latest Zone report
correct latest policy-bearing report
ZONE_ANCHOR_POLICY_V1 ACTIVE
context stale at commit NO
new anchor candidate counters visible
new bridge counters visible
phantom deferrals visible
same-slice retries visible
sync guard trips visible
```

## Test 5: capability lifecycle carry-forward

If equipment or spec is changed for testing:

```text
first action rebuilds affected capability/index state once
next unchanged action reuses it
stale at commit remains NO
```

No weapon capability changes are expected from v1.11.11.

---

# Release acceptance criteria

v1.11.11 is package-ready only when all of the following are true:

1. Exact v1.11.10 SHA verified before modification.
2. Cooperative Zone anchor candidate worker exists.
3. Hidden metadata API calls are removed from pure anchor score stages.
4. Hidden set-list API calls are removed from pure anchor score stages.
5. Hidden tracking API calls are removed from pure Zone affinity scoring.
6. Candidate random consumption exactly matches v1.11.10.
7. Locked anchor semantics are unchanged.
8. Weapon candidate boundary is either cooperative or proven bounded by fixture.
9. Support bridge reuses prepared profile/node descriptors.
10. Bridge target, descriptor, candidate-pair, and baseline-pair work are independently resumable/measurable.
11. Support decision parity is exact.
12. Fallback first-best tie behavior is unchanged.
13. Demand-aware era admission remains unchanged and all inherited era tests pass.
14. Scheduler constants remain unchanged.
15. No runtime Lua file reaches 500 lines.
16. All Lua tests pass.
17. All Python/static verifiers pass.
18. Every TOC runtime Lua file parses.
19. Every runtime module appears exactly once in the TOC.
20. Diagnostic compaction remains under 20,480 bytes.
21. Zone debug export remains format 4.
22. Final ZIP passes fresh-extraction validation.
23. Exact final ZIP SHA-256 is recorded in the handoff.

v1.11.11 is Retail-validated only when, in addition:

24. Cold Generate Outfit completes in <=10 seconds and <16 ms worker slice.
25. All three consecutive warm Reroll Unlocked actions complete in <=6 seconds each.
26. All three warm worker slices are <8 ms.
27. All three warm largest instrumented calls are <8 ms.
28. All three warm maximum slice debts are <=2 ms.
29. Pure anchor candidate subphases remain <4 ms.
30. Support bridge subphases remain <4 ms.
31. Phantom era deferrals remain 0.
32. Same-slice DEFERRED retries remain 0.
33. Synchronous era guard trips remain 0.
34. Post-expensive continuations remain 0.
35. No performance warning appears on any warm run.
36. No report is rejected.
37. Format-4 policy/report lineage remains correct.

Only after all 37 criteria pass may the current Zone anchor-policy performance slice be declared closed.

---

# Explicit non-goals

v1.11.11 does not change:

```text
Zone context evidence
Zone profile definitions
provenance registries
starting-zone registries
Zone affinity weights or classification thresholds
Zone anchor policy constants
anchor pool limits
anchor beam width
anchor final shortlist
anchor score window
support pool limit
support beam width
support shortlist
support score formulas
support bridge definitions
support neighbor definitions
mismatch budgets
repeat penalties
outlier classifications
Phase D repair rules
weapon route legality
weapon capability semantics
weapon index policy
random-selection formulas
Traveler behavior
Class Fantasy behavior
Chronicle Echo behavior
report persistence ceiling
cache formats
SavedVariables schema
Courier format
Zone debug export format
scheduler budgets
```

v1.11.11 is not the Zone support-policy rewrite.

It is the final bounded-scoring closure for the currently active `ZONE_ANCHOR_POLICY_V1` implementation slice.

---

# Contingency rules

## If anchor legacy score itself remains >=4 ms after dependencies are prepared

Do not immediately alter scoring weights or keyword tables.

First decompose `ScoreSource()` internally by read-only stages:

```text
profile keywords
avoid keywords
class keywords
traveler keywords
Chronicle keywords
coherence application
favorite/stable affinity
```

Preserve exact accumulation order.

Only implement this deeper split if prepared-input isolation proves the pure score itself is still the bottleneck.

## If traveler descriptor construction remains >=4 ms after dependencies are prepared

Decompose descriptor construction by lexicon family:

```text
palette
material
finish
motif
curated override
normalization/dominants
loudness/finalize
```

Preserve the exact lexicon iteration and final values.

Do not ship an opaque >=4 ms descriptor call merely because overall cold generation stays under 16 ms.

## If a support pair cohesion calculation itself remains >=4 ms

Do not alter pair weights.

Profile the component functions first:

```text
palette
material
finish
visualWeight
motif
provenance
```

If necessary, create a resumable pair-cohesion work object that accumulates components in the same `pairWeights` order used by the reference scorer.

This is a contingency only.

The initial v1.11.11 design assumes descriptor reuse will remove the observed 7.8 ms bridge spike without rewriting pair cohesion.

## If fresh-frame pressure increases latency

Reject the build rather than relaxing latency gates.

The purpose of v1.11.11 is bounded and productive scheduling simultaneously.

No return to one-frame-per-small-operation behavior is acceptable.

---

# Expected handoff artifacts

When implementation is complete, the v1.11.11 handoff should contain:

```text
QuestChronicle-v1.11.11.zip
QuestChronicle-v1.11.11.sha256
QuestChronicle-v1.11.11-Architecture-and-Development-Plan.md
QuestChronicle-v1.11.11-Live-Validation-Steps.md
QuestChronicle-v1.11.11-Automated-Validation.md
QuestChronicle-v1.11.11-Validation-Report.md
QuestChronicle-v1.11.11-Parity-Report.md
QuestChronicle-v1.11.11-Implementation-Conformance.md
QuestChronicle-v1.11.11-Bounded-Scoring-Closure.md
QuestChronicle-v1.11.11-Release-Notes.md
QuestChronicle-v1.11.11-Handoff-Manifest.md
```

The handoff must distinguish:

```text
package-ready
Retail validation pending
Retail validated
```

No package may be described as Retail validated before the live gates are run in WoW.

---

# Planned Conventional Commit message

Subject:

```text
perf: Update Quest Chronicle to v1.11.11
```

Body template:

```text
Split Zone anchor candidate preparation and scoring into bounded cooperative stages
Remove hidden metadata, set, and tracking API work from pure anchor scoring
Reuse prepared support descriptors and split bridge relationship work into micro-steps
Preserve anchor policy, support scoring, random consumption, and scheduler budgets
Retain v1.11.10 demand-aware era admission and end-to-end latency behavior
```

---

# Closure statement

v1.11.10 proved that Quest Chronicle can be both watchdog-safe and fast enough end to end.

v1.11.11 should not redesign that success.

Its job is to expose and bound the final two opaque scoring operations:

```text
anchorCandidateScoring
supportCandidateBridge
```

After this release, the expected scheduler shape is:

```text
variable Blizzard API work
→ explicitly admitted
→ independently measured
→ force-yielded if expensive

pure candidate scoring
→ cache/prepared-input only
→ resumable at meaningful boundaries
→ no hidden API calls

support bridge scoring
→ prepared descriptors
→ one pair operation at a time
→ no partial beam mutation
```

If the exact Retail batch then produces one cold run and three consecutive warm runs within the frozen gates, the `ZONE_ANCHOR_POLICY_V1` performance-closure slice can finally be declared complete and the project can move forward without carrying scheduler debt into the future Zone support-policy work.
