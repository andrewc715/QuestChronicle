local clock=0
function debugprofilestop() return clock end
QuestChronicle={_Core={Workers={}},Wardrobe={_Private={}},ZoneStyle={_Private={},Traveler={},Zone={}},Generation={}}
local QC,P,Z,ZP=QuestChronicle,QuestChronicle.Wardrobe._Private,QuestChronicle.ZoneStyle,QuestChronicle.ZoneStyle._Private
Z.MODE_ZONE_NATIVE="ZONE_NATIVE"
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Workers/SliceBudget.lua")
dofile(base.."Core/Wardrobe/GenerationScheduling.lua")
P.GenerationNowMilliseconds=function() return clock end
P.GENERATION_ERA_CANDIDATES_PER_OPERATION=1
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}; P.slotByKey={CHEST={key="CHEST"},ONE_HAND={key="ONE_HAND"},OFF_HAND={key="OFF_HAND"}}
local phases={}
function P.RecordGenerationPhase(_,key,elapsed)
 local e=phases[key] or {maxMs=0,totalMs=0,calls=0}; phases[key]=e
 e.maxMs=math.max(e.maxMs,elapsed); e.totalMs=e.totalMs+elapsed; e.calls=e.calls+1
end
ZP.sourceSetCache={}; ZP.trackedOriginCache={}
function ZP.IsSourceItemMetadataTrusted(s) return s.itemMetadataVerified==true end
function ZP.LoadItemMetadata(s) clock=clock+1.10; s.itemMetadataVerified=true; s.itemMetadataItemID=s.itemID; s.expansionID=1; return 1 end
function ZP.BuildSourceMetadataSnapshot(s) clock=clock+.30; return string.lower(s.name or "") end
function ZP.GetSourceSetIDs(s)
 if ZP.sourceSetCache[s.sourceID] then return ZP.sourceSetCache[s.sourceID] end
 clock=clock+1.05; ZP.sourceSetCache[s.sourceID]={41,42}; return ZP.sourceSetCache[s.sourceID]
end
function ZP.GetSourceStyleSignalsPrepared(_,text) clock=clock+.45; return {text=text,families={knightly=2},intensity=2} end
function ZP.GetAppearanceTrackingType() return 1 end
function ZP.GetTrackedSourceOrigin(s)
 if ZP.trackedOriginCache[s.sourceID]~=nil then return ZP.trackedOriginCache[s.sourceID] or nil end
 clock=clock+1.20; local o={provenanceKey="stormwind",expansionID=0}; ZP.trackedOriginCache[s.sourceID]=o; return o
end
function ZP.NewPreparedSourceInputs(s,era) return {source=s,expansionID=era and era.expansionID,expansionIDKnown=era~=nil,setIDsKnown=false,trackedOriginKnown=false} end
function Z.GetSourceCoherencePrepared() clock=clock+.75; return 7,true,"cohesive" end
function Z.ScoreSourcePrepared() clock=clock+2.20; return 22,{"fixture"} end
function Z.GetTravelerDescriptor(_,_,prepared) clock=clock+.90; return {setIDs=prepared.setIDs,palette={steel=1},material={plate=1},finish={military=1},motifs={alliance=1},confidence={},dominantMaterial="plate",dominantMotif="alliance",dominantPalette="steel",visualWeight=3} end
function Z.GetSourcePreference() clock=clock+.05; return "favorite" end
QC.Generation.ZoneAffinityPolicy={AnalyzeAppearance=function(_,_,_,prepared) clock=clock+.80; assert(prepared.trackedOriginKnown); return {score=.82,confidence=.65,classification="STRONGLY_NATIVE"} end}
Z.Zone={ApplyAnchorEvidence=function(candidate,affinity) clock=clock+.35; candidate.anchorPolicy={zoneAffinity=affinity.score,finalRelevance=candidate.baseScore+6}; candidate.baseScore=candidate.baseScore+6; return candidate end}
function ZP.GetSourceSetIDsPrepared() end
C_TransmogSets={GetSetsContainingSourceID=function() return {41,42} end}
C_ContentTracking={GetBestMapForTrackable=function() return 1 end}
function P.GetSourceByID() return nil end
local oldRandom=math.random; math.random=function() clock=clock+.02; return .42 end

dofile(base.."Core/Wardrobe/AnchorCandidateWork.lua")
dofile(base.."Core/Wardrobe/AnchorWorkerScheduling.lua")
local source={sourceID=901,visualID=1901,itemID=2901,name="Worst Case Anchor",itemMetadataVerified=false}
local job={styleMode=Z.MODE_ZONE_NATIVE,styleContext={},modeContext={fingerprint="ZCTX"},modePolicy={capabilities={zoneAnchorPolicy=true}},schedulerDiagnostics={expensiveCallYields=0,phaseTransitionYields=0,preventedPhaseTransitions=0,postExpensiveCallContinuations=0,maximumSliceDebtMs=0}}
local candidate={source=source,eraEvidence={expansionID=1}}
local maxSlice=0
local function NewSlice() job.currentSlice=P.BeginGenerationWorkerSlice() end
local function FinishSlice()
 maxSlice=math.max(maxSlice,clock-(job.currentSlice.startedAtMs or clock))
 P.AccumulateGenerationSliceDiagnostics(job)
 NewSlice()
end
NewSlice()
local guard=0
while true do
 local done=P.StepPreparedAnchorCandidateForWorker(job,candidate,P.slotByKey.CHEST,false)
 guard=guard+1; assert(guard<100,"anchor benchmark stalled")
 if done then break end
 if job.anchorCandidateYieldRequested or P.ShouldYieldGenerationWorker(job,.5) then
  job.anchorCandidateYieldRequested=nil; FinishSlice()
 end
end
maxSlice=math.max(maxSlice,clock-(job.currentSlice.startedAtMs or clock)); P.AccumulateGenerationSliceDiagnostics(job)
local pure={"anchorCandidateStyleSignals","anchorCandidateCoherence","anchorCandidateLegacyScore","anchorCandidateDescriptor","anchorCandidateRandom","anchorCandidateAffinity","anchorCandidatePolicy","anchorCandidateFinalize"}
local pureMax=0
for _,k in ipairs(pure) do pureMax=math.max(pureMax,tonumber(phases[k] and phases[k].maxMs) or 0) end
local apiMax=math.max(tonumber(phases.anchorCandidateMetadata and phases.anchorCandidateMetadata.maxMs) or 0,tonumber(phases.anchorCandidateSetIDs and phases.anchorCandidateSetIDs.maxMs) or 0,tonumber(phases.anchorCandidateTracking and phases.anchorCandidateTracking.maxMs) or 0)
assert(pureMax<4.0,string.format("pure anchor candidate subphase %.3f ms >= 4",pureMax))
assert(apiMax<8.0,string.format("anchor API subphase %.3f ms >= 8",apiMax))
assert(maxSlice<8.0,string.format("simulated warm slice %.3f ms >= 8",maxSlice))
assert((job.schedulerDiagnostics.maximumSliceDebtMs or 0)<=2.0,string.format("slice debt %.3f > 2",job.schedulerDiagnostics.maximumSliceDebtMs or 0))
assert((job.schedulerDiagnostics.postExpensiveCallContinuations or 0)==0,"post-expensive continuation detected")
assert((job.anchorCandidateAdmissionDeferrals or 0)<10,"anchor decomposition created excessive admission deferrals")
math.random=oldRandom
print(string.format("PASS v1.11.11 anchor benchmark: pure %.2f ms, API %.2f ms, simulated warm slice %.2f ms, debt %.2f ms",pureMax,apiMax,maxSlice,job.schedulerDiagnostics.maximumSliceDebtMs or 0))
