#!/usr/bin/env python3
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parents[1]
def text(name): return (root/name).read_text(encoding='utf-8')
def sha(name): return hashlib.sha256((root/name).read_bytes()).hexdigest()
def need(name,*needles):
    data=text(name)
    for needle in needles:
        if needle not in data: raise SystemExit(f"FAIL: {name} missing {needle!r}")
version=text('VERSION.txt').strip(); toc=text('QuestChronicle.toc')
if version!='1.11.11' or '## Version: 1.11.11' not in toc: raise SystemExit('FAIL: package metadata is not v1.11.11')
frozen={
 'Core/ZoneStyle/Scoring.lua':'34749bf94f7ddac3bcbfbff72a0f7c1a3d1a70b4700fd6cfb449172a0cd87ecb',
 'Core/ZoneStyle/EraExecution.lua':'92d9efc680f16e7e81f6b672d7fbb039a42741c60dbe0c926d25479c851ec66c',
 'Core/ZoneStyle/EraCandidateWork.lua':'c9a7426f9cacfd2c7867b52f5877806596dd1648c48d168803770940fbd75b3a',
 'Core/Workers/SliceBudget.lua':'ac3309c40a67c621ad245a09817a10c8939013b7dbf579d0b7d4ec87468ec46f',
}
for name,expected in frozen.items():
    actual=sha(name)
    if actual!=expected: raise SystemExit(f'FAIL: frozen v1.11.10 boundary changed: {name} {actual}')
need('Core/ZoneStyle/PreparedSource.lua','BuildSourceMetadataSnapshot','GetSourceStyleSignalsPrepared','GetPreparedTrackedOrigin','ScoreSourcePrepared','GetSourceCoherencePrepared')
need('Core/ZoneStyle/Traveler/Descriptors.lua','prepared and prepared.expansionIDKnown','prepared and prepared.setIDsKnown')
need('Core/ZoneStyle/Zone/Affinity.lua','prepared and prepared.expansionIDKnown','prepared and prepared.trackedOriginKnown')
need('Core/Wardrobe/AnchorCandidateWork.lua','METADATA_SNAPSHOT','SET_IDS_SNAPSHOT','STYLE_SIGNALS','COHERENCE','LEGACY_SCORE','DESCRIPTOR','POOL_RANDOM','TRACKING','ZONE_AFFINITY','ZONE_POLICY_APPLY','PREFERENCE','CreateWeaponAnchorScoringWork')
anchor=text('Core/Wardrobe/AnchorCandidateWork.lua')
descriptor_i=anchor.find('elseif work.stage == "DESCRIPTOR"'); random_stage_i=anchor.find('elseif work.stage == "POOL_RANDOM"'); random_i=anchor.find('BuildLegacyCandidate(work)', random_stage_i); tracking_i=anchor.find('elseif work.stage == "TRACKING"'); affinity_i=anchor.find('elseif work.stage == "ZONE_AFFINITY"')
order=[descriptor_i,random_stage_i,random_i,tracking_i,affinity_i]
if min(order)<0 or not (order[0]<order[1]<=order[2]<order[3]<order[4]): raise SystemExit('FAIL: anchor random/tracking/affinity ordering changed')
need('Core/Wardrobe/AnchorWorkerScheduling.lua','anchorCandidateMetadataAPICalls','anchorCandidateSetAPICalls','anchorCandidateTrackingAPICalls','anchorCandidatePreparedMetadataHits','anchorCandidatePreparedSetHits','anchorCandidatePreparedTrackingHits','ConsumeAnchorCandidateYieldRequest')
need('Core/Wardrobe/SupportCandidateWork.lua','BRIDGE_TARGET_RESOLVE','BRIDGE_DESCRIPTOR_RESOLVE','BRIDGE_PAIR_CANDIDATE','BRIDGE_AFTER_FINALIZE','BRIDGE_BASELINE_PAIR','BRIDGE_FINALIZE','ProfileDescriptor','descriptorFallbacks')
need('Core/Wardrobe/SupportWorker.lua','supportBridgeTargetResolutions','supportBridgeDescriptorHits','supportBridgeDescriptorFallbacks','supportBridgeCandidatePairs','supportBridgeBaselinePairs','supportBridgeAdmissionDeferrals')
need('Core/Wardrobe/ScoringPotholePerformance.lua','BuildScoringPotholeDiagnostics','largestSubphase','supportCandidateBridgeBaseline')
need('Core/Diagnostics/SnapshotBuilder.lua','scoringPotholes = CopyTable(performance.scoringPotholes)')
need('Core/Diagnostics/ReportCompaction.lua','core.scoringPotholes = performance.scoringPotholes')
need('Core/Diagnostics/ReportEmergencyStub.lua','result.scoringPotholes = performance.scoringPotholes')
need('Core/ZoneStyle/Zone/DebugExport.lua','Anchor candidate scheduling:','Support bridge scheduling:')
for name in ['tools/test_anchor_candidate_benchmark_v11111.lua','tools/test_anchor_weapon_work_v11111.lua','tools/test_support_bridge_benchmark_v11111.lua']:
    if not (root/name).exists(): raise SystemExit(f'FAIL: missing closure fixture {name}')
order_names=[r'Core\Wardrobe\AnchorCandidateWork.lua',r'Core\Wardrobe\AnchorWorkerScheduling.lua',r'Core\Wardrobe\AnchorSkeletonWorker.lua']
pos=[toc.find(x) for x in order_names]
if min(pos)<0 or pos!=sorted(pos): raise SystemExit('FAIL: anchor runtime module TOC order is invalid')
for path in root.rglob('*.lua'):
    if any(part in {'tools','docs'} for part in path.relative_to(root).parts): continue
    lines=len(path.read_text(encoding='utf-8').splitlines())
    if lines>=500: raise SystemExit(f'FAIL: runtime Lua file >=500 lines: {path.relative_to(root)} ({lines})')
print('PASS: v1.11.11 scoring-pothole closure preserves frozen era/scoring boundaries and wires cooperative anchor/support bridge diagnostics.')
