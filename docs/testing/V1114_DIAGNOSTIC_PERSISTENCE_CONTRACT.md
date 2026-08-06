# Quest Chronicle v1.11.4 Diagnostic Persistence Contract

## Identity

```text
Diagnostic format: 1
Per-report ceiling: 20,480 bytes
History ceiling: 204,800 bytes
Maximum reports: 10
```

## Ownership

```text
Core/Diagnostics/ReportCompaction.lua
  sizing
  ordered compaction
  REPORT_TRIMMED warning
  Zone duplicate removal

Core/Diagnostics/History.lua
  validation
  duplicate rejection
  insertion and pruning
  counters
  visible persistence-failure reporting
```

## Authoritative Zone facts

A persisted Zone report stores these facts once:

```text
Selected source identities            skeleton.components
Zone anchor policy result             zoneFoundation.anchorPolicy
Support reroll ancestry               support.profile.entries
Completed-outfit validation           support final-validation fields
Current full affinity dossier         rebuilt by /qc zone debug export
```

## Compaction preservation

Every accepted compacted report retains:

- report identity, lineage, parent report, and anchor source;
- action, result, mode, message, character, and context;
- selected anchors and weapon identities;
- `ZONE_ANCHOR_POLICY_V1` identity and authority;
- selected Zone relevance decomposition;
- candidate-pool summaries;
- visual and Zone pair channels;
- route family and linked-visual deduplication;
- aggregate current-look affinity;
- reusable support profile entries;
- support decisions and Phase D result;
- warnings and headline performance.

## Compaction removals

Only oversized reports may lose:

1. duplicated `outfit.slots`;
2. display-only profile copies;
3. item IDs duplicated by stable visual/source identities;
4. per-piece persisted Zone affinity detail;
5. per-component Zone policy calculations duplicated by the authoritative summary;
6. verbose score prose;
7. detailed phase timing and cache-reason maps at later stages.

## Failure visibility

A report that remains too large after every stage must:

```text
increment malformedReportsDiscarded
print Debug report could not be saved: <reason>
emit DIAGNOSTIC_REPORT_REJECTED
```

It must not disappear silently.
