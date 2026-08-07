# Quest Chronicle v1.11.7 Architecture & Development Plan

## Cooperative contextual-support scheduling closure

## Release purpose

Quest Chronicle v1.11.7 closes the final cooperative-performance gap left by the first authoritative Zone anchor-policy slice.

The current Zone architecture is:

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
```

v1.11.3 transferred Zone anchor preference to `ZONE_ANCHOR_POLICY_V1`.

v1.11.4 restored Debug History persistence for realistic Zone reports.

v1.11.5 introduced bounded weapon eligibility, reusable weapon capability snapshots, and independent policy-report lineage.

v1.11.6 replaced brittle report trimming with exact-size adaptive diagnostic compaction and Retail-validated both persistence and export lineage.

The remaining closure failure is now isolated to the legacy contextual-support worker:

```text
Warm Reroll Unlocked run 2
Longest worker slice: 9.0 ms
Largest instrumented call: supportBeamExpansion 7.1 ms
Maximum slice debt: 3.52 ms
Post-expensive continuations: 0
```

The same Retail batch also recorded one cold support eligibility call at 9.3 ms.

v1.11.7 therefore has one narrow purpose:

```text
Keep contextual-support scoring and selection exactly the same,
but make its eligibility, fallback, and beam-finalization work obey
the frozen cooperative scheduler contract under cold and warm load.
```

This release does not begin Zone support-policy design. It modernizes execution boundaries only.

---

# Starting point

Create v1.11.7 directly from the exact Quest Chronicle v1.11.6 package:

```text
QuestChronicle-v1.11.6.zip
SHA-256:
fed59975f609ad3de52dedb4b1106bb4cb372eb825a4ea50634914277b10a199
```

v1.11.6 remains authoritative for:

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
- legal weapon routes and linked-visual deduplication;
- stale Zone-context and weapon-capability commit protection;
- current support scoring, beam width, pool limits, budgets, validation, and repair;
- all locks, hidden-slot behavior, novelty classes, and repeat penalties.

No earlier package is an acceptable implementation baseline.

---

# Retail evidence

## Persistence and lineage passed

The v1.11.6 Retail batch retained all four full reports at `SUMMARY_TABLES` tier:

```text
Cold Generate Outfit: 34,783 -> 18,574 bytes
Warm reroll 1:        34,753 -> 18,230 bytes
Warm reroll 2:        34,714 -> 18,374 bytes
Warm reroll 3:        34,210 -> 18,025 bytes
```

No report-rejection warning appeared.

Zone debug export format 4 correctly identified:

```text
Latest Zone Native report
Latest Zone anchor-policy-bearing report
ZONE_ANCHOR_POLICY_V1 source lineage
Weapon capability and eligibility performance
```

v1.11.7 must not disturb those validated contracts.

## Cold Generate Outfit

Observed:

```text
Prepared: 333 frames • 4.8 sec
Longest worker slice: 9.6 ms
Largest instrumented call: Support eligibility 9.3 ms
Maximum slice debt: 4.08 ms
Post-expensive continuations: 0
```

The cold action passed the existing severe 16 ms closure gate, but the 9.3 ms eligibility call is still a synchronous island inside an otherwise cooperative worker.

## Warm Reroll Unlocked sequence

Observed:

```text
Warm 1
Worker slice: 7.3 ms
Largest call: UI refresh 2.7 ms
Maximum slice debt: 0.00 ms
Post-expensive continuations: 0

Warm 2
Worker slice: 9.0 ms
Largest call: Support beam expansion 7.1 ms
Maximum slice debt: 3.52 ms
Post-expensive continuations: 0

Warm 3
Worker slice: 5.34 ms
Largest call: UI refresh 2.62 ms
Maximum slice debt: 0.00 ms
Post-expensive continuations: 0
```

Two of three warm runs passed. The second failed both:

```text
worker slice below 8.0 ms
maximum slice debt at or below 2.0 ms
```

The largest support call was itself below 8 ms. The worker crossed 8 ms because the 7.1 ms operation began after earlier work had already consumed part of the slice.

This distinction defines the v1.11.7 architecture.

---

# Root-cause model

## Support eligibility

`Core/Wardrobe/SupportWorker.lua` currently performs final support eligibility through:

```text
GetSourceEligibilityCached(...)
```

That helper creates cached eligibility work but then drains it synchronously with a marker batch of `1,000,000`.

The codebase already provides cooperative primitives:

```text
CreateCachedSourceEligibilityWork(...)
StepCachedSourceEligibilityWork(work, markerBatch)
```

The support worker is not using them.

The cold `supportEligibility 9.3 ms` call is therefore structurally explainable and fixable without changing eligibility semantics.

## Support beam expansion

`Core/Wardrobe/SupportBeam.lua` combines three different operation classes behind one call:

```text
normal candidate expansion
fallback scan
stage finalization and table sort
```

The normal path evaluates one candidate and is naturally bounded.

The fallback path can scan an entire support pool synchronously.

The stage-finalization path can sort and deduplicate a large `nextBeam` in one call.

`Core/Wardrobe/SupportWorker.lua` currently checks only a generic 1.0 ms phase reserve before calling `StepSupportBeamWork()`.

That reserve does not distinguish a cheap candidate step from a potentially 7 ms stage finalization. A stage finalization can therefore begin after earlier work has already consumed 1 to 3 ms, producing an otherwise avoidable 9 ms slice.

## Scheduler behavior

The frozen worker contract already does the correct thing after an expensive call:

```text
Expensive-call threshold: 2.0 ms
forceYield: true
post-expensive continuations: 0
```

The remaining failure happens before the call starts, not after it returns.

v1.11.7 must add operation-aware admission control rather than raising scheduler budgets.

---

# Release identity

v1.11.7 retains the established hybrid identity:

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
```

The support policy remains `LEGACY` because:

- support relevance coefficients do not change;
- support pool ranking does not change;
- beam width and shortlist rules do not change;
- budget and mismatch rules do not change;
- final validation and Phase D repair do not change;
- no Zone-specific support policy is introduced.

v1.11.7 changes execution scheduling only.

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

No migration, cache reset, or report-format bump is required.

---

# Design principles

## 1. Preserve semantic order

Cooperative stepping may change frame boundaries, but it must not change:

- source traversal order;
- eligibility results;
- candidate pool order;
- random-call count or order;
- support pool priority;
- beam expansion order;
- fallback choice;
- selected support configuration;
- chosen shortlist rank;
- Phase D result;
- final outfit.

## 2. Expensive work starts fresh

An operation that is known to have an expensive upper bound must not begin late in a partially consumed slice.

```text
cheap operation:
may begin when normal reserve allows

fresh-slice operation:
must begin before unrelated work consumes the slice
```

## 3. One bounded unit per step

Eligibility marker traversal and fallback scoring must expose resumable work state rather than draining an entire internal list in one call.

## 4. Frozen budgets remain frozen

```text
Preferred slice:          5.5 ms
Soft slice ceiling:       7.5 ms
Expensive-call threshold: 2.0 ms
Phase-transition reserve: 1.0 ms
```

v1.11.7 may not increase these values or suppress warnings to claim success.

## 5. Diagnostics explain the real operation

`supportBeamExpansion` is too broad for closure analysis.

Reports must distinguish:

```text
supportBeamCandidate
supportBeamFallback
supportBeamStageFinalize
```

The existing aggregate may remain for compatibility, but the largest subphase must be visible.

---

# Track A: cooperative support eligibility

## New candidate-work state

Extend each support candidate work item with optional eligibility state:

```text
candidateWork.eligibilityWork
candidateWork.eligibilitySteps
candidateWork.eligibilityCompleted
candidateWork.eligibilityFromCache
```

The candidate remains attached to the current source until eligibility completes or rejects it.

## Use existing cached-work API

When the support candidate reaches final eligibility:

1. create cached eligibility work once;
2. retain the work object on `candidateWork`;
3. step it with a bounded marker batch;
4. return control when incomplete;
5. continue the same candidate on the next scheduler operation;
6. build the support candidate only after eligibility completes successfully.

Preferred implementation contract:

```text
SUPPORT_ELIGIBILITY_MARKER_BATCH = 4
```

This matches the bounded weapon eligibility approach unless an executable fixture proves a smaller batch is required.

## Compatibility fallback

When a style engine lacks the cooperative cached-work API, retain the existing synchronous fallback:

```text
GetSourceEligibilityCached(...)
GetSourceEligibility(...)
```

The current Zone style engine must use the cooperative path.

Traveler, Class Fantasy, and Chronicle Echo behavior must remain unchanged when their adapters do not expose the work API.

## Random parity

`BuildSupportCandidate()` consumes one random value for a retained, fully evaluated source.

Eligibility stepping occurs before `BuildSupportCandidate()`.

Therefore cooperative eligibility must not consume random values and must not reorder candidate completion.

A source cannot advance to the next source until its current eligibility work is complete.

## Eligibility diagnostics

Add compact counters to the generation job:

```text
supportEligibilitySteps
supportEligibilityYields
supportEligibilityCacheCompletions
supportEligibilityComputedCompletions
supportEligibilityMarkerBatch
```

The performance report should print:

```text
Support eligibility: <steps> steps • <yields> yields • batch <n>
Cache completions: <count> • computed completions: <count>
```

These counters are additive and must survive `SUMMARY_TABLES` compaction.

---

# Track B: operation-aware support beam scheduling

## Explicit next-operation identity

Add a read-only helper owned by the support beam module:

```text
DescribeNextSupportBeamOperation(work)
```

It returns one of:

```text
COMPLETE
CANDIDATE
FALLBACK_SCAN
STAGE_FINALIZE
```

The helper must not mutate work or consume random values.

## Candidate expansion

Normal candidate expansion remains one `ScoreSupportCandidate()` call plus one node extension.

Its order and result remain unchanged.

It uses the normal scheduler reserve.

## Cooperative fallback scan

Replace the synchronous full-pool fallback loop with resumable state:

```text
work.fallbackWork = {
    node = <current node>,
    pool = <current pool>,
    candidateIndex = 1,
    bestDecision = nil,
    remainingSlots = <frozen list>
}
```

Each scheduler operation evaluates at most one fallback candidate.

Selection semantics remain:

```text
choose the decision with the lowest mismatchSpent
```

Tie behavior must remain the same as the current first-best traversal:

```text
replace best only when mismatchSpent is strictly lower
```

When the scan completes:

- mark the best decision allowed;
- mark it as fallback and over-budget;
- extend the node once;
- clear fallback work;
- continue beam traversal.

No random values are consumed by fallback scoring.

## Fresh-slice stage finalization

Stage finalization currently performs:

```text
sort nextBeam
retain the first unique signatures up to SUPPORT_BEAM_WIDTH
record deduplication
advance to the next support slot
```

v1.11.7 initially preserves that exact algorithm and comparator.

Before stage finalization begins, the support worker must require a fresh slice.

Suggested helper in `Core/Wardrobe/GenerationScheduling.lua`:

```text
CanStartFreshGenerationPhase(job, maximumPriorElapsedMs)
```

Contract:

```text
maximumPriorElapsedMs = 0.25 ms
current slice forceYield = false
current slice operationCount = 0
elapsed time <= maximumPriorElapsedMs
```

When those conditions are not met, the worker returns `RUNNING` without mutating beam state.

The next scheduled frame begins the stage-finalization call near the start of a new slice.

After finalization:

- record `supportBeamStageFinalize`;
- allow the existing expensive-call detector to set `forceYield` when appropriate;
- return control before unrelated work continues.

This does not increase the scheduler budget. It only prevents a known expensive operation from borrowing time already spent by previous operations.

## Stage-finalization contingency

The fresh-slice gate is the preferred minimal repair because the Retail call itself was 7.1 ms, below the 8 ms closure limit.

Before packaging, run a synthetic worst-case beam fixture using:

```text
SUPPORT_BEAM_WIDTH = 24
SUPPORT_POOL_LIMIT = 32
maximum practical nextBeam size for all active support slots
```

If `supportBeamStageFinalize` still reaches or exceeds 7.5 ms from a fresh slice, the build must not ship with only the fresh-slice gate.

In that case, implement cooperative finalization with these invariants:

1. scan `nextBeam` incrementally;
2. preserve original insertion ordinal;
3. retain the highest-scoring node per signature;
4. maintain the top 24 unique signatures with the same score ordering;
5. use insertion ordinal only to make exact-score ties deterministic;
6. prove selected finalists and random behavior match all non-tie fixtures;
7. freeze tie fixtures to the new deterministic contract.

This contingency is allowed only when the uninterruptible sort cannot meet the soft ceiling from a fresh slice.

## Beam diagnostics

Add compact counters:

```text
supportBeamCandidateSteps
supportBeamFallbackSteps
supportBeamFallbackYields
supportBeamStageFinalizations
supportBeamFreshSliceDeferrals
supportBeamStageFinalizeMaxMs
```

The report should distinguish the largest support operation rather than reporting all of them as `supportBeamExpansion`.

---

# Track C: scheduler admission control

## Fresh-phase helper

The fresh-phase helper is intentionally narrower than the global scheduler.

It must not change:

- preferred slice duration;
- soft ceiling;
- expensive-call threshold;
- phase-transition reserve;
- existing anchor or weapon scheduling.

It is used only when an operation advertises `STAGE_FINALIZE` or another explicitly approved fresh-slice class.

## No busy waiting

When a fresh phase cannot start, the worker must return `RUNNING` immediately.

It must not loop until elapsed time resets and must not perform unrelated support work first.

## Post-expensive integrity

After any support call at or above 2.0 ms:

```text
forceYield = true
postExpensiveCallContinuations = 0
```

The existing worker diagnostics remain authoritative.

## Slice-debt rule

The goal is not zero debt for every expensive call.

The closure requirement remains:

```text
warm maximum slice debt <= 2.0 ms
```

A 7.1 ms stage finalization beginning near 0 ms produces about 1.6 ms debt against the 5.5 ms preferred slice, which is acceptable.

The same call beginning after 1.9 ms produces about 3.5 ms debt, which is not acceptable.

---

# Diagnostics and export

## Report fields

Add a compact support-scheduling summary under Performance or Cache and Metadata:

```text
Support eligibility: <steps> steps • <yields> yields • batch <n>
Support beam: <candidate steps> candidate • <fallback steps> fallback
Stage finalizations: <count> • fresh-slice deferrals <count>
Largest support subphase: <phase> <ms>
```

## Zone debug export

Zone debug export remains format 4.

The `Zone Anchor Policy Performance` section may add optional lines:

```text
Support eligibility steps: <count> • yields: <count>
Support stage finalizations: <count>
Support fresh-slice deferrals: <count>
Largest support subphase: <phase> <ms>
```

Older reports render unavailable fields as `Not recorded`.

No lineage selector changes are permitted.

## Adaptive compaction

The new counters are mandatory closure diagnostics but are scalar values.

They must survive:

```text
SUMMARY_TABLES
MANDATORY_CORE
EMERGENCY_STUB
```

They must not materially increase report size.

The report ceiling remains 20,480 bytes.

---

# Compatibility and parity contract

## Support algorithm constants remain frozen

```text
SUPPORT_POOL_LIMIT = 32
SUPPORT_BEAM_WIDTH = 24
SUPPORT_FINAL_SHORTLIST = 6
SUPPORT_FINAL_SCORE_WINDOW = 20
```

No support coefficient, tolerance, prominence, mismatch, bridge, repeat, or outlier value may change.

## Candidate parity

For identical input state and random seed, v1.11.7 must preserve:

- validated source set;
- eligibility result per source;
- source traversal order;
- candidate random draw count and order;
- pool membership;
- pool priority values;
- beam expansion order;
- budget decisions;
- fallback winner;
- finalist ordering;
- chosen rank;
- final support selections;
- Phase D status and repairs.

## Mode parity

Traveler remains exact.

Class Fantasy and Chronicle Echo remain on their existing legacy adapters.

Zone anchor scoring and policy authority remain unchanged.

The new support eligibility work path may be shared by modes only when it preserves their existing source order and results.

## Atomicity

No partial support selection may commit while:

- eligibility work is incomplete;
- fallback work is incomplete;
- beam stage finalization is deferred;
- the Zone snapshot is stale;
- the weapon capability snapshot is stale.

The previous preview remains intact until the full action commits.

---

# Proposed runtime module changes

Expected existing modules:

```text
Core/Wardrobe/SupportWorker.lua
Core/Wardrobe/SupportBeam.lua
Core/Wardrobe/GenerationScheduling.lua
Core/Wardrobe/GenerationPerformance.lua
Core/Diagnostics/SnapshotBuilder.lua
Core/Diagnostics/ReportFormatter.lua
Core/Diagnostics/ReportCompaction.lua
Core/Diagnostics/ReportEmergencyStub.lua
Core/ZoneStyle/Zone/DebugExport.lua
Core/Version.lua or equivalent version metadata
QuestChronicle.toc
```

A small new module is preferred if required to keep files below 500 lines:

```text
Core/Wardrobe/SupportScheduling.lua
```

Suggested ownership:

```text
SupportScheduling.lua
fresh-slice admission
support operation counters
support eligibility marker-batch constant
support scheduling diagnostics helpers
```

`SupportBeam.lua` should remain responsible for beam semantics and resumable beam state.

`SupportWorker.lua` should remain responsible for orchestration.

No generation-facing file may reach 500 lines.

---

# Implementation sequence

## Phase 0: freeze v1.11.6

1. verify the v1.11.6 SHA-256;
2. extract to a clean worktree;
3. run all inherited Lua tests;
4. run all static verifiers;
5. record runtime module count and TOC order;
6. save exact support-selection fixtures and random traces.

## Phase 1: diagnostics-only decomposition

Before changing scheduling behavior:

1. split support timing labels into candidate, fallback, and stage-finalize subphases;
2. add operation identity reporting;
3. confirm selection and random parity remain exact;
4. reproduce the 7.1 ms class in a synthetic beam fixture.

This phase must not alter call boundaries yet.

## Phase 2: cooperative support eligibility

1. add retained cached eligibility work to support candidates;
2. step with marker batch 4;
3. preserve source completion order;
4. add eligibility counters;
5. prove cold eligibility calls are bounded;
6. prove support selections and random traces remain exact.

## Phase 3: cooperative fallback scanning

1. add resumable fallback work;
2. score one fallback candidate per operation;
3. preserve strict-lower mismatch replacement;
4. preserve selected fallback and diagnostics;
5. verify no new random calls.

## Phase 4: fresh-slice stage finalization

1. add fresh-phase scheduler admission;
2. defer stage finalization when the current slice is already used;
3. run stage finalization from a fresh slice;
4. force yield after expensive finalization;
5. record deferrals and maximum finalization time;
6. run worst-case fixture.

## Phase 5: contingency finalization

Only when the fresh-slice fixture still reaches 7.5 ms or more:

1. implement cooperative top-24 unique selection;
2. preserve score semantics and insertion ordinal;
3. add tie-specific fixtures;
4. document the deterministic tie clarification;
5. repeat all parity tests.

## Phase 6: report and export integration

1. add scalar support-scheduling counters;
2. preserve them through adaptive compaction;
3. render older reports as `Not recorded`;
4. keep export format 4;
5. verify independent report lineage remains unchanged.

## Phase 7: exact-package validation

1. update version metadata to `1.11.7`;
2. update README and release notes;
3. run complete inherited and new tests;
4. parse every runtime Lua file;
5. verify each TOC entry appears exactly once;
6. verify no runtime Lua file reaches 500 lines;
7. build the ZIP;
8. extract the exact ZIP into a fresh directory;
9. rerun every gate from that extraction;
10. calculate and publish SHA-256.

---

# Automated validation

## Support eligibility parity fixture

Construct sources covering:

- immediate in-memory cache hit;
- persistent cache hit;
- computed eligibility with one marker;
- computed eligibility with multiple markers;
- rejected source;
- pending or unknown evidence;
- source requiring era evidence work.

Run the v1.11.6 synchronous path and the v1.11.7 cooperative path with the same context.

Require identical:

- eligibility result;
- kind and reason;
- persistent cache entry;
- source traversal completion order;
- retained pool;
- random trace;
- final support selection.

## Marker-batch fixture

Use eligibility work larger than one batch.

Require:

```text
marker batch = 4
multiple steps recorded
at least one scheduler yield possible
no source-order change
no duplicate cache write
```

## Fallback parity fixture

Create a pool where no normal candidate is allowed and several candidates have different mismatch costs.

Require:

- the same lowest-mismatch fallback as v1.11.6;
- first candidate wins an exact mismatch tie;
- one candidate scored per fallback step;
- no random calls;
- identical committed fallback decision.

## Stage-finalization admission fixture

Simulate a slice that already consumed 1.8 ms before the next operation becomes `STAGE_FINALIZE`.

Require:

- stage finalization does not start;
- worker returns `RUNNING`;
- beam state remains unchanged;
- fresh-slice deferral increments once;
- finalization starts on the next empty slice;
- post-expensive continuations remain zero.

## Worst-case beam fixture

Build a maximum practical `nextBeam` under the frozen 24 by 32 support limits.

Require from a fresh slice:

```text
supportBeamStageFinalize < 7.5 ms
```

If this fails, activate the cooperative-finalization contingency before packaging.

## Full support parity fixture

Use a fixed wardrobe, locks, hidden slots, Zone context, and random seed.

Compare v1.11.6 and v1.11.7:

- pool sizes;
- candidate identities and priorities;
- expansion counts;
- retained counts;
- budget rejections;
- fallback count;
- shortlist identities and scores;
- chosen rank;
- final support appearances;
- whole-outfit cohesion;
- mismatch spend;
- Phase D result;
- random trace.

Everything must match.

## Scheduler integrity fixture

Require:

```text
Preferred slice: 5.5 ms
Soft ceiling: 7.5 ms
Expensive threshold: 2.0 ms
Post-expensive continuations: 0
Fresh-stage deferrals: recorded
No busy waiting
```

## Diagnostic compaction fixture

Create a realistic v1.11.7 Zone report above 34 KB.

Require:

- it persists below 20,480 bytes;
- support-scheduling closure counters survive;
- Zone policy and selected anchors survive;
- no emergency stub for the realistic fixture;
- exact final serialized size is recorded.

## Export regression fixture

Create history where the newest Zone report is a legacy individual reroll and the newest policy-bearing report is a warm Reroll Unlocked action.

Require:

- latest Zone report remains the individual reroll;
- policy section uses the warm policy-bearing report;
- support scheduling fields come from that same policy report;
- no live-state and historical-report blending;
- export format remains 4.

## Mode regression fixture

Require:

```text
Traveler generation unchanged
Class Fantasy generation unchanged
Chronicle Echo generation unchanged
Zone anchor selections unchanged for fixed seeds
Support selections unchanged for fixed seeds
```

---

# Retail live validation

## Test 1: cold Zone Generate Outfit

After installing v1.11.7 and `/reload`:

1. wait for the wardrobe refresh to settle;
2. select Zone Native;
3. generate one outfit;
4. confirm a new Debug report persists;
5. confirm `ZONE_ANCHOR_POLICY_V1 • ACTIVE`;
6. confirm adaptive persistence remains below 20,480 bytes;
7. record support eligibility and beam subphase diagnostics.

Cold acceptance gate:

- longest worker slice below 16.0 ms;
- largest instrumented call below 16.0 ms;
- `supportEligibility` no longer appears as one opaque synchronous 9 ms drain;
- cooperative support eligibility records bounded steps;
- no post-expensive continuation;
- no report rejection.

Preferred cold quality target:

```text
largest support eligibility step below 8.0 ms
```

A cold run above 16 ms blocks release closure.

## Test 2: three consecutive warm Reroll Unlocked actions

Run three rerolls without equipment, specialization, collection, mode, or location changes.

Every report must show:

```text
Weapon capabilities: REUSED
Capability stale at commit: NO
Zone context stale at commit: NO
Post-expensive continuations: 0
```

Warm acceptance gate for all three runs:

- longest worker slice below 8.0 ms;
- largest instrumented call below 8.0 ms;
- maximum slice debt at or below 2.0 ms;
- no worker-slice warning;
- no severe-worker-slice warning;
- no instrumented-call warning;
- no severe-instrumented-call warning;
- no diagnostic persistence rejection.

One passing sample is insufficient. All three must pass.

## Test 3: support-stage evidence

At least one report in the batch must record one of:

```text
support stage finalization
fresh-slice stage deferral
cooperative fallback step
```

When a stage deferral occurs, confirm:

- stage finalization begins on the next slice;
- the resulting selected outfit remains valid;
- no duplicate or skipped support slot appears.

## Test 4: capability carry-forward

Change equipped weapon or specialization once.

Require:

- next action rebuilds capability state at most once;
- following unchanged action reuses it;
- legal route remains correct;
- support scheduling remains under the warm gate after reuse.

## Test 5: format-4 export

Run:

```text
/qc zone debug export
```

Confirm:

- export format is 4;
- policy lineage remains correct;
- latest Zone report remains correct;
- support eligibility steps and stage diagnostics are present when recorded;
- older unavailable fields are not rendered as zero;
- `DIAGNOSTIC_ESCAPE_V1` remains intact.

## Test 6: individual reroll non-regression

Run one contextual support-slot reroll and one legacy individual anchor reroll.

Require:

- both reports persist;
- contextual reroll behavior remains unchanged;
- the legacy anchor reroll remains explicitly legacy;
- the known synchronous individual anchor-reroll debt is not mistaken for v1.11.7 support-generation closure.

---

# Acceptance criteria

v1.11.7 is package-ready when:

1. support final eligibility uses bounded cached eligibility work;
2. support eligibility preserves exact results and random order;
3. fallback scans are resumable and preserve the same winner;
4. support beam operations identify candidate, fallback, and stage-finalize work;
5. stage finalization cannot begin late in an already-used slice;
6. stage finalization forces a yield when expensive;
7. the worst-case fresh-slice stage finalization remains below 7.5 ms, or cooperative finalization is implemented;
8. support scores, pools, beam results, budgets, and Phase D are parity-safe;
9. scheduler constants remain unchanged;
10. post-expensive continuations remain zero;
11. adaptive persistence and format-4 lineage remain intact;
12. all inherited and new tests pass;
13. all static verifiers pass;
14. every runtime Lua file parses;
15. every TOC module appears exactly once;
16. no runtime Lua file reaches 500 lines;
17. the exact ZIP passes fresh-extraction validation.

v1.11.7 is live-validated only when:

1. one cold Generate Outfit remains below 16 ms;
2. three consecutive warm Reroll Unlocked actions each remain below 8 ms;
3. all three warm largest calls remain below 8 ms;
4. all three warm maximum slice debts remain at or below 2 ms;
5. post-expensive continuations remain zero;
6. all reports persist below the existing ceiling;
7. format-4 policy lineage remains correct;
8. legal weapon routes and capability lifecycle remain correct;
9. fixed-seed support-selection parity is confirmed.

Only then is the `ZONE_ANCHOR_POLICY_V1` implementation slice considered closed.

---

# Explicit non-goals

v1.11.7 does not:

- change Zone anchor-policy coefficients;
- change Zone affinity scoring;
- introduce a Zone support policy;
- change support relevance, profile-fit, neighbor, bridge, budget, repeat, or outlier coefficients;
- change support pool limits, beam width, shortlist size, or score window;
- change source eligibility rules;
- change era or provenance restrictions;
- change random-call count or order;
- change weapon style ordering or legal routes;
- change final validation or Phase D repair;
- modernize individual anchor or weapon rerolls;
- repair the known synchronous individual anchor-reroll spike;
- raise scheduler budgets;
- raise the report persistence ceiling;
- change SavedVariables, cache, Courier, diagnostic, or export formats;
- begin the first Zone-native contextual-support policy slice.

---

# Expected release result

When v1.11.7 passes Retail:

```text
Zone foundation: validated
Zone anchor policy: authoritative and performance-closed
Diagnostic persistence: validated
Policy lineage export: validated
Weapon eligibility and capabilities: cooperatively validated
Legacy contextual-support execution: cooperatively scheduled
Zone support policy: still LEGACY and ready for the next design slice
```

The likely next release in the v1.11.x train may then begin the first actual Zone contextual-support policy slice, rather than spending another release chasing scheduler debt inherited from the legacy support engine.
