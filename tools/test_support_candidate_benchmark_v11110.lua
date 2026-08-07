local clock=0
function debugprofilestop() return clock end
QuestChronicle={Wardrobe={_Private={}},ZoneStyle={Traveler={}},_Core={}}
local QC,P,T=QuestChronicle,QuestChronicle.Wardrobe._Private,QuestChronicle.ZoneStyle.Traveler
P.SUPPORT_SLOT_ORDER={"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}
P.slotByKey={}
for _,key in ipairs({"CHEST","LEGS","SHOULDER","ONE_HAND","OFF_HAND","WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}) do P.slotByKey[key]={key=key} end
local sourceMap={}
local function Source(id,v) local s={sourceID=id,visualID=id,_desc={v=v}}; sourceMap[id]=s; return s end
local anchors={CHEST=Source(1,.2),LEGS=Source(2,.35),SHOULDER=Source(3,.5),ONE_HAND=Source(4,.65),OFF_HAND=Source(5,.8)}
function P.GetSourceByID(_,id) return sourceMap[id] end
function P.IsAnchorActive() return true end
function P.GetActiveAnchorSource(_,_,key) if key=="WEAPON" then return anchors.ONE_HAND,"ONE_HAND" end return anchors[key],key end
function QuestChronicle.ZoneStyle.GetTravelerDescriptor(source) clock=clock+.15; return source and source._desc end
function T.GetPairCohesion(left,right) clock=clock+.75; return .2+left.v*.3+right.v*.4 end
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Wardrobe/SupportBudget.lua")
dofile(base.."Core/Wardrobe/SupportScoring.lua")
function P.ResolveSupportRole(slotKey) return {role=P.SUPPORT_SLOT_ROLES[slotKey],bridgeTargets=P.SUPPORT_BRIDGES[slotKey]} end
dofile(base.."Core/Wardrobe/SupportCandidateWork.lua")
local draft={selections={CHEST=1,LEGS=2,SHOULDER=3,ONE_HAND=4,OFF_HAND=5},hidden={},locks={}}
local profile={activeAnchorMask={CHEST=true,LEGS=true,SHOULDER=true,WEAPON=true}}
local maxStep=0; local completions=0
for nodeIndex=1,24 do
 local selected={}
 for i,key in ipairs(P.SUPPORT_SLOT_ORDER) do local s=Source(1000+nodeIndex*20+i,.1+i*.04); selected[key]={source=s,descriptor=s._desc} end
 local node={selected=selected,budget={starting=12,lockedCommitment=0,generatedSpend=0,borrowed=0,overrun=0,remaining=12}}
 for candidateIndex=1,32 do
  local source=Source(10000+nodeIndex*100+candidateIndex,.2+(candidateIndex%10)*.03)
  local candidate={slotKey=P.SUPPORT_SLOT_ORDER[(candidateIndex-1)%#P.SUPPORT_SLOT_ORDER+1],source=source,descriptor=source._desc,
   baseScore=10,profileFit=.7,mismatchCost=.5,repeatPenalty=0,outlierState="NORMAL",forceFallback=false}
  local work=P.CreateSupportCandidateWork(candidate,node,{draft=draft},profile,{},false)
  local guard=0
  while not work.done do
   local before=clock
   P.StepSupportCandidateWork(work)
   local elapsed=clock-before
   maxStep=math.max(maxStep,elapsed)
   guard=guard+1; assert(guard<100,"synthetic candidate work stalled")
  end
  completions=completions+1
 end
end
assert(completions==768,"synthetic beam candidate count changed")
assert(maxStep<4.0,string.format("support candidate substep exceeded 4 ms target: %.3f",maxStep))
print(string.format("PASS v1.11.10 support candidate benchmark: 768 candidates, max synthetic substep %.3f ms",maxStep))
