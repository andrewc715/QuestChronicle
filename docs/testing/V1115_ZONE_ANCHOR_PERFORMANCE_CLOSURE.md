# Quest Chronicle v1.11.5 Zone Anchor Performance Closure

## Source findings addressed

The v1.11.4 Retail batch recorded:

```text
Cold Generate Outfit: 33.9 ms worker slice
weaponStyleEligibility: 8.7 ms
Warm Reroll Unlocked: 9.4 ms worker slice
Weapon context: 6.1 ms
```

v1.11.5 addresses the two structural causes identified in the approved plan.

## Cooperative eligibility contract

```text
Marker batch: 4
Eligibility traversal: reverse candidate order
Coherence: exactly once after eligibility completion
Scoring traversal: forward retained order
Random draws: exactly one per retained candidate
Sort: descending stylePriority
```

The work object yields between bounded eligibility steps and between coherence/scoring operations. It does not use the synchronous million-marker drain in the weapon ordering path.

## Capability snapshot contract

```text
First action request: build or reuse session snapshot
Later finalists in action: reuse attached snapshot
Explicit route invalidation: increment capability generation and clear snapshot
Commit: compare captured generation with current generation
Stale result: cancel atomically and preserve previous preview
TTL alone: not an authority boundary
```

## Frozen scheduler constants

```text
Preferred slice: 5.5 ms
Soft ceiling: 7.5 ms
Expensive-call threshold: 2.0 ms
Phase-transition reserve: 1.0 ms
```

No budget was raised.

## Automated status

```text
Bounded-step fixtures: PASS
Ordering and RNG parity: PASS
Capability build/reuse: PASS
Explicit invalidation: PASS
Stale commit cancellation: PASS
Post-expensive continuation static guards: PASS
```

## Retail closure gates

Cold Zone Generate Outfit must show:

```text
Longest worker slice < 16.0 ms
Largest instrumented call < 16.0 ms
Capability builds this action <= 1
Capability stale at commit: NO
Post-expensive continuations: 0
```

Three consecutive warm Reroll Unlocked actions must each show:

```text
Longest worker slice < 8.0 ms
Largest instrumented call < 8.0 ms
Maximum slice debt <= 2.0 ms
Capability snapshot: REUSED
Capability builds this action: 0
Capability stale at commit: NO
Post-expensive continuations: 0
```

These thresholds require Retail timing evidence and remain pending until live validation.
