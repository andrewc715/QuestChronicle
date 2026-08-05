from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def text(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")

checks = {
    "observation module in TOC": "Core\\ZoneStyle\\Traveler\\TuningAudit.lua" in text("QuestChronicle.toc"),
    "export module in TOC": "Core\\ZoneStyle\\Traveler\\TuningExport.lua" in text("QuestChronicle.toc"),
    "history observes after accepted report": "traveler.ObserveTuningReport" in text("Core/Diagnostics/History.lua"),
    "observer failures cannot block history": "pcall(traveler.ObserveTuningReport, report)" in text("Core/Diagnostics/History.lua"),
    "audit is opt in": "if not audit.enabled or not IsObservableReport(report)" in text("Core/ZoneStyle/Traveler/TuningAudit.lua"),
    "visual identity is primary": 'return "V:" .. tostring(visualID)' in text("Core/ZoneStyle/Traveler/TuningAudit.lua"),
    "identity cap is bounded": "T.TUNING_MAX_IDENTITIES = 300" in text("Core/ZoneStyle/Traveler/TuningAudit.lua"),
    "copyable export command": 'tuningCommand == "export"' in text("Core/Chronicle/TravelerTuningCommands.lua"),
    "clear confirmation": 'tuningRest == "confirm"' in text("Core/Chronicle/TravelerTuningCommands.lua"),
    "normal reports do not embed audit": "travelerTuningAudit" not in text("Core/Diagnostics/SnapshotBuilder.lua"),
    "no curated runtime override yet": not (ROOT / "Core/ZoneStyle/Traveler/CuratedOverrides.lua").exists(),
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit("FAIL Phase E observation verifier: " + ", ".join(failed))
print(f"PASS Phase E observation build verifier: {len(checks)} checks")
