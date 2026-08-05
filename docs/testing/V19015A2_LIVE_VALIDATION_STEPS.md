# Quest Chronicle v1.9.0.15a2 Live Validation Steps

## Goal

Confirm the six reviewed descriptors are correct in Retail and that ordinary Traveler generation still follows the unchanged Phase B, Phase C, and Phase D rules.

## 1. Install

1. Replace the QuestChronicle addon folder with v1.9.0.15a2.
2. Use `/reload`.
3. Confirm the addon reports version `1.9.0.15a2`.

A collection scan should not be required. The curated tuning version invalidates only Traveler descriptor-cache entries.

## 2. Inspect the six reviewed descriptors

Use the Appearance Browser to select each appearance in its normal slot, then run:

```text
/qc traveler debug
```

Expected curated lines:

```text
Gray Woolen Shirt
palette neutral [lexicon]
finish plain 100% [curated]
override visualID 912

Stylish Black Shirt
palette dark [lexicon]
finish plain 100% [curated]
override visualID 1208

Hide of Lupos
palette dark 45%, neutral 35%, purple 20% [curated]
finish primal 75%, weathered 25% [curated]
override visualID 1051

Rugged Plate Vest
palette blue 45%, steel 35%, dark 20% [curated]
finish weathered 60%, plain 40% [curated]
override visualID 1139

Expedition Defender's Shoulders
palette green 70%, steel 30% [curated]
finish military 80%, polished 20% [curated]
override visualID 5237

Orcish Scout Boots
palette dark 70%, blue 20%, steel 10% [curated]
finish plain 75%, polished 25% [curated]
override visualID 12877
```

The boots must not report green.

## 3. Verify ordinary Debug reports

Generate one Traveler outfit and copy its report.

Confirm:

- selected reviewed appearances show a compact `Curated tags:` marker;
- the report remains visible, selectable, and copyable;
- there is no full override vector duplicated into every report;
- there is no fallback, malformed-report warning, or ledger reconciliation failure.

## 4. Focused ten-action batch

Run:

```text
/qc traveler tuning clear confirm
/qc traveler tuning start
```

Complete ten Traveler actions using a mixture of:

```text
Generate Outfit
Reroll Unlocked
Reroll one visible support slot
```

Then run:

```text
/qc traveler tuning stop
/qc traveler tuning status
/qc traveler tuning export
```

Expected:

- exactly 10 completed actions;
- at least one visual identity;
- 0 collection errors;
- no cancelled or failed action counted;
- curated appearances in the audit show `Curated: palette`, `Curated: finish`, or `Curated: palette, finish`;
- ordinary Debug reports remain separate from the tuning export.

## 5. Behavioral guardrails

These outcomes are valid:

- Gray Woolen Shirt or Stylish Black Shirt may still be replaced for palette-family overflow.
- A reviewed appearance may score differently or be selected differently because its descriptor is now accurate.
- Phase D may repair a reviewed appearance when the completed outfit genuinely violates an unchanged gate.

These outcomes are failures:

- either shirt changes dominant palette;
- Orcish Scout Boots report green;
- a reviewed item becomes forced, protected, or exempt from Phase D;
- a lock or hidden slot changes unexpectedly;
- a support-only reroll changes a non-target support slot;
- a report disappears, becomes uncopyable, or exceeds persistence limits without compaction;
- fallback, malformed report, collection error, or ledger reconciliation failure appears.

## Return

Return:

1. the six `/qc traveler debug` descriptor lines;
2. the final ten-action tuning export;
3. one full Debug report containing at least one curated appearance;
4. screenshots only if a rendered appearance contradicts its curated descriptor or an outfit looks visibly wrong.
