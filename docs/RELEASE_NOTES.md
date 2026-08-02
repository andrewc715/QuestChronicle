# Quest Chronicle v1.9.0a — Traveler Cohesion Instrumentation

## Purpose

v1.9.0a is Phase A of the Traveler Cohesion Rewrite. It adds observation and explanation tools without changing how Traveler outfits are selected.

## Added

- Coarse style descriptors for palette, material, finish, motif, visual weight, and loudness.
- Confidence-weighted compatibility calculations so unknown style metadata remains neutral rather than creating false clashes.
- The planned pairwise cohesion formula:
  - 40% palette
  - 22% material
  - 14% finish
  - 10% visual weight
  - 9% motif
  - 5% provenance
- Anchor-profile analysis using chest, legs, shoulders, and the active weapon presentation.
- Diagnostic mismatch classifications:
  - Cohesive
  - Mild weathered mismatch
  - Strong supported mismatch
  - Strong mismatch
  - Postal-code outlier
- A two-point diagnostic mismatch budget.
- `/qc traveler debug` to explain the current outfit piece by piece.

## Deliberately unchanged

- Traveler candidate pools and weighted selection.
- Slot generation order.
- Existing native-set and motif coherence logic.
- Zone, Class, and Chronicle Echo generation.
- Weapon Appearance Routes.
- Wardrobe cache format 7.
- SavedVariables schema 2 and Courier format 1.

The new scores are advisory in v1.9.0a. They do not reject, reroll, or replace any appearance yet.
