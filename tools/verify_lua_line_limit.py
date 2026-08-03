#!/usr/bin/env python3
"""Fail when a Quest Chronicle Lua source file reaches the 500-line ceiling."""

from pathlib import Path
import sys

LIMIT = 500
ROOT = Path(__file__).resolve().parents[1]

violations = []
files = sorted(ROOT.rglob("*.lua"))
for path in files:
    line_count = sum(1 for _ in path.open("r", encoding="utf-8"))
    if line_count >= LIMIT:
        violations.append((path.relative_to(ROOT), line_count))

if violations:
    print(f"FAIL: {len(violations)} Lua file(s) reach or exceed {LIMIT} lines:")
    for path, line_count in violations:
        print(f"  {line_count:4d}  {path}")
    sys.exit(1)

largest = max((sum(1 for _ in path.open("r", encoding="utf-8")), path.relative_to(ROOT)) for path in files)
print(f"PASS: every Lua file is below {LIMIT} lines.")
print(f"Largest: {largest[0]} lines — {largest[1]}")
print(f"Files checked: {len(files)}")
