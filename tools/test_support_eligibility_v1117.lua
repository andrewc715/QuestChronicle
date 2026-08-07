QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} } }
local W, P, Z, T = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle.Traveler
W.slotDefinitions = {}
for _, key in ipairs({"HEAD","SHOULDER","BACK","CHEST","SHIRT","TABARD","WRIST","HANDS","WAIST","LEGS","FEET","ONE_HAND","OFF_HAND"}) do
    local d={key=key,label=key}; W.slotDefinitions[#W.slotDefinitions+1]=d
end
P.slotByKey={}; for _,d in ipairs(W.slotDefinitions) do P.slotByKey[d.key]=d end
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}; P.GENERATION_ERA_CANDIDATES_PER_OPERATION=1
P.GENERATION_OPERATION_SAFETY_CAP=2000; P.GENERATION_TIME_BUDGET_MS=2.5
local now=0; function P.GenerationNowMilliseconds() now=now+.02 return now end
function P.RecordGenerationPhase(job,key,elapsed)
    job.phaseStats=job.phaseStats or {}; local row=job.phaseStats[key] or {calls=0,totalMs=0,maxMs=0}; job.phaseStats[key]=row
    row.calls=row.calls+1; row.totalMs=row.totalMs+elapsed; row.maxMs=math.max(row.maxMs,elapsed)
end
local bySlot, byID = {}, {}
local function add(slot,id,value)
    local source={slotKey=slot,sourceID=id,visualID=id,styleName=slot..id,descriptor={palette={steel=value},material={plate=value},finish={military=value},motifs={frontier=value},confidence={palette=1,material=1,finish=1,motifs=1,visualWeight=1,provenance=1},visualWeight=2.5,loudness=.2,expansionID=1,setIDs={},dominantPalette="steel",dominantMaterial="plate",dominantFinish="military",dominantMotif="frontier"}}
    bySlot[slot]=bySlot[slot] or {}; bySlot[slot][#bySlot[slot]+1]=source; byID[slot..id]=source; return source
end
add("CHEST",1,.9); add("LEGS",2,.85); add("SHOULDER",3,.82); add("ONE_HAND",4,.8)
local id=100
for _,slot in ipairs({"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}) do add(slot,id,.82); id=id+1; add(slot,id,.2); id=id+1 end
function W.GetSlotSources(slot) return bySlot[slot] or {} end
function W.ValidateSource() return true end
function P.GetSourceByID(slot,sourceID) return byID[slot..sourceID] end
function P.SetSelectedSource(state,slot,source) state.selections[slot]=source and source.sourceID or nil; state.selectionVisuals[slot]=source and source.visualID or nil end
function Z.GetTravelerDescriptor(source) return source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS={CHEST=1,LEGS=.8,SHOULDER=1,ONE_HAND=.9,WAIST=.5,HANDS=.65,FEET=.6,HEAD=.9,BACK=.55,WRIST=.25,SHIRT=.2,TABARD=.2}
function T.GetPairCohesion(left,right) local a=left.palette.steel or 0; local b=right.palette.steel or 0; local s=1-math.abs(a-b); return s,{palette=s,material=s,finish=s,visualWeight=s,motif=s,provenance=.78} end
for _,f in ipairs({"SupportProfileIdentity.lua","SupportProfile.lua","SupportBudget.lua","SupportScoring.lua","SupportBeam.lua","SupportWorker.lua"}) do dofile("Core/Wardrobe/"..f) end

local common={
    GetSourceCoherence=function() return .8,true end,
    ScoreSource=function(source) return (source.descriptor.palette.steel or 0)*25,{} end,
    GetSourcePreEraEligibility=function() return true end,
    GetSourcePreEraEligibilityCached=function() return true end,
    CreateSourceEraEvidenceWork=function() return {done=true,result={state="KNOWN"}} end,
    GetSourceEligibility=function() return true end,
    GetSourceEligibilityCached=function() return true end,
    AddSourceToGenerationContext=function() end,
}
local cooperative={}; for k,v in pairs(common) do cooperative[k]=v end
function cooperative.CreateCachedSourceEligibilityWork(source)
    if source.sourceID % 2 == 0 then return {done=true,eligible=true,fromCache=true} end
    return {done=false,eligible=false,fromCache=false,remaining=9}
end
function cooperative.StepCachedSourceEligibilityWork(work,batch)
    assert(batch==4,"support eligibility marker batch changed")
    if work.done then return true,work.eligible,"eligible","cached",work.fromCache end
    work.remaining=work.remaining-batch
    if work.remaining>0 then return false end
    work.done=true; work.eligible=true
    return true,true,"eligible","computed",false
end
local function run(style)
    local state={selections={CHEST=1,LEGS=2,SHOULDER=3,ONE_HAND=4},selectionVisuals={},hidden={},locks={}}
    local job={draft=state,liveState=state,styleEngine=style,styleMode="TRAVELER",styleContext={},reroll=false,selectedArmor=3,candidatesProcessed=0,eraCandidatesProcessed=0,phaseStats={}}
    local status,frames
    frames=0
    repeat frames=frames+1; status=P.StepSupportGenerationJob(job,P.GenerationNowMilliseconds()); assert(frames<1000,"support worker timeout") until status~="RUNNING"
    assert(status=="READY","support worker failed")
    return state,job
end
math.randomseed(1117); local syncState=run(common)
math.randomseed(1117); local coopState,job=run(cooperative)
for _,slot in ipairs(P.SUPPORT_SLOT_ORDER) do assert(syncState.selections[slot]==coopState.selections[slot],"cooperative eligibility changed selection for "..slot) end
assert(job.supportEligibilityMarkerBatch==4,"marker batch missing")
assert((job.supportEligibilitySteps or 0)>0 and (job.supportEligibilityYields or 0)>0,"cooperative steps and yields must be recorded")
assert((job.supportEligibilityCacheCompletions or 0)>0 and (job.supportEligibilityComputedCompletions or 0)>0,"cache and computed completions must be separated")
print(string.format("PASS v1.11.7 support eligibility: %d steps, %d yields, %d cache, %d computed; selection parity preserved",job.supportEligibilitySteps,job.supportEligibilityYields,job.supportEligibilityCacheCompletions,job.supportEligibilityComputedCompletions))
