QuestChronicle={Wardrobe={_Private={}},ZoneStyle={_Private={},expansions={}}}
local Z,E=QuestChronicle.ZoneStyle,QuestChronicle.ZoneStyle._Private
for i=0,11 do Z.expansions[i]={label="E"..i,shortLabel="E"..i} end
function E.Normalize(v) return string.lower(tostring(v or "")) end; function E.TextMatchesAny() return false end; function E.SafeCall(cb,...) return cb(...) end
function E.GetCuratedSourceOrigin() return nil end; function E.GetAppearanceTrackingType() return nil end
local ids={}; for i=1,300 do ids[i]=i end
local setCalls=0
C_TransmogSets={GetSetsContainingSourceID=function() return ids end,GetSetInfo=function(id) setCalls=setCalls+1 return {expansionID=(id%3),name="Set"..id} end}
C_TransmogCollection={GetSourceInfo=function(id) return {itemID=2000+id,sourceType=1,name="S"} end,GetSourceItemID=function(id) return 2000+id end,GetAppearanceSourceDrops=function() return {} end}
C_Item={GetItemInfo=function() return "Item","link",2,1,1,"Armor","Plate",1,"INV",1,0,4,4,1,1 end}
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/ZoneStyle/EraExecution.lua"); dofile(base.."Core/ZoneStyle/EraEvidence.lua"); dofile(base.."Core/ZoneStyle/EraCandidateWork.lua")
local source={sourceID=8,visualID=8,itemID=2008,sourceType=1,eraManifestVersion=E.ERA_MANIFEST_VERSION,eraSourceIDs={8},metadataRevision=0}
local before=E.eraSynchronousProgressGuardTrips or 0
local result=Z.GetSourceEraEvidence(source)
assert(result and result.expansionID~=nil,"long finite synchronous evidence did not complete")
assert(setCalls==300,"long finite set list was not processed exactly once")
assert((E.eraSynchronousProgressGuardTrips or 0)==before,"finite progressing evidence tripped watchdog guard")
print("PASS v1.11.9 watchdog ceiling: 300-entry finite synchronous evidence progresses without guard trip")
