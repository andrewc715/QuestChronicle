# Quest Chronicle v1.10.0 Cross-Version Parity Report

## Baseline

```text
Quest Chronicle v1.9.0.15
SHA-256: 9090655fb8bbec7170698df2b45caae499bdde4da8df67ae6e9dcf32ad49ec66
```

## Runtime diff boundary

The v1.9.0.15 baseline contains 99 runtime Lua modules.

```text
91 existing modules remain byte-identical
8 existing modules changed
26 shared-framework modules were added
125 runtime modules are listed in v1.10.0
```

Changed existing runtime files:

```text
Core/Chronicle/Foundation.lua
Core/Diagnostics/ReportFormatter.lua
Core/Diagnostics/SnapshotBuilder.lua
Core/Wardrobe/GenerationWorker.lua
Core/Wardrobe/SupportReroll.lua
Core/Wardrobe/SupportRerollWorker.lua
UI/Outfits/AppearanceBrowser.lua
UI/Outfits/Layout.lua
```

No Traveler descriptor, cohesion, mismatch, anchor search, support scoring, support beam, final validation, repair, weapon route, cache, or scheduler formula file changed.

## Difference classifications

### VERSION_ONLY

- package version metadata;
- runtime version fallback;
- release documentation.

### ADDITIVE_FRAMEWORK_DIAGNOSTIC

- immutable reports may include `Generation implementation: SHARED_FRAMEWORK` or `LEGACY`;
- transient shared action IDs and states are exposed through `GetCurrentGenerationState()`.

### ADDITIVE_FRAMEWORK_ROUTING

- Outfits UI actions route through `QuestChronicle.Generation`;
- Traveler jobs enter the shared phase state machine;
- contextual support rerolls attach to the shared lifecycle;
- Zone, Class, and Echo enter the original worker path through explicit adapters.

### TIMING_ONLY

No deterministic timing difference is expected. Wall-clock measurements may vary in Retail as before.

### SEMANTIC

```text
None found by automated validation.
```

## Parity categories

| Category | Automated result |
|---|---|
| Traveler selection parity | PASS |
| Traveler score-provider parity | PASS, provider modules byte-identical |
| Traveler repair parity | PASS, Phase D modules and fixtures unchanged |
| Traveler reroll parity | PASS, inherited reroll fixtures plus shared routing test |
| Traveler scheduler parity | PASS, scheduler modules byte-identical and deterministic phase counts matched |
| Curated descriptor parity | PASS, all six overrides and guardrails unchanged |
| Legacy Zone parity | PASS, explicit adapter calls original path |
| Legacy Class parity | PASS, explicit adapter calls original path |
| Legacy Echo parity | PASS, explicit adapter calls original path |
| Report and cache parity | PASS, formats unchanged; implementation marker is additive |

## Deterministic orchestration fixture

The shared Traveler and original orchestration paths were run with the same state, candidate pools, random seed, and worker budget.

```text
Chest source: 105 on both paths
Legs source: 204 on both paths
Worker steps: 4 on both paths
Candidate counts: identical
Selected armor counts: identical
Phase call counts: identical
```

## Retail status

Automated parity is complete. In-game Retail validation remains required for the client-facing gates in `V1100_LIVE_VALIDATION_STEPS.md`.
