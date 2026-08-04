# Quest Chronicle v1.9.0.13

## Weapon-Index Invalidation Lifecycle

Quest Chronicle now reports the canonical cause of each weapon candidate-index lifecycle transition without carrying an old invalidation label into later warm actions.

- Reports `LOGIN_SESSION_RESET` for the session-only index after reload and preserves it through the cold and partial bucket-build sequence.
- Reports `NONE` for warm reuse and other actions that did not process a new invalidation.
- Assigns explicit reasons for automatic login refresh, manual wardrobe-cache replacement, collection revision changes, newly collected appearances, and character capability changes.
- Infers canonical reasons when the wardrobe-cache identity or character identity changes before an explicit invalidation call.
- Emits an `UNKNOWN_WEAPON_INDEX_INVALIDATION` warning only when a caller omits the reason or supplies an unrecognized reason.
- Preserves v1.9.0.12 candidate ordering, selections, scores, weapon routes, cooperative scheduling, phase transitions, and scheduler diagnostics.
- Keeps SavedVariables schema 2, Courier format 1, wardrobe cache format 7, generation-cache store 2, diagnostic format 1, and weapon-index format 1 unchanged.

The package is automated-validated and requires Retail validation before replacing v1.9.0.12 as the live baseline.
