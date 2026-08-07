#!/usr/bin/env python3
"""Verify v1.11.9 Zone anchor-policy lineage and cooperative weapon closure wiring."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
toc=(root/'QuestChronicle.toc').read_text()
version=(root/'VERSION.txt').read_text().strip()
exporter=(root/'Core/ZoneStyle/Zone/DebugExport.lua').read_text()
scoring=(root/'Core/ZoneStyle/Scoring.lua').read_text()
ordering=(root/'Core/Wardrobe/WeaponStyleOrdering.lua').read_text()
capability=(root/'Core/Wardrobe/WeaponCapabilitySnapshot.lua').read_text()
pipeline=(root/'Core/Wardrobe/WeaponPipeline.lua').read_text()
anchor=(root/'Core/Wardrobe/AnchorSkeletonWorker.lua').read_text()
perf=(root/'Core/Wardrobe/GenerationPerformance.lua').read_text()
snapshot=(root/'Core/Diagnostics/SnapshotBuilder.lua').read_text()
checks={
 'numeric v1.11.9 metadata': version=='1.11.9' and '## Version: 1.11.9' in toc,
 'new modules listed once': toc.count(r'Core\Wardrobe\WeaponCapabilitySnapshot.lua')==1 and toc.count(r'Core\Wardrobe\WeaponStyleOrdering.lua')==1,
 'ordering loads after eligibility': toc.index(r'Core\ZoneStyle\GenerationEligibility.lua') < toc.index(r'Core\Wardrobe\WeaponStyleOrdering.lua'),
 'export format 4': 'Zone.DEBUG_EXPORT_FORMAT = 4' in exporter,
 'independent selectors': all(x in exporter for x in ['LatestZoneNativeReport','LatestZoneAnchorPolicyReport','ValidAnchorPolicy']),
 'legacy latest warning': 'legacy action without an anchor-policy payload' in exporter,
 'policy performance section': 'Zone Anchor Policy Performance' in exporter and 'latestPolicyReportID' in exporter,
 'synchronous ordering drain removed': 'GetSourceEligibilityCached(candidate.source' not in scoring and 'CreateWeaponStyleOrderingWork' in scoring,
 'bounded marker batch': 'P.WEAPON_STYLE_MARKER_BATCH = 4' in ordering and 'StepCachedSourceEligibilityWork(work.eligibilityWork, P.WEAPON_STYLE_MARKER_BATCH)' in ordering,
 'one random draw per retained candidate': ordering.count('math.random()')==1,
 'capability session snapshot': all(x in capability for x in ['weaponCapabilitySnapshot','weaponCapabilityGeneration','GetWeaponCapabilitySnapshotForJob']),
 'explicit invalidation lineage': 'InvalidateWeaponCapabilitySnapshot' in capability and 'CHARACTER_CAPABILITY_CHANGED' in (root/'Core/Wardrobe/Events.lua').read_text(),
 'stale commit guard': 'ValidateWeaponCapabilitySnapshotAtCommit' in capability and 'ValidateWeaponCapabilitySnapshotAtCommit' in (root/'Core/Wardrobe/AnchorPolicyBridge.lua').read_text(),
 'job reaches all anchor weapon works': 'styleContext, job)' in anchor and 'activeWeaponGenerationJob' in pipeline,
 'performance diagnostics persist': 'weaponCapabilities = job and' in perf and 'weaponCapabilities = CopyTable' in snapshot,
 'selection formulas frozen': all(token in (root/'Core/ZoneStyle/Zone/AnchorScoring.lua').read_text() for token in ['neutralAffinity = 0.35','affinityScale = 20.00','maximumBonus = 8.00','maximumPenalty = -6.00']),
 'new executable fixtures': all((root/'tools'/name).exists() for name in ['test_zone_debug_export_lineage_v1115.lua','test_weapon_style_ordering_v1115.lua','test_weapon_capability_snapshot_v1115.lua']),
}
failed=[k for k,v in checks.items() if not v]
if failed:
 print('FAIL v1.11.9 Zone anchor closure verifier:')
 for k in failed: print('  -',k)
 sys.exit(1)
print(f'PASS v1.11.9 Zone anchor closure verification: {len(checks)} checks')
