# Quest Chronicle v1.11.6

## Adaptive diagnostic-budget guarantee

The first Retail v1.11.5 Zone generation completed successfully but its diagnostic report still exceeded the 20,480-byte persistence ceiling after fixed compaction. v1.11.6 replaces that brittle boundary with deterministic adaptive tiers.

### Fixed

- Reports are measured with the same serialized representation used by persistence.
- Compaction advances through duplicate removal, reconstructible-detail removal, summary-table collapse, mandatory-core rebuilding, and an emergency stub only as needed.
- Valid generation reports no longer vanish merely because optional diagnostic detail is large.
- The emergency stub retains action identity, Zone policy, selected anchors, weapon capability and scheduler summaries, support and Phase D outcomes, warnings, and the final message.
- Existing compacted reports are stabilized and remeasured when Debug History is pruned.

### Diagnostics

Every compacted report records:

```text
compaction format
compaction tier and label
original serialized bytes
final serialized bytes
emergency-stub state
```

The copy report displays the same persistence summary in **Warnings and Fallback**.

### Preserved

- diagnostic format 1 and the 20,480-byte per-report ceiling;
- `ZONE_ANCHOR_POLICY_V1` authority and coefficients;
- weapon capability, cooperative ordering, and stale-commit behavior from v1.11.5;
- all generation, support, repair, reroll, lock, hidden-slot, cache, SavedVariables, and Courier behavior.
