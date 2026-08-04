# Quest Chronicle v1.9.0.13 Implementation Conformance Report

## Plan boundary

The rebuild began from the original v1.9.0.12 release archive. The earlier v1.9.0.13 package was used only as a comparison specimen and was not used as the branch baseline.

## Implemented requirements

| Planned requirement | Implementation result |
|---|---|
| Assign canonical reasons at every lifecycle transition | Explicit reasons are supplied by login scans, manual scans, collection events, capability events, debug resets, repairs, and defensive identity inference. |
| Report `NONE` when no invalidation was processed | Warm reuse, idle actions, and invalidation-only actions report `NONE`. |
| Report `LOGIN_SESSION_RESET` after reload | The transient index begins each addon session with `LOGIN_SESSION_RESET`. |
| Preserve the reason through cold and partial builds | The lifecycle reason remains attached to the index while missing subtype buckets are constructed, even when warm reuse occurs between builds. |
| Warn only for a genuine `UNKNOWN` fallback | The warning gate checks the final action-local reason and fires only for `UNKNOWN`. |
| Verify cold, partial, and warm behavior | Dedicated tests cover cold to warm to partial to warm, plus the direct cold to partial to warm path. |
| Preserve v1.9.0.12 generation behavior | All 56 shared Lua harnesses retained semantic parity; 55 matched byte for byte and one differed only in measured benchmark time. |
| Avoid scheduler surgery | No scheduler, worker-budget, selection, scoring, route-resolution, support, or commit module changed. |

## Runtime files changed

```text
Core/Chronicle/Foundation.lua
Core/Diagnostics/Comparison.lua
Core/Wardrobe/CollectionScanAndPreview.lua
Core/Wardrobe/EquipmentTopology.lua
Core/Wardrobe/Events.lua
Core/Wardrobe/WeaponCandidateIndex.lua
```

`Foundation.lua` changes only the fallback version string. The remaining files implement the planned diagnostic lifecycle and reason forwarding.

## Additional edge corrected during rebuild

The focused lifecycle suite found that an implicit format, character, or wardrobe identity change could rebuild an empty index while the pre-action snapshot still contained old buckets. Without an additional sequence check, that full rebuild could be mislabeled `PARTIAL_BUILD`.

The final implementation treats a build accompanied by a newly detected invalidation sequence as `COLD_BUILD`. This affects diagnostics only and does not alter bucket contents, routes, scoring, scheduling, or selections.
