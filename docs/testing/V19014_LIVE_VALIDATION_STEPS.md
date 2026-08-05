# Quest Chronicle v1.9.0.14 Live Validation Steps

## What to do

Keep your normal Traveler settings, locks, and hidden slots. Do not clear any caches.

### 1. Install and reload

1. Replace the existing `QuestChronicle` addon folder with the folder from `QuestChronicle-v1.9.0.14.zip`.
2. Launch Retail or use `/reload`.
3. Run `/qc status` and confirm `1.9.0.14`.

### 2. Generate a normal Traveler outfit

1. Open the Outfit workbench.
2. Select **Generate Outfit**.
3. Open the **Debug** tab.
4. Confirm the new generation appears in **Generation History** and **Copy Report** is enabled.
5. Copy the full Debug report.

A `REPORT_TRIMMED` warning is acceptable when the live report crossed the 20 KB persistence ceiling. The report itself must remain visible and copyable.

The report must show one of:

```text
Final validation: CLEAN
Final validation: REPAIRED • 1 pass
Final validation: REPAIRED • 2 passes
Final validation: LOCKED_OVERRIDE
Final validation: ALTERNATE_SKELETON
```

For a normal clean outfit, expect:

```text
Final validation: CLEAN
Repair passes: 0
Fallback: None
```

### 3. Generate again

Select **Generate Outfit** again without changing equipment, specialization, talents, collection state, locks, or hidden slots.

Copy the full Debug report.

Verify:

```text
Weapon index use: WARM_REUSE
Weapon index invalidation: NONE
Fallback: None
```

The same Phase D status rules from Step 2 apply.

### 4. Reroll Unlocked

Select **Reroll Unlocked** and copy the full Debug report.

Verify:

- hidden slots remain hidden;
- locked slots remain unchanged;
- the weapon route remains legal;
- final validation completes before the preview commits;
- `Fallback: None`;
- no duplicate or malformed report appears.

### 5. Reroll one support slot

Reroll one visible unlocked support slot, preferably **Head**, **Hands**, or **Back**.

Copy the full Debug report.

Verify:

```text
Only the requested support slot changes
Anchor phase: Reused from parent report
Profile phase: Reused
Budget reconciliation: Pass
Fallback: None
```

If the first candidate fails final validation, the report may show one target-local repair. No other support slot or anchor may change.

### 6. Check lock sovereignty

1. Lock a different visible support slot.
2. Record its appearance.
3. Reroll the same target slot from Step 5 again.
4. Copy the full Debug report.

Verify:

- the newly locked appearance remains unchanged;
- only the requested reroll target changes;
- hidden slots remain hidden;
- `Budget reconciliation: Pass`;
- final validation reports the locked state truthfully;
- no automatic unlock or replacement occurs.

## Performance gate

Across the reports, verify:

```text
No visible freeze
No repeated worker slice above 8 ms
No individual Phase D call above 8 ms
Post-expensive-call continuations: 0
Fallback: None
0 duplicate reports
0 malformed reports
Every completed action appears in Debug History
```

An isolated small timing overrun may be recorded as variance when it does not repeat, no individual Phase D call exceeds 8 ms, and there is no visible hitch.

## What to send back

Send these five Debug reports:

1. First Generate Outfit after install or reload
2. Warm Generate Outfit
3. Reroll Unlocked
4. First support-slot reroll
5. Second reroll of that slot after locking another support slot

Automated fixtures already prove the exact one-pass, two-pass, hard two-pass cap, locked-only override, and alternate-skeleton branches. Retail validation confirms that the real workbench remains coherent, responsive, target-isolated, and atomic.
