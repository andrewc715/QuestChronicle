#!/usr/bin/env python3
"""Verify v1.11.6 weapon-index invalidation lifecycle wiring and scope."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
index = (ROOT / "Core/Wardrobe/WeaponCandidateIndex.lua").read_text(encoding="utf-8")
routes = (ROOT / "Core/Wardrobe/EquipmentTopology.lua").read_text(encoding="utf-8")
scan = (ROOT / "Core/Wardrobe/CollectionScanAndPreview.lua").read_text(encoding="utf-8")
events = (ROOT / "Core/Wardrobe/Events.lua").read_text(encoding="utf-8")
comparison = (ROOT / "Core/Diagnostics/Comparison.lua").read_text(encoding="utf-8")
version = (ROOT / "VERSION.txt").read_text(encoding="utf-8").strip()
toc = (ROOT / "QuestChronicle.toc").read_text(encoding="utf-8")

canonical = {
    "NONE", "FORMAT_MISMATCH", "WARDROBE_CACHE_REPLACED",
    "COLLECTION_REVISION_CHANGED", "METADATA_REVISION_CHANGED",
    "CHARACTER_CAPABILITY_CHANGED", "APPEARANCE_COLLECTED",
    "EVIDENCE_OUTCOME_CHANGED", "ELIGIBILITY_OUTCOME_CHANGED",
    "LOGIN_SESSION_RESET", "MANUAL_DEBUG_RESET", "UNKNOWN",
}
route_calls = re.findall(r"InvalidateWeaponAppearanceRoutes\(([^)]*)\)", scan + "\n" + events)

checks = {
    "v1.11.6 metadata": version == "1.11.6" and "## Version: 1.11.6" in toc,
    "canonical registry is complete": all(f"{reason} = true" in index for reason in canonical),
    "session-only index starts with LOGIN_SESSION_RESET": 'weaponCandidateIndexInvalidationReason or "LOGIN_SESSION_RESET"' in index,
    "lifecycle sequence exists": "weaponCandidateIndexInvalidationSequence" in index and "NextInvalidationSequence" in index,
    "action snapshot captures sequence": "invalidationSequence = current.invalidationSequence" in index,
    "completed builds retain their processed cause": all(token in index for token in (
        "lastProcessedInvalidationReason",
        "lastProcessedInvalidationUnknownFallback",
        "lastProcessedInvalidationSequence",
    )),
    "warm and idle actions default to NONE": 'local invalidationReason, invalidationUnknownFallback = "NONE", false' in index,
    "build and repair actions retain lifecycle cause": "if built > 0 or repaired > 0 then" in index,
    "missing or unrecognized causes become UNKNOWN": index.count('return "UNKNOWN", true') >= 2,
    "identity changes are classified defensively": all(token in index for token in (
        'return "FORMAT_MISMATCH", false',
        'return "CHARACTER_CAPABILITY_CHANGED", false',
        'return "WARDROBE_CACHE_REPLACED", false',
    )),
    "route invalidation requires reason forwarding": "function Wardrobe.InvalidateWeaponAppearanceRoutes(reason)" in routes
        and "P.InvalidateWeaponCandidateIndex(reason)" in routes,
    "all production route invalidations provide an argument": bool(route_calls) and all(call.strip() for call in route_calls),
    "automatic login and manual scan are distinguished": 'cache.scanTrigger == "AUTO_LOGIN"' in scan
        and '"LOGIN_SESSION_RESET" or "WARDROBE_CACHE_REPLACED"' in scan,
    "collection additions use APPEARANCE_COLLECTED": 'indexReason = "APPEARANCE_COLLECTED"' in scan,
    "other collection mutations use COLLECTION_REVISION_CHANGED": 'indexReason = "COLLECTION_REVISION_CHANGED"' in scan,
    "capability entrypoints use CHARACTER_CAPABILITY_CHANGED": events.count('InvalidateWeaponAppearanceRoutes("CHARACTER_CAPABILITY_CHANGED")') >= 2,
    "warning is gated on final UNKNOWN reason": 'weaponIndex.invalidationReason == "UNKNOWN"' in comparison
        and "UNKNOWN_WEAPON_INDEX_INVALIDATION" in comparison,
    "runtime does not emit UNSPECIFIED": "UNSPECIFIED" not in index + routes + scan + events + comparison,
}

failed = [name for name, passed in checks.items() if not passed]
if failed:
    print("FAIL: weapon-index invalidation lifecycle verification failed:")
    for name in failed:
        print(f"- {name}")
    raise SystemExit(1)

print(f"PASS: v1.11.6 weapon-index invalidation lifecycle verification: {len(checks)} checks")
