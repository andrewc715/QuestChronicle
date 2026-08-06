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
