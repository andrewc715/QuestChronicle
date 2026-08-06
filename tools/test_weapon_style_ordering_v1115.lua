QuestChronicle = { Wardrobe={_Private={}}, ZoneStyle={} }
local QC, P, Z = QuestChronicle, QuestChronicle.Wardrobe._Private, QuestChronicle.ZoneStyle
QC.Wardrobe.GetSlotDefinition = function(key) return { key=key } end
local eligible = { [1]=true,[2]=false,[3]=true,[4]=true }
local coherent = { [1]=true,[2]=true,[3]=false,[4]=true }
local markerBatches = {}
Z.CreateCachedSourceEligibilityWork = function(source) return { source=source, step=0, done=false } end
Z.StepCachedSourceEligibilityWork = function(work,batch)
    markerBatches[#markerBatches+1]=batch
    work.step=work.step+1
    if work.step<2 then return false end
    work.done=true
    return true, eligible[work.source.id]
end
Z.GetSourceCoherence = function(source) return source.id/10, coherent[source.id], "fixture" end
Z.WeightForSource = function(source) return source.id+2 end
local randomValues, randomIndex = { .91, .73 }, 0
local originalRandom = math.random
math.random = function() randomIndex=randomIndex+1 return randomValues[randomIndex] end
local candidates = {}
for id=1,4 do candidates[#candidates+1]={slotKey="TWO_HAND",source={id=id}} end
local root=debug.getinfo(1,"S").source:sub(2):gsub("tools/test_weapon_style_ordering_v1115.lua$","")
assert(loadfile(root.."Core/Wardrobe/WeaponStyleOrdering.lua"))()
local job={}
local work=P.CreateWeaponStyleOrderingWork(candidates,"ZONE_NATIVE",{},job)
local steps=0
while true do
    local done=P.StepWeaponStyleOrderingWork(work)
    steps=steps+1
    if done then break end
    assert(steps<100,"ordering work did not complete")
end
math.random=originalRandom
assert(#candidates==2 and candidates[1].source.id==1 and candidates[2].source.id==4, "retained or sorted candidate order changed")
assert(randomIndex==2, "random draw count changed")
assert(math.abs(candidates[1].stylePriority-(math.log(.91)/3))<1e-12, "source 1 priority changed")
assert(math.abs(candidates[2].stylePriority-(math.log(.73)/6))<1e-12, "source 4 priority changed")
for _, batch in ipairs(markerBatches) do assert(batch==4,"eligibility marker batch is not bounded at 4") end
assert(job.weaponStyleEligibilitySteps==8 and job.weaponStyleEligibilityYields==4, "eligibility diagnostics changed")
assert(job.weaponStyleCoherenceCalls==4 and job.weaponStyleScoringCalls==2, "coherence/scoring diagnostics changed")
print("PASS v1.11.5 weapon style ordering: bounded eligibility preserves retention, RNG count, priorities, and order")
