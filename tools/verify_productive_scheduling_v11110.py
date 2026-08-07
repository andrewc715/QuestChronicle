#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
version=(root/'VERSION.txt').read_text(encoding='utf-8').strip()
toc=(root/'QuestChronicle.toc').read_text(encoding='utf-8')
if version not in {'1.11.11','1.11.11'} or f'## Version: {version}' not in toc:
 raise SystemExit('FAIL: package metadata is not a v1.11.11-compatible release')
checks={
 'era admission classes': ('Core/ZoneStyle/EraExecution.lua',['ERA_ADMISSION_LOCAL','ERA_ADMISSION_API_HEADROOM','ERA_API_RESERVE_MS = 3.0','eraApiHeadroomDeferrals','eraPhantomDeferrals']),
 'demand-aware probe': ('Core/ZoneStyle/EraCandidateWork.lua',['DescribeNextEraCandidateAdmission','trackedOriginCache[sourceID] ~= nil','ERA_ADMISSION_API_HEADROOM']),
 'nested support candidate worker': ('Core/Wardrobe/SupportCandidateWork.lua',['CreateSupportCandidateWork','NEIGHBOR_TARGET_RESOLVE','BRIDGE_TARGET_RESOLVE','BRIDGE_PAIR_CANDIDATE','BRIDGE_BASELINE_PAIR','EvaluateSupportBudget','StepSupportCandidateWork']),
 'beam integration': ('Core/Wardrobe/SupportBeam.lua',['CreateSupportCandidateWork','StepSupportCandidateWork','lastCandidateCompleted','candidateWork = nil']),
 'support timing': ('Core/Wardrobe/SupportWorker.lua',['supportCandidateNeighbor','supportCandidateBridge','supportCandidateBudget','supportCandidateFinalize','supportCandidateDeferrals']),
 'headline diagnostics': ('Core/Wardrobe/GenerationPerformance.lua',['apiHeadroomDeferrals','phantomDeferrals','candidateSubsteps','largestCandidateSubphase']),
 'format4 diagnostics': ('Core/ZoneStyle/Zone/DebugExport.lua',['Era admission:','Support candidate scheduling:','Largest support candidate subphase:']),
}
for label,(name,needles) in checks.items():
 text=(root/name).read_text(encoding='utf-8')
 for needle in needles:
  if needle not in text: raise SystemExit(f'FAIL: {label} missing {needle!r} in {name}')
a=toc.find(r'Core\Wardrobe\SupportCandidateWork.lua'); b=toc.find(r'Core\Wardrobe\SupportBeam.lua')
if a<0 or b<0 or a>b: raise SystemExit('FAIL: SupportCandidateWork must load before SupportBeam')
print('PASS: v1.11.11 productive era admission and resumable support-candidate scheduling contract is preserved.')
