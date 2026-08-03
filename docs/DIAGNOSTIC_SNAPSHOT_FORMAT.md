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
    version = "1.9.0.3",
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

The skeleton also records chosen rank, shortlist size, total score, mean pair cohesion, hard clashes, fallback reason, score breakdown, cohesion dimensions, strongest bridge, and weakest relationship when available.

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

`performance.phaseStats` stores the maximum, total, and call count already recorded by the generation pipeline. `cache` stores the generation-cache lifecycle snapshot already attached to the performance record.

The Debug tab formats these values but does not recalculate generation outcomes.

## Warnings and comparison

Warnings are derived after the generation and UI completion pipeline settles. Current warnings include performance thresholds, legacy fallback, and repeated Chest/Shoulder foundations.

The optional `comparison` table records changed and unchanged skeleton slots plus score and cohesion movement relative to the previous completed report.

## Immutability boundary

Snapshot construction deep-copies supported primitive fields. The report never retains references to mutable preview state, beam nodes, source rows, or worker tables. Later item hydration, cache invalidation, rerolls, and scans cannot rewrite an existing report.

## Format changes

A future incompatible diagnostic format increments `QuestChronicle.Diagnostics.FORMAT_VERSION`. Incompatible diagnostic history may be discarded without changing any other Quest Chronicle data.
