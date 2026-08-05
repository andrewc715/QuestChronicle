from pathlib import Path

root = Path(__file__).resolve().parents[1]
history = (root / "Core/Diagnostics/History.lua").read_text(encoding="utf-8")
formatter = (root / "Core/Diagnostics/SupportReportFormatter.lua").read_text(encoding="utf-8")
test = (root / "tools/test_diagnostic_report_compaction_v19014.lua").read_text(encoding="utf-8")

required_history = [
    "CompactReportToLimit",
    "report.outfit.slots = nil",
    "profile.activeAnchors = nil",
    "report.performance.phaseStats = nil",
    "Diagnostic report remained above the persistence limit after compaction.",
]
for marker in required_history:
    assert marker in history, f"missing diagnostic compaction marker: {marker}"

assert "anchorRows = profile.entries" in formatter, "compacted profiles must still format active anchors"
assert "D.GetReports()" in test and "REPORT_TRIMMED" in test, "runtime compaction regression must verify history retention and warning"
assert "compacted report must remain visible in Debug History" in test

print("PASS diagnostic report compaction wiring and history-retention regression")
