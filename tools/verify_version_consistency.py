#!/usr/bin/env python3
"""Verify Quest Chronicle's package and runtime version sources agree."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)

version_file = (ROOT / "VERSION.txt").read_text(encoding="utf-8").strip()
toc_text = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")
foundation_text = (ROOT / "Core/Chronicle/Foundation.lua").read_text(encoding="utf-8")

toc_match = re.search(r"^## Version:\s*(\S+)\s*$", toc_text, re.MULTILINE)
if not toc_match:
    fail("QuestChronicle.toc has no ## Version field")
toc_version = toc_match.group(1)

fallback_match = re.search(
    r'P\.ADDON_VERSION\s*=.*?GetAddOnMetadata\(P\.ADDON_NAME,\s*"Version"\).*?or\s*"([^"]+)"',
    foundation_text,
)
if not fallback_match:
    fail("Foundation.lua does not read TOC metadata with an explicit fallback")
runtime_fallback = fallback_match.group(1)

if version_file != toc_version:
    fail(f"VERSION.txt={version_file!r} but TOC={toc_version!r}")
if runtime_fallback != toc_version:
    fail(f"runtime fallback={runtime_fallback!r} but TOC={toc_version!r}")

print(
    "PASS: VERSION.txt, TOC metadata, and runtime fallback agree on "
    f"{toc_version}; runtime display reads the TOC."
)
