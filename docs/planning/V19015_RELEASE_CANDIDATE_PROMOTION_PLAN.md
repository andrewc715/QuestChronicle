# Quest Chronicle v1.9.0.15 Release Candidate and Promotion Plan

## Release purpose

Quest Chronicle v1.9.0.15 is the promotion release for the completed Traveler Cohesion Rewrite and its first curated Phase E descriptor set.

The corrected v1.9.0.15a2 build has passed Retail validation.

The release candidate therefore exists to:

- freeze the validated curated data;
- confirm regression parity;
- remove development-only residue;
- align version and release documentation;
- verify the packaged archive;
- perform a short final Retail smoke test;
- promote without adding new tuning.

This is not another tuning batch.

```text
No new appearance overrides.
No new palette judgments.
No new finish judgments.
No new echo tags.
No scoring or scheduler changes.
```

---

# Starting point

Build the release candidate directly from the exact Retail-validated v1.9.0.15a2 source tree.

Do not rebuild from:

- v1.9.0.15a1;
- an earlier superseded a2 package;
- v1.9.0.14;
- the original provisional review vectors.

The authoritative curated set is the validated six-visual set:

| Visual ID | Appearance | Palette | Finish |
|---:|---|---|---|
| 912 | Gray Woolen Shirt | unchanged: neutral | plain 1.00 |
| 1208 | Stylish Black Shirt | unchanged: dark | plain 1.00 |
| 1051 | Hide of Lupos | dark .45, neutral .35, purple .20 | primal .75, weathered .25 |
| 1139 | Rugged Plate Vest | blue .45, steel .35, dark .20 | weathered .60, plain .40 |
| 5237 | Expedition Defender's Shoulders | green .70, steel .30 | military .80, polished .20 |
| 12877 | Orcish Scout Boots | dark .70, blue .20, steel .10 | plain .75, polished .25 |

Orcish Scout Boots must remain dark navy or blue-black and must not become green.

Sterling Chain Cloak remains deferred.

No global lexicon or echo-only correction is included.

---

# Versioning decision

Use the addon version:

```text
1.9.0.15
```

The ZIP filename may be:

```text
QuestChronicle-v1.9.0.15.zip
```

The top-level folder inside the ZIP remains:

```text
QuestChronicle
```

Release-candidate status belongs in the handoff and validation documentation, not in the in-game addon version string.

After the final smoke test passes, the exact same package is promoted without rebuilding it.

---

# Allowed source changes

The release-candidate diff from validated a2 is restricted to:

- addon version strings;
- release notes;
- changelog;
- README status;
- validation and promotion documentation;
- removal of temporary development-only hooks or comments that are proven unused;
- test metadata needed to recognize the final version.

Any runtime change requires returning to alpha validation.

## Runtime freeze

The following runtime modules should remain byte-identical to validated a2 whenever possible:

```text
Core/ZoneStyle/Traveler/CuratedOverrides.lua
Core/ZoneStyle/Traveler/Descriptors.lua
Core/ZoneStyle/Traveler/Cohesion.lua
Core/ZoneStyle/Traveler/TuningAudit.lua
Core/ZoneStyle/Traveler/TuningExport.lua
Core/Wardrobe/SupportFinalValidation.lua
Core/Wardrobe/SupportRepair.lua
Core/Wardrobe/SupportRerollWorker.lua
```

When a version constant is located inside a runtime file, only the exact version token may change.

---

# Frozen systems

The release candidate must not alter:

- the six validated visual-ID overrides;
- curated tuning version `1`;
- tuning audit format `1`;
- StyleLexicon tokens or relationship matrices;
- descriptor precedence or confidence;
- `echoPalette` defaults;
- Phase B scoring, search, novelty, or quality windows;
- Phase C profile, candidate, beam, budget, or support-role behavior;
- Phase D mismatch, severity, palette-family, echo, repair, or alternate-skeleton behavior;
- weapon routes or equipment topology;
- locks, hidden state, or atomic commit;
- random consumption;
- scheduler budgets or yield policy;
- reroll reconciliation;
- report compaction;
- cache schemas or formats;
- diagnostic format;
- Courier format;
- tuning-audit limits or commands.

---

# Release-candidate regression matrix

## 1. Exact curated-descriptor confirmation

Run the six descriptor fixtures and require exact values:

```text
Gray Woolen Shirt
palette neutral [lexicon]
finish plain 100% [curated]

Stylish Black Shirt
palette dark [lexicon]
finish plain 100% [curated]

Hide of Lupos
palette dark 45%, neutral 35%, purple 20% [curated]
finish primal 75%, weathered 25% [curated]

Rugged Plate Vest
palette blue 45%, steel 35%, dark 20% [curated]
finish weathered 60%, plain 40% [curated]

Expedition Defender's Shoulders
palette green 70%, steel 30% [curated]
finish military 80%, polished 20% [curated]

Orcish Scout Boots
palette dark 70%, blue 20%, steel 10% [curated]
finish plain 75%, polished 25% [curated]
```

Fail immediately if Orcish Scout Boots report green.

## 2. Validated-a2 parity

Run every shared deterministic harness against:

```text
validated v1.9.0.15a2
v1.9.0.15 release candidate
```

Expected differences are limited to:

- version string;
- release documentation;
- build timestamp;
- wall-clock benchmark values.

The following must remain identical:

- selected appearance IDs;
- descriptor vectors;
- curated fields and keys;
- pair and profile scores;
- Phase B skeleton rankings;
- Phase C support selections and ledgers;
- Phase D validation and repairs;
- weapon routes;
- lock and hidden preservation;
- tuning-audit aggregation;
- report compaction behavior;
- scheduler phase order and deterministic counters.

## 3. Unaffected-fixture parity

Fixtures containing none of the six curated visuals must remain semantically identical to corrected a1 and validated a2.

There must be no broad tuning spillover.

## 4. Shirt guardrails

Verify:

- Gray Woolen Shirt remains neutral;
- Stylish Black Shirt remains dark;
- both use curated plain finish;
- both remain eligible for normal palette-overflow repair;
- neither receives an exemption, protection, or direct score adjustment.

## 5. Audit regression

Verify:

```text
/qc traveler tuning start
/qc traveler tuning status
/qc traveler tuning stop
/qc traveler tuning export
/qc traveler tuning clear confirm
```

Requirements:

- completed actions count once;
- failed and cancelled actions do not count;
- curated markers remain present;
- 300-identity and sample caps remain deterministic;
- collection errors remain zero;
- audit data remains separate from Debug History and Courier.

## 6. Reroll regression

Verify:

- Reroll Unlocked remains cooperative;
- support-slot rerolls remain target-isolated;
- current-live-outfit ledger reconciliation passes;
- locks and hidden slots remain sovereign;
- parent reports are ancestry only;
- no stale-parent false failure returns.

The legacy synchronous individual anchor and weapon reroll path is not changed in this release and remains separately deferred.

## 7. Diagnostic regression

Verify:

- completed reports remain visible and copyable;
- oversized reports compact below the persistence ceiling;
- Phase D details survive compaction;
- curated markers survive compaction;
- ancestry required by support rerolls survives compaction;
- no duplicate or malformed report appears.

## 8. Performance regression

Require:

```text
No new repeated worker slice above 8 ms
No new individual curated or audit call above 8 ms
0 post-expensive continuations
No visible freeze introduced by the release candidate
```

Known deferred observations remain outside this release:

- legacy individual Chest reroll synchronous stall;
- isolated Zone Native total-slice spike.

The release candidate must neither fix nor worsen them.

---

# Full automated validation

Run:

- every Lua regression harness;
- every Python/static verifier;
- Lua syntax validation;
- TOC completeness and uniqueness;
- runtime file line-limit enforcement;
- JSON validation;
- version consistency checks;
- orphaned-helper and stale-reference checks;
- cache and schema checks;
- package extraction tests;
- ZIP compressed-data integrity;
- cross-version parity;
- SHA-256 generation.

Every runtime Lua file must remain below 500 physical lines.

---

# Documentation freeze

Update:

```text
QuestChronicle.toc
README.md
RELEASE_NOTES.md
docs/CHANGELOG.md
docs/ARCHITECTURE.md
docs/tuning/V19015_TRAVELER_TUNING_LEDGER.md
```

The release notes should distinguish:

## Phase E workflow

- opt-in bounded local tuning audit;
- stable visual-ID evidence aggregation;
- copyable tuning export.

## Curated descriptor set

- six reviewed exact visual identities;
- no global lexicon changes;
- no echo-only additions;
- corrected descriptor inputs rather than forced outcomes.

## Stability fixes carried into the release

- oversized diagnostic compaction;
- current-live-outfit reroll ledger reconciliation.

## Deferred engineering work

- legacy individual anchor and weapon reroll scheduling;
- isolated Zone Native slice investigation;
- Sterling Chain Cloak finish review;
- future curated batches.

---

# Final Retail smoke test

Because validated a2 already completed the full descriptor and ten-action Retail validation, the release candidate needs a short package-confirmation pass rather than another tuning batch.

## Step 1: Install

Install the exact release-candidate ZIP and use:

```text
/reload
```

Confirm:

```text
Version: 1.9.0.15
```

Do not perform a collection scan.

## Step 2: Curated spot checks

Run `/qc traveler debug` on:

```text
Rugged Plate Vest
Orcish Scout Boots
Expedition Defender's Shoulders
```

Expected:

```text
Rugged Plate Vest
blue 45%, steel 35%, dark 20%
weathered 60%, plain 40%

Orcish Scout Boots
dark 70%, blue 20%, steel 10%
plain 75%, polished 25%

Expedition Defender's Shoulders
green 70%, steel 30%
military 80%, polished 20%
```

## Step 3: Generation smoke test

Perform:

```text
Generate Outfit
Generate Outfit
Reroll Unlocked
Reroll one visible support slot
```

Confirm:

- reports remain visible and copyable;
- `Fallback: None`;
- no malformed or duplicate report;
- no ledger reconciliation failure;
- support reroll changes only the target;
- locks and hidden slots remain unchanged;
- `0 post-expensive continuations`;
- no new repeatable performance regression.

## Step 4: Audit smoke test

Run:

```text
/qc traveler tuning clear confirm
/qc traveler tuning start
```

Perform one completed Traveler action, then:

```text
/qc traveler tuning stop
/qc traveler tuning status
/qc traveler tuning export
```

Expected:

```text
Completed Traveler actions: 1
Collection errors: 0
```

Confirm the export is copyable and separate from normal Debug History.

---

# Promotion criteria

Promote the exact release-candidate ZIP when:

1. The source diff from validated a2 contains no unapproved runtime behavior change.
2. All six curated descriptors remain exact.
3. Orcish Scout Boots remain dark/blue/steel and never green.
4. Every shared deterministic regression passes.
5. Unaffected fixtures remain unchanged.
6. Phase B, C, and D outputs remain stable outside corrected descriptors.
7. Audit, reroll, compaction, locks, hidden state, and routes pass regression.
8. All syntax, static, TOC, line-limit, JSON, and packaging checks pass.
9. The final Retail smoke test passes.
10. The ZIP hash tested in Retail matches the promoted ZIP hash.

Do not rebuild after Retail validation.

The tested archive becomes the final release archive.

---

# Release artifacts

The final handoff should include:

```text
QuestChronicle-v1.9.0.15.zip
QuestChronicle-v1.9.0.15-Live-Validation-Steps.md
QuestChronicle-v1.9.0.15-Release-Notes.md
QuestChronicle-v1.9.0.15-Automated-Validation.md
QuestChronicle-v1.9.0.15-Parity-Report.md
QuestChronicle-v1.9.0.15-Curated-Review-Ledger.md
QuestChronicle-v1.9.0.15.sha256
```

---

# Planned commit message

```text
fix: Update Quest Chronicle to v1.9.0.15

Promote the Retail-validated Phase E curated descriptor set
Freeze six reviewed visual-ID corrections without adding new tuning
Confirm regression parity across Traveler scoring, repair, audit, and reroll systems
Preserve cache formats, routes, scheduler behavior, and diagnostic compaction
Finalize the Traveler Cohesion Rewrite for release
```
