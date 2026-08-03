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
    version = "1.9.0.7",
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
