# Quest Chronicle v1.11.6 Parity Report

## Baseline

```text
Baseline: Quest Chronicle v1.11.5
Target:   Quest Chronicle v1.11.6
```

## Intentional differences

```text
VERSION_ONLY
- package metadata and fallback version become 1.11.6

DIAGNOSTIC_PERSISTENCE
- exact serialized size is checked after deterministic compaction tiers
- large reports may retain progressively smaller optional detail
- emergency and minimal action stubs replace silent loss of valid reports
- compaction tier, original size, final size, and emergency state are reported
```

## Frozen generation contract

No intentional differences are permitted in:

- candidate eligibility or ordering;
- random consumption;
- Zone affinity or anchor-policy coefficients;
- selected anchor skeletons or legal weapon routes;
- capability-snapshot or cooperative weapon behavior;
- contextual support, Phase D validation, repair, or rerolls;
- locks, hidden slots, favorites, exclusions, or atomic commit;
- SavedVariables, cache formats, Courier, Traveler, Class Fantasy, or Chronicle Echo.


## Runtime boundary

```text
144 inherited runtime modules byte-identical
4 inherited runtime modules changed
1 Diagnostics runtime module added
0 runtime modules removed
```

The only generation-facing runtime change is the fallback version string in `Core/Chronicle/Foundation.lua`. All behavioral changes are contained within `Core/Diagnostics`.
