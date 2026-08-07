# Quest Chronicle v1.11.10 Architecture & Development Plan

## Productive cooperative scheduling and end-to-end latency closure

## Release purpose

Quest Chronicle v1.11.10 is the corrective performance release that follows the successful v1.11.9 watchdog-boundary repair.

v1.11.9 proved that the catastrophic v1.11.8 deadlock is gone. Cooperative era work now returns control correctly, the synchronous era path has forward-progress protection, and the new integrity counters remained clean in Retail:

```text
same-slice DEFERRED retries:       0
synchronous progress-guard trips: 0
post-expensive continuations:      0
```

The remaining Retail problem is no longer safety. It is scheduling efficiency.

Observed v1.11.9 Retail results:

```text
Cold Generate Outfit
1,686 frames • 24.2 sec
worker slice 6.7 ms
era fresh-slice deferrals 1,277
deferred returns 1,280

Warm Reroll Unlocked #1
1,389 frames • 19.9 sec
worker slice 5.4 ms
era operations 0
era fresh-slice deferrals 1,117
deferred returns 1,117

Warm Reroll Unlocked #2
533 frames • 7.7 sec
worker slice 12.2 ms
largest call supportBeamCandidate 9.1 ms
maximum slice debt 6.72 ms

Warm Reroll Unlocked #3
230 frames • 3.3 sec
worker slice 5.7 ms
```

The cold and first warm runs show a severe frame-tax problem: work is yielding safely but far too often. The second warm run separately proves that one contextual-support candidate can still execute too much work in one operation.

v1.11.10 therefore has two equal goals:

```text
1. Keep the v1.11.9 watchdog-safe execution boundary while eliminating
   unnecessary era deferrals and one-frame-per-API-call behavior.

2. Make contextual-support candidate scoring resumable so no individual
   support candidate can produce another isolated 8+ ms call.
```

This is the first release in the performance train with an explicit end-to-end latency gate in addition to per-slice timing gates.

---

# Baseline and release authority

## Implementation baseline

Build v1.11.10 directly from the exact v1.11.9 package:

```text
QuestChronicle-v1.11.9.zip
SHA-256:
b806ef200da6b03272ccd5b2a013e9838a66c59344a409434211d08410d0fbbe
```

v1.11.9 is the required baseline because it contains the corrected execution-mode boundary:

```text
GENERATION_COOPERATIVE
SUPPORT_REROLL_COOPERATIVE
BACKGROUND_TICK
SYNCHRONOUS
```

and the production invariants:

```text
same-slice DEFERRED retry = forbidden
synchronous no-progress spin = forbidden
cooperative caller owns nested era work
background admission is isolated from foreground generation
```

## Retail safety status

v1.11.9 is watchdog-safe in Retail but is not accepted as the final Zone performance baseline because of end-to-end latency and one warm support-candidate spike.

v1.11.7 remains the useful latency reference for the same generation family:

```text
Cold: 6.7 sec
Warm samples: 4.0 sec, 3.8 sec, 3.1 sec
```

v1.11.10 must retain v1.11.9 safety while returning toward that latency envelope.

---

# Architecture identity remains frozen

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
Zone debug export format: 4
Zone affinity format: 2
Diagnostic report format: 1
Persistence ceiling: 20,480 bytes
Preferred worker budget: 5.5 ms
Soft worker limit: 7.5 ms
Expensive-call force-yield threshold: 2.0 ms
```

v1.11.10 is a scheduling release only. It does not begin the Zone-native support-policy rewrite.

---

# Confirmed root cause A: fresh-frame tax in era evidence

## Current v1.11.9 admission contract

`Core/ZoneStyle/EraCandidateWork.lua` currently describes these stages as requiring a fresh slice:

```text
SET_LIST
TRACKING
ENCOUNTER_LIST
ITEM_METADATA
```

`Core/ZoneStyle/EraEvidence.lua` asks `AdmitEraEvidenceOperation()` before it executes the stage.

For cooperative foreground work, `CanStartFreshGenerationPhase()` rejects admission whenever the current slice has already performed any operation.

That means a fresh-sensitive era stage usually costs at least one scheduler return before the stage itself executes.

## Why this is now too conservative

The v1.11.8 monolithic era resolver was dangerous because several evidence sources were bundled into one call. v1.11.9 has already decomposed that work.

Retail v1.11.9 measured the largest individual era subphase at only:

```text
Era tracking evidence: 2.12 ms
```

The architecture is therefore still applying a fresh-slice rule designed for a monolithic 8+ ms operation to new 0-2 ms suboperations.

## Phantom deferrals

The strongest evidence is Warm Reroll #1:

```text
era operations: 0
era API work: 0
era fresh-slice deferrals: 1,117
deferred returns: 1,117
```

A scheduler deferral that occurs when the action ultimately performs no era operation is not productive work protection. It is admission overhead.

v1.11.10 must make this state impossible.

---

# Confirmed root cause B: support candidate remains monolithic

`Core/Wardrobe/SupportBeam.lua` currently processes one candidate with one call to:

```text
ScoreSupportCandidate(candidate, node, job, profile, remainingSlots, locked)
```

That call performs, in order:

```text
NeighborScore
BridgeScore
EvaluateSupportBudget
Final score construction
Decision-table construction
ExtendNode when allowed
```

`NeighborScore` and `BridgeScore` themselves walk multiple relationships and repeatedly resolve descriptors and pair cohesion.

v1.11.7 successfully made support eligibility, fallback scanning, and beam-stage finalization cooperative, but one candidate score is still an indivisible unit.

Retail v1.11.9 captured:

```text
supportBeamCandidate: 9.11 ms
worker slice: 12.2 ms
maximum slice debt: 6.72 ms
```

The stage finalizer remained healthy at roughly 1.1 ms. The remaining support problem is specifically candidate scoring granularity.

---

# Release invariants

## Invariant A: watchdog safety cannot regress

The following remain absolute gates:

```text
same-slice DEFERRED retries = 0
synchronous progress-guard trips = 0
post-expensive continuations = 0
script ran too long = never
```

A latency optimization may not weaken the v1.11.9 execution boundary.

## Invariant B: every era deferral must protect real pending work

A cooperative era deferral is legal only when all of these are true:

```text
an actual variable API stage is pending
that API stage cannot safely start with current slice headroom
the work object remains unchanged by the denied admission
the caller immediately returns to its scheduler
```

No local-only stage, fragment-cache hit, already-resolved source cache, unavailable API branch, or stable tracked-origin cache hit may request a new frame.

## Invariant C: no one-frame-per-API policy

A variable API call no longer automatically requires an otherwise empty worker slice.

Admission is based on available headroom and call class, not `operationCount == 0`.

Several inexpensive era API operations may run in the same worker slice when the slice still has sufficient reserved headroom.

## Invariant D: support score semantics are immutable

Splitting support candidate scoring must preserve:

```text
neighbor traversal order
bridge-target traversal order
floating-point accumulation order
budget evaluation inputs
allowed/rejected result
score value
bridge result and labels
mismatch cost
node extension order
beam expansion order
fallback first-best tie behavior
random-call count and order
```

`ScoreSupportCandidate()` remains the semantic reference oracle.

## Invariant E: total latency is now part of correctness

A build that meets the 8 ms frame budget by spreading ordinary work across thousands of unnecessary frames is not accepted.

---

# Track A: demand-aware era admission

## A1. Replace the boolean `fresh` descriptor with an admission class

The current descriptor:

```lua
operation, fresh
```

should become an explicit operation contract, conceptually:

```lua
{
    operation = "TRACKING",
    admission = "API_HEADROOM",
    reserveMs = 3.0,
    willInvokeAPI = true,
}
```

Recommended admission classes:

```text
LOCAL
API_HEADROOM
FRESH_ONLY
COMPLETE
```

`FRESH_ONLY` remains available as a safety valve for a future operation empirically shown to require it, but v1.11.10 should not classify the current decomposed era calls as fresh-only by default.

## A2. Probe before admission

The candidate worker must perform cheap, non-mutating readiness checks before scheduler admission.

Examples:

### SET_LIST

```text
C_TransmogSets missing/unavailable
→ LOCAL transition to TRACKING
→ no scheduler deferral

API available and source ID valid
→ API_HEADROOM
```

### TRACKING

```text
trackedOriginCache[sourceID] already has stable result
→ LOCAL

tracking API unavailable
→ LOCAL

uncached origin requires GetBestMapForTrackable
→ API_HEADROOM
```

### ENCOUNTER_LIST

```text
GetAppearanceSourceDrops unavailable
→ LOCAL transition

call required
→ API_HEADROOM
```

### ITEM_METADATA

```text
no item ID
→ LOCAL

item getter unavailable
→ LOCAL

metadata call required
→ API_HEADROOM
```

The probe may inspect state and API availability but must not invoke the variable Blizzard API itself.

## A3. Headroom admission instead of empty-slice admission

Add an era-specific cooperative admission path that uses the existing slice budget rather than requiring `operationCount == 0`.

Conceptually:

```text
CanStartEraAPIOperation(job, reserveMs)
```

The call should be admitted when the current slice has enough budget to accommodate the operation plus reserve.

Initial reserve:

```text
3.0 ms
```

Rationale:

```text
Retail largest decomposed era subphase: 2.12 ms
Reserve margin above that observation: ~0.88 ms
Preferred worker budget remains: 5.5 ms
Soft limit remains: 7.5 ms
```

This constant is scheduling headroom only. It is not permission to raise the worker budget.

## A4. Preserve force-yield after an actually expensive API call

The existing 2.0 ms expensive-call mechanism remains authoritative.

If an admitted era API call itself crosses the expensive-call threshold, the slice becomes force-yielded and no further work continues in that slice.

This gives the scheduler adaptive behavior:

```text
cheap API call
→ another operation may still fit

expensive API call
→ current slice ends immediately
```

## A5. Deferral must be edge-triggered, not frame-triggered

When an API operation is denied for insufficient headroom:

```text
record one deferral
mark forceYield
return to scheduler
```

On the next slice it should either execute or reveal that the stage no longer requires an API call.

Same-slice retries remain forbidden.

## A6. Do not charge fresh admission for completed source-level era cache hits

`CreateSourceEraEvidenceWork()` already returns a completed work item when `ReadCachedEvidence(source)` succeeds.

Tests must prove that a completed source-level era cache path reaches eligibility without:

```text
candidate-work allocation
API admission
deferred return
fragment work
```

## A7. Fragment-cache hits must complete locally

A candidate fragment hit is discovered in `BUILD` before the variable API stages.

Tests must prove:

```text
BUILD
→ fragment hit
→ candidate complete
```

with zero API admission and zero deferral.

---

# Track B: productive-deferral diagnostics

v1.11.10 must make the scheduler tax visible instead of reporting only aggregate deferrals.

Add headline counters:

```text
era local operations
era API operations
era API admissions
era API headroom deferrals
era fresh-only deferrals
era phantom deferrals
era source-cache completions
era fragment-cache completions
```

Define `phantom deferral` narrowly:

```text
A deferral recorded for an operation that resolves without invoking the
API boundary it claimed to protect before any intervening invalidation.
```

Expected production value:

```text
0
```

Retain existing counters:

```text
deferred returns
same-slice deferred retries
synchronous guard trips
operations
siblings
fragment hits/builds
API call counts
largest era subphase
```

## Deferral efficiency line

Debug History and Zone export should include a compact line such as:

```text
Era admission: 151 API calls • 28 headroom deferrals • 0 phantom • 0 fresh-only
```

Do not bump Zone export format unless the schema parser requires it. Prefer additive format-4 fields.

---

# Track C: resumable contextual-support candidate scoring

## C1. Add `SupportCandidateWork`

Create a dedicated state object for one beam candidate.

Recommended new module:

```text
Core/Wardrobe/SupportCandidateWork.lua
```

Recommended stages:

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

The exact names may be simplified during implementation, but each operation must be bounded.

## C2. Preserve the reference function

Keep `P.ScoreSupportCandidate()` unchanged as the synchronous semantic oracle for:

```text
unit parity tests
legacy/non-beam callers
small synchronous paths outside this release scope
```

The new worker must produce a decision table equivalent to the oracle.

## C3. One relationship operation at a time

The cooperative worker should process no more than one neighbor or bridge relationship per step.

A relationship step may perform:

```text
resolve one target source/descriptor
compute one pair-cohesion value
accumulate it
advance index
```

It may not scan all neighbors or bridge targets in one step.

## C4. Descriptor reuse within candidate work

The worker should memoize descriptors it resolves while scoring a candidate.

It must not create a persistent descriptor format or change Traveler's descriptor cache semantics.

This is only per-candidate/per-node reuse to avoid repeated lookups within the same decision.

## C5. Budget and final arithmetic remain atomic

`EvaluateSupportBudget()` and the final scalar score calculation are currently small and deterministic.

They may remain atomic unless a synthetic test demonstrates otherwise.

Expected target:

```text
budget/final score subphase < 2 ms
```

## C6. Node extension remains after decision completion

`ExtendNode()` executes only after the decision has fully completed.

A partially scored candidate must never mutate:

```text
nextBeam
beam expansion counters
budget state
selected source maps
decision arrays
```

This is essential for yield-safe parity.

## C7. Integrate the worker into normal candidate and fallback paths

`SupportBeamWork` should carry a nested `candidateWork`.

For normal candidates:

```text
create work
step until complete across scheduler operations
commit allowed decision or rejection
advance candidate index
```

For fallback scanning:

```text
create work for one fallback candidate
step cooperatively
compare completed mismatch against current best
preserve strict-lower first-best tie rule
advance fallback candidate index
```

The fallback path must not regain a monolithic `ScoreSupportCandidate()` call.

## C8. Scheduler admission for support substeps

Candidate substeps should use ordinary generation headroom admission.

Do not require every pair relationship to begin on a fresh slice.

Recommended reserve:

```text
1.0 ms ordinary substep admission
```

If a relationship operation itself exceeds the 2.0 ms expensive threshold, existing force-yield behavior ends the slice.

---

# Track D: support candidate diagnostics

Replace the single opaque support-candidate timing with subphase visibility while keeping compatibility totals.

Add timing/counter keys such as:

```text
supportCandidateNeighbor
supportCandidateBridge
supportCandidateBudget
supportCandidateFinalize
supportCandidateDeferrals
supportCandidateCompletions
```

Retain:

```text
supportBeamCandidate
supportBeamExpansion
```

as compatibility aggregates.

Debug output should identify:

```text
Largest support subphase
Largest support candidate subphase
Candidate scoring deferrals
Candidate scoring completions
```

Adaptive compaction must retain only headline values, not per-candidate trace arrays.

---

# Track E: end-to-end latency accounting

## E1. Separate scheduler safety from scheduler efficiency

Diagnostics should report both:

```text
worker-slice safety
end-to-end action latency
```

Existing `Prepared: frames • seconds` remains the user-facing measure.

Add a compact scheduling-efficiency summary:

```text
productive operations
deferred returns
deferral-to-operation ratio
API headroom deferrals
support candidate substeps
```

## E2. No frame-count optimization that changes semantic ordering

v1.11.10 may reduce yields and combine safe operations into one slice, but it may not:

```text
parallelize candidate evaluation
reorder candidate traversal
precompute random-bearing work out of order
change cache commit ordering when externally observable
```

---

# Track F: test plan

## F1. Reproduce the v1.11.9 frame-tax case

Construct a cooperative eligibility fixture where era evidence requires many candidates but the final action performs no variable API work because stable caches satisfy every candidate.

v1.11.9 reference expectation:

```text
large deferral count despite 0 API calls
```

v1.11.10 required result:

```text
API calls: 0
API headroom deferrals: 0
fresh-only deferrals: 0
phantom deferrals: 0
same-slice retries: 0
```

## F2. Real API-stage headroom fixture

Simulate inexpensive variable API calls with deterministic fake clock costs.

Prove that several calls can execute in one worker slice while total elapsed time remains inside the scheduling budget.

## F3. Expensive API-call fixture

Simulate one era API call above 2.0 ms.

Required behavior:

```text
call executes once
slice becomes force-yielded
no subsequent era operation runs in that slice
post-expensive continuation count remains 0
```

## F4. Admission denial immutability

When headroom admission denies an era API call, verify no mutation to:

```text
candidate stage
set/drop/tier indexes
best evidence
pending state
cache state
progress serial
```

except deferral diagnostics.

## F5. Source-cache and fragment-cache no-tax fixtures

Prove completed cache hits generate no API admission and no scheduler deferral.

## F6. Support candidate oracle parity

Build representative nodes/candidates for every support slot and compare:

```text
ScoreSupportCandidate()
vs
SupportCandidateWork completion
```

Exact parity fields:

```text
allowed
score
role
profileFit
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
budgetEvaluation
```

Use numeric tolerance only where Lua floating representation requires it; traversal and accumulation order should normally permit exact equality.

## F7. Support yield-point parity

Force a yield after every possible candidate-work stage and prove the final decision is identical to uninterrupted execution.

## F8. Fallback tie parity

Two fallback candidates with identical mismatch must continue to select the first candidate.

## F9. Candidate no-partial-commit fixture

Yield during neighbor and bridge work and verify `nextBeam` is unchanged until `COMPLETE`.

## F10. Synthetic support worst case

Construct a maximum-width beam with candidate relationships designed to exercise every neighbor and bridge path.

Required automated target:

```text
largest candidate subphase < 4.0 ms
```

No single synthetic candidate operation may exceed 7.5 ms.

## F11. Watchdog regression wall

Retain every v1.11.9 execution-boundary fixture:

```text
used-slice DEFERRED returns to scheduler
same-slice retries remain zero
synchronous no-progress sabotage trips guard
300-set synchronous stress completes
background/foreground admission isolation
```

## F12. Existing complete suite

All inherited tests remain mandatory:

```text
era tuple parity
eligibility parity
weapon ordering parity
support selection parity
random consumption parity
Zone policy parity
adaptive persistence
format-4 lineage
capability invalidation
locks and hidden slots
Phase D repair
runtime syntax
TOC uniqueness
<500-line runtime files
```

---

# Track G: Retail validation contract

## G1. Cold Generate Outfit

After `/reload`, generate one Zone Native outfit.

Hard requirements:

```text
Result: Completed
No Lua error
No script ran too long
No diagnostic rejection
Longest worker slice < 16.0 ms
Largest era subphase < 4.0 ms
Same-slice deferred retries = 0
Synchronous guard trips = 0
Post-expensive continuations = 0
Phantom era deferrals = 0
Total preparation time <= 10.0 sec
```

Preferred cold target:

```text
<= 8.0 sec
```

## G2. Three consecutive warm Reroll Unlocked actions

Without reloading or changing zones, run three consecutive rerolls.

Every run must satisfy:

```text
Longest worker slice < 8.0 ms
Largest instrumented call < 8.0 ms
Maximum slice debt <= 2.0 ms
Post-expensive continuations = 0
Same-slice deferred retries = 0
Synchronous guard trips = 0
Phantom era deferrals = 0
No performance warning
No diagnostic rejection
Total preparation time <= 6.0 sec
```

Preferred warm target:

```text
<= 5.0 sec each
```

## G3. Zero-era-work warm action rule

If a warm action reports:

```text
Era API work: 0
```

then it must also report:

```text
Era API headroom deferrals: 0
Era fresh-only deferrals: 0
Era phantom deferrals: 0
```

This is a hard correctness gate, not a performance preference.

## G4. Support candidate closure

Across the three warm runs:

```text
Largest support candidate subphase < 4.0 ms preferred
No support candidate aggregate call >= 8.0 ms
No support-caused performance warning
```

## G5. Zone debug export

Run:

```text
/qc zone debug export
```

Confirm:

```text
format 4
latest Zone report lineage correct
latest policy-bearing lineage correct
ZONE_ANCHOR_POLICY_V1 ACTIVE
era execution boundary counters retained
productive-deferral counters retained
support candidate scheduling counters retained
adaptive persistence under 20,480 bytes
```

## G6. Contextual support-slot reroll

Run one modern contextual support-slot reroll.

Confirm:

```text
report persists
anchor ancestry reused
profile ancestry reused
no watchdog warning
no same-slice retry
no support scoring regression
```

---

# Acceptance matrix

v1.11.10 may be accepted only if all rows pass:

| Area | Requirement |
|---|---|
| Watchdog safety | No script watchdog, no same-slice DEFERRED retries, no sync guard trips |
| Era semantics | Exact evidence/eligibility parity |
| Era admission | Zero phantom deferrals; no deferrals on zero-API warm actions |
| Era call timing | Largest era subphase <4 ms target; no 8 ms call |
| Support semantics | Exact candidate and beam-selection parity |
| Support granularity | No support candidate operation >=8 ms |
| Cold slice | <16 ms |
| Warm slices | Three consecutive runs <8 ms |
| Warm debt | <=2 ms each |
| Cold latency | <=10 sec |
| Warm latency | <=6 sec each |
| Diagnostics | Retained, correctly compacted, format-4 lineage intact |
| Files | Runtime Lua <500 lines, TOC exact, syntax clean |

Any failed hard row blocks the Zone performance closure.

---

# Explicit non-goals

v1.11.10 will not:

- rewrite the Zone contextual-support policy;
- change `ZONE_ANCHOR_POLICY_V1` coefficients;
- modernize the synchronous legacy individual anchor/weapon reroll;
- change evidence ranks, Era Evidence v2, or manifest formats;
- change wardrobe persistent cache formats;
- change support beam width, pool limit, shortlist size, or score window;
- change support mismatch budgets;
- change Phase D repair logic;
- change weapon capability, route, or linked-visual rules;
- raise scheduler budgets to hide an overage;
- change Traveler, Class Fantasy, or Chronicle Echo behavior.

---

# Expected implementation footprint

Likely modified runtime modules:

```text
Core/ZoneStyle/EraCandidateWork.lua
Core/ZoneStyle/EraEvidence.lua
Core/ZoneStyle/EraExecution.lua
Core/ZoneStyle/EligibilityWork.lua
Core/ZoneStyle/GenerationEligibility.lua
Core/Wardrobe/SupportBeam.lua
Core/Wardrobe/SupportWorker.lua
Core/Wardrobe/GenerationPerformance.lua
Core/Diagnostics/EraPerformanceFormatter.lua
Core/Diagnostics/SupportReportFormatter.lua
Core/Diagnostics/SnapshotBuilder.lua
Core/Diagnostics/ReportCompaction.lua
Core/Diagnostics/ReportEmergencyStub.lua
Core/ZoneStyle/Zone/DebugExport.lua
```

Recommended new runtime module:

```text
Core/Wardrobe/SupportCandidateWork.lua
```

Potential additional small diagnostics formatter module is allowed if required to keep every runtime file below 500 lines.

No generation-policy or scoring-coefficient module should change.

---

# Development order

## Slice 1: baseline and red fixtures

1. Verify exact v1.11.9 SHA-256.
2. Run the complete inherited test wall untouched.
3. Add a frame-tax fixture reproducing deferrals with zero API work.
4. Add a support-candidate synthetic fixture reproducing monolithic score cost under a fake clock.

## Slice 2: era admission contract

1. Add admission classes.
2. Add non-mutating stage probes.
3. Add API-headroom admission.
4. Preserve force-yield after expensive calls.
5. Add productive/phantom deferral counters.
6. Run watchdog and era parity suites.

## Slice 3: support candidate state machine

1. Add `SupportCandidateWork.lua`.
2. Implement neighbor stages.
3. Implement bridge stages.
4. Add budget/final stages.
5. Integrate normal beam candidates.
6. Integrate fallback candidates.
7. Run oracle, yield-point, and beam parity suites.

## Slice 4: diagnostics and persistence

1. Add era admission efficiency fields.
2. Add support candidate subphase fields.
3. Preserve headline fields through adaptive compaction.
4. Extend format-4 Zone export without format bump if compatible.

## Slice 5: exact-package validation

1. Version stamp `1.11.10`.
2. Run all Lua regression tests.
3. Run all static verifiers.
4. Parse every runtime Lua file.
5. Verify every TOC runtime entry exactly once.
6. Verify zero runtime Lua files >=500 lines.
7. Build exact ZIP.
8. Fresh-extract exact ZIP.
9. Repeat the complete wall from the extracted package.
10. Publish SHA-256 and Retail validation steps.

---

# Release success definition

v1.11.10 succeeds only when Quest Chronicle demonstrates all three properties together:

```text
SAFE
No watchdog loop and no post-expensive continuation.

BOUNDED
Cold <16 ms and three consecutive warm runs <8 ms.

PRODUCTIVE
Cold <=10 sec and every warm reroll <=6 sec, with zero phantom era deferrals.
```

The release must not trade one property for another.

The intended endpoint is not merely a scheduler that never freezes. It is a scheduler that yields only when yielding protects the frame, then uses the rest of the available frame budget to make visible forward progress.
