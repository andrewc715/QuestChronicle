#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
needle = "UpdateUsableAppearances"
violations = []
for path in sorted(root.rglob("*.lua")):
    if "docs" in path.parts or "tools" in path.parts:
        continue
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if needle in line and not line.lstrip().startswith("--"):
            violations.append(f"{path.relative_to(root)}:{number}: {line.strip()}")

if violations:
    print("FAIL: blocking transmog usability refresh call found:")
    for violation in violations:
        print(violation)
    sys.exit(1)

print("PASS: no runtime Lua calls C_TransmogCollection.UpdateUsableAppearances.")
