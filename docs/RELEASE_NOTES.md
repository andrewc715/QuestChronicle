# Quest Chronicle v1.9.0a1 — Traveler Cohesion Calibration

v1.9.0a1 calibrates Phase A of the Traveler Cohesion Rewrite. It changes only the read-only diagnostics. Traveler candidate selection, random generation, rerolls, and outfit commitment remain unchanged from the validated v1.8.5 generation path.

## Calibrated mismatch accounting

The analyzer now distinguishes intrinsic loudness from outfit impact:

```text
visual impact = intrinsic loudness × slot prominence
```

A vivid belt or wrist piece can therefore be visually noticeable without carrying the same outfit-level weight as a chest, shoulder, head, or weapon appearance.

Mismatch costs are now fractional:

- Cohesive: `0.00`
- Supported Variation: `0.00`
- Mild: `0.50 × slot prominence`
- Supported strong mismatch: `1.00 × slot prominence`
- Strong mismatch: `1.00 × slot prominence`
- Postal-code outlier: reported separately rather than charged to the budget

A piece with at least 65% profile cohesion, or at least 65% accent echo, is normally treated as Supported Variation at zero cost unless it remains a high-impact clash.

## Linked weapon analysis

Matching linked Main Hand and Off Hand selections are now analyzed as one Weapon Pair block. The two physical selections remain visible in Current Preview, but the diagnostics no longer charge the same visual twice or double-weight it in the anchor profile.

## Evidence-based explanations

The debug output now names the actual evidence behind each classification:

- strongest visual bridge
- weakest compatibility component
- dominant accent
- accent echo support
- raw loudness
- slot-weighted visual impact

Generic explanations such as “weathered mismatch” are no longer emitted when the descriptor evidence does not support that claim.

## Command

Run after generating a Traveler outfit:

```text
/qc traveler debug
```

The report now includes both selected appearance count and analysis-block count, fractional mismatch budget use, Supported Variation count, and per-block raw loudness versus effective visual impact.

## Compatibility

- Addon version: `1.9.0a1`
- SavedVariables schema: `2`
- Courier format: `1`
- Wardrobe cache format: `7`
- No wardrobe rescan or migration required
- Every runtime Lua file remains under 500 lines
