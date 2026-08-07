#!/usr/bin/env python3
"""Verify the v1.11.10 copy-ready Zone debug export contract."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
commands = (root / "Core/Chronicle/Commands.lua").read_text()
handler = (root / "Core/Chronicle/ZoneDebugCommands.lua").read_text()
exporter = (root / "Core/ZoneStyle/Zone/DebugExport.lua").read_text()
ui = (root / "UI/DebugReport.lua").read_text()
toc = (root / "QuestChronicle.toc").read_text()

checks = {
    "numeric v1.11.10 metadata": "## Version: 1.11.10" in toc and (root / "VERSION.txt").read_text().strip() == "1.11.10",
    "command module listed once": toc.count(r"Core\Chronicle\ZoneDebugCommands.lua") == 1,
    "export module listed once": toc.count(r"Core\ZoneStyle\Zone\DebugExport.lua") == 1,
    "help advertises export": "/qc zone debug [export]" in commands,
    "zone branch delegates": "HandleZoneDebugCommand" in commands,
    "exact command is parsed": 'rest == "export"' in handler and "BuildZoneDebugExport" in handler,
    "copy surface is wired": "ShowZoneDebugExport" in handler and "Copy Zone Debug Export" in ui,
    "export includes architecture": "Generation architecture" in exporter and "GetModeCapabilities" in exporter,
    "export includes complete ancestry": "Complete evidence ancestry" in exporter and "for index, entry in ipairs(evidence.entries" in exporter,
    "export includes per-piece affinity": "Current-look Zone affinity" in exporter and "AFFINITY_COMPONENTS" in exporter,
    "export includes latest Zone report": "Latest Zone Native diagnostic report" in exporter and "LatestZoneNativeReport" in exporter and "LatestZoneAnchorPolicyReport" in exporter,
    "export is session-only": "QuestChronicleDB" not in exporter and "SavedVariables" not in exporter,
    "export does not use randomness": "math.random" not in exporter and "random(" not in exporter.lower(),
    "export does not invoke generation": all(token not in exporter for token in ["GenerateCurrentMode", "StartGenerateOutfit", "RerollUnlockedCurrentMode"]),
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    print("FAIL: v1.11.10 Zone debug export guard failed:")
    for name in failed:
        print("  -", name)
    raise SystemExit(1)
print(f"PASS: v1.11.10 Zone debug export verification: {len(checks)} checks")
