#!/usr/bin/env python3
"""Verify the v1.11.8 adaptive diagnostic-budget persistence contract."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
read = lambda rel: (root / rel).read_text(encoding="utf-8")
version = read("VERSION.txt").strip()
toc = read("QuestChronicle.toc")
compaction = read("Core/Diagnostics/ReportCompaction.lua")
emergency = read("Core/Diagnostics/ReportEmergencyStub.lua")
history = read("Core/Diagnostics/History.lua")
formatter = read("Core/Diagnostics/ReportFormatter.lua")
test = read("tools/test_adaptive_report_budget_v1116.lua")

checks = {
    "numeric v1.11.8 metadata": version == "1.11.8" and "## Version: 1.11.8" in toc,
    "emergency module ordered before compaction": toc.index("Core\\Diagnostics\\ReportEmergencyStub.lua") < toc.index("Core\\Diagnostics\\ReportCompaction.lua"),
    "exact serialized size authority": "QC._Core.JsonEncode" in compaction and "pcall(QC._Core.JsonEncode, report)" in compaction,
    "all adaptive tier labels": all(label in compaction for label in (
        "DUPLICATE_FIELDS", "RECONSTRUCTIBLE_DETAIL", "SUMMARY_TABLES",
        "MANDATORY_CORE", "EMERGENCY_STUB", "MINIMAL_STUB",
    )),
    "deterministic tier progression": all(call in compaction for call in (
        "ApplyTier1(report)", "ApplyTier2(report)", "ApplyTier3(report)", "ApplyTier4(report)",
    )),
    "emergency payload builder": "function P.BuildAdaptiveEmergencyStub" in emergency,
    "mandatory Zone policy retention": "CompactPolicySelected" in emergency and "anchorPolicy = CompactPolicy" in emergency,
    "mandatory support and Phase D retention": "CompactSupport" in emergency and "phaseDFinal = CompactPhaseD" in emergency,
    "capability and scheduler retention": "CompactCapabilities" in emergency and "CompactScheduler" in emergency,
    "history emergency fallback": history.count("P.BuildEmergencyReportStub") >= 2,
    "visible final rejection guard retained": "DIAGNOSTIC_REPORT_REJECTED" in history and "Debug report could not be saved" in history,
    "compaction telemetry formatter": all(token in formatter for token in (
        "Diagnostic persistence:", "originalBytes", "finalBytes", "emergencyStub",
    )),
    "worst-case dynamic fixture": "8147167" not in test and "adaptive report must be persisted" in test,
    "pathological emergency fixture": "pathological valid report must persist as a stub" in test,
    "exact byte assertion": "report.approximateBytes == #JsonEncode(report)" in test,
    "no persistence ceiling increase": "D.MAX_REPORT_BYTES = 20480" in read("Core/Diagnostics/Foundation.lua"),
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    print("FAIL v1.11.8 adaptive diagnostic-budget verifier:")
    for name in failed:
        print(f"- {name}")
    sys.exit(1)
print(f"PASS v1.11.8 adaptive diagnostic-budget verification: {len(checks)} checks")
