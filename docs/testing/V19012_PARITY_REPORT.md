# Quest Chronicle v1.9.0.12 Selection-Parity Report

The exact v1.9.0.11 release tree and v1.9.0.12 were executed through deterministic harnesses.

Byte-for-byte standard output matched for:

- Anchor beam search
- Mode identity
- Anchor novelty selection
- Anchor worker integration
- Contextual support profile and budget
- Contextual support reroll behavior
- Legacy generation selection
- Weapon pipeline

Three benchmark harnesses intentionally reported different frame counts or maximum synthetic slice values because v1.9.0.12 changes scheduling boundaries. After removing timing-only fields, their semantic outputs matched exactly:

- Anchor pipeline benchmark: 112 candidates, 2,096 beam expansions, 80 weapon yields
- Contextual support worker: eight selected slots, cohesion `0.889`, remaining budget `8.47`
- Contextual support benchmark: 256 prepared candidates, 5,408 expansions, rank `3/6`

A dedicated cross-version support-reroll dump matched byte for byte:

```text
WAIST:10021:9.376000:0.491563:2:6
HEAD:40022:7.268000:0.541250:1:6
BACK:50045:5.328000:0.629062:2:6
HANDS:20021:3.984000:0.665000:2:6
```

Each row contains target slot, selected appearance, generated mismatch spend, whole-outfit cohesion, chosen rank, and shortlist size.

The release changes continuation boundaries, scalar diagnostic capture, full-generation setup staging, adaptive batch sizes, and weapon-index reporting only.
