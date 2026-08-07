QuestChronicle = {
  _Core={Workers={}}, Wardrobe={_Private={}},
  ZoneStyle={_Private={},expansions={}},
}
local Z,P,W=QuestChronicle.ZoneStyle,QuestChronicle.ZoneStyle._Private,QuestChronicle.Wardrobe._Private
for i=0,11 do Z.expansions[i]={label="Expansion "..i,shortLabel="E"..i} end
function P.Normalize(v) return string.lower(tostring(v or "")) end
function P.TextMatchesAny(text,values)
 text=P.Normalize(text); for _,v in ipairs(values or {}) do v=P.Normalize(v); if v~="" and text:find(v,1,true) then return true end end; return false
end
function P.SafeCall(cb,...) return cb(...) end
function P.GetCuratedSourceOrigin() return nil end
function P.GetAppearanceTrackingType() return 1 end
P.trackedOriginCache={}
local calls={setList=0,setEntry=0,tracking=0,dropList=0,item=0}
C_TransmogSets={
 GetSetsContainingSourceID=function() calls.setList=calls.setList+1 return {11,12} end,
 GetSetInfo=function(id) calls.setEntry=calls.setEntry+1 return {expansionID=id==11 and 1 or 3,name="Set"..id} end,
}
C_ContentTracking={GetBestMapForTrackable=function() return 2,nil end}
Enum={ContentTrackingResult={Failure=2},ContentTrackingType={Appearance=1}}
function P.GetTrackedSourceOrigin(candidate) calls.tracking=calls.tracking+1; P.trackedOriginCache[candidate.sourceID]=false; return nil end
C_TransmogCollection={
 GetSourceInfo=function(id) return {itemID=1000+id,sourceType=1,name="S"..id} end,
 GetSourceItemID=function(id) return 1000+id end,
 GetAppearanceSourceDrops=function()
   calls.dropList=calls.dropList+1
   return {{instance="Unknown",encounter="Boss",tiers={"UnknownA","UnknownB"}},{instance="Unknown2",encounter="Boss2",tiers={"UnknownC"}}}
 end,
}
C_Item={GetItemInfo=function(id) calls.item=calls.item+1 return "Item","link",2,1,1,"Armor","Plate",1,"INV",1,0,4,4,1,1 end}
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Workers/SliceBudget.lua")
dofile(base.."Core/Wardrobe/GenerationScheduling.lua")
dofile(base.."Core/Wardrobe/SupportRerollScheduling.lua")
dofile("Core/ZoneStyle/EraExecution.lua")
dofile(base.."Core/ZoneStyle/EraEvidence.lua")
dofile(base.."Core/ZoneStyle/EraCandidateWork.lua")

local candidate={sourceID=7,itemID=1007,sourceType=1,name="Fixture"}
local work=P.CreateEraCandidateResolutionWork(nil,7,{candidate=candidate,skipFragmentCache=true})
local previous={setList=0,setEntry=0,tracking=0,dropList=0,item=0}
local stages={}
while not work.done do
 local op=P.DescribeNextEraCandidateOperation(work)
 stages[#stages+1]=op
 P.StepEraCandidateResolutionWork(work)
 for key,value in pairs(calls) do
   assert(value-(previous[key] or 0)<=1,"one candidate step performed multiple "..key.." callbacks")
   previous[key]=value
 end
end
assert(calls.setList==1 and calls.setEntry==2 and calls.tracking==1 and calls.dropList==1,"external operation counts changed")
assert(calls.item==0,"encounter-or-stronger set evidence should skip item metadata")
local expected={"CURATED","SET_LIST","SET_ENTRY","SET_ENTRY","TRACKING","ENCOUNTER_LIST","ENCOUNTER_DROP","ENCOUNTER_TIER","ENCOUNTER_TIER","ENCOUNTER_DROP","ENCOUNTER_TIER","ENCOUNTER_RESOLVE","EARLY_DECISION","FINALIZE"}
assert(#stages==#expected,"candidate stage count changed")
for i,name in ipairs(expected) do assert(stages[i]==name,string.format("stage %d mismatch: %s vs %s",i,tostring(stages[i]),name)) end

-- Every variable-cost operation defers from an already-used generation slice without mutation.
local function assertFreshDeferral(stage, setup)
 local cw=P.CreateEraCandidateResolutionWork(nil,9,{candidate={sourceID=9,itemID=1009,sourceType=1},skipFragmentCache=true})
 setup(cw)
 W.generationJob={currentSlice=QuestChronicle._Core.Workers.BeginSlice(5.5,7.5)}
 local outer={candidateWork=cw,lastStepDiagnostics=nil,executionMode=P.ERA_EXECUTION_GENERATION_COOPERATIVE,schedulerOwner=W.generationJob,progressSerial=0}
 W.generationJob.currentSlice.operationCount=1
 local before={stage=cw.stage,setIndex=cw.setIndex,dropIndex=cw.dropIndex,item=calls.item,setList=calls.setList,tracking=calls.tracking,dropList=calls.dropList}
 local op,fresh=P.DescribeNextEraCandidateOperation(cw)
 assert(op==stage and fresh==true,"fixture did not target fresh stage "..stage)
 assert(P.AdmitEraEvidenceOperation(outer,op,fresh)==false,"used slice admitted "..stage)
 assert(cw.stage==before.stage and cw.setIndex==before.setIndex and cw.dropIndex==before.dropIndex,"deferred "..stage.." mutated work")
 assert(calls.item==before.item and calls.setList==before.setList and calls.tracking==before.tracking and calls.dropList==before.dropList,"deferred "..stage.." ran an API")
 assert((W.generationJob.eraFreshSliceDeferrals or 0)==1,"fresh deferral counter missing for "..stage)
 W.generationJob=nil
end
assertFreshDeferral("SET_LIST",function(cw) cw.stage="SET_LIST" end)
assertFreshDeferral("TRACKING",function(cw) cw.stage="TRACKING" end)
assertFreshDeferral("ENCOUNTER_LIST",function(cw) cw.stage="ENCOUNTER_LIST" end)
assertFreshDeferral("ITEM_METADATA",function(cw) cw.stage="ITEM_METADATA" end)

print("PASS v1.11.8 era operation granularity and fresh admission for all variable API stages")
