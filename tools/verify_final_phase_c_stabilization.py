#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
toc = (root / "QuestChronicle.toc").read_text(encoding="utf-8")
version = (root / "VERSION.txt").read_text(encoding="utf-8").strip()
launch = (root / "Core/Wardrobe/SupportRerollLaunch.lua").read_text(encoding="utf-8")
entry = (root / "Core/Wardrobe/SupportReroll.lua").read_text(encoding="utf-8")
worker = (root / "Core/Wardrobe/SupportRerollWorker.lua").read_text(encoding="utf-8")
roles = (root / "Core/Wardrobe/SupportRoleResolver.lua").read_text(encoding="utf-8")
scoring = (root / "Core/Wardrobe/SupportScoring.lua").read_text(encoding="utf-8")
performance = (root / "Core/Wardrobe/GenerationPerformance.lua").read_text(encoding="utf-8")
formatter = (root / "Core/Diagnostics/ReportFormatter.lua").read_text(encoding="utf-8")
comparison = (root / "Core/Diagnostics/Comparison.lua").read_text(encoding="utf-8")
history = (root / "Core/Diagnostics/History.lua").read_text(encoding="utf-8")
checks = {
    "v1.9.0.11 metadata": version == "1.9.0.11" and "## Version: 1.9.0.11" in toc,
    "launch and role modules loaded": all(x in toc for x in (
        r"Core\Wardrobe\SupportRerollLaunch.lua", r"Core\Wardrobe\SupportRoleResolver.lua")),
    "launch manifest is primitive": "CreateSupportRerollManifest" in launch and "CopySupportRerollState" not in launch,
    "entry starts from compact manifest": "CreateSupportRerollManifest" in entry and 'phase = "IDENTITY"' in entry,
    "immutable report references are pinned": "PinReport" in history and "ReleaseReport" in history and "pinnedReportIDs" in worker,
    "snapshot materializes cooperatively": all(x in worker for x in (
        'job.phase == "IDENTITY"', 'job.phase == "STATE"', 'job.phase == "CONTEXT_INIT"', 'job.phase == "CONTEXT_SEED"', 'job.phase == "CONTEXT_PREPARE"',
        'rerollStateMaterialization', 'rerollDiagnosticIdentity', 'rerollAnchorSummary', 'rerollStyleContextInit', 'rerollStyleContextSeed', 'rerollEligibilityContext', 'rerollSupportSummaryFoundation', 'rerollCacheSummaryFoundation')),
    "legacy state capture removed": '"rerollStateCapture"' not in worker,
    "stale state is revision guarded": "ValidateSupportRerollManifest" in worker and "TouchPreviewRevision" in worker,
    "active endpoint roles are centralized": "ResolveSupportRole" in roles and "Chest identity support" in roles and "Chest silhouette support" in roles,
    "scoring uses resolved role endpoints": "ResolveSupportRole" in scoring and "resolvedRole" in scoring,
    "timing domains renamed": "synchronousLaunchPreparationMs" in performance and "Synchronous launch preparation" in formatter,
    "launch warning names correct domain": "SYNC_LAUNCH_OVERRUN" in comparison,
    "candidate and finalist limits preserved": "P.SUPPORT_POOL_LIMIT" in (root / "Core/Wardrobe/SupportRerollScoring.lua").read_text()
        and "P.SUPPORT_FINAL_SHORTLIST" in (root / "Core/Wardrobe/SupportRerollScoring.lua").read_text(),
}
failed = [name for name, ok in checks.items() if not ok]
if failed:
    for name in failed: print("FAIL:", name)
    raise SystemExit(1)
print(f"PASS: v1.9.0.11 final Phase C stabilization verification: {len(checks)} checks")
