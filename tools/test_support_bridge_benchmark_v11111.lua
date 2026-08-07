local clock=0
function debugprofilestop() return clock end
QuestChronicle={Wardrobe={_Private={}},ZoneStyle={Traveler={}}}
local QC,P,T=QuestChronicle,QuestChronicle.Wardrobe._Private,QuestChronicle.ZoneStyle.Traveler
P.SUPPORT_SLOT_ORDER={"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}; P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}; P.slotByKey={}
for _,k in ipairs({"CHEST","LEGS","SHOULDER","ONE_HAND","OFF_HAND","WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}) do P.slotByKey[k]={key=k} end
local sourceMap={}; local function Source(id,v) local s={sourceID=id,visualID=id,_desc={v=v}}; sourceMap[id]=s; return s end
local anchors={CHEST=Source(1,.2),LEGS=Source(2,.35),SHOULDER=Source(3,.5),ONE_HAND=Source(4,.65),OFF_HAND=Source(5,.8)}
function P.GetSourceByID(_,id) return sourceMap[id] end
function P.IsAnchorActive() return true end
function P.GetActiveAnchorSource(_,_,key) if key=="WEAPON" then return anchors.ONE_HAND,"ONE_HAND" end return anchors[key],key end
local descriptorCalls=0
function QC.ZoneStyle.GetTravelerDescriptor(source) descriptorCalls=descriptorCalls+1; clock=clock+.9; return source and source._desc end
function T.GetPairCohesion(left,right) clock=clock+.75; return .2+left.v*.3+right.v*.4 end
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Wardrobe/SupportBudget.lua"); dofile(base.."Core/Wardrobe/SupportScoring.lua")
function P.ResolveSupportRole(slotKey) return {role=P.SUPPORT_SLOT_ROLES[slotKey],bridgeTargets=P.SUPPORT_BRIDGES[slotKey]} end
dofile(base.."Core/Wardrobe/SupportCandidateWork.lua"); dofile(base.."Core/Wardrobe/SupportBeam.lua")
local draft={selections={CHEST=1,LEGS=2,SHOULDER=3,ONE_HAND=4,OFF_HAND=5},hidden={},locks={}}
local profile={activeAnchorMask={CHEST=true,LEGS=true,SHOULDER=true,WEAPON=true},entries={}}
for key,s in pairs(anchors) do profile.entries[#profile.entries+1]={source=s,slotKey=key,descriptor=s._desc} end
local bridgeMax=0; local completions=0
for nodeIndex=1,24 do
 local selected={}
 for i,key in ipairs(P.SUPPORT_SLOT_ORDER) do local s=Source(1000+nodeIndex*20+i,.1+i*.04); selected[key]={source=s,descriptor=s._desc} end
 local node={selected=selected,budget={starting=12,lockedCommitment=0,generatedSpend=0,borrowed=0,overrun=0,remaining=12}}
 for candidateIndex=1,32 do
  local s=Source(10000+nodeIndex*100+candidateIndex,.2+(candidateIndex%10)*.03)
  local candidate={slotKey=P.SUPPORT_SLOT_ORDER[(candidateIndex-1)%8+1],source=s,descriptor=s._desc,baseScore=10,profileFit=.7,mismatchCost=.5,repeatPenalty=0,outlierState="NORMAL",forceFallback=false}
  local work=P.CreateSupportCandidateWork(candidate,node,{draft=draft},profile,{},false); local guard=0
  while not work.done do
   local op=P.DescribeSupportCandidateWorkOperation(work); local before=clock; P.StepSupportCandidateWork(work); local elapsed=clock-before
   if op:find("^BRIDGE") then bridgeMax=math.max(bridgeMax,elapsed) end
   guard=guard+1; assert(guard<100,"support bridge benchmark stalled")
  end
  assert((work.descriptorFallbacks or 0)==0,"prepared bridge target unexpectedly rebuilt descriptor")
  completions=completions+1
 end
end
assert(completions==768,"support bridge benchmark candidate count changed")
assert(descriptorCalls==0,"prepared anchor/node bridge targets invoked GetTravelerDescriptor")
assert(bridgeMax<4.0,string.format("support bridge microphase %.3f ms >= 4",bridgeMax))
-- Fallback candidates use the same worker and retain strict-lower first-best tie semantics.
local pool={}
for i,cost in ipairs({4,2,2}) do local s=Source(50000+i,.3+i*.01); s.visualID=60000+i; pool[i]={slotKey="WAIST",source=s,descriptor=s._desc,baseScore=10,profileFit=.7,mismatchCost=cost,repeatPenalty=0,outlierState="NORMAL",forceFallback=false} end
local fallback=P.CreateSupportBeamWork({draft=draft},profile,{starting=1,lockedCommitment=0,generatedSpend=0,borrowed=0,overrun=0,remaining=1},{"WAIST"},{WAIST=pool},{},{})
local guard=0
while fallback.stageIndex<=1 and guard<1000 do P.StepSupportBeamWork(fallback); guard=guard+1 end
assert(guard<1000,"fallback bridge benchmark stalled")
assert(fallback.beam[1] and fallback.beam[1].selected.WAIST and fallback.beam[1].selected.WAIST.source.visualID==60002,"fallback bridge first-best tie changed")
print(string.format("PASS v1.11.11 support bridge benchmark: 768 candidates, max bridge microphase %.2f ms, zero prepared-descriptor fallbacks",bridgeMax))
