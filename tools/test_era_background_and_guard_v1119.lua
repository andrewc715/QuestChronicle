QuestChronicle={_Core={Workers={}},Wardrobe={_Private={}},ZoneStyle={_Private={},expansions={}}}
local QC,Z,E,W=QuestChronicle,QuestChronicle.ZoneStyle,QuestChronicle.ZoneStyle._Private,QuestChronicle.Wardrobe._Private
for i=0,11 do Z.expansions[i]={label="E"..i,shortLabel="E"..i} end
function E.Normalize(v) return string.lower(tostring(v or "")) end; function E.TextMatchesAny() return false end; function E.SafeCall(cb,...) return cb(...) end
function E.GetCuratedSourceOrigin() return nil end; function E.GetAppearanceTrackingType() return nil end
C_TransmogSets={GetSetsContainingSourceID=function() return {1,2,3} end,GetSetInfo=function(id) return {expansionID=id==1 and 1 or 2,name="Set"..id} end}
C_TransmogCollection={GetSourceInfo=function(id) return {itemID=1000+id,sourceType=1,name="S"} end,GetSourceItemID=function(id) return 1000+id end,GetAppearanceSourceDrops=function() return {} end}
C_Item={GetItemInfo=function() return "Item","link",2,1,1,"Armor","Plate",1,"INV",1,0,4,4,1,1 end}
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Workers/SliceBudget.lua"); dofile(base.."Core/Wardrobe/GenerationScheduling.lua")
dofile(base.."Core/ZoneStyle/EraExecution.lua"); dofile(base.."Core/ZoneStyle/EraEvidence.lua"); dofile(base.."Core/ZoneStyle/EraCandidateWork.lua")
local source={sourceID=5,visualID=5,itemID=1005,sourceType=1,eraManifestVersion=E.ERA_MANIFEST_VERSION,eraSourceIDs={5},metadataRevision=0}
-- Background work must ignore an unrelated used foreground slice.
W.generationJob={currentSlice=QC._Core.Workers.BeginSlice(5.5,7.5)}; W.generationJob.currentSlice.operationCount=20
local bg=Z.CreateSourceEraEvidenceWork(source,{forceRefresh=true,suppressCache=true,executionMode=E.ERA_EXECUTION_BACKGROUND_TICK})
local sawSet=false
for _=1,20 do
  local _,_,_,status=Z.StepSourceEraEvidenceWork(bg,1)
  assert(status~="DEFERRED","background tick was blocked by foreground ambient state")
  if bg.setListCalls and bg.setListCalls>0 then sawSet=true end
  if bg.done then break end
end
assert(sawSet,"background fixture never executed variable set work")
while not bg.done do local _,_,_,status=Z.StepSourceEraEvidenceWork(bg,1); assert(status~="DEFERRED","background force drain deferred") end
assert(bg.result and bg.result.expansionID==2,"background completion changed evidence")
-- Synchronous progress guard must stop a deliberately broken no-progress step.
local original=Z.StepSourceEraEvidenceWork
Z.StepSourceEraEvidenceWork=function(work) return false,nil,0,"PROGRESSED" end
local before=E.eraSynchronousProgressGuardTrips or 0
local guarded=Z.GetSourceEraEvidence({sourceID=99,visualID=99,eraManifestVersion=E.ERA_MANIFEST_VERSION,eraSourceIDs={99},metadataRevision=0})
assert(guarded and guarded.pending and guarded.synchronousGuard,"no-progress synchronous drain was not aborted")
assert((E.eraSynchronousProgressGuardTrips or 0)==before+1,"synchronous guard counter did not increment")
Z.StepSourceEraEvidenceWork=original
print("PASS v1.11.9 background isolation and synchronous no-progress watchdog guard")
