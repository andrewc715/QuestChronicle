QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} } }
local W, P, Z, T = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle.Traveler
W.slotDefinitions = {}
for _, key in ipairs({"HEAD","SHOULDER","BACK","CHEST","SHIRT","TABARD","WRIST","HANDS","WAIST","LEGS","FEET","ONE_HAND","OFF_HAND"}) do local d={key=key,label=key}; W.slotDefinitions[#W.slotDefinitions+1]=d end
P.slotByKey={}; for _,d in ipairs(W.slotDefinitions) do P.slotByKey[d.key]=d end
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}; P.GENERATION_ERA_CANDIDATES_PER_OPERATION=1; P.GENERATION_OPERATION_SAFETY_CAP=2000; P.GENERATION_TIME_BUDGET_MS=2.5
local now=0; function P.GenerationNowMilliseconds() now=now+.02 return now end
function P.RecordGenerationPhase(job,key,elapsed) job.phaseStats=job.phaseStats or {}; local p=job.phaseStats[key] or {calls=0,totalMs=0,maxMs=0}; job.phaseStats[key]=p; p.calls=p.calls+1;p.totalMs=p.totalMs+elapsed;p.maxMs=math.max(p.maxMs,elapsed) end
local bySlot={}; local byID={}
local function add(slot,id,value)
 local source={slotKey=slot,sourceID=id,visualID=id,styleName=slot..id,descriptor={palette={steel=value},material={plate=value},finish={military=value},motifs={frontier=value},confidence={palette=1,material=1,finish=1,motifs=1,visualWeight=1,provenance=1},visualWeight=2.5,loudness=.2,expansionID=1,setIDs={},dominantPalette="steel",dominantMaterial="plate",dominantFinish="military",dominantMotif="frontier"}}
 bySlot[slot]=bySlot[slot] or {}; bySlot[slot][#bySlot[slot]+1]=source; byID[slot..id]=source; return source
end
local chest=add("CHEST",1,.9); local legs=add("LEGS",2,.85); local shoulder=add("SHOULDER",3,.82); local weapon=add("ONE_HAND",4,.8)
for _,slot in ipairs({"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}) do add(slot,100+#byID,.82); add(slot,200+#byID,.2) end
function W.GetSlotSources(slot) return bySlot[slot] or {} end
function W.ValidateSource() return true end
function P.GetSourceByID(slot,id) return byID[slot..id] end
function P.SetSelectedSource(state,slot,source) state.selections[slot]=source and source.sourceID or nil; state.selectionVisuals[slot]=source and source.visualID or nil end
function Z.GetTravelerDescriptor(source) return source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS={CHEST=1,LEGS=.8,SHOULDER=1,ONE_HAND=.9,WAIST=.5,HANDS=.65,FEET=.6,HEAD=.9,BACK=.55,WRIST=.25,SHIRT=.2,TABARD=.2}
function T.GetPairCohesion(left,right) local a=left.palette.steel or 0; local b=right.palette.steel or 0; local s=1-math.abs(a-b); return s,{palette=s,material=s,finish=s,visualWeight=s,motif=s,provenance=.78} end
local style={
 GetSourceCoherence=function() return .8,true end,
 ScoreSource=function(source) return (source.descriptor.palette.steel or 0)*25,{} end,
 GetSourcePreEraEligibility=function() return true end, GetSourcePreEraEligibilityCached=function() return true end,
 CreateSourceEraEvidenceWork=function() return {done=true,result={state="KNOWN"}} end,
 GetSourceEligibility=function() return true end, GetSourceEligibilityCached=function() return true end,
 AddSourceToGenerationContext=function() end,
}
math.randomseed(1907)
for _,f in ipairs({"SupportProfile.lua","SupportBudget.lua","SupportScoring.lua","SupportBeam.lua","SupportWorker.lua"}) do dofile("Core/Wardrobe/"..f) end
local state={selections={CHEST=1,LEGS=2,SHOULDER=3,ONE_HAND=4},selectionVisuals={},hidden={},locks={}}
local job={draft=state,liveState=state,styleEngine=style,styleMode="TRAVELER",styleContext={},reroll=false,selectedArmor=3,candidatesProcessed=0,eraCandidatesProcessed=0,phaseStats={}}
local status; local frames=0
repeat frames=frames+1; status=P.StepSupportGenerationJob(job,P.GenerationNowMilliseconds()); assert(frames<1000,"support worker timeout") until status~="RUNNING"
assert(status=="READY","support worker must finish")
assert(job.supportStats and #job.supportStats.decisions==8,"all support slots need decisions")
assert(job.supportStats.remainingBudget>=0,"support budget must reconcile")
for _,slot in ipairs(P.SUPPORT_SLOT_ORDER) do assert(state.selections[slot],"missing support selection "..slot) end
assert(job.phaseStats.supportBeamExpansion and job.phaseStats.supportCandidateScoring,"support phases must be instrumented")
print(string.format("PASS contextual support worker: %d slots in %d cooperative frames, cohesion %.3f, remaining %.2f",#job.supportStats.decisions,frames,job.supportStats.wholeOutfitCohesion,job.supportStats.remainingBudget))
