QuestChronicle={Wardrobe={_Private={}},ZoneStyle={Traveler={}}}
local W,P,Z,T=QuestChronicle.Wardrobe,QuestChronicle.Wardrobe._Private,QuestChronicle.ZoneStyle,QuestChronicle.ZoneStyle.Traveler
W.slotDefinitions={}
for _,key in ipairs({"HEAD","SHOULDER","BACK","CHEST","SHIRT","TABARD","WRIST","HANDS","WAIST","LEGS","FEET","ONE_HAND"}) do local d={key=key,label=key};W.slotDefinitions[#W.slotDefinitions+1]=d end
P.slotByKey={};for _,d in ipairs(W.slotDefinitions) do P.slotByKey[d.key]=d end
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"};P.GENERATION_ERA_CANDIDATES_PER_OPERATION=1;P.GENERATION_OPERATION_SAFETY_CAP=1000;P.GENERATION_TIME_BUDGET_MS=2.5
local now=0;function P.GenerationNowMilliseconds() now=now+.02 return now end;function P.RecordGenerationPhase() end
local bySlot,byID={},{}
local function add(slot,id,value,loud)
 local s={slotKey=slot,sourceID=id,visualID=id,styleName=slot..id,descriptor={palette={steel=value},material={plate=value},finish={military=value},motifs={frontier=value},confidence={palette=1,material=1,finish=1,motifs=1,visualWeight=1,provenance=1},visualWeight=2.5,loudness=loud or .2,expansionID=1,setIDs={},dominantPalette="steel",dominantMaterial="plate",dominantFinish="military",dominantMotif="frontier"}};bySlot[slot]=bySlot[slot] or {};bySlot[slot][#bySlot[slot]+1]=s;byID[slot..id]=s;return s
end
local chest,legs,shoulder,weapon=add("CHEST",1,.9),add("LEGS",2,.85),add("SHOULDER",3,.8),add("ONE_HAND",4,.8)
local lockedBack=add("BACK",5,.05,.9)
for _,slot in ipairs({"WAIST","HANDS","FEET","HEAD","WRIST","SHIRT","TABARD"}) do add(slot,100+#byID,.82);add(slot,200+#byID,.2,.9) end
function W.GetSlotSources(slot) return bySlot[slot] or {} end;function W.ValidateSource() return true end
function P.GetSourceByID(slot,id) return byID[slot..id] end;function P.SetSelectedSource(state,slot,source) state.selections[slot]=source and source.sourceID or nil;state.selectionVisuals[slot]=source and source.visualID or nil end
function Z.GetTravelerDescriptor(source) return source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS={CHEST=1,LEGS=.8,SHOULDER=1,ONE_HAND=.9,WAIST=.5,HANDS=.65,FEET=.6,HEAD=.9,BACK=.55,WRIST=.25,SHIRT=.2,TABARD=.2}
function T.GetPairCohesion(left,right) local a=left.palette.steel or 0;local b=right.palette.steel or 0;local s=1-math.abs(a-b);return s,{palette=s,material=s,finish=s,visualWeight=s,motif=s,provenance=.78} end
local style={GetSourceCoherence=function(source) if source==lockedBack then return .1,false,"locked clash" end return .8,true end,ScoreSource=function(source) return source.descriptor.palette.steel*25,{} end,GetSourcePreEraEligibility=function() return true end,GetSourcePreEraEligibilityCached=function() return true end,CreateSourceEraEvidenceWork=function() return {done=true,result={state="KNOWN"}} end,GetSourceEligibility=function() return true end,GetSourceEligibilityCached=function() return true end,AddSourceToGenerationContext=function() end}
math.randomseed(1907);for _,f in ipairs({"SupportProfile.lua","SupportBudget.lua","SupportScoring.lua","SupportBeam.lua","SupportWorker.lua"}) do dofile("Core/Wardrobe/"..f) end
local state={selections={CHEST=1,LEGS=2,SHOULDER=3,ONE_HAND=4,BACK=5},selectionVisuals={},hidden={HEAD=true},locks={BACK=true}}
local job={draft=state,liveState=state,styleEngine=style,styleMode="TRAVELER",styleContext={},reroll=false,selectedArmor=3,candidatesProcessed=0,eraCandidatesProcessed=0,phaseStats={}}
local status,guard="RUNNING",0;while status=="RUNNING" do guard=guard+1;status=P.StepSupportGenerationJob(job,P.GenerationNowMilliseconds());assert(guard<500,"state worker timeout") end
assert(status=="READY","state worker failed")
assert(state.selections.BACK==5,"locked incoherent Back must remain sovereign")
assert(state.selections.HEAD==nil,"hidden Head must remain skipped")
assert(math.abs(job.supportStats.startingBudget-8.75)<.001,"hidden Head allowance must be omitted")
assert(job.supportStats.lockedCommitment>0,"locked support mismatch must be committed")
local foundBack=false;for _,decision in ipairs(job.supportStats.decisions) do if decision.slotKey=="BACK" then foundBack=true;assert(decision.locked,"Back decision must be locked") end end
assert(foundBack,"locked Back must appear in support decisions")
print(string.format("PASS contextual support states: hidden Head omitted, locked Back retained, %.2f committed of %.2f budget",job.supportStats.lockedCommitment,job.supportStats.startingBudget))
