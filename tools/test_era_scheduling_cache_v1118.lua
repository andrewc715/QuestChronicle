QuestChronicle = {
  _Core = { Workers = {} },
  Wardrobe = { _Private = {} },
  ZoneStyle = { _Private = {}, expansions = {} },
}
local Z, P = QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle._Private
local W = QuestChronicle.Wardrobe._Private
for i=0,11 do Z.expansions[i]={label="Expansion "..i,shortLabel="E"..i} end
function P.Normalize(v) return string.lower(tostring(v or "")) end
function P.TextMatchesAny() return false end
function P.SafeCall(cb,...) return cb(...) end
function P.GetCuratedSourceOrigin() return nil end
function P.GetAppearanceTrackingType() return 1 end
P.trackedOriginCache={}
local calls={sets=0,setInfo=0,tracking=0,drops=0,item=0}
C_TransmogSets={
 GetSetsContainingSourceID=function() calls.sets=calls.sets+1 return {11} end,
 GetSetInfo=function() calls.setInfo=calls.setInfo+1 return {expansionID=3,name="Set"} end,
}
C_ContentTracking={GetBestMapForTrackable=function() calls.tracking=calls.tracking+1 return 2,nil end}
Enum={ContentTrackingResult={Failure=2},ContentTrackingType={Appearance=1}}
function P.GetTrackedSourceOrigin(candidate)
 calls.tracking=calls.tracking+1
 P.trackedOriginCache[candidate.sourceID]=false
 return nil
end
C_TransmogCollection={
 GetSourceInfo=function(id) return {itemID=1000+id,sourceType=1,name="S"..id} end,
 GetSourceItemID=function(id) return 1000+id end,
 GetAppearanceSourceDrops=function() calls.drops=calls.drops+1 return {} end,
}
C_Item={
 GetItemInfo=function(id) calls.item=calls.item+1 return "Item","link",2,1,1,"Armor","Plate",1,"INV",1,0,4,4,1,1 end,
 RequestLoadItemDataByID=function() end,
}
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Workers/SliceBudget.lua")
dofile(base.."Core/Wardrobe/GenerationScheduling.lua")
dofile(base.."Core/Wardrobe/SupportRerollScheduling.lua")
dofile("Core/ZoneStyle/EraExecution.lua")
dofile(base.."Core/ZoneStyle/EraEvidence.lua")
dofile(base.."Core/ZoneStyle/EraCandidateWork.lua")

local source={sourceID=1,visualID=1,eraManifestVersion=P.ERA_MANIFEST_VERSION,eraSourceIDs={1},metadataRevision=0}
W.generationJob={currentSlice=QuestChronicle._Core.Workers.BeginSlice(5.5,7.5)}
local work=Z.CreateSourceEraEvidenceWork(source,{forceRefresh=true,suppressCache=true,executionMode=P.ERA_EXECUTION_GENERATION_COOPERATIVE,schedulerOwner=W.generationJob})
-- BUILD and CURATED are ordinary operations.
Z.StepSourceEraEvidenceWork(work,1)
Z.StepSourceEraEvidenceWork(work,1)
assert(work.candidateWork.stage=="SET_LIST","fixture did not reach SET_LIST")
W.generationJob.currentSlice.operationCount = 2
W.generationJob.currentSlice.startedAtMs = -3
local beforeSets=calls.sets
local done,_,processed,status=Z.StepSourceEraEvidenceWork(work,1)
assert(not done and processed==0 and status=="DEFERRED","low-headroom SET_LIST was not deferred")
assert(calls.sets==beforeSets and work.candidateWork.stage=="SET_LIST","deferred SET_LIST mutated state")
assert((W.generationJob.eraApiHeadroomDeferrals or 0)==1,"API-headroom deferral counter missing")

-- Available headroom admits SET_LIST.
W.generationJob.currentSlice=QuestChronicle._Core.Workers.BeginSlice(5.5,7.5)
Z.StepSourceEraEvidenceWork(work,1)
assert(calls.sets==beforeSets+1 and work.candidateWork.stage=="SET_ENTRY","admitted SET_LIST did not execute exactly once")

-- Finish with a fresh slice whenever the descriptor requires it.
local guard=0
while not work.done and guard<100 do
 local _,fresh=Z.DescribeNextSourceEraEvidenceOperation(work)
 if fresh then W.generationJob.currentSlice=QuestChronicle._Core.Workers.BeginSlice(5.5,7.5) end
 local d=Z.StepSourceEraEvidenceWork(work,1)
 if W.generationJob.currentSlice.forceYield then W.generationJob.currentSlice=QuestChronicle._Core.Workers.BeginSlice(5.5,7.5) end
 guard=guard+1
end
assert(work.done,"scheduled era work did not finish")
W.generationJob=nil

-- Stable fragment reuse avoids the expensive evidence APIs after candidate build.
P.ClearEraCandidateFragmentCache()
for k in pairs(calls) do calls[k]=0 end
local first=Z.CreateSourceEraEvidenceWork(source,{forceRefresh=true,suppressCache=true})
while not first.done do Z.StepSourceEraEvidenceWork(first,1) end
local apiFirst=calls.sets+calls.setInfo+calls.tracking+calls.drops+calls.item
assert((first.fragmentCacheBuilds or 0)==1,"stable fragment was not memoized")
for k in pairs(calls) do calls[k]=0 end
local second=Z.CreateSourceEraEvidenceWork(source,{forceRefresh=true,suppressCache=true})
while not second.done do Z.StepSourceEraEvidenceWork(second,1) end
assert((second.fragmentCacheHits or 0)==1,"stable fragment was not reused")
assert(calls.sets+calls.setInfo+calls.tracking+calls.drops+calls.item==0,"fragment hit still ran evidence APIs")
assert(second.result.expansionID==first.result.expansionID,"fragment reuse changed aggregate evidence")

-- Item invalidation removes the matching fragment.
assert(P.InvalidateEraCandidateFragmentsForItem(1001)==1,"item invalidation did not clear fragment")
local third=Z.CreateSourceEraEvidenceWork(source,{forceRefresh=true,suppressCache=true})
while not third.done do Z.StepSourceEraEvidenceWork(third,1) end
assert((third.fragmentCacheHits or 0)==0,"stale fragment survived item invalidation")

print("PASS v1.11.10 headroom admission and stable fragment-cache invalidation")
