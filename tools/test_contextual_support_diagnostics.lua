QuestChronicle={version="1.9.0.7",Wardrobe={_Private={},slotDefinitions={}},Diagnostics={_Private={}}}
local W,P,D,DP=QuestChronicle.Wardrobe,QuestChronicle.Wardrobe._Private,QuestChronicle.Diagnostics,QuestChronicle.Diagnostics._Private
for _,key in ipairs({"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}) do W.slotDefinitions[#W.slotDefinitions+1]={key=key,label=key} end
function W.GetSlotDefinition(key) for _,d in ipairs(W.slotDefinitions) do if d.key==key then return d end end end
P.SUPPORT_SLOT_ORDER={"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}
function DP.DeepCopy(v) if type(v)~="table" then return v end local r={}; for k,x in pairs(v) do r[k]=DP.DeepCopy(x) end return r end
local state={hidden={HEAD=true},locks={BACK=true}}
local function decision(slot,id) return {slotKey=slot,source={sourceID=id,visualID=id,itemID=id,styleName=slot..id},role="role",profileFit=.8,neighborCohesion=.75,bridgeBonus=3,bridgeTarget="A ↔ B",bridgeBefore=.5,bridgeAfter=.7,mismatchSpent=.4,budgetState="WITHIN",outlierState="NORMAL",repeatPenalty=0,score=20} end
local stats={activeSlots={"WAIST","HANDS","FEET","WRIST","SHIRT","TABARD"},profile={activeAnchorCount=4,meanAnchorCohesion=.7,descriptor={dominantPalette="steel",dominantMaterial="plate",dominantFinish="military",dominantMotif="frontier",visualWeight=2.5},entries={},tolerance={},confidence={}},startingBudget=8.75,lockedCommitment=.3,generatedSpend=2.1,borrowed=0,overrun=0,remainingBudget=6.35,configurationScore=120,wholeOutfitCohesion=.78,controlledAccents=1,outliers=0,fallbackSlots=0,chosenRank=1,shortlistSize=4,poolSizes={WAIST=32},expansions={WAIST=32},retained={WAIST=24},decisions={decision("WAIST",1),decision("HANDS",2)}}
P.lastSupportDiagnostics=stats
dofile("Core/Diagnostics/SupportSnapshot.lua")
local snapshot=DP.BuildSupportSnapshot(state,{supportDiagnostics=stats})
assert(snapshot and snapshot.remainingBudget==6.35,"support snapshot missing")
assert(snapshot.excluded[1]=="HEAD (Hidden)" and snapshot.excluded[2]=="BACK (Locked)","hidden/locked exclusions")
dofile("Core/Diagnostics/SupportReportFormatter.lua")
local lines={}; DP.AddSupportSection(lines,{support=snapshot},false,false)
local text=table.concat(lines,"\n")
assert(text:find("Contextual Support",1,true) and text:find("Budget:",1,true) and text:find("HEAD (Hidden)",1,true),"support report incomplete")
print(string.format("PASS contextual support diagnostics: %d decisions, %d bytes",#snapshot.decisions,#text))
