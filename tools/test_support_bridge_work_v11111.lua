QuestChronicle={Wardrobe={_Private={}},ZoneStyle={Traveler={}}}
local QC,P,T=QuestChronicle,QuestChronicle.Wardrobe._Private,QuestChronicle.ZoneStyle.Traveler
P.SUPPORT_SLOT_ORDER={"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}
P.slotByKey={}
for _,key in ipairs({"CHEST","LEGS","SHOULDER","ONE_HAND","OFF_HAND","WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}) do P.slotByKey[key]={key=key} end
local sourceMap={}
local function Desc(v) return {v=v} end
local function Source(id,v) local s={sourceID=id,visualID=id,_desc=Desc(v)}; sourceMap[id]=s; return s end
local chest,legs,shoulder,weapon=Source(1,.20),Source(2,.40),Source(3,.60),Source(4,.80)
local wrist=Source(5,.55)
function P.GetSourceByID(_,id) return sourceMap[id] end
function P.IsAnchorActive(mask,key) return not mask or mask[key]~=false end
function P.GetActiveAnchorSource(_,_,key) if key=="WEAPON" then return weapon,"ONE_HAND" end return ({CHEST=chest,LEGS=legs,SHOULDER=shoulder})[key],key end
local descriptorCalls=0
function QC.ZoneStyle.GetTravelerDescriptor(source) descriptorCalls=descriptorCalls+1; return source and source._desc end
function T.GetPairCohesion(left,right) return left.v*.37+right.v*.41+.1 end
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Wardrobe/SupportBudget.lua")
dofile(base.."Core/Wardrobe/SupportScoring.lua")
function P.ResolveSupportRole(slotKey) return {role=P.SUPPORT_SLOT_ROLES[slotKey],bridgeTargets=P.SUPPORT_BRIDGES[slotKey]} end
dofile(base.."Core/Wardrobe/SupportCandidateWork.lua")
local draft={selections={CHEST=1,LEGS=2,SHOULDER=3,ONE_HAND=4},hidden={},locks={}}
local node={selected={WRIST={source=wrist,descriptor=wrist._desc}},budget={starting=12,lockedCommitment=0,generatedSpend=0,borrowed=0,overrun=0,remaining=12}}
local job={draft=draft}
local profile={activeAnchorMask={CHEST=true,LEGS=true,SHOULDER=true,WEAPON=true},entries={
 {source=chest,slotKey="CHEST",descriptor=chest._desc},{source=legs,slotKey="LEGS",descriptor=legs._desc},
 {source=shoulder,slotKey="SHOULDER",descriptor=shoulder._desc},{source=weapon,slotKey="ONE_HAND",descriptor=weapon._desc},
}}
local candidate={slotKey="HANDS",source=Source(20,.33),descriptor=Desc(.33),baseScore=15,profileFit=.72,mismatchCost=.4,repeatPenalty=0,outlierState="NORMAL"}
local expected=P.ScoreSupportCandidate(candidate,node,job,profile,{"HEAD"},false)
assert(descriptorCalls>0,"legacy oracle did not exercise descriptor lookup")
descriptorCalls=0
local work=P.CreateSupportCandidateWork(candidate,node,job,profile,{"HEAD"},false)
local seen={}
local guard=0
while not work.done do local op=P.DescribeSupportCandidateWorkOperation(work); seen[op]=true; P.StepSupportCandidateWork(work); guard=guard+1; assert(guard<100,"bridge worker stalled") end
local function Eq(a,b,path) path=path or "decision"; assert(type(a)==type(b),path.." type"); if type(a)=="table" then for k,v in pairs(a) do Eq(v,b[k],path.."."..tostring(k)) end for k in pairs(b) do assert(a[k]~=nil,path.." missing "..tostring(k)) end elseif type(a)=="number" then assert(a==b,string.format("%s %.17g %.17g",path,a,b)) else assert(a==b,path.." mismatch") end end
Eq(expected,work.decision)
assert(descriptorCalls==0,"cooperative bridge rebuilt a descriptor already owned by profile/node")
assert((work.descriptorFallbacks or 0)==0,"normal bridge path used descriptor fallback")
assert(seen.BRIDGE_TARGET and seen.BRIDGE_PAIR and seen.BRIDGE_BASELINE and seen.BRIDGE_FINALIZE,"bridge microphase identity missing")
print("PASS v1.11.11 support bridge: exact oracle parity, authoritative descriptor reuse, split pair/baseline phases")
