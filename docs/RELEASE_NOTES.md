# Quest Chronicle v1.11.3 Release Notes

Quest Chronicle v1.11.3 makes the live-validated Zone evidence foundation authoritative for anchor preference through `ZONE_ANCHOR_POLICY_V1`.

Zone Native still reports `Generation implementation: LEGACY`, because support, final validation, repair, and rerolls remain on their existing paths. The release changes only eligible anchor preference and its diagnostics. Shared visual cohesion, hard clashes, legal weapons, novelty, locks, hidden slots, eligibility, provenance, era, promotional exclusions, Heritage restrictions, and random-call counts remain protected.

The policy uses one immutable Zone Context Snapshot per action, bounded Affinity v2 adjustments, bounded pair support, and one logical affinity contribution for linked weapon visuals. A changed Zone fingerprint cancels the action before atomic commit.

`/qc zone debug export` now uses format 3 and includes policy identity, authority, selected score decomposition, pool aggregates, pair-support channels, weapon deduplication, context-staleness state, policy timing, and the explicit `Zone support policy: LEGACY` boundary.

Retail validation is required before promotion to live-validated status.


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
