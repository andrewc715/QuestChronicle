# Quest Chronicle v1.11.2 Retail Live Validation Steps

## Purpose

Validate the copy-fidelity and coverage-aware affinity corrections without changing Zone Native generation behavior.

## 1. Install and reload

1. Back up the current Quest Chronicle addon folder if desired.
2. Install `QuestChronicle-v1.11.2.zip` so the top-level addon folder is exactly `QuestChronicle`.
3. Enter Retail and use `/reload`.
4. Open Status & Maintenance and confirm:

```text
Quest Chronicle 1.11.2
```

No SavedVariables migration, wardrobe rescan, cache reset, or Courier-format change should occur.

## 2. Architecture and format identity

Run:

```text
/qc zone debug export
```

Copy the selected text and confirm the header reports:

```text
Traveler: SHARED_FRAMEWORK
Zone Native: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
Class Fantasy: LEGACY
Chronicle Echo: LEGACY
Zone debug export format: 2
Zone affinity format: 2
Dynamic value encoding: DIAGNOSTIC_ESCAPE_V1
Literal pipe representation: \u007C
```

## 3. External copy fidelity

In Netherstorm, copy the complete export with `Ctrl+C` and paste it into an external plain-text or Markdown destination.

Confirm:

- no descriptor character disappears after a slot key;
- descriptor separators appear as `\u007C`;
- item-link-like, texture-like, and color-like values remain plain diagnostic text;
- no value is converted into a hyperlink, texture, color span, or missing-character sequence;
- Markdown tables retain their columns;
- the complete evidence ancestry remains present.

Healthy examples include:

```text
HEAD\u007CTemplar Crown
BACK\u007CRoyal Cloak
CHEST\u007CReplica Lightforge Breastplate
FEET\u007CHeavy Lamellar Boots
```

## 4. Applicability semantics

In the canonical Zone evidence section, confirm:

```text
avoids: NOT_APPLICABLE
```

For every current-look affinity piece, confirm:

```text
avoids: NOT_APPLICABLE
N/A channels: avoids
```

Also confirm `avoids` does not appear in that piece's missing-channel list.

## 5. Numeric parity

When the same Netherstorm snapshot and outfit remain visible from v1.11.1, require:

```text
Selected visible pieces: 12
Mean affinity: 0.291
Mean confidence: 0.536
OFF_ZONE_SIGNAL: 5
PARTIAL_EVIDENCE: 2
WEAK_LOCAL_SIGNAL: 5
```

Per-piece score, confidence, and classification values should remain unchanged. Only transport encoding and applicability labels may differ.

## 6. Latest Zone report

Generate one Zone Native outfit, then rerun:

```text
/qc zone debug export
```

Confirm the latest Zone Native diagnostic-report section now contains a report and still identifies:

```text
Generation implementation: LEGACY
Zone foundation: CONTEXT_EVIDENCE_V1
```

## 7. Observational neutrality

Before and after invoking the export, confirm:

- the current preview is unchanged;
- no generation or reroll starts;
- no new Debug History report is created by export alone;
- locks and hidden slots remain unchanged;
- no Zone suggestion is consumed;
- Courier readiness and snapshot size are unchanged;
- no Lua error appears.

## 8. Reload compatibility

Use `/reload`, then rerun the export.

Confirm:

- the Zone snapshot reconstructs cleanly;
- export format 2 and affinity format 2 remain reported;
- older retained Zone reports remain viewable;
- no migration, cache reset, or wardrobe rescan occurs.

## Pass criteria

```text
Version and architecture identity: PASS
External copy fidelity: PASS
NOT_APPLICABLE semantics: PASS
Numeric affinity parity: PASS
Latest Zone report availability: PASS
Observational neutrality: PASS
Reload compatibility: PASS
Lua errors: 0
```
