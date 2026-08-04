# Quest Chronicle Diagnostic Snapshot Format

Diagnostic format: `1`

Storage location:

```text
QuestChronicleDB.debug
```

The diagnostic store is independent of the recorder schema, Courier snapshot, wardrobe cache, concepts, and persistent generation cache.

## Store envelope

```lua
QuestChronicleDB.debug = {
    formatVersion = 1,
    nextSequence = 1,
    reports = {},
}
```

The store retains at most ten reports. Each report is limited to 20 KB and the approximate combined history is limited to 200 KB. Invalid, oversized, or incompatible reports are discarded during initialization and ordinary reads.

## Report identity

Every report includes:

```lua
{
    formatVersion = 1,
    id = "QCDBG-<timestamp>-<sequence>",
    sequence = 1,
    timestamp = 0,
    timestampText = "YYYY-MM-DD HH:MM:SS",
    version = "1.9.0.13",
    action = "GENERATE_OUTFIT",
    result = "COMPLETED",
    success = true,
    message = "...",
}
```

Supported actions:

```text
GENERATE_OUTFIT
REROLL_UNLOCKED
REROLL_SLOT
```

Supported results:

```text
COMPLETED
FALLBACK
CANCELLED
FAILED
NO_ALTERNATIVE
```

## Character and context

The `character` table contains only the current character key, name, realm, class, race, and level. The `context` table contains the recorded generation mode, zone profile, provenance, map, and era ceiling.

No account paths, Chronicle event history, SavedVariables dump, or Courier payload is copied into a diagnostic report.

## Outfit and skeleton

`outfit.slots` contains compact appearance snapshots for the finished preview. `skeleton.components` contains the anchor components used by the report:

```text
CHEST
LEGS
SHOULDER
ONE_HAND
TWO_HAND
RANGED
OFF_HAND
```

Each appearance may contain stable display and identity fields:

```lua
{
    slotKey = "CHEST",
    slotLabel = "Chest",
    name = "Rugged Plate Vest",
    sourceID = 123,
    visualID = 456,
    itemID = 789,
    categoryID = 4,
    locked = false,
    hidden = false,
    baseScore = 31.2,
    scoreReasons = {},
}
```

The skeleton also records chosen rank, shortlist size, base score, repeat penalty, adjusted selection score, novelty class, compared/changed/repeated logical anchors, mean pair cohesion, hard clashes, fallback reason, score breakdown, cohesion dimensions, strongest bridge, and weakest relationship when available.

Weapon components retain their internal family key but use physical `Main Hand` and `Off Hand` labels. Weapon subtype is stored separately as presentation metadata.

## Beam report

The `beam` table records compact counters only:

```lua
{
    poolSizes = {},
    expansions = {},
    retained = {},
    weaponBundles = 0,
    pairCacheHits = 0,
    pairCacheMisses = 0,
    completeSkeletons = 0,
    finalShortlist = 0,
    chosenRank = 0,
    weightedWindow = 0,
    fallbackReason = nil,
}
```

Candidate arrays, beam nodes, source tables, and coroutine state are never persisted.

## Performance and cache

`performance.phaseStats` stores the maximum, total, and call count already recorded by the generation pipeline. `longestWorkerSliceMs` records the complete cooperative resume, while `largestInstrumentedCallMs` and `largestInstrumentedCallPhase` record the largest individually timed operation inside those slices. `cache` stores the generation-cache lifecycle snapshot already attached to the performance record.

The Debug tab formats these values but does not recalculate generation outcomes.

## Warnings and comparison

Warnings are derived after the generation and UI completion pipeline settles. Current warnings include performance thresholds, legacy fallback, and repeated Chest/Shoulder foundations.

The optional `comparison` table records changed and unchanged skeleton slots plus immutable base score, adjusted score, and cohesion movement relative to the previous completed report. v1.9.0.3 reports remain valid and simply lack novelty fields.

## Immutability boundary

Snapshot construction deep-copies supported primitive fields. The report never retains references to mutable preview state, beam nodes, source rows, or worker tables. Later item hydration, cache invalidation, rerolls, and scans cannot rewrite an existing report.

## Format changes

A future incompatible diagnostic format increments `QuestChronicle.Diagnostics.FORMAT_VERSION`. Incompatible diagnostic history may be discarded without changing any other Quest Chronicle data.

## v1.9.0.5 optional fields

Diagnostic format 1 adds optional `lineageID`, `generationToken`, `parentCompletedReportID`, and stable reserved `sequence` fields. Comparisons may include an `excluded` list for Hidden, Locked, or Unavailable anchors. Existing v1.9.0.3 and v1.9.0.4 reports remain readable without these fields.


## v1.9.0.7 contextual support fields

Diagnostic format 1 adds an optional `support` table. Older reports remain valid and display `Contextual support data: Not recorded by this version`.

The support snapshot contains only immutable selected decisions and aggregate counters:

```lua
support = {
    version = 1,
    profile = {
        activeAnchors = {},
        activeAnchorCount = 4,
        meanAnchorCohesion = 0.68,
        strongestRelationship = {},
        weakestRelationship = {},
        centers = {},
        tolerance = {},
        confidence = {},
    },
    startingBudget = 10.75,
    lockedCommitment = 0,
    generatedSpend = 0,
    borrowed = 0,
    overrun = 0,
    remainingBudget = 10.75,
    configurationScore = 0,
    wholeOutfitCohesion = 0,
    controlledAccents = 0,
    outliers = 0,
    fallbackSlots = 0,
    emptySlots = 0,
    chosenRank = 1,
    shortlistSize = 6,
    poolSizes = {},
    expansions = {},
    retained = {},
    deduplicated = 0,
    budgetRejections = 0,
    decisions = {},
    excluded = {},
}
```

Each decision stores the selected slot and stable appearance identity plus role, profile fit, neighbor cohesion, bridge target and improvement, mismatch cost, budget state, outlier state, repeat penalty, lock state, fallback state, and recorded score. Candidate pools, beam nodes, source tables, and mutable budget objects are never persisted.

Support comparisons add changed, unchanged, and excluded support slots plus immutable mismatch, whole-outfit cohesion, and outlier-count movement. A contextual-support legacy fallback may store `supportFallbackReason` on the report without changing the diagnostic format version.

## v1.9.0.8 support-reroll ancestry and fields

Diagnostic format 1 adds optional dual ancestry fields:

```lua
{
    parentCompletedReportID = "QCDBG-...",
    anchorSourceReportID = "QCDBG-...",
    previousAnchorSourceReportID = "QCDBG-...",
    performedAnchorSelection = false,
    anchorPhase = "REUSED",
}
```

`parentCompletedReportID` identifies the immediately previous completed visible outfit. `anchorSourceReportID` identifies the most recent report that actually completed Phase B anchor selection. A support-only reroll deep-copies the anchor source's skeleton and beam snapshots so rank, base score, adjusted score, cohesion, and score ledger remain immutable. Support-only actions cannot become anchor sources or advance repeated-foundation warning sequences.

The optional support-reroll snapshot fields include target slot, previous target identity and cost, replacement cost, budget before and after, fixed-context count, and no-alternative state. Support decisions may mark `contextFixed`, `targetRerolled`, or `noAlternative`. Relationship diagnostics use `Bridge improvement` only when the recorded delta exceeds `0.005`; otherwise the relationship is reported without a bridge claim.

## v1.9.0.9 canonical profile identity and timing fields

Diagnostic format 1 adds optional immutable Phase C profile fields without changing the format number:

```lua
support = {
    profileID = "QCPROFILE-...",
    profileSourceReportID = "QCDBG-...",
    profileReused = true,
    profileRepaired = false,
    profileMigrated = false,
    profileRepairReason = nil,
    profileBasisConsistent = true,
    profileAdjustment = 0,
    expectedBudgetAfter = 1.23,
    budgetReconciled = true,
    profile = {
        version = 2,
        activeAnchorMask = {
            CHEST = { state = "ACTIVE", ... },
            LEGS = { state = "LOCKED", ... },
            SHOULDER = { state = "HIDDEN", ... },
            WEAPON = { state = "ACTIVE", ... },
        },
        activeAnchorMaskSignature = "...",
        descriptor = { ... },
        entries = { ... },
    },
}
```

The active-anchor mask is authoritative. `HIDDEN` and `UNAVAILABLE` anchors contribute zero profile weight even when their appearance identity remains available in the preview. Support-only rerolls reuse a version-2 profile whose mask signature matches the current anchor snapshot. Legacy or malformed snapshots are rebuilt once and record their repair or migration state.

Persisted profile entries retain only slot, label, weight, and source/visual identity. The aggregate immutable descriptor, tolerance, confidence, relationship ledger, and canonical mask contain the scoring basis; redundant per-entry descriptor copies are omitted to keep maximum-detail reports below the 20 KB persistence limit.

Support-reroll mismatch snapshots additionally store full-precision `budgetBefore`, `previousTargetCost`, `replacementCost`, `profileAdjustment`, `expectedBudgetAfter`, and `budgetAfter`. A healthy inherited profile has a zero adjustment, and the worker verifies reconciliation before atomically committing the target appearance.

Performance snapshots may add:

```lua
performance = {
    supportRerollTiming = true,
    preWorkerPreparationMs = 6.4,
    longestWorkerSliceMs = 2.9,
    largestCooperativeCallPhase = "rerollCandidatePreparation",
    largestCooperativeCallMs = 0.7,
}
```

The Overview labels pre-worker preparation, longest cooperative worker slice, and largest cooperative call separately. Commit and UI presentation phases remain visible in the detailed phase table but do not masquerade as cooperative worker work.


## v1.9.0.10 launch and role fields

Support-only reroll performance snapshots add `synchronousLaunchPreparationMs` while retaining `preWorkerPreparationMs` as a compatibility alias. New phases include `rerollLaunchManifest`, `rerollAnchorSnapshotReuse`, `rerollStateMaterialization`, and `rerollDiagnosticFoundation`. The legacy `rerollStateCapture` phase is rendered only for older reports.

Support decisions store role text resolved from the immutable active-anchor mask. Hidden or unavailable Shoulders therefore produce Chest-only Head and Back roles and relationship endpoints.

## v1.9.0.11 scheduling and weapon-index fields

Diagnostic format 1 remains unchanged. Performance snapshots may add compact weapon-index telemetry:

```lua
performance = {
    weaponIndex = {
        format = 1,
        state = "PARTIAL",
        use = "COLD_BUILD" | "PARTIAL_WARM" | "WARM" | "INCREMENTAL_REPAIR" | "NONE",
        buckets = 3,
        examined = 240,
        yields = 30,
        builds = 3,
        repairs = 1,
        reused = 4,
        invalidationReason = nil,
    },
}
```

Support-reroll performance phase tables may contain the decomposed keys:

```text
rerollDiagnosticIdentity
rerollAnchorSummary
rerollAnchorSnapshotReuse
rerollStateMaterialization
rerollStyleContextInit
rerollStyleContextSeed
rerollEligibilityContext
rerollSupportSummaryFoundation
rerollCacheSummaryFoundation
```

The historical `rerollDiagnosticFoundation` phase remains renderable for older reports but is not emitted by v1.9.0.11. Weapon diagnostics distinguish `weaponAppearance` lookup from `weaponIndexBuild`, `weaponIndexRepair`, and `weaponIndexLookup` work. The index snapshot stores only aggregate counters and readiness state; subtype source arrays are transient and never persisted inside diagnostic history.

## Scheduler diagnostics added in v1.9.0.12

Completed generation and contextual-reroll snapshots may include an additive `scheduler` table:

```lua
{
    expensiveCallYields = 0,
    phaseTransitionYields = 0,
    preventedPhaseTransitions = 0,
    postExpensiveCallContinuations = 0,
    maximumSliceDebtMs = 0,
}
```

These values describe execution only and never participate in candidate ranking or selection. Healthy actions keep `postExpensiveCallContinuations` at zero.

Cache diagnostics store scalar counter snapshots rather than references to persistent cache tables. Human-readable invalidation ordering and optional zero-value lines are produced lazily by the report renderer.

## Weapon-index action snapshot

Weapon index format 1 may contribute:

```lua
{
    stateBefore = "STALE",
    stateAfter = "PARTIAL",
    use = "COLD_BUILD",
    bucketsBuilt = 1,
    bucketsRepaired = 0,
    bucketsReused = 0,
    examinedThisAction = 240,
    yieldsThisAction = 30,
    invalidationReason = "LOGIN_SESSION_RESET",
    lifetimeBuckets = 1,
    lifetimeExamined = 240,
    lifetimeYields = 30,
}
```

Action-local values are immutable. Lifetime values are captured at completion and do not change when the session index later grows.

## Weapon-index invalidation action semantics in v1.9.0.13

The action-local `invalidationReason` field is always present:

```lua
invalidationReason = "LOGIN_SESSION_RESET" -- cold or partial build after reload
invalidationReason = "NONE"                -- warm reuse with no new invalidation
invalidationReason = "UNKNOWN"             -- only an unclassified fallback
```

The active lifecycle cause remains attached to the transient session index so all buckets built during the same cold/partial sequence report the same cause. Warm actions do not inherit that historical label. When `UNKNOWN` is emitted, `invalidationUnknownFallback = true` may also be stored and the completed report receives an `UNKNOWN_WEAPON_INDEX_INVALIDATION` warning.
