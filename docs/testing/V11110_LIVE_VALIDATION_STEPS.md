# Quest Chronicle v1.11.10 Retail Live Validation Steps

## Install

1. Exit World of Warcraft.
2. Replace the existing Quest Chronicle addon folder with the `QuestChronicle` folder from `QuestChronicle-v1.11.10.zip`.
3. Launch Retail and log into the validation character.
4. Confirm Quest Chronicle reports version `1.11.10`.
5. Enter the intended Zone Native validation location and run `/reload` once before the cold test.

Do not reload, change zone, change specialization, or alter equipment between the three warm rerolls unless the test explicitly calls for it.

## Gate 1: cold Generate Outfit

Generate one Zone Native outfit immediately after the reload.

Stop immediately on any Lua error, `script ran too long`, diagnostic rejection, same-slice retry warning, synchronous guard warning, or phantom-deferral warning.

Record the Debug History report. Required hard gates:

- result `COMPLETED`;
- longest worker slice `< 16.0 ms`;
- largest era subphase `< 4.0 ms`;
- total prepared duration `<= 10.0 sec`;
- zero post-expensive continuations;
- zero same-slice era deferred retries;
- zero synchronous progress-guard trips;
- zero phantom era deferrals;
- diagnostic report retained beneath the persistence ceiling.

Preferred cold duration: `<= 8.0 sec`.

### Productive-deferral check

Inspect the era admission counters. Deferrals are allowed only when actual API work required headroom. A report with zero era API operations must also report zero API-headroom and fresh-only era deferrals.

## Gate 2: three consecutive warm Reroll Unlocked actions

Without reloading or changing context, run **Reroll Unlocked** three times consecutively.

Every run must independently satisfy:

- result `COMPLETED`;
- longest worker slice `< 8.0 ms`;
- largest instrumented call `< 8.0 ms`;
- maximum slice debt `<= 2.0 ms`;
- total prepared duration `<= 6.0 sec`;
- zero post-expensive continuations;
- zero performance warning;
- zero diagnostic rejection;
- zero same-slice era deferred retries;
- zero synchronous progress-guard trips;
- zero phantom era deferrals.

Preferred warm duration: `<= 5.0 sec`.

A single failed warm run rejects the three-run performance closure.

## Gate 3: support candidate closure

For all four principal actions, inspect the support scheduling lines.

Required:

- candidate substeps are recorded;
- candidate completions are recorded;
- largest support-candidate subphase `< 4.0 ms` target;
- stage finalization remains bounded;
- no evidence of partial candidate commit or incomplete support result;
- final validation remains `CLEAN` or a truthful existing Phase D repair result.

## Gate 4: Zone debug export

Run:

`/qc zone debug export`

Confirm export format remains `4` and the latest policy-bearing report contains:

- `ZONE_ANCHOR_POLICY_V1` / `ACTIVE`;
- correct snapshot and report lineage;
- era local/API operation counts;
- API admissions and headroom/fresh-only/phantom deferrals;
- source/fragment cache completions;
- execution-boundary counters;
- support candidate substeps/completions/deferrals;
- largest support-candidate subphase;
- scheduler debt and post-expensive continuation counts.

## Gate 5: contextual support-slot reroll

Reroll one contextual support slot after the performance sequence.

Confirm:

- anchor skeleton/profile reuse remains truthful;
- only the requested support slot changes unless existing final validation repairs another slot;
- the report persists;
- no watchdog, guard, phantom-deferral, or diagnostic-rejection warning occurs.

## Acceptance

v1.11.10 passes Retail only when the cold test, all three warm tests, format-4 export, and contextual support-slot smoke test all pass. The release is rejected immediately for a watchdog error or any nonzero execution-boundary integrity counter.
