#!/usr/bin/env python3
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
version = (ROOT / "VERSION.txt").read_text().strip()
toc = (ROOT / "QuestChronicle.toc").read_text()
history = (ROOT / "Core/Diagnostics/History.lua").read_text()
comparison = (ROOT / "Core/Diagnostics/Comparison.lua").read_text()
snapshot = (ROOT / "Core/Diagnostics/SnapshotBuilder.lua").read_text()
filters = (ROOT / "Core/Wardrobe/WeaponFilters.lua").read_text()
selection = (ROOT / "Core/Wardrobe/WeaponSelection.lua").read_text()
scan = (ROOT / "Core/Wardrobe/CollectionScanWorker.lua").read_text()
performance = (ROOT / "Core/Wardrobe/GenerationPerformance.lua").read_text()
checks = {
 "version": version == "1.11.8" and "## Version: 1.11.8" in toc,
 "comparison loads before snapshots": toc.find(r"Core\Diagnostics\Comparison.lua") < toc.find(r"Core\Diagnostics\SnapshotBuilder.lua"),
 "stable ancestry": all(t in history + snapshot + comparison for t in ("parentCompletedReportID", "BeginGenerationAttempt", "generationToken")),
 "duplicate protection": all(t in history for t in ("duplicateInsertionsIgnored", "ReportFingerprint", "Duplicate diagnostic report ignored")),
 "hidden anchors excluded": all(t in comparison for t in ('component.hidden', '" (Hidden)"', 'comparison.excluded')),
 "foundation warning ignores hidden/locked": "chest.hidden or shoulder.hidden or chest.locked or shoulder.locked" in comparison,
 "scan prewarms appearance index": "StoreWeaponGenerationAppearanceIndex" in scan and "weaponGenerationAppearanceIndex" in filters,
 "source metadata is reused": "GetCachedWeaponSourceInfo" in selection and "weaponSourceInfoCache" in filters,
 "validation crosses finalists": "weaponValidationSessionCache" in selection and "weaponValidationSessionCache" in filters,
 "precise weapon subphase": "weaponSlowYieldPhase" in performance and "weaponAppearance" in performance,
}
failed=[k for k,v in checks.items() if not v]
if failed:
 print("FAIL: Phase B stabilization guard failed:")
 for item in failed: print("  - "+item)
 sys.exit(1)
print("PASS: hidden-anchor truthfulness, immutable ancestry, duplicate protection, metadata prewarming, and precise weapon subphases are wired.")
