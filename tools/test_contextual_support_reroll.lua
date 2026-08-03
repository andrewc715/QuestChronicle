QuestChronicle = { Wardrobe = { _Private = {} }, ZoneStyle = { Traveler = {} } }
local QC, W, P, Z, T = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle, QuestChronicle.ZoneStyle.Traveler
W.slotDefinitions = {}
for _, key in ipairs({"HEAD","SHOULDER","BACK","CHEST","SHIRT","TABARD","WRIST","HANDS","WAIST","LEGS","FEET","ONE_HAND","OFF_HAND"}) do local d={key=key,label=key}; W.slotDefinitions[#W.slotDefinitions+1]=d end
P.slotByKey={}; for _,d in ipairs(W.slotDefinitions) do P.slotByKey[d.key]=d end
P.MAIN_WEAPON_SLOT_KEYS={"ONE_HAND"}
local bySlot, byID = {}, {}
local function add(slot,id,value)
    local source={slotKey=slot,sourceID=id,visualID=id,styleName=slot..id,descriptor={palette={steel=value},material={plate=value},finish={military=value},motifs={frontier=value},confidence={palette=1,material=1,finish=1,motifs=1,visualWeight=1,provenance=1},visualWeight=2.5,loudness=.2,expansionID=1,setIDs={},dominantPalette="steel",dominantMaterial="plate",dominantFinish="military",dominantMotif="frontier"}}
    bySlot[slot]=bySlot[slot] or {}; bySlot[slot][#bySlot[slot]+1]=source; byID[slot..id]=source; return source
end
local chestA, chestB = add("CHEST",1,.9), add("CHEST",2,.8)
local legs, shoulder, weapon = add("LEGS",3,.86), add("SHOULDER",4,.84), add("ONE_HAND",5,.82)
local supportSlots={"WAIST","HANDS","FEET","HEAD","BACK","WRIST","SHIRT","TABARD"}
local currentBySlot, alternativeBySlot = {}, {}
for index,slot in ipairs(supportSlots) do currentBySlot[slot]=add(slot,100+index,.25); alternativeBySlot[slot]=add(slot,200+index,.83) end
function W.GetSlotSources(slot) return bySlot[slot] or {} end
function W.ValidateSource() return true end
function W.GetSlotDefinition(key) return P.slotByKey[key] end
function W.IsSlotLocked(slot) return P.EnsurePreviewState().locks[slot] == true end
function P.GetSourceByID(slot,id) return byID[slot..id] end
function P.SetSelectedSource(state,slot,source) state.selections[slot]=source and source.sourceID or nil; state.selectionVisuals[slot]=source and source.visualID or nil end
function Z.GetTravelerDescriptor(source) return source and source.descriptor end
T.SLOT_VISIBILITY_WEIGHTS={CHEST=1,LEGS=.8,SHOULDER=1,ONE_HAND=.9,WAIST=.5,HANDS=.65,FEET=.6,HEAD=.9,BACK=.55,WRIST=.25,SHIRT=.2,TABARD=.2}
function T.GetPairCohesion(left,right) local a=left.palette.steel or 0; local b=right.palette.steel or 0; local s=1-math.abs(a-b); return s,{palette=s,material=s,finish=s,visualWeight=s,motif=s,provenance=.78} end
Z.MODE_TRAVELER="TRAVELER"
function Z.NormalizeMode(mode) return mode end
function Z.GetCurrentContext() return {} end
function Z.GetSourceCoherence() return .8,true end
function Z.ScoreSource(source) return (source.descriptor.palette.steel or 0)*25,{} end
function Z.GetSourcePreEraEligibility() return true end
function Z.GetSourcePreEraEligibilityCached() return true end
function Z.GetSourceEraEvidence() return {state="KNOWN"} end
function Z.GetSourceEligibility() return true end
function Z.GetSourceEligibilityCached() return true end
function P.CreateStyleGenerationContext() return {} end
function P.RefreshGeneratedOutfitName(state) state.generatedName="Contextual Test"; return state.generatedName end
QC.Notify=function() end
local state={selections={CHEST=chestA.sourceID,LEGS=legs.sourceID,SHOULDER=shoulder.sourceID,ONE_HAND=weapon.sourceID},selectionVisuals={},hidden={},locks={},styleMode="TRAVELER"}
for _,slot in ipairs(supportSlots) do state.selections[slot]=currentBySlot[slot].sourceID end
P.EnsurePreviewState=function() return state end
local originalAnchorCalls=0
W.RerollSlot=function(slotKey) originalAnchorCalls=originalAnchorCalls+1; if slotKey=="CHEST" then P.SetSelectedSource(state,"CHEST",chestB) end; return true,"anchor rerolled" end
math.randomseed(1907)
for _,f in ipairs({"SupportProfile.lua","SupportBudget.lua","SupportScoring.lua","SupportBeam.lua","SupportWorker.lua","SupportReroll.lua"}) do dofile("Core/Wardrobe/"..f) end
local before={}; for slot,id in pairs(state.selections) do before[slot]=id end
local ok,message=W.RerollSlot("WAIST")
assert(ok and message:find("contextually",1,true),"support reroll should succeed contextually")
assert(state.selections.WAIST~=before.WAIST,"support reroll must hard-exclude the current visual")
for slot,id in pairs(before) do if slot~="WAIST" then assert(state.selections[slot]==id,"support reroll changed unrelated slot "..slot) end end
assert(P.lastSupportDiagnostics and P.lastSupportDiagnostics.chosenRank>=1 and P.lastSupportDiagnostics.shortlistSize>=1,"reroll diagnostics need truthful rank")
state.locks.BACK=true; local lockedBack=state.selections.BACK
ok,message=W.RerollSlot("CHEST")
assert(ok and originalAnchorCalls==1,"anchor reroll must call the original route")
assert(state.selections.CHEST==chestB.sourceID,"anchor selection was not preserved")
assert(state.selections.BACK==lockedBack,"locked support must survive anchor-context rebuild")
state.locks.WAIST=true
ok,message=W.RerollSlot("WAIST")
assert(not ok and message:find("Unlock",1,true),"locked support reroll must fail safely")
print(string.format("PASS contextual support reroll: isolated support replacement, anchor rebuild, locked preservation, rank %d/%d",P.lastSupportDiagnostics.chosenRank,P.lastSupportDiagnostics.shortlistSize))
