# Quest Chronicle v1.11.3

## Zone Anchor Policy v1

Quest Chronicle v1.11.3 activates the first explicit Zone generation policy.

Zone Native continues through its legacy outer lifecycle, support policy, validation, repair, and reroll paths, but its anchor preference is now owned by `ZONE_ANCHOR_POLICY_V1` through the shared anchor-policy bridge.

### Evidence-driven anchor preference

Every Zone Native action captures one immutable Zone Context Snapshot and uses it throughout candidate, pair, weapon-bundle, novelty, and diagnostic work. Affinity v2 contributes a bounded preference adjustment to the existing continuity score:

```text
Neutral affinity:       0.35
Scale:                 20.00
Maximum bonus:          +8.00
Maximum penalty:        -6.00
Full-confidence point:   0.65
Pair-support cap:        +4.00
```

Chest and Shoulders use a 1.00 prominence multiplier, Legs use 0.90, and logical weapons use 1.10. Unknown and zero-confidence evidence remain neutral.

### Protected mechanics

The policy cannot change eligibility, provenance, era, promotional or Heritage restrictions, hard-clash state, legal weapon topology, locks, hidden slots, novelty classes, or support thresholds. It adds no random calls and performs no second candidate pass.

Linked or two-handed presentations receive one logical Zone affinity contribution for the same visual. Distinct weapon visuals remain independently analyzed.

### Atomic context safety

Before commit, the current Zone snapshot fingerprint is compared with the action fingerprint. A material context change cancels the action and preserves the previous preview.

### Diagnostics

Zone debug export advances to format 3 and records policy identity, authority, selected score decomposition, candidate-pool aggregates, pair-support channels, logical weapon deduplication, support-policy boundary, context staleness, and policy timing. `DIAGNOSTIC_ESCAPE_V1` and Affinity format 2 remain unchanged.

### Compatibility

- Traveler remains `SHARED_FRAMEWORK` with semantic parity.
- Zone Native remains `LEGACY` overall with `ZONE_ANCHOR_POLICY_V1` active.
- Class Fantasy and Chronicle Echo remain `LEGACY` and unchanged.
- Zone Context Snapshot remains format 1.
- Zone Affinity remains format 2.
- SavedVariables, Courier, wardrobe cache, generation cache, diagnostic format, and weapon index remain unchanged.
- No migration or cache reset is required.


# Quest Chronicle v1.11.2

## Zone debug export fidelity and applicability semantics

Quest Chronicle v1.11.2 corrects the copy-ready Zone debug dossier without changing Zone Native selection behavior.

### Lossless diagnostic transport

`/qc zone debug export` now declares export format 2 and encodes arbitrary dynamic values with `DIAGNOSTIC_ESCAPE_V1` before they enter WoW's copy EditBox. Literal pipes are represented as `\u007C`, preventing `|T`, `|H`, `|c`, `|r`, and related WoW formatting tokens from consuming descriptor characters. Backslashes, backticks, carriage returns, and line feeds also use deterministic reversible representations.

Markdown table structure remains readable, while descriptor fingerprints, evidence values, names, registry keys, messages, and other dynamic fields remain character-complete after external paste.

### Coverage-aware Zone affinity format 2

Every per-piece Zone affinity component now has one explicit state:

```text
VALUE
MISSING
NOT_APPLICABLE
```

`NOT_APPLICABLE` is neither positive evidence nor missing evidence. It contributes no score weight, no confidence weight, and no missing-channel warning. Profiles whose canonical `avoids` channel is not applicable now report it honestly in a separate N/A list.

The existing affinity arithmetic is frozen. The first Netherstorm Retail fixture remains `0.291` mean affinity, `0.536` mean confidence, with five `OFF_ZONE_SIGNAL`, two `PARTIAL_EVIDENCE`, and five `WEAK_LOCAL_SIGNAL` pieces.

### Compatibility

- Zone Context Snapshot remains format 1.
- Zone foundation remains `CONTEXT_EVIDENCE_V1`.
- Zone Native remains `LEGACY` and selection-neutral.
- Traveler remains `SHARED_FRAMEWORK`.
- Class Fantasy and Chronicle Echo remain `LEGACY`.
- Format-1 affinity records remain readable through display-time normalization.
- SavedVariables schema remains 2.
- Courier format remains 1.
- Wardrobe cache remains format 7.
- No migration, cache reset, wardrobe rescan, scoring change, or UI redesign is required.
