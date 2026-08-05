# Quest Chronicle v1.9.0.15a2 Implementation Conformance

## Approved scope

The build implements the first six exact visual-ID corrections from the reviewed Phase E ledger and nothing broader.

## Conformance

- `CuratedOverrides.lua` loads after `StyleLexicon.lua` and before `Descriptors.lua`.
- Curated fields replace lexicon fields before normalization and dominance calculation.
- Visual identity is the active correction key; item and source refinement tables remain empty.
- Curated palette and finish fields receive confidence 0.95.
- Curated tuning version 1 participates in the descriptor fingerprint.
- `echoPalette` defaults to the final ordinary palette.
- Pair cohesion, profile centers, dominant palette, and Phase D palette-family counting continue to use ordinary palette.
- Normal reports persist only compact field and identity markers.
- The local audit remains opt-in, bounded, local, and absent from Courier export.

## Non-goals honored

The build does not:

- force or suppress a selection;
- exempt any appearance from mismatch or repair;
- change repeat penalties or random consumption;
- change any Phase B, Phase C, or Phase D formula;
- alter locks, hidden state, routes, topology, scheduler behavior, or atomic commit;
- add a global lexicon rule;
- add an echo-only correction;
- change any SavedVariables or Courier format.
