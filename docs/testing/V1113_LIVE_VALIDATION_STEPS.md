# Quest Chronicle v1.11.3 Retail Live Validation Steps

## Purpose

Validate the first authoritative Zone anchor policy while confirming that eligibility, visual cohesion, legal weapon topology, novelty, locks, hidden state, and the legacy support pipeline remain intact.

## 1. Install and reload

1. Back up the current Quest Chronicle addon folder if desired.
2. Install `QuestChronicle-v1.11.3.zip` so the top-level addon folder is exactly `QuestChronicle`.
3. Enter Retail and use `/reload`.
4. Open Status & Maintenance and confirm:

```text
Quest Chronicle 1.11.3
```

No SavedVariables migration, cache reset, wardrobe rescan, or Courier-format change should occur.

## 2. Architecture identity

Run:

```text
/qc zone debug export
```

Copy the export and confirm:

```text
Traveler implementation: SHARED_FRAMEWORK
Zone Native implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Zone anchor policy: ZONE_ANCHOR_POLICY_V1
Zone anchor authority: ACTIVE
Zone support policy: LEGACY
Class Fantasy implementation: LEGACY
Chronicle Echo implementation: LEGACY
Zone debug export format: 3
Zone affinity format: 2
```

`DIAGNOSTIC_ESCAPE_V1` and literal `\u007C` descriptor separators must remain intact.

## 3. Zone Native generation

In a well-resolved zone such as Netherstorm, perform:

```text
Generate Outfit
Generate Outfit
Reroll Unlocked
```

For every action, confirm:

- the action completes without a Lua error;
- `Generation implementation: LEGACY` remains truthful;
- `Zone anchor policy: ZONE_ANCHOR_POLICY_V1` and `ACTIVE` appear;
- `Zone support policy: LEGACY` appears;
- `Fallback: None`, unless an explicit compatibility fallback is reported and explained;
- the action snapshot fingerprint is present;
- legal weapon routes are preserved;
- the Zone Anchor Policy report section is present;
- selected anchors include legacy relevance, affinity, confidence, adjustment, and final relevance;
- support generation, final validation, and repair still report their established behavior.

## 4. Local-evidence behavior

Inspect the selected anchors and candidate-pool summaries. No predetermined outfit is required.

Confirm:

- locally supported evidence can produce a positive bounded adjustment;
- known off-zone evidence can produce a bounded negative adjustment;
- unknown or zero-confidence evidence produces `+0.00` adjustment;
- lower-confidence evidence produces a smaller adjustment than equivalent full-confidence evidence;
- era validity alone is not described as local evidence;
- visual hard clashes remain rejected rather than cleared by Zone support;
- policy adjustments remain within their documented slot-scaled bounds.

Current constants are:

```text
Neutral affinity:       0.35
Affinity scale:         20.00
Maximum candidate bonus: +8.00 before slot multiplier
Maximum candidate penalty: -6.00 before slot multiplier
Full-confidence point:  0.65
Maximum pair support:   +4.00
```

## 5. Legal weapon bundles

When available, generate at least one one-hand or linked bundle and one two-hand bundle.

Confirm:

- all routes are legal under the existing equipment topology;
- the report identifies the route family;
- linked or two-handed presentations of one visual receive one logical Zone affinity contribution;
- distinct weapon visuals remain independently analyzed;
- no ranged appearance leaks into a melee route;
- shields and holdables appear only on previously legal routes;
- physical Main Hand and Off Hand labels remain correct.

## 6. Locks and hidden state

1. Lock one visible anchor.
2. Hide one optional anchor, such as Shoulders when available.
3. Generate and use Reroll Unlocked.

Confirm:

- the locked anchor remains unchanged;
- the locked low-affinity appearance is analyzed but never rejected merely for affinity;
- the hidden slot remains hidden;
- hidden anchors do not participate in Zone local averages or pair support;
- repair and reroll behavior preserve both states.

## 7. Context-staleness protection

When practical, begin a Zone Native generation near a meaningful zone boundary and cross it before completion.

Expected result:

- the action cancels clearly;
- the previous preview remains unchanged;
- one cancellation report records the original and current fingerprints.

If the Retail boundary timing cannot be exercised reliably, mark this test **Not exercised in Retail**. The packaged deterministic harness already verifies changed-fingerprint cancellation, unchanged-fingerprint commit, and atomic preview preservation.

## 8. Traveler regression

Perform:

```text
Traveler Generate Outfit
Traveler Reroll Unlocked
Traveler contextual support reroll
```

Confirm:

- Traveler remains `SHARED_FRAMEWORK`;
- no Zone policy section leaks into Traveler reports;
- legal weapons, Phase D validation, repair, contextual rerolls, locks, hidden state, and scheduler integrity remain intact;
- `Fallback: None` unless an established Traveler fallback is explicitly reported.

## 9. Class and Echo regression

Generate one outfit in each mode:

```text
Class Fantasy
Chronicle Echo
```

Confirm both remain `LEGACY`, complete normally, and contain no Zone anchor-policy fields.

## 10. Performance

For Zone Native actions, confirm:

```text
Longest worker slice below 8 ms
Largest Zone anchor-policy call below 8 ms
0 post-expensive continuations
No synchronous launch stall
```

Also confirm there is no extra wardrobe scan, repeated candidate pass, repeated phase, or expanded legal weapon-route enumeration.

## 11. Export and reload

After Zone generation:

1. run `/qc zone debug export`;
2. copy the complete dossier externally;
3. use `/reload`;
4. run the export again.

Confirm:

- export format 3 persists;
- copy fidelity remains intact;
- selected mode and preview persist as before;
- report history remains readable;
- no cache reset or wardrobe rescan occurs;
- no duplicate Zone suggestion appears;
- policy identity and legacy support boundary remain correct.

## Pass criteria

```text
Version and architecture identity: PASS
Zone anchor policy authority: PASS
Local-evidence behavior: PASS
Legal weapon topology: PASS
Logical weapon deduplication: PASS
Locks and hidden state: PASS
Context staleness: PASS or Not exercised in Retail with automated PASS
Traveler regression: PASS
Class and Echo regression: PASS
Performance: PASS
Export and reload: PASS
Lua errors: 0
```
