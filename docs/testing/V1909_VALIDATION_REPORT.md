# Quest Chronicle v1.9.0.9 Automated Validation Report

## Results

- Lua syntax: 129 files passed.
- Lua regression harnesses: 49 passed.
- Static verification tools: 18 passed.
- Runtime TOC modules: 80, each listed exactly once.
- Runtime Lua line limit: all files below 500 physical lines.
- Largest runtime Lua file: `Core/ZoneStyle/SourceMetadata.lua`, 499 lines.
- Blocking transmog usability refresh audit: no runtime call to `C_TransmogCollection.UpdateUsableAppearances`.
- Split-helper orphan audit: passed.
- Version consistency: TOC, `VERSION.txt`, and runtime fallback agree on 1.9.0.9.
- Diagnostic persistence: maximum-detail Phase C snapshot measured 14,170 approximate bytes.
- Selection parity: thirteen deterministic v1.9.0.8 comparisons matched byte for byte.
- SavedVariables schema: 2.
- Courier format: 1.
- Wardrobe cache format: 7.
- Generation cache: 2.
- Diagnostic format: 1.

ZIP integrity and clean-extraction results are recorded in the packaged validation log generated during release assembly.
