#!/usr/bin/env python3
"""Verify that the TOC lists every runtime Lua module exactly once and every entry exists."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "QuestChronicle.toc"
entries = []
for raw in TOC.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line or line.startswith("##"):
        continue
    entries.append(line.replace("\\", "/"))

missing = [entry for entry in entries if not (ROOT / entry).is_file()]
duplicates = sorted({entry for entry in entries if entries.count(entry) > 1})
runtime = sorted(
    path.relative_to(ROOT).as_posix()
    for directory in (ROOT / "Core", ROOT / "UI")
    for path in directory.rglob("*.lua")
)
unlisted = sorted(set(runtime) - set(entries))
unexpected = sorted(set(entries) - set(runtime))

if missing or duplicates or unlisted or unexpected:
    print("FAIL: TOC manifest validation failed.")
    for label, values in (
        ("Missing files", missing),
        ("Duplicate entries", duplicates),
        ("Unlisted runtime Lua", unlisted),
        ("Unexpected TOC entries", unexpected),
    ):
        if values:
            print(f"{label}:")
            for value in values:
                print(f"  - {value}")
    sys.exit(1)

print(f"PASS: TOC lists all {len(runtime)} runtime Lua modules exactly once and every path exists.")
