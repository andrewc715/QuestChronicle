local clock = 0
function debugprofilestop() return clock end
QuestChronicle = { _Core={Workers={}}, Wardrobe={_Private={}}, ZoneStyle={_Private={},expansions={}} }
local QC, Z, P, W = QuestChronicle, QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle._Private, QuestChronicle.Wardrobe._Private
for i=0,11 do Z.expansions[i]={label="E"..i,shortLabel="E"..i} end
function P.Normalize(v) return string.lower(tostring(v or "")) end
function P.TextMatchesAny() return false end
function P.SafeCall(cb,...) return cb(...) end
function P.GetCuratedSourceOrigin() return nil end
function P.ResolveEraFromText() return nil end
function P.GetAppearanceTrackingType() return 1 end
P.trackedOriginCache = {}
local calls = { setList=0, setEntry=0, tracking=0, encounter=0, item=0 }
function P.GetTrackedSourceOrigin(candidate)
    local id = tonumber(candidate and candidate.sourceID)
    if P.trackedOriginCache[id] ~= nil then return P.trackedOriginCache[id] or nil end
    calls.tracking = calls.tracking + 1
    clock = clock + 0.35
    P.trackedOriginCache[id] = false
    return nil
end
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Workers/SliceBudget.lua")
dofile(base.."Core/Wardrobe/GenerationScheduling.lua")
dofile(base.."Core/ZoneStyle/EraExecution.lua")
dofile(base.."Core/ZoneStyle/EraEvidence.lua")
dofile(base.."Core/ZoneStyle/EraCandidateWork.lua")

local function Source(id)
    return { sourceID=id, visualID=id, itemID=1000+id, sourceType=1,
        eraManifestVersion=P.ERA_MANIFEST_VERSION, eraSourceIDs={id}, metadataRevision=0 }
end
local function NewJob()
    local job={currentSlice=QC._Core.Workers.BeginSlice(5.5,7.5)}
    W.generationJob=job
    return job
end
local function Run(work, job, limit)
    local guard=0
    while not work.done and guard < (limit or 200) do
        local done,_,_,status=Z.StepSourceEraEvidenceWork(work,1)
        assert(status~="DEFERRED","fixture unexpectedly deferred")
        if done then break end
        guard=guard+1
    end
    assert(work.done,"era work did not complete")
end

-- Zero variable API work must create zero admission tax, even on a nearly exhausted slice.
C_TransmogSets=nil; C_ContentTracking=nil; C_TransmogCollection={}; C_Item=nil; GetItemInfo=nil
P.trackedOriginCache[1]=false
clock=4.8
local job=NewJob(); job.currentSlice.startedAtMs=0
local zero=Z.CreateSourceEraEvidenceWork(Source(1),{forceRefresh=true,suppressCache=true,executionMode=P.ERA_EXECUTION_GENERATION_COOPERATIVE,schedulerOwner=job})
Run(zero,job)
assert((job.eraApiOperations or 0)==0,"zero-API fixture recorded API work")
assert((job.eraApiAdmissions or 0)==0,"zero-API fixture requested API admission")
assert((job.eraApiHeadroomDeferrals or 0)==0,"zero-API fixture paid a headroom deferral")
assert((job.eraFreshOnlyDeferrals or 0)==0,"zero-API fixture paid a fresh-only deferral")
assert((job.eraPhantomDeferrals or 0)==0,"zero-API fixture recorded a phantom deferral")
assert((job.eraDeferredReturns or 0)==0,"zero-API fixture returned to scheduler unnecessarily")

-- Completed source cache and fragment cache paths also pay no admission tax.
clock=0
local cachedSource=Source(5)
local seed=Z.CreateSourceEraEvidenceWork(cachedSource,{forceRefresh=true})
while not seed.done do Z.StepSourceEraEvidenceWork(seed,1) end
job=NewJob(); clock=4.8; job.currentSlice.startedAtMs=0
local cached=Z.CreateSourceEraEvidenceWork(cachedSource,{executionMode=P.ERA_EXECUTION_GENERATION_COOPERATIVE,schedulerOwner=job})
assert(cached.done and cached.cached,"completed source cache did not return immediately")
assert((job.eraSourceCacheCompletions or 0)==1,"source-cache completion was not counted")
assert((job.eraApiAdmissions or 0)==0 and (job.eraDeferredReturns or 0)==0,"source cache paid API admission tax")
P.ClearEraCandidateFragmentCache()
local fragmentSource=Source(6)
local fragmentSeed=Z.CreateSourceEraEvidenceWork(fragmentSource,{forceRefresh=true,suppressCache=true})
while not fragmentSeed.done do Z.StepSourceEraEvidenceWork(fragmentSeed,1) end
assert((fragmentSeed.fragmentCacheBuilds or 0)==1,"fragment seed was not memoized")
job=NewJob(); clock=4.8; job.currentSlice.startedAtMs=0
local fragment=Z.CreateSourceEraEvidenceWork(fragmentSource,{forceRefresh=true,suppressCache=true,executionMode=P.ERA_EXECUTION_GENERATION_COOPERATIVE,schedulerOwner=job})
while not fragment.done do
 local _,_,_,fragmentStatus=Z.StepSourceEraEvidenceWork(fragment,1)
 assert(fragmentStatus~="DEFERRED","fragment cache hit requested scheduler admission")
end
assert((fragment.fragmentCacheHits or 0)==1,"cooperative fragment cache hit was not observed")
assert((job.eraApiAdmissions or 0)==0 and (job.eraDeferredReturns or 0)==0,"fragment cache paid API admission tax")

-- Several cheap real API calls may share one slice when headroom remains.
for k in pairs(calls) do calls[k]=0 end
P.trackedOriginCache={}; clock=0
C_TransmogSets={
    GetSetsContainingSourceID=function() calls.setList=calls.setList+1; clock=clock+0.35; return {11} end,
    GetSetInfo=function() calls.setEntry=calls.setEntry+1; clock=clock+0.35; return {expansionID=1,name="Fixture"} end,
}
C_ContentTracking={GetBestMapForTrackable=function() return 2,nil end}
C_TransmogCollection={GetAppearanceSourceDrops=function() calls.encounter=calls.encounter+1; clock=clock+0.35; return {} end}
C_Item={GetItemInfo=function() calls.item=calls.item+1; clock=clock+0.35; return "Item","link",2,1,1,"Armor","Plate",1,"INV",1,0,4,4,1,1 end}
job=NewJob()
local shared=Z.CreateSourceEraEvidenceWork(Source(2),{forceRefresh=true,suppressCache=true,executionMode=P.ERA_EXECUTION_GENERATION_COOPERATIVE,schedulerOwner=job})
Run(shared,job)
assert(calls.setList==1 and calls.setEntry==1 and calls.tracking==1 and calls.encounter==1,"cheap API fixture call shape changed")
assert((job.eraApiOperations or 0)==4,"cheap API operations were not counted")
assert((job.eraApiAdmissions or 0)==4,"cheap API admissions were not counted")
assert((job.eraApiHeadroomDeferrals or 0)==0,"cheap API operations were unnecessarily split across frames")
assert(clock < 2,"cheap API fixture consumed unexpected time")

-- Insufficient headroom denies an API boundary without mutating candidate work.
for k in pairs(calls) do calls[k]=0 end
P.trackedOriginCache={}; clock=0
job=NewJob()
local denied=Z.CreateSourceEraEvidenceWork(Source(3),{forceRefresh=true,suppressCache=true,executionMode=P.ERA_EXECUTION_GENERATION_COOPERATIVE,schedulerOwner=job})
Z.StepSourceEraEvidenceWork(denied,1) -- BUILD
Z.StepSourceEraEvidenceWork(denied,1) -- CURATED
assert(denied.candidateWork.stage=="SET_LIST","denial fixture did not reach SET_LIST")
clock=3.0
local beforeSerial=denied.progressSerial
local beforeStage=denied.candidateWork.stage
local done,_,processed,status=Z.StepSourceEraEvidenceWork(denied,1)
assert(not done and processed==0 and status=="DEFERRED","low-headroom API stage was not deferred")
assert(denied.progressSerial==beforeSerial and denied.candidateWork.stage==beforeStage,"denied admission mutated era work")
assert(calls.setList==0,"denied admission crossed the API boundary")
assert((job.eraApiHeadroomDeferrals or 0)==1 and job.currentSlice.forceYield==true,"headroom deferral diagnostics missing")
assert((job.eraSameSliceDeferredRetries or 0)==0,"single denial was misclassified as same-slice retry")

-- An actually expensive admitted API call force-yields before the next API operation.
for k in pairs(calls) do calls[k]=0 end
P.trackedOriginCache={}; clock=0
C_TransmogSets.GetSetsContainingSourceID=function() calls.setList=calls.setList+1; clock=clock+2.2; return {11} end
job=NewJob()
local expensive=Z.CreateSourceEraEvidenceWork(Source(4),{forceRefresh=true,suppressCache=true,executionMode=P.ERA_EXECUTION_GENERATION_COOPERATIVE,schedulerOwner=job})
Z.StepSourceEraEvidenceWork(expensive,1); Z.StepSourceEraEvidenceWork(expensive,1)
local started=clock
local _,_,_,s1=Z.StepSourceEraEvidenceWork(expensive,1)
assert(s1~="DEFERRED" and calls.setList==1,"expensive set-list call did not execute once")
QC._Core.Workers.NoteCall(job.currentSlice,clock-started)
assert(job.currentSlice.forceYield==true,"expensive API call did not force-yield")
local setEntryBefore=calls.setEntry
local _,_,_,s2=Z.StepSourceEraEvidenceWork(expensive,1)
assert(s2=="DEFERRED" and calls.setEntry==setEntryBefore,"post-expensive API operation continued in the same slice")

print("PASS v1.11.10 productive era admission: no phantom tax, shared cheap headroom, immutable denial, expensive force-yield")
