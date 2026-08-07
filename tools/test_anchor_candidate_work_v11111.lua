local clock = 0
function debugprofilestop() return clock end
QuestChronicle = {
    _Core = { Workers = {} },
    Wardrobe = { _Private = {} },
    ZoneStyle = { _Private = {}, Traveler = {}, Zone = {} },
    Generation = {},
}
local QC, W, Z, WP, ZP = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.ZoneStyle, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle._Private
Z.MODE_ZONE_NATIVE = "ZONE_NATIVE"
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Workers/SliceBudget.lua")
dofile(base.."Core/Wardrobe/GenerationScheduling.lua")
dofile(base.."Core/ZoneStyle/Zone/Foundation.lua")
dofile(base.."Core/ZoneStyle/Zone/AnchorScoring.lua")

local calls={metadata=0,setList=0,tracking=0,random=0,coherence=0,score=0,descriptor=0,affinity=0}
local source={sourceID=77,visualID=88,itemID=99,name="Fixture Plate",styleName="Fixture Plate",itemMetadataVerified=false}
local definition={key="CHEST"}
ZP.trackedOriginCache={}
ZP.sourceSetCache={}
function ZP.IsSourceItemMetadataTrusted(s) return s.itemMetadataVerified==true end
function ZP.LoadItemMetadata(s) calls.metadata=calls.metadata+1; clock=clock+.25; s.itemMetadataVerified=true; s.itemMetadataItemID=s.itemID; s.expansionID=1; return 1 end
function ZP.BuildSourceMetadataSnapshot(s) return string.lower(s.styleName or s.name or "") end
function ZP.GetSourceSetIDs(s)
    local id=s.sourceID
    if ZP.sourceSetCache[id] then return ZP.sourceSetCache[id] end
    calls.setList=calls.setList+1; clock=clock+.25
    ZP.sourceSetCache[id]={501}; return ZP.sourceSetCache[id]
end
function ZP.GetSourceStyleSignalsPrepared(_,text) return {text=text,families={knightly=2},intensity=2} end
function ZP.GetAppearanceTrackingType() return 1 end
function ZP.GetTrackedSourceOrigin(s)
    if ZP.trackedOriginCache[s.sourceID]~=nil then return ZP.trackedOriginCache[s.sourceID] or nil end
    calls.tracking=calls.tracking+1; clock=clock+.25
    local origin={provenanceKey="stormwind",label="Stormwind",expansionID=0}
    ZP.trackedOriginCache[s.sourceID]=origin; return origin
end
function ZP.NewPreparedSourceInputs(s,era) return {source=s,expansionID=era and era.expansionID,expansionIDKnown=era~=nil,setIDsKnown=false,trackedOriginKnown=false} end
function Z.GetSourceCoherencePrepared(_,_,prepared)
    calls.coherence=calls.coherence+1
    assert(prepared.metadataText and prepared.setIDsKnown and prepared.styleSignals,"coherence did not receive prepared inputs")
    return 6,true,"matching knightly motif"
end
function Z.ScoreSourcePrepared(_,_,_,_,coherence,_,_,prepared)
    calls.score=calls.score+1
    assert(coherence==6 and prepared.metadataText=="fixture plate","score did not receive prepared metadata")
    return 21,{"Local: knightly","Match: matching knightly motif"}
end
function Z.GetTravelerDescriptor(_,_,prepared)
    calls.descriptor=calls.descriptor+1
    assert(prepared.setIDsKnown and #prepared.setIDs==1,"descriptor did not reuse prepared set IDs")
    return {fingerprint="fixture",setIDs=prepared.setIDs,dominantMaterial="plate",dominantMotif="knightly",dominantPalette="steel",loudness=.3}
end
function Z.GetSourcePreference() return "favorite" end
QC.Generation.ZoneAffinityPolicy={AnalyzeAppearance=function(_,_,snapshot,prepared)
    calls.affinity=calls.affinity+1
    assert(snapshot and snapshot.fingerprint=="ZCTX","snapshot missing")
    assert(prepared.trackedOriginKnown and prepared.trackedOrigin.provenanceKey=="stormwind","affinity did not receive prepared tracking")
    return {classification="STRONGLY_NATIVE",score=.9,confidence=.65}
end}
C_TransmogSets={GetSetsContainingSourceID=function() error("direct set API should be hidden by stub") end}
C_ContentTracking={GetBestMapForTrackable=function() error("direct tracking API should be hidden by stub") end}

WP.GENERATION_ERA_CANDIDATES_PER_OPERATION=1
WP.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}
WP.slotByKey={CHEST=definition,ONE_HAND={key="ONE_HAND"},OFF_HAND={key="OFF_HAND"}}
function WP.GetSourceByID() return nil end
local oldRandom=math.random
math.random=function() calls.random=calls.random+1; return .25 end

dofile(base.."Core/Wardrobe/AnchorSkeletonCache.lua")
dofile(base.."Core/Wardrobe/AnchorCandidateWork.lua")

local job={styleMode=Z.MODE_ZONE_NATIVE,styleContext={},modeContext={fingerprint="ZCTX"},modePolicy={capabilities={zoneAnchorPolicy=true}},currentSlice=QC._Core.Workers.BeginSlice(5.5,7.5)}
local work=WP.CreateAnchorCandidateWork(job,source,definition,job.styleContext,false,{expansionID=1})
local stages={}
while not work.done do
    local op=WP.DescribeNextAnchorCandidateOperation(work)
    stages[#stages+1]=op.phase
    if op.class=="API_HEADROOM" then assert(WP.CanStartGenerationPhase(job,op.reserveMs),"fresh fixture should admit API work") end
    local before=clock
    WP.StepAnchorCandidateWork(work)
    QC._Core.Workers.NoteCall(job.currentSlice,clock-before)
    assert(#stages<50,"anchor candidate worker stalled")
end
local c=assert(work.result,"cooperative candidate unexpectedly rejected")
assert(c.baseScore>21 and c.anchorPolicy,"Zone policy was not applied")
assert(c.anchorPolicy.favorite==true,"favorite flag missing")
assert(c.poolRandomValue==.25 and calls.random==1,"accepted candidate must consume exactly one random draw")
assert(calls.metadata==1 and calls.setList==1 and calls.tracking==1,"API preparation call counts changed")
assert(calls.coherence==1 and calls.score==1 and calls.descriptor==1 and calls.affinity==1,"pure scoring stages did not execute exactly once")
assert(stages[1]=="METADATA_SNAPSHOT" and stages[#stages]=="PREFERENCE","candidate stage ordering changed")

-- A rejected incoherent candidate completes before POOL_RANDOM and consumes no random draw.
local rejectedSource={sourceID=78,visualID=89,itemID=nil,name="Reject"}
ZP.sourceSetCache[78]={}
ZP.trackedOriginCache[78]=false
local priorRandom=calls.random
local priorCoherence=Z.GetSourceCoherencePrepared
Z.GetSourceCoherencePrepared=function() return -20,false,"clash" end
local rejected=WP.CreateAnchorCandidateWork(job,rejectedSource,definition,job.styleContext,false,{expansionID=0})
while not rejected.done do WP.StepAnchorCandidateWork(rejected) end
assert(rejected.result==nil,"incoherent candidate should be rejected")
assert(calls.random==priorRandom,"rejected candidate consumed random")
Z.GetSourceCoherencePrepared=priorCoherence

-- Low headroom denies an API stage without mutating candidate state.
local deniedSource={sourceID=79,visualID=90,itemID=199,name="Denied",itemMetadataVerified=false}
local denied=WP.CreateAnchorCandidateWork(job,deniedSource,definition,job.styleContext,false,{expansionID=1})
job.currentSlice=QC._Core.Workers.BeginSlice(5.5,7.5)
job.currentSlice.startedAtMs=0; clock=3.0
local op=WP.DescribeNextAnchorCandidateOperation(denied)
assert(op.class=="API_HEADROOM" and op.phase=="METADATA_SNAPSHOT","metadata stage did not request API headroom")
local beforeStage=denied.stage
assert(not WP.CanStartGenerationPhase(job,op.reserveMs),"low-headroom fixture unexpectedly admitted API")
assert(denied.stage==beforeStage and denied.prepared.metadataText==nil,"denied admission mutated candidate work")

math.random=oldRandom
print("PASS v1.11.11 anchor candidate work: staged API preparation, exact random boundary, policy application, immutable denial")
