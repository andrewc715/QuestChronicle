from pathlib import Path
root = Path(__file__).resolve().parents[1]
identity = (root / "Core/Wardrobe/SupportProfileIdentity.lua").read_text(encoding="utf-8")
profile = (root / "Core/Wardrobe/SupportProfile.lua").read_text(encoding="utf-8")
scoring = (root / "Core/Wardrobe/SupportScoring.lua").read_text(encoding="utf-8")
reroll = (root / "Core/Wardrobe/SupportRerollWorker.lua").read_text(encoding="utf-8")
performance = (root / "Core/Wardrobe/GenerationPerformance.lua").read_text(encoding="utf-8")
formatter = (root / "Core/Diagnostics/SupportReportFormatter.lua").read_text(encoding="utf-8")
toc = (root / "QuestChronicle.toc").read_text(encoding="utf-8")
version = (root / "VERSION.txt").read_text(encoding="utf-8").strip()
checks = {
    "v1.9.0.15 metadata": version == "1.9.0.15" and "## Version: 1.9.0.15" in toc,
    "canonical mask module loaded": "Core\\Wardrobe\\SupportProfileIdentity.lua" in toc,
    "state beats appearance identity": 'state = ResolveState(hidden, available, locked)' in identity,
    "hidden anchors are profile gated": 'P.IsAnchorActive(mask, slotKey)' in profile,
    "support relationships use profile mask": 'P.IsAnchorActive(mask, slotKey)' in scoring,
    "support rerolls resolve inherited profiles": 'P.ResolveContextualSupportProfile' in reroll,
    "budget reconciliation blocks commit": 'if not stats.budgetReconciled then' in reroll,
    "timing domains separated": 'largestCooperativeCallPhase' in performance and 'preWorkerPreparationMs' in performance,
    "profile identity is reported": 'Profile ID:' in formatter and 'Budget reconciliation:' in formatter,
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit("FAIL profile-integrity verification: " + ", ".join(failed))
print(f"PASS phase C profile-integrity verification: {len(checks)} checks")
