QuestChronicle = { ZoneStyle = { _Private = {}, expansions = {} } }
local Z, P = QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle._Private
for i=0,11 do Z.expansions[i]={label="Expansion "..i,shortLabel="E"..i} end
function P.Normalize(v) return string.lower(tostring(v or "")) end
function P.TextMatchesAny() return false end
function P.SafeCall(cb,...) return cb(...) end
function P.GetCuratedSourceOrigin() return nil end
function P.GetAppearanceTrackingType() return 1 end
P.trackedOriginCache={}

local mode="stable_none"
local calls={sets=0,tracking=0,drops=0,item=0,request=0}
C_TransmogSets={
 GetSetsContainingSourceID=function() calls.sets=calls.sets+1 return {} end,
 GetSetInfo=function() error("no set entry expected") end,
}
C_ContentTracking={GetBestMapForTrackable=function() return 2,nil end}
Enum={ContentTrackingResult={Failure=2,DataPending=1},ContentTrackingType={Appearance=1}}
function P.GetTrackedSourceOrigin(candidate)
 calls.tracking=calls.tracking+1
 if mode=="tracking_pending" then P.trackedOriginCache[candidate.sourceID]=nil return nil end
 P.trackedOriginCache[candidate.sourceID]=false
 return nil
end
C_TransmogCollection={
 GetSourceInfo=function(id) return {itemID=1000+id,sourceType=1,name="S"..id} end,
 GetSourceItemID=function(id) return 1000+id end,
 GetAppearanceSourceDrops=function() calls.drops=calls.drops+1 return {} end,
}
C_Item={
 GetItemInfo=function(id)
   calls.item=calls.item+1
   if mode=="item_pending" then return nil end
   if mode=="stable_none" then return nil end
   return "Item","link",2,1,1,"Armor","Plate",1,"INV",1,0,4,4,1,1
 end,
 RequestLoadItemDataByID=function() calls.request=calls.request+1 end,
}

local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/ZoneStyle/EraEvidence.lua")
dofile(base.."Core/ZoneStyle/EraCandidateWork.lua")

local function resetCalls()
 for key in pairs(calls) do calls[key]=0 end
end
local function finish(sourceID, itemID)
 local work=P.CreateEraCandidateResolutionWork(nil,sourceID)
 local guard=0
 while not work.done and guard<100 do P.StepEraCandidateResolutionWork(work); guard=guard+1 end
 assert(work.done,"candidate did not complete")
 return work
end

-- Stable no-evidence without an item getter is memoizable. Temporarily remove C_Item
-- so this is a genuinely stable no-evidence result rather than a pending item load.
P.ClearEraCandidateFragmentCache(); resetCalls(); mode="stable_none"
local savedItem=C_Item; C_Item=nil
local none1=finish(1,nil)
assert(none1.resultEvidence==nil and none1.candidatePending==false,"stable no-evidence tuple changed")
assert(none1.fragmentCacheBuilt==true,"stable no-evidence fragment was not cached")
local apiAfterFirst=calls.sets+calls.tracking+calls.drops
local none2=finish(1,nil)
assert(none2.fragmentCacheHit==true,"stable no-evidence fragment was not reused")
assert(calls.sets+calls.tracking+calls.drops==apiAfterFirst,"stable no-evidence cache hit reran evidence APIs")
C_Item=savedItem

-- Item-pending candidates must never be memoized.
P.ClearEraCandidateFragmentCache(); P.trackedOriginCache={}; resetCalls(); mode="item_pending"
local pending1=finish(2,1002)
assert(pending1.itemPending==true and pending1.candidatePending==true,"item-pending semantics changed")
assert(pending1.fragmentCacheBuilt~=true,"item-pending fragment was cached")
local requestsAfterFirst=calls.request
P.trackedOriginCache={}
local pending2=finish(2,1002)
assert(pending2.fragmentCacheHit~=true,"item-pending fragment was reused")
assert(calls.request>requestsAfterFirst,"item-pending candidate was not reevaluated")

-- Tracking-pending candidates must never be memoized even when item metadata is available.
P.ClearEraCandidateFragmentCache(); P.trackedOriginCache={}; resetCalls(); mode="tracking_pending"
local tracking1=finish(3,1003)
assert(tracking1.trackingPending==true and tracking1.candidatePending==true,"tracking-pending semantics changed")
assert(tracking1.resultEvidence==nil,"weak item evidence escaped tracking pending")
assert(tracking1.fragmentCacheBuilt~=true,"tracking-pending fragment was cached")
local trackingCalls=calls.tracking
P.trackedOriginCache={}
local tracking2=finish(3,1003)
assert(tracking2.fragmentCacheHit~=true,"tracking-pending fragment was reused")
assert(calls.tracking>trackingCalls,"tracking-pending candidate was not reevaluated")

print("PASS v1.11.8 fragment cache stores stable no-evidence and rejects item/tracking pending fragments")
