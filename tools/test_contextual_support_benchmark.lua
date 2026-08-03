QuestChronicle={Wardrobe={_Private={}},ZoneStyle={Traveler={}}}
local W,P,Z,T=QuestChronicle.Wardrobe,QuestChronicle.Wardrobe._Private,QuestChronicle.ZoneStyle,QuestChronicle.ZoneStyle.Traveler
W.slotDefinitions={}
for _,key in ipairs({"HEAD","SHOULDER","BACK","CHEST","SHIRT","TABARD","WRIST","HANDS","WAIST","LEGS","FEET","ONE_HAND","OFF_HAND"}) do local d={key=key,label=key}; W.slotDefinitions[#W.slotDefinitions+1]=d end
P.slotByKey={}; for _,d in ipairs(W.slotDefinitions) do P.slotByKey[d.key]=d end
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}; P.GENERATION_ERA_CANDIDATES_PER_OPERATION=1; P.GENERATION_OPERATION_SAFETY_CAP=2000; P.GENERATION_TIME_BUDGET_MS=2.5
local now=0; function P.GenerationNowMilliseconds() now=now+.01 return now end
function P.RecordGenerationPhase(job,key,elapsed) local x=job.phaseStats[key] or {calls=0,totalMs=0,maxMs=0}; job.phaseStats[key]=x; x.calls=x.calls+1;x.totalMs=x.totalMs+elapsed;x.maxMs=math.max(x.maxMs,elapsed) end
local bySlot,byID={},{}
local function add(slot,id,value)
 local source={slotKey=slot,sourceID=id,visualID=id,styleName=slot..id,descriptor={palette={steel=value},material={plate=value},finish={military=value},motifs={frontier=value},confidence={palette=1,material=1,finish=1,motifs=1,visualWeight=1,provenance=1},visualWeight=2.5,loudness=.15+(id%5)*.02,expansionID=1,setIDs={},dominantPalette="steel",dominantMaterial="plate",dominantFinish="military",dominantMotif="frontier"}}
 bySlot[slot]=bySlot[slot] or {}; bySlot[slot][#bySlot[slot]+1]=source; byID[slot..id]=source; return source
end
local chest=add("CHEST",1,.90);local legs=add("LEGS",2,.86);local shoulder=add("SHOULDER",3,.84);local weapon=add("ONE_HAND",4,.82)
local supports={"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}
local id=100
for _,slot in ipairs(supports) do for i=1,32 do id=id+1; add(slot,id,.72+(i%10)*.02) end end
function W.GetSlotSources(slot) return bySlot[slot] or {} end
function W.ValidateSource() return true end
function P.GetSourceByID(slot,sourceID) return byID[slot..sourceID] end
function P.SetSelectedSource(state,slot,source) state.selections[slot]=source and source.sourceID or nil; state.selectionVisuals[slot]=source and source.visualID or nil end
function Z.GetTravelerDescriptor(source) return source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS={CHEST=1,LEGS=.8,SHOULDER=1,ONE_HAND=.9,WAIST=.5,HANDS=.65,FEET=.6,HEAD=.9,BACK=.55,WRIST=.25,SHIRT=.2,TABARD=.2}
function T.GetPairCohesion(left,right) local a=left.palette.steel or 0;local b=right.palette.steel or 0;local s=1-math.abs(a-b);return s,{palette=s,material=s,finish=s,visualWeight=s,motif=s,provenance=.78} end
local style={GetSourceCoherence=function() return .85,true end,ScoreSource=function(source) return source.descriptor.palette.steel*25,{} end,GetSourcePreEraEligibility=function() return true end,GetSourcePreEraEligibilityCached=function() return true end,CreateSourceEraEvidenceWork=function() return {done=true,result={state="KNOWN"}} end,GetSourceEligibility=function() return true end,GetSourceEligibilityCached=function() return true end,AddSourceToGenerationContext=function() end}
math.randomseed(1907)
for _,f in ipairs({"SupportProfileIdentity.lua","SupportProfile.lua","SupportBudget.lua","SupportScoring.lua","SupportBeam.lua","SupportWorker.lua"}) do dofile("Core/Wardrobe/"..f) end
local state={selections={CHEST=1,LEGS=2,SHOULDER=3,ONE_HAND=4},selectionVisuals={},hidden={},locks={}}
local job={draft=state,liveState=state,styleEngine=style,styleMode="TRAVELER",styleContext={},reroll=false,selectedArmor=3,candidatesProcessed=0,eraCandidatesProcessed=0,phaseStats={}}
local status,frames,maxSlice="RUNNING",0,0
while status=="RUNNING" do frames=frames+1;local start=P.GenerationNowMilliseconds();status=P.StepSupportGenerationJob(job,start);maxSlice=math.max(maxSlice,P.GenerationNowMilliseconds()-start);assert(frames<1000,"support benchmark timeout") end
assert(status=="READY","benchmark support worker failed")
for _,slot in ipairs(supports) do assert(job.supportStats.poolSizes[slot]==32,"pool cap mismatch for "..slot);assert((job.supportStats.retained[slot] or 0)<=24,"beam width exceeded for "..slot) end
assert(job.supportStats.shortlistSize<=6,"support shortlist exceeded")
assert(maxSlice<=2.7,"synthetic support worker slice exceeded budget: "..maxSlice)
local expansions=0;for _,value in pairs(job.supportStats.expansions) do expansions=expansions+value end
print(string.format("PASS contextual support benchmark: 256 prepared, %d expansions, %d frames, %.2f ms max slice, rank %d/%d",expansions,frames,maxSlice,job.supportStats.chosenRank,job.supportStats.shortlistSize))
