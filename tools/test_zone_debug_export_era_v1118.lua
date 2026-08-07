QuestChronicle = {
    version = "1.11.10",
    ZoneStyle = {
        MODE_TRAVELER = "TRAVELER", MODE_ZONE_NATIVE = "ZONE_NATIVE",
        MODE_CLASS_FANTASY = "CLASS_FANTASY", MODE_CHRONICLE_ECHO = "CHRONICLE_ECHO",
        Zone = {}, _Private = {},
    },
    Generation = { POLICY_CONTRACT_VERSION = 1, API_CONTRACT_VERSION = 1 },
    Diagnostics = {}, Wardrobe = { _Private = {} },
}
local QC, ZoneStyle = QuestChronicle, QuestChronicle.ZoneStyle
local Zone = ZoneStyle.Zone
Zone.FOUNDATION_ID, Zone.AFFINITY_FORMAT = "CONTEXT_EVIDENCE_V1", 2
Zone.ANCHOR_POLICY_ID, Zone.ANCHOR_POLICY_AUTHORITY = "ZONE_ANCHOR_POLICY_V1", "ACTIVE"
Zone.AFFINITY_COMPONENT_STATUS = { VALUE="VALUE", MISSING="MISSING", NOT_APPLICABLE="NOT_APPLICABLE" }
Zone.ProfileRegistry = { order={"outland"}, collisions={} }
Zone.ProvenanceRegistry = { list={{}} }
Zone.StartingZoneRegistry = { list={{}} }
Zone.GetFoundationStatus = function() return { foundation=Zone.FOUNDATION_ID, contextFormat=1, profileRegistryVersion=1,
    provenanceRegistryVersion=1, startingZoneRegistryVersion=1, eraRuleVersion=1, affinityFormat=2,
    anchorPolicyFormat=1, anchorPolicyID=Zone.ANCHOR_POLICY_ID, anchorPolicyAuthority="ACTIVE" } end
ZoneStyle.GetZoneCompatibilityStatus = function() return { pass=true, differences={} } end
QC.Generation.GetModeCapabilities = function(modeID) return { displayLabel=modeID, implementation=modeID=="TRAVELER" and "SHARED_FRAMEWORK" or "LEGACY",
    implementationGeneration=1, zoneFoundation=modeID=="ZONE_NATIVE" and Zone.FOUNDATION_ID or nil } end
QC.Wardrobe._Private.GetSourceByID = function() return { name="Fixture" } end
local snapshot = { capturedAt=1, fingerprint="ZCTX-live", location={zone="Shadowmoon Valley",mapID=104,mapName="Shadowmoon Valley",mapTrail={"Outland"}},
    identity={label="Outland",profileKey="outland",description="Fixture",resolutionLevel="EXACT_ZONE",confidence=.9},
    era={shortLabel="TBC",maxExpansionID=1,resolutionLevel="MAP_TRAIL",confidence=.8}, provenance={label="Shadowmoon Valley",key="shadowmoon_outland",resolutionLevel="EXACT_ZONE",confidence=.9},
    restrictions={restrictionLabel="Through TBC",eraEnabled=true}, fallback={used=false}, style={coverage={}}, evidence={entries={},warnings={}} }
for _, channel in ipairs({"culture","climate","terrain","palette","material","finish","motif","magic","silhouette","avoids"}) do
    snapshot.style.coverage[channel] = channel=="avoids" and "NOT_APPLICABLE" or "KNOWN"
    snapshot.style[channel] = {}
end
local affinity = { selected=0, score=0, confidence=0, classifications={}, pieces={} }
ZoneStyle.GetZoneContextSnapshot = function() return snapshot end
Zone.BuildSelectedOutfitAffinity = function() return affinity end

local newest = { id="QCDBG-new", timestampText="2026-08-06 12:00:03", action="REROLL_SLOT", result="COMPLETED", mode="ZONE_NATIVE",
    zoneFoundation={foundation=Zone.FOUNDATION_ID,fingerprint="ZCTX-live",compatibility="PASS",affinity={}}, message="Legacy reroll" }
local malformed = { id="QCDBG-bad", mode="ZONE_NATIVE", zoneFoundation={anchorPolicy={policyID="ZONE_ANCHOR_POLICY_V1",snapshotFingerprint="ZCTX-bad"}} }
local fallbackOnly = { id="QCDBG-fallback-only", mode="ZONE_NATIVE", zoneFoundation={anchorPolicy={policyID="ZONE_ANCHOR_POLICY_V1",authority="ACTIVE",fallback="None"}} }
local policy = { id="QCDBG-policy", timestampText="2026-08-06 12:00:01", action="REROLL_UNLOCKED", result="COMPLETED", mode="ZONE_NATIVE",
    parentCompletedReportID="QCDBG-parent", anchorSourceReportID="QCDBG-policy", generationImplementation="LEGACY",
    zoneFoundation={foundation=Zone.FOUNDATION_ID,fingerprint="ZCTX-policy",compatibility="PASS",affinity={},anchorPolicy={
        policyID="ZONE_ANCHOR_POLICY_V1",authority="ACTIVE",snapshotFingerprint="ZCTX-policy",supportPolicy="LEGACY",selected={},pools={}
    }}, performance={longestWorkerSliceMs=7.2,largestInstrumentedCallPhase="weaponStyleEligibilityStep",largestInstrumentedCallMs=1.4,
        weaponCapabilities={status="REUSED",generation=4,buildsThisAction=0,reusesThisAction=4,staleAtCommit=false,eligibilitySteps=12,eligibilityYields=5},
        eraScheduling={operations=444,siblingCompletions=37,localOperations=390,apiOperations=54,apiAdmissions=54,apiHeadroomDeferrals=7,freshOnlyDeferrals=0,phantomDeferrals=0,sourceCacheCompletions=31,fragmentCacheCompletions=22,freshSliceDeferrals=0,fragmentCacheHits=22,fragmentCacheBuilds=15,
            pendingCandidateCompletions=2,aggregateFinalizations=37,largestSubphase="eraSetList",largestSubphaseMs=2.75},
        supportScheduling={eligibilitySteps=928,eligibilityYields=140,eligibilityMarkerBatch=4,beamStageFinalizations=7,
            beamFreshSliceDeferrals=7,beamStageFinalizeMaxMs=6.8,candidateSubsteps=1234,candidateCompletions=192,candidateDeferrals=4,largestCandidateSubphase="supportCandidateBridge",largestCandidateSubphaseMs=1.2,largestSubphase="supportBeamStageFinalize",largestSubphaseMs=6.8},
        scoringPotholes={anchor={substeps=440,completions=32,apiOperations=12,admissionDeferrals=4,largestSubphase="anchorCandidateDescriptor",largestSubphaseMs=1.7},
            supportBridge={targetResolutions=900,descriptorHits=899,descriptorFallbacks=1,candidatePairs=720,baselinePairs=180,admissionDeferrals=9,largestSubphase="supportCandidateBridgePair",largestSubphaseMs=1.5}},
        schedulerDiagnostics={maximumSliceDebtMs=0.4,postExpensiveCallContinuations=0}}, message="Policy reroll" }
QC.Diagnostics.GetReports = function() return { newest, malformed, fallbackOnly, policy } end

local root = debug.getinfo(1,"S").source:sub(2):gsub("tools/test_zone_debug_export_era_v1118.lua$","")
assert(loadfile(root.."Core/ZoneStyle/Zone/ExportEncoding.lua"))()
assert(loadfile(root.."Core/ZoneStyle/Zone/DebugExport.lua"))()
local text, status = Zone.BuildZoneDebugExport(snapshot, affinity)
for _, expected in ipairs({
    "Zone debug export format: `4`", "Source report: `QCDBG-policy`", "Latest Zone report carries policy: `NO`",
    "legacy action without an anchor-policy payload", "Parent report: `QCDBG-parent`", "Snapshot: `ZCTX-policy`",
    "## Zone Anchor Policy Performance", "Capability snapshot: `REUSED`", "Eligibility steps: `12` • eligibility yields: `5`",
    "Support eligibility steps: `928` • yields: `140` • batch: `4`", "Support stage finalizations: `7` • fresh-slice deferrals: `7`",
    "Support candidate scheduling: `1234` substeps • completions: `192` • admission deferrals: `4`",
    "Anchor candidate scheduling: `440` substeps • `32` completions • `12` API operations • `4` admission deferrals",
    "Support bridge scheduling: `900` targets • `899` descriptor hits • `1` descriptor fallbacks • `720` candidate pairs • `180` baseline pairs • `9` admission deferrals",
    "Largest support candidate subphase: `supportCandidateBridge` `1.20 ms`", "Largest support subphase: `supportBeamStageFinalize` `6.80 ms`",
    "Era operations: `444` • sibling completions: `37` • local: `390` • API: `54` • fragment-cache hits: `22`",
    "Era admission: `54` API admissions • headroom deferrals: `7` • fresh-only: `0` • phantom: `0`",
    "Largest era subphase: `eraSetList` `2.75 ms`",
    "Report ID: `QCDBG-new`", "Action: `REROLL_SLOT`",
}) do assert(text:find(expected,1,true), "missing lineage text: "..expected) end
assert(not text:find("QCDBG-bad",1,true), "malformed policy payload was selected")
assert(not text:find("QCDBG-fallback-only",1,true), "fallback without reason was treated as valid policy lineage")
assert(status.latestZoneReportID=="QCDBG-new" and status.latestPolicyReportID=="QCDBG-policy", "selector metadata is wrong")

policy.performance = {}
QC.Diagnostics.GetReports = function() return { newest, policy } end
local older = Zone.BuildZoneDebugExport(snapshot, affinity)
for _, expected in ipairs({
    "Worker slice: `Not recorded`", "Largest call: `Not recorded`",
    "Capability builds this action: `Not recorded`", "Eligibility steps: `Not recorded`",
    "Maximum slice debt: `Not recorded`", "Support eligibility steps: `Not recorded`",
    "Support stage finalizations: `Not recorded`", "Support candidate scheduling: `Not recorded`", "Largest support candidate subphase: `Not recorded`", "Largest support subphase: `Not recorded`",
    "Era operations: `Not recorded`", "Era admission: `Not recorded`", "Largest era subphase: `Not recorded`",
    "Anchor candidate scheduling: `Not recorded`", "Support bridge scheduling: `Not recorded`",
}) do assert(older:find(expected,1,true), "older policy performance should remain unknown: "..expected) end

QC.Diagnostics.GetReports = function() return {} end
local empty = Zone.BuildZoneDebugExport(snapshot, affinity)
assert(empty:find("No Zone anchor-policy report is currently available.",1,true), "empty policy history message missing")
assert(empty:find("No Zone Native generation report is currently available.",1,true), "empty Zone history message missing")
print("PASS v1.11.10 format-4 Zone export adds productive era and support scheduling while preserving independent policy lineage")
