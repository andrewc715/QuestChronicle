# Quest Chronicle v1.11.11 Parity Report

v1.11.11 is a scheduling decomposition release. It does not intentionally alter generation answers.

## Anchor parity

`Core/ZoneStyle/Scoring.lua` is byte-identical to v1.11.10. Prepared anchor coherence and source scoring reproduce the frozen oracle exactly, including reason ordering. The cooperative candidate worker preserves descriptor-before-random ordering and uses the same Zone affinity/policy application semantics.

Weapon finalist scoring reproduces the frozen `ScoreWeaponBundleForAnchor` aggregation exactly while spreading candidate and relationship work across resumable operations.

## Support parity

`ScoreSupportCandidate()` remains the synchronous semantic oracle. The cooperative support candidate worker reproduces exact decision fields for all support slots, including neighbor cohesion, bridge before/after values, bridge bonus, budget outcome, mismatch spend, repeat penalty, score, allowed state, and fallback state.

Fallback scanning retains strict-lower first-best tie behavior.

## Frozen systems

No intentional changes were made to:

- Zone anchor policy constants or affinity coefficients;
- era evidence precedence, retry semantics, or admission policy;
- support profile rules, mismatch budgets, beam width, shortlist size, repair rules, or repeat penalties;
- weapon legal routes, capability lifecycle, or style ordering;
- random-call count/order outside the decomposed preservation boundary;
- Traveler, Class Fantasy, or Chronicle Echo behavior;
- SavedVariables, wardrobe cache, generation cache, diagnostic format, Courier format, or Zone export format.
