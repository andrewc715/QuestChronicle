# Quest Chronicle v1.9.0.15a1 Live Validation Steps

## Goal

Confirm the Phase E observation build collects a local Traveler batch without changing generation behavior or normal Debug reports.

## Do this

1. Install v1.9.0.15a1 and use `/reload`.
2. Run:

   ```text
   /qc traveler tuning clear confirm
   /qc traveler tuning start
   ```

3. Complete these three Traveler actions:

   ```text
   Generate Outfit
   Reroll Unlocked
   Reroll one visible support slot
   ```

   The support-slot reroll must complete normally. A message that the contextual mismatch ledger could not be reconciled is a failure.

4. Run:

   ```text
   /qc traveler tuning status
   ```

   Expected: collecting, `3 actions`, at least one visual identity, `0 collection errors`.

5. Open Debug and verify all three ordinary reports are still present, selectable, and copyable. They must not contain the full tuning audit.
6. Run:

   ```text
   /qc traveler tuning stop
   /qc traveler tuning export
   ```

   Expected: a **Copy Traveler Tuning Audit** window with selected Markdown containing:

   ```text
   Palette Suspects
   Finish Suspects
   Missing Echo Suspects
   Repeat Offenders
   ```

7. Use `/reload`, then run:

   ```text
   /qc traveler tuning status
   ```

   Expected: the audit remains stopped and still reports the same action count.

8. Run `/qc traveler tuning start`, complete one more Traveler action, then run `/qc traveler tuning stop` and `/qc traveler tuning status`.

   Expected: the action count increases by exactly one.

## After the mechanics pass

Start the audit and collect at least **20 completed Traveler actions**. A target of **30** is better.

Capture screenshots only when a palette, finish, accent echo, or repeated outlier appears visually suspicious. Then stop and export the batch.

## Return

Return:

1. The final copied tuning-audit Markdown
2. Screenshots of suspicious outfits
3. The matching full Debug reports when available
4. Any visible error or unexpected change in generated outfits
