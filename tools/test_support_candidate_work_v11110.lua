QuestChronicle={Wardrobe={_Private={}},ZoneStyle={Traveler={}},_Core={}}
local QC,P,T=QuestChronicle,QuestChronicle.Wardrobe._Private,QuestChronicle.ZoneStyle.Traveler
P.SUPPORT_SLOT_ORDER={"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}
P.slotByKey={}
for _,key in ipairs({"CHEST","LEGS","SHOULDER","ONE_HAND","OFF_HAND","WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}) do P.slotByKey[key]={key=key} end
local sourceMap={}
local function Desc(v) return {v=v} end
local function Source(id,v) local s={sourceID=id,visualID=id,_desc=Desc(v)}; sourceMap[id]=s; return s end
local anchors={CHEST=Source(1,.2),LEGS=Source(2,.4),SHOULDER=Source(3,.6),ONE_HAND=Source(4,.8),OFF_HAND=Source(5,.7)}
local supportSources={}
for i,key in ipairs(P.SUPPORT_SLOT_ORDER) do supportSources[key]=Source(20+i,.1+i*.07) end
function P.GetSourceByID(_,id) return sourceMap[id] end
function P.IsAnchorActive(mask,key) return not mask or mask[key]~=false end
function P.GetActiveAnchorSource(_,state,key)
 if key=="WEAPON" then return anchors.ONE_HAND,"ONE_HAND" end
 return anchors[key],key
end
function QuestChronicle.ZoneStyle.GetTravelerDescriptor(source) return source and source._desc end
function T.GetPairCohesion(left,right) return left.v*.37+right.v*.41+.1 end
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Wardrobe/SupportBudget.lua")
dofile(base.."Core/Wardrobe/SupportScoring.lua")
function P.ResolveSupportRole(slotKey) return {role=P.SUPPORT_SLOT_ROLES[slotKey],bridgeTargets=P.SUPPORT_BRIDGES[slotKey]} end
dofile(base.."Core/Wardrobe/SupportCandidateWork.lua")
dofile(base.."Core/Wardrobe/SupportBeam.lua")

local draft={selections={CHEST=1,LEGS=2,SHOULDER=3,ONE_HAND=4,OFF_HAND=5},hidden={},locks={}}
local nodeSelected={}
for _,key in ipairs(P.SUPPORT_SLOT_ORDER) do nodeSelected[key]={source=supportSources[key],descriptor=supportSources[key]._desc} end
local node={selected=nodeSelected,budget={starting=12,lockedCommitment=0,generatedSpend=0,borrowed=0,overrun=0,remaining=12}}
local job={draft=draft}
local profile={activeAnchorMask={CHEST=true,LEGS=true,SHOULDER=true,WEAPON=true}}

local function Candidate(slot,index,cost)
 return {slotKey=slot,source=Source(100+index,.22+index*.03),descriptor=Desc(.22+index*.03),baseScore=11+index,
  profileFit=.61+index*.01,mismatchCost=cost or .45,repeatPenalty=index%2==0 and .25 or 0,
  outlierState=index%3==0 and "ACCENT" or "NORMAL",forceFallback=false}
end
local function AssertEqual(a,b,path)
 path=path or "decision"
 if type(a)~=type(b) then error(path.." type mismatch") end
 if type(a)=="table" then
  for k,v in pairs(a) do AssertEqual(v,b[k],path.."."..tostring(k)) end
  for k in pairs(b) do assert(a[k]~=nil,path.." missing key "..tostring(k)) end
 elseif type(a)=="number" then assert(a==b,string.format("%s numeric mismatch %.17g vs %.17g",path,a,b))
 else assert(a==b,path.." mismatch") end
end

-- Every support slot must reproduce the synchronous semantic oracle exactly.
for i,slot in ipairs(P.SUPPORT_SLOT_ORDER) do
 local candidate=Candidate(slot,i,.35+i*.04)
 local expected=P.ScoreSupportCandidate(candidate,node,job,profile,{"HEAD","BACK"},false)
 local work=P.CreateSupportCandidateWork(candidate,node,job,profile,{"HEAD","BACK"},false)
 local steps=0
 while not work.done do P.StepSupportCandidateWork(work); steps=steps+1; assert(steps<100,"candidate worker stalled") end
 assert(steps>3,"candidate worker did not decompose relationships")
 AssertEqual(expected,work.decision,slot)
end

-- Partial scoring cannot mutate a beam node or nextBeam before COMPLETE.
local beamCandidate=Candidate("WAIST",20,.4)
local beam=P.CreateSupportBeamWork(job,profile,node.budget,{"WAIST"},{WAIST={beamCandidate}}, {}, {})
local partialSteps=0
while not beam.lastCandidateCompleted do
 P.StepSupportBeamWork(beam); partialSteps=partialSteps+1
 if not beam.lastCandidateCompleted then assert(#beam.nextBeam==0,"partial candidate mutated nextBeam") end
 assert(partialSteps<100,"beam candidate worker stalled")
end
assert(#beam.nextBeam==1,"completed allowed candidate did not extend beam")
assert((beam.expansions.WAIST or 0)==1,"candidate expansion counted before/after completion incorrectly")

-- Fallback remains cooperative and preserves strict-lower first-best tie behavior.
local fbPool={Candidate("WAIST",31,4),Candidate("WAIST",32,2),Candidate("WAIST",33,2)}
fbPool[1].source.visualID=301; fbPool[2].source.visualID=302; fbPool[3].source.visualID=303
local fallback=P.CreateSupportBeamWork(job,profile,node.budget,{"WAIST"},{WAIST=fbPool}, {}, {})
local guard=0
while fallback.stageIndex<=1 and guard<1000 do P.StepSupportBeamWork(fallback); guard=guard+1 end
assert(guard<1000,"fallback worker stalled")
assert(fallback.beam[1] and fallback.beam[1].selected.WAIST,"fallback did not produce a selection")
assert(fallback.beam[1].selected.WAIST.source.visualID==302,"equal mismatch fallback did not preserve first-best tie")

print("PASS v1.11.10 support candidate worker: oracle parity, no partial commit, cooperative fallback tie parity")
