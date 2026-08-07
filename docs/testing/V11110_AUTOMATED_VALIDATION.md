# Quest Chronicle v1.11.10 Automated Validation

## Stamped source-tree gate

The version-stamped v1.11.10 source tree passes:

- 115 / 115 Lua regression tests
- 38 / 38 Python static verifiers
- 153 / 153 TOC runtime modules parsed by Lua 5.4 `loadfile`
- 153 unique runtime Lua entries in the TOC
- 0 missing TOC runtime files
- 0 runtime Lua files at or above 500 lines

## v1.11.10-specific fixtures

### Productive era admission

`test_era_productive_admission_v11110.lua` proves:

- no phantom frame tax for local work;
- no API admission tax for source-cache and fragment-cache completion;
- several cheap API calls can share available headroom;
- low-headroom denial is immutable;
- an admitted expensive call preserves force-yield behavior.

### Resumable support candidate

`test_support_candidate_work_v11110.lua` proves:

- exact decision parity with the synchronous support scorer;
- no partial beam commit;
- cooperative fallback preserves first-best strict-lower tie behavior.

### Synthetic support benchmark

`test_support_candidate_benchmark_v11110.lua` processes 768 synthetic candidate works with a maximum synthetic substep of 0.750 ms, below the 4.0 ms subphase target.

### Static wiring

`verify_productive_scheduling_v11110.py` verifies release identity, era admission classes, demand-aware probes, nested support-candidate integration, timing identities, headline diagnostics, Zone export formatting, and TOC load order.

## Existing regression wall

All inherited Zone context, anchor policy, support, repair, reroll, weapon, diagnostics, persistence, export, execution-boundary, and shared-framework tests remain enabled. No inherited test was removed or relaxed to accept v1.11.10.

## Exact-package gate

The release handoff repeats the complete wall from a clean extraction of the exact delivered ZIP. Retail validation is a separate gate and remains pending until performed in World of Warcraft.
