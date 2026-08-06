# Quest Chronicle v1.11.0 Retail Live Validation Steps

## Goal

Confirm that the new Zone context and evidence foundation works in Retail while Zone Native generation remains behaviorally unchanged and truthfully reports `LEGACY`.

## 1. Install and reload

1. Back up the existing `QuestChronicle` addon folder and SavedVariables.
2. Install the v1.11.0 package.
3. Log in or use `/reload`.
4. Open Quest Chronicle and confirm:

```text
Version: 1.11.0
Traveler implementation: SHARED_FRAMEWORK
Zone Native implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Class Fantasy implementation: LEGACY
Chronicle Echo implementation: LEGACY
```

Confirm no cache-reset or migration warning appears.

## 2. Detailed Outland context

In Netherstorm, run:

```text
/qc zone debug
```

Confirm:

- location facts identify Netherstorm and the Outland map ancestry;
- style profile is Outland;
- provenance pool is Netherstorm;
- era ceiling is Through TBC;
- identity, era, and provenance resolution ancestry is visible;
- no fallback is falsely reported;
- evidence coverage and snapshot fingerprint are readable;
- the selected-look affinity summary is bounded and does not change the preview.

## 3. Exact-profile context

Visit Silvermoon or Eversong and run `/qc zone debug`.

Confirm:

- style profile resolves to Quel'Thalas;
- local provenance resolves correctly;
- era ceiling remains TBC;
- exact local evidence outranks broad Eastern Kingdoms evidence;
- no automatic outfit generation occurs.

## 4. Explicit fallback

Visit an area without a dedicated broad profile.

Confirm:

- the intended regional or Azeroth fallback appears;
- fallback level and reason are explicit;
- the diagnostic does not claim exact local evidence;
- Zone Native generation remains available.

## 5. Zone Native generation parity

Select Zone Native and perform:

```text
Generate Outfit
Generate Outfit
Reroll Unlocked
Reroll one armor slot
```

Confirm:

- every report says `Generation implementation: LEGACY`;
- every report includes `Zone foundation: CONTEXT_EVIDENCE_V1`;
- familiar Zone Native weighting and variety remain intact;
- legal weapon routes remain intact;
- locks and hidden slots are preserved;
- no unexpected fallback or Lua error appears;
- additive Zone sections do not crowd out core report data;
- performance remains comparable to v1.10.0.

## 6. Zone suggestion lifecycle

Cross into a new zone.

Confirm:

- exactly one Zone Native suggestion appears;
- the preview does not change automatically;
- Traveler generation does not consume the suggestion;
- Zone Native generation consumes it;
- tab and ready-state behavior remain unchanged;
- moving between subzones does not create duplicate suggestions.

## 7. Favorites and exclusions

Favor one eligible appearance and exclude another in the current zone.

Confirm:

- the favorite retains its strong legacy weight;
- the exclusion never generates;
- both remain scoped to the current zone key;
- changing zones does not leak either preference;
- returning restores them.

## 8. Eligibility and provenance

In an Outland zone, inspect:

- a later-expansion appearance;
- a foreign TBC boss or tracked quest source;
- a promotional appearance;
- a manually previewable but auto-generation-ineligible appearance.

Confirm all v1.10.0 eligibility and manual-preview behavior remains unchanged.

## 9. Cross-mode isolation

Generate once in Traveler, Class Fantasy, and Chronicle Echo.

Confirm:

```text
Traveler        SHARED_FRAMEWORK
Class Fantasy   LEGACY
Chronicle Echo  LEGACY
```

Confirm Zone evidence does not alter their outputs and none consumes a pending Zone suggestion.

## 10. Reload persistence

Use `/reload`.

Confirm:

- selected mode and preview persist;
- concepts, favorites, and exclusions persist;
- Debug History persists as before;
- no cache reset occurs;
- the Zone snapshot rebuilds cleanly;
- no duplicate suggestion appears merely because the session snapshot was reconstructed.

## Pass criteria

The Retail gate passes when all ten sections succeed with:

```text
Zone Native implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Unexpected selection changes: None
Unexpected fallbacks: None
Lua errors: None
Repeatable performance regression: None
```
