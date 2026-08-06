# Quest Chronicle v1.11.3 Automated Validation

## Reference baseline

Quest Chronicle v1.11.3 was built directly from the final live-validated v1.11.2 package whose SHA-256 is:

```text
d2286798cc0fadbd1d8612b7d3a56db3a1f9152419c38bcb89037595cc39d88c
```

## Executable Lua regression suite

```text
91 / 91 tests passed
```

The inherited 85-test suite remains green. Six new v1.11.3 tests are:

```text
test_zone_anchor_policy_v1113.lua
test_anchor_policy_bridge_v1113.lua
test_zone_anchor_weapon_dedup_v1113.lua
test_zone_context_staleness_v1113.lua
test_zone_anchor_report_v1113.lua
test_zone_anchor_selection_v1113.lua
```

They verify:

- authoritative Zone policy identity and callback completeness;
- shared bridge compatibility fallback for modes without an anchor policy;
- bounded evidence adjustments and neutral unknown evidence;
- candidate reordering when legacy factors are otherwise equal;
- preservation of favorite and locked-state semantics;
- one logical affinity contribution for linked or two-handed weapon visuals;
- immutable action context and atomic stale-context cancellation;
- selected-anchor, pair-channel, pool, route, and policy-boundary diagnostics;
- no additional random calls while Zone affinity changes candidate priority.

## Python static verifiers

```text
31 / 31 verifiers passed
```

The new `verify_zone_anchor_policy_v1113.py` checks:

- exact v1.11.3 metadata and TOC order;
- `ZONE_ANCHOR_POLICY_V1`, format 1, and `ACTIVE` authority;
- truthful overall `LEGACY` identity and legacy support boundary;
- one immutable context snapshot per action;
- commit-time fingerprint validation before any live-state commit;
- candidate, pair, skeleton, novelty, and logical-weapon callback wiring;
- bounded coefficients and single ownership of policy constants;
- zero random calls in Zone evidence, affinity, bridge, and policy modules;
- no `ZONE_NATIVE` branch embedded in shared anchor search mechanics;
- report, export-format-3, copy-fidelity, and performance instrumentation;
- unchanged support, validation, repair, reroll, route, scheduler, and Traveler modules.

## Runtime syntax and hygiene

```text
145 / 145 runtime Lua modules parsed successfully
145 / 145 TOC modules listed exactly once
0 Lua files at or above 500 physical lines
Largest runtime Lua file: Core/ZoneStyle/SourceMetadata.lua, 499 lines
```

## Protected-module parity

Byte-identical checks preserve the following policy boundaries:

```text
ZoneStyle/Scoring.lua
ZoneStyle/Zone/Affinity.lua
Wardrobe/SupportProfile.lua
Wardrobe/SupportBudget.lua
Wardrobe/SupportRoleResolver.lua
Wardrobe/SupportScoring.lua
Wardrobe/SupportBeam.lua
Wardrobe/SupportFinalValidation.lua
Wardrobe/SupportRepair.lua
Wardrobe/SupportReroll.lua
Wardrobe/AppearanceRoutes.lua
Wardrobe/WeaponPipeline.lua
Wardrobe/GenerationScheduling.lua
Traveler/AnchorPolicy.lua
Traveler/SupportPolicy.lua
Traveler/ValidationPolicy.lua
```

## Automated result

```text
Automated validation: PASS
Package readiness: PASS
Retail validation: Pending
```
