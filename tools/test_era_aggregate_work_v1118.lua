QuestChronicle = { ZoneStyle = { _Private = {}, expansions = {} } }
local Z, P = QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle._Private
for i = 0, 11 do Z.expansions[i] = { label = "Expansion " .. i, shortLabel = "E" .. i } end
Z.expansions[1] = { label = "The Burning Crusade", shortLabel = "TBC" }
Z.expansions[3] = { label = "Cataclysm", shortLabel = "Cata" }
function P.Normalize(v) return string.lower(tostring(v or "")) end
function P.TextMatchesAny(text, values)
  text=P.Normalize(text); for _,v in ipairs(values or {}) do v=P.Normalize(v); if v~="" and text:find(v,1,true) then return true end end; return false
end
function P.SafeCall(cb, ...) return cb(...) end
function P.GetCuratedSourceOrigin() return nil end
function P.GetAppearanceTrackingType() return nil end
P.trackedOriginCache = {}

local bySource = {
  [1] = { item = 101, expansion = 3 },
  [2] = { item = 102, expansion = 1 },
  [3] = { item = 103, pending = true },
}
C_TransmogCollection = {
  GetSourceInfo = function(id) local r=bySource[id]; return { itemID=r.item, sourceType=1, name="S"..id } end,
  GetSourceItemID = function(id) return bySource[id].item end,
  GetAppearanceSourceDrops = function() return {} end,
}
C_TransmogSets = { GetSetsContainingSourceID=function() return {} end, GetSetInfo=function() return nil end }
C_Item = {
  GetItemInfo = function(itemID)
    for _,r in pairs(bySource) do if r.item==itemID then
      if r.pending then return nil end
      return "Item","link",2,1,1,"Armor","Plate",1,"INVTYPE_CHEST",1,0,4,4,1,r.expansion
    end end
  end,
  RequestLoadItemDataByID=function() end,
}

local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/ZoneStyle/EraEvidence.lua")
dofile(base.."Core/ZoneStyle/EraCandidateWork.lua")

local function clearSource(s)
  for k in pairs(s) do if tostring(k):match("^eraEvidence") then s[k]=nil end end
end
local source={ sourceID=1, visualID=77, eraManifestVersion=P.ERA_MANIFEST_VERSION, eraSourceIDs={1,2,3}, metadataRevision=0 }

local newCreate,newStep=P.CreateEraCandidateResolutionWork,P.StepEraCandidateResolutionWork
local runtimeResolve = P.ResolveEraCandidate
P.CreateEraCandidateResolutionWork=nil; P.StepEraCandidateResolutionWork=nil
P.ResolveEraCandidate = P.ResolveEraCandidateReference
local ref=Z.CreateSourceEraEvidenceWork(source,{forceRefresh=true,suppressCache=true})
while not ref.done do Z.StepSourceEraEvidenceWork(ref,1) end
local expected=ref.result
P.CreateEraCandidateResolutionWork = newCreate
P.StepEraCandidateResolutionWork = newStep
P.ResolveEraCandidate = runtimeResolve
clearSource(source); P.ClearEraCandidateFragmentCache()
local coop=Z.CreateSourceEraEvidenceWork(source,{forceRefresh=true,suppressCache=true})
local completed=0; local guard=0
while not coop.done and guard<200 do
  local done,result,processed=Z.StepSourceEraEvidenceWork(coop,1)
  completed=completed+(processed or 0); guard=guard+1
end
assert(coop.done and completed==3,"cooperative aggregate did not complete all siblings")
local actual=coop.result
for _,k in ipairs({"expansionID","provisionalExpansionID","pending","unknown","trackingPending","candidateCount"}) do
  assert(actual[k]==expected[k],"aggregate mismatch: "..k)
end
assert(actual.pendingItemIDs and expected.pendingItemIDs and actual.pendingItemIDs[1]==expected.pendingItemIDs[1],"pending item IDs changed")
assert(coop.siblingCompletions==3,"sibling completion counter changed")
assert((coop.candidateOperations or 0)>3,"candidate work was not decomposed into nested operations")
assert(coop.aggregateFinalizations==1,"aggregate finalization was not a separate operation")
print("PASS v1.11.8 nested aggregate era work preserves sibling and pending semantics")
