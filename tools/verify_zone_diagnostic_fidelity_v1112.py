#!/usr/bin/env python3
"""Verify the v1.11.2 Zone export-fidelity and applicability contract."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
toc = (root / "QuestChronicle.toc").read_text()
version = (root / "VERSION.txt").read_text().strip()
foundation = (root / "Core/ZoneStyle/Zone/Foundation.lua").read_text()
encoding = (root / "Core/ZoneStyle/Zone/ExportEncoding.lua").read_text()
affinity = (root / "Core/ZoneStyle/Zone/Affinity.lua").read_text()
exporter = (root / "Core/ZoneStyle/Zone/DebugExport.lua").read_text()
snapshot = (root / "Core/Diagnostics/SnapshotBuilder.lua").read_text()
adapter = (root / "Core/Generation/Modes/ZoneLegacyAdapter.lua").read_text()
ui = (root / "UI/DebugReport.lua").read_text()

checks = {
    "clean numeric metadata": version == "1.11.2" and "## Version: 1.11.2" in toc,
    "encoding module listed once": toc.count(r"Core\ZoneStyle\Zone\ExportEncoding.lua") == 1,
    "affinity format 2": "Zone.AFFINITY_FORMAT = 2" in foundation,
    "export format 2": "Zone.DEBUG_EXPORT_FORMAT = 2" in exporter,
    "tri-state constants": all(token in foundation for token in ["VALUE", "MISSING", "NOT_APPLICABLE"]),
    "diagnostic encoding identity": 'DIAGNOSTIC_VALUE_ENCODING = "DIAGNOSTIC_ESCAPE_V1"' in encoding,
    "pipe encoding": 'gsub("|", "\\\\u007C")' in encoding,
    "backtick encoding": 'gsub("`", "\\\\u0060")' in encoding,
    "unsafe-token detector": "ContainsUnsafeWoWControl" in encoding,
    "export declares encoding": all(token in exporter for token in ["Dynamic value encoding", "Literal pipe representation", "Zone affinity format"]),
    "export uses serializer": all(token in exporter for token in ["EscapeDiagnosticValue", "MarkdownCell", "MarkdownCode"]),
    "missing and N/A columns": "Missing channels | N/A channels" in exporter,
    "coverage-aware statuses": all(token in affinity for token in ["ResolveComponentStatus", "componentStatus", "notApplicableChannels"]),
    "format-1 normalization": all(token in affinity for token in ["NormalizeZoneAffinityPiece", "NormalizeSelectedOutfitAffinity"]),
    "new report status fields": all(token in snapshot for token in ["componentStatus", "notApplicableChannels", "components = CopyTable"]),
    "Zone remains legacy": all(token in adapter for token in ["CreateLegacyWardrobePolicy", "sharedFramework = false", "legacy = true"]),
    "export remains observational": all(token not in exporter + encoding + affinity for token in ["math.random", "GenerateCurrentMode", "StartGenerateOutfit", "RerollUnlockedCurrentMode", "QuestChronicleDB"]),
    "generic copy UI unchanged in responsibility": "ShowZoneDebugExport" in ui and "DIAGNOSTIC_ESCAPE_V1" not in ui,
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    print("FAIL: v1.11.2 Zone diagnostic-fidelity guard failed:")
    for name in failed:
        print("  -", name)
    raise SystemExit(1)
print(f"PASS: v1.11.2 Zone diagnostic fidelity verification: {len(checks)} checks")
