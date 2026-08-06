#!/usr/bin/env python3
"""Verify the v1.11.6 Zone diagnostic-persistence repair and protected scope."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
toc = (root / "QuestChronicle.toc").read_text(encoding="utf-8")
version = (root / "VERSION.txt").read_text(encoding="utf-8").strip()
history = (root / "Core/Diagnostics/History.lua").read_text(encoding="utf-8")
compaction = (root / "Core/Diagnostics/ReportCompaction.lua").read_text(encoding="utf-8")
zone_test = (root / "tools/test_zone_report_persistence_v1114.lua").read_text(encoding="utf-8")
rejection_test = (root / "tools/test_diagnostic_rejection_visibility_v1114.lua").read_text(encoding="utf-8")

checks = {
    "numeric v1.11.6 metadata": version == "1.11.6" and "## Version: 1.11.6" in toc,
    "compaction module loads before history": "Core\\Diagnostics\\ReportCompaction.lua\nCore\\Diagnostics\\AnchorAncestry.lua\nCore\\Diagnostics\\History.lua" in toc,
    "Zone aggregate policy is retained": "foundation.anchorPolicy" in compaction and "component.anchorPolicy = nil" in compaction,
    "per-piece affinity duplicate is removed": "foundation.affinity.pieces = nil" in compaction,
    "support ancestry is preserved": "profile.entries" not in compaction or "profile.entries = nil" not in compaction,
    "Phase D is not removed": "finalValidationStatus = nil" not in compaction and "repairs = nil" not in compaction,
    "visible failure path exists": "Debug report could not be saved" in history and "DIAGNOSTIC_REPORT_REJECTED" in history,
    "realistic Zone persistence fixture exists": "realistic v1.11.3 Zone report must survive compaction" in zone_test and "ZONE_ANCHOR_POLICY_V1" in zone_test,
    "rejection visibility fixture exists": "Debug report could not be saved" in rejection_test and "DIAGNOSTIC_REPORT_REJECTED" in rejection_test,
    "persistence limit remains frozen": "D.MAX_REPORT_BYTES = 20480" in (root / "Core/Diagnostics/Foundation.lua").read_text(encoding="utf-8"),
}

failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: v1.11.6 Zone report persistence guard failed:")
    for name in failed:
        print(f"  - {name}")
    sys.exit(1)
print(f"PASS: v1.11.6 Zone report persistence verification: {len(checks)} checks")
