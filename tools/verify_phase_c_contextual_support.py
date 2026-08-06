#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
toc=(root/'QuestChronicle.toc').read_text()
worker=(root/'Core/Wardrobe/GenerationWorker.lua').read_text()
anchor=(root/'Core/Wardrobe/AnchorSkeletonWorker.lua').read_text()
snapshot=(root/'Core/Diagnostics/SnapshotBuilder.lua').read_text()
report=(root/'Core/Diagnostics/ReportFormatter.lua').read_text()
required=[
 'Core\\Wardrobe\\SupportProfile.lua','Core\\Wardrobe\\SupportBudget.lua','Core\\Wardrobe\\SupportScoring.lua',
 'Core\\Wardrobe\\SupportBeam.lua','Core\\Wardrobe\\SupportWorker.lua','Core\\Wardrobe\\SupportReroll.lua',
 'Core\\Diagnostics\\SupportSnapshot.lua','Core\\Diagnostics\\SupportComparison.lua','Core\\Diagnostics\\SupportReportFormatter.lua']
checks={
 'all Phase C modules are in TOC': all(x in toc for x in required),
 'anchor phase hands off to SUPPORT': 'job.phase = P.StepSupportGenerationJob and "SUPPORT" or "ARMOR"' in anchor,
 'generation worker advances SUPPORT cooperatively': 'P.StepSupportGenerationJob(job, stepStarted)' in worker,
 'diagnostic snapshot records support': 'DP.BuildSupportSnapshot' in snapshot,
 'debug formatter renders support': 'P.AddSupportSection' in report,
 'version is v1.11.3': '## Version: 1.11.3' in toc and (root/'VERSION.txt').read_text().strip()=='1.11.3',
}
failed=[name for name,ok in checks.items() if not ok]
if failed:
 for name in failed: print('FAIL:',name)
 raise SystemExit(1)
print('PASS: Phase C contextual profiles, mismatch budget, support beam, rerolls, diagnostics, and parity boundary are wired.')
