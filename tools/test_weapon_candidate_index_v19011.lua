QuestChronicle = { Wardrobe = { _Private = {}, weaponSubtypeDefinitions = {} } }
local W, P = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
local clock = 0
debugprofilestop = function() clock = clock + 0.03 return clock end
P.EnsureCache = function() return { scanCompletedAt = 100, totalVisuals = 240, characterKey = "Tester" } end
W.weaponSubtypeDefinitions.SWORD = { familyKey = "ONE_HAND" }
P.ResolveWeaponSubtypeCategoryID = function() return 7 end
local sources = {}
for index = 1, 240 do sources[index] = { sourceID = index, categoryID = index % 3 == 0 and 7 or 8 } end
W.GetSlotSources = function() return sources end

dofile("Core/Wardrobe/WeaponPipeline.lua")
dofile("Core/Wardrobe/WeaponCandidateIndex.lua")

local function RunIndex()
    P.GenerateWeapons = function()
        local result = P.GetIndexedWeaponSources("SWORD")
        return true, #result
    end
    local work = P.CreateWeaponGenerationWork({}, false, nil, nil)
    local frames = 0
    while true do
        frames = frames + 1
        assert(frames < 1000, "weapon index worker did not finish")
        local done, ok, value = P.StepWeaponGenerationWork(work)
        if done then return frames, ok, value, work end
    end
end

local coldFrames, ok, count, coldWork = RunIndex()
assert(ok and count == 80, "cold index output changed")
assert(coldFrames > 1 and coldWork.yields >= 20, "cold index did not build cooperatively")
local first = P.GetWeaponCandidateIndexDiagnostics()
assert(first.use == "COLD_BUILD" and first.buckets == 1, "cold index diagnostics are incomplete")

local warmFrames, warmOK, warmCount, warmWork = RunIndex()
assert(warmOK and warmCount == 80, "warm index output changed")
assert(warmFrames == 1 and warmWork.yields == 0, "warm index rebuilt instead of reusing its bucket")
local warm = P.GetWeaponCandidateIndexDiagnostics()
assert(warm.use == "WARM" and warm.reused >= 1, "warm reuse was not recorded")

P.InvalidateWeaponCandidateIndex("TEST_BUCKET_CHANGE", "SWORD")
local repairFrames, repairOK, repairCount = RunIndex()
assert(repairOK and repairCount == 80 and repairFrames > 1, "bucket-local repair did not rebuild cooperatively")
local repaired = P.GetWeaponCandidateIndexDiagnostics()
assert(repaired.use == "INCREMENTAL_REPAIR" and repaired.repairs == 1, "bucket repair diagnostics are incorrect")

print(string.format("PASS v1.9.0.11 weapon index: %d cold frames, %d warm frame, %d repair frames, %d sources", coldFrames, warmFrames, repairFrames, count))
