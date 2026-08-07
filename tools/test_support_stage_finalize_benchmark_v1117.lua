QuestChronicle={Wardrobe={_Private={}}}
local P=QuestChronicle.Wardrobe._Private
function P.CopySupportBudget(b) return b or {} end
function P.SupportVisualIdentity(source) return tostring(source and source.visualID or 0) end
function P.CommitSupportBudget(b) return b end
dofile("Core/Wardrobe/SupportBeam.lua")
local maxMs=0
for pass=1,20 do
    local work=P.CreateSupportBeamWork({}, {}, {}, {"WAIST"}, {WAIST={}}, {}, {})
    work.beam={}; work.nextBeam={}
    for index=1,P.SUPPORT_BEAM_WIDTH*P.SUPPORT_POOL_LIMIT do
        work.nextBeam[index]={
            totalScore=((index*37)%997)/10,
            selected={WAIST={source={visualID=((index-1)%320)+1}}}, decisions={}, budget={}, mismatchSpent=0, fallbackCount=0,
        }
    end
    assert(P.DescribeNextSupportBeamOperation(work)=="STAGE_FINALIZE","fixture must target stage finalization")
    local started=os.clock()*1000
    local done=P.StepSupportBeamWork(work)
    local elapsed=os.clock()*1000-started
    maxMs=math.max(maxMs,elapsed)
    assert(done==true and #work.beam==P.SUPPORT_BEAM_WIDTH,"stage finalization must retain the frozen beam width")
end
assert(maxMs<7.5,string.format("support stage finalization exceeded fresh-slice ceiling: %.3f ms",maxMs))
print(string.format("PASS v1.11.7 support stage finalization benchmark: 768 nodes, %.3f ms max",maxMs))
