QuestChronicle={_Core={Workers={}},Wardrobe={_Private={},GetZonePreferenceKey=function() return "zone" end,GetSourceZonePreference=function() return nil end},ZoneStyle={_Private={},expansions={}},GetSettings=function() return {restrictOutfitsToZoneEra=true} end}
local QC,Z,E,W=QuestChronicle,QuestChronicle.ZoneStyle,QuestChronicle.ZoneStyle._Private,QuestChronicle.Wardrobe._Private
for i=0,11 do Z.expansions[i]={label="E"..i,shortLabel="E"..i} end
function UnitClass() return "Warrior","WARRIOR",1 end; function UnitRace() return "Human","Human",1 end; function UnitLevel() return 70 end
function E.GetReachableMaxPlayerLevel() return 80 end
function E.Normalize(v) return string.lower(tostring(v or "")) end
function E.TextMatchesAny() return false end
function E.SafeCall(cb,...) return cb(...) end
function E.GetCuratedSourceOrigin() return nil end
function E.GetAppearanceTrackingType() return nil end
function E.SourceMetadata() return "" end; function E.GetDropOrigin() return "",nil end; function E.GetTrackedSourceOrigin() return nil end
E.provenanceByKey={}; E.provenanceOriginMarkers={}
function Z.GetCurrentContext() return {eraMax=2,eraLabel="TBC",provenanceResolved=true,provenanceKey="none"} end
function Z.ResolveEra() return 2,"TBC","TBC" end; function Z.ResolveProvenance() return nil,"none" end
function Z.GetSourcePreference() return nil end; function Z.GetSourcePreEraEligibility() return true,"eligible","ok" end
C_TransmogSets={GetSetsContainingSourceID=function() return {1} end,GetSetInfo=function() return {expansionID=1,name="Set"} end}
C_TransmogCollection={GetSourceInfo=function(id) return {itemID=1000+id,sourceType=1,name="S"} end,GetSourceItemID=function(id) return 1000+id end,GetAppearanceSourceDrops=function() return {} end}
C_Item={GetItemInfo=function() return "Item","link",2,1,1,"Armor","Plate",1,"INV",1,0,4,4,1,1 end}
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Workers/SliceBudget.lua"); dofile(base.."Core/Wardrobe/GenerationScheduling.lua")
dofile(base.."Core/ZoneStyle/EraExecution.lua"); dofile(base.."Core/ZoneStyle/EraEvidence.lua"); dofile(base.."Core/ZoneStyle/EraCandidateWork.lua")
dofile(base.."Core/ZoneStyle/EligibilityWork.lua"); dofile(base.."Core/ZoneStyle/GenerationEligibility.lua")
local source={sourceID=3,visualID=3,itemID=1003,sourceType=1,eraManifestVersion=E.ERA_MANIFEST_VERSION,eraSourceIDs={3},metadataRevision=0}
local context=Z.PrepareGenerationEligibilityContext(Z.GetCurrentContext())
local syncCalls=0; local real=Z.GetSourceEraEvidence; Z.GetSourceEraEvidence=function(s) syncCalls=syncCalls+1; return real(s) end
local job={currentSlice=QC._Core.Workers.BeginSlice(5.5,7.5)}; job.currentSlice.operationCount=1; W.generationJob=job
local work=Z.CreateSourceEligibilityWork(source,"ZONE_NATIVE",context,nil,true,{executionMode=E.ERA_EXECUTION_GENERATION_COOPERATIVE,schedulerOwner=job})
local deferred=false
for _=1,12 do
  local _,_,_,_,status=Z.StepSourceEligibilityWork(work,4)
  if status=="DEFERRED" then deferred=true; break end
end
assert(deferred,"raw cooperative eligibility never propagated nested era DEFERRED")
assert(syncCalls==0,"raw cooperative eligibility invoked synchronous era getter")
assert(work.stage=="ERA_STEP","raw eligibility advanced past a deferred era stage")
assert(job.currentSlice.forceYield==true,"raw eligibility deferral did not request a yield")
-- Resume with fresh slices until complete.
local guard=0
while not work.done and guard<100 do
  job.currentSlice=QC._Core.Workers.BeginSlice(5.5,7.5)
  local _,_,_,_,status=Z.StepSourceEligibilityWork(work,4)
  assert(status~="DEFERRED" or job.currentSlice.forceYield==true,"deferred status lacked yield request")
  guard=guard+1
end
assert(work.done and work.eligible,"raw cooperative eligibility did not complete after scheduler resumes")
-- Synchronous public eligibility must complete even with an ambient used generation slice.
job.currentSlice=QC._Core.Workers.BeginSlice(5.5,7.5); job.currentSlice.operationCount=1
local ok=Z.GetSourceEligibility(source,"ZONE_NATIVE",context,nil,true)
assert(ok==true,"synchronous public eligibility failed under ambient generation")
assert(job.currentSlice.forceYield~=true,"synchronous eligibility leaked into foreground admission")
assert(syncCalls==0,"synchronous public eligibility should own nested synchronous work directly")
print("PASS v1.11.9 raw eligibility owns nested era work in cooperative and synchronous modes")
