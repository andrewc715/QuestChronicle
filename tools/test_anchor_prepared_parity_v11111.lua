QuestChronicle={ZoneStyle={_Private={},profiles={}},Wardrobe={_Private={}}}
local Z,P=QuestChronicle.ZoneStyle,QuestChronicle.ZoneStyle._Private
Z.MODE_ZONE_NATIVE="ZONE_NATIVE"; Z.MODE_TRAVELER="TRAVELER"; Z.MODE_CLASS_FANTASY="CLASS"; Z.MODE_CHRONICLE_ECHO="ECHO"
function Z.NormalizeMode(v) return v end
function Z.GetCurrentContext() return {} end
Z.profiles.human={seed=17,keywords={stormwind=3,plate=1},avoid={fel=-2}}
Z.profiles.azeroth=Z.profiles.human
P.classKeywords={[1]={warrior=2,plate=1}}
P.travelerKeywords={worn=1,road=2}; P.travelerAvoid={ornate=-1}
P.styleFamilies={knightly={stormwind=2,plate=1},fel={fel=4}}; P.dramaticFamilies={fel=true}; P.conflictingFamilies={fel={knightly=true},knightly={fel=true}}
function P.Normalize(v) return tostring(v or ""):lower():gsub("[^%w]+"," "):gsub("^%s+",""):gsub("%s+$","") end
function P.AddKeywordScore(text,keywords,mult,reasons,prefix)
 local score=0; local padded=" "..text.." "
 for token,value in pairs(keywords or {}) do local n=P.Normalize(token); if n~="" and padded:find(" "..n.." ",1,true) then local c=value*mult; score=score+c; if c>0 and #reasons<4 then reasons[#reasons+1]=(prefix or "")..token end end end
 return score
end
local source={sourceID=11,visualID=21,itemID=31,quality=3}
local metadata="stormwind warrior plate worn"
function P.SourceMetadata(s) assert(s==source); return metadata end
function P.GetSourceSetIDs() return {100,200} end
function P.GetSourceStyleSignals() return {text=metadata,families={knightly=3},intensity=0} end
function Z.GetSourcePreference() return "favorite" end
local chronicle={questCount=1,appearanceKeywords={stormwind=2,road=1}}
function Z.GetChronicleProfile() return chronicle end
function P.ChronicleScore(_,context,mult,reasons) return P.AddKeywordScore(metadata,(context and context.chronicleProfile or chronicle).appearanceKeywords,mult,reasons,"Echo: ") end
function UnitClass() return "Warrior","WARRIOR",1 end
function CreateFrame() return {RegisterEvent=function() end,SetScript=function() end} end
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/ZoneStyle/Scoring.lua")
dofile(base.."Core/ZoneStyle/PreparedSource.lua")
local context={profileKey="human",chronicleProfile=chronicle,outfitProfile={sourceCount=3,setIDs={[200]=1},families={knightly=4},themedSources=2}}
local prepared={metadataText=metadata,setIDs={100,200},setIDsKnown=true,styleSignals={text=metadata,families={knightly=3},intensity=0}}
local a1,b1,c1=Z.GetSourceCoherence(source,context)
local a2,b2,c2=Z.GetSourceCoherencePrepared(source,context,prepared)
assert(a1==a2 and b1==b2 and c1==c2,"prepared coherence diverged from frozen oracle")
local s1,r1=Z.ScoreSource(source,{key="CHEST"},Z.MODE_ZONE_NATIVE,context,a1,b1,c1)
local s2,r2=Z.ScoreSourcePrepared(source,{key="CHEST"},Z.MODE_ZONE_NATIVE,context,a2,b2,c2,prepared)
assert(s1==s2,string.format("prepared score diverged %.17g vs %.17g",s1,s2))
assert(#r1==#r2,"reason count diverged")
for i=1,#r1 do assert(r1[i]==r2[i],"reason order diverged at "..i) end
print("PASS v1.11.11 prepared anchor parity: frozen coherence, score, and reason ordering are exact")
