QuestChronicle={Wardrobe={_Private={}},ZoneStyle={_Private={},Zone={}},Generation={}}
local QC,P=QuestChronicle,QuestChronicle.Wardrobe._Private
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}
P.slotByKey={ONE_HAND={key="ONE_HAND"},OFF_HAND={key="OFF_HAND"}}
local sourceMap={}
local function Source(id,visual) local s={sourceID=id,visualID=visual or id}; sourceMap[id]=s; return s end
local main,off=Source(10,110),Source(11,111)
function P.GetSourceByID(_,id) return sourceMap[id] end
function P.AnchorSkeletonSignature() return "SIG" end
local function Candidate(source,slot)
 return {source=source,slotKey=slot,definition=P.slotByKey[slot],baseScore=source.sourceID*.75,anchorPolicy={finalRelevance=source.sourceID*.75}}
end
function P.EvaluateAnchorCandidateForJob(_,source,definition) return Candidate(source,definition.key) end
function P.ScoreAnchorRelationshipForJob(_,left,right)
 local l=tonumber(left.source and left.source.sourceID) or 0
 local r=tonumber(right.source and right.source.sourceID) or 0
 local pair=(l*13+r*7)%31/31
 local visual=pair*4.25
 local zone=(l+r)%5/10
 return visual+zone,pair,{},false,{visualBonus=visual,zonePairBonus=zone}
end
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Wardrobe/AnchorSkeletonSearch.lua")
dofile(base.."Core/Wardrobe/AnchorCandidateWork.lua")
-- For this fixture, candidate construction is already parity-tested separately. Make weapon work consume the same candidate oracle.
P.CreateAnchorCandidateWork=function(job,source,definition) return {job=job,source=source,definition=definition,stage="FIXTURE",done=false} end
P.DescribeNextAnchorCandidateOperation=function(work) return work.done and {class="COMPLETE",phase="COMPLETE",reserveMs=0} or {class="LOCAL",phase="FIXTURE",reserveMs=.5} end
P.StepAnchorCandidateWork=function(work)
 if work.done then return true,work.result end
 work.result=P.EvaluateAnchorCandidateForJob(work.job,work.source,work.definition)
 work.done=true; return true,work.result
end
local armor1={source=Source(1),slotKey="CHEST",baseScore=12}
local armor2={source=Source(2),slotKey="LEGS",baseScore=9}
local node={sources={armor1,armor2},sourceBySlot={CHEST=armor1,LEGS=armor2},score=48,meanPairCohesion=.61,hardClashes=0,activeComponents=2}
local draft={selections={ONE_HAND=10,OFF_HAND=11},lastWeaponRoute="ONE_HAND_PLUS_OFF_HAND"}
local job={styleMode="ZONE_NATIVE"}
local expected=assert(P.ScoreWeaponBundleForAnchor(node,draft,job.styleMode,{},job))
local work=P.CreateWeaponAnchorScoringWork(job,node,draft,{})
local guard=0
while not work.done do P.StepWeaponAnchorScoringWork(work); guard=guard+1; assert(guard<100,"weapon anchor worker stalled") end
local actual=assert(work.result)
local function Eq(a,b,path)
 path=path or "result"
 assert(type(a)==type(b),path.." type")
 if type(a)=="table" then
  for k,v in pairs(a) do Eq(v,b[k],path.."."..tostring(k)) end
  for k in pairs(b) do assert(a[k]~=nil,path.." missing "..tostring(k)) end
 elseif type(a)=="number" then assert(a==b,string.format("%s %.17g %.17g",path,a,b))
 else assert(a==b,path.." mismatch") end
end
Eq(expected,actual)
assert(guard>5,"weapon scorer did not decompose candidate/relationship work")
print("PASS v1.11.11 weapon anchor scoring: exact frozen-oracle aggregation parity across resumable candidates and relationships")
