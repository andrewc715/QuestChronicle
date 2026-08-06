# Quest Chronicle v1.11.1 Retail Live Validation Steps

## Goal

Confirm that `/qc zone debug export` opens a complete copy-ready Zone snapshot without changing the selection-neutral v1.11.0 Zone foundation or any generation behavior.

## 1. Install and reload

1. Back up the existing `QuestChronicle` addon folder and SavedVariables.
2. Install the v1.11.1 package.
3. Log in or use `/reload`.
4. Open Status & Maintenance and confirm `Quest Chronicle 1.11.1`.
5. Confirm no migration, cache-reset, or wardrobe-rescan warning appears.

## 2. Preserve compact chat diagnostics

Run:

```text
/qc zone debug
```

Confirm the existing compact chat summary still appears and includes:

- `Zone foundation: CONTEXT_EVIDENCE_V1`;
- current location and map ancestry;
- style profile, era, and provenance;
- restriction and fallback state;
- evidence coverage;
- selected-look affinity;
- registry counts and snapshot fingerprint.

## 3. Open the copy-ready export

Run:

```text
/qc zone debug export
```

Confirm:

- Quest Chronicle opens to the Debug tab;
- the copy dialog title is `Copy Zone Debug Export`;
- the complete Markdown text is selected automatically;
- `Ctrl+C` copies the entire export;
- closing the dialog returns to the Debug Workbench normally.

## 4. Confirm architecture identities

The export must contain:

```text
Quest Chronicle version: 1.11.1
Traveler: SHARED_FRAMEWORK
Zone Native: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Class Fantasy: LEGACY
Chronicle Echo: LEGACY
```

The exact presentation is a Markdown table, but all identities must be present and truthful.

## 5. Confirm complete Zone snapshot

In a known zone such as Netherstorm, confirm the export contains:

- snapshot fingerprint and capture time;
- zone, subzone, map ID, map name, and map trail;
- profile key, label, description, resolution level, and confidence;
- era identity and confidence;
- provenance identity and confidence;
- restriction, favorite scope, exclusion scope, and fallback state;
- profile, provenance, starting-zone, era-rule, context, and affinity format versions;
- registry counts and compatibility parity.

## 6. Confirm untruncated evidence ancestry

Compare the compact `/qc zone debug` output with the export.

Confirm:

- the export includes every evidence entry, not only the first eight;
- each entry includes channel, subject, value, matched text, alias, source level, confidence, and registry key;
- evidence warnings, when present, are included;
- no `additional entries omitted` line appears in the export.

## 7. Confirm canonical style evidence

Confirm the export contains all ten channels:

```text
culture
climate
terrain
palette
material
finish
motif
magic
silhouette
avoids
```

Each channel must include its coverage state and complete signal map.

## 8. Confirm current-look affinity

With a visible outfit selected, confirm the export contains:

- selected-piece count;
- mean affinity and confidence;
- classification totals;
- one row per visible selected piece;
- appearance name, source ID, visual ID, classification, score, confidence, and missing channels;
- per-piece palette, material, finish, motif, culture, magic, avoidance, and provenance components;
- descriptor fingerprint and evidence ancestry.

## 9. Confirm latest Zone report summary

Generate one Zone Native outfit, then rerun `/qc zone debug export`.

Confirm the export includes the latest Zone Native report ID, time, action, result, generation implementation, Zone foundation, snapshot fingerprint, compatibility parity, recorded affinity, and message.

## 10. Confirm observational neutrality

Before and after opening the export, confirm:

- the preview does not change;
- no outfit generation or reroll starts;
- no random-looking selection change occurs;
- locks and hidden slots remain unchanged;
- no Zone suggestion is consumed;
- no new Debug History report is created merely by exporting;
- Courier output is unchanged;
- no Lua error appears.

## 11. Cross-mode and reload checks

1. Generate once in Traveler, Zone Native, Class Fantasy, and Chronicle Echo.
2. Confirm their implementation identities remain unchanged.
3. Use `/reload`.
4. Rerun `/qc zone debug export`.
5. Confirm the snapshot reconstructs cleanly and the copy dialog still works.

## Pass criteria

```text
Version:                              1.11.1
Compact /qc zone debug:              PASS
Copy-ready debug export:             PASS
Complete evidence ancestry:          PASS
Per-piece Zone affinity:             PASS
Generation identities:               PASS
Preview and selection neutrality:    PASS
SavedVariables or Courier changes:   None
Lua errors:                           None
```
