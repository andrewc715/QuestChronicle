# Quest Chronicle v0.9.1 Live Test Checklist

## Favorite toggle

1. Open Outfits, select an appearance, and note the current zone.
2. Click **Favor in Zone**.
3. Confirm the button changes to **Unfavor**, the row says **Zone favorite**, and the favored count increases.
4. Hover **Unfavor** and confirm its tooltip says it will remove the zone favorite.
5. Click **Unfavor**.
6. Confirm the button returns to **Favor in Zone**, the row marker disappears, and the favored count decreases.
7. Repeat the complete Favor → Unfavor cycle once more.

## Exclusion toggle

1. With an appearance selected, click **Exclude in Zone**.
2. Confirm the button changes to **Allow in Zone**, the row says **Zone excluded**, and the excluded count increases.
3. Hover **Allow in Zone** and confirm its tooltip says it will remove the exclusion.
4. Click **Allow in Zone**.
5. Confirm the button returns to **Exclude in Zone**, the row marker disappears, and the excluded count decreases.
6. Repeat the complete Exclude → Allow cycle once more.

## Cross-state and persistence

1. Favorite an appearance, then exclude it; confirm exclusion replaces favorite rather than creating both states.
2. Allow it again; confirm neither preference remains.
3. Exclude an appearance, then favor it; confirm favorite replaces exclusion.
4. Move to another zone and confirm its preference state is independent.
5. Return to the original zone and confirm the saved state returns.
6. Use `/reload` and confirm the final preference state persists.

## Regression safety

1. Generate and reroll an outfit; confirm excluded visuals are not selected and favored visuals receive their normal weighting.
2. Confirm manual preview remains available for excluded visuals.
3. Confirm v0.9.0 automatic collection refresh, recovery diagnostics, high contrast, era limits, and zone profiles still work.
4. Confirm no collection rescan was required by the update.
