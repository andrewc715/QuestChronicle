# Quest Chronicle v1.9.0.15a1 Implementation Conformance

## Phase E observation scope

The alpha implements only the observation stage defined by the v1.9.0.15 plan.

Implemented:

- opt-in local audit commands;
- stable visual identity aggregation with source and item fallbacks;
- linked-weapon deduplication;
- selection, anchor, support, repair, replacement, palette-overflow, zero-echo, severe, and worst-outlier evidence;
- bounded contexts and sample report IDs;
- deterministic 300-identity pruning;
- copyable Markdown export;
- confirmed clear behavior;
- failure isolation from diagnostic persistence;
- separate audit format 1 without changing the main schema.

Intentionally not implemented in a1:

- `CuratedOverrides.lua`;
- palette corrections;
- finish corrections;
- echo-only descriptor tags;
- loudness or visual-weight overrides;
- global lexicon changes;
- any direct scoring, mismatch, selection, or Phase D outcome override.

## Frozen systems

The implementation does not change Phase B, Phase C, or Phase D formulas and thresholds, candidate ordering, beam widths, novelty, mismatch budgets, repair limits, weapon routes, cache formats, Courier format, diagnostic format, or scheduler budgets.
