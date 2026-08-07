#!/usr/bin/env python3
"""Verify the v1.11.9 diagnostics workbench wiring and read-only boundaries."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")
version = (ROOT / "VERSION.txt").read_text(encoding="utf-8").strip()
main = (ROOT / "UI/MainWindow.lua").read_text(encoding="utf-8")
commands = (ROOT / "Core/Chronicle/Commands.lua").read_text(encoding="utf-8")
generation = (ROOT / "Core/Wardrobe/GenerationWorker.lua").read_text(encoding="utf-8")
history = (ROOT / "Core/Diagnostics/History.lua").read_text(encoding="utf-8")
snapshot = (ROOT / "Core/Diagnostics/SnapshotBuilder.lua").read_text(encoding="utf-8")
formatter = (ROOT / "Core/Diagnostics/ReportFormatter.lua").read_text(encoding="utf-8")
debug_tab = (ROOT / "UI/DebugTab.lua").read_text(encoding="utf-8")
tooltip = (ROOT / "UI/Outfits/ConceptManager.lua").read_text(encoding="utf-8")

checks = {
    "version is v1.11.9": version == "1.11.9" and "## Version: 1.11.9" in toc,
    "all diagnostics modules load": all(name in toc for name in (
        "Core\\Diagnostics\\Foundation.lua", "Core\\Diagnostics\\ReportCompaction.lua", "Core\\Diagnostics\\History.lua",
        "Core\\Diagnostics\\SnapshotBuilder.lua", "Core\\Diagnostics\\ReportFormatter.lua",
        "UI\\DebugHistory.lua", "UI\\DebugReport.lua", "UI\\DebugTab.lua")),
    "debug is a top-level tab": 'key = "debug"' in main and "UI.CreateDebugTab" in main,
    "slash command opens debug": 'command == "debug"' in commands and 'QC.ShowWindow("debug")' in commands,
    "generation queues immutable report": "QueueGenerationAttempt" in generation and "BuildGenerationSeed" in snapshot,
    "history is bounded": "MAX_REPORTS" in history and "MAX_HISTORY_BYTES" in history and "table.remove(valid)" in history,
    "history clear is isolated": "function D.ClearReports" in history and "store.reports = {}" in history,
    "copy report has core sections": all(section in formatter for section in (
        "Anchor Skeleton", "Beam Search", "Score Breakdown", "Performance", "Cache and Metadata", "Warnings and Fallback")),
    "debug tab reacts without opening itself": "DIAGNOSTIC_REPORT_ADDED" in debug_tab and "ShowWindow" not in debug_tab,
    "outfits tooltip points to debug": "Open the Debug tab" in tooltip,
    "diagnostics do not call selection mutators": all(token not in (history + snapshot + formatter) for token in (
        "SetSelectedSource(", "GenerateWeapons(", "ChooseAnchorSkeleton(", "SetRandomSelection(")),
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: diagnostics workbench guard failed:")
    for name in failed:
        print(f"  - {name}")
    sys.exit(1)
print("PASS: bounded immutable diagnostics, top-level Debug UI, copy reporting, and read-only generation integration are wired.")
