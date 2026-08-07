QuestChronicle = {
  _Core = { Workers = {} },
  Wardrobe = { _Private = {}, GetZonePreferenceKey=function() return "zone" end, GetSourceZonePreference=function() return nil end },
  ZoneStyle = { _Private = {}, expansions = {} },
  GetSettings = function() return { restrictOutfitsToZoneEra = true } end,
}
local QC, Z, E, W = QuestChronicle, QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle._Private, QuestChronicle.Wardrobe._Private
for i=0,11 do Z.expansions[i]={label="Expansion "..i,shortLabel="E"..i} end
function UnitClass() return "Warrior","WARRIOR",1 end
function UnitRace() return "Human","Human",1 end
function UnitLevel() return 70 end
function E.GetReachableMaxPlayerLevel() return 80 end
function E.Normalize(v) return string.lower(tostring(v or "")) end
function E.TextMatchesAny(text,values)
  text=E.Normalize(text); for _,v in ipairs(values or {}) do v=E.Normalize(v); if v~="" and text:find(v,1,true) then return true end end; return false
end
function E.SafeCall(cb,...) return cb(...) end
function E.GetCuratedSourceOrigin() return nil end
function E.GetAppearanceTrackingType() return nil end
E.provenanceByKey = {}
E.provenanceOriginMarkers = {}
function E.SourceMetadata() return "" end
function E.GetDropOrigin() return "",nil end
function E.GetTrackedSourceOrigin() return nil end
function Z.GetCurrentContext() return {eraMax=2,eraLabel="TBC",eraShortLabel="TBC",provenanceResolved=true,provenanceKey="none"} end
function Z.ResolveEra() return 2,"TBC","TBC" end
function Z.ResolveProvenance() return nil,"none" end
function Z.GetSourcePreference() return nil end
function Z.GetSourcePreEraEligibility() return true,"eligible","ok" end
function Z.GetSourceCoherence() return 1,true,"ok" end
function Z.WeightForSource() return 1 end
function QuestChronicle.Wardrobe.GetSlotDefinition() return {} end

local calls={setList=0,setInfo=0,syncGetter=0}
C_TransmogSets={
  GetSetsContainingSourceID=function() calls.setList=calls.setList+1 return {11} end,
  GetSetInfo=function() calls.setInfo=calls.setInfo+1 return {expansionID=1,name="Fixture"} end,
}
C_TransmogCollection={
  GetSourceInfo=function(id) return {itemID=1000+id,sourceType=1,name="Fixture"} end,
  GetSourceItemID=function(id) return 1000+id end,
  GetAppearanceSourceDrops=function() return {} end,
}
C_Item={GetItemInfo=function() return "Item","link",2,1,1,"Armor","Plate",1,"INV",1,0,4,4,1,1 end}

local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Workers/SliceBudget.lua")
dofile(base.."Core/Wardrobe/GenerationScheduling.lua")
dofile(base.."Core/ZoneStyle/EraExecution.lua")
dofile(base.."Core/ZoneStyle/EraEvidence.lua")
dofile(base.."Core/ZoneStyle/EraCandidateWork.lua")
dofile(base.."Core/ZoneStyle/EligibilityWork.lua")
dofile(base.."Core/ZoneStyle/GenerationEligibility.lua")
dofile(base.."Core/Wardrobe/WeaponStyleOrdering.lua")

local realGetter=Z.GetSourceEraEvidence
Z.GetSourceEraEvidence=function(source) calls.syncGetter=calls.syncGetter+1; return realGetter(source) end
local source={sourceID=7,visualID=7,itemID=1007,sourceType=1,eraManifestVersion=E.ERA_MANIFEST_VERSION,eraSourceIDs={7},metadataRevision=0}
local context=Z.PrepareGenerationEligibilityContext(Z.GetCurrentContext())
local job={currentSlice=QC._Core.Workers.BeginSlice(5.5,7.5),phaseStats={}}
job.currentSlice.operationCount=1
job.currentSlice.startedAtMs=-3
W.generationJob=job
local ordering=W.CreateWeaponStyleOrderingWork({{source=source,slotKey="MAIN_HAND"}},"ZONE_NATIVE",context,job)

local deferred=false
for _=1,12 do
  local beforeSerial=ordering.eligibilityWork and ordering.eligibilityWork.eraWork and ordering.eligibilityWork.eraWork.progressSerial
  local done=W.StepWeaponStyleOrderingWork(ordering)
  assert(done==false,"weapon ordering unexpectedly completed before deferral")
  local era=ordering.eligibilityWork and ordering.eligibilityWork.eraWork
  if era and era.lastStepDiagnostics and era.lastStepDiagnostics.deferred then
    assert(era.progressSerial==beforeSerial,"DEFERRED mutated era progress")
    assert((era.sameSliceDeferredRetries or 0)==0,"single outer step retried DEFERRED in the same slice")
    assert(job.currentSlice.forceYield==true,"DEFERRED did not request scheduler yield")
    deferred=true
    break
  end
end
assert(deferred,"fatal v1.11.8 route did not reach a fresh-slice deferral")
assert(calls.syncGetter==0,"weapon cached eligibility invoked synchronous era getter")
assert(calls.setList==0,"fresh-only set list executed on a used slice")

-- The same ambient used slice must not poison a legitimate synchronous getter.
job.currentSlice=QC._Core.Workers.BeginSlice(5.5,7.5)
job.currentSlice.operationCount=1
local guardBefore=E.eraSynchronousProgressGuardTrips or 0
local result=Z.GetSourceEraEvidence(source)
assert(result and result.expansionID==1,"synchronous getter did not complete authoritative evidence")
assert(job.currentSlice.forceYield~=true,"synchronous getter depended on foreground forceYield")
assert((E.eraSynchronousProgressGuardTrips or 0)==guardBefore,"synchronous getter tripped progress guard")
assert(calls.syncGetter==1,"synchronous getter wrapper count changed")

print("PASS v1.11.9 execution boundary: weapon eligibility returns on DEFERRED and synchronous era ignores ambient generation slices")
