QuestChronicle = {
    _Core = {},
    Wardrobe = { _Private = {}, slotDefinitions = { { key = "CHEST" }, { key = "HEAD" } } },
    ZoneStyle = {},
}
local QC, Wardrobe, P = QuestChronicle, QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
local clock = 0
debugprofilestop = function() return clock end
P.GenerationNowMilliseconds = function() return clock end
P.RecordGenerationPhase = function(job, key, elapsed)
    job.phaseStats = job.phaseStats or {}
    job.phaseStats[key] = { maxMs = elapsed, calls = 1, totalMs = elapsed }
end
P.GetSourceByID = function(slot, id) return { slotKey = slot, sourceID = id } end
P.GetGenerationCacheCounterSnapshot = function() clock = clock + 0.1 return { addedEvidence = 1 } end
P.BeginWeaponIndexActionSnapshot = function() clock = clock + 0.1 return { state = "PARTIAL" } end
P.BuildAnchorNoveltyContext = function() clock = clock + 0.2 return { active = true } end
QC.ZoneStyle.NormalizeMode = function(mode) return mode end
QC.ZoneStyle.GetCurrentContext = function() clock = clock + 0.1 return { zone = "Outland" } end
QC.ZoneStyle.CreateGenerationContext = function(base) return { zone = base.zone, seeded = 0 } end
QC.ZoneStyle.AddSourceToGenerationContext = function(context) clock = clock + 0.05 context.seeded = context.seeded + 1 end
QC.ZoneStyle.PrepareGenerationEligibilityContext = function(context) clock = clock + 0.2 context.prepared = true end

dofile("Core/Workers/SliceBudget.lua")
dofile("Core/Wardrobe/GenerationSetupWorker.lua")
local live = {
    selections = { CHEST = 11, HEAD = 12 }, selectionVisuals = { CHEST = 21, HEAD = 22 },
    locks = { CHEST = true }, hidden = {}, weaponFamilies = {}, weaponSubtypes = {},
    styleMode = "TRAVELER", linkWeaponHands = true,
}
local job = { liveState = live, requestedStyleMode = "TRAVELER", action = "Generate Outfit", setupPhase = "IDENTITY" }
local frames = 0
while job.phase ~= "ARMOR" do
    frames = frames + 1
    assert(frames < 30, "generation setup worker did not complete")
    job.currentSlice = QuestChronicle._Core.Workers.BeginSlice(5.5, 7.5)
    local done, reason = P.StepGenerationSetup(job)
    assert(reason == nil, reason)
    if done then break end
    clock = clock + 0.2
end
assert(job.draft and job.draft ~= live, "generation setup did not create a worker-local draft")
assert(job.styleContext and job.styleContext.seeded == 1 and job.styleContext.prepared, "generation setup context changed")
assert(job.cacheCountersStarted.addedEvidence == 1, "cache scalar setup stage missing")
assert(job.weaponIndexActionStarted.state == "PARTIAL", "weapon-index setup stage missing")
for _, phase in ipairs({
    "generationActionIdentity", "generationStateSnapshot", "generationModeContext", "generationContextSeed",
    "generationEligibilityContext", "generationNoveltyReference", "generationCacheScalarSnapshot", "generationWeaponIndexSnapshot",
}) do assert(job.phaseStats[phase], "missing generation setup phase " .. phase) end
assert(job.phaseStats.Setup == nil, "monolithic Setup phase returned")
print(string.format("PASS v1.9.0.12 generation setup: %d cooperative frame(s), immutable draft, and eight bounded stages", frames))
