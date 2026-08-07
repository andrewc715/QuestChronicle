# Quest Chronicle v1.11.9 Retail Live Validation Steps

## Install

1. Exit World of Warcraft completely.
2. Replace the existing Quest Chronicle addon folder with the `QuestChronicle` folder from `QuestChronicle-v1.11.9.zip`.
3. Start Retail and log into the validation character.
4. Confirm Quest Chronicle reports version `1.11.9`.
5. Set generation mode to Zone Native and remain in one zone for the full performance sequence.

## 1. Watchdog safety smoke test

Run `/reload`, then Generate Outfit once.

Stop immediately and report the result if any of these occur:

- `script ran too long`
- Lua error
- multi-second worker slice
- era synchronous progress-guard warning
- era same-slice deferred-retry warning
- diagnostic report rejection

## 2. Cold Generate Outfit

Open the new Debug History report and record:

- longest worker slice;
- largest instrumented call;
- maximum slice debt;
- post-expensive continuations;
- era execution mode;
- era deferred returns;
- era same-slice deferred retries;
- era synchronous progress-guard trips;
- largest era subphase.

Required cold gates:

- longest worker slice < 16.0 ms;
- largest instrumented call < 16.0 ms;
- post-expensive continuations = 0;
- same-slice deferred retries = 0;
- synchronous progress-guard trips = 0.

Design target: largest era subphase < 4.0 ms.

## 3. Three consecutive warm Reroll Unlocked actions

Without reloading, changing zone, specialization, equipment topology, or collection state, run Reroll Unlocked three times.

Every run must satisfy:

- longest worker slice < 8.0 ms;
- largest instrumented call < 8.0 ms;
- maximum slice debt <= 2.0 ms;
- post-expensive continuations = 0;
- same-slice deferred retries = 0;
- synchronous progress-guard trips = 0;
- no performance warning;
- no diagnostic rejection.

All three runs must pass.

## 4. Zone debug export

Run `/qc zone debug export` and save the output.

Confirm:

- Zone debug export format 4;
- `ZONE_ANCHOR_POLICY_V1` / `ACTIVE`;
- correct latest policy-bearing report lineage;
- Era execution boundary reports the cooperative mode;
- same-slice deferred retries = 0;
- synchronous guard trips = 0;
- support scheduling and weapon capability sections remain healthy.

## 5. Contextual support-slot reroll

Reroll one contextual support slot. Confirm the report persists, anchor/profile ancestry is reused as expected, and no era integrity warning appears.

## 6. Legacy individual reroll smoke test

Reroll one individual anchor or weapon slot. The known legacy synchronous latency is outside this release's closure gate, but there must be no era `DEFERRED` spin and no script watchdog error.

## Pass decision

v1.11.9 passes only when the watchdog safety requirements, cold gate, all three warm gates, export lineage, contextual reroll, and legacy smoke test all pass.
