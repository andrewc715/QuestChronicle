#!/usr/bin/env python3
"""Verify the v1.11.5 Zone context and evidence foundation contract."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
toc = (root / "QuestChronicle.toc").read_text()
adapter = (root / "Core/Generation/Modes/ZoneLegacyAdapter.lua").read_text()
commands = (root / "Core/Chronicle/Commands.lua").read_text()
snapshot = (root / "Core/ZoneStyle/Zone/ContextResolver.lua").read_text()
compat = (root / "Core/ZoneStyle/Zone/Compatibility.lua").read_text()
affinity = (root / "Core/ZoneStyle/Zone/Affinity.lua").read_text()
report_builder = (root / "Core/Diagnostics/SnapshotBuilder.lua").read_text()
report_formatter = (root / "Core/Diagnostics/ReportFormatter.lua").read_text()
profile_registry = (root / "Core/ZoneStyle/Zone/ProfileRegistry.lua").read_text()
provenance_registry = (root / "Core/ZoneStyle/Zone/ProvenanceRegistry.lua").read_text()
starting_registry = (root / "Core/ZoneStyle/Zone/StartingZoneRegistry.lua").read_text()

required_modules = [
    r"Core\ZoneStyle\Zone\Foundation.lua",
    r"Core\ZoneStyle\Zone\EvidenceLedger.lua",
    r"Core\ZoneStyle\Zone\CanonicalStyles.lua",
    r"Core\ZoneStyle\Zone\ProfileRegistry.lua",
    r"Core\ZoneStyle\Zone\ProvenanceRegistry.lua",
    r"Core\ZoneStyle\Zone\StartingZoneRegistry.lua",
    r"Core\ZoneStyle\Zone\ContextResolver.lua",
    r"Core\ZoneStyle\Zone\Compatibility.lua",
    r"Core\ZoneStyle\Zone\Affinity.lua",
    r"Core\ZoneStyle\Zone\Debug.lua",
    r"Core\Generation\Modes\Zone\Context.lua",
    r"Core\Generation\Modes\Zone\Affinity.lua",
    r"Core\Generation\Modes\Zone\Diagnostics.lua",
]

checks = {
    "clean v1.11.5 metadata": "## Version: 1.11.5" in toc and (root / "VERSION.txt").read_text().strip() == "1.11.5",
    "all Zone foundation modules are listed exactly once": all(toc.count(path) == 1 for path in required_modules),
    "Zone remains truthful LEGACY generation": 'implementationGeneration = 1' in adapter and 'sharedFramework = false' in adapter and 'legacy = true' in adapter,
    "Zone foundation marker is exposed": 'zoneFoundation = "CONTEXT_EVIDENCE_V1"' in adapter,
    "Zone anchor policy is active while later policies remain disabled": all(token in adapter for token in ['zoneAnchorPolicy = true', 'zoneAnchorPolicyVersion = 1', 'zoneAnchorAuthority = "ACTIVE"', 'zoneSupportPolicy = false', 'zoneFinalValidation = false', 'zoneTuningAudit = false']),
    "validated profile registry exists": all(token in profile_registry for token in ['ValidateZoneProfile', 'RegisterZoneProfile', 'BootstrapProfileRegistry']),
    "validated provenance registry exists": all(token in provenance_registry for token in ['ValidateZoneProvenance', 'RegisterZoneProvenance', 'BootstrapProvenanceRegistry']),
    "validated starting-zone registry exists": all(token in starting_registry for token in ['ValidateStartingZoneCase', 'RegisterStartingZoneCase', 'BootstrapStartingZoneRegistry']),
    "immutable-copy snapshot API exists": all(token in snapshot for token in ['BuildZoneContextSnapshot', 'CopyPrimitive', 'snapshotCache', 'fingerprint']),
    "compatibility parity is measured": all(token in compat for token in ['BuildLegacyReference', 'CompareCompatibility', 'compatibilityStatus']),
    "Zone debug command is wired": '/qc zone debug [export]' in commands and 'HandleZoneDebugCommand' in commands,
    "read-only affinity exists": all(token in affinity for token in ['GetZoneAffinity', 'BuildSelectedOutfitAffinity', 'classification']),
    "Zone report snapshot is additive": 'zoneFoundation = BuildZoneFoundation' in report_builder,
    "Zone report formatting is additive": 'Zone Context and Evidence' in report_formatter and 'Compatibility parity:' in report_formatter,
    "foundation has no random calls": all('math.random' not in (root / path.replace('\\', '/')).read_text() for path in required_modules[:10]),
    "legacy scoring does not consume canonical style vectors": '.style.' not in (root / 'Core/ZoneStyle/Scoring.lua').read_text() and 'canonical' not in (root / 'Core/ZoneStyle/Scoring.lua').read_text().lower(),
    "no prerelease suffix": not re.search(r"1\.11\.0(?:a|b|rc|alpha|beta)", "\n".join(p.read_text(errors='ignore') for p in root.rglob('*') if p.is_file() and p.suffix in {'.lua','.toc','.md','.txt','.py'}), re.I),
}

failed = [name for name, ok in checks.items() if not ok]
if failed:
    print("FAIL: v1.11.5 Zone context foundation guard failed:")
    for name in failed:
        print("  -", name)
    raise SystemExit(1)
print(f"PASS: v1.11.5 Zone context foundation verification: {len(checks)} checks")
