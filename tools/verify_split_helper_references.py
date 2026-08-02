#!/usr/bin/env python3
"""Detect private helpers orphaned as globals when Lua monoliths are split.

Each normalized subsystem stores cross-file private helpers on a local `P`
namespace. A bare call to a helper defined as `P.Helper` is almost certainly a
missed namespace qualification and will become a nil global at runtime.
"""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
GROUPS = (
    ROOT / "Core" / "Chronicle",
    ROOT / "Core" / "Wardrobe",
    ROOT / "Core" / "ZoneStyle",
    ROOT / "UI" / "Outfits",
)

violations: list[tuple[Path, int, str, str]] = []

for group in GROUPS:
    files = sorted(group.rglob("*.lua"))
    helper_names: set[str] = set()

    for path in files:
        for line in path.read_text(encoding="utf-8").splitlines():
            match = re.match(r"\s*function\s+P\.([A-Za-z_]\w*)\s*\(", line)
            if match:
                helper_names.add(match.group(1))

    for helper_name in sorted(helper_names):
        bare_call = re.compile(rf"(?<![\w.]){re.escape(helper_name)}\s*\(")
        definition = re.compile(rf"\s*(?:local\s+)?function\s+{re.escape(helper_name)}\s*\(")

        for path in files:
            for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                if bare_call.search(line) and not definition.match(line):
                    violations.append((path.relative_to(ROOT), line_number, helper_name, line.strip()))

if violations:
    print("FAIL: split-module private helper calls are missing the P. namespace:")
    for path, line_number, helper_name, source in violations:
        print(f"  {path}:{line_number}: {helper_name} -> {source}")
    sys.exit(1)

print("PASS: no split-module private helpers are called as orphaned globals.")
