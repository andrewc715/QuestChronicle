QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} } }
local W, P, Z, T = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle.Traveler
W.slotDefinitions = {}
for _, key in ipairs({"HEAD","SHOULDER","BACK","CHEST","SHIRT","TABARD","WRIST","HANDS","WAIST","LEGS","FEET","ONE_HAND","OFF_HAND"}) do local d={key=key,label=key}; W.slotDefinitions[#W.slotDefinitions+1]=d end
P.slotByKey={}; for _,d in ipairs(W.slotDefinitions) do P.slotByKey[d.key]=d end
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}; P.GENERATION_ERA_CANDIDATES_PER_OPERATION=1; P.GENERATION_OPERATION_SAFETY_CAP=2000; P.GENERATION_TIME_BUDGET_MS=2.5
local now=0; function P.GenerationNowMilliseconds() now=now+.02 return now end
function P.RecordGenerationPhase(job,key,elapsed) job.phaseStats=job.phaseStats or {}; local p=job.phaseStats[key] or {calls=0,totalMs=0,maxMs=0}; job.phaseStats[key]=p; p.calls=p.calls+1;p.totalMs=p.totalMs+elapsed;p.maxMs=math.max(p.maxMs,elapsed) end
local bySlot, byID = {}, {}
local function descriptor(value)
 return {palette={steel=value},material={plate=value},finish={military=value},motifs={frontier=value},confidence={palette=1,material=1,finish=1,motifs=1,visualWeight=1,provenance=1},visualWeight=2.5,loudness=.15,expansionID=1,setIDs={},dominantPalette="steel",dominantMaterial="plate",dominantFinish="military",dominantMotif="frontier"}
end
local function add(slot,id,value)
 local source={slotKey=slot,sourceID=id,visualID=id,styleName=slot..id,descriptor=descriptor(value)}
 bySlot[slot]=bySlot[slot] or {}; bySlot[slot][#bySlot[slot]+1]=source; byID[slot..id]=source; return source
end
add("CHEST",1,.9); add("LEGS",2,.88); add("SHOULDER",3,.86); add("ONE_HAND",4,.84)
local expected={}
for index,slot in ipairs({"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}) do expected[slot]=add(slot,100+index,.82); add(slot,200+index,.3) end
function W.GetSlotSources(slot) return bySlot[slot] or {} end
function W.ValidateSource() return true end
function P.GetSourceByID(slot,id) return byID[slot..id] end
function P.SetSelectedSource(state,slot,source) state.selections[slot]=source and source.sourceID or nil; state.selectionVisuals[slot]=source and source.visualID or nil end
function Z.GetTravelerDescriptor(source) return source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS={CHEST=1,LEGS=.8,SHOULDER=1,ONE_HAND=.9,WAIST=.5,HANDS=.65,FEET=.6,HEAD=.9,BACK=.55,WRIST=.25,SHIRT=.2,TABARD=.2}
T.CONFIG={profileWeights={palette=.32,material=.20,finish=.14,visualWeight=.12,motif=.22},thresholds={loudImpact=.55,postalCohesion=.35,echo=.65,postalBridge=.35,cohesive=.55,supportedCohesion=.45,strongBridge=.70,mild=.35,mildBridge=.55}}
T.PALETTE_RELATIONS={}; T.MATERIAL_RELATIONS={}; T.FINISH_RELATIONS={}
function T.GetPairCohesion(left,right) local a=left.palette.steel or 0; local b=right.palette.steel or 0; local s=1-math.abs(a-b); return s,{palette=s,material=s,finish=s,visualWeight=s,motif=s,provenance=.78} end
local style={GetSourceCoherence=function() return .8,true end,ScoreSource=function(source) return (source.descriptor.palette.steel or 0)*25,{} end,GetSourcePreEraEligibility=function() return true end,GetSourcePreEraEligibilityCached=function() return true end,CreateSourceEraEvidenceWork=function() return {done=true,result={state="KNOWN"}} end,GetSourceEligibility=function() return true end,GetSourceEligibilityCached=function() return true end,AddSourceToGenerationContext=function() end}
math.randomseed(190714)
dofile("Core/ZoneStyle/Traveler/MismatchAnalysis.lua")
for _,f in ipairs({"SupportProfileIdentity.lua","SupportProfile.lua","SupportBudget.lua","SupportScoring.lua","SupportBeam.lua","SupportFinalValidation.lua","SupportRepair.lua","SupportWorker.lua"}) do dofile("Core/Wardrobe/"..f) end
local state={selections={CHEST=1,LEGS=2,SHOULDER=3,ONE_HAND=4},selectionVisuals={},hidden={},locks={}}
local job={draft=state,liveState=state,styleEngine=style,styleMode="TRAVELER",styleContext={},reroll=false,selectedArmor=3,candidatesProcessed=0,eraCandidatesProcessed=0,phaseStats={}}
local status, frames
for index=1,2000 do frames=index; status=P.StepSupportGenerationJob(job,P.GenerationNowMilliseconds()); if status~="RUNNING" then break end end
assert(status=="READY","Phase D clean worker must finish")
assert(job.supportStats.finalValidationStatus=="CLEAN","clean configuration must remain clean")
assert(job.supportStats.repairPasses==0 and #(job.supportStats.repairs or {})==0,"clean path must not repair")
assert(job.phaseStats.supportFinalValidation and not job.phaseStats.supportRepairPass1,"clean path must validate without repair work")
for slot,source in pairs(expected) do assert(state.selections[slot]==source.sourceID,"clean path selection drift in "..slot) end
print(string.format("PASS Phase D clean worker parity: %d slots, %d frames, status %s",#job.supportStats.decisions,frames,job.supportStats.finalValidationStatus))
