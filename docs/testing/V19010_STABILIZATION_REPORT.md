# Quest Chronicle v1.9.0.10 Final Phase C Stabilization Report

## Scope

v1.9.0.10 removes the last synchronous support-reroll snapshot bottleneck and corrects Head and Back role wording when Shoulders are hidden or unavailable. It intentionally does not retune Phase B, weapons, mismatch costs, bridge weights, support pools, shortlist sizes, or outfit naming.

## Implementation

- `SupportRerollLaunch.lua` creates a primitive launch manifest containing the target identity, profile identity, style mode, generation token, and preview revision.
- `SupportRerollWorker.lua` now materializes report ancestry, draft state, profile references, support context, and diagnostic foundations across cooperative phases.
- Diagnostic parent and anchor-source records are pinned for the worker lifetime and released on completion, cancellation, or failure.
- Workbench revision and target identity are validated before materialization, during worker execution, and before atomic commit.
- `SupportRoleResolver.lua` resolves Head and Back labels and relationship endpoints from the canonical active-anchor mask.
- Timing reports now distinguish synchronous launch preparation from cooperative materialization and scoring.
- Fast read-only diagnostic history lookups avoid repeatedly pruning the bounded store during reroll startup.

## Synthetic result

```text
Target: Head
Cooperative frames: 72
Synchronous launch preparation: 0.08 ms
Candidate pool: 30 or fewer in the test fixture
Final shortlist: 6
Hidden Shoulder relationship endpoint: excluded
Stale revision commit: cancelled
```

The broader 32-candidate stress harness completed across 95 frames with a 0.52 ms maximum synthetic worker slice.

## Selection boundary

Healthy v1.9.0.9 rerolls and v1.9.0.10 selected identical Waist, Head, Back, and Hands appearances, finalist ranks, generated mismatch spend, and whole-outfit cohesion in the deterministic parity fixture. Full anchor, weapon, and Phase C support harnesses also matched byte for byte.

## Compatibility

```text
SavedVariables schema:  2
Courier format:         1
Wardrobe cache format:  7
Generation cache:       2
Diagnostic format:      1
```
