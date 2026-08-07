# Quest Chronicle v1.11.9 Architecture & Development Plan

## Cooperative era execution-boundary correction

## Release purpose

Quest Chronicle v1.11.9 is the corrective release for the catastrophic v1.11.8 Retail scheduler regression.

The intended v1.11.8 architecture remains valuable: per-sibling era evidence was split into bounded operations, stable fragment memoization was added, and detailed era scheduling diagnostics were introduced. The Retail build failed because the new cooperative era state machine was still reachable through synchronous compatibility wrappers that could not honor a fresh-slice deferral.

The observed Retail failure was:

```text
EraEvidence.lua:423: script ran too long
Prepared in 127 frames • 97.8 sec
Worker slice: 19015.9 ms
Largest instrumented call: Anchor weapons 19012.7 ms
```

The source audit identifies the precise deadlock pattern:

```text
fresh-slice era operation is requested
→ scheduler admission returns DEFERRED
→ current slice is marked forceYield
→ synchronous wrapper ignores DEFERRED
→ wrapper immediately steps the same work again on the same Lua stack
→ no frame boundary can occur
→ repeated DEFERRED attempts make no progress
→ WoW's script watchdog terminates the call
```

v1.11.9 has one overriding goal:

```text
No cooperative era operation may be synchronously drained while it can defer.
Every era caller must have an explicit execution contract, and every DEFERRED
result must return control to a scheduler that can actually produce a new slice.
```

This release is primarily a scheduler-boundary and API-contract correction. It must preserve the v1.11.8 era evidence state machine, evidence precedence, fragment-cache semantics, Zone policy, support behavior, weapon legality, random consumption, and diagnostic formats.

---

# Baselines and authority

## Implementation baseline

Build v1.11.9 directly from the exact v1.11.8 package:

```text
QuestChronicle-v1.11.8.zip
SHA-256:
bf0cd555dfd1cf560be5bba2b3c8243c84b84defd2faaed47604d73bb891e930
```

v1.11.8 is the implementation baseline because it contains:

- the per-candidate era state machine;
- operation-aware era scheduling;
- stable non-pending era-fragment memoization;
- era scheduling diagnostics;
- adaptive-compaction preservation of era diagnostics;
- format-4 Zone export rendering for era performance.

## Retail safety baseline

v1.11.7 remains the last usable Retail baseline:

```text
QuestChronicle-v1.11.7.zip
SHA-256:
e0eddc6c6c66d407a0960dc1355c89a64845db68792293c9d0c9055b6d449ff0
```

v1.11.8 must not be treated as live-validated or as a safe fallback build.

The v1.11.9 implementation therefore has two parity obligations:

```text
Behavioral safety and generation semantics: v1.11.7
Era evidence tuple semantics and intended scheduling decomposition: v1.11.8
```

---

# Architecture identity remains unchanged

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
```

v1.11.9 does not begin the Zone-native support-policy rewrite.

---

# Confirmed root cause

## 1. The cooperative era worker can legitimately defer

`Core/ZoneStyle/EraEvidence.lua` exposes:

```text
CreateSourceEraEvidenceWork(source, options)
StepSourceEraEvidenceWork(work, maxCandidates)
```

The v1.11.8 stepper asks `AdmitEraEvidenceOperation()` before fresh-slice-sensitive stages. When admission is denied it returns:

```text
false, nil, 0, "DEFERRED"
```

That is correct for a cooperative caller.

## 2. The synchronous era getter cannot honor that contract

The shipped v1.11.8 compatibility getter is structurally equivalent to:

```lua
function ZoneStyle.GetSourceEraEvidence(source)
    local work = ZoneStyle.CreateSourceEraEvidenceWork(source)
    while not work.done do
        ZoneStyle.StepSourceEraEvidenceWork(work, 1000000)
    end
    return work.result
end
```

It discards the step status.

When a step returns `DEFERRED`, the wrapper immediately calls it again without returning to WoW. Because the same worker slice remains active, admission continues to fail forever.

## 3. Weapon style ordering reaches the synchronous getter indirectly

The critical Retail route is not an explicit call from the anchor worker.

`Core/Wardrobe/WeaponStyleOrdering.lua` creates cached eligibility work without precomputed era evidence:

```text
CreateCachedSourceEligibilityWork(candidate.source, modeKey, context)
```

In v1.11.8, `CreateCachedSourceEligibilityWork()` contains the eager fallback:

```text
if evidence == nil then
    evidence = GetSourceEraEvidence(source)
end
```

That means the call enters synchronous era resolution during weapon-style eligibility initialization, before the cooperative eligibility state machine has a chance to own or yield the era work.

The parent call remains inside the anchor weapon coroutine, which is why Retail reports the 19-second call as:

```text
Anchor weapons
```

## 4. A second synchronous fallback exists inside raw eligibility

`Core/ZoneStyle/EligibilityWork.lua` also performs:

```text
work.eraEvidence = work.eraEvidence or GetSourceEraEvidence(source)
```

inside the `ERA` stage.

Any caller that creates raw eligibility work without resolved evidence can therefore reproduce the same execution-boundary mistake.

## 5. Other synchronous callers must be classified explicitly

The source audit found `GetSourceEraEvidence()` access from:

- `GenerationWorker.lua` fallback path;
- `AnchorSkeletonWorker.lua` fallback path;
- `SupportWorker.lua` fallback path;
- `SupportRerollScoring.lua` fallback path;
- `SupportRerollLegacy.lua`;
- `EligibilityWork.lua`;
- `GenerationEligibility.lua`;
- `Scoring.lua` through `GetSourceExpansionID()`;
- the public `GetSourceExpansionID()` helper.

Not every synchronous caller is wrong. The problem is allowing a synchronous caller to instantiate work that still participates in cooperative fresh-slice admission.

## 6. Ambient scheduler detection is too implicit

`AdmitEraEvidenceOperation()` currently discovers `generationJob` or `supportRerollJob` from global Wardrobe state.

That creates a hidden coupling:

```text
same era work object
+ same API call
+ different unrelated ambient job
= different admission behavior
```

v1.11.9 must move the scheduling contract onto the era work itself. A work item must know whether it is cooperative, background-ticked, or synchronous before its first step.

---

# Release invariants

## Invariant A: execution mode is explicit

Every source-era work object must carry an immutable execution contract.

Recommended modes:

```text
GENERATION_COOPERATIVE
SUPPORT_REROLL_COOPERATIVE
BACKGROUND_TICK
SYNCHRONOUS
```

The exact string constants may be adjusted during implementation, but the semantic distinction is mandatory.

## Invariant B: only cooperative modes may return DEFERRED

```text
GENERATION_COOPERATIVE      may DEFER
SUPPORT_REROLL_COOPERATIVE  may DEFER
BACKGROUND_TICK             does not spin; one bounded operation per callback
SYNCHRONOUS                 must never return DEFERRED
```

A synchronous caller may pay synchronous cost, but it must always make state-machine progress and may never wait for a frame boundary that cannot occur.

## Invariant C: DEFERRED means return to the scheduler

Once any nested era step reports `DEFERRED`:

```text
no second step of that era work may execute in the same caller stack
no eligibility stage may advance
no scoring may occur
no random draw may occur
no cache record may be committed
```

The caller returns control immediately.

## Invariant D: generation must never fall back to synchronous era resolution

When a generation, weapon-style, support-generation, or modern support-reroll job is active, unresolved era evidence must be represented as nested work.

Synchronous getters may remain public compatibility APIs, but they are forbidden as a normal generation path.

## Invariant E: no semantic drift

The correction must not change:

- source IDs examined;
- evidence ranks or precedence;
- earliest-expansion selection;
- equal-expansion stronger-evidence preference;
- pending item semantics;
- tracking-pending suppression semantics;
- fragment-cache keys or eligibility rules;
- persistent era cache version;
- generation-eligibility keys for equivalent evidence;
- candidate eligibility;
- candidate ordering;
- random-call order or count;
- selected armor or weapon semantics;
- Zone anchor-policy coefficients;
- support scoring;
- Phase D validation and repair;
- legal weapon routes;
- locks and hidden slots.

---

# Track A: explicit era execution contracts

## Add execution identity to source-era work

`CreateSourceEraEvidenceWork()` should accept scheduling options and store them on the returned work object.

Conceptually:

```lua
CreateSourceEraEvidenceWork(source, {
    executionMode = "GENERATION_COOPERATIVE",
    schedulerOwner = job,
})
```

The execution mode must not be inferred later from whichever global job happens to exist.

## Scheduler owner

For cooperative work, retain the specific parent job responsible for servicing a deferral.

The owner can be:

```text
generation job
support-reroll job
background resolver token
none for synchronous work
```

`AdmitEraEvidenceOperation()` must consult the work's own contract first.

## Remove ambient-job dependence from ordinary admission

The current global lookup may remain as a temporary compatibility fallback only if necessary during migration, but the finished v1.11.9 path must not rely on it for normal generation.

Automated verification should fail if the primary admission path again chooses behavior solely from global `generationJob` or `supportRerollJob` state.

---

# Track B: make synchronous era resolution genuinely synchronous

## Synchronous getter contract

`GetSourceEraEvidence(source)` remains available for compatibility and non-generation callers.

It must create source-era work in `SYNCHRONOUS` mode.

In synchronous mode:

```text
fresh-slice admission never returns DEFERRED
forceYield is never used as a wait condition
one state-machine step always either advances state or completes
```

This keeps one authoritative evidence implementation while preventing cooperative semantics from leaking into a blocking API.

## Progress guard

Every synchronous drain must have a progress invariant.

At minimum, each iteration must prove one of:

```text
source index advanced
candidate stage advanced
set index advanced
encounter drop index advanced
encounter tier index advanced
work completed
```

If a synchronous iteration reports neither completion nor progress, abort the drain safely and return a diagnostic pending result rather than spinning.

Do not use only an enormous blind iteration count. The guard should detect lack of state progress directly.

## Optional absolute operation ceiling

A secondary operation ceiling may exist as a final watchdog, derived from the work structure rather than a magic million-step drain.

A ceiling trip must:

- stop the synchronous loop;
- return a non-authoritative pending result;
- increment a diagnostic guard counter;
- produce a visible warning in debug-capable contexts;
- never hang the client.

## No `1000000` era drain

The v1.11.9 static verifier should reject the old pattern:

```text
StepSourceEraEvidenceWork(work, 1000000)
```

inside the synchronous era getter.

The exact step count argument can become `1` because the synchronous wrapper owns the loop and must verify progress after each bounded operation.

---

# Track C: make cached eligibility own unresolved era work

This is the most important caller correction because it directly fixes the Retail Anchor Weapons route.

## Current problem

`CreateCachedSourceEligibilityWork()` currently tries to compute its cache key immediately. The key includes era evidence, so missing evidence triggers the synchronous getter during construction.

## New cached-eligibility state machine

When evidence is supplied, preserve the existing fast path.

When evidence is absent, create a resumable cached-eligibility object with stages such as:

```text
PRECHECK
ERA_INIT
ERA_STEP
CACHE_KEY
CACHE_LOOKUP
RAW_INIT
RAW_STEP
COMPLETE
```

The exact names may differ, but the ordering is mandatory.

### ERA_INIT

Create nested source-era work using the eligibility work's own execution contract.

For weapon style ordering:

```text
execution mode = GENERATION_COOPERATIVE
scheduler owner = active weapon-generation job
```

### ERA_STEP

Call `StepSourceEraEvidenceWork()` once.

If it returns `DEFERRED`:

```text
return not-done immediately
preserve all eligibility state
perform no cache-key construction
perform no cache lookup
perform no random or scoring work
```

If it makes progress but is incomplete, return not-done normally.

If complete, store the evidence and advance to `CACHE_KEY`.

### CACHE_KEY

Only now compute `EligibilityKey()`.

This preserves current cache identity because the same completed evidence tuple is used.

### CACHE_LOOKUP

Perform source-local and persistent eligibility lookup exactly as v1.11.8 does today.

### RAW_INIT and RAW_STEP

If no eligibility cache entry exists, create raw source-eligibility work with the already-resolved evidence.

The raw eligibility worker must not need to invoke `GetSourceEraEvidence()` in this path.

---

# Track D: remove synchronous era lookup from raw eligibility

## Current problem

`StepSourceEligibilityWork()` currently contains a synchronous getter in its `ERA` stage when `resolvedEraEvidence` is absent.

## New behavior

Raw eligibility work must support two explicit modes:

```text
resolved evidence supplied
nested era work required
```

When nested era work is required, use stages equivalent to:

```text
ERA_INIT
ERA_STEP
ERA_APPLY
```

The nested work receives the same execution contract as the eligibility work.

## Synchronous public eligibility API

`GetSourceEligibility()` remains a synchronous compatibility API.

Its work must be created with `SYNCHRONOUS` execution mode. Therefore its nested era work is also synchronous and cannot return `DEFERRED`.

## Cooperative public eligibility API

`CreateSourceEligibilityWork()` and `CreateCachedSourceEligibilityWork()` must accept an execution/scheduler options object so cooperative callers can propagate ownership explicitly.

---

# Track E: migrate generation callers to explicit cooperative ownership

## Weapon style ordering

This is the critical Retail route.

`CreateWeaponStyleOrderingWork()` already owns the active generation job.

Pass that job into cached eligibility creation:

```text
CreateCachedSourceEligibilityWork(
    source,
    modeKey,
    context,
    nil,
    prechecked,
    GENERATION_COOPERATIVE,
    job
)
```

Do not resolve era evidence inside `ELIGIBILITY_INIT`.

One call to `StepWeaponStyleOrderingWork()` must perform at most one bounded nested eligibility/era operation before returning.

The parent anchor weapon coroutine must therefore regain control whenever the nested era worker defers.

## Generation armor worker

`GenerationWorker.lua` already creates and steps source-era work explicitly.

Update creation to attach `GENERATION_COOPERATIVE` and the current job.

The fallback synchronous getter should be retained only for harness compatibility when the cooperative APIs are genuinely absent. The production TOC path must always choose the cooperative branch.

## Anchor skeleton worker

Apply the same explicit cooperative ownership.

## Contextual support worker

Apply the same explicit cooperative ownership.

Support eligibility already has bounded marker work and must continue to receive precomputed era evidence when available.

## Modern support reroll worker

`SupportRerollScoring.lua` already has `ERA_INIT` and `ERA_STEP` stages.

Attach `SUPPORT_REROLL_COOPERATIVE` ownership to its era work.

Any fallback to `GetSourceEraEvidence()` is compatibility-only and must never be chosen in the fully loaded addon.

---

# Track F: classify legitimate synchronous callers

## Legacy contextual slot reroll

`SupportRerollLegacy.lua` is intentionally synchronous legacy code.

It may continue to call the synchronous getter, provided:

```text
GetSourceEraEvidence uses SYNCHRONOUS mode
no fresh-slice DEFERRED result is possible
progress guard is active
```

This release does not modernize the legacy reroll's overall latency.

## Scoring helpers

`GetSourceExpansionID()` and other non-worker helpers may use synchronous era resolution.

They must never inherit cooperative admission merely because a generation job exists elsewhere in global state.

## Synchronous eligibility wrappers

`GetSourceEligibility()` and `GetSourceEligibilityCached()` may remain synchronous compatibility APIs.

Their nested era work must inherit `SYNCHRONOUS` mode.

Generation code should pass completed evidence or use cooperative work APIs rather than reaching these synchronous wrappers with unresolved evidence.

---

# Track G: background pending-evidence reevaluation

## Scheduled background path

`PendingEvidenceResolver.lua` already advances one nested era operation per callback.

Create its source-era work in `BACKGROUND_TICK` mode.

A background callback is already a scheduler boundary. It should perform one bounded operation and return without consulting an unrelated foreground generation slice.

## Forced flush path

`FlushPendingEraEvidenceReevaluations()` may synchronously drain work for tests, shutdown-style maintenance, or explicit flush behavior.

Forced flush must switch to a synchronous execution contract or otherwise guarantee that `DEFERRED` cannot be returned.

A force loop may never repeatedly invoke a background work item that is waiting for a fresh frame.

## Cross-job isolation

A foreground generation job must not cause background era work to defer merely because the global generation slice is currently used.

Likewise, background work must not mutate foreground slice admission state.

---

# Track H: DEFERRED propagation and progress instrumentation

## Step return contract

Keep the existing caller-compatible values, but standardize the final status field:

```text
PROGRESSED
DEFERRED
COMPLETE
```

A nil status may remain accepted for old focused harnesses, but production code should produce one of the explicit states.

## Progress serial

Add a monotonically increasing progress serial or equivalent state fingerprint to source-era work.

Increment it whenever meaningful work advances.

Use it to prove:

```text
DEFERRED did not mutate evidence state
synchronous step made progress
cooperative caller did not retry DEFERRED in the same stack
```

## Same-slice deferred retry counter

Add a diagnostic counter for attempted repeated deferral without an intervening scheduler boundary.

Expected production value:

```text
0
```

Any nonzero value should be treated as a scheduler-integrity defect.

## Synchronous guard counter

Record:

```text
era synchronous progress-guard trips
```

Expected value:

```text
0
```

A guard trip must be visible in Debug History and should produce a warning.

---

# Track I: watchdog-specific safety contract

v1.11.9 needs a contract stronger than ordinary timing tests.

## Hard safety requirement

No user action may remain inside a no-progress era loop.

This requirement is independent of the usual 8 ms performance target.

## Fatal-regression fixture

Create a test that reproduces the exact Retail conditions:

```text
active generation job
weapon style ordering
cached eligibility created without precomputed era evidence
nested era candidate reaches a fresh-slice-required operation
current generation slice is already used
admission rejects the operation
```

Expected result:

```text
StepWeaponStyleOrderingWork returns to caller
nested era work remains incomplete
parent job has forceYield requested
no second era step occurs on that stack
progress state is unchanged after DEFERRED
```

The fixture must fail against v1.11.8.

## Busy-spin tripwire

Instrument the test with an era-step call counter.

One outer weapon-style step must not invoke the same deferred source-era work more than once.

The test should hard-fail after a tiny number of calls rather than relying on wall-clock timeout.

## Synchronous getter fixture

Create the same used-slice ambient conditions and call `GetSourceEraEvidence()` directly.

Expected:

```text
work uses SYNCHRONOUS execution mode
fresh operation is admitted synchronously
result completes
no DEFERRED status is observed
no forceYield loop occurs
```

This proves that ambient foreground state cannot poison legitimate synchronous callers.

---

# Track J: diagnostics and export

## Preserve existing formats

Do not bump:

```text
Diagnostic report format 1
Zone debug export format 4
Era Evidence version 2
Manifest version 3
```

The correction changes scheduler execution identity, not persisted evidence schema.

## Add headline scheduler-boundary fields

Where report size permits, record:

```text
Era execution mode counts
Era deferred operations
Era same-slice deferred retries
Era synchronous guard trips
Weapon eligibility era deferrals
Background era operations
```

These must survive `SUMMARY_TABLES` adaptive compaction if they are required to validate closure.

## Existing era performance fields remain

Preserve:

- era operations;
- sibling completions;
- fresh-slice deferrals;
- fragment-cache hits and builds;
- pending candidate completions;
- set-list calls;
- set-entry calls;
- tracking calls;
- encounter-list calls;
- encounter-entry operations;
- item-metadata calls;
- aggregate finalizations;
- largest era subphase.

## Watchdog warning

A synchronous progress-guard trip should emit an explicit warning distinct from the ordinary performance warning.

Suggested semantic identity:

```text
ERA_PROGRESS_GUARD
```

Exact user-facing wording can be finalized during implementation.

---

# Track K: cache and invalidation parity

The v1.11.8 fragment cache is preserved.

## Stable fragment rules remain

Cache only completed, semantically stable candidate fragments.

Never cache:

```text
item-pending fragments
tracking-pending fragments
partially completed state-machine work
DEFERRED work state
```

## Execution mode is not evidence identity

Execution mode must not enter evidence cache keys.

The same source resolved synchronously and cooperatively must produce the same evidence tuple and may reuse the same stable fragment result when all existing cache conditions permit it.

## Invalidation remains conservative

Preserve current invalidation for:

- item-data changes;
- tracking changes;
- collection changes where relevant;
- manifest changes;
- source identity changes.

v1.11.9 must not widen persistent cache lifetime merely to improve performance.

---

# Track L: random and selection parity

The scheduler correction must be invisible to generation decisions.

## Random invariant

No random draw may occur until the same eligibility and scoring point used by v1.11.7/v1.11.8.

DEFERRED operations consume zero random draws.

## Candidate-order invariant

Resuming a deferred era or eligibility worker must continue at the exact same source and candidate index.

No candidate may be skipped, duplicated, or moved.

## Weapon-route invariant

The v1.11.5 legal-route and capability-snapshot behavior remains frozen.

The fatal bug happened while preparing weapon-style eligibility, not in legal route selection.

Do not alter:

- route discovery;
- route completeness;
- one-hand/two-hand/shield compatibility;
- linked-visual deduplication;
- weapon capability generation.

---

# Proposed runtime module changes

## Primary modules

Likely changes:

```text
Core/ZoneStyle/EraEvidence.lua
Core/ZoneStyle/EraCandidateWork.lua
Core/ZoneStyle/EligibilityWork.lua
Core/ZoneStyle/GenerationEligibility.lua
Core/Wardrobe/WeaponStyleOrdering.lua
Core/Wardrobe/GenerationWorker.lua
Core/Wardrobe/AnchorSkeletonWorker.lua
Core/Wardrobe/SupportWorker.lua
Core/Wardrobe/SupportRerollScoring.lua
Core/Wardrobe/PendingEvidenceResolver.lua
```

## Compatibility callers

Audit and change only as needed:

```text
Core/Wardrobe/SupportRerollLegacy.lua
Core/ZoneStyle/Scoring.lua
```

## Diagnostics

Likely changes:

```text
Core/Diagnostics/EraPerformanceFormatter.lua
Core/Diagnostics/SnapshotBuilder.lua
Core/Diagnostics/ReportCompaction.lua
Core/Diagnostics/ZoneDebugExport.lua or current format-4 rendering module
```

Exact filenames should follow the existing module split and the no-file-at-or-above-500-lines rule.

## No generation-policy module changes

Do not change Zone anchor-policy coefficients, support scoring formulas, Phase D rules, or weapon-route policy as part of v1.11.9.

---

# Implementation sequence

## Phase 0: freeze and reproduce

1. Verify the exact v1.11.8 package SHA-256.
2. Extract into a clean worktree.
3. Run the full inherited v1.11.8 automated wall.
4. Add the fatal-regression fixture before changing runtime code.
5. Confirm the fixture reproduces repeated `DEFERRED` attempts or otherwise fails against v1.11.8.

No fix is accepted until the test is red on the original package.

## Phase 1: add execution contracts

1. Add execution-mode constants.
2. Add immutable mode and scheduler-owner fields to source-era work.
3. Update `AdmitEraEvidenceOperation()` to honor work-owned execution identity.
4. Add progress serial/state tracking.
5. Add same-slice retry and synchronous-guard diagnostics.

Keep caller behavior unchanged in this phase.

## Phase 2: repair synchronous getter

1. Make `GetSourceEraEvidence()` create `SYNCHRONOUS` work.
2. Step one bounded operation at a time.
3. Assert progress on every incomplete synchronous step.
4. Remove the million-step drain pattern.
5. Add a safe guard failure result.

Run evidence parity tests before continuing.

## Phase 3: refactor cached eligibility

1. Stop eager era lookup in `CreateCachedSourceEligibilityWork()`.
2. Add nested era work stages when evidence is absent.
3. Build the eligibility cache key only after era completion.
4. Preserve immediate cached fast paths when evidence is already provided.
5. Make `StepCachedSourceEligibilityWork()` propagate incomplete/deferred nested work without scoring or random consumption.

This phase should make the fatal weapon-style test green.

## Phase 4: refactor raw eligibility

1. Remove direct synchronous era lookup from the raw `ERA` stage.
2. Add nested era work support.
3. Propagate execution mode from the eligibility work.
4. Keep synchronous `GetSourceEligibility()` safe through `SYNCHRONOUS` mode.

## Phase 5: migrate all production callers

Attach explicit scheduling ownership in:

- armor generation;
- anchor skeleton generation;
- contextual support generation;
- weapon style ordering;
- modern support reroll;
- pending background resolver.

Verify that no fully loaded generation path calls synchronous era resolution for unresolved evidence.

## Phase 6: background and force-flush safety

1. Set scheduled pending reevaluation to `BACKGROUND_TICK`.
2. Ensure each scheduled callback performs bounded work and returns.
3. Ensure forced flush cannot receive `DEFERRED`.
4. Add cross-job isolation tests.

## Phase 7: diagnostics and compaction

1. Add execution-boundary counters.
2. Preserve them through adaptive compaction.
3. Add them to Debug History.
4. Add them to Zone export format 4 without a format bump.
5. Verify worst-case report retention under 20,480 bytes.

## Phase 8: full parity and package gate

1. Run fixed-seed era tuple parity.
2. Run candidate/selection parity.
3. Run random-consumption parity.
4. Run scheduler integrity tests.
5. Run the entire Lua and Python wall.
6. Verify TOC uniqueness and runtime syntax.
7. Verify no runtime Lua file is at or above 500 lines.
8. Package the exact ZIP.
9. Extract the ZIP fresh.
10. Repeat every gate against the extracted package.

---

# Automated validation plan

## Test 1: exact v1.11.8 deadlock reproduction

Create `test_era_deferred_sync_deadlock_v1119.lua` or equivalent.

Fixture:

```text
active generation job
used current slice
weapon-style ordering candidate
no precomputed era evidence
candidate reaches SET_LIST, TRACKING, ENCOUNTER_LIST, or ITEM_METADATA
fresh admission denied
```

v1.11.8 expected behavior:

```text
fixture detects repeated no-progress stepping / fails guard
```

v1.11.9 expected behavior:

```text
outer weapon-style step returns incomplete
exactly one DEFERRED era attempt occurs
no nested retry occurs until a new outer step
```

## Test 2: synchronous getter under ambient generation

With an active used generation slice, call the synchronous getter.

Assert:

```text
execution mode SYNCHRONOUS
no DEFERRED
no same-slice retry
no forceYield dependency
same evidence tuple as reference resolver
```

## Test 3: cached eligibility nested-era fixture

Create cached eligibility without evidence.

Assert stage order:

```text
ERA_INIT
ERA_STEP ...
CACHE_KEY
CACHE_LOOKUP
RAW_INIT/RAW_STEP as required
COMPLETE
```

Cache key must not exist before era evidence completes.

## Test 4: weapon-style end-to-end scheduler fixture

Run multiple weapon candidates with variable era operations.

Assert:

```text
candidate order preserved
eligibility order preserved
random draws occur only during scoring
same retained weapon candidates
same style-priority ordering for fixed random stream
no synchronous era getter called
```

## Test 5: raw eligibility nested-era fixture

Call `CreateSourceEligibilityWork()` without precomputed evidence in cooperative mode.

Assert it yields through nested era work and never invokes the synchronous getter.

Repeat in synchronous mode and assert completion without DEFERRED.

## Test 6: DEFERRED immutability fixture

Capture the source-era state fingerprint before a denied fresh operation.

After the denied step, assert:

```text
state fingerprint unchanged
progress serial unchanged
candidate indexes unchanged
cache unchanged
random count unchanged
```

## Test 7: background isolation fixture

Run a foreground generation job with a used slice and step a background pending reevaluation.

Assert the background work is not incorrectly blocked by foreground ambient state.

## Test 8: forced pending flush fixture

Force pending reevaluation to completion and assert:

```text
no DEFERRED spin
bounded progress every iteration
same final evidence as scheduled background completion
```

## Test 9: evidence reference parity

Reuse and extend v1.11.8 candidate parity cases:

- no evidence;
- curated evidence;
- set evidence;
- conflicting sets;
- tracking evidence;
- tracking pending;
- encounter evidence;
- multiple drops and tiers;
- item metadata;
- item pending;
- early encounter decision;
- tracking-pending item suppression.

Compare:

```text
expansionID
rank
method
label
sourceID
itemID
pending state
pending item ID
tracking-pending state
```

## Test 10: execution-mode cache parity

Resolve the same stable source:

```text
synchronously
cooperatively
background tick
```

Assert identical final evidence and identical stable fragment-cache identity.

## Test 11: pending-fragment cache safety

Verify pending candidates are never memoized regardless of execution mode.

## Test 12: generation fixed-seed parity

Against the v1.11.7/v1.11.8 intended selection semantics, verify:

```text
same armor pool ordering
same anchor candidate ordering
same legal weapon candidates
same random call count and sequence
same shortlist construction
same support decisions
same Phase D result
```

Scheduling may change frame counts. Selection semantics may not.

## Test 13: watchdog operation ceiling

Add a synthetic source with a deliberately long but finite set/drop structure.

Assert:

```text
cooperative path returns after bounded work
synchronous path shows monotonic progress
no single caller performs a no-progress loop
no safety guard trips
```

## Test 14: diagnostics and compaction

Build a worst-case Zone report containing all v1.11.9 execution-boundary counters.

Assert:

```text
report persists <= 20,480 bytes
ZONE_ANCHOR_POLICY_V1 retained
era performance headline retained
same-slice retry counter retained
synchronous guard counter retained
support and Phase D outcomes retained
```

## Test 15: format-4 export regression

Assert format remains `4` and exports:

```text
latest Zone report
latest policy-bearing report
era execution/scheduler headline
weapon capability headline
support scheduling headline
scheduler integrity
```

## Static verifier

Add a v1.11.9 verifier that fails if production generation code contains any of these patterns:

```text
GetSourceEraEvidence(source) from weapon-style eligibility initialization
GetSourceEraEvidence(source) from raw cooperative eligibility ERA stage
StepSourceEraEvidenceWork(..., 1000000) in synchronous getter
while not work.done with no progress/deferred handling around source-era stepping
```

The verifier should also confirm production generation workers pass explicit execution ownership when creating source-era work.

---

# Retail live validation

Retail testing restarts from the beginning because v1.11.8 did not complete a valid cold action.

## Test 1: watchdog safety smoke test

After `/reload`, start one Zone Native Generate Outfit.

Immediate hard requirements:

```text
No "script ran too long"
No Lua error
No multi-second single worker slice
No era progress-guard warning
No diagnostic rejection
```

If any watchdog or progress-guard failure occurs, stop testing the build.

## Test 2: cold Generate Outfit

Closure gate:

```text
Longest worker slice < 16.0 ms
Largest instrumented call < 16.0 ms
Post-expensive continuations = 0
No performance warning preferred
No scheduler-integrity warning
```

Era-specific expectations:

```text
Same-slice deferred retries = 0
Synchronous guard trips = 0
Largest era subphase target < 4.0 ms
```

The 4 ms era target remains a design target. The frozen overall cold acceptance gate remains 16 ms.

## Test 3: three consecutive warm Reroll Unlocked actions

Without reloading, changing zone, specialization, equipment topology, or collection state, run three consecutive Reroll Unlocked actions.

Every run must satisfy:

```text
Longest worker slice < 8.0 ms
Largest instrumented call < 8.0 ms
Maximum slice debt <= 2.0 ms
Post-expensive continuations = 0
Same-slice deferred retries = 0
Synchronous guard trips = 0
No performance warning
No diagnostic rejection
```

All three must pass. Two of three is still a failure.

## Test 4: Zone debug export

Run:

```text
/qc zone debug export
```

Confirm:

```text
format 4
ZONE_ANCHOR_POLICY_V1 ACTIVE
correct latest policy-bearing report lineage
era scheduler counters present
era same-slice deferred retries 0
era synchronous guard trips 0
support scheduling remains healthy
weapon capability state remains healthy
```

## Test 5: contextual support-slot reroll

Run one support-only slot reroll.

Confirm:

```text
report persists
anchor ancestry reused
support profile reused where expected
no era deadlock
no synchronous guard trip
```

## Test 6: individual legacy reroll smoke test

Run one legacy individual anchor or weapon reroll only as a regression smoke test.

The known synchronous legacy latency remains outside v1.11.9 closure, but the action must not enter an era `DEFERRED` spin or produce a script watchdog error.

---

# Acceptance criteria

## Safety

v1.11.9 is rejected immediately if any of these occur:

```text
script ran too long
same-slice DEFERRED retry > 0
synchronous era progress-guard trip > 0
unbounded era drain
foreground/background admission contamination
```

## Architecture

Pass only if:

- every source-era work item has explicit execution identity;
- cooperative generation work owns its scheduler context;
- synchronous work cannot return `DEFERRED`;
- cached eligibility no longer eagerly resolves missing era evidence synchronously;
- raw cooperative eligibility no longer invokes the synchronous era getter;
- background reevaluation is isolated from foreground slice state;
- no normal generation path relies on ambient global job discovery for era admission.

## Parity

Pass only if:

- era evidence tuple parity is exact;
- pending behavior is exact;
- fragment-cache semantics are unchanged;
- generation eligibility is unchanged;
- fixed-seed candidate ordering is unchanged;
- random consumption is unchanged;
- selected results are parity-safe;
- Zone policy and support scoring are unchanged.

## Diagnostics

Pass only if:

- existing v1.11.8 era counters remain available;
- execution-boundary counters are recorded;
- adaptive persistence retains required headline data;
- format-4 export remains valid;
- no valid report is rejected.

## Retail performance

Pass only if:

```text
Cold Generate Outfit < 16 ms
Warm reroll 1 < 8 ms
Warm reroll 2 < 8 ms
Warm reroll 3 < 8 ms
Every warm largest call < 8 ms
Every warm slice debt <= 2 ms
Post-expensive continuations = 0
Performance warnings = 0 on all warm runs
```

## Package quality

Pass only if:

- all Lua regression tests pass;
- all Python/static verifiers pass;
- all runtime modules parse;
- every TOC runtime module appears exactly once;
- no runtime Lua file is at or above 500 lines;
- ZIP integrity passes;
- fresh-extraction validation passes;
- version metadata is consistently `1.11.9`.

---

# Explicit non-goals

v1.11.9 does not:

- redesign era evidence scoring;
- change evidence rank or precedence;
- change Zone affinity coefficients;
- change `ZONE_ANCHOR_POLICY_V1`;
- make Zone support policy authoritative;
- redesign contextual support scoring;
- change Phase D repair;
- change weapon legal-route policy;
- modernize the known synchronous legacy individual anchor/weapon reroll;
- raise scheduler budgets;
- increase the 20,480-byte report ceiling;
- bump persistent era evidence version;
- bump manifest version;
- bump Zone export format beyond 4;
- change SavedVariables schema;
- change Traveler, Class Fantasy, or Chronicle Echo behavior.

Any of those belongs in a later release after the anchor-policy train is safely closed.

---

# Expected release result

A successful v1.11.9 should make the following statement true:

```text
Quest Chronicle's era evidence system has one semantic resolver but two explicit
execution contracts. Cooperative callers can defer and always return control to
a scheduler. Synchronous callers cannot defer and always make bounded progress.
Eligibility no longer bridges those contracts implicitly. No used worker slice
can trap the addon in a DEFERRED loop, and the v1.11.8 evidence decomposition can
finally be evaluated on Retail under the original Zone performance gates.
```

Only after the watchdog safety gate and all three warm performance runs pass should the first authoritative Zone anchor-policy slice be considered closed.
