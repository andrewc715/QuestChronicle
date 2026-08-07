# Quest Chronicle v1.11.11 Retail Live Validation Steps

## Install

1. Exit World of Warcraft.
2. Replace the existing Quest Chronicle addon folder with the `QuestChronicle` folder from `QuestChronicle-v1.11.11.zip`.
3. Launch Retail and log into the test character.
4. Confirm Quest Chronicle reports version `1.11.11`.
5. Run `/reload` once before the cold test.

Do not change zone, specialization, equipped weapon topology, hidden slots, or locked slots between the cold test and the three warm rerolls unless a step below explicitly asks for it.

## Test 1: cold Zone Native Generate Outfit

Generate one Zone Native outfit immediately after `/reload`.

Record the full diagnostic report.

Required hard gates:

- result Completed;
- no Lua error or `script ran too long`;
- total preparation time <=10.0 sec;
- longest worker slice <16.0 ms;
- largest pure anchor candidate subphase <4.0 ms;
- largest support bridge subphase <4.0 ms;
- era phantom deferrals = 0;
- era same-slice deferred retries = 0;
- era synchronous guard trips = 0;
- scheduler post-expensive continuations = 0;
- diagnostic persistence succeeds without rejection.

Also confirm the new lines are present:

- `Anchor candidate scheduling`;
- `Largest anchor candidate subphase`;
- `Support bridge scheduling`;
- `Largest support bridge subphase`.

## Test 2: three consecutive warm Reroll Unlocked actions

Without `/reload`, changing zone, or changing equipment, run Reroll Unlocked three consecutive times.

Every single run must satisfy:

- total preparation time <=6.0 sec;
- longest worker slice <8.0 ms;
- largest instrumented call <8.0 ms;
- maximum slice debt <=2.0 ms;
- largest pure anchor candidate subphase <4.0 ms;
- largest support bridge subphase <4.0 ms;
- post-expensive continuations = 0;
- era phantom deferrals = 0;
- era same-slice deferred retries = 0;
- era synchronous guard trips = 0;
- no Quest Chronicle performance warning;
- no diagnostic persistence rejection.

Preferred total time is <=5.0 sec per warm reroll.

For a warm action with zero era API work, require zero era API headroom/fresh-only deferrals.

A 2/3 warm pass is a release failure. All three must pass.

## Test 3: format-4 Zone export

Run:

`/qc zone debug export`

Confirm:

- Zone debug export format remains `4`;
- `ZONE_ANCHOR_POLICY_V1` remains `ACTIVE`;
- latest policy-bearing report lineage is correct;
- current context is not stale at commit;
- anchor candidate scheduling counters are visible;
- support bridge counters are visible;
- era integrity counters remain zero;
- weapon capability lifecycle remains truthful.

## Test 4: contextual support-slot reroll

Reroll one unlocked contextual support slot.

Require:

- action completes without changing the anchor skeleton;
- cooperative worker slice <8.0 ms;
- no watchdog or performance warning;
- fixed contextual slots remain fixed;
- budget reconciliation passes;
- report persists successfully.

## Closure decision

v1.11.11 closes the current Zone anchor-policy performance train only when the cold action, all three warm actions, format-4 export, and contextual support reroll pass together.
