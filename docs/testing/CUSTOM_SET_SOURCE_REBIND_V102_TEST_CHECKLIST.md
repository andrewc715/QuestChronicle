# Quest Chronicle v1.0.2 Collected Source Rebind Test Checklist

Use `CUSTOM_SET_SLOT_MAPPING_V102_TEST_CHECKLIST.md` for the complete live test.

Source-specific expectations:

1. v1.0.2 rebuilds wardrobe cache format 6.
2. A collected visual represented by an uncollected sibling source must be rebound to an actually collected source.
3. Quest Chronicle must abort before calling Blizzard's Custom Set save functions when any selected slot has no collected source.
4. Hidden Head, Back, Shirt, and Tabard choices must use the corresponding hidden visual source.
5. The concept stores `customSetResolvedSources` so the requested and exported source IDs can be audited after the save.
