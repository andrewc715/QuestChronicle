# Quest Chronicle v1.11.1

## Copy-ready Zone debug export

Quest Chronicle v1.11.1 adds a complete, copyable Zone foundation snapshot while preserving the selection-neutral v1.11.0 Zone context and evidence architecture.

### New command

```text
/qc zone debug export
```

The command opens the Debug Workbench copy dialog with a selected Markdown export containing:

- Quest Chronicle version and all four generation implementation identities;
- Zone foundation and format versions;
- validated registry counts and profile-alias collisions;
- the complete immutable Zone Context Snapshot;
- canonical culture, climate, terrain, palette, material, finish, motif, magic, silhouette, and avoidance evidence;
- the full evidence ledger without the eight-entry chat truncation;
- current-look Zone affinity summary and per-piece components;
- source, visual, descriptor, profile, and provenance identities;
- the latest Zone Native diagnostic-report summary.

The existing command remains unchanged:

```text
/qc zone debug
```

It continues to print the compact chat summary.

### Runtime identity

```text
Traveler        SHARED_FRAMEWORK
Zone Native     LEGACY • CONTEXT_EVIDENCE_V1
Class Fantasy   LEGACY
Chronicle Echo  LEGACY
```

### Selection neutrality

The export is read-only and session-only. It does not:

- enumerate generation candidates;
- call Zone scoring or selection;
- consume random values;
- start generation or rerolls;
- modify the preview;
- write SavedVariables;
- change Courier output;
- change caches, locks, hidden slots, favorites, exclusions, or suggestions.

### Compatibility

- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache remains format 7.
- Zone Context Snapshot remains format 1.
- Zone affinity remains format 1.
- No migration, cache reset, wardrobe rescan, or UI redesign is required.
