# Quest Chronicle v1.11.8

Quest Chronicle records a character's quest journey, builds zone-aware outfit concepts, and exports verified Blizzard Custom Sets.

Version 1.11.8 closes the remaining era-evidence scheduling gap beneath the authoritative Zone anchor policy. Per-visual-sibling era evidence is now a resumable state machine, variable Blizzard API work starts from fresh worker slices, and stable non-pending sibling fragments can be reused during aggregate rebuilds.

## v1.11.8 focus

- resolve one bounded era-evidence operation per cooperative step;
- preserve the exact curated, set, tracking, encounter, and item evidence precedence from v1.11.7;
- require set-list, tracking, encounter-list, and item-metadata calls to begin on fresh worker slices;
- process one set record, drop record, or tier record per operation;
- cache only stable non-pending source fragments in session memory with conservative invalidation;
- keep aggregate earliest-era, pending, retry, and persistent-cache semantics unchanged;
- expose exact era subphase timing, operation counts, deferrals, sibling completions, and fragment reuse in retained diagnostics and Zone export format 4;
- keep the frozen 5.5 ms preferred slice, 7.5 ms soft ceiling, and 2.0 ms expensive-call threshold.

## Architecture boundary

```text
Traveler implementation:       SHARED_FRAMEWORK
Zone Native implementation:    LEGACY
Zone foundation:               CONTEXT_EVIDENCE_V1
Zone anchor policy:            ZONE_ANCHOR_POLICY_V1 / ACTIVE
Zone support policy:           LEGACY
Era evidence:                  COOPERATIVE_CANDIDATE_WORK_V1
Zone debug export:             4
Diagnostic format:             1
Report persistence ceiling:    20,480 bytes
```

v1.11.8 changes era-evidence execution boundaries and diagnostics only. Evidence ranks and meanings, Zone scoring, support scoring, candidate order, random consumption, weapon routes, Phase D, rerolls, locks, hidden state, SavedVariables, cache formats, Courier output, adaptive persistence, and export lineage remain unchanged.
