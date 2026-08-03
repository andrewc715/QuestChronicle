# Quest Chronicle v1.9.0.7 Live-Test Checklist

Install v1.9.0.7 over the live-validated v1.9.0.5 build without deleting `QuestChronicleDB`. Allow the automatic wardrobe scan to finish before generating.

Keep v1.9.0.5 available as the immediate fallback while Phase C is being validated.

## A. Baseline Traveler generation

1. Select **Traveler** mode.
2. Make Chest, Legs, Shoulders, weapons, and all visible support slots unlocked.
3. Click **Generate Outfit**.
4. Open `/qc debug` and copy the report.

Confirm:

- The Phase B Chest, Legs, Shoulders, and weapon bundle are legal and coherent.
- `Contextual Support` is present.
- The profile lists the active anchors and descriptor centers.
- Every available visible support slot appears exactly once.
- The budget starts at the sum of active-slot allowances, normally 10.75 for all eight support slots.
- Locked commitment plus generated spend plus remaining budget reconciles with the starting budget.
- No support operation exceeds 8 ms; no operation exceeds 12 ms under any circumstance.

## B. Generate Outfit novelty

1. Click **Generate Outfit** twice more.
2. Copy both reports.

Confirm:

- Phase B novelty still behaves like v1.9.0.5.
- Unlocked support pieces receive soft repeat pressure rather than hard exclusion.
- A strong bridge piece may remain, but the report records its repeat penalty.
- Waist connects Chest and Legs.
- Hands make sense beside both Chest and the weapon bundle.
- Feet continue the lower silhouette.
- Head and Back do not become unrelated visual outliers.
- Controlled accents are possible without accumulating multiple loud clashes.

## C. Reroll Unlocked

1. Click **Reroll Unlocked**.
2. Copy the report.

Confirm:

- Current unlocked anchors and support appearances are excluded where alternatives exist.
- Locked and hidden slots remain untouched.
- Phase C derives a fresh profile from the new anchor skeleton.
- The report contains one immutable support configuration, not a mixture of the old and new outfits.

## D. Contextual single-slot rerolls

1. Reroll **Waist**.
2. Reroll **Head**.
3. Copy both reports.

Confirm:

- Only the requested support slot changes.
- All unrelated selections remain identical.
- The current appearance is hard-excluded when a legal alternative exists.
- The new Waist is scored against Chest and Legs.
- The new Head is scored against Chest, visible Shoulders, and any fixed Back appearance.
- Each report records the selected rank, budget state, bridge relationship, mismatch spend, and outlier state.

## E. Locked support adaptation

1. Lock **Back**.
2. Generate Outfit.
3. Lock **Hands** as well.
4. Generate Outfit again.

Confirm:

- Locked Back and Hands never change, even when they are imperfect matches.
- Both locked pieces appear as committed support decisions.
- Their mismatch costs appear under `locked` commitment rather than generated spend.
- Remaining unlocked support slots adapt around those choices.
- Locked choices are never rejected or silently cleared.

## F. Hidden slots and active-anchor changes

1. Hide **Head** and generate.
2. Unhide Head, hide **Shoulders**, and generate again.

Confirm:

- Hidden Head is omitted from active support slots and consumes no Head allowance.
- Hidden Head is listed under `Excluded` and never appears as changed or unchanged.
- Hidden Shoulders reduce the contextual profile's active logical anchors from four to three.
- Head and Back bridge scoring omits hidden Shoulders instead of consulting their old preview appearance.
- No hidden slot creates mismatch spend, repeat pressure, or outlier warnings.

## G. Mixed locked and hidden state

1. Keep Chest locked.
2. Keep Shoulders hidden.
3. Keep one support piece locked.
4. Generate Outfit.

Confirm:

- Phase B comparisons exclude locked Chest and hidden Shoulders correctly.
- Phase C profile still includes visible locked Chest.
- Hidden Shoulders contribute zero profile weight.
- The support budget and active-slot list reconcile.
- The final report contains no duplicate or contradictory slot states.

## H. Persistence and report ancestry

1. Use `/reload`.
2. Allow the scan to finish.
3. Generate one Traveler outfit.
4. Open `/qc debug`.

Confirm:

- Existing v1.9.0.5 reports remain readable and say contextual data was not recorded.
- New Phase C reports survive `/reload`.
- The newest report compares against the actual previous completed report.
- Historical support mismatch, cohesion, and outlier values match their original reports.
- One action creates exactly one report.
- Duplicate and malformed report counters remain zero.

## I. Custom Set regression

1. Save the generated Quest Chronicle concept.
2. Export it to a Blizzard Custom Set.
3. Read the saved set back through Quest Chronicle.

Confirm:

- The native recipe matches the final visible Phase C preview.
- No protected Outfit slot is touched.
- No transmog is applied and no gold is spent.

## Retail promotion criteria

v1.9.0.7 may become the new live baseline when:

- Phase B anchors remain consistent with v1.9.0.5 behavior.
- Support choices look contextual across several Traveler generations.
- Single-slot rerolls remain isolated.
- Locked and hidden states are truthful.
- Every budget ledger reconciles.
- No Phase C instrumented call exceeds 8 ms in normal use.
- No Phase C call exceeds 12 ms.
- No report exceeds the diagnostic storage limit or disappears after creation.
