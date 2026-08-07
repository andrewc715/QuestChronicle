# Quest Chronicle v1.11.10 Validation Report

## Package status

Automated source validation: PASS.

Retail validation: PENDING.

v1.11.10 must not be treated as the accepted Zone anchor-policy performance baseline until the live validation sequence passes in World of Warcraft.

## Automated status

The stamped source tree passes the full inherited and v1.11.10-specific wall:

- 115 / 115 Lua tests
- 38 / 38 Python verifiers
- 153 / 153 runtime Lua modules parsed
- 153 unique TOC runtime entries
- 0 runtime Lua files at or above 500 lines

The exact delivered ZIP is independently re-extracted and revalidated during handoff creation.

## Principal automated proofs

- no phantom era admission for local/cache work;
- no API deferral when no API work is required in the dedicated zero-work fixture;
- cheap API operations may share a slice;
- insufficient API headroom is immutable and cooperative;
- expensive API calls still force-yield;
- resumable support candidate decisions match the synchronous oracle;
- partial candidate work cannot mutate the beam;
- fallback ties preserve first-best strict-lower behavior;
- 768-candidate synthetic support workload remains below the 4.0 ms subphase target.

## Retail blockers

Any of the following rejects v1.11.10:

- `script ran too long`;
- Lua error;
- same-slice era deferred retry above zero;
- synchronous era progress-guard trip above zero;
- phantom era deferral above zero;
- zero era API work accompanied by era API deferrals;
- diagnostic report rejection;
- cold or warm worker-slice gate failure;
- warm maximum slice debt above 2.0 ms;
- cold total duration above 10 seconds;
- any warm total duration above 6 seconds;
- a warm performance warning.
