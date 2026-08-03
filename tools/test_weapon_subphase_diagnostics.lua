QuestChronicle = { Wardrobe = { _Private = {} } }
local W, P = QuestChronicle.Wardrobe, QuestChronicle.Wardrobe._Private
local clock = 0
debugprofilestop = function() return clock end

dofile("Core/Wardrobe/GenerationPerformance.lua")
local job = {
    startedAtMs = 0, steps = 2, maxStepMs = 20.9, candidatesProcessed = 1,
    phaseStats = { anchorWeaponExpansion = { calls = 1, totalMs = 19.9, maxMs = 19.9 } },
    anchorWeaponSlowYieldMs = 19.5, anchorWeaponSlowYieldPhase = "weaponAppearance",
}
local performance = P.BuildGenerationPerformance(job, 30)
assert(performance.largestInstrumentedCallPhase == "weaponAppearance", "weapon subphase must replace the opaque outer phase")
assert(performance.largestInstrumentedCallMs == 19.5, "weapon subphase duration must remain exact")
assert(P.GENERATION_PHASE_LABELS.weaponAppearance == "Weapon appearance lookup", "subphase label must be human-readable")
print("PASS weapon subphase diagnostics: slow anchor weapon resumes identify their exact inner phase")
